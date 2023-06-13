//-----------------------------------------------------------------------------
// cursor wire char to current position cursor.
//-----------------------------------------------------------------------------
module dma_cur_wr_char (
    input wire         i_clk,
    output wire [7:0]  o_vram_data,
    output wire [11:0] o_vram_adr,
    output wire        o_vram_we,

    output wire [11:0] o_cursor_adr,
    output wire        o_cursor_on
);

reg [3:0]  st = 0;

reg [7:0]  vram_data  = 0;
reg [11:0] vram_adr   = 0;
reg        vram_we    = 0;

reg [11:0] cursor_adr = 0;
reg        cursor_on  = 1;



always @(posedge i_clk)
begin
    case (st)
    0:
    begin
        vram_data <= 0;
        vram_adr  <= 0;
        vram_we   <= 1;

        st <= 1;
    end

    1:	 
    begin
        vram_adr <= vram_adr + 1'b1;
        vram_data <= vram_data + 1'b1;
        if (vram_data == 255) begin // stop
            vram_we <= 0;
 			st <= 2;
        end
    end

    2:
    begin

    end

    default: st <= 0;

    endcase
end

assign o_vram_data  = vram_data;
assign o_vram_adr   = vram_adr;
assign o_vram_we    = vram_we;
assign o_cursor_adr = cursor_adr;
assign o_cursor_on  = cursor_on;

endmodule
