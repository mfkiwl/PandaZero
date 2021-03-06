// ------------------------ Disclaimer -----------------------
// No warranty of correctness, synthesizability or 
// functionality of this code is given.
// Use this code under your own risk.
// When using this code, copy this disclaimer at the top of 
// Your file
//
// (c) Luca Hanel 2020
//
// ------------------------------------------------------------
//
// Module name: core_wrapper
// 
// Functionality: Verilog wrapper file for the core, in order
//                to instantiate it in a block design in Vivado
//                and connect a BRAM
//
// ------------------------------------------------------------

/* verilator lint_off PINMISSING */

module core_wrapper
(
    input wire          clk,
    input wire          rstn_i,
    input wire [7:0]    dbg_cmd_i,
    input wire [31:0]   dbg_addr_i,
    input wire [31:0]   dbg_data_i,
    output wire [31:0]  dbg_data_o,
    output wire         dbg_ready_o
);

// Reset signals
logic core_rst_reqn;
logic periph_rst_req;

// debug signals
logic dbg_halt_core;
logic dbg_core_rst_req;
logic dbg_periph_rst_req;

// Wishbone busses
wb_master_bus_t#(.TAGSIZE(1)) masters[3];
wb_slave_bus_t#(.TAGSIZE(1))  slaves[1];

// Reset requests
assign core_rst_reqn  = (~dbg_core_rst_req) & rstn_i;
assign periph_rst_req = (~dbg_periph_rst_req) & rstn_i;

core_top core_i
(
    .clk        ( clk           ),
    .rstn_i     ( rstn_i        ),
    .halt_core_i( dbg_halt_core ),
    .rst_reqn_o ( core_rst_reqn ),
    .IF_wb_bus  ( masters[2]    ),
    .MEM_wb_bus ( masters[1]    )
);

dbg_module #(
  .INTERNAL_MEM_S   ( 0 )
)dbg_module_i (
  .clk              ( clk               ),
  .rstn_i           ( rstn_i            ),
  .cmd_i            ( dbg_cmd_i         ),
  .addr_i           ( dbg_addr_i        ),
  .data_i           ( dbg_data_i        ),
  .data_o           ( dbg_data_o        ),
  .ready_o          ( dbg_ready_o       ),
  .halt_core_o      ( dbg_halt_core     ),
  .core_rst_req_o   ( dbg_core_rst_req  ),
  .periph_rst_req_o ( dbg_periph_rst_req),
  .wb_bus           ( masters[0]        )
);

wb_ram_wrapper #(
  .SIZE (32)
) ram_i (
  .clk    ( clk       ),
  .rstn_i ( rstn_i    ),
  .wb_bus ( slaves[0] )
);

wishbone_interconnect #(
    .TAGSIZE        ( 1 ),
    .N_SLAVE        ( 1 ),
    .N_MASTER       ( 3 )
) wb_intercon (
    .clk_i          ( clk       ),
    .rst_i          ( ~rstn_i   ),
    .SSTART_ADDR    ({32'h0}    ),
    .SEND_ADDR      ({32'h1000} ),
    .wb_master_bus  (masters    ),
    .wb_slave_bus   (slaves     )
);

endmodule