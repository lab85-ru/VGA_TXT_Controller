//-----------------------------------------------------------------------------
// rom font (Znako generator)
//-----------------------------------------------------------------------------
module vga_rom_font
(
    input wire i_clk,
    input wire [11:0] i_addr,      // Address input
    output wire [7:0] o_data        // Data output
);

//rom_1 RFONT(
//	.address(i_addr),
//	.clock(i_clk),
//	.q(o_data)
//);

/*
rom RFONT(
  .clka(i_clk),
  .addra(i_addr),
  .douta(o_data)
);
*/

// GoWin -------------------
rom RFONT(
    .dout  ( o_data ),
    .clk   ( i_clk  ),
    .oce   ( 1'b1   ),
    .ce    ( 1'b1   ),
    .reset ( 1'b0   ),
    .ad    ( i_addr )
);

 
endmodule

