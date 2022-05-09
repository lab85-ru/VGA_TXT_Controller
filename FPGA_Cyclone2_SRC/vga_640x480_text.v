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

//
`define VGA80x25 // font 8x16
//`define VGA64x30 // font 8x16
//`define VGA64x60 // font 8x8

module vga_640x480_text (
    input wire i_clk,
	 
    input wire [7:0] i_cmd,             // CMD
	 input wire [11:0] i_cur_adr,        // cursor adres
	 input wire [7:0] i_port,            // port data
	 output wire [7:0] o_port,           // port data
	 input wire i_cs_h,                  // chip select, for I/O port*
	 input wire i_rl_wh,                 // if =0 then RE, if =1 then WE.
	 output wire o_ready_h,              // controler gotov
	 
	 output wire o_hs,
	 output wire o_vs,
	 output wire o_video
	 
`ifdef DEBUG	 
	 ,
	 output wire [11:0] v_addr,          // video ram inteface for test write
	 output wire [7:0] v_data,
	 output wire v_we,
	 
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
    output wire [11:0] start_vram_addr_,
    output wire [11:0] vram_addr_,
	 output wire t8,
	 output wire [7:0] o_data_rom,
	 output wire o_cur_out_en_h
`endif
);

`ifdef VGA80x25
localparam VGA_TEXT_RES_X_MAX = 8'd80;  // kolichestvo simvolov po X
localparam VGA_TEXT_RES_Y_MAX = 8'd25;  // kolichestvo simvolov po Y
`endif

`ifdef VGA64x30
localparam VGA_TEXT_RES_X_MAX = 8'd64;  // kolichestvo simvolov po X
localparam VGA_TEXT_RES_Y_MAX = 8'd30;  // kolichestvo simvolov po Y
`endif

`ifdef VGA64x60
localparam VGA_TEXT_RES_X_MAX = 8'd64;  // kolichestvo simvolov po X
localparam VGA_TEXT_RES_Y_MAX = 8'd60;  // kolichestvo simvolov po Y
`endif


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
wire [11:0] start_vram_addr;
wire [11:0] vram_addr;
wire [7:0] vram_data;        // data read from Video ram buffer
wire [7:0] data_rom;         // data read from ROM FONT
wire tic8_en;                // pulse 1 tic na 8 clk

wire cur_out_en_h;           // strob CURSOR enable to screen
wire cur_cmp_ok_h;           // strob coordinate cursor = output char to pos screen 

wire [11:0] cursor_cur_addr; // tekushee poloshenie cursora

wire [11:0] vram_addr_wr;    // hina zapisi v video ram
wire [7:0] vram_data_wr;
wire vram_wr_h;
wire reg_control_cur_en;     // signal cursor enable from register control

//-----------------------------------------------------------------------------
// video rom (font 8x16 pixel)
//-----------------------------------------------------------------------------
rom_font FONT_ROM (
    .i_clk(  i_clk),

`ifdef VGA80x25
    .i_addr( { vram_data, c_y[3:0] } ),
`endif

`ifdef VGA64x30
    .i_addr( { vram_data, c_y[3:0] } ),
`endif

`ifdef VGA64x60
    .i_addr( {1'b0, vram_data, c_y[2:0] } ),
`endif

	 //.i_addr( vram_addr[11:0] ),// temp for test
    .o_data( data_rom)
);

//-----------------------------------------------------------------------------
// Video ram 
//-----------------------------------------------------------------------------
ram_video_buf VRAM (
    .i_clk(      i_clk ),
    .i_d_we(     vram_data_wr ),
    .i_addr_we(  vram_addr_wr ),
	 .i_we_en_h(  vram_wr_h ),
	 
	 .i_addr_re(  vram_addr[11:0] ),
	 .i_re_en_h(  c_x_en_h ),
	 .o_d_re(     vram_data )
);

//-----------------------------------------------------------------------------
// Shift register, out 8 pixel to monitor
//-----------------------------------------------------------------------------
`ifdef VGA80x25
shift_reg_8bit SHIFT_REG (
    .i_clk(   i_clk ),
	 .i_cs_h(  c_x_en_h ),       // chip select
	 .i_data(  (cur_cmp_ok_h & cur_out_en_h & reg_control_cur_en) ? 8'hff : data_rom),      // Vhodnie danie
	 .i_ld_h(  tic8_en ),        // load data to shift reg
	 .o_data(  o_video )         // output date
);
`endif

`ifdef VGA64x30
shift_reg_10bit SHIFT_REG (
    .i_clk(   i_clk ),
	 .i_cs_h(  c_x_en_h ),       // chip select
	 .i_data(  (cur_cmp_ok_h & cur_out_en_h & reg_control_cur_en) ? 8'hff : data_rom),      // Vhodnie danie
	 .i_ld_h(  tic8_en ),        // load data to shift reg
	 .o_data(  o_video )         // output date
);
`endif

`ifdef VGA64x60
shift_reg_10bit SHIFT_REG (
    .i_clk(   i_clk ),
	 .i_cs_h(  c_x_en_h ),       // chip select
	 .i_data(  (cur_cmp_ok_h & cur_out_en_h & reg_control_cur_en) ? 8'hff : data_rom),      // Vhodnie danie
	 .i_ld_h(  tic8_en ),        // load data to shift reg
	 .o_data(  o_video )         // output date
);
`endif

//-----------------------------------------------------------------------------
// Signal kursor blinking
//-----------------------------------------------------------------------------
cursor_blinking
#(
    .CUR_COUNT_VS(30)        // Colichestvo kadorv na kotorih viden Cursor
)
CUR_TGL
(
    .i_clk(i_clk),
	 .i_vs_h(vs),             // virtikal syncro
	 .o_cur_en_h(cur_out_en_h)// cursor enable
);

//-----------------------------------------------------------------------------
// Signal vivoda kursora = pri sovpadenie tekushego polocheniya kursora i vivodimogo znaka mesta
//-----------------------------------------------------------------------------
cmp_cursor_coordinate CMP_CUR_COOR(
    .i_clk(i_clk),
	 .i_cur_pos_addr(cursor_cur_addr),     // tekushee poloshenie kursora
	 .i_out_addr_char( vram_addr[11:0] ),  // tekushe poloshenie vivoda simvola
	 .o_cmp_ok_h(cur_cmp_ok_h)
);

//-----------------------------------------------------------------------------
// Avtomat video controlera I/O data - controls - status
//-----------------------------------------------------------------------------
port_io 
#(
    .RES_X_MAX(VGA_TEXT_RES_X_MAX),
	 .RES_Y_MAX(VGA_TEXT_RES_Y_MAX)
)
PORT_IO(
    .i_clk(i_clk),
	 .i_cmd(i_cmd),
	 .i_cur_adr(i_cur_adr),
	 .i_port(i_port),
	 .o_port(o_port),
	 .i_cs_h(i_cs_h),
	 .i_rl_wh(i_rl_wh),
	 .o_ready_h(o_ready_h),
	 
	 .vram_addr(vram_addr_wr),
	 .vram_data(vram_data_wr),
	 .vram_we_h(vram_wr_h),
	 
    .cursor_cur_addr(cursor_cur_addr),
    .cursor_enable_h(reg_control_cur_en)
);

//-----------------------------------------------------------------------------
// couter X
//-----------------------------------------------------------------------------
always @(posedge i_clk)
begin
    if (c_x_clr_h)
	     c_x <= 0;
	 else begin
	     if (c_x_en_h)
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
	     if (c_y_en_h)
	         c_y <= c_y + 1'b1;
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

`ifdef VGA64x60
	 24800-1:
`endif

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

`ifdef VGA64x30
	 408800-1:
`endif

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
		  784-1:                     // stop ACTIVE string
`endif
`ifdef VGA64x30
		  784-1+10:                     // stop ACTIVE string
`endif
`ifdef VGA64x60
		  784-1+10:                     // stop ACTIVE string
`endif
		  begin
		      hs_str_en_h <= 0;
                      hs_str_stop <= 1'b1 & hs_en_h;
		      hs_c <= hs_c + 1'b1;
		  end

`ifdef VGA80x25
		  784:
`endif
`ifdef VGA64x30
		  784+10:
`endif
`ifdef VGA64x60
		  784+10:
`endif
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
tic_8 TIC8(
    .i_clk(  i_clk ),
    .i_en_h( hs_str_en_h ),
    .o_t_h(  tic8_en )
);
`endif

`ifdef VGA64x30
tic_10 TIC10(
    .i_clk(  i_clk ),
    .i_en_h( hs_str_en_h ),
    .o_t_h(  tic8_en )
);
`endif

`ifdef VGA64x60
tic_10 TIC10(
    .i_clk(  i_clk ),
    .i_en_h( hs_str_en_h ),
    .o_t_h(  tic8_en )
);
`endif

avt_read_vram 
#(
    .RES_X_MAX(VGA_TEXT_RES_X_MAX),
    .RES_Y_MAX(VGA_TEXT_RES_Y_MAX)
)
A_R_VRAM(
    .i_clk(   i_clk ),
	 .i_en(    hs_str_stop ),
	 .o_wr_h(  wr_pos ),
	 .o_pos(   start_vram_addr )
);

vram_pos VRAM_POS(
    .i_clk(      i_clk ),
	 .i_ld_h(     wr_pos ),
	 .i_en_h(     tic8_en ),
	 .i_ld_data(  start_vram_addr ),
	 .o(          vram_addr )
);


assign o_hs = hs;
assign o_vs = vs;

`ifdef DEBUG

assign t8 = tic8_en;
assign wr_pos_ = wr_pos;
assign start_vram_addr_ = start_vram_addr;
assign vram_addr_ = vram_addr;

assign hs_str_en_h_ = hs_str_en_h;
assign hs_str_start_ = hs_str_start;
assign hs_str_stop_ = hs_str_stop;

assign st_char_ = st_char;
assign vr_re_h_ = vr_re_h;
assign cr_re_h_ = cr_re_h;
assign shreg_en_h_ = shreg_en_h;

assign o_c_x_clr_h = c_x_clr_h;
assign o_c_x_en_h = c_x_en_h;
assign o_c_x = c_x;
assign o_c_y_clr_h = c_y_clr_h;
assign o_c_y_en_h = c_y_en_h;
assign o_c_y = c_y;

assign o_vram_data = vram_data;

assign o_data_rom = data_rom;
assign o_cur_out_en_h = cur_out_en_h;

assign v_addr = vram_addr_wr;
assign v_data = vram_data_wr;
assign v_we = vram_wr_h;

`endif

assign c_x_clr_h = ~ hs;   // obnulaem chetctiki
assign c_y_clr_h = ~ vs;
assign c_x_en_h = hs_str_en_h;
assign c_y_en_h = hs_str_stop;

endmodule


//-----------------------------------------------------------------------------
// rom font (Znako generator)
//-----------------------------------------------------------------------------
module rom_font (
    input wire i_clk,
    input wire [11:0] i_addr,      // Address input
    output wire [7:0] o_data        // Data output
);

rom_1 RFONT(
	.address(i_addr),
	.clock(i_clk),
	.q(o_data)
);
 
endmodule


//-----------------------------------------------------------------------------
// video buffer 80x30 byte
//-----------------------------------------------------------------------------
module ram_video_buf(
    input wire i_clk,
	 input wire [7:0] i_d_we,
	 input wire [11:0] i_addr_we,
	 input wire i_we_en_h,
	 
	 input wire [11:0] i_addr_re,
	 input wire i_re_en_h,
	 output wire [7:0] o_d_re
);

ram_1 RAM (
	.clock(i_clk),
	.data(i_d_we),
	.rdaddress(i_addr_re),
	.rden(i_re_en_h),
	.wraddress(i_addr_we),
	.wren(i_we_en_h),
	.q(o_d_re)
);

endmodule

//-----------------------------------------------------------------------------
//counter 8 tick (80x25)
//-----------------------------------------------------------------------------
module tic_8(
    input wire i_clk,
	 input wire i_en_h,
	 output wire o_t_h
);

reg [2:0] q = 0;
reg t = 0;

always @(posedge i_clk)
begin
    if (i_en_h) begin
        q <= q + 1'b1;
        if (q == 7) t <= 1;
	     else t <= 0;
	 end else begin
	     q <= 0;
		  t <= 0;
	 end
end
assign o_t_h = t;
endmodule

//-----------------------------------------------------------------------------
//counter 10 tick (64x25, 64x30)
//-----------------------------------------------------------------------------
module tic_10(
    input wire i_clk,
	 input wire i_en_h,
	 output wire o_t_h
);

reg [3:0] q = 0;
reg t = 0;

always @(posedge i_clk)
begin
    if (i_en_h) begin
        if (q == 9) begin
		      t <= 1;
				q <= 0;
	     end else begin
		      t <= 0;
				q <= q + 1'b1;
		  end
	 end else begin
	     q <= 0;
		  t <= 0;
	 end
end
assign o_t_h = t;
endmodule

//-----------------------------------------------------------------------------
// counter vram position
//-----------------------------------------------------------------------------
module vram_pos (
    input wire i_clk,
	 input wire i_ld_h,
	 input wire i_en_h,
	 input wire [11:0] i_ld_data,
	 output wire [11:0] o
);
reg [11:0] q = 0;

always @(posedge i_clk)
begin
    if (i_ld_h == 1) begin
	     q <= i_ld_data;
	 end else 
    if (i_en_h) begin
	     q <= q + 1'b1;
	 end
end

assign o = q;

endmodule

//-----------------------------------------------------------------------------
// avtomat lineynogo chetiniya ram
//-----------------------------------------------------------------------------
module avt_read_vram 
#(
    parameter RES_X_MAX = 8'd80,
	 parameter RES_Y_MAX = 8'd30
)
(
    input wire i_clk,
	 input wire i_en,
	 output reg o_wr_h,
	 output wire [11:0] o_pos
);
reg [2:0] st = 0;
reg [11:0] q = 0;
reg [4:0] c = 0;


always @(posedge i_clk)
begin
	     case (st)
		  0:
		  begin
		      if (i_en) begin
		          c <= c + 1'b1;
				    st <= st + 1'b1;
				end
		  end
		  
		  1:
		  begin
		  
`ifdef VGA80x25
		      if (c == 16) begin
`endif
`ifdef VGA64x30
		      if (c == 16) begin
`endif
`ifdef VGA64x60
		      if (c == 8) begin
`endif

				    c <= 0;
					 q <= q + RES_X_MAX;
				end
            st <= st + 1'b1;
		  end
		  
		  2:
		  begin
		      if (q == RES_X_MAX * RES_Y_MAX) // /* =14'd2400*/ 
				    q <= 0;
				st <= st + 1'b1;
		  end
		  
		  3:
		  begin
		      o_wr_h <= 1;
				st <= st + 1'b1;
		  end
		  
		  4:
		  begin
		      o_wr_h <= 0;
				st <= 0;
		  end
		  
		  endcase
end

assign o_pos = q;

endmodule

//-----------------------------------------------------------------------------
// shift register
// 10 bit - t.k. 2 bita zazor mehdu simvolami(font 8x16) inache simvoli skleivautsa
//-----------------------------------------------------------------------------
module shift_reg_10bit (
    input wire i_clk,
	 input wire i_cs_h,         // chip select
	 input wire [7:0] i_data,   // Vhodnie danie
	 input wire i_ld_h,         // load data to shift reg
	 output wire o_data         // output date
);
reg [9:0] shreg_d = 0;
reg o_d = 0;

always @(posedge i_clk)
begin
    if (i_cs_h) begin
	     if (i_ld_h) begin
		      shreg_d <= {i_data, 2'b00};
		  end else begin
	         o_d <= shreg_d[9];
		      shreg_d[9:0] <= { shreg_d[8:0], 1'b0};
		  end
	 end else begin
	     shreg_d <= 0;
		  o_d <= 0;
	 end
end

assign o_data = o_d;

endmodule

//-----------------------------------------------------------------------------
// shift register
// 8 bit
//-----------------------------------------------------------------------------
module shift_reg_8bit (
    input wire i_clk,
	 input wire i_cs_h,         // chip select
	 input wire [7:0] i_data,      // Vhodnie danie
	 input wire i_ld_h,         // load data to shift reg
	 output wire o_data            // output date
);
reg [7:0] shreg_d = 0;
reg o_d = 0;

always @(posedge i_clk)
begin
    if (i_cs_h) begin
	     if (i_ld_h) begin
		      shreg_d <= i_data;
		  end else begin
	         o_d <= shreg_d[7];
		      shreg_d[7:0] <= { shreg_d[6:0], 1'b0};
		  end
	 end else begin
	     shreg_d <= 0;
		  o_d <= 0;
	 end
end

assign o_data = o_d;

endmodule

//-----------------------------------------------------------------------------
// cursor Migaet
//-----------------------------------------------------------------------------
module cursor_blinking 
#(
    parameter CUR_COUNT_VS = 30    // cursor viden na 60 kadrah
)
(
    input wire i_clk,
	 input wire i_vs_h,        // virtikal syncro
	 output wire o_cur_en_h    // cursor enable
);

reg [1:0] st = 0;
reg [7:0] count = 0;
reg cur_en_h = 0;

always @(posedge i_clk)
begin
    case (st)
	 0:
	 begin
	     if (i_vs_h == 0) begin
		      count <= count + 1'b1;
				st <= st + 1'b1;
		  end
	 end

	 1:
	 begin
	     if (i_vs_h == 1) st <= st + 1'b1;
	 end
	 
	 2:
	 begin
	     if (count == CUR_COUNT_VS) begin
		      cur_en_h <= ~ cur_en_h;
				count <= 0;
		  end
		  st <= 0;
	 end
	 
	 endcase
end

assign o_cur_en_h = cur_en_h;

endmodule

//-----------------------------------------------------------------------------
// cursor coordinate compare
//-----------------------------------------------------------------------------
module cmp_cursor_coordinate(
    input wire i_clk,
	 input wire [11:0] i_cur_pos_addr,  // tekushee poloshenie kursora
	 input wire [11:0] i_out_addr_char,   // tekushe poloshenie vivoda simvola
	 output wire o_cmp_ok_h
);

reg cmp_ok_h;

always @(posedge i_clk)
begin
    if (i_cur_pos_addr == i_out_addr_char) cmp_ok_h <= 1;
	 else cmp_ok_h <= 0;
end

assign o_cmp_ok_h = cmp_ok_h;

endmodule

//-----------------------------------------------------------------------------
// avtomat port I/O
//-----------------------------------------------------------------------------
module port_io 
#(
    parameter RES_X_MAX = 8'd80,
	 parameter RES_Y_MAX = 8'd30
)

(
    input wire i_clk,

    input wire [7:0]  i_cmd,        // CMD
	 input wire [11:0] i_cur_adr,    // cursor adres
	 input wire [7:0]  i_port,       // input DATA
	 output wire [7:0] o_port,       // output DATA
	 input wire        i_cs_h,       // chip select
	 input wire        i_rl_wh,      // read=0, write=1
	 output wire       o_ready_h,    // cntr = READY
	 
	 output reg [11:0] vram_addr,
	 output reg [7:0]  vram_data,
	 output reg        vram_we_h,
	 
    output wire [11:0] cursor_cur_addr,
	 output wire       cursor_enable_h
);

initial
begin
    vram_addr = 0;
	 vram_data = 0;
	 vram_we_h = 0;
end

reg [2:0] st      = 0;  // avtomat state
reg [7:0] cmd     = 0;  // cmd
reg [7:0] pd      = 0;  // data port data
reg [7:0] data_io = 0;

// registri video controlera --------------------------------------------------
// 0 - status
// 1 - data write
// 2 - cursor addr (for write char) pos low
// 3 - cursor addr (for write char) pos high
// 4 - control
localparam REG_STATUS  = 8'h00;
localparam REG_DATA    = 8'h01;
localparam REG_CUR_AL  = 8'h02;
localparam REG_CUR_AH  = 8'h03;
localparam REG_CONTROL = 8'h04;

// REG_STATUS (bits)
localparam BIT_READY_H      = 8'h01;   // bit gotovnost, rezultat vipolneniya posledney komandi 

// REG_CONTROL (bits)
localparam BIT_CUR_ENABLE_H = 8'h01;   // bit viklucheniya kursora

reg [11:0] reg_cur_addr_pos = 0;      // vga register: cursor addr position
reg [7:0]  reg_status       = 8'ha0 | BIT_READY_H;  // vga register: status
reg [7:0]  reg_control      = BIT_CUR_ENABLE_H;  // vga register control

// registri video controlera --------------------------------------------------

always @(posedge i_clk)
begin
    case (st)
	 0:
	 begin
	     if (i_cs_h) begin
            //synopsys translate_off
            $display("VGA CMD = 0x%X", i_cmd);
            //synopsys translate_on
		      cmd <= i_cmd;
		      st  <= st + 1'b1;
				reg_status[ BIT_READY_H ] <= 0;
		  end else 
		      reg_status[ BIT_READY_H ] <= 1; // vontrolleer READY for new command
	 end

	 1:
	 begin
	     if (i_rl_wh == 0) begin //read -----------------------------------------------------
		    //synopsys translate_off
		    $display("VGA read.");
			 //synopsys translate_on
		  
    	     case (cmd)
	    	  REG_STATUS:  data_io <= reg_status;                        // status
		     REG_DATA:    data_io <= 8'b1111_1111;                      // data wire, read= ff
		     REG_CUR_AL:  data_io <= reg_cur_addr_pos[7:0];             // addr low
		     REG_CUR_AH:  data_io <= {4'b0000, reg_cur_addr_pos[11:8]}; // addr high
			  REG_CONTROL: data_io <= reg_control;                       // control
			  default:     data_io <= 8'hee;                             // return ERROR
		     endcase
			  st <= 0; 
		  end else begin  // write -----------------------------------------------------------
		    //synopsys translate_off
		    $display("VGA write.");
			 //synopsys translate_on

                case (cmd)
/*
				    REG_STATUS:
					 begin
					     reg_status <= i_port;
						  st <= 0;
					 end
*/					 
				    REG_DATA:    // write to ext memory
				    begin
					    //synopsys translate_off
					    $display("VGA Write data = 0x%X", i_port);
						 //synopsys translate_on
    		          pd <= i_port;
	   			    st <= st + 1'b1;
				    end
					 
				    REG_CUR_AL, REG_CUR_AH:
					 begin
					     reg_cur_addr_pos <= i_cur_adr;
						  //synopsys translate_off
						  $display("VGA reg_cur_addr_pos = 0x%X i_cur_adr = 0x%X", reg_cur_addr_pos, i_cur_adr);
						  //synopsys translate_on
						  st <= 0;
					 end 
					 
					 REG_CONTROL:
					 begin
						  //synopsys translate_off
						  $display("VGA write control = 0x%X", i_port);
						  //synopsys translate_on
					     reg_control <= i_port;
						  st <= 0;
					 end

					 default:
					 begin
						  //synopsys translate_off
						  $display("VGA error CMD = 0x%X", cmd);
						  //synopsys translate_on
						  st <= 0;
					 end
						 
				    endcase // ---------------------------
		  end
	 end
	 
	 2:
	 begin
	     //synopsys translate_off
	     $display("VGA reg_cur_addr_pos = %d", reg_cur_addr_pos);
		  //synopsys translate_on
        vram_addr <= reg_cur_addr_pos;
		  vram_data <= pd;
		  vram_we_h <= 1;
		  reg_cur_addr_pos <= reg_cur_addr_pos + 1'b1;
		  st <= st + 1'b1;
	 end
	 
	 3:
	 begin
	     vram_we_h <= 0;
	     if (reg_cur_addr_pos == RES_X_MAX * RES_Y_MAX) reg_cur_addr_pos <= 0;
	     st <= 0;
	 end
	 
	 default:
	 begin
		  st <= 0;
    end
 
	 endcase

end

assign cursor_cur_addr = reg_cur_addr_pos;
assign o_ready_h       = reg_status[ BIT_READY_H ];
assign o_port          = data_io;
assign cursor_enable_h = reg_control[ BIT_CUR_ENABLE_H ];

endmodule
