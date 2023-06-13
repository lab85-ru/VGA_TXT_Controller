//-----------------------------------------------------------------------------
// cursor coordinate compare
//-----------------------------------------------------------------------------
module vga_cmp_cursor_coordinate(
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
