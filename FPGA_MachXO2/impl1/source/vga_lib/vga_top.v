//-----------------------------------------------------------------------------
// VGA 640x480 pixel 60 Hz Standart
// Text video adapter: 80x25 char (30 text strok to 25, ne vivodim 40 strok s verhu i 40 strok s nizu !!! ekonomiya video ram 4096 -> 2048 !!!)
// Color: 0-1
//
// input i_clk = 25.175 MHz T= 39.72 ns (25MHz-40 ns)
// 
// 
// 
// VGA Signal 640 x 480 @ 60 Hz Industry standard timing
// General timing
//
// Screen refresh rate	60 Hz
// Vertical refresh	31.46875 kHz
// Pixel freq.	25.175 MHz
// Horizontal timing (line)
//
// Polarity of horizontal sync pulse is negative.
// Scanline part	Pixels	Time [Р’Вµs]
// Visible area	640      25.422045680238
// Front porch	   16	      0.63555114200596
// Sync pulse	   96	      3.8133068520357
// Back porch	   48	      1.9066534260179
// Whole line	   800	   31.777557100298
//
// Vertical timing (frame)
//
// Polarity of vertical sync pulse is negative.
// Frame part	  Lines	Time [ms]
// Visible area	480   15.253227408143
// Front porch	   10	   0.31777557100298
// Sync pulse	   2	   0.063555114200596
// Back porch	   33	   1.0486593843098
// Whole frame	   525   16.683217477656
//
//       <--------- whole ------------------------->
//                         visible area
//                       ++++++++++++++++
//             back porch                front porch
//  ----|    |-------------------------------------|   |------
//      |    |                                     |   |
//      |____|                                     |___|
//        \
//       sync Pulse
//
//
//
// registri video controlera
// INDEX REGISTER
// 0 - status
// 1 - data wire
// 2 - cursor addr (for write char) pos low
// 3 - cursor addr (for write char) pos high
// 4 - control
//-----------------------------------------------------------------------------

//`define DEBUG

`include "vga_config.vh"
//`define VGA80x25 // font 8x16
//`define VGA64x30 // font 8x16
//`define VGA64x60 // font 8x8 - OFF

module vga_top
(
    input  wire i_clk,

`ifdef VGA_CMD_PORT
    input  wire [7:0]  i_cmd,     // CMD
	input  wire [10:0] i_cur_adr, // cursor adres
	input  wire [7:0]  i_port,    // port data
	output wire [7:0]  o_port,    // port data
	input  wire        i_cs_h,    // chip select, for I/O port*
	input  wire        i_rl_wh,   // if =0 then RE, if =1 then WE.
	output wire        o_ready_h, // controler gotov
`endif

`ifdef VGA_DMA_PORT
    input  wire [10:0] i_vram_addr_wr,       // bus adr video ram
    input  wire [7:0]  i_vram_data_wr,       // bus data video ram
    input  wire        i_vram_wr_h,          // strobe write data to mem
 
    input  wire [10:0] i_cursor_addr,        // set cursor position
    input  wire        i_cursor_en,          // cursor enable/disable
`endif

// VGA analog output-------------------------------------------------
	output wire o_hs,
	output wire o_vs,
	output wire o_video
);

`ifdef VGA80x25
localparam VGA_TEXT_RES_X_MAX = 8'd80;  // kolichestvo simvolov po X
localparam VGA_TEXT_RES_Y_MAX = 8'd25;  // kolichestvo simvolov po Y
`endif

`ifdef VGA64x30
localparam VGA_TEXT_RES_X_MAX = 8'd64;  // kolichestvo simvolov po X
localparam VGA_TEXT_RES_Y_MAX = 8'd30;  // kolichestvo simvolov po Y
`endif

//`ifdef VGA64x60
//localparam VGA_TEXT_RES_X_MAX = 8'd64;  // kolichestvo simvolov po X
//localparam VGA_TEXT_RES_Y_MAX = 8'd60;  // kolichestvo simvolov po Y
//`endif


reg hs = 1;               // signali synchonizachii
reg vs = 1;

reg hs_en_h = 0;          // enable module HS

reg [18:0] vs_c  = 0;     // counter for Vertical Sync
reg [9:0] hs_c   = 0;     // counter for Horizontal Sync

reg hs_str_en_h  = 0;     // string active Enable 
reg hs_str_start = 0;     // strob string active start
reg hs_str_stop  = 0;     // strob string active stop

wire c_x_clr_h;
wire c_x_en_h;
reg [14:0] c_x   = 0;     // max X 640

wire c_y_clr_h;
wire c_y_en_h;
reg [8:0] c_y    = 0;     // max Y 480

reg [3:0] st_char = 0;
reg vr_re_h       = 0;
reg cr_re_h       = 0;
reg shreg_en_h    = 0;

wire wr_pos;
wire [10:0] start_vram_addr;
wire [10:0] vram_addr;
wire [7:0] vram_data;        // data read from Video ram buffer
wire [7:0] data_rom;         // data read from ROM FONT
wire tic8_en;                // pulse 1 tic na 8 clk

wire cur_out_en_h;           // strob CURSOR enable to screen
wire cur_cmp_ok_h;           // strob coordinate cursor = output char to pos screen 

wire [10:0] cursor_addr;     // tekushee poloshenie cursora

wire [10:0] vram_addr_wr;    // hina zapisi v video ram
wire [7:0] vram_data_wr;
wire vram_wr_h;
wire cursor_en;     // signal cursor enable from register control

//-----------------------------------------------------------------------------
// video rom (font 8x16 pixel)
//-----------------------------------------------------------------------------
vga_rom_font FONT_ROM (
    .i_clk(  i_clk),

`ifdef VGA80x25
    .i_addr( { vram_data, c_y[3:0] } ),
`endif

`ifdef VGA64x30
    .i_addr( { vram_data, c_y[3:0] } ),
`endif

//`ifdef VGA64x60
//    .i_addr( {1'b0, vram_data, c_y[2:0] } ),
//`endif

	 //.i_addr( vram_addr[11:0] ),// temp for test
    .o_data( data_rom)
);

//-----------------------------------------------------------------------------
// Video ram 
//-----------------------------------------------------------------------------
vga_ram_video_buf VRAM 
(
    .i_clk     ( i_clk        ),
    .i_d_we    ( vram_data_wr ),
    .i_addr_we ( vram_addr_wr ),
	.i_we_en_h ( vram_wr_h    ),

	.i_addr_re ( vram_addr[10:0] ),
	.i_re_en_h ( c_x_en_h     ),
	.o_d_re    ( vram_data    )
);

//-----------------------------------------------------------------------------
// Shift register, out 8 pixel to monitor
//-----------------------------------------------------------------------------
`ifdef VGA80x25
vga_shift_reg_8bit SHIFT_REG
(
    .i_clk  ( i_clk    ),
    .i_cs_h ( c_x_en_h ),      // chip select
    .i_data ( (cur_cmp_ok_h & cur_out_en_h & cursor_en) ? 8'hff : data_rom), // Vhodnie danie
    .i_ld_h ( tic8_en  ),      // load data to shift reg
    .o_data ( o_video  )       // output date
);
`endif

`ifdef VGA64x30
vga_shift_reg_10bit SHIFT_REG
(
    .i_clk  ( i_clk    ),
	.i_cs_h ( c_x_en_h ),      // chip select
	.i_data ( (cur_cmp_ok_h & cur_out_en_h & cursor_en) ? 8'hff : data_rom), // Vhodnie danie
	.i_ld_h ( tic8_en  ),      // load data to shift reg
	.o_data ( o_video  )       // output date
);
`endif

//`ifdef VGA64x60
//vga_shift_reg_10bit SHIFT_REG (
//    .i_clk(   i_clk ),
//	 .i_cs_h(  c_x_en_h ),       // chip select
//	 .i_data(  (cur_cmp_ok_h & cur_out_en_h & cursor_en) ? 8'hff : data_rom),      // Vhodnie danie
//	 .i_ld_h(  tic8_en ),        // load data to shift reg
//	 .o_data(  o_video )         // output date
//);
//`endif

//-----------------------------------------------------------------------------
// Signal kursor blinking
//-----------------------------------------------------------------------------
vga_cursor_blinking
#(
    .CUR_COUNT_VS(30)        // Colichestvo kadorv na kotorih viden Cursor
)
CUR_TGL
(
    .i_clk      ( i_clk        ),
    .i_vs_h     ( vs           ), // virtikal syncro
    .o_cur_en_h ( cur_out_en_h )  // cursor enable
);

//-----------------------------------------------------------------------------
// Signal vivoda kursora = pri sovpadenie tekushego polocheniya kursora i vivodimogo znaka mesta
//-----------------------------------------------------------------------------
vga_cmp_cursor_coordinate CMP_CUR_COOR
(
    .i_clk           ( i_clk           ),
	.i_cur_pos_addr  ( cursor_addr     ),  // tekushee poloshenie kursora
	.i_out_addr_char ( vram_addr[10:0] ),  // tekushe poloshenie vivoda simvola
	.o_cmp_ok_h      ( cur_cmp_ok_h    )
);

//-----------------------------------------------------------------------------
// Avtomat video controlera I/O data - controls - status
//-----------------------------------------------------------------------------
`ifdef VGA_CMD_PORT
vga_port_io 
#(
    .RES_X_MAX ( VGA_TEXT_RES_X_MAX ),
    .RES_Y_MAX ( VGA_TEXT_RES_Y_MAX )
)
PORT_IO
(
    .i_clk     ( i_clk     ),
    .i_cmd     ( i_cmd     ),
    .i_cur_adr ( i_cur_adr ),
    .i_port    ( i_port    ),
    .o_port    ( o_port    ),
    .i_cs_h    ( i_cs_h    ),
    .i_rl_wh   ( i_rl_wh   ),
    .o_ready_h ( o_ready_h ),

    .vram_addr ( vram_addr_wr ),
    .vram_data ( vram_data_wr ),
    .vram_we_h ( vram_wr_h    ),
 
    .cursor_cur_addr ( cursor_addr ),
    .cursor_enable_h ( cursor_en   )
);
`endif

`ifdef VGA_DMA_PORT
assign vram_addr_wr = i_vram_addr_wr;
assign vram_data_wr = i_vram_data_wr;
assign vram_wr_h    = i_vram_wr_h;
assign cursor_addr  = i_cursor_addr;
assign cursor_en    = i_cursor_en;
`endif

//-----------------------------------------------------------------------------
// couter X
//-----------------------------------------------------------------------------
always @(posedge i_clk)
begin
    if (c_x_clr_h)
        c_x <= 0;
    else begin if (c_x_en_h)
        c_x <= c_x + 1'b1;
    end
end

//-----------------------------------------------------------------------------
// counter Y
//-----------------------------------------------------------------------------
always @(posedge i_clk)
begin
    if (c_y_clr_h)
        c_y <= 0;
    else begin
        if (c_y_en_h) c_y <= c_y + 1'b1;
    end
end

//-----------------------------------------------------------------------------
// Generated VS Timing
//-----------------------------------------------------------------------------
always @(posedge i_clk)
begin
    case (vs_c)
    0:                           // pulse vs = 0 Active
    begin
        vs <= 0;
	    vs_c <= vs_c + 1'b1;
    end
 
    1600-1:                      // pulse vs = 1 De-Active
    begin
        vs <= 1;
	    vs_c <= vs_c + 1'b1;
    end

`ifdef VGA80x25
    24800-1+32000: // -40 strok FOR XXx25 strok !
`endif

`ifdef VGA64x30
    24800-1:
`endif

//`ifdef VGA64x60
//	 24800-1:
//`endif
    begin
        hs_en_h <= 1;            // enable HS module
        vs_c <= vs_c + 1'b1;
    end

`ifdef VGA80x25
	408800-1-32000: // -40 strok FOR XXx25 strok !
`endif

`ifdef VGA64x30
    408800-1:
`endif

//`ifdef VGA64x60
//	 408800-1:
//`endif
    begin
        hs_en_h <= 0;            // disable HS module
	    vs_c <= vs_c + 1'b1;
    end

    416800-1:                    // period VS
    begin
        vs_c <= 0;
    end
	 
    default: vs_c <= vs_c + 1'b1;
 
    endcase
end

//-----------------------------------------------------------------------------
// Generate HS Timing
//-----------------------------------------------------------------------------
always @(posedge i_clk)
begin
    case (hs_c)
    0:                         // HS=0 ACTIVE
    begin
        hs <= 0;
        hs_c <= hs_c + 1'b1;
    end

    96-1:                      // HS=1 DE-ACTIVE
    begin
        hs <= 1;
        hs_c <= hs_c + 1'b1;
    end

    144-1:                     // start ACTIVE string + pulse counter string ON
    begin
        hs_str_en_h <= 1'b1 & hs_en_h;
        hs_str_start <= 1'b1 & hs_en_h;
        hs_c <= hs_c + 1'b1;
    end
		  
    145-1:                     // pulse counter string OFF
    begin
        hs_str_start <= 0;
        hs_c <= hs_c + 1'b1;
    end

`ifdef VGA80x25
    784-1+8:                     // stop ACTIVE string
`endif
`ifdef VGA64x30
    784-1+10:                     // stop ACTIVE string
`endif
//`ifdef VGA64x60
//		  784-1+10:                     // stop ACTIVE string
//`endif
    begin
        hs_str_en_h <= 0;
        hs_str_stop <= 1'b1 & hs_en_h;
        hs_c <= hs_c + 1'b1;
    end

`ifdef VGA80x25
    784+8:
`endif
`ifdef VGA64x30
    784+10:
`endif
//`ifdef VGA64x60
//		  784+10:
//`endif
    begin
        hs_str_stop <= 0;
        hs_c <= hs_c + 1'b1;
    end

    800-1:
    begin
        hs_c <= 0;
    end

    default: hs_c <= hs_c + 1'b1;
	endcase
end

`ifdef VGA80x25
vga_tic_8 TIC8
(
    .i_clk  ( i_clk       ),
    .i_en_h ( hs_str_en_h ),
    .o_t_h  ( tic8_en     )
);
`endif

`ifdef VGA64x30
vga_tic_10 TIC10
(
    .i_clk  ( i_clk       ),
    .i_en_h ( hs_str_en_h ),
    .o_t_h  ( tic8_en     )
);
`endif

//`ifdef VGA64x60
//vga_tic_10 TIC10(
//    .i_clk(  i_clk ),
//    .i_en_h( hs_str_en_h ),
//    .o_t_h(  tic8_en )
//);
//`endif

vga_avt_read_vram 
#(
    .RES_X_MAX ( VGA_TEXT_RES_X_MAX ),
    .RES_Y_MAX ( VGA_TEXT_RES_Y_MAX )
)
A_R_VRAM
(
    .i_clk  ( i_clk           ),
    .i_en   ( hs_str_stop     ),
    .o_wr_h ( wr_pos          ),
    .o_pos  ( start_vram_addr )
);

vga_vram_pos VRAM_POS
(
    .i_clk     ( i_clk           ),
    .i_ld_h    ( wr_pos          ),
    .i_en_h    ( tic8_en         ),
    .i_ld_data ( start_vram_addr ),
    .o         ( vram_addr       )
);


assign o_hs = hs;
assign o_vs = vs;

assign c_x_clr_h = ~ hs;   // obnulaem chetctiki
assign c_y_clr_h = ~ vs;
assign c_x_en_h = hs_str_en_h;
assign c_y_en_h = hs_str_stop;

endmodule

