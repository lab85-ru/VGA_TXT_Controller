//-----------------------------------------------------------------------------
// video buffer 80x30 byte
//-----------------------------------------------------------------------------
module vga_ram_video_buf
(
    input wire i_clk,
	 input wire [7:0] i_d_we,
	 input wire [11:0] i_addr_we,
	 input wire i_we_en_h,
	 
	 input wire [11:0] i_addr_re,
	 input wire i_re_en_h,
	 output wire [7:0] o_d_re
);
/*
ram_1 RAM (
	.clock(i_clk),
	.data(i_d_we),
	.rdaddress(i_addr_re),
	.rden(i_re_en_h),
	.wraddress(i_addr_we),
	.wren(i_we_en_h),
	.q(o_d_re)
);
*/

/*
ram RAM(
  .clka(i_clk),
  .wea(i_we_en_h),
  .addra(i_addr_we),
  .dina(i_d_we),
  
  .clkb(i_clk),
  .addrb(i_addr_re),
  .doutb(o_d_re)
);
*/



//output [7:0] dout;
//input clka;
//input cea;
//input reseta;
//input clkb;
//input ceb;
//input resetb;
//input oce;
//input [10:0] ada;
//input [7:0] din;
//input [10:0] adb;


// GoWin -------------------
ram RAM(
  .reseta ( 1'b0      ),
  .resetb ( 1'b0      ),

  .clka   ( i_clk     ),
  .cea    ( i_we_en_h ),
  .ada    ( i_addr_we ),
  .din    ( i_d_we    ),
  
  .clkb   ( i_clk     ),
  .ceb    ( 1'b1      ),
  .oce    ( 1'b1      ),
  .adb    ( i_addr_re ),
  .dout   ( o_d_re    )
);

endmodule
