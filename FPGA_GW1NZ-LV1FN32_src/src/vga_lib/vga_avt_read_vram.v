//-----------------------------------------------------------------------------
// avtomat lineynogo chetiniya ram
//-----------------------------------------------------------------------------
`include "vga_config.vh"

module vga_avt_read_vram 
#(
    parameter RES_X_MAX = 8'd80,
    parameter RES_Y_MAX = 8'd25
)
(
    input  wire        i_clk,
	input  wire        i_en,
	output reg         o_wr_h,
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
			
//`ifdef VGA80x25
// for VGA80x25 and VGA64x30
			if (c == 16) begin
//`endif
//`ifdef VGA64x30
//		      if (c == 16) begin
//`endif
//`ifdef VGA64x60
//		      if (c == 8) begin
//`endif
				
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
