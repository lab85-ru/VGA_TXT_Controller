//-----------------------------------------------------------------------------
// module SPI controler for VGA
//
//
// Format SPI CMD-DATA:
//
//   7-0            7---H---0  7---L---0
// 8'hxx(cmd), 16'b xxxx_xxxx  xxxx_xxxx  (data)
//    CMD            data[1]    data[0]
// 
// (READ STATUS)  xxxx_xxxx  DATA
// 
// (WRITE STATUS) DATA
// 
// (READ CONTROL)  xxxx_xxxx DATA
// 
// (WRITE CONTROL) DATA
// 
// (WRITE CUR POS) pos_high  pos_low
// 
// (WRITE DATA)    DATA
// 
// (WRITE COLOR)   COLOR-DATA
// 
//-----------------------------------------------------------------------------

//`define DEBUG

module spi_contr(
    input wire i_clk,

	 output wire [7:0]  o_vga_cmd,            // command 
	 output wire [10:0] o_vga_cur_adr,        // set adr cursor
	 output wire [7:0]  o_vga_port,           // output port data
	 input wire  [7:0]  i_vga_port,           // input port data
	 output wire        o_vga_cs_h,           // chip select, for I/O port*
	 output wire        o_vga_rl_wh,          // if =0 then RE, if =1 then WE.
	 input wire         i_vga_ready_h,        // controler gotov
	 
	 input wire         i_spi_mosi,      // EXTERNAL i/o interface SPI
	 input wire         i_spi_cs,
	 input wire         i_spi_sck,
	 output wire        o_spi_miso

    ,
    output wire o_d
	 
`ifdef DEBUG
    ,
	 output wire        d_spi_cs,
	 output wire [7:0]  d_spi_i_data,
	 output wire [7:0]  d_spi_o_data,
	 output wire        d_spi_we,
	 output wire        d_spi_re,

	 output wire        d_spi_rx_ready,
	 output wire        d_spi_tx_ready,

	 output wire [5:0]  d_rx_bit_counter,
	 output wire [5:0]  d_tx_bit_counter,
	 output wire [7:0]  d_st
`endif	 
	 

);

// include VERSION this prj !
//`include "version.txt"

localparam JMP_W            = 5'd4;
localparam JMP_R            = 5'd14;
localparam JMP_WAIT_CS_HIGH = 5'd21;
reg [4:0] st = 0;


localparam CMD_R_STATUS  = 8'h00; // read status
localparam CMD_R_CONTROL = 8'h04; // read control
localparam CMD_R_CUR_AL  = 8'h02; // read cursor low adr 
localparam CMD_R_CUR_AH  = 8'h03; // read cursor high adr 

localparam CMD_W_STATUS  = 8'h80; // write to status
localparam CMD_W_CONTROL = 8'h84; // write to control
localparam CMD_W_DATA    = 8'h81; // write data to position cursor
localparam CMD_W_CUR_ADR = 8'h82; // write adress cursor
localparam CMD_W_COLOR   = 8'h85; // write color char + color background + blink


reg [7:0]  spi_cmd     = 0;  // SPI command 
reg [7:0]  vga_cmd     = 0;  // VGA command 
reg [10:0] vga_cur_adr = 0;  // set adr cursor
reg [7:0]  vga_oport   = 0;  // output port data
reg        vga_cs_h    = 0;  // chip select, for I/O port*
reg        vga_rl_wh   = 0;  // if =0 then RE, if =1 then WE.
reg [7:0]  vga_datah   = 0;  // data high
reg [7:0]  vga_datal   = 0;  // data low


// spi spi wires -------------------------------------------------------------
reg        spi_cs      = 0;
reg [7:0]  spi_i_data  = 0;
reg        spi_we      = 0;
reg        spi_re      = 0;

reg [3:0]  reg_spi_cs   = 0;

wire [7:0] spi_o_data;
wire       spi_tx_ready;
wire       spi_rx_ready;


spi_slave SPI_TO_spi
(
    .i_clk(        i_clk            ),
	 // i/o inteface
	 .i_cs(         spi_cs           ),
	 .i_data(       spi_i_data       ),
	 .o_data(       spi_o_data       ),
	 .i_we(         spi_we           ),  // read,  i/o inteface
	 .i_re(         spi_re           ),  // write, i/o inteface
	 .o_rx_error(                    ),  // perepolninie, ne zabrali danie, kak bili zagrusheni novie !
	 .o_rx_ready(   spi_rx_ready     ),
	 
	 .o_tx_error(                    ),  // error: popitka zapisi v spi ! 1-idet peredacha(zanat), 2-net gotovnosti spi
	 .o_tx_ready(   spi_tx_ready     ),
	 
	 // SPI slave interface
	 .i_spi_sck(    i_spi_sck    ),
	 .i_spi_cs_l(   i_spi_cs     ),
	 .i_spi_mosi(   i_spi_mosi   ),
	 .o_spi_miso(   o_spi_miso   )

`ifdef DEBUG	 
    ,
	 .d_rx_bit_counter(d_rx_bit_counter ),
//	 .d_rx_flag(    d_rx_flag           ),
	 .d_tx_bit_counter(d_tx_bit_counter )
//	 .d_tx_flag(    d_tx_flag           )
`endif	 
	 
);



// synchonizator for spi CS ------------------------------
always @(posedge i_clk)
begin
    reg_spi_cs[3:0] <= { reg_spi_cs[2:0], i_spi_cs };
end

always @(posedge i_clk)
begin
    case (st)
	 0: // start
	 begin
		  vga_rl_wh <= 0;
		  vga_cs_h  <= 0;
		  
	     st <= st + 1'b1;
	 end
	 
	 1:
	 begin
	     if (spi_rx_ready && reg_spi_cs[3] == 0) begin
		      st <= st + 1'b1;
		  end
	 end
	 
	 2:
	 begin
	     spi_cs <= 1;
		  spi_re <= 1;
		  spi_cmd <= spi_o_data;
		  st      <= st + 1'b1;
	 end
	 
	 3:
	 begin
	     spi_cs <= 0;
		  spi_re <= 0;
		  
	     //synopsys translate_off
		  $display("SPIC SPI_cmd = 0x%X", spi_cmd);
		  //synopsys translate_on

	     case (spi_cmd)
            CMD_W_STATUS, CMD_W_CONTROL, CMD_W_DATA, CMD_W_CUR_ADR, CMD_W_COLOR:
				begin
	             //synopsys translate_off
		          $display("SPIC JMP_W");
		          //synopsys translate_on
				    vga_cmd <= {1'b0, spi_cmd[6:0]};
				    st <= JMP_W;
				end
				
            CMD_R_CONTROL, CMD_R_STATUS, CMD_R_CUR_AL, CMD_R_CUR_AH:
				begin
	             //synopsys translate_off
		          $display("SPIC JMP_R");
		          //synopsys translate_on
				    vga_cmd <= {1'b0, spi_cmd[6:0]};
				    st <= JMP_R;
				end
				
				default:
				begin
				    // Неверная команда, ожидание окончания транзакции и игнор всего
				    st <= JMP_WAIT_CS_HIGH; //if ( reg_spi_cs[3] ) begin // wait perehod cs 0 => 1
				end
        endcase				
    end
	 
	 JMP_W + 0:
	 begin
	     if (reg_spi_cs[3] == 1) 
		      st <= 0;
	     else if (spi_rx_ready) begin
		          st <= st + 1'b1;
		  end
	 end
	 
	 JMP_W + 1:  // read 2-byte from SPI
	 begin
	     //synopsys translate_off
		  $display("SPIC SPI READ_H = 0x%X", spi_o_data);
		  //synopsys translate_on
	     spi_cs   <= 1;
		  spi_re   <= 1;
		  vga_datah <= spi_o_data;
		  st        <= st + 1'b1;
	 end
	 
	 JMP_W + 2:
	 begin
	     spi_cs <= 0;
		  spi_re <= 0;
		  if (spi_cmd == CMD_W_CUR_ADR)
		      st <= st + 1'b1;
		  else
		      st <= JMP_W + 4'd6; // wait CS -> 1
    end
		  
	 JMP_W + 3:
	 begin
	     if (reg_spi_cs[3] == 1) 
		      st <= 0;
	     else if (spi_rx_ready) begin
		          st <= st + 1'b1;
		  end
	 end

	 JMP_W + 4:  // read 2-byte from SPI
	 begin
	     //synopsys translate_off
		  $display("SPIC SPI READ_L = 0x%X", spi_o_data);
		  //synopsys translate_on
	     spi_cs    <= 1;
		  spi_re    <= 1;
		  vga_datal <= spi_o_data;
		  st        <= st + 1'b1;
	 end
	 
	 JMP_W + 5:
	 begin
	     spi_cs <= 0;
		  spi_re <= 0;
		  st     <= st + 1'b1;
    end

	 JMP_W + 6:  // wait CS 0___/---1
	 begin
	     if (reg_spi_cs[3] == 1) begin
            //synopsys translate_off
            $display("SPIC wait CS 0___/---1 OK");
            //synopsys translate_on
		      st <= st  + 1'b1;
        end
    end

    JMP_W + 7: // VGA ready ?
	 begin
	     if (i_vga_ready_h == 1)
		      st <= st + 1'b1;
        else
		      st <= 0;
	 end
	 
    JMP_W + 8: // write data to VGA
	 begin
        case (spi_cmd)
        CMD_W_CUR_ADR:
        begin
            //synopsys translate_off
		    $display("SPIC spi_cmd == CMD_W_CUR_ADR, write to VGA cur adr = 0x%X", {vga_datah[3:0], vga_datal});
            //synopsys translate_on
		    vga_cur_adr <= {vga_datah[2:0], vga_datal};
        end

        CMD_W_STATUS, CMD_W_CONTROL, CMD_W_DATA, CMD_W_COLOR:
        begin
            //synopsys translate_off
		    $display("SPIC write to VGA data = 0x%X", vga_datah);
		    //synopsys translate_on
		    vga_oport <= vga_datah;
        end

        default: st <= 0;
        endcase

/*
	     if (spi_cmd == CMD_W_CUR_ADR) begin
            //synopsys translate_off
		      $display("SPIC spi_cmd == CMD_W_CUR_ADR, write to VGA cur adr = 0x%X", {vga_datah[3:0], vga_datal});
            //synopsys translate_on
		      vga_cur_adr <= {vga_datah[3:0], vga_datal};
		  end else begin
	         //synopsys translate_off
		      $display("SPIC write to VGA data = 0x%X", vga_datah);
		      //synopsys translate_on
		      vga_oport <= vga_datah;
		  end
*/

		  vga_rl_wh <= 1;
		  vga_cs_h  <= 1;
		  st        <= st + 1'b1;
	 end

    JMP_W + 9:
	 begin
        //synopsys translate_off
        $display("SPIC Write  END");
	     //synopsys translate_on
		  vga_rl_wh <= 1;
		  vga_cs_h  <= 0;
		  st        <= 0;
    end

//-READ----------------------------------------------------------
    JMP_R + 0:
	 begin
        //synopsys translate_off
        $display("SPIC vga_ready = %d", i_vga_ready_h);
	     //synopsys translate_on
	     if (i_vga_ready_h == 1) 
		      st <= st + 1'b1;
		  else 
		      st <= 0;
    end
	 
    JMP_R + 1:
	 begin
		  vga_rl_wh <= 0;
		  vga_cs_h  <= 1;
		  st        <= st + 1'b1;
	 end

    JMP_R + 2:
	 begin
		  vga_rl_wh <= 0;
		  vga_cs_h  <= 0;
		  st        <= st + 1'b1;
	 end

    JMP_R + 3:
	 begin
	     if (i_vga_ready_h == 1) begin
            //synopsys translate_off
            $display("SPIC Read from VGA = %X", i_vga_port);
            //synopsys translate_on
		      st <= st + 1'b1;
        end
    end

    JMP_R + 4: // wait xxxx_xxxx data from SPI
	 begin
	     if (spi_rx_ready)
		      st <= st + 1'b1;
	 end

    JMP_R + 5:
	 begin
	     if (spi_tx_ready) begin
            //synopsys translate_off
            $display("SPIC Write to SPI = %X", i_vga_port);
            //synopsys translate_on
		      spi_i_data <= i_vga_port;
				spi_cs     <= 1;
				spi_we     <= 1;
		      st          <= st + 1'b1;
        end
	 end

    JMP_R + 6:
	 begin
        spi_cs     <= 0;
        spi_we     <= 0;
        st          <= st + 1'b1;
    end
	 
// wait cs = 0->1	 -------------------------------------------------------------
    JMP_WAIT_CS_HIGH:
	 begin
	     if (reg_spi_cs[3] == 1) begin
            //synopsys translate_off
            $display("SPIC Wait CS = 0->1 OK.");
            //synopsys translate_on
		      st <= 0;
        end
    end

	 default: st <= 0;
	 endcase
end
//==============================================================================



assign o_vga_cmd     = vga_cmd;
assign o_vga_cur_adr = vga_cur_adr;
assign o_vga_port    = vga_oport;
assign o_vga_cs_h    = vga_cs_h;
assign o_vga_rl_wh   = vga_rl_wh;


`ifdef DEBUG
assign d_st            = st;
assign d_spi_rx_ready = spi_rx_ready;
assign d_spi_tx_ready = spi_tx_ready;
assign d_spi_cs       = spi_cs;
assign d_spi_i_data   = spi_i_data;
assign d_spi_o_data   = spi_o_data;
assign d_spi_we       = spi_we;
assign d_spi_re       = spi_re;

`endif	 

assign o_d = spi_rx_ready;

endmodule
