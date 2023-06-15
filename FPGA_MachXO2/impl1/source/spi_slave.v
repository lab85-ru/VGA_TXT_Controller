//-----------------------------------------------------------------------------
// spi slave
// v1.0 2015
//
// test modelsim ok: 4*i_clk >= i_spi_sck
//
//-----------------------------------------------------------------------------
//`timescale 1ps/1ps
//`define DEBUG

module spi_slave 
#(
    parameter SHIFT_REG_LEN = 8           // dlinna shift registra
)
(
    input wire i_clk,
	 // i/o inteface
	 input wire i_cs,
	 input wire [SHIFT_REG_LEN-1:0] i_data,
	 output wire [SHIFT_REG_LEN-1:0] o_data,
	 input wire i_we,                        // read,  i/o inteface
	 input wire i_re,                        // write, i/o inteface
	 output wire o_rx_error,                 // perepolninie, ne zabrali danie, kak bili zagrusheni novie !
	 output wire o_rx_ready,
	 
	 output wire o_tx_error,                 // error: popitka zapisi v spi ! 1-idet peredacha(zanat), 2-net gotovnosti spi
	 output wire o_tx_ready,
	 
	 // SPI slave interface
	 input wire i_spi_sck,
	 input wire i_spi_cs_l,
	 input wire i_spi_mosi,
	 output reg o_spi_miso

`ifdef DEBUG
    ,
	 output wire [5:0] d_rx_bit_counter,
	 output wire d_rx_flag,
	 output wire [5:0] d_tx_bit_counter,
	 output wire d_tx_flag
`endif

);

reg [SHIFT_REG_LEN-1:0] spi_rx_reg = 0;     // reg for i/o interface
reg [SHIFT_REG_LEN-1:0] spi_tx_reg = 0;     // reg for i/o interface
reg [SHIFT_REG_LEN-1:0] spi_shift_reg = 0;  // reg for i/o interface
reg [SHIFT_REG_LEN-1:0] spi_tx_fifo = 0;    // temp reg for copy i_data -> spi_tx_fifo -> spi_tx_reg

reg [5:0] rx_bit_counter = 0;  // counter bit for spi inteface
reg [5:0] tx_bit_counter = 0;  // counter bit for spi inteface

reg rx_flag = 0;    // (spi slave inteface) rx data from spi
reg rx_ready = 0;   // spi rx data (i/o inteface)
reg rx_error = 0;   // perepolninie, ne zabrali danie, kak bili zagrusheni novie !
reg tx_flag = 0;    // (spi slave inteface) rx data from spi
reg tx_ready = 0;   // spi rx data (i/o inteface)
reg tx_error = 0;   //

reg rx_f1 = 0; // sync register (clokoviy domen spi->i_clk)
reg rx_f2 = 0;
reg rx_f3 = 0;

reg tx_f1 = 0; // sync register (clokoviy domen spi->i_clk)
reg tx_f2 = 0;
reg tx_f3 = 0;

reg cs_f1 = 0; // sync register (clokoviy domen spi->i_clk)
reg cs_f2 = 0;
reg cs_f3 = 0;

reg reset = 0;
//-----------------------------------------------------------------------------

// tx spi
always @( spi_tx_reg or i_spi_cs_l or tx_bit_counter)
begin
    if ( i_spi_cs_l == 0 ) begin
	     o_spi_miso <= spi_tx_reg[SHIFT_REG_LEN - tx_bit_counter - 1];
	 end else
	     o_spi_miso <= 1'b1;
end

// rx spi
always @(posedge i_spi_sck)
begin
    if (i_spi_cs_l == 0) begin
	     spi_shift_reg[SHIFT_REG_LEN - rx_bit_counter - 1] <= i_spi_mosi;
	 end
end

// rx spi bit counter
always @(posedge i_spi_sck or posedge reset)
begin
    if (reset) begin
	     rx_bit_counter <= 0;
	 end else 
    if (i_spi_cs_l == 0) begin
	     if (rx_bit_counter == SHIFT_REG_LEN - 1) begin
		      rx_bit_counter <= 0;
				rx_flag <= 1;
		  end else begin
	         rx_bit_counter <= rx_bit_counter + 1'b1;
				rx_flag <= 0;
		  end
	 end
end

// rx
// perehod cherez CLK domen spi->i_clk
always @(posedge i_clk)
begin
    rx_f1 <= rx_flag;
	 rx_f2 <= rx_f1;
	 rx_f3 <= rx_f2;
	 
    cs_f1 <= i_spi_cs_l;
	 cs_f2 <= cs_f1;
	 cs_f3 <= cs_f2;
	 
	 if (cs_f3 == 0) begin
	 
	     if (rx_f2 && !rx_f3) begin
	         rx_ready <= 1;
		      spi_rx_reg <= spi_shift_reg;
	     end else if (i_re && i_cs)
	         rx_ready <= 0;

	     if (rx_f2 && !rx_f3 && rx_ready) begin
	         rx_error <= 1;
	     end else if (i_re && i_cs)
	         rx_error <= 0;

	 end else begin
	     rx_ready <= 0;
	     rx_error <= 0;
	 end
		  
end

//tx copy to tmp buf
always @(posedge i_clk)
begin
    if (i_we && i_cs && tx_ready) begin
	     spi_tx_fifo <= i_data;
	 end
	 
    spi_tx_reg <= spi_tx_fifo;
end

// tx spi bit counter
always @(negedge i_spi_sck or posedge reset)
begin
    if (reset) begin
	     tx_bit_counter <= 0;
	 end else
    if (i_spi_cs_l == 0) begin
	     if (tx_bit_counter == SHIFT_REG_LEN - 1) begin
		      tx_bit_counter <= 0;
				tx_flag <= 1;
		  end else begin
	         tx_bit_counter <= tx_bit_counter + 1'b1;
				tx_flag <= 0;
		  end
	 end
end


// tx
// perehod cherez CLK domen spi->i_clk
always @(posedge i_clk)
begin
    tx_f1 <= tx_flag;
	 tx_f2 <= tx_f1;
	 tx_f3 <= tx_f2;
	 
	 if (cs_f3 == 0) begin

	     if (tx_f2 && !tx_f3) begin
	         tx_ready <= 1;
	     end else if (i_we && i_cs || tx_flag == 0)// || !i_spi_cs_l)
	         tx_ready <= 0;

	     if (i_we && i_cs && !tx_ready) begin
	         tx_error <= 1;
	     end else if (i_we && i_cs)
	         tx_error <= 0;
	 end else begin
	     tx_ready <= 0;
	     tx_error <= 0;
	 end
		  
end

always @(posedge i_clk)
begin
    if (cs_f3) begin
	     reset <= 1;
	 end else begin
	     reset <= 0;
	 end
end


assign o_rx_ready = rx_ready;
assign o_data = spi_rx_reg;
assign o_rx_error = rx_error;

assign o_tx_ready = tx_ready;
assign o_tx_error = tx_error;

`ifdef DEBUG
assign d_rx_bit_counter = rx_bit_counter;
assign d_rx_flag = rx_flag;
assign d_tx_bit_counter = tx_bit_counter;
assign d_tx_flag = tx_flag;
`endif

endmodule

