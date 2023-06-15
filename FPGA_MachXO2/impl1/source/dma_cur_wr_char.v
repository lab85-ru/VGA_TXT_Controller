//-----------------------------------------------------------------------------
// cursor wire char to current position cursor.
//-----------------------------------------------------------------------------
module dma_cur_wr_char 
(
    input wire         i_clk,
    output wire [7:0]  o_vram_data,
    output wire [10:0] o_vram_adr,
    output wire        o_vram_we,

    output wire [7:0]  o_cram_data,

    output wire [10:0] o_cursor_adr,
    output wire        o_cursor_on
);

localparam VGA_CHAR_COLOR_BIT_R = 8'b0000_0001;
localparam VGA_CHAR_COLOR_BIT_G = 8'b0000_0010;
localparam VGA_CHAR_COLOR_BIT_B = 8'b0000_0100;

localparam VGA_BACKGROUND_BIT_R = 8'b0001_0000;
localparam VGA_BACKGROUND_BIT_G = 8'b0010_0000;
localparam VGA_BACKGROUND_BIT_B = 8'b0100_0000;

localparam VGA_CHAR_BLINK       = 8'b1000_0000;


reg [1:0]  st = 0;

reg [7:0]  cram_data  = 0;
reg [7:0]  vram_data  = 0;
reg [10:0] vram_adr   = 0;
reg        vram_we    = 0;

reg [10:0] cursor_adr = 0;
reg        cursor_on  = 1;
reg [7:0]  m = 0;

`ifdef VGA_COLOR_ENABLE
always @(posedge i_clk)
begin
    case (st)
    0:
    begin
        case (m)
        // Blink - off
        0: cram_data <= VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_G | VGA_CHAR_COLOR_BIT_B;
        1: cram_data <= VGA_CHAR_COLOR_BIT_R;
        2: cram_data <= VGA_CHAR_COLOR_BIT_G;
        3: cram_data <= VGA_CHAR_COLOR_BIT_B;
        4: cram_data <= VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_G;
        5: cram_data <= VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_B;
        6: cram_data <= VGA_CHAR_COLOR_BIT_G | VGA_CHAR_COLOR_BIT_B;

        7: cram_data <= VGA_BACKGROUND_BIT_R | VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_G | VGA_CHAR_COLOR_BIT_B;
        8: cram_data <= VGA_BACKGROUND_BIT_G | VGA_CHAR_COLOR_BIT_R;
        9: cram_data <= VGA_BACKGROUND_BIT_B | VGA_CHAR_COLOR_BIT_G;

        // Blink - on
        10: cram_data <= VGA_CHAR_BLINK | VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_G | VGA_CHAR_COLOR_BIT_B;
        11: cram_data <= VGA_CHAR_BLINK | VGA_CHAR_COLOR_BIT_R;
        12: cram_data <= VGA_CHAR_BLINK | VGA_CHAR_COLOR_BIT_G;
        13: cram_data <= VGA_CHAR_BLINK | VGA_CHAR_COLOR_BIT_B;
        14: cram_data <= VGA_CHAR_BLINK | VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_G;
        15: cram_data <= VGA_CHAR_BLINK | VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_B;
        16: cram_data <= VGA_CHAR_BLINK | VGA_CHAR_COLOR_BIT_G | VGA_CHAR_COLOR_BIT_B;

        17: cram_data <= VGA_CHAR_BLINK | VGA_BACKGROUND_BIT_R | VGA_CHAR_COLOR_BIT_R | VGA_CHAR_COLOR_BIT_G | VGA_CHAR_COLOR_BIT_B;
        18: cram_data <= VGA_CHAR_BLINK | VGA_BACKGROUND_BIT_G | VGA_CHAR_COLOR_BIT_R;
        19: cram_data <= VGA_CHAR_BLINK | VGA_BACKGROUND_BIT_B | VGA_CHAR_COLOR_BIT_G;

        default: m <= 0;
        endcase

        vram_data <= 0;
        vram_we   <= 1;

        st <= 1;
    end

    1:	 
    begin
        vram_adr <= vram_adr + 1'b1;
        vram_data <= vram_data + 1'b1;
        if (vram_data == 8'd80 - 1) begin // stop
            vram_we <= 0;
 			st <= 2;
        end
    end

    2:
    begin
        if (m != 19) begin
            m <= m + 1'b1;
            st <= 0;
        end

    end

    default: st <= 0;

    endcase
end

`else

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
`endif

assign o_cram_data  = cram_data;

assign o_vram_data  = vram_data;
assign o_vram_adr   = vram_adr;
assign o_vram_we    = vram_we;
assign o_cursor_adr = cursor_adr;
assign o_cursor_on  = cursor_on;

endmodule
