// ======================================================
// Top-level: platformer_top.v
// ======================================================

module platformer_top (
    input        CLOCK_50,
    input  [3:0] KEY,
    input  [9:0] SW,

    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,

    output       VGA_BLANK_N,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_CLK,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_SYNC_N
);

    // Turn off HEX / LEDs
    assign HEX0 = 7'h00;
    assign HEX1 = 7'h00;
    assign HEX2 = 7'h00;
    assign HEX3 = 7'h00;
    assign LEDR = 10'b0;

    //-------------------------------------------------------
    // VGA timing
    //-------------------------------------------------------
    wire clk = CLOCK_50;
    wire rst = SW[0]; // active-low reset

    wire       active_pixels;
    wire [9:0] x;
    wire [9:0] y;

    vga_driver the_vga(
        .clk          (clk),
        .rst          (rst),
        .vga_clk      (VGA_CLK),
        .hsync        (VGA_HS),
        .vsync        (VGA_VS),
        .active_pixels(active_pixels),
        .xPixel       (x),
        .yPixel       (y),
        .VGA_BLANK_N  (VGA_BLANK_N),
        .VGA_SYNC_N   (VGA_SYNC_N)
    );

    //-------------------------------------------------------
    // 60 Hz GAME TICK
    //-------------------------------------------------------
    localparam TICK_DIV_MAX = 20'd833333; // 50MHz / 60Hz

    reg [19:0] tick_counter;
    reg        game_tick;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            tick_counter <= 20'd0;
            game_tick    <= 1'b0;
        end else begin
            if (tick_counter == TICK_DIV_MAX) begin
                tick_counter <= 20'd0;
                game_tick    <= 1'b1;
            end else begin
                tick_counter <= tick_counter + 1'b1;
                game_tick    <= 1'b0;
            end
        end
    end

    //-------------------------------------------------------
    // INPUT HANDLING
    //-------------------------------------------------------
    wire raw_move_right = ~KEY[0];
    wire raw_jump       = ~KEY[1];
    wire raw_move_left  = ~KEY[2];

    wire move_left  = raw_move_left;
    wire move_right = raw_move_right;
    wire jump       = raw_jump;

    wire any_input_level = raw_move_left | raw_move_right | raw_jump;

    //-------------------------------------------------------
    // COLLISION + PLAYER SIGNALS
    //-------------------------------------------------------
    wire [9:0] player_x;
    wire [9:0] player_y;

    wire       on_ground;
    wire [9:0] support_y;
    wire       hit_ceiling;
    wire       hit_left_wall;
    wire       hit_right_wall;
    wire       at_goal_region;
    wire       in_lava;

    reg [1:0] level = 2'd0; // current level

    // Lava band
    reg [9:0] lava_height;
    reg       lava_rise;

    platform_collision collision (
        .player_x     (player_x),
        .player_y     (player_y),
        .level        (level),
        .lava_height  (lava_height),
		  .hit_lava_wall(hit_lava_wall),
        .on_ground    (on_ground),
        .support_y    (support_y),
        .hit_ceiling  (hit_ceiling),
        .hit_left_wall(hit_left_wall),
        .hit_right_wall(hit_right_wall),
        .at_goal_region(at_goal_region),
        .in_lava      (in_lava)
    );

    //-------------------------------------------------------
    // GAME FSM + LAVA LOGIC
    //-------------------------------------------------------
    localparam S_RUNNING   = 3'd0;
    localparam S_GAME_OVER = 3'd1;
    localparam S_WIN       = 3'd2;

    reg [2:0] game_state;
    reg       freeze;
    reg [15:0] score;
    reg        lava_speed_boost_pulse;

    reg [9:0] player_x_reset = 10'd50;
    reg [9:0] player_y_reset = 10'd50;

    localparam LAVA_TOP    = 10'd380;
    localparam LAVA_BOTTOM = 10'd0;
    localparam LAVA_SPEED  = 3;

    wire jump_landed_pulse;

    // Enemy hit (from enemy_controller)
    wire hit_enemy;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            game_state  <= S_RUNNING;
            freeze      <= 1'b0;
            score       <= 16'd0;
            level       <= 2'd0;
            lava_height <= 10'd0;
            lava_rise   <= 1'b1;

            // starter position
            player_x_reset <= 10'd20;
            player_y_reset <= 10'd360 - 10'd16;
        end else if (game_tick) begin
            lava_speed_boost_pulse <= 1'b0;

            case (game_state)
                S_RUNNING: begin
                    freeze <= 1'b0;

                    if (jump_landed_pulse) begin
                        score <= score + 1;
                        lava_speed_boost_pulse <= 1'b1;
                    end

                    // Death by lava OR enemy/projectile
                    if (in_lava || hit_enemy) begin
                        game_state <= S_GAME_OVER;
                        freeze     <= 1'b1;
                    end else if (at_goal_region) begin
                        game_state <= S_WIN;
                        freeze     <= 1'b1;
                    end

                    // Lava rising/falling logic (only in level 0)
                    if (level == 2'd0) begin
                        if (lava_rise) begin
                            if (lava_height + LAVA_SPEED < LAVA_TOP)
                                lava_height <= lava_height + LAVA_SPEED;
                            else begin
                                lava_height <= LAVA_TOP;
                                lava_rise   <= 1'b0;
                            end
                        end else begin
                            if (lava_height >= LAVA_SPEED)
                                lava_height <= lava_height - LAVA_SPEED;
                            else begin
                                lava_height <= LAVA_BOTTOM;
                                lava_rise   <= 1'b1;
                            end
                        end
                    end else begin
                        // Level 1 or higher: keep lava safely at bottom
                        lava_height <= LAVA_BOTTOM;
                        lava_rise   <= 1'b1;
                    end
                end

                S_GAME_OVER: begin
                    freeze     <= 1'b1;
                    game_state <= S_GAME_OVER;

                    // Reset position values (actual reset handled by player_physics if you use reset_player)
                    if (level == 2'd0) begin
                        player_x_reset <= 10'd20;
                        player_y_reset <= 10'd360 - 10'd16;
                    end else begin
                        player_x_reset <= 10'd20;
                        player_y_reset <= 10'd380 - 10'd16;
                    end
                end

                S_WIN: begin
                    if (level < 2'd1) begin
                        // advance to next level
                        player_x_reset <= 10'd20;
                        player_y_reset <= 10'd380 - 10'd16;

                        lava_height <= 10'd0;
                        lava_rise   <= 1'b1;

                        game_state  <= S_RUNNING;
                        freeze      <= 1'b0;
                        level       <= level + 1'b1;
                    end else begin
                        // last level, stay in win state
                        level      <= 2'd1;
                        game_state <= S_WIN;
                        freeze     <= 1'b1;
                    end
                end
            endcase
        end
    end

    //-------------------------------------------------------
    // PLAYER PHYSICS
    //-------------------------------------------------------
    wire reset_player = 1'b0; // still unused pulse; can wire later if you want

    player_physics player (
        .clk              (clk),
        .rst              (rst),
        .game_tick        (game_tick),
        .move_left        (move_left),
        .move_right       (move_right),
        .jump             (jump),
        .on_ground        (on_ground),
        .support_y        (support_y),
        .hit_ceiling      (hit_ceiling),
        .hit_left_wall    (hit_left_wall),
        .hit_right_wall   (hit_right_wall),
        .freeze           (freeze),
        .reset_x          (player_x_reset),
        .reset_y          (player_y_reset),
        .reset_player     (reset_player),
        .player_x         (player_x),
        .player_y         (player_y),
        .jump_landed_pulse(jump_landed_pulse)
    );

    //-------------------------------------------------------
    // LAVA CONTROLLER (side wall)
    //-------------------------------------------------------
    wire [9:0] lava_wall_x;
    wire       hit_lava_wall;

    lava_controller lava (
        .clk              (clk),
        .rst              (rst),
        .game_tick        (game_tick),
        .any_input_level  (any_input_level),
        .speed_boost_pulse(lava_speed_boost_pulse),
        .freeze           (freeze),
        .player_x         (player_x),
        .level            (level),
        .lava_wall_x      (lava_wall_x),
        .hit_lava_wall    (hit_lava_wall)
    );

    //-------------------------------------------------------
    // ENEMY CONTROLLER (Level 2 flying enemy with 4 bullets)
    //-------------------------------------------------------
    wire [9:0] enemy_x;
    wire [9:0] enemy_y;

    wire [9:0] proj0_x, proj0_y;
    wire       proj0_active;
    wire [9:0] proj1_x, proj1_y;
    wire       proj1_active;
    wire [9:0] proj2_x, proj2_y;
    wire       proj2_active;
    wire [9:0] proj3_x, proj3_y;
    wire       proj3_active;

    enemy_controller enemy_ctrl (
        .clk         (clk),
        .rst         (rst),
        .game_tick   (game_tick),
        .freeze      (freeze),
        .level       (level),
        .player_x    (player_x),
        .player_y    (player_y),

        .enemy_x     (enemy_x),
        .enemy_y     (enemy_y),

        .proj0_x     (proj0_x),
        .proj0_y     (proj0_y),
        .proj0_active(proj0_active),

        .proj1_x     (proj1_x),
        .proj1_y     (proj1_y),
        .proj1_active(proj1_active),

        .proj2_x     (proj2_x),
        .proj2_y     (proj2_y),
        .proj2_active(proj2_active),

        .proj3_x     (proj3_x),
        .proj3_y     (proj3_y),
        .proj3_active(proj3_active),

        .hit_enemy   (hit_enemy)
    );

    //-------------------------------------------------------
    // VGA RENDERER
    //-------------------------------------------------------
    vga_driver_memory the_renderer(
        .x             (x),
        .y             (y),
        .active_pixels (active_pixels),
        .player_x      (player_x),
        .player_y      (player_y),
        .lava_wall_x   (lava_wall_x),
        .lava_height   (lava_height),
        .game_state    (game_state),
        .level         (level),

        .enemy_x       (enemy_x),
        .enemy_y       (enemy_y),

        .proj0_x       (proj0_x),
        .proj0_y       (proj0_y),
        .proj0_active  (proj0_active),
        .proj1_x       (proj1_x),
        .proj1_y       (proj1_y),
        .proj1_active  (proj1_active),
        .proj2_x       (proj2_x),
        .proj2_y       (proj2_y),
        .proj2_active  (proj2_active),
        .proj3_x       (proj3_x),
        .proj3_y       (proj3_y),
        .proj3_active  (proj3_active),

        .VGA_R         (VGA_R),
        .VGA_G         (VGA_G),
        .VGA_B         (VGA_B)
    );

endmodule