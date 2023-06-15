//-----------------------------------------------------------------------------
// VGA 640x480 pixel 60 Hz Standart
// Text video adapter: 80x25 char
// Color: 0-1
//
// input i_clk = 25.175 MHz T= 39.72 ns (25MHz-40 ns)
// 
//-----------------------------------------------------------------------------

// `define DEBUG
`include "vga_config.vh"

module top 
(
    input wire i_clk,
//	 output wire o_video_rgb,
	 output wire o_video_r,
	 output wire o_video_g,
	 output wire o_video_b,
	 output wire o_vs,
	 output wire o_hs
//     ,
	 
//	 input wire i_spi_mosi,              // EXTERNAL i/o interface SPI for DM
//	 input wire i_spi_cs,
//	 input wire i_spi_sck,
//	 output wire o_spi_miso
);


//wire i_clk;

wire [7:0] cmd;           // command
wire [10:0] cursor_adr;      // adr cursor
wire [7:0] spi_to_vga;    // data to controller
wire [7:0] wr_to_vga;     // data to controller
wire [7:0] vga_to_spi;    // data from controller
wire cs_h;                // chip select
wire rl_wh;               // read - write
wire ready_h;             // controler status
wire video_rgb;

//-----------------------------------------------------------------------------
// Most SPI to VGA
//-----------------------------------------------------------------------------
/*
spi_contr SPI_TO_VGA
(
    .i_clk         ( i_clk      ),
	.o_vga_cmd     ( cmd        ),    // command 
	.o_vga_cur_adr ( cursor_adr ),    // set adr cursor
	.o_vga_port    ( spi_to_vga ),    // output port data
	.i_vga_port    ( vga_to_spi ),    // input port data
	.o_vga_cs_h    ( cs_h       ),    // chip select, for I/O port*
	.o_vga_rl_wh   ( rl_wh      ),    // if =0 then RE, if =1 then WE.
	.i_vga_ready_h ( ready_h    ),    // controler gotov
	 
	.i_spi_mosi    ( i_spi_mosi ),    // EXTERNAL i/o interface SPI
	.i_spi_cs      ( i_spi_cs   ),
	.i_spi_sck     ( i_spi_sck  ),
	.o_spi_miso    ( o_spi_miso )
);
*/

`ifdef VGA_CMD_PORT
cur_wr_char WR_CHAR 
(
    .i_clk        ( i_clk      ),
	.o_cmd        ( cmd        ),
	.o_cursor_adr ( cursor_adr ),
	.o_port       ( wr_to_vga  ),
	.o_cs_h       ( cs_h       ),
	.o_rl_wh      ( rl_wh      ),
	.i_ready_h    ( ready_h    ) 
);
`endif

`ifdef VGA_DMA_PORT
wire [7:0]  vram_data;
wire [10:0] vram_adr;
wire        vram_we;
wire [10:0] cursor_adr;
wire        cursor_on;

dma_cur_wr_char DMA_WR_CHAR
(
    .i_clk        ( i_clk      ),
    .o_vram_data  ( vram_data  ),
    .o_vram_adr   ( vram_adr   ),
    .o_vram_we    ( vram_we    ),
    .o_cursor_adr ( cursor_adr ),
    .o_cursor_on  ( cursor_on  )
);
`endif

//-----------------------------------------------------------------------------
// Video adapter TEXT 80x25 64x30 char, vga 640x480
//-----------------------------------------------------------------------------
vga_top VGA
(
    .i_clk     ( i_clk       ),

`ifdef VGA_CMD_PORT
	.i_cmd     ( cmd         ),   // CMD
	.i_cur_adr ( cursor_adr  ),   // cursor ADRES
//	.i_port    ( spi_to_vga  ),   // port data
	.i_port    ( wr_to_vga   ),   // port data
	.o_port    ( vga_to_spi  ),   // port data
	.i_cs_h    ( cs_h        ),   // chip select, for I/O port*
	.i_rl_wh   ( rl_wh       ),   // if =1 then RE, if =0 then WE.
	.o_ready_h ( ready_h     ),   // controler zanat
`endif

`ifdef VGA_DMA_PORT
    .i_vram_addr_wr ( vram_adr   ), // bus adr video ram
    .i_vram_data_wr ( vram_data  ), // bus data video ram
    .i_vram_wr_h    ( vram_we    ), // strobe write data to mem
    .i_cursor_addr  ( cursor_adr ), // set cursor position
    .i_cursor_en    ( cursor_on  ), // cursor enable/disable
`endif

// VGA output
	.o_hs      ( o_hs        ),
	.o_vs      ( o_vs        ),
	.o_video   ( video_rgb   )
	 
);

//assign o_video_rgb = video_rgb;
assign o_video_r = video_rgb;
assign o_video_g = video_rgb;
assign o_video_b = video_rgb;

endmodule

