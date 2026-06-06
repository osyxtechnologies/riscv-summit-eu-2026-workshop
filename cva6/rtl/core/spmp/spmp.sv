// Copyright © 2025 Manuel Rodríguez & Zero-Day Labs, Lda.
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
// Date: 02/03/2024
//
// Description: RISC-V SPMP top module.
//
// Based on the PMP module developed by: Moritz Schneider (ETH Zurich) for the CVA6 core.
//

module spmp 
    import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    // Access data
    input logic [CVA6Cfg.PLEN-1:0] addr_i,
    input riscv::pmp_access_t access_type_i,
    input riscv::priv_lvl_t priv_lvl_i,
    // CSR data
    input  logic sum_i,
    input  logic mxr_i,
    input  logic mmu_enabled_i,
    input  riscv::pmpcfg_t [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0] pmpcfg_i,
    input  riscv::spmpcfg_t [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0] spmpcfg_i,
    input  logic [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0][CVA6Cfg.PLEN-3:0] spmpaddr_i,
    input  logic [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0] spmpen_i,
    // Output
    output logic allow_o
);

    if (CVA6Cfg.NrSPMPEntries > 0) begin : gen_spmp_logic

        //--------------------------
        // SPMP Address Match Logic
        //--------------------------

        logic [(CVA6Cfg.NrSPMPEntries-1):0] match;

        for (genvar i = 0; i < CVA6Cfg.NrSPMPEntries; i++) begin : gen_spmp_matchers
            
            // Get previous address reg for TOR configs
            logic [(CVA6Cfg.NrSPMPEntries-1):0][CVA6Cfg.PLEN-3:0] spmpaddr_prev;
            assign spmpaddr_prev[i] = ((i == 0) ? ('0) : (spmpaddr_i[i-1]));

            spmp_addr_matcher #(
                .CVA6Cfg            (CVA6Cfg)
            ) i_spmp_matcher (
                .addr_i             (addr_i),
                .spmpaddr_i         (spmpaddr_i[i]),
                .spmpaddr_prev_i    (spmpaddr_prev[i]),
                .matching_mode_i    (pmpcfg_i[i].addr_mode),
                .match_o            (match[i])
            );
        end : gen_spmp_matchers

        //------------------------------
        // SPMP Permissions Check Logic
        //------------------------------

        logic  access_R;
        logic  access_W;
        logic  access_X;
        logic  access_RW;

        assign access_R     = (access_type_i == riscv::ACCESS_READ);
        assign access_W     = (access_type_i == riscv::ACCESS_WRITE);
        assign access_X     = (access_type_i == riscv::ACCESS_EXEC);
        assign access_RW    = access_R | access_W;

        // Permission check
        logic [(CVA6Cfg.NrSPMPEntries-1):0] enforce, enforce_no_x;

        always_comb begin : gen_spmp_enforce

            for (int unsigned i = 0; i < CVA6Cfg.NrSPMPEntries; i++) begin

                enforce[i]      = 1'b0;
                enforce_no_x[i] = 1'b0;

                // Enforce checks
                // Access is allowed if:
                // (1) Permissions matches with access type
                // (2) Read access and spmpcfg.X = 1 and sstatus.MXR = 1
                if (((access_type_i & pmpcfg_i[i].access_type) == access_type_i) ||
                    (access_R && pmpcfg_i[i].access_type.x && mxr_i)) begin
                    enforce[i] = 1'b1;
                end

                // Enforce checks without X permissions
                if ((access_type_i & {1'b0, pmpcfg_i[i].access_type[1:0]}) == access_type_i) begin
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
            for (k = 0; k < CVA6Cfg.NrSPMPEntries; k++) begin

                if (match[k] && (spmpen_i[k] || !CVA6Cfg.SPMPSwitchOptEn)) begin

                    // Shared region
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
                                if (((priv_lvl_i == riscv::PRIV_LVL_S) && enforce[k]) ||
                                    ((priv_lvl_i == riscv::PRIV_LVL_U) && access_R)) begin
                                    allow = 1'b1;
                                end
                            end

                            // Enforce for S-mode, XO for U-mode
                            3'b111: begin
                                if (((priv_lvl_i == riscv::PRIV_LVL_S) && enforce[k]) ||
                                    ((priv_lvl_i == riscv::PRIV_LVL_U) && access_X)) begin
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

                            3'b000,
                            3'b001,
                            3'b011,
                            3'b100,
                            3'b101,
                            3'b111: begin

                                // S-mode rule: Enforce for S-mode, deny for U-mode
                                if (!spmpcfg_i[k].u && (priv_lvl_i == riscv::PRIV_LVL_S) && enforce[k]) begin
                                    allow = 1'b1;
                                end

                                // U-mode rule:
                                // Deny for S-mode if sstatus.SUM = 0,
                                // Enforce without X for S-mode if sstatus.SUM = 1,
                                // Enforce for U-mode 
                                else begin
                                    if (((priv_lvl_i == riscv::PRIV_LVL_S) && sum_i && enforce_no_x[k]) ||
                                        ((priv_lvl_i == riscv::PRIV_LVL_U) && enforce[k])) begin
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

            /* If the effective privilege mode of the access is S/U and no SPMP entry matches, 
               but at least one SPMP entry is delegated, the access is denied. */
        end : gen_spmp_check

        always_comb begin : gen_spmp_allow

            allow_o = 1'b0;

            // All M-mode accesses pass SPMP cheks
            // If the core MMU is enabled (satp.mode != Bare), SPMP is not used
            if ((priv_lvl_i == riscv::PRIV_LVL_M) || mmu_enabled_i) begin
                allow_o = 1'b1;
            end

            else begin
                allow_o = allow;
            end
        end : gen_spmp_allow
    end : gen_spmp_logic
    
    // if there are no SPMP entries we can always grant the access
    else
        assign allow_o = 1'b1;

endmodule