//-----------------------------------------------------------------------------
// avtomat port I/O
//-----------------------------------------------------------------------------
module vga_port_io 
(
    input  wire        i_clk,
	
    input  wire [7:0]  i_cmd,         // CMD
	input  wire [10:0] i_cursor_addr, // cursor adres
	input  wire [7:0]  i_port,        // input DATA
	output wire [7:0]  o_port,        // output DATA
	input  wire        i_cs_h,        // chip select
	input  wire        i_rl_wh,       // read=0, write=1
	output wire        o_ready_h,     // cntr = READY
	
    // Video RAM
	output wire [10:0] o_vram_addr,
	output wire [7:0]  o_vram_data,
	output wire        o_vram_we_h,

    // Color Attribute RAM
	output wire [10:0] o_cram_addr,
	output wire [7:0]  o_cram_data,
	output wire        o_cram_we_h,
	
    output wire [10:0] o_cursor_addr,
	output wire        o_cursor_enable_h
);

`include "vga_config.vh"

`ifdef VGA64x30
    localparam RES_X_MAX = 8'd64;
    localparam RES_Y_MAX = 8'd30;
`endif

`ifdef VGA80x25
    localparam RES_X_MAX = 8'd80;
    localparam RES_Y_MAX = 8'd25;
`endif

reg        ready = 1;

reg [10:0] vram_addr = 0;
reg [7:0]  vram_data = 0;
reg        vram_we_h = 0;

reg [10:0] cram_addr = 0;
reg [7:0]  cram_data = 0;
reg        cram_we_h = 0;

reg [7:0]  reg_color_attr  = 8'b0_000_0_111; // Color attribute register (default char white RGB = ON)
//  7 6 5 4 3 2 1 0
//  M B G R - B G R
//  | | | | | | | |
//  | | | | | | | +-- CHAR COLOR RED
//  | | | | | | +---- CHAR COLOR GREEN
//  | | | | | +------ CHAR COLOR BLUE
//  | | | | +-------- clear
//  | | | +---------- background RED
//  | | +------------ background GREEN
//  | +-------------- background BLUE
//  +---------------- CHAR BLINK

	
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
// 5 - set color + attributes
localparam REG_STATUS  = 8'h00;
localparam REG_DATA    = 8'h01;
localparam REG_CUR_AL  = 8'h02;
localparam REG_CUR_AH  = 8'h03;
localparam REG_CONTROL = 8'h04;
localparam REG_COLOR   = 8'h05;

// REG_STATUS (bits)
localparam REG_STATUS_BIT_READY_MASK = 8'h01; // bit ready, MASK
localparam REG_STATUS_BIT_READY_POS  = 8'h00; // bit ready, Bit position

// REG_CONTROL (bits)
localparam REG_CONTROL_BIT_CURSOR_EN_MASK = 8'h01; // bit cursor enable/disable, MASK
localparam REG_CONTROL_BIT_CURSOR_EN_POS  = 8'h00; // bit cursor enable/disable, Bit position

reg [10:0] reg_cursor_addr = 0;      // vga register: cursor addr position
reg [7:0]  reg_status      = 8'ha0 | REG_STATUS_BIT_READY_MASK;  // vga register: status - set ready
reg [7:0]  reg_control     = REG_CONTROL_BIT_CURSOR_EN_MASK;     // vga register control

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
				ready <= 0;
			end else 
                ready <= 1; // controller READY
		end
		
		1:
		begin
			if (i_rl_wh == 0) begin //read -----------------------------------------------------
				//synopsys translate_off
				$display("rtl: VGA Operation Read.");
				//synopsys translate_on

				case (cmd)
					REG_STATUS:  data_io <= reg_status;                        // status
					REG_DATA:    data_io <= 8'b1111_1111;                      // data wire, read= ff
					REG_CUR_AL:  data_io <= reg_cursor_addr[7:0];              // addr low
					REG_CUR_AH:  data_io <= {5'b00000, reg_cursor_addr[10:8]}; // addr high
					REG_CONTROL: data_io <= reg_control;                       // control
					default:     data_io <= 8'hee;                             // return ERROR
				endcase
				st <= 0; 
				
			end else begin  // write -----------------------------------------------------------
				//synopsys translate_off
				$display("rtl: VGA Operation Write.");
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
						reg_cursor_addr <= i_cursor_addr;
						//synopsys translate_off
						$display("rtl: VGA reg_cursor_addr = 0x%X", i_cursor_addr);
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
					
					REG_COLOR:
					begin
				    	//synopsys translate_off
					    $display("rtl: VGA write Color = 0x%X", i_port);
					    //synopsys translate_on
					    reg_color_attr <= i_port;
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
			$display("rtl: VGA reg_cursor_addr = %d", reg_cursor_addr);
			//synopsys translate_on
			vram_addr <= reg_cursor_addr;
			vram_data <= pd;
			vram_we_h <= 1;

			cram_addr <= reg_cursor_addr;
			cram_data <= reg_color_attr;
			cram_we_h <= 1;

			reg_cursor_addr <= reg_cursor_addr + 1'b1;
			st <= st + 1'b1;
		end
					
		3:
		begin
			vram_we_h <= 0;
			cram_we_h <= 0;
			if (reg_cursor_addr == RES_X_MAX * RES_Y_MAX) reg_cursor_addr <= 0;
			st <= 0;
		end
					
		default:
		begin
			st <= 0;
		end
					
	endcase
					
end

					
assign o_ready_h         = ready;
assign o_port            = data_io;
assign o_cursor_addr     = reg_cursor_addr;
assign o_cursor_enable_h = reg_control[ REG_CONTROL_BIT_CURSOR_EN_POS ];

assign o_vram_addr = vram_addr;
assign o_vram_data = vram_data;
assign o_vram_we_h = vram_we_h;

assign o_cram_addr = cram_addr;
assign o_cram_data = cram_data;
assign o_cram_we_h = cram_we_h;

endmodule
