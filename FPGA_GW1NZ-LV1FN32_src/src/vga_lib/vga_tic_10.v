//-----------------------------------------------------------------------------
	//counter 10 tick (64x25, 64x30)
//-----------------------------------------------------------------------------
module vga_tic_10
(
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
