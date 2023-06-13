//-----------------------------------------------------------------------------
// counter vram position
//-----------------------------------------------------------------------------
module vga_vram_pos
(
    input  wire        i_clk,
	input  wire        i_ld_h,
	input  wire        i_en_h,
	input  wire [11:0] i_ld_data,
	output wire [11:0] o
);

reg [11:0] q = 0;

always @(posedge i_clk)
begin
    if (i_ld_h == 1) begin
		q <= i_ld_data;
	end else if (i_en_h) begin
		q <= q + 1'b1;
	end
end

assign o = q;

endmodule
