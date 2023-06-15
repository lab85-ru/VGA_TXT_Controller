//-----------------------------------------------------------------------------
// avtomat port I/O
//-----------------------------------------------------------------------------
module vga_port_io 
#(
    parameter RES_X_MAX = 8'd80,
	parameter RES_Y_MAX = 8'd25
)

(
    input  wire i_clk,
	
    input  wire [7:0]  i_cmd,        // CMD
	input  wire [11:0] i_cur_adr,    // cursor adres
	input  wire [7:0]  i_port,       // input DATA
	output wire [7:0]  o_port,       // output DATA
	input  wire        i_cs_h,       // chip select
	input  wire        i_rl_wh,      // read=0, write=1
	output wire        o_ready_h,    // cntr = READY
	
	output reg [11:0]  vram_addr,
	output reg [7:0]   vram_data,
	output reg         vram_we_h,
	
    output wire [11:0] cursor_cur_addr,
	output wire        cursor_enable_h
);

initial
begin
    vram_addr = 0;
	vram_data = 0;
	vram_we_h = 0;
end

reg [2:0] st      = 0;  // avtomat state
reg [7:0] cmd     = 0;  // cmd
reg [7:0] pd      = 0;  // data port data
reg [7:0] data_io = 0;

// registri video controlera --------------------------------------------------
	// 0 - status
	// 1 - data write
	// 2 - cursor addr (for write char) pos low
	// 3 - cursor addr (for write char) pos high
// 4 - control
localparam REG_STATUS  = 8'h00;
localparam REG_DATA    = 8'h01;
localparam REG_CUR_AL  = 8'h02;
localparam REG_CUR_AH  = 8'h03;
localparam REG_CONTROL = 8'h04;

// REG_STATUS (bits)
localparam BIT_READY_H      = 8'h01;   // bit gotovnost, rezultat vipolneniya posledney komandi 

// REG_CONTROL (bits)
localparam BIT_CUR_ENABLE_H = 8'h01;   // bit viklucheniya kursora

reg [11:0] reg_cur_addr_pos = 0;      // vga register: cursor addr position
reg [7:0]  reg_status       = 8'ha0 | BIT_READY_H;  // vga register: status
reg [7:0]  reg_control      = BIT_CUR_ENABLE_H;  // vga register control

// registri video controlera --------------------------------------------------

always @(posedge i_clk)
begin
    case (st)
		0:
		begin
			if (i_cs_h) begin
				//synopsys translate_off
				$display("rtl: VGA CMD = 0x%X", i_cmd);
				//synopsys translate_on
				cmd <= i_cmd;
				st  <= st + 1'b1;
				reg_status[ BIT_READY_H ] <= 0;
			end else 
                reg_status[ BIT_READY_H ] <= 1; // vontrolleer READY for new command
		end
		
		1:
		begin
			if (i_rl_wh == 0) begin //read -----------------------------------------------------
				//synopsys translate_off
				$display("rtl: VGA read.");
				//synopsys translate_on
				
				case (cmd)
					REG_STATUS:  data_io <= reg_status;                        // status
					REG_DATA:    data_io <= 8'b1111_1111;                      // data wire, read= ff
					REG_CUR_AL:  data_io <= reg_cur_addr_pos[7:0];             // addr low
					REG_CUR_AH:  data_io <= {4'b0000, reg_cur_addr_pos[11:8]}; // addr high
					REG_CONTROL: data_io <= reg_control;                       // control
					default:     data_io <= 8'hee;                             // return ERROR
				endcase
				st <= 0; 
				
			end else begin  // write -----------------------------------------------------------
				//synopsys translate_off
				$display("rtl: VGA write.");
				//synopsys translate_on
				
				case (cmd)
					/*
						REG_STATUS:
						begin
						reg_status <= i_port;
						st <= 0;
						end
					*/					 
					REG_DATA:    // write to ext memory
					begin
						//synopsys translate_off
						$display("rtl: VGA Write data = 0x%X", i_port);
						//synopsys translate_on
						pd <= i_port;
						st <= st + 1'b1;
					end
					
					REG_CUR_AL, REG_CUR_AH:
					begin
						reg_cur_addr_pos <= i_cur_adr;
						//synopsys translate_off
						$display("rtl: VGA reg_cur_addr_pos = 0x%X i_cur_adr = 0x%X", reg_cur_addr_pos, i_cur_adr);
						//synopsys translate_on
			    		st <= 0;
					end 
					
					REG_CONTROL:
					begin
				    	//synopsys translate_off
					    $display("rtl: VGA write control = 0x%X", i_port);
					    //synopsys translate_on
					    reg_control <= i_port;
					    st <= 0;
					end
					
					default:
					begin
					    //synopsys translate_off
					    $display("rtl: VGA error CMD = 0x%X", cmd);
					    //synopsys translate_on
					    st <= 0;
					end
					
				endcase // ---------------------------
			end
		end
					
		2:
		begin
			//synopsys translate_off
			$display("rtl: VGA reg_cur_addr_pos = %d", reg_cur_addr_pos);
			//synopsys translate_on
			vram_addr <= reg_cur_addr_pos;
			vram_data <= pd;
			vram_we_h <= 1;
			reg_cur_addr_pos <= reg_cur_addr_pos + 1'b1;
			st <= st + 1'b1;
		end
					
		3:
		begin
			vram_we_h <= 0;
			if (reg_cur_addr_pos == RES_X_MAX * RES_Y_MAX) reg_cur_addr_pos <= 0;
			st <= 0;
		end
					
		default:
		begin
			st <= 0;
		end
					
	endcase
					
end
					
assign cursor_cur_addr = reg_cur_addr_pos;
assign o_ready_h       = reg_status[ BIT_READY_H ];
assign o_port          = data_io;
assign cursor_enable_h = reg_control[ BIT_CUR_ENABLE_H ];

endmodule
