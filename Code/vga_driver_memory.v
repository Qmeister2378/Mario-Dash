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

    input  wire [9:0] enemy_x,
    input  wire [9:0] enemy_y,

    input  wire [9:0] proj0_x,
    input  wire [9:0] proj0_y,
    input  wire       proj0_active,

    input  wire [9:0] proj1_x,
    input  wire [9:0] proj1_y,
    input  wire       proj1_active,

    input  wire [9:0] proj2_x,
    input  wire [9:0] proj2_y,
    input  wire       proj2_active,

    input  wire [9:0] proj3_x,
    input  wire [9:0] proj3_y,
    input  wire       proj3_active,

    output reg  [7:0] VGA_R,
    output reg  [7:0] VGA_G,
    output reg  [7:0] VGA_B
);

    // Game States
    localparam S_RUNNING   = 3'd0;
    localparam S_GAME_OVER = 3'd1;
    localparam S_WIN       = 3'd2;

    // Colors
    localparam LIGHT_GRAY      = 24'hC0C0C0;
    localparam DARK_GRAY       = 24'h505050;
    localparam LAVA_RED        = 24'hFF4500;
    localparam GOLD            = 24'hFFD700;
    localparam PLAYER_COLOR    = 24'h0000FF;
    localparam LAVA_WALL_COLOR = 24'hFF6600;
    localparam BROWN           = 24'h964B00;
    localparam GRASS_GREEN     = 24'h3CB043;
    localparam WATER_BLUE      = 24'h00AFFF;
    localparam ENEMY_COLOR     = 24'hFF00FF;
    localparam PROJ_COLOR      = 24'hFFFFFF;

    // Screen geometry
    localparam SCREEN_HEIGHT = 10'd480;
    localparam LAVA_Y        = 10'd380;
    localparam LAVA_X_START  = 270;
    localparam LAVA_WIDTH    = 40;

    reg [23:0] base_color;
    reg [23:0] vga_color;
    reg        draw_player;

    always @(*) begin
        base_color = LIGHT_GRAY;

        // Ceiling
        if (y < 75)
            base_color = DARK_GRAY;

        // Static lava floor (level 0)
        if (level == 2'd0 && y >= LAVA_Y)
            base_color = LAVA_RED;

        // Rising lava band (level 0)
        if (level == 2'd0 &&
            (x >= LAVA_X_START && x < LAVA_X_START + LAVA_WIDTH) &&
            (y >= (SCREEN_HEIGHT - lava_height)))
            base_color = LAVA_RED;

        // LEVEL GEOMETRY
        case (level)
            2'd0: begin
                // Level 1 platforms
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
                if (x >= 540 &&          y >= 360 && y <= 380)     base_color = DARK_GRAY;
            end

            2'd1: begin
                // Ground chunks
                if (x >= 0   && x <= 100 && y >= 400) base_color = GRASS_GREEN;
                if (x >= 200 && x <= 300 && y >= 400) base_color = GRASS_GREEN;
                if (x >= 400 && x <= 500 && y >= 400) base_color = GRASS_GREEN;
                if (x >= 550 && x <= 639 && y >= 400) base_color = GRASS_GREEN;

                // Floating platforms (brown)
                if (x >= 120 && x <= 180 && y >= 370 && y <= 385) base_color = BROWN;
                if (x >= 350 && x <= 400 && y >= 350 && y <= 365) base_color = BROWN;

                // Water pits
                if (y >= 400) begin
                    if (x > 100 && x < 200) base_color = WATER_BLUE;
                    if (x > 300 && x < 400) base_color = WATER_BLUE;
                    if (x > 500 && x < 550) base_color = WATER_BLUE;
                end

                // Enemy (16x16)
                if (x >= enemy_x && x < enemy_x + 16 &&
                    y >= enemy_y && y < enemy_y + 16)
                    base_color = ENEMY_COLOR;

                // Projectiles original(2x5) – up to 4 // now 4 x 10
                if (proj0_active &&
                    x >= proj0_x && x < proj0_x + 5 &&
                    y >= proj0_y && y < proj0_y + 12)
                    base_color = PROJ_COLOR;

                if (proj1_active &&
                    x >= proj1_x && x < proj1_x + 5 &&
                    y >= proj1_y && y < proj1_y + 12)
                    base_color = PROJ_COLOR;

                if (proj2_active &&
                    x >= proj2_x && x < proj2_x + 5 &&
                    y >= proj2_y && y < proj2_y + 12)
                    base_color = PROJ_COLOR;

                if (proj3_active &&
                    x >= proj3_x && x < proj3_x + 5 &&
                    y >= proj3_y && y < proj3_y + 12)
                    base_color = PROJ_COLOR;
            end
        endcase

        // Goals
        if (level == 2'd0 && x >= 580 && x <= 630 && y >= 355 && y <= 360)
            base_color = GOLD;

        if (level == 2'd1 && x >= 10 && x <= 60 && y >= 395 && y <= 400)
            base_color = GOLD;

        // Side lava wall (level 0)
        if (level == 2'd0 && x >= lava_wall_x && x < lava_wall_x + 10)
            base_color = LAVA_WALL_COLOR;

        // PLAYER SPRITE
        if (x >= player_x && x < player_x + 16 &&
            y >= player_y && y < player_y + 16) begin

            integer px;
            integer py;
            px = x - player_x;
            py = y - player_y;

            draw_player = 1'b0;

            // head
            if (px >= 5 && px <= 10 && py <= 5) draw_player = 1'b1;
            // body
            if (px >= 7 && px <= 8 && py >= 6 && py <= 12) draw_player = 1'b1;

            // arms
            if ((py >= 8 && py <= 12) && (px == 7 - (py - 8))) draw_player = 1'b1;
            if ((py >= 8 && py <= 12) && (px == 8 + (py - 8))) draw_player = 1'b1;

            // legs
            if ((py >= 13 && py <= 15) && (px == 7 - (py - 13))) draw_player = 1'b1;
            if ((py >= 13 && py <= 15) && (px == 8 + (py - 13))) draw_player = 1'b1;

            if (draw_player)
                base_color = PLAYER_COLOR;
        end

        // GAME STATE TINT
        vga_color = base_color;

        if (active_pixels) begin
            if (game_state == S_GAME_OVER) begin
                // red tint
                vga_color[23:16] = base_color[23:16] | 8'h60;
                vga_color[15:8]  = base_color[15:8]  >> 1;
                vga_color[7:0]   = base_color[7:0]   >> 1;
            end else if (game_state == S_WIN) begin
                // warm tint
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
