module vga_driver_memory (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active_pixels,

    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire [9:0] lava_wall_x,
    input  wire [2:0] game_state,

    output reg  [7:0] VGA_R,
    output reg  [7:0] VGA_G,
    output reg  [7:0] VGA_B
);
 localparam S_RUNNING   = 3'd0;
 localparam S_GAME_OVER = 3'd1;
 localparam S_WIN       = 3'd2;

 // Colors
 localparam LIGHT_GRAY = 24'hC0C0C0;
 localparam DARK_GRAY  = 24'h505050;
 localparam LAVA_RED   = 24'hFF4500;
 localparam GOLD       = 24'hFFD700;

 localparam PLAYER_COLOR    = 24'h0000FF;
 localparam LAVA_WALL_COLOR = 24'hFF6600;

 localparam LAVA_Y = 10'd380;

 reg [23:0] base_color;
 reg [23:0] vga_color;

 always @(*) begin
	  base_color = LIGHT_GRAY;

	  // Ceiling
	  if (y < 75)
			base_color = DARK_GRAY;

	  // Lava floor
	  if (y >= LAVA_Y)
			base_color = LAVA_RED;

	  // Platforms (match your level layout)
	  // 1: Small left step
	  if (x >= 0   && x <= 60  && y >= 360 && y <= 380) base_color = DARK_GRAY;
	  // 2: Long ground platform
	  if (x >= 90  && x <= 270 && y >= 360 && y <= 380) base_color = DARK_GRAY;
	  // 3: Middle ledge
	  if (x >= 130 && x <= 200 && y >= 295 && y <= 310) base_color = DARK_GRAY;
	  // 4: Floating mid tiny platform
	  if (x >= 175 && x <= 210 && y >= 240 && y <= 255) base_color = DARK_GRAY;
	  // 5: Tall block
	  if (x >= 240 && x <= 270 && y >= 220 && y <= 380) base_color = DARK_GRAY;
	  // 6: Right of tall block
	  if (x >= 330 && x <= 380 && y >= 360 && y <= 380) base_color = DARK_GRAY;
	  // 7: Mid ledge
	  if (x >= 380 && x <= 430 && y >= 295 && y <= 310) base_color = DARK_GRAY;
	  // 8: Higher small ledge
	  if (x >= 345 && x <= 380 && y >= 230 && y <= 245) base_color = DARK_GRAY;
	  // 9: High ledge
	  if (x >= 370 && x <= 430 && y >= 165 && y <= 180) base_color = DARK_GRAY;
	  // 10: Elevated platform
	  if (x >= 475 && x <= 550 && y >= 190 && y <= 240) base_color = DARK_GRAY;
	  // 11: Far right ground
	  if (x >= 540 &&             y >= 360 && y <= 380) base_color = DARK_GRAY;

	  // Goal (gold podium)
	  if (x >= 580 && x <= 630 && y >= 355 && y <= 360) base_color = GOLD;

	  // Lava wall from left
	  if (x >= lava_wall_x && x < lava_wall_x + 10)
			base_color = LAVA_WALL_COLOR;

	  // Player
	  if (x >= player_x && x < player_x + 16 &&
			y >= player_y && y < player_y + 16)
			base_color = PLAYER_COLOR;

	  // Start with base
	  vga_color = base_color;

	  // Apply tints only on active pixels
	  if (active_pixels) begin
			if (game_state == S_GAME_OVER) begin
				 // red tint: boost red, dampen G/B
				 vga_color[23:16] = base_color[23:16] | 8'h60;
				 vga_color[15:8]  = base_color[15:8]  >> 1;
				 vga_color[7:0]   = base_color[7:0]   >> 1;
			end else if (game_state == S_WIN) begin
				 // gold tint
				 vga_color = base_color | 24'h302000;
			end
	  end
 end

 always @(*) begin
	  VGA_R = vga_color[23:16];
	  VGA_G = vga_color[15:8];
	  VGA_B = vga_color[7:0];
 end

endmodule
