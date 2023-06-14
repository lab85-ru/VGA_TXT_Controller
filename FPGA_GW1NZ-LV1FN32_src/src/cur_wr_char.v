//-----------------------------------------------------------------------------
// cursor wire char to current position cursor.
//-----------------------------------------------------------------------------
module cur_wr_char (
    input wire i_clk,
	 output wire [7:0] o_cmd,
	 output wire [10:0] o_cursor_adr,
	 output wire [7:0] o_port,
	 output wire o_cs_h,
	 output wire o_rl_wh,
	 input wire i_ready_h 
);

reg [7:0]  cmd        = 0;
reg [10:0] cursor_adr = 0;
reg [24:0] st         = 0;
reg [7:0]  char       = 0;//8'h30;
reg [7:0]  port       = 0;
reg cs_h              = 0;
reg rl_wh             = 0;

localparam REG_STATUS  = 8'h00;
localparam REG_DATA    = 8'h01;
localparam REG_CUR_AL  = 8'h02;
localparam REG_CUR_AH  = 8'h03;
localparam REG_CONTROL = 8'h04;


always @(posedge i_clk)
begin
    case (st)
	 1000:
	 begin
	     cmd <= REG_CUR_AH;
	     cursor_adr <= 12'h000;        // cursor addr
//	     cursor_adr <= 12'h320;        // cursor addr
//	     cursor_adr <= 12'h040 + 256;  // cursor addr
		  cs_h <= 1;
		  rl_wh <= 1;
		  st <= st + 1'b1;
	 end
	 
	 1001:
	 begin
	     cs_h <= 0;
		  st <= st + 1'b1;
	 end
	 
	 1002:
	 begin
	     if (i_ready_h) st <= st + 1'b1;
	 end
	 
	 1003: // write data
	 begin
	     cmd <= REG_DATA;
		  port <= char;
		  cs_h <= 1;
		  rl_wh <= 1;
	     st <= st + 1'b1;    
	 end

	 1004:
	 begin
	     cs_h <= 0;
	     st <= st + 1'b1;    
	 end

	 1005:
	 begin
		  if (i_ready_h) st <= st + 1'b1;    
	 end

	 1006:
	 begin
	     char <= char + 1'b1;
	     st <= st + 1'b1;
	 end
	 
	 1007:
	 begin
	     if (char == 0) begin // stop
				st <= st + 1'b1;
		  end else st <= 1003; // next char
	 end
	 
	 // cursor disable ------------------------------------------
	 /*
	 1_000_002:
	 begin
	     cmd <= REG_CONTROL; // reg control
		  cs_h <= 1;
		  rl_wh <= 1;
	     st <= st + 1'b1;    
	 end
	 
	 1_000_003:
	 begin
	     cs_h <= 0;
	     st <= st + 1'b1;    
	 end

	 1_000_004:
	 begin
		  if (i_ready_h) st <= st + 1'b1;    
	 end
	 */
	 1_000_007:
	 begin
		  //if (i_ready_h) st <= st + 1'b1;    
		  //stop
	 end
	 	 
	 default:
	 begin
	     st <= st + 1'b1;
	 end

    endcase
end

assign o_port      = port;
assign o_cs_h      = cs_h;
assign o_rl_wh     = rl_wh;
assign o_cmd       = cmd;
assign o_cursor_adr = cursor_adr;

endmodule
