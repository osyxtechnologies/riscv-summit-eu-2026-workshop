// Copyright © 2024 Manuel Rodríguez & Zero-Day Labs, Lda.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// Licensed under the Solderpad Hardware License v 2.1 (the “License”); 
// you may not use this file except in compliance with the License, 
// or, at your option, the Apache License version 2.0. 
// You may obtain a copy of the License at https://solderpad.org/licenses/SHL-2.1/.
// Unless required by applicable law or agreed to in writing, 
// any work distributed under the License is distributed on an “AS IS” BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
// See the License for the specific language governing permissions and limitations under the License.
//
// Author: Manuel Rodríguez <manuel.cederog@gmail.com>
// Date: 02/03/2023
//
// Description: RISC-V SPMP for Hypervisor. Top module.
//
// Based on the PMP module developed by: Moritz Schneider (ETH Zurich) for the CVA6 core.
//

/*
    # is_vSPMP = 0
    To turn the SPMP virtualization-capable (and thus, perform checks as the hgPMP), we need to check the V bit.
    If V = 0, we consider S-mode and U-mode as it is in the table
    If V = 1, we consider VS and VU mode as U-mode in the table, and HS mode as S-mode in the table.

    In this case, we use the normal SPMP CSRs and sstatus.sum

    # is_vSPMP = 1
    For the vSPMP we consider VS-mode as S-mode and and VU-mode as U-mode in the table.
    In this case, we use the vSPMP CSRs and vsstatus.sum
*/

module spmp_hyp 
    import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,

    // [0] -> hSPMP
    // [1] -> vSPMP
    parameter bit is_vSPMP = 0,
    parameter int unsigned NrSPMPEntries = 32'd0

) (
    // Access data
    input  logic [CVA6Cfg.PLEN-1:0] addr_i,
    input  riscv::pmp_access_t access_type_i,
    input  riscv::priv_lvl_t priv_lvl_i,
    // CSR data
    input  logic sum_i,
    input  logic mxr_i,
    input  logic vmxr_i,
    input  logic v_i,
    input  logic is_hlvx_inst_i,
    input  logic mmu_enabled_i,
    input  riscv::pmpcfg_t [(NrSPMPEntries > 0 ? NrSPMPEntries-1 : 0):0] pmpcfg_i,
    input  logic [(NrSPMPEntries > 0 ? NrSPMPEntries-1 : 0):0][CVA6Cfg.PLEN-3:0] pmpaddr_i,
    input  riscv::spmpcfg_t [(NrSPMPEntries > 0 ? NrSPMPEntries-1 : 0):0] spmpcfg_i,
    input  logic [(NrSPMPEntries > 0 ? NrSPMPEntries-1 : 0):0] spmpen_i,
    // Output
    output logic allow_o
);

    if (NrSPMPEntries > 0) begin : gen_spmp_logic

        //--------------------------
        // SPMP Address Match Logic
        //--------------------------

        logic [(NrSPMPEntries-1):0] match;

        for (genvar i = 0; i < NrSPMPEntries; i++) begin : gen_spmp_matchers

            // Get previous address reg for TOR configs
            logic [(NrSPMPEntries-1):0][CVA6Cfg.PLEN-3:0] pmpaddr_prev;
            assign pmpaddr_prev[i] = ((i == 0) ? ('0) : (pmpaddr_i[i-1]));

            spmp_addr_matcher #(
                .CVA6Cfg            (CVA6Cfg)
            ) i_spmp_matcher (
                .addr_i             (addr_i),
                .spmpaddr_i         (pmpaddr_i[i]),
                .spmpaddr_prev_i    (pmpaddr_prev[i]),
                .matching_mode_i    (pmpcfg_i[i].addr_mode),
                .match_o            (match[i])
            );
        end : gen_spmp_matchers

        //------------------------------
        // SPMP Permissions Check Logic
        //------------------------------

        // Access type
        logic  access_R;
        logic  access_X;

        assign access_R     = (access_type_i == riscv::ACCESS_READ);
        assign access_X     = (access_type_i == riscv::ACCESS_EXEC);

        // Access privilege
        logic  access_S;
        logic  access_U;
        logic  access_HS;
        logic  access_M;

        assign access_U     = (priv_lvl_i == riscv::PRIV_LVL_U);
        assign access_S     = (priv_lvl_i == riscv::PRIV_LVL_S);
        assign access_HS    = (priv_lvl_i == riscv::PRIV_LVL_HS);
        assign access_M     = (priv_lvl_i == riscv::PRIV_LVL_M);

        // Efective privilege modes
        logic eff_Smode, eff_Umode;
        // Accesses to bypass
        logic bypass_check;
        // Permission check
        logic [(NrSPMPEntries-1):0] enforce, enforce_no_x;

        /* Determine effective privileges */
        if (is_vSPMP) begin : gen_vspmp_priv
            // For the vSPMP we consider VS-mode as S-mode and and VU-mode as U-mode.
            assign eff_Smode  = access_S & v_i;
            assign eff_Umode  = access_U & v_i;
            // Bypass non-guest accesses
            assign bypass_check = !v_i;
        end : gen_vspmp_priv

        else begin : gen_unif_spmp_priv
            // In the unified SPMP model, we consider S/HS-mode as S-mode
            // If V = 0, we consider U-mode as Umode
            // If V = 1, we consider VS-mode and VU-mode as Umode
            assign eff_Smode  = access_HS | (access_S & !v_i);
            assign eff_Umode  = (v_i) ? (access_S | access_U)  : (access_U);
            // Bypass all M-mode accesses
            assign bypass_check = access_M;
        end : gen_unif_spmp_priv

        always_comb begin : gen_spmp_enforce

            for (int unsigned i = 0; i < NrSPMPEntries; i++) begin

                enforce[i]      = 1'b0;
                enforce_no_x[i] = 1'b0;

                // Enforce checks
                // Access is allowed if:
                // (1) Permissions matches with access type, if not an HLVX instruction
                // (2) Load and cfg.X = 1 and (sstatus.MXR = 1 or (vsstatus.MXR = 1 and is_vSPMP = 1))
                // (3) HLVX instruction and cfg.X = 1
                if ( (((access_type_i & pmpcfg_i[i].access_type) == access_type_i) && !is_hlvx_inst_i) || 
                        (access_R && pmpcfg_i[i].access_type.x && (mxr_i || is_hlvx_inst_i || (vmxr_i && is_vSPMP)))) begin
                    enforce[i] = 1'b1;
                end

                // HLVX will always fail when enforcing checks with no X permissions
                // MXR has no effect without X permissions
                if (((access_type_i & {1'b0, pmpcfg_i[i].access_type[1:0]}) == access_type_i) && !is_hlvx_inst_i) begin
                    enforce_no_x[i] = 1'b1;
                end
            end
        end : gen_spmp_enforce

        logic allow;

        always_comb begin : gen_spmp_check

            int unsigned k;

            allow = 1'b0;

            // SPMP entries are statically prioritized
            // The lowest-numbered SPMP matching entry determines whether the access is allowed or fails
            for (k = 0; k < NrSPMPEntries; k++) begin

                if (match[k] && (spmpen_i[k] || !CVA6Cfg.SPMPSwitchOptEn)) begin

                    // S-mode only rule
                    if (spmpcfg_i[k].shared) begin
                        
                        // XWR
                        case (pmpcfg_i[k].access_type)

                            // Enforce for S/U-mode 
                            3'b000,
                            3'b001,
                            3'b100,
                            3'b101: begin
                                if (enforce[k]) begin
                                    allow = 1'b1;
                                end
                            end

                            // Enforce for S-mode, RO for U-mode
                            3'b011: begin
                                if ((eff_Smode && enforce[k]) ||
                                    (eff_Umode && access_R)) begin
                                    allow =   1'b0;
                                end
                            end

                            // Enforce for S-mode, XO for U-mode
                            3'b111: begin
                                if ((eff_Smode && enforce[k]) ||
                                    (eff_Umode && access_X)) begin
                                    allow = 1'b1;
                                end
                            end

                            // Reserved
                            3'b010,
                            3'b110: begin
                                allow = 1'b0;
                            end

                        endcase
                    end

                    // Non-shared rule
                    else begin
                        
                        // XWR
                        case (pmpcfg_i[k].access_type)

                            // Deny for S-mode if sstatus.SUM = 0,
                            // Enforce without X for S-mode if sstatus.SUM = 1,
                            // Enforce for U-mode
                            3'b000,
                            3'b001,
                            3'b011,
                            3'b100,
                            3'b101,
                            3'b111: begin
                                // S-mode rule: Enforce for S-mode, deny for U-mode
                                if (!spmpcfg_i[k].u && eff_Smode && enforce[k]) begin
                                    allow = 1'b1;
                                end

                                // U-mode rule:
                                // Deny for S-mode if sstatus.SUM = 0,
                                // Enforce without X for S-mode if sstatus.SUM = 1,
                                // Enforce for U-mode 
                                else begin
                                    if ((eff_Smode && sum_i && enforce_no_x[k]) ||
                                        (eff_Umode && enforce[k])) begin
                                        allow = 1'b1;
                                    end
                                end
                            end

                            // Reserved
                            3'b010,
                            3'b110: begin
                                allow = 1'b0;
                            end
                        endcase
                    end

                    // No need to continue after a match
                    break;
                end
            end

            /* If the effective privilege mode of the access is [H][V]S/U and no SPMP entry matches, 
               but at least one SPMP entry is delegated, the access is denied. */
        end : gen_spmp_check

        always_comb begin : spmp_allow

            allow_o = 1'b0;

            // All M-mode accesses pass SPMP cheks
            // If the core MMU is enabled (vsatp.mode/hgatp.mode != Bare), SPMP is not used
            if (bypass_check || mmu_enabled_i) begin
                allow_o = 1'b1;
            end

            else begin
                allow_o = allow;
            end
        end : spmp_allow
    end : gen_spmp_logic
    
    // if there are no SPMP entries we can always grant the access
    else
        assign allow_o = 1'b1;

endmodule