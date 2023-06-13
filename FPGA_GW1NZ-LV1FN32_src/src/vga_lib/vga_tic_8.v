//-----------------------------------------------------------------------------
	//counter 8 tick (80x25)
//-----------------------------------------------------------------------------
module vga_tic_8
(
    input wire i_clk,
	input wire i_en_h,
	output wire o_t_h
);

reg [2:0] q = 0;
reg t = 0;

always @(posedge i_clk)
begin
    if (i_en_h) begin
        if (q == 7) begin
            q <= 0;
            t <= 1;
		end else begin
            q <= q + 1'b1;
            t <= 0;
		end
	end else begin
	    q <= 0;
		t <= 0;
	end
end

assign o_t_h = t;

endmodule
