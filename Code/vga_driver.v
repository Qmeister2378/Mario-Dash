
/////////////////////////////////////////////////////////////////////////////////////
// 640x480 VGA timing generator
// Adapted for DE1-SoC / DE2-style boards
/////////////////////////////////////////////////////////////////////////////////////

module vga_driver(
    input  clk,
    input  rst,

    output reg vga_clk,

    output reg hsync,
    output reg vsync,

    output reg active_pixels,

    output reg [9:0] xPixel,
    output reg [9:0] yPixel,

    output reg VGA_BLANK_N,
    output reg VGA_SYNC_N
);

// 640x480 @60Hz timing
// Horizontal
parameter HA_END = 10'd639;           // end of active video
parameter HS_STA = HA_END + 10'd16;   // sync start
parameter HS_END = HS_STA + 10'd96;   // sync end
parameter WIDTH  = 10'd799;           // total width

// Vertical
parameter VA_END = 10'd479;           // end of active video
parameter VS_STA = VA_END + 10'd10;   // sync start
parameter VS_END = VS_STA + 10'd2;    // sync end
parameter HEIGHT = 10'd524;           // total height

// Combinational timing outputs
always @(*) begin
    hsync         = ~((xPixel >= HS_STA) && (xPixel < HS_END));
    vsync         = ~((yPixel >= VS_STA) && (yPixel < VS_END));
    active_pixels = (xPixel <= HA_END && yPixel <= VA_END);

    VGA_BLANK_N   = active_pixels;
    VGA_SYNC_N    = 1'b1;
end

// Pixel counters + pixel clock divide-by-2
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        vga_clk <= 1'b0;
        xPixel  <= 10'd0;
        yPixel  <= 10'd0;
    end else begin
        vga_clk <= ~vga_clk;

        if (vga_clk) begin
            if (xPixel == WIDTH) begin
                xPixel <= 10'd0;
                if (yPixel == HEIGHT)
                    yPixel <= 10'd0;
                else
                    yPixel <= yPixel + 10'd1;
            end else begin
                xPixel <= xPixel + 10'd1;
            end
        end
    end
end

endmodule
