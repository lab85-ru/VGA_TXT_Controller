//-----------------------------------------------------------------------------
// VGA 640x480 pixel 60 Hz Standart
// Text video adapter: 80x30 char
// Color: 0-1
//
// input i_clk = 25.175 MHz T= 39.72 ns (25MHz-40 ns)
// 
//-----------------------------------------------------------------------------

// `define DEBUG

module vga_640x480 (
    input wire i_clk50,
	 output wire o_video,
	 output wire o_vs,
	 output wire o_hs,
	 
	 input wire i_spi_mosi,              // EXTERNAL i/o interface SPI for DM
	 input wire i_spi_cs,
	 input wire i_spi_sck,
	 output wire o_spi_miso

`ifdef DEBUG	 
	 ,
	 output wire [11:0] v_addr,// video ram inteface for test write
	 output wire [7:0] v_data,
	 output wire v_we,
	 output wire v_ready,

	 output wire [7:0] p_i_port,               // port data
	 output wire [7:0] p_o_port,               // port data
	 output wire p_i_cs_h,                 // chip select, for I/O port*
	 output wire p_i_rl_wh,               // if =1 then RE, if =0 then WE.
//	 output wire o_ready_h,               // controler zanat

	 
	 // debug
	 output wire hs_str_en_h_,
	 output wire hs_str_start_,

    output wire [3:0] st_char_,
    output wire vr_re_h_,
    output wire cr_re_h_,
    output wire shreg_en_h_,
	 
	 output wire hs_str_stop_,
	 output wire o_c_x_clr_h,
    output wire o_c_x_en_h,
    output wire [14:0] o_c_x,
	 output wire o_c_y_clr_h,
    output wire o_c_y_en_h,
    output wire [8:0] o_c_y,
	 output wire [7:0] o_vram_data,
	 
	 output wire wr_pos_,
    output wire [14:0] start_vram_addr_,
    output wire [14:0] vram_addr_,
	 output wire t8,
	 output wire [7:0] o_data_rom,
	 output wire o_cur_out_en_h
`endif
);


wire i_clk;

wire [7:0] cmd;           // command
wire [11:0] cur_adr;      // adr cursor
wire [7:0] spi_to_vga;    // data to controller
wire [7:0] vga_to_spi;    // data from controller
wire cs_h;                // chip select
wire rl_wh;               // read - write
wire ready_h;             // controler status



//-----------------------------------------------------------------------------
// PLL CLK DIV 50MHz -> 25 MHz
//-----------------------------------------------------------------------------
pll25 P50_25 (
	.inclk0(i_clk50),
	.c0(i_clk)
);

//-----------------------------------------------------------------------------
// Most SPI to VGA
//-----------------------------------------------------------------------------
spi_contr SPI_TO_VGA
(
    .i_clk(     i_clk   ),

	 .o_vga_cmd(     cmd     ),        // command 
	 .o_vga_cur_adr( cur_adr ),        // set adr cursor
	 .o_vga_port(    spi_to_vga ),     // output port data
	 .i_vga_port(    vga_to_spi ),     // input port data
	 .o_vga_cs_h(    cs_h    ),        // chip select, for I/O port*
	 .o_vga_rl_wh(   rl_wh   ),        // if =0 then RE, if =1 then WE.
	 .i_vga_ready_h( ready_h ),        // controler gotov
	 
	 .i_spi_mosi( i_spi_mosi ),    // EXTERNAL i/o interface SPI
	 .i_spi_cs(   i_spi_cs   ),
	 .i_spi_sck(  i_spi_sck  ),
	 .o_spi_miso( o_spi_miso )
);

//-----------------------------------------------------------------------------
// Video adapter TEXT 80x25 64x30 64x60 char, vga 640x480
//-----------------------------------------------------------------------------
vga_640x480_text VGA (
    .i_clk(    i_clk ),
	 
	 .i_cmd(    cmd         ),   // CMD
	 .i_cur_adr(cur_adr     ),   // cursor ADRES
	 .i_port(   spi_to_vga  ),   // port data
	 .o_port(   vga_to_spi  ),   // port data
	 .i_cs_h(   cs_h        ),   // chip select, for I/O port*
	 .i_rl_wh(  rl_wh       ),   // if =1 then RE, if =0 then WE.
	 .o_ready_h(ready_h     ),   // controler zanat
	 
	 .o_hs(     o_hs ),
	 .o_vs(     o_vs ),
	 .o_video(  o_video )
	 
`ifdef DEBUG	 
	 ,
	 .v_addr(v_addr),            // video ram inteface for test write
	 .v_data(v_data),
	 .v_we(v_we),
	 	 
	 // debug
	 .hs_str_en_h_(hs_str_en_h_),
	 .hs_str_start_(hs_str_start_),

    .st_char_(st_char_),
    .vr_re_h_(vr_re_h_),
    .cr_re_h_(cr_re_h_),
    .shreg_en_h_(shreg_en_h_),
	 
	 .hs_str_stop_(hs_str_stop_),
	 .o_c_x_clr_h(o_c_x_clr_h),
    .o_c_x_en_h(o_c_x_en_h),
    .o_c_x(o_c_x),
	 .o_c_y_clr_h(o_c_y_clr_h),
    .o_c_y_en_h(o_c_y_en_h),
    .o_c_y(o_c_y),
	 .o_vram_data(o_vram_data),
	 
	 .wr_pos_(wr_pos_),
    .start_vram_addr_(start_vram_addr_),
    .vram_addr_(vram_addr_),
	 .t8(t8),
	 .o_data_rom(o_data_rom),
	 .o_cur_out_en_h(o_cur_out_en_h)

`endif
);



`ifdef DEBUG
assign v_ready = ready_h;

assign p_i_port = spi_to_vga;
assign p_o_port = vga_to_spi;           // port data
assign p_i_cs_h = cs_h;                 // chip select, for I/O port*
assign p_i_rl_wh = rl_wh;               // if =1 then RE, if =0 then WE.

`endif

endmodule

