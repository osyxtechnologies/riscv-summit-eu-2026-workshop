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
// Description: RISC-V SPMP Interface.
//

module spmp_interface #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg        = config_pkg::cva6_cfg_empty,
    parameter type                   icache_areq_t  = logic,
    parameter type                   icache_arsp_t  = logic,
    parameter type                   exception_t    = logic
) (
    input logic clk_i,
    input logic rst_ni,

    // CSR data
    input  riscv::priv_lvl_t priv_lvl_i,
    input  riscv::priv_lvl_t ld_st_priv_lvl_i,
    input  logic sum_i,
    input  logic mxr_i,
    input  logic mmu_enabled_i,

    // IF interface
    input  icache_arsp_t if_req_i,
    output icache_areq_t if_req_o,

    // LSU interface
    input  logic lsu_valid_i,
    input  logic [CVA6Cfg.VLEN-1:0] lsu_vaddr_i,
    input  logic lsu_is_store_i,
    input  exception_t misaligned_ex_i,

    output logic lsu_valid_o,
    output logic lsu_is_store_o,
    output logic [CVA6Cfg.PLEN-1:0] lsu_paddr_o,
    output exception_t lsu_exception_o,

    // SPMP CSRs
    input  riscv::pmpcfg_t [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0] pmpcfg_i,
    input  riscv::spmpcfg_t [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0] spmpcfg_i,
    input  logic [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0][CVA6Cfg.PLEN-3:0] spmpaddr_i,
    input  logic [(CVA6Cfg.NrSPMPEntries > 0 ? CVA6Cfg.NrSPMPEntries-1 : 0):0] spmpen_i
);

    //---------
    // IF SPMP
    //---------

    logic [CVA6Cfg.PLEN-1:0]  if_req_addr;
    logic [CVA6Cfg.XLEN-1:0]  if_ex_addr;
    logic if_spmp_allow;

    always_comb begin : if_spmp

        if_req_addr = (CVA6Cfg.VLEN >= CVA6Cfg.PLEN) ?
                        (if_req_i.fetch_vaddr[CVA6Cfg.PLEN-1:0]) :
                        (CVA6Cfg.PLEN'(if_req_i.fetch_vaddr));

        if_ex_addr  = (CVA6Cfg.VLEN > CVA6Cfg.PLEN) ? 
                        {{8{1'b0}}, if_req_addr}:
                        (if_req_addr[CVA6Cfg.VLEN-1:0]);

        if_req_o.fetch_valid        = if_req_i.fetch_req;
        if_req_o.fetch_paddr        = if_req_addr;
        if_req_o.fetch_exception    = '0;

        /*** IF request ***/
        if (if_req_i.fetch_req) begin
            // SPMP Exception
            if (!if_spmp_allow) begin
                if_req_o.fetch_exception.cause  = riscv::INSTR_PAGE_FAULT;
                if_req_o.fetch_exception.tval   = if_ex_addr;
                if_req_o.fetch_exception.valid  = 1'b1;
            end
        end
    end : if_spmp

    //----------
    // LSU SPMP
    //----------

    typedef struct packed {
        logic [CVA6Cfg.PLEN-1:0] addr;
        logic is_store;
        exception_t ex;
    } lsu_access_t;
    lsu_access_t lsu_data_q, lsu_data_d;
    logic lsu_req_q, lsu_req_d;
    
    logic [CVA6Cfg.PLEN-1:0]  lsu_req_addr;
    riscv::pmp_access_t access_type;

    logic [CVA6Cfg.XLEN-1:0]  lsu_ex_addr;
    logic                     lsu_spmp_allow_q, lsu_spmp_allow_d;

    always_comb begin : lsu_spmp

        lsu_req_addr    = (CVA6Cfg.VLEN >= CVA6Cfg.PLEN) ?
                          (lsu_vaddr_i[CVA6Cfg.PLEN-1:0]) :
                          (CVA6Cfg.PLEN'(lsu_vaddr_i));
        access_type     = (lsu_is_store_i) ? 
                          (riscv::ACCESS_WRITE) : 
                          (riscv::ACCESS_READ);

        lsu_data_d.addr         = lsu_req_addr;
        lsu_data_d.is_store     = lsu_is_store_i;
        lsu_data_d.ex           = misaligned_ex_i;

        lsu_req_d  = lsu_valid_i;

        lsu_ex_addr     = (CVA6Cfg.VLEN > CVA6Cfg.PLEN)? 
                          {{8{1'b0}}, lsu_data_q.addr}:
                          (lsu_data_q.addr[CVA6Cfg.VLEN-1:0]);

        lsu_valid_o     = lsu_req_q;
        lsu_is_store_o  = lsu_data_q.is_store;
        lsu_paddr_o     = lsu_data_q.addr;
        lsu_exception_o = lsu_data_q.ex;

        /*** Load request ***/
        if (lsu_req_q && !lsu_data_q.is_store) begin
            // SPMP Exception
            if (!lsu_spmp_allow_q) begin
                lsu_exception_o.cause  = riscv::LOAD_PAGE_FAULT;
                lsu_exception_o.tval   = lsu_ex_addr;
                lsu_exception_o.tval2  = {CVA6Cfg.GPLEN{1'b0}};
                lsu_exception_o.tinst  = {32{1'b0}};
                lsu_exception_o.gva    = 1'b0;
                lsu_exception_o.valid  = 1'b1;
            end
        end

        /*** Store request ***/
        else if (lsu_req_q && lsu_data_q.is_store) begin
            // SPMP Exception
            if (!lsu_spmp_allow_q) begin
                lsu_exception_o.cause  = riscv::STORE_PAGE_FAULT;
                lsu_exception_o.tval   = lsu_ex_addr;
                lsu_exception_o.tval2  = {CVA6Cfg.GPLEN{1'b0}};
                lsu_exception_o.tinst  = {32{1'b0}};
                lsu_exception_o.gva    = 1'b0;
                lsu_exception_o.valid  = 1'b1;
            end
        end
    end : lsu_spmp

    //--------------------
    // SPMP Instantiation
    //--------------------
    
    // IF SPMP
    spmp #( 
        .CVA6Cfg            (CVA6Cfg)
    ) i_if_spmp (
        .addr_i             (if_req_addr),
        .access_type_i      (riscv::ACCESS_EXEC),
        .priv_lvl_i         (priv_lvl_i),
        .sum_i              (sum_i),
        .mxr_i              (1'b0),
        .mmu_enabled_i      (mmu_enabled_i),
        .pmpcfg_i           (pmpcfg_i),
        .spmpcfg_i          (spmpcfg_i),
        .spmpaddr_i         (spmpaddr_i),
        .spmpen_i           (spmpen_i),
        .allow_o            (if_spmp_allow)
    );

    // LSU SPMP
    spmp #( 
        .CVA6Cfg            (CVA6Cfg)
    ) i_lsu_spmp (
        .addr_i             (lsu_req_addr),
        .access_type_i      (access_type),
        .priv_lvl_i         (ld_st_priv_lvl_i),
        .sum_i              (sum_i),
        .mxr_i              (mxr_i),
        .mmu_enabled_i      (mmu_enabled_i),
        .pmpcfg_i           (pmpcfg_i),
        .spmpcfg_i          (spmpcfg_i),
        .spmpaddr_i         (spmpaddr_i),
        .spmpen_i           (spmpen_i),
        .allow_o            (lsu_spmp_allow_d)
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            lsu_data_q          <= '0;
            lsu_req_q           <= 1'b0;
            lsu_spmp_allow_q    <= 1'b1;
        end else begin
            lsu_data_q          <= lsu_data_d;
            lsu_req_q           <= lsu_req_d;
            lsu_spmp_allow_q    <= lsu_spmp_allow_d;
        end
    end
endmodule