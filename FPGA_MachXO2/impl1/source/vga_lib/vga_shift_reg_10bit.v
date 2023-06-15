//-----------------------------------------------------------------------------
	// shift register
	// 10 bit - t.k. 2 bita zazor mehdu simvolami(font 8x16) inache simvoli skleivautsa
//-----------------------------------------------------------------------------
module vga_shift_reg_10bit
(
    input wire i_clk,
	input wire i_cs_h,         // chip select
	input wire [9:0] i_data,   // Vhodnie danie
	input wire i_ld_h,         // load data to shift reg
	output wire o_data         // output date
);
reg [9:0] shreg_d = 0;

always @(posedge i_clk)
begin
    if (i_cs_h) begin
		if (i_ld_h) begin
			shreg_d <= i_data;
		end else begin
			shreg_d[9:0] <= {shreg_d[8:0], 1'b0};
		end
	end
end

assign o_data = i_cs_h == 1 ? shreg_d[9] : 1'b0;

endmodule
