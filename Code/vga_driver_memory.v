module vga_driver_memory (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active_pixels,

    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire [9:0] lava_wall_x,
    input  wire [9:0] lava_height,
    input  wire [2:0] game_state,
    input  wire [1:0] level,      

    output reg  [7:0] VGA_R,
    output reg  [7:0] VGA_G,
    output reg  [7:0] VGA_B
);

    // Game States
    localparam S_RUNNING   = 3'd0;
    localparam S_GAME_OVER = 3'd1;
    localparam S_WIN       = 3'd2;

    // Colors
    localparam LIGHT_GRAY  = 24'hC0C0C0;
    localparam DARK_GRAY   = 24'h505050;
    localparam LAVA_RED    = 24'hFF4500;
    localparam GOLD        = 24'hFFD700;
    localparam PLAYER_COLOR = 24'h0000FF;
    localparam LAVA_WALL_COLOR = 24'hFF6600;

    // NEW GRASS COLOR
    localparam GRASS_GREEN = 24'h3CB043;

    // Screen geometry
    localparam SCREEN_HEIGHT = 10'd480;
    localparam LAVA_Y = 10'd380;

    localparam LAVA_X_START = 270;
    localparam LAVA_WIDTH   = 40;

    reg [23:0] base_color;
    reg [23:0] vga_color;
    reg draw_player;

    always @(*) begin
        base_color = LIGHT_GRAY;

        // Ceiling
        if (y < 75)
            base_color = DARK_GRAY;

        // Static lava floor
        if (level == 2'd0 && y >= LAVA_Y)
            base_color = LAVA_RED;

        // Rising lava band
        if ((x >= LAVA_X_START && x < LAVA_X_START + LAVA_WIDTH) &&
            (y >= (SCREEN_HEIGHT - lava_height)))
            base_color = LAVA_RED;

        // ----------------- LEVEL SWITCH -----------------
        case(level)

            // LEVEL 0 (unchanged)
            2'd0: begin
                if (x >= 0   && x <= 60  && y >= 360 && y <= 380) base_color = DARK_GRAY;
                if (x >= 90  && x <= 270 && y >= 360 && y <= 380) base_color = DARK_GRAY;
                if (x >= 130 && x <= 200 && y >= 295 && y <= 310) base_color = DARK_GRAY;
                if (x >= 175 && x <= 210 && y >= 240 && y <= 255) base_color = DARK_GRAY;
                if (x >= 240 && x <= 270 && y >= 220 && y <= 380) base_color = DARK_GRAY;
                if (x >= 330 && x <= 380 && y >= 360 && y <= 380) base_color = DARK_GRAY;
                if (x >= 380 && x <= 430 && y >= 295 && y <= 310) base_color = DARK_GRAY;
                if (x >= 345 && x <= 380 && y >= 230 && y <= 245) base_color = DARK_GRAY;
                if (x >= 370 && x <= 430 && y >= 165 && y <= 180) base_color = DARK_GRAY;
                if (x >= 475 && x <= 550 && y >= 190 && y <= 240) base_color = DARK_GRAY;
                if (x >= 540 && y >= 360 && y <= 380) base_color = DARK_GRAY;
            end


            // ---------------------- LEVEL 2 (NEW) ----------------------
            2'd1: begin
                // New Platforms
                if (x >= 0   && x <= 639 && y >= 400 && y <= 480) base_color = GRASS_GREEN;
                if (x >= 100 && x <= 200 && y >= 340 && y <= 355) base_color = GRASS_GREEN;
                if (x >= 250 && x <= 350 && y >= 280 && y <= 295) base_color = GRASS_GREEN;
                if (x >= 400 && x <= 500 && y >= 220 && y <= 235) base_color = GRASS_GREEN;
                if (x >= 200 && x <= 300 && y >= 160 && y <= 175) base_color = GRASS_GREEN;
                if (x >= 50  && x <= 150 && y >= 100 && y <= 115) base_color = GRASS_GREEN;
                if (x >= 550 && x <= 639 && y >= 50  && y <= 65)  base_color = GRASS_GREEN;
            end

        endcase

        // Goal (same for any level)
        if (level == 2'd0 && x >= 580 && x <= 630 && y >= 355 && y <= 360)
            base_color = GOLD;

        // Side lava wall
        if (level == 2'd0 && x >= lava_wall_x && x < lava_wall_x + 10)
            base_color = LAVA_WALL_COLOR;

        // PLAYER SPRITE (same)
        if (x >= player_x && x < player_x + 16 &&
            y >= player_y && y < player_y + 16)
        begin
            integer px, py;
            px = x - player_x;
            py = y - player_y;

            draw_player = 1'b0;

            if (px >= 5 && px <= 10 && py <= 5) draw_player = 1'b1;
            if (px >= 7 && px <= 8  && py >= 6 && py <= 12) draw_player = 1'b1;

            if ((py >= 8  && py <= 12) && (px == 7 - (py - 8))) draw_player = 1'b1;
            if ((py >= 8  && py <= 12) && (px == 8 + (py - 8))) draw_player = 1'b1;

            if ((py >= 13 && py <= 15) && (px == 7 - (py - 13))) draw_player = 1'b1;
            if ((py >= 13 && py <= 15) && (px == 8 + (py - 13))) draw_player = 1'b1;

            if (draw_player)
                base_color = PLAYER_COLOR;
        end

        // GAME STATE TINT
        vga_color = base_color;

        if (active_pixels) begin
            if (game_state == S_GAME_OVER) begin
                vga_color[23:16] = base_color[23:16] | 8'h60;
                vga_color[15:8]  = base_color[15:8]  >> 1;
                vga_color[7:0]   = base_color[7:0]   >> 1;
            end
            else if (game_state == S_WIN) begin
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
