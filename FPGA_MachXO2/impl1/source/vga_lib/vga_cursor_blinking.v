
//-----------------------------------------------------------------------------
// cursor Migaet
//-----------------------------------------------------------------------------
module vga_cursor_blinking 
#(
    parameter CUR_COUNT_VS = 30    // cursor viden na 60 kadrah
)
(
    input  wire i_clk,
	input  wire i_vs_h,       // virtikal syncro
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
