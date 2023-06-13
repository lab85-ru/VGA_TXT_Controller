//-----------------------------------------------------------------------------
// shift register
// 8 bit
//-----------------------------------------------------------------------------
module vga_shift_reg_8bit
(
    input wire       i_clk,
    input wire       i_cs_h,   // chip select
    input wire [7:0] i_data,   // Vhodnie danie
    input wire       i_ld_h,   // load data to shift reg
    output wire      o_data    // output date
);

reg [7:0] shreg_d = 0;

always @(posedge i_clk)
begin
    if (i_cs_h) begin
        if (i_ld_h) begin
            shreg_d <= i_data;
        end else begin
            shreg_d[7:0] <= {shreg_d[6:0], 1'b0};
        end
    end
end

assign o_data = i_cs_h == 1 ? shreg_d[7] : 1'b0;

endmodule
