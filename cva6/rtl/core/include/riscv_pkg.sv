/* Copyright 2018 ETH Zurich and University of Bologna.
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the “License”); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * File:   riscv_pkg.sv
 * Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
 * Date:   30.6.2017
 *
 * Description: Common RISC-V definitions.
 */

 /*verilator tracing_off*/

package riscv;

  // ----------------------
  // Import cva6 config from cva6_config_pkg
  // ----------------------
  // FIXME stop using them from CoreV-Verif and HPDCache
  // Then remove them from this package
  localparam XLEN = cva6_config_pkg::CVA6ConfigXlen;
  localparam PLEN = (XLEN == 32) ? 34 : 56;

  // --------------------
  // Privilege Spec
  // --------------------
  typedef enum logic [1:0] {
    PRIV_LVL_M  = 2'b11,
    PRIV_LVL_HS = 2'b10,
    PRIV_LVL_S  = 2'b01,
    PRIV_LVL_U  = 2'b00
  } priv_lvl_t;

  // type which holds xlen
  typedef enum logic [1:0] {
    XLEN_32  = 2'b01,
    XLEN_64  = 2'b10,
    XLEN_128 = 2'b11
  } xlen_e;

  typedef enum logic [1:0] {
    Off     = 2'b00,
    Initial = 2'b01,
    Clean   = 2'b10,
    Dirty   = 2'b11
  } xs_t;

  typedef struct packed {
    logic sd;  // signal dirty state - read-only
    logic [62:34] wpri6;  // writes preserved reads ignored
    xlen_e uxl;  // variable user mode xlen - hardwired to zero
    logic [11:0] wpri5;  // writes preserved reads ignored
    logic mxr;  // make executable readable
    logic sum;  // permit supervisor user memory access
    logic wpri4;  // writes preserved reads ignored
    xs_t xs;  // extension register - hardwired to zero
    xs_t fs;  // floating point extension register
    logic [1:0] wpri3;  // writes preserved reads ignored
    xs_t vs;  // vector extension register
    logic spp;  // holds the previous privilege mode up to supervisor
    logic wpri2;  // writes preserved reads ignored
    logic mpie;  // machine interrupts enable bit active prior to trap
    logic         ube;    // UBE controls whether explicit load and store memory accesses made from U-mode are little-endian (UBE=0) or big-endian (UBE=1)
    logic spie;  // supervisor interrupts enable bit active prior to trap
    logic [2:0] wpri1;  // writes preserved reads ignored
    logic sie;  // supervisor interrupts enable
    logic wpri0;  // writes preserved reads ignored
  } sstatus_rv_t;

  typedef struct packed {
    logic [63:34] wpri4;  // writes preserved reads ignored
    xlen_e        vsxl;   // variable virtual supervisor mode xlen - hardwired to zero
    logic [8:0]   wpri3;  // floating point extension register
    logic         vtsr;   // virtual trap sret
    logic         vtw;    // virtual time wait
    logic         vtvm;   // virtual trap virtual memory
    logic [1:0]   wpri2;  // writes preserved reads ignored
    logic [5:0]   vgein;  // virtual guest external interrupt number
    logic [1:0]   wpri1;  // writes preserved reads ignored
    logic         hu;     // virtual-machine load/store instructions enable in U-mode
    logic         spvp;   // supervisor previous virtual privilege
    logic         spv;    // supervisor previous virtualization mode
    logic         gva;    // variable set when trap writes to stval
    logic         vsbe;   // endianness of explicit memory accesses made from VS-mode
    logic [4:0]   wpri0;  // writes preserved reads ignored
  } hstatus_rv_t;

  typedef struct packed {
    logic sd;  // signal dirty state - read-only
    logic [62:40] wpri4;  // writes preserved reads ignored
    logic mpv;  // machine previous virtualization mode
    logic gva;  // variable set when trap writes to stval
    logic mbe;  // endianness memory accesses made from M-mode
    logic sbe;  // endianness memory accesses made from S-mode
    xlen_e sxl;  // variable supervisor mode xlen - hardwired to zero
    xlen_e uxl;  // variable user mode xlen - hardwired to zero
    logic [8:0] wpri3;  // writes preserved reads ignored
    logic tsr;  // trap sret
    logic tw;  // time wait
    logic tvm;  // trap virtual memory
    logic mxr;  // make executable readable
    logic sum;  // permit supervisor user memory access
    logic mprv;  // modify privilege - privilege level for ld/st
    xs_t xs;  // extension register - hardwired to zero
    xs_t fs;  // floating point extension register
    priv_lvl_t mpp;  // holds the previous privilege mode up to machine
    xs_t vs;  // vector extension register
    logic spp;  // holds the previous privilege mode up to supervisor
    logic mpie;  // machine interrupts enable bit active prior to trap
    logic         ube;    // UBE controls whether explicit load and store memory accesses made from U-mode are little-endian (UBE=0) or big-endian (UBE=1)
    logic spie;  // supervisor interrupts enable bit active prior to trap
    logic wpri2;  // writes preserved reads ignored
    logic mie;  // machine interrupts enable
    logic wpri1;  // writes preserved reads ignored
    logic sie;  // supervisor interrupts enable
    logic wpri0;  // writes preserved reads ignored
  } mstatus_rv_t;

  typedef struct packed {
    logic        stce;   // not implemented - requires Sctc extension
    logic        pbmte;  // not implemented - requires Svpbmt extension
    logic [61:8] wpri1;  // writes preserved reads ignored
    logic        cbze;   // not implemented - requires Zicboz extension
    logic        cbcfe;  // not implemented - requires Zicbom extension
    logic [1:0]  cbie;   // not implemented - requires Zicbom extension
    logic [2:0]  wpri0;  // writes preserved reads ignored
    logic        fiom;   // fence of I/O implies memory
  } envcfg_rv_t;

  // --------------------
  // Instruction Types
  // --------------------
  typedef struct packed {
    logic [31:25] funct7;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] funct3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } rtype_t;

  typedef struct packed {
    logic [31:27] rs3;
    logic [26:25] funct2;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] funct3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } r4type_t;

  typedef struct packed {
    logic [31:27] funct5;
    logic [26:25] fmt;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] rm;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } rftype_t;  // floating-point

  typedef struct packed {
    logic [31:30] funct2;
    logic [29:25] vecfltop;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:14] repl;
    logic [13:12] vfmt;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } rvftype_t;  // vectorial floating-point

  typedef struct packed {
    logic [31:20] imm;
    logic [19:15] rs1;
    logic [14:12] funct3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } itype_t;

  typedef struct packed {
    logic [31:25] imm;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] funct3;
    logic [11:7]  imm0;
    logic [6:0]   opcode;
  } stype_t;

  typedef struct packed {
    logic [31:12] imm;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } utype_t;

  // atomic instructions
  typedef struct packed {
    logic [31:27] funct5;
    logic         aq;
    logic         rl;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] funct3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } atype_t;

  typedef union packed {
    logic [31:0] instr;
    rtype_t      rtype;
    r4type_t     r4type;
    rftype_t     rftype;
    rvftype_t    rvftype;
    itype_t      itype;
    stype_t      stype;
    utype_t      utype;
    atype_t      atype;
  } instruction_t;

  // --------------------
  // Opcodes
  // --------------------
  // RV32/64G listings:
  // Quadrant 0
  localparam OpcodeLoad = 7'b00_000_11;
  localparam OpcodeLoadFp = 7'b00_001_11;
  localparam OpcodeCustom0 = 7'b00_010_11;
  localparam OpcodeMiscMem = 7'b00_011_11;
  localparam OpcodeOpImm = 7'b00_100_11;
  localparam OpcodeAuipc = 7'b00_101_11;
  localparam OpcodeOpImm32 = 7'b00_110_11;
  // Quadrant 1
  localparam OpcodeStore = 7'b01_000_11;
  localparam OpcodeStoreFp = 7'b01_001_11;
  localparam OpcodeCustom1 = 7'b01_010_11;
  localparam OpcodeAmo = 7'b01_011_11;
  localparam OpcodeOp = 7'b01_100_11;
  localparam OpcodeLui = 7'b01_101_11;
  localparam OpcodeOp32 = 7'b01_110_11;
  // Quadrant 2
  localparam OpcodeMadd = 7'b10_000_11;
  localparam OpcodeMsub = 7'b10_001_11;
  localparam OpcodeNmsub = 7'b10_010_11;
  localparam OpcodeNmadd = 7'b10_011_11;
  localparam OpcodeOpFp = 7'b10_100_11;
  localparam OpcodeVec = 7'b10_101_11;
  localparam OpcodeCustom2 = 7'b10_110_11;
  // Quadrant 3
  localparam OpcodeBranch = 7'b11_000_11;
  localparam OpcodeJalr = 7'b11_001_11;
  localparam OpcodeRsrvd2 = 7'b11_010_11;
  localparam OpcodeJal = 7'b11_011_11;
  localparam OpcodeSystem = 7'b11_100_11;
  localparam OpcodeRsrvd3 = 7'b11_101_11;
  localparam OpcodeCustom3 = 7'b11_110_11;

  // RV64C/RV32C listings:
  // Quadrant 0
  localparam OpcodeC0 = 2'b00;
  localparam OpcodeC0Addi4spn = 3'b000;
  localparam OpcodeC0Fld = 3'b001;
  localparam OpcodeC0Lw = 3'b010;
  localparam OpcodeC0Ld = 3'b011;
  localparam OpcodeC0Zcb = 3'b100;
  localparam OpcodeC0Fsd = 3'b101;
  localparam OpcodeC0Sw = 3'b110;
  localparam OpcodeC0Sd = 3'b111;
  // Quadrant 1
  localparam OpcodeC1 = 2'b01;
  localparam OpcodeC1Addi = 3'b000;
  localparam OpcodeC1Addiw = 3'b001;  //for RV64I only
  localparam OpcodeC1Jal = 3'b001;  //for RV32I only
  localparam OpcodeC1Li = 3'b010;
  localparam OpcodeC1LuiAddi16sp = 3'b011;
  localparam OpcodeC1MiscAlu = 3'b100;
  localparam OpcodeC1J = 3'b101;
  localparam OpcodeC1Beqz = 3'b110;
  localparam OpcodeC1Bnez = 3'b111;
  // Quadrant 2
  localparam OpcodeC2 = 2'b10;
  localparam OpcodeC2Slli = 3'b000;
  localparam OpcodeC2Fldsp = 3'b001;
  localparam OpcodeC2Lwsp = 3'b010;
  localparam OpcodeC2Ldsp = 3'b011;
  localparam OpcodeC2JalrMvAdd = 3'b100;
  localparam OpcodeC2Fsdsp = 3'b101;
  localparam OpcodeC2Swsp = 3'b110;
  localparam OpcodeC2Sdsp = 3'b111;

  // ----------------------
  // Virtual Memory
  // ----------------------
  // memory management, pte for sv39
  typedef struct packed {
    logic [9:0] reserved;
    logic [44-1:0] ppn;  // PPN length for
    logic [1:0] rsw;
    logic d;
    logic a;
    logic g;
    logic u;
    logic x;
    logic w;
    logic r;
    logic v;
  } pte_t;

  // memory management, pte for sv32
  typedef struct packed {
    logic [22-1:0] ppn;  // PPN length for
    logic [1:0] rsw;
    logic d;
    logic a;
    logic g;
    logic u;
    logic x;
    logic w;
    logic r;
    logic v;
  } pte_sv32_t;

  // ----------------------
  // Exception Cause Codes
  // ----------------------
  localparam logic [XLEN-1:0] INSTR_ADDR_MISALIGNED = 0;
  localparam logic [XLEN-1:0] INSTR_ACCESS_FAULT    = 1;  // Illegal access as governed by PMPs and PMAs
  localparam logic [XLEN-1:0] ILLEGAL_INSTR = 2;
  localparam logic [XLEN-1:0] BREAKPOINT = 3;
  localparam logic [XLEN-1:0] LD_ADDR_MISALIGNED = 4;
  localparam logic [XLEN-1:0] LD_ACCESS_FAULT = 5;  // Illegal access as governed by PMPs and PMAs
  localparam logic [XLEN-1:0] ST_ADDR_MISALIGNED = 6;
  localparam logic [XLEN-1:0] ST_ACCESS_FAULT = 7;  // Illegal access as governed by PMPs and PMAs
  localparam logic [XLEN-1:0] ENV_CALL_UMODE = 8;  // environment call from user mode or virtual user mode
  localparam logic [XLEN-1:0] ENV_CALL_SMODE = 9;  // environment call from hypervisor-extended supervisor mode
  localparam logic [XLEN-1:0] ENV_CALL_VSMODE = 10; // environment call from virtual supervisor mode
  localparam logic [XLEN-1:0] ENV_CALL_MMODE = 11;  // environment call from machine mode
  localparam logic [XLEN-1:0] INSTR_PAGE_FAULT = 12;  // Instruction page fault
  localparam logic [XLEN-1:0] LOAD_PAGE_FAULT = 13;  // Load page fault
  localparam logic [XLEN-1:0] STORE_PAGE_FAULT = 15;  // Store page fault
  localparam logic [XLEN-1:0] INSTR_GUEST_PAGE_FAULT = 20;  // Instruction guest-page fault
  localparam logic [XLEN-1:0] LOAD_GUEST_PAGE_FAULT = 21;  // Load guest-page fault
  localparam logic [XLEN-1:0] VIRTUAL_INSTRUCTION = 22;  // virtual instruction
  localparam logic [XLEN-1:0] STORE_GUEST_PAGE_FAULT = 23;  // Store guest-page fault
  localparam logic [XLEN-1:0] DEBUG_REQUEST = 24;  // Debug request

  localparam int unsigned IRQ_S_SOFT = 1;
  localparam int unsigned IRQ_VS_SOFT = 2;
  localparam int unsigned IRQ_M_SOFT = 3;
  localparam int unsigned IRQ_S_TIMER = 5;
  localparam int unsigned IRQ_VS_TIMER = 6;
  localparam int unsigned IRQ_M_TIMER = 7;
  localparam int unsigned IRQ_S_EXT = 9;
  localparam int unsigned IRQ_VS_EXT = 10;
  localparam int unsigned IRQ_M_EXT = 11;
  localparam int unsigned IRQ_HS_EXT = 12;

  localparam logic [31:0] MIP_SSIP = 1 << IRQ_S_SOFT;
  localparam logic [31:0] MIP_VSSIP = 1 << IRQ_VS_SOFT;
  localparam logic [31:0] MIP_MSIP = 1 << IRQ_M_SOFT;
  localparam logic [31:0] MIP_STIP = 1 << IRQ_S_TIMER;
  localparam logic [31:0] MIP_VSTIP = 1 << IRQ_VS_TIMER;
  localparam logic [31:0] MIP_MTIP = 1 << IRQ_M_TIMER;
  localparam logic [31:0] MIP_SEIP = 1 << IRQ_S_EXT;
  localparam logic [31:0] MIP_VSEIP = 1 << IRQ_VS_EXT;
  localparam logic [31:0] MIP_MEIP = 1 << IRQ_M_EXT;
  localparam logic [31:0] MIP_SGEIP = 1 << IRQ_HS_EXT;

  // ----------------------
  // PseudoInstructions Codes
  // ----------------------
  localparam logic [31:0] READ_32_PSEUDOINSTRUCTION = 32'h00002000;
  localparam logic [31:0] WRITE_32_PSEUDOINSTRUCTION = 32'h00002020;
  localparam logic [31:0] READ_64_PSEUDOINSTRUCTION = 32'h00003000;
  localparam logic [31:0] WRITE_64_PSEUDOINSTRUCTION = 32'h00003020;

  // -----
  // CSRs
  // -----
  typedef enum logic [11:0] {
    // Floating-Point CSRs
    CSR_FFLAGS           = 12'h001,
    CSR_FRM              = 12'h002,
    CSR_FCSR             = 12'h003,
    CSR_FTRAN            = 12'h800,
    // Vector CSRs
    CSR_VSTART           = 12'h008,
    CSR_VXSAT            = 12'h009,
    CSR_VXRM             = 12'h00A,
    CSR_VCSR             = 12'h00F,
    CSR_VL               = 12'hC20,
    CSR_VTYPE            = 12'hC21,
    CSR_VLENB            = 12'hC22,
    // Virtual Supervisor Mode CSRs
    CSR_VSSTATUS         = 12'h200,
    CSR_VSIE             = 12'h204,
    CSR_VSIEH            = 12'h214,
    CSR_VSTVEC           = 12'h205,
    CSR_VSSCRATCH        = 12'h240,
    CSR_VSEPC            = 12'h241,
    CSR_VSCAUSE          = 12'h242,
    CSR_VSTVAL           = 12'h243,
    CSR_VSIP             = 12'h244,
    CSR_VSTIMECMP        = 12'h24D,
    CSR_VSISELECT        = 12'h250,
    CSR_VSIREG           = 12'h251,
    CSR_VSIREG2          = 12'h252,
    CSR_VSIREG3          = 12'h253,
    CSR_VSIPH            = 12'h254,
    CSR_VSIREG4          = 12'h255,
    CSR_VSIREG5          = 12'h256,
    CSR_VSIREG6          = 12'h257,
    CSR_VSTOPEI          = 12'h25C,
    CSR_VSTIMECMPH       = 12'h25D,
    CSR_VSATP            = 12'h280,
    CSR_VSPMPEN          = 12'h283,
    CSR_VSPMPENH         = 12'h293,
    CSR_VSTOPI           = 12'hEB0,
    // Supervisor Mode CSRs
    CSR_SSTATUS          = 12'h100,
    CSR_SIE              = 12'h104,
    CSR_SIEH             = 12'h114,
    CSR_STVEC            = 12'h105,
    CSR_SCOUNTEREN       = 12'h106,
    CSR_SENVCFG          = 12'h10A,
    CSR_SSCRATCH         = 12'h140,
    CSR_SEPC             = 12'h141,
    CSR_SCAUSE           = 12'h142,
    CSR_STVAL            = 12'h143,
    CSR_SIP              = 12'h144,
    CSR_STIMECMP         = 12'h14D,
    CSR_SISELECT         = 12'h150,
    CSR_SIREG            = 12'h151,
    CSR_SIREG2           = 12'h152,
    CSR_SIREG3           = 12'h153,
    CSR_SIPH             = 12'h154,
    CSR_SIREG4           = 12'h155,
    CSR_SIREG5           = 12'h156,
    CSR_SIREG6           = 12'h157,
    CSR_STOPEI           = 12'h15C,
    CSR_STIMECMPH        = 12'h15D,
    CSR_SATP             = 12'h180,
    CSR_SPMPEN           = 12'h183,
    CSR_SPMPENH          = 12'h193,
    CSR_STOPI            = 12'hDB0,
    // Hypervisor-extended Supervisor Mode CSRs
    CSR_HSTATUS          = 12'h600,
    CSR_HEDELEG          = 12'h602,
    CSR_HIDELEG          = 12'h603,
    CSR_HIDELEGH         = 12'h613,
    CSR_HIE              = 12'h604,
    CSR_HCOUNTEREN       = 12'h606,
    CSR_HGEIE            = 12'h607,
    CSR_HVIEN            = 12'h608,
    CSR_HVIENH           = 12'h618,
    CSR_HVICTL           = 12'h609,
    CSR_HSPMPDELEG       = 12'h616,
    CSR_HTVAL            = 12'h643,
    CSR_HIP              = 12'h644,
    CSR_HVIP             = 12'h645,
    CSR_HVIPH            = 12'h655,
    CSR_HVIPRIO1         = 12'h646,
    CSR_HVIPRIO1H        = 12'h656,
    CSR_HVIPRIO2         = 12'h647,
    CSR_HVIPRIO2H        = 12'h657,
    CSR_HTINST           = 12'h64A,
    CSR_HGEIP            = 12'hE12,
    CSR_HENVCFG          = 12'h60A,
    CSR_HENVCFGH         = 12'h61A,
    CSR_HGATP            = 12'h680,
    CSR_HSPMPEN          = 12'h683,
    CSR_HSPMPENH         = 12'h693,
    CSR_HCONTEXT         = 12'h6A8,
    CSR_HTIMEDELTA       = 12'h605,
    CSR_HTIMEDELTAH      = 12'h615,
    // Machine Mode CSRs
    CSR_MSTATUS          = 12'h300,
    CSR_MISA             = 12'h301,
    CSR_MEDELEG          = 12'h302,
    CSR_MIDELEG          = 12'h303,
    CSR_MIDELEGH         = 12'h313,
    CSR_MIE              = 12'h304,
    CSR_MIEH             = 12'h314,
    CSR_MTVEC            = 12'h305,
    CSR_MCOUNTEREN       = 12'h306,
    CSR_MVIEN            = 12'h308,
    CSR_MVIENH           = 12'h318,
    CSR_MVIP             = 12'h309,
    CSR_MVIPH            = 12'h319,
    CSR_MSTATUSH         = 12'h310,
    CSR_MPMPDELEG        = 12'h316,
    CSR_MCOUNTINHIBIT    = 12'h320,
    CSR_MHPM_EVENT_3     = 12'h323,  //Machine performance monitoring Event Selector
    CSR_MHPM_EVENT_4     = 12'h324,  //Machine performance monitoring Event Selector
    CSR_MHPM_EVENT_5     = 12'h325,  //Machine performance monitoring Event Selector
    CSR_MHPM_EVENT_6     = 12'h326,  //Machine performance monitoring Event Selector
    CSR_MHPM_EVENT_7     = 12'h327,  //Machine performance monitoring Event Selector
    CSR_MHPM_EVENT_8     = 12'h328,  //Machine performance monitoring Event Selector
    CSR_MHPM_EVENT_9     = 12'h329,  //Reserved
    CSR_MHPM_EVENT_10    = 12'h32A,  //Reserved
    CSR_MHPM_EVENT_11    = 12'h32B,  //Reserved
    CSR_MHPM_EVENT_12    = 12'h32C,  //Reserved
    CSR_MHPM_EVENT_13    = 12'h32D,  //Reserved
    CSR_MHPM_EVENT_14    = 12'h32E,  //Reserved
    CSR_MHPM_EVENT_15    = 12'h32F,  //Reserved
    CSR_MHPM_EVENT_16    = 12'h330,  //Reserved
    CSR_MHPM_EVENT_17    = 12'h331,  //Reserved
    CSR_MHPM_EVENT_18    = 12'h332,  //Reserved
    CSR_MHPM_EVENT_19    = 12'h333,  //Reserved
    CSR_MHPM_EVENT_20    = 12'h334,  //Reserved
    CSR_MHPM_EVENT_21    = 12'h335,  //Reserved
    CSR_MHPM_EVENT_22    = 12'h336,  //Reserved
    CSR_MHPM_EVENT_23    = 12'h337,  //Reserved
    CSR_MHPM_EVENT_24    = 12'h338,  //Reserved
    CSR_MHPM_EVENT_25    = 12'h339,  //Reserved
    CSR_MHPM_EVENT_26    = 12'h33A,  //Reserved
    CSR_MHPM_EVENT_27    = 12'h33B,  //Reserved
    CSR_MHPM_EVENT_28    = 12'h33C,  //Reserved
    CSR_MHPM_EVENT_29    = 12'h33D,  //Reserved
    CSR_MHPM_EVENT_30    = 12'h33E,  //Reserved
    CSR_MHPM_EVENT_31    = 12'h33F,  //Reserved
    CSR_MSCRATCH         = 12'h340,
    CSR_MEPC             = 12'h341,
    CSR_MCAUSE           = 12'h342,
    CSR_MTVAL            = 12'h343,
    CSR_MIP              = 12'h344,
    CSR_MIPH             = 12'h354,
    CSR_MTINST           = 12'h34A,
    CSR_MTVAL2           = 12'h34B,
    CSR_MENVCFG          = 12'h30A,
    CSR_MENVCFGH         = 12'h31A,
    CSR_MISELECT         = 12'h350,
    CSR_MIREG            = 12'h351,
    CSR_MIREG2           = 12'h352,
    CSR_MIREG3           = 12'h353,
    CSR_MIREG4           = 12'h355,
    CSR_MIREG5           = 12'h356,
    CSR_MIREG6           = 12'h357,
    CSR_MTOPEI           = 12'h35C,
    CSR_PMPCFG0          = 12'h3A0,
    CSR_PMPCFG1          = 12'h3A1,
    CSR_PMPCFG2          = 12'h3A2,
    CSR_PMPCFG3          = 12'h3A3,
    CSR_PMPCFG4          = 12'h3A4,
    CSR_PMPCFG5          = 12'h3A5,
    CSR_PMPCFG6          = 12'h3A6,
    CSR_PMPCFG7          = 12'h3A7,
    CSR_PMPCFG8          = 12'h3A8,
    CSR_PMPCFG9          = 12'h3A9,
    CSR_PMPCFG10         = 12'h3AA,
    CSR_PMPCFG11         = 12'h3AB,
    CSR_PMPCFG12         = 12'h3AC,
    CSR_PMPCFG13         = 12'h3AD,
    CSR_PMPCFG14         = 12'h3AE,
    CSR_PMPCFG15         = 12'h3AF,
    CSR_PMPADDR0         = 12'h3B0,
    CSR_PMPADDR1         = 12'h3B1,
    CSR_PMPADDR2         = 12'h3B2,
    CSR_PMPADDR3         = 12'h3B3,
    CSR_PMPADDR4         = 12'h3B4,
    CSR_PMPADDR5         = 12'h3B5,
    CSR_PMPADDR6         = 12'h3B6,
    CSR_PMPADDR7         = 12'h3B7,
    CSR_PMPADDR8         = 12'h3B8,
    CSR_PMPADDR9         = 12'h3B9,
    CSR_PMPADDR10        = 12'h3BA,
    CSR_PMPADDR11        = 12'h3BB,
    CSR_PMPADDR12        = 12'h3BC,
    CSR_PMPADDR13        = 12'h3BD,
    CSR_PMPADDR14        = 12'h3BE,
    CSR_PMPADDR15        = 12'h3BF,
    CSR_PMPADDR16        = 12'h3C0,
    CSR_PMPADDR17        = 12'h3C1,
    CSR_PMPADDR18        = 12'h3C2,
    CSR_PMPADDR19        = 12'h3C3,
    CSR_PMPADDR20        = 12'h3C4,
    CSR_PMPADDR21        = 12'h3C5,
    CSR_PMPADDR22        = 12'h3C6,
    CSR_PMPADDR23        = 12'h3C7,
    CSR_PMPADDR24        = 12'h3C8,
    CSR_PMPADDR25        = 12'h3C9,
    CSR_PMPADDR26        = 12'h3CA,
    CSR_PMPADDR27        = 12'h3CB,
    CSR_PMPADDR28        = 12'h3CC,
    CSR_PMPADDR29        = 12'h3CD,
    CSR_PMPADDR30        = 12'h3CE,
    CSR_PMPADDR31        = 12'h3CF,
    CSR_PMPADDR32        = 12'h3D0,
    CSR_PMPADDR33        = 12'h3D1,
    CSR_PMPADDR34        = 12'h3D2,
    CSR_PMPADDR35        = 12'h3D3,
    CSR_PMPADDR36        = 12'h3D4,
    CSR_PMPADDR37        = 12'h3D5,
    CSR_PMPADDR38        = 12'h3D6,
    CSR_PMPADDR39        = 12'h3D7,
    CSR_PMPADDR40        = 12'h3D8,
    CSR_PMPADDR41        = 12'h3D9,
    CSR_PMPADDR42        = 12'h3DA,
    CSR_PMPADDR43        = 12'h3DB,
    CSR_PMPADDR44        = 12'h3DC,
    CSR_PMPADDR45        = 12'h3DD,
    CSR_PMPADDR46        = 12'h3DE,
    CSR_PMPADDR47        = 12'h3DF,
    CSR_PMPADDR48        = 12'h3E0,
    CSR_PMPADDR49        = 12'h3E1,
    CSR_PMPADDR50        = 12'h3E2,
    CSR_PMPADDR51        = 12'h3E3,
    CSR_PMPADDR52        = 12'h3E4,
    CSR_PMPADDR53        = 12'h3E5,
    CSR_PMPADDR54        = 12'h3E6,
    CSR_PMPADDR55        = 12'h3E7,
    CSR_PMPADDR56        = 12'h3E8,
    CSR_PMPADDR57        = 12'h3E9,
    CSR_PMPADDR58        = 12'h3EA,
    CSR_PMPADDR59        = 12'h3EB,
    CSR_PMPADDR60        = 12'h3EC,
    CSR_PMPADDR61        = 12'h3ED,
    CSR_PMPADDR62        = 12'h3EE,
    CSR_PMPADDR63        = 12'h3EF,
    CSR_MVENDORID        = 12'hF11,
    CSR_MARCHID          = 12'hF12,
    CSR_MIMPID           = 12'hF13,
    CSR_MHARTID          = 12'hF14,
    CSR_MCONFIGPTR       = 12'hF15,
    CSR_MTOPI            = 12'hFB0,
    CSR_MCYCLE           = 12'hB00,
    CSR_MCYCLEH          = 12'hB80,
    CSR_MINSTRET         = 12'hB02,
    CSR_MINSTRETH        = 12'hB82,
    //Performance Counters
    CSR_MHPM_COUNTER_3   = 12'hB03,
    CSR_MHPM_COUNTER_4   = 12'hB04,
    CSR_MHPM_COUNTER_5   = 12'hB05,
    CSR_MHPM_COUNTER_6   = 12'hB06,
    CSR_MHPM_COUNTER_7   = 12'hB07,
    CSR_MHPM_COUNTER_8   = 12'hB08,
    CSR_MHPM_COUNTER_9   = 12'hB09,  // reserved
    CSR_MHPM_COUNTER_10  = 12'hB0A,  // reserved
    CSR_MHPM_COUNTER_11  = 12'hB0B,  // reserved
    CSR_MHPM_COUNTER_12  = 12'hB0C,  // reserved
    CSR_MHPM_COUNTER_13  = 12'hB0D,  // reserved
    CSR_MHPM_COUNTER_14  = 12'hB0E,  // reserved
    CSR_MHPM_COUNTER_15  = 12'hB0F,  // reserved
    CSR_MHPM_COUNTER_16  = 12'hB10,  // reserved
    CSR_MHPM_COUNTER_17  = 12'hB11,  // reserved
    CSR_MHPM_COUNTER_18  = 12'hB12,  // reserved
    CSR_MHPM_COUNTER_19  = 12'hB13,  // reserved
    CSR_MHPM_COUNTER_20  = 12'hB14,  // reserved
    CSR_MHPM_COUNTER_21  = 12'hB15,  // reserved
    CSR_MHPM_COUNTER_22  = 12'hB16,  // reserved
    CSR_MHPM_COUNTER_23  = 12'hB17,  // reserved
    CSR_MHPM_COUNTER_24  = 12'hB18,  // reserved
    CSR_MHPM_COUNTER_25  = 12'hB19,  // reserved
    CSR_MHPM_COUNTER_26  = 12'hB1A,  // reserved
    CSR_MHPM_COUNTER_27  = 12'hB1B,  // reserved
    CSR_MHPM_COUNTER_28  = 12'hB1C,  // reserved
    CSR_MHPM_COUNTER_29  = 12'hB1D,  // reserved
    CSR_MHPM_COUNTER_30  = 12'hB1E,  // reserved
    CSR_MHPM_COUNTER_31  = 12'hB1F,  // reserved
    CSR_MHPM_COUNTER_3H  = 12'hB83,
    CSR_MHPM_COUNTER_4H  = 12'hB84,
    CSR_MHPM_COUNTER_5H  = 12'hB85,
    CSR_MHPM_COUNTER_6H  = 12'hB86,
    CSR_MHPM_COUNTER_7H  = 12'hB87,
    CSR_MHPM_COUNTER_8H  = 12'hB88,
    CSR_MHPM_COUNTER_9H  = 12'hB89,  // reserved
    CSR_MHPM_COUNTER_10H = 12'hB8A,  // reserved
    CSR_MHPM_COUNTER_11H = 12'hB8B,  // reserved
    CSR_MHPM_COUNTER_12H = 12'hB8C,  // reserved
    CSR_MHPM_COUNTER_13H = 12'hB8D,  // reserved
    CSR_MHPM_COUNTER_14H = 12'hB8E,  // reserved
    CSR_MHPM_COUNTER_15H = 12'hB8F,  // reserved
    CSR_MHPM_COUNTER_16H = 12'hB90,  // reserved
    CSR_MHPM_COUNTER_17H = 12'hB91,  // reserved
    CSR_MHPM_COUNTER_18H = 12'hB92,  // reserved
    CSR_MHPM_COUNTER_19H = 12'hB93,  // reserved
    CSR_MHPM_COUNTER_20H = 12'hB94,  // reserved
    CSR_MHPM_COUNTER_21H = 12'hB95,  // reserved
    CSR_MHPM_COUNTER_22H = 12'hB96,  // reserved
    CSR_MHPM_COUNTER_23H = 12'hB97,  // reserved
    CSR_MHPM_COUNTER_24H = 12'hB98,  // reserved
    CSR_MHPM_COUNTER_25H = 12'hB99,  // reserved
    CSR_MHPM_COUNTER_26H = 12'hB9A,  // reserved
    CSR_MHPM_COUNTER_27H = 12'hB9B,  // reserved
    CSR_MHPM_COUNTER_28H = 12'hB9C,  // reserved
    CSR_MHPM_COUNTER_29H = 12'hB9D,  // reserved
    CSR_MHPM_COUNTER_30H = 12'hB9E,  // reserved
    CSR_MHPM_COUNTER_31H = 12'hB9F,  // reserved
    // Cache Control (platform specifc)
    CSR_DCACHE           = 12'h7C1,
    CSR_ICACHE           = 12'h7C0,
    // Accelerator memory consistency (platform specific)
    CSR_ACC_CONS         = 12'h7C2,
    // Triggers
    CSR_TSELECT          = 12'h7A0,
    CSR_TDATA1           = 12'h7A1,
    CSR_TDATA2           = 12'h7A2,
    CSR_TDATA3           = 12'h7A3,
    CSR_TINFO            = 12'h7A4,
    // Debug CSR
    CSR_DCSR             = 12'h7b0,
    CSR_DPC              = 12'h7b1,
    CSR_DSCRATCH0        = 12'h7b2,  // optional
    CSR_DSCRATCH1        = 12'h7b3,  // optional
    // Counters and Timers from Zicntr extension (User Mode - R/O Shadows)
    CSR_CYCLE            = 12'hC00,
    CSR_CYCLEH           = 12'hC80,
    CSR_TIME             = 12'hC01,
    CSR_TIMEH            = 12'hC81,
    CSR_INSTRET          = 12'hC02,
    CSR_INSTRETH         = 12'hC82,
    // Performance counters from Zihpm extension (User Mode - R/O Shadows)
    CSR_HPM_COUNTER_3    = 12'hC03,
    CSR_HPM_COUNTER_4    = 12'hC04,
    CSR_HPM_COUNTER_5    = 12'hC05,
    CSR_HPM_COUNTER_6    = 12'hC06,
    CSR_HPM_COUNTER_7    = 12'hC07,
    CSR_HPM_COUNTER_8    = 12'hC08,
    CSR_HPM_COUNTER_9    = 12'hC09,  // reserved
    CSR_HPM_COUNTER_10   = 12'hC0A,  // reserved
    CSR_HPM_COUNTER_11   = 12'hC0B,  // reserved
    CSR_HPM_COUNTER_12   = 12'hC0C,  // reserved
    CSR_HPM_COUNTER_13   = 12'hC0D,  // reserved
    CSR_HPM_COUNTER_14   = 12'hC0E,  // reserved
    CSR_HPM_COUNTER_15   = 12'hC0F,  // reserved
    CSR_HPM_COUNTER_16   = 12'hC10,  // reserved
    CSR_HPM_COUNTER_17   = 12'hC11,  // reserved
    CSR_HPM_COUNTER_18   = 12'hC12,  // reserved
    CSR_HPM_COUNTER_19   = 12'hC13,  // reserved
    CSR_HPM_COUNTER_20   = 12'hC14,  // reserved
    CSR_HPM_COUNTER_21   = 12'hC15,  // reserved
    CSR_HPM_COUNTER_22   = 12'hC16,  // reserved
    CSR_HPM_COUNTER_23   = 12'hC17,  // reserved
    CSR_HPM_COUNTER_24   = 12'hC18,  // reserved
    CSR_HPM_COUNTER_25   = 12'hC19,  // reserved
    CSR_HPM_COUNTER_26   = 12'hC1A,  // reserved
    CSR_HPM_COUNTER_27   = 12'hC1B,  // reserved
    CSR_HPM_COUNTER_28   = 12'hC1C,  // reserved
    CSR_HPM_COUNTER_29   = 12'hC1D,  // reserved
    CSR_HPM_COUNTER_30   = 12'hC1E,  // reserved
    CSR_HPM_COUNTER_31   = 12'hC1F,  // reserved
    CSR_HPM_COUNTER_3H   = 12'hC83,
    CSR_HPM_COUNTER_4H   = 12'hC84,
    CSR_HPM_COUNTER_5H   = 12'hC85,
    CSR_HPM_COUNTER_6H   = 12'hC86,
    CSR_HPM_COUNTER_7H   = 12'hC87,
    CSR_HPM_COUNTER_8H   = 12'hC88,
    CSR_HPM_COUNTER_9H   = 12'hC89,  // reserved
    CSR_HPM_COUNTER_10H  = 12'hC8A,  // reserved
    CSR_HPM_COUNTER_11H  = 12'hC8B,  // reserved
    CSR_HPM_COUNTER_12H  = 12'hC8C,  // reserved
    CSR_HPM_COUNTER_13H  = 12'hC8D,  // reserved
    CSR_HPM_COUNTER_14H  = 12'hC8E,  // reserved
    CSR_HPM_COUNTER_15H  = 12'hC8F,  // reserved
    CSR_HPM_COUNTER_16H  = 12'hC90,  // reserved
    CSR_HPM_COUNTER_17H  = 12'hC91,  // reserved
    CSR_HPM_COUNTER_18H  = 12'hC92,  // reserved
    CSR_HPM_COUNTER_19H  = 12'hC93,  // reserved
    CSR_HPM_COUNTER_20H  = 12'hC94,  // reserved
    CSR_HPM_COUNTER_21H  = 12'hC95,  // reserved
    CSR_HPM_COUNTER_22H  = 12'hC96,  // reserved
    CSR_HPM_COUNTER_23H  = 12'hC97,  // reserved
    CSR_HPM_COUNTER_24H  = 12'hC98,  // reserved
    CSR_HPM_COUNTER_25H  = 12'hC99,  // reserved
    CSR_HPM_COUNTER_26H  = 12'hC9A,  // reserved
    CSR_HPM_COUNTER_27H  = 12'hC9B,  // reserved
    CSR_HPM_COUNTER_28H  = 12'hC9C,  // reserved
    CSR_HPM_COUNTER_29H  = 12'hC9D,  // reserved
    CSR_HPM_COUNTER_30H  = 12'hC9E,  // reserved
    CSR_HPM_COUNTER_31H  = 12'hC9F   // reserved
  } csr_reg_t;

  // CSRs accessible via Sxcsrind
  // Bit 12 must be set *only* for CSRs exclusively accessible via Sxcsrind
  typedef enum logic [12:0] {
    /*** CSRs accessible via Sxcsrind or direct access ***/
    // ...

    /*** CSRs accessible *only* via Sxcsrind ***/
    // AIA CSRs
    CSR_MIPRIO      = 13'h1000,
    CSR_MIMSIC      = 13'h1001,
    CSR_SIPRIO      = 13'h1002,
    CSR_SIMSIC      = 13'h1003,
    CSR_VSIMSIC     = 13'h1004,

    // SPMP CSRs
    CSR_SPMPCFG     = 13'h1005,
    CSR_SPMPADDR    = 13'h1006,
    CSR_VSPMPCFG    = 13'h1007,
    CSR_VSPMPADDR   = 13'h1008,
    
    // ...

    // Dummy encoding to overcome xireg3->xireg4 jump
    CSR_DUMMY            = 13'h1FFD,
    // Aux encoding for indirect accesses to unimplemented CSRs
    CSR_ILLEGAL          = 13'h1FFF
  } csr_ind_reg_t;

  localparam logic [63:0] SSTATUS_UIE = 'h00000001;
  localparam logic [63:0] SSTATUS_SIE = 'h00000002;
  localparam logic [63:0] SSTATUS_SPIE = 'h00000020;
  localparam logic [63:0] SSTATUS_SPP = 'h00000100;
  localparam logic [63:0] SSTATUS_FS = 'h00006000;
  localparam logic [63:0] SSTATUS_XS = 'h00018000;
  localparam logic [63:0] SSTATUS_SUM = 'h00040000;
  localparam logic [63:0] SSTATUS_MXR = 'h00080000;
  localparam logic [63:0] SSTATUS_UPIE = 'h00000010;
  localparam logic [63:0] SSTATUS_UXL = 64'h0000000300000000;
  function automatic logic [63:0] sstatus_sd(logic IS_XLEN64);
    return {IS_XLEN64, 31'h00000000, ~IS_XLEN64, 31'h00000000};
  endfunction

  localparam logic [63:0] HSTATUS_VSBE = 'h00000020;
  localparam logic [63:0] HSTATUS_GVA = 'h00000040;
  localparam logic [63:0] HSTATUS_SPV = 'h00000080;
  localparam logic [63:0] HSTATUS_SPVP = 'h00000100;
  localparam logic [63:0] HSTATUS_HU = 'h00000200;
  localparam logic [63:0] HSTATUS_VGEIN = 'h0003F000;
  localparam logic [63:0] HSTATUS_VTVM = 'h00100000;
  localparam logic [63:0] HSTATUS_VTW = 'h00200000;
  localparam logic [63:0] HSTATUS_VTSR = 'h00400000;
  localparam logic [63:0] HSTATUS_VSXL = 64'h0000000300000000;

  localparam logic [63:0] MSTATUS_UIE = 'h00000001;
  localparam logic [63:0] MSTATUS_SIE = 'h00000002;
  localparam logic [63:0] MSTATUS_HIE = 'h00000004;
  localparam logic [63:0] MSTATUS_MIE = 'h00000008;
  localparam logic [63:0] MSTATUS_UPIE = 'h00000010;
  localparam logic [63:0] MSTATUS_SPIE = 'h00000020;
  localparam logic [63:0] MSTATUS_HPIE = 'h00000040;
  localparam logic [63:0] MSTATUS_MPIE = 'h00000080;
  localparam logic [63:0] MSTATUS_SPP = 'h00000100;
  localparam logic [63:0] MSTATUS_HPP = 'h00000600;
  localparam logic [63:0] MSTATUS_MPP = 'h00001800;
  localparam logic [63:0] MSTATUS_FS = 'h00006000;
  localparam logic [63:0] MSTATUS_XS = 'h00018000;
  localparam logic [63:0] MSTATUS_MPRV = 'h00020000;
  localparam logic [63:0] MSTATUS_SUM = 'h00040000;
  localparam logic [63:0] MSTATUS_MXR = 'h00080000;
  localparam logic [63:0] MSTATUS_TVM = 'h00100000;
  localparam logic [63:0] MSTATUS_TW = 'h00200000;
  localparam logic [63:0] MSTATUS_TSR = 'h00400000;
  function automatic logic [63:0] mstatus_uxl(logic IS_XLEN64);
    return {30'h0000000, IS_XLEN64, IS_XLEN64, 32'h00000000};
  endfunction
  function automatic logic [63:0] mstatus_sxl(logic IS_XLEN64);
    return {28'h0000000, IS_XLEN64, IS_XLEN64, 34'h00000000};
  endfunction
  function automatic logic [63:0] mstatus_sd(logic IS_XLEN64);
    return {IS_XLEN64, 31'h00000000, ~IS_XLEN64, 31'h00000000};
  endfunction

  localparam logic [63:0] MENVCFG_FIOM = 'h00000001;
  localparam logic [63:0] MENVCFG_CBIE = 'h00000030;
  localparam logic [63:0] MENVCFG_CBFE = 'h00000040;
  localparam logic [63:0] MENVCFG_CBZE = 'h00000080;
  localparam logic [63:0] MENVCFG_PBMTE = 64'h4000000000000000;
  localparam logic [63:0] MENVCFG_STCE = 64'h8000000000000000;



  typedef enum logic [2:0] {
    CSRRW  = 3'h1,
    CSRRS  = 3'h2,
    CSRRC  = 3'h3,
    CSRRWI = 3'h5,
    CSRRSI = 3'h6,
    CSRRCI = 3'h7
  } csr_op_t;

  // decoded CSR address
  typedef struct packed {
    logic [1:0] rw;
    priv_lvl_t  priv_lvl;
    logic [7:0] address;
  } csr_addr_t;

  typedef union packed {
    csr_reg_t  address;
    csr_addr_t csr_decode;
  } csr_t;

  // CSR Indirect Access
  typedef struct packed {
    logic csrind_only;
    csr_t csr;
  } csr_ind_addr_t;
  
  typedef struct packed {
    priv_lvl_t csr_priv;
    logic [63:0] xiselect;
    csr_ind_addr_t csr_addr;
  } csr_ind_t;

  // Floating-Point control and status register (32-bit!)
  typedef struct packed {
    logic [31:15] reserved;  // reserved for L extension, return 0 otherwise
    logic [6:0]   fprec;     // div/sqrt precision control
    logic [2:0]   frm;       // float rounding mode
    logic [4:0]   fflags;    // float exception flags
  } fcsr_t;

  // PMP
  typedef enum logic [1:0] {
    OFF   = 2'b00,
    TOR   = 2'b01,
    NA4   = 2'b10,
    NAPOT = 2'b11
  } pmp_addr_mode_t;

  // PMP Access Type
  typedef enum logic [2:0] {
    ACCESS_NONE  = 3'b000,
    ACCESS_READ  = 3'b001,
    ACCESS_WRITE = 3'b010,
    ACCESS_EXEC  = 3'b100
  } pmp_access_t;

  typedef struct packed {
    logic x;
    logic w;
    logic r;
  } pmpcfg_access_t;

  // packed struct of a PMP configuration register (8bit)
  typedef struct packed {
    logic           locked;       // lock this configuration
    logic [1:0]     reserved;
    pmp_addr_mode_t addr_mode;    // Off, TOR, NA4, NAPOT
    pmpcfg_access_t access_type;  // [x, w, r]
  } pmpcfg_t;

  // -----
  // SPMP
  // -----
  // SPMP configuration fields
  typedef struct packed {
    logic [5:0] reserved;
    logic       shared;   // Shared region
    logic       u;        // U-mode /S-mode rule
  } spmpcfg_t;

  // -----
  // Debug
  // -----
  typedef struct packed {
    logic [31:28] xdebugver;
    logic [27:18] zero2;
    logic         ebreakvs;
    logic         ebreakvu;
    logic         ebreakm;
    logic         zero1;
    logic         ebreaks;
    logic         ebreaku;
    logic         stepie;
    logic         stopcount;
    logic         stoptime;
    logic [8:6]   cause;
    logic         v;
    logic         mprven;
    logic         nmip;
    logic         step;
    priv_lvl_t    prv;
  } dcsr_t;

  // Instruction Generation *incomplete*
  function automatic logic [31:0] jal(logic [4:0] rd, logic [20:0] imm);
    // OpCode Jal
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h6f};
  endfunction

  function automatic logic [31:0] jalr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] offset);
    // OpCode Jal
    return {offset[11:0], rs1, 3'b0, rd, 7'h67};
  endfunction

  function automatic logic [31:0] andi(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
    // OpCode andi
    return {imm[11:0], rs1, 3'h7, rd, 7'h13};
  endfunction

  function automatic logic [31:0] slli(logic [4:0] rd, logic [4:0] rs1, logic [5:0] shamt);
    // OpCode slli
    return {6'b0, shamt[5:0], rs1, 3'h1, rd, 7'h13};
  endfunction

  function automatic logic [31:0] srli(logic [4:0] rd, logic [4:0] rs1, logic [5:0] shamt);
    // OpCode srli
    return {6'b0, shamt[5:0], rs1, 3'h5, rd, 7'h13};
  endfunction

  function automatic logic [31:0] load(logic [2:0] size, logic [4:0] dest, logic [4:0] base,
                                       logic [11:0] offset);
    // OpCode Load
    return {offset[11:0], base, size, dest, 7'h03};
  endfunction

  function automatic logic [31:0] auipc(logic [4:0] rd, logic [20:0] imm);
    // OpCode Auipc
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h17};
  endfunction

  function automatic logic [31:0] store(logic [2:0] size, logic [4:0] src, logic [4:0] base,
                                        logic [11:0] offset);
    // OpCode Store
    return {offset[11:5], src, base, size, offset[4:0], 7'h23};
  endfunction

  function automatic logic [31:0] float_load(logic [2:0] size, logic [4:0] dest, logic [4:0] base,
                                             logic [11:0] offset);
    // OpCode Load
    return {offset[11:0], base, size, dest, 7'b00_001_11};
  endfunction

  function automatic logic [31:0] float_store(logic [2:0] size, logic [4:0] src, logic [4:0] base,
                                              logic [11:0] offset);
    // OpCode Store
    return {offset[11:5], src, base, size, offset[4:0], 7'b01_001_11};
  endfunction

  function automatic logic [31:0] csrw(csr_reg_t csr, logic [4:0] rs1);
    // CSRRW, rd, OpCode System
    return {csr, rs1, 3'h1, 5'h0, 7'h73};
  endfunction

  function automatic logic [31:0] csrr(csr_reg_t csr, logic [4:0] dest);
    // rs1, CSRRS, rd, OpCode System
    return {csr, 5'h0, 3'h2, dest, 7'h73};
  endfunction

  function automatic logic [31:0] branch(logic [4:0] src2, logic [4:0] src1, logic [2:0] funct3,
                                         logic [11:0] offset);
    // OpCode Branch
    return {offset[11], offset[9:4], src2, src1, funct3, offset[3:0], offset[10], 7'b11_000_11};
  endfunction

  function automatic logic [31:0] ebreak();
    return 32'h00100073;
  endfunction

  function automatic logic [31:0] wfi();
    return 32'h10500073;
  endfunction

  function automatic logic [31:0] nop();
    return 32'h00000013;
  endfunction

  function automatic logic [31:0] illegal();
    return 32'h00000000;
  endfunction

  // This functions converts S-mode CSR addresses into VS-mode CSR addresses
  // when V=1 (i.e., running in VS-mode).
  function automatic csr_t convert_vs_access_csr(csr_t csr_addr, logic v);
    csr_t ret;
    ret = csr_addr;
    unique case (csr_addr.address) inside
      [CSR_SSTATUS : CSR_STVEC], 
      [CSR_SSCRATCH : CSR_SATP], 
      [CSR_SPMPEN : CSR_SPMPENH], 
      CSR_STOPI: begin
        if (v) begin
          ret.csr_decode.priv_lvl = PRIV_LVL_HS;
        end
        return ret;
      end
      default: return ret;
    endcase
  endfunction

  // Indirect‑CSR mapping tables
  localparam int MAX_XISELECT = 32'h140;
  localparam int MAX_XISELECT_W = $clog2(MAX_XISELECT);
  localparam int XIREGS = 7;

  localparam int XISELECT_SPMP_BASE = 32'h100;

  localparam csr_ind_reg_t CSRIND_DEFAULT [XIREGS] = 
    '{ CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL };

  // M‑mode table
  localparam csr_ind_reg_t MCSRIND_MAP [MAX_XISELECT][XIREGS] = '{
    default : CSRIND_DEFAULT,
    /* miselect */      /* mireg, mireg2, mireg3, DUMMY, mireg4, mireg5, mireg6 */

        /* AIA iprio */
        'h30        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h31        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h32        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h33        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h34        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h35        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h36        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h37        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h38        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h39        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3A        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3B        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3C        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3D        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3E        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3F        : '{ CSR_MIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },

        /* AIA IMSIC */
        'h70        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h71        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h72        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h73        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h74        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h75        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h76        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h77        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h78        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h79        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7A        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7B        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7C        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7D        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7E        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7F        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h80        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h81        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h82        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h83        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h84        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h85        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h86        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h87        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h88        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h89        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8A        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8B        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8C        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8D        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8E        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8F        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h90        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h91        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h92        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h93        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h94        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h95        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h96        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h97        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h98        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h99        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9A        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9B        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9C        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9D        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9E        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9F        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA0        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA1        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA2        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA3        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA4        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA5        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA6        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA7        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA8        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA9        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAA        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAB        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAC        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAD        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAE        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAF        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB0        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB1        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB2        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB3        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB4        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB5        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB6        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB7        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB8        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB9        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBA        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBB        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBC        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBD        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBE        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBF        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC0        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC1        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC2        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC3        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC4        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC5        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC6        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC7        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC8        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC9        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCA        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCB        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCC        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCD        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCE        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCF        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD0        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD1        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD2        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD3        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD4        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD5        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD6        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD7        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD8        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD9        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDA        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDB        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDC        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDD        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDE        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDF        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE0        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE1        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE2        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE3        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE4        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE5        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE6        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE7        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE8        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE9        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEA        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEB        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEC        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hED        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEE        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEF        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF0        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF1        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF2        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF3        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF4        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF5        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF6        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF7        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF8        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF9        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFA        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFB        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFC        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFD        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFE        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFF        : '{ CSR_MIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },

        /* SPMP CSRs */
        'h100       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h101       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h102       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h103       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h104       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h105       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h106       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h107       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h108       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h109       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h110       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h111       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h112       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h113       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h114       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h115       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h116       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h117       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h118       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h119       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h120       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h121       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h122       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h123       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h124       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h125       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h126       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h127       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h128       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h129       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h130       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h131       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h132       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h133       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h134       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h135       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h136       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h137       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h138       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h139       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL }
  };

  // S‑mode table
  localparam csr_ind_reg_t SCSRIND_MAP [MAX_XISELECT][XIREGS] = '{
    default : CSRIND_DEFAULT,
    /* siselect */     /* sireg, sireg2, sireg3, DUMMY, sireg4, sireg5, sireg6 */

        /* AIA iprio */
        'h30        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h31        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h32        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h33        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h34        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h35        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h36        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h37        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h38        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h39        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3A        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3B        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3C        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3D        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3E        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h3F        : '{ CSR_SIPRIO, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },

        /* AIA IMSIC */
        'h70        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h71        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h72        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h73        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h74        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h75        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h76        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h77        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h78        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h79        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7A        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7B        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7C        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7D        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7E        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7F        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h80        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h81        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h82        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h83        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h84        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h85        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h86        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h87        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h88        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h89        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8A        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8B        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8C        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8D        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8E        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8F        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h90        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h91        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h92        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h93        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h94        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h95        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h96        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h97        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h98        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h99        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9A        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9B        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9C        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9D        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9E        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9F        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA0        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA1        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA2        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA3        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA4        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA5        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA6        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA7        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA8        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA9        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAA        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAB        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAC        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAD        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAE        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAF        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB0        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB1        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB2        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB3        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB4        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB5        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB6        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB7        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB8        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB9        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBA        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBB        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBC        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBD        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBE        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBF        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC0        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC1        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC2        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC3        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC4        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC5        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC6        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC7        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC8        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC9        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCA        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCB        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCC        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCD        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCE        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCF        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD0        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD1        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD2        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD3        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD4        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD5        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD6        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD7        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD8        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD9        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDA        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDB        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDC        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDD        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDE        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDF        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE0        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE1        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE2        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE3        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE4        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE5        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE6        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE7        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE8        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE9        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEA        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEB        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEC        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hED        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEE        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEF        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF0        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF1        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF2        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF3        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF4        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF5        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF6        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF7        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF8        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF9        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFA        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFB        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFC        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFD        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFE        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFF        : '{ CSR_SIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },

        /* SPMP CSRs */
        'h100       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h101       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h102       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h103       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h104       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h105       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h106       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h107       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h108       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h109       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h110       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h111       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h112       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h113       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h114       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h115       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h116       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h117       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h118       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h119       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h120       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h121       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h122       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h123       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h124       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h125       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h126       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h127       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h128       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h129       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h130       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h131       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h132       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h133       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h134       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h135       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h136       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h137       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h138       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h139       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13A       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13B       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13C       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13D       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13E       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13F       : '{ CSR_SPMPADDR, CSR_SPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL }
  };

  // VS‑mode table
  localparam csr_ind_reg_t VSCSRIND_MAP [MAX_XISELECT][XIREGS] = '{
    default : CSRIND_DEFAULT,
    /* vsiselect */    /* vsireg, vsireg2, vsireg3, DUMMY, vsireg4, vsireg5, vsireg6 */

        /* AIA IMSIC */
        'h70        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h71        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h72        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h73        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h74        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h75        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h76        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h77        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h78        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h79        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7A        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7B        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7C        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7D        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7E        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h7F        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h80        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h81        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h82        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h83        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h84        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h85        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h86        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h87        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h88        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h89        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8A        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8B        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8C        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8D        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8E        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h8F        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h90        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h91        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h92        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h93        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h94        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h95        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h96        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h97        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h98        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h99        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9A        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9B        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9C        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9D        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9E        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h9F        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA0        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA1        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA2        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA3        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA4        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA5        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA6        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA7        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA8        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hA9        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAA        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAB        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAC        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAD        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAE        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hAF        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB0        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB1        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB2        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB3        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB4        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB5        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB6        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB7        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB8        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hB9        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBA        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBB        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBC        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBD        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBE        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hBF        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC0        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC1        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC2        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC3        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC4        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC5        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC6        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC7        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC8        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hC9        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCA        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCB        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCC        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCD        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCE        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hCF        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD0        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD1        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD2        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD3        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD4        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD5        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD6        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD7        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD8        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hD9        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDA        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDB        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDC        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDD        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDE        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hDF        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE0        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE1        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE2        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE3        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE4        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE5        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE6        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE7        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE8        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hE9        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEA        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEB        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEC        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hED        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEE        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hEF        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF0        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF1        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF2        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF3        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF4        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF5        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF6        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF7        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF8        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hF9        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFA        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFB        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFC        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFD        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFE        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'hFF        : '{ CSR_VSIMSIC, CSR_ILLEGAL, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },

        /* SPMP CSRs */
        'h100       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h101       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h102       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h103       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h104       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h105       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h106       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h107       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h108       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h109       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10A       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10B       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10C       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10D       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10E       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h10F       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h110       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h111       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h112       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h113       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h114       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h115       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h116       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h117       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h118       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h119       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11A       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11B       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11C       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11D       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11E       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h11F       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h120       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h121       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h122       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h123       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h124       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h125       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h126       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h127       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h128       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h129       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12A       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12B       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12C       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12D       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12E       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h12F       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h130       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h131       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h132       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h133       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h134       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h135       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h136       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h137       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h138       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h139       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13A       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13B       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13C       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13D       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13E       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL },
        'h13F       : '{ CSR_VSPMPADDR, CSR_VSPMPCFG, CSR_ILLEGAL, CSR_DUMMY, CSR_ILLEGAL, CSR_ILLEGAL, CSR_ILLEGAL }
  };

  // Output the address of the corresponding CSR when it 
  //  is accessed indirectly via one of the xireg CSRs
  function automatic csr_ind_t convert_csrind_access(csr_t csr_addr, logic [63:0] miselect, 
                                                 logic [63:0] siselect, logic [63:0] vsiselect);
    csr_ind_t ret;

    unique case (csr_addr.address) inside
      [CSR_MIREG : CSR_MIREG3], [CSR_MIREG4 : CSR_MIREG6]: begin
        automatic int unsigned xireg = csr_addr.address - CSR_MIREG;
        ret.csr_addr = csr_ind_addr_t'(MCSRIND_MAP[miselect[MAX_XISELECT_W-1:0]][xireg[2:0]]);
        ret.csr_priv = PRIV_LVL_M;
        ret.xiselect = miselect;
      end
      [CSR_SIREG : CSR_SIREG3], [CSR_SIREG4 : CSR_SIREG6]: begin
        automatic int unsigned xireg = csr_addr.address - CSR_SIREG;
        ret.csr_addr = csr_ind_addr_t'(SCSRIND_MAP[siselect[MAX_XISELECT_W-1:0]][xireg[2:0]]);
        ret.csr_priv = PRIV_LVL_S;
        ret.xiselect = siselect;
      end
      [CSR_VSIREG : CSR_VSIREG3], [CSR_VSIREG4 : CSR_VSIREG6]: begin
        automatic int unsigned xireg = csr_addr.address - CSR_VSIREG;
        ret.csr_addr = csr_ind_addr_t'(VSCSRIND_MAP[vsiselect[MAX_XISELECT_W-1:0]][xireg[2:0]]);
        ret.csr_priv = PRIV_LVL_S;
        ret.xiselect = vsiselect;
      end
      default: begin
        ret.csr_priv = PRIV_LVL_U;
        ret.xiselect = '0;
        ret.csr_addr.csrind_only = 1'b0;
        ret.csr_addr.csr = csr_addr;
      end
    endcase

    return ret;
  endfunction

  // trace log compatible to spikes commit log feature
  // pragma translate_off
  function string spikeCommitLog(logic [63:0] pc, priv_lvl_t priv_lvl, logic [31:0] instr,
                                 logic [4:0] rd, logic [63:0] result, logic rd_fpr);
    string rd_s;
    string instr_word;

    automatic string rf_s = rd_fpr ? "f" : "x";

    if (instr[1:0] != 2'b11) begin
      instr_word = $sformatf("(0x%h)", instr[15:0]);
    end else begin
      instr_word = $sformatf("(0x%h)", instr);
    end

    if (rd < 10) rd_s = $sformatf("%s %0d", rf_s, rd);
    else rd_s = $sformatf("%s%0d", rf_s, rd);

    if (rd_fpr || rd != 0) begin
      // 0 0x0000000080000118 (0xeecf8f93) x31 0x0000000080004000
      return $sformatf("%d 0x%h %s %s 0x%h\n", priv_lvl, pc, instr_word, rd_s, result);
    end else begin
      // 0 0x000000008000019c (0x0040006f)
      return $sformatf("%d 0x%h %s\n", priv_lvl, pc, instr_word);
    end
  endfunction

  typedef struct {
    byte priv;
    longint unsigned pc;
    byte is_fp;
    byte rd;
    longint unsigned data;
    int unsigned instr;
    byte was_exception;
  } commit_log_t;
  // pragma translate_on

endpackage

/*verilator tracing_off*/
