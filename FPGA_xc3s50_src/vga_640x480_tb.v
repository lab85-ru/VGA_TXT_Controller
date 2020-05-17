`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:54:52 07/30/2019
// Design Name:   vga_640x480
// Module Name:   C:/CAD_H/vga-test/xilinx/vga_spi/vga_spi/vga_640x480_tb.v
// Project Name:  vga_spi
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vga_640x480
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/1 ns
module vga_640x480_tb;

	// Inputs
	reg i_clk;
	reg i_spi_mosi;
	reg i_spi_cs;
	reg i_spi_sck;

	// Outputs
	wire o_video;
	wire o_vs;
	wire o_hs;
	wire o_spi_miso;
	
	localparam T_CLK = 40; // ns

	// Instantiate the Unit Under Test (UUT)
	vga_640x480 uut (
		.i_clk(i_clk), 
		.o_video(o_video), 
		.o_vs(o_vs), 
		.o_hs(o_hs), 
		.i_spi_mosi(i_spi_mosi), 
		.i_spi_cs(i_spi_cs), 
		.i_spi_sck(i_spi_sck), 
		.o_spi_miso(o_spi_miso)
	);

	initial begin
		// Initialize Inputs
		i_clk = 0;
		i_spi_mosi = 0;
		i_spi_cs = 1;
		i_spi_sck = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
	
	always #(T_CLK/2) forever #(T_CLK/2) i_clk = !i_clk;

/*      
always
begin
	   
    $display("Start test....");	 
	 #10_000;

    $display("Stop test...");	 
end
*/


endmodule

