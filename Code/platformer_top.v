module platformer_top (
    input  CLOCK_50,

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

    // turn off HEX / LEDs for now (you can hook score later)
    assign HEX0 = 7'h00;
    assign HEX1 = 7'h00;
    assign HEX2 = 7'h00;
    assign HEX3 = 7'h00;
    assign LEDR = 10'b0;

    //-------------------------------------------------------
    // VGA timing
    //-------------------------------------------------------
    wire clk = CLOCK_50;
    wire rst = SW[0];   // 0 = reset, 1 = run (active-low inside submodules)

    wire        active_pixels;
    wire [9:0]  x;
    wire [9:0]  y;

    vga_driver the_vga(
        .clk        (clk),
        .rst        (rst),
        .vga_clk    (VGA_CLK),
        .hsync      (VGA_HS),
        .vsync      (VGA_VS),
        .active_pixels(active_pixels),
        .xPixel     (x),
        .yPixel     (y),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N (VGA_SYNC_N)
    );

    //-------------------------------------------------------
    // 60 Hz GAME TICK (inlined tick_60hz)
    //-------------------------------------------------------
    // 50 MHz / 60 ≈ 833,333
    localparam TICK_DIV_MAX = 20'd833333;

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
    // INPUT HANDLING (inlined input_controller)
    //-------------------------------------------------------
    // DE Keys are active-low
    wire raw_move_right = ~KEY[0];  // move right
    wire raw_jump       = ~KEY[1];  // jump
    wire raw_move_left  = ~KEY[2];  // move left

    wire move_left       = raw_move_left;
    wire move_right      = raw_move_right;
    wire jump            = raw_jump;
    wire any_input_level = raw_move_left | raw_move_right | raw_jump;

    //-------------------------------------------------------
    // COLLISION + PLAYER + LAVA SIGNALS
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

    platform_collision collision (
        .player_x      (player_x),
        .player_y      (player_y),
        .on_ground     (on_ground),
        .support_y     (support_y),
        .hit_ceiling   (hit_ceiling),
        .hit_left_wall (hit_left_wall),
        .hit_right_wall(hit_right_wall),
        .at_goal_region(at_goal_region),
        .in_lava       (in_lava)
    );

    //-------------------------------------------------------
    // GAME FSM STATE (inlined game_fsm)
    //-------------------------------------------------------
    localparam S_RUNNING   = 3'd0;
    localparam S_GAME_OVER = 3'd1;
    localparam S_WIN       = 3'd2;

    reg [2:0]  game_state;
    reg        freeze;
    reg [15:0] score;
    reg        lava_speed_boost_pulse;

    wire       jump_landed_pulse;

    //-------------------------------------------------------
    // PLAYER PHYSICS
    //-------------------------------------------------------
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
        .player_x         (player_x),
        .player_y         (player_y),
        .jump_landed_pulse(jump_landed_pulse)
    );

    //-------------------------------------------------------
    // LAVA CONTROLLER
    //-------------------------------------------------------
    wire [9:0] lava_wall_x;
    wire       hit_lava_wall;

    lava_controller lava (
        .clk               (clk),
        .rst               (rst),
        .game_tick         (game_tick),
        .any_input_level   (any_input_level),
        .speed_boost_pulse (lava_speed_boost_pulse),
        .freeze            (freeze),
        .player_x          (player_x),
        .lava_wall_x       (lava_wall_x),
        .hit_lava_wall     (hit_lava_wall)
    );

    //-------------------------------------------------------
    // GAME FSM LOGIC (RUNNING / WIN / GAME OVER + SCORE)
    //-------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            game_state             <= S_RUNNING;
            freeze                 <= 1'b0;
            score                  <= 16'd0;
            lava_speed_boost_pulse <= 1'b0;
        end else if (game_tick) begin
            lava_speed_boost_pulse <= 1'b0;

            case (game_state)
                S_RUNNING: begin
                    freeze <= 1'b0;

                    // Difficulty / score from jumps
                    if (jump_landed_pulse) begin
                        score                  <= score + 1'b1;
                        lava_speed_boost_pulse <= 1'b1;
                    end

                    // Death conditions
                    if (in_lava || hit_lava_wall) begin
                        game_state <= S_GAME_OVER;
                        freeze     <= 1'b1;
                    end
                    // Win condition
                    else if (at_goal_region) begin
                        game_state <= S_WIN;
                        freeze     <= 1'b1;
                    end
                end

                S_GAME_OVER: begin
                    freeze     <= 1'b1;
                    game_state <= S_GAME_OVER;
                end

                S_WIN: begin
                    freeze     <= 1'b1;
                    game_state <= S_WIN;
                end

                default: begin
                    game_state <= S_RUNNING;
                    freeze     <= 1'b0;
                end
            endcase
        end
    end

    //-------------------------------------------------------
    // RENDERER (vga_driver_memory)
    //-------------------------------------------------------
    vga_driver_memory the_renderer(
        .x            (x),
        .y            (y),
        .active_pixels(active_pixels),
        .player_x     (player_x),
        .player_y     (player_y),
        .lava_wall_x  (lava_wall_x),
        .game_state   (game_state),
        .VGA_R        (VGA_R),
        .VGA_G        (VGA_G),
        .VGA_B        (VGA_B)
    );

endmodule
