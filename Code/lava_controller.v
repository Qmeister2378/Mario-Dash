module lava_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire       game_tick,
    input  wire       any_input_level,
    input  wire       speed_boost_pulse,
    input  wire       freeze,
    input  wire [9:0] player_x,

    output reg  [9:0] lava_wall_x,
    output reg        hit_lava_wall
);
    localparam SCREEN_W         = 10'd640;
    localparam LAVA_WALL_WIDTH  = 10'd10;
    localparam LAVA_DELAY_TICKS = 9'd120;    // ~2 seconds at 60 Hz

    reg [7:0] lava_speed;
    reg       lava_enabled;
    reg       first_move_done;
    reg [8:0] delay_cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            lava_wall_x      <= 10'd0;
            lava_speed       <= 8'd1;
            lava_enabled     <= 1'b0;
            first_move_done  <= 1'b0;
            delay_cnt        <= 9'd0;
            hit_lava_wall    <= 1'b0;
        end else if (game_tick) begin
            hit_lava_wall <= 1'b0;

            if (freeze) begin
                // freeze everything in WIN / GAME_OVER
            end else begin
                // detect first player input
                if (!first_move_done && any_input_level)
                    first_move_done <= 1'b1;

                // start lava a few ticks after first move
                if (first_move_done && !lava_enabled) begin
                    if (delay_cnt < LAVA_DELAY_TICKS)
                        delay_cnt <= delay_cnt + 1'b1;
                    else
                        lava_enabled <= 1'b1;
                end

                // speed up lava over time (score-based)
                if (speed_boost_pulse)
                    lava_speed <= lava_speed + 1'b1;

                // move lava wall
                if (lava_enabled) begin
                    lava_wall_x <= lava_wall_x + lava_speed;
                    if (lava_wall_x > SCREEN_W)
                        lava_wall_x <= SCREEN_W; // clamp
                end

                // Collision with player
                if (lava_wall_x + LAVA_WALL_WIDTH >= player_x)
                    hit_lava_wall <= 1'b1;
            end
        end
    end

endmodule
