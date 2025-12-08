module player_physics (
    input  wire       clk,
    input  wire       rst,
    input  wire       game_tick,
    input  wire       move_left,
    input  wire       move_right,
    input  wire       jump,
    input  wire       on_ground,
    input  wire [9:0] support_y,
    input  wire       hit_ceiling,
    input  wire       hit_left_wall,
    input  wire       hit_right_wall,
    input  wire       freeze,

    output reg  [9:0] player_x,
    output reg  [9:0] player_y,
    output reg        jump_landed_pulse
);

    localparam SCREEN_W = 10'd640;
    localparam PLAYER_W = 10'd16;
    localparam PLAYER_H = 10'd16;

    localparam H_SPEED    = 10'd3;
    localparam signed [7:0] GRAVITY      = 8'sd1;
    localparam signed [7:0] JUMP_VEL     = -8'sd11;

    // Clamp vertical speed so we don't fall too fast and tunnel through platforms
    localparam signed [7:0] MAX_FALL_VEL = 8'sd8;    // max downward speed
    

    localparam START_X  = 10'd20;
    localparam START_Y  = 10'd360 - PLAYER_H;

    reg signed [7:0] vy;       // current vertical velocity
    reg signed [7:0] vy_next;  // next vertical velocity
    reg        was_in_air;

    reg [9:0] next_x;
    reg [9:0] next_y;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            player_x          <= START_X;
            player_y          <= START_Y;
            vy                <= 8'sd0;
            vy_next           <= 8'sd0;
            was_in_air        <= 1'b0;
            jump_landed_pulse <= 1'b0;
        end
        else if (game_tick) begin
            jump_landed_pulse <= 1'b0;

            if (!freeze) begin

                // ============================================================
                // HORIZONTAL MOVEMENT (use next_x as temp)
                // ============================================================
                next_x = player_x;

                if (move_left && !move_right) begin
                    if (!hit_left_wall && player_x > H_SPEED)
                        next_x = player_x - H_SPEED;
                end
                else if (move_right && !move_left) begin
                    if (!hit_right_wall &&
                        player_x < SCREEN_W - PLAYER_W - H_SPEED)
                        next_x = player_x + H_SPEED;
                end

                // Commit new x
                player_x <= next_x;

                // ============================================================
                // VERTICAL MOVEMENT WITH CLAMPED VELOCITY
                // ============================================================
                next_y  = player_y;
                vy_next = vy;

                if (jump && on_ground) begin
                    // Start jump
                    vy_next   = JUMP_VEL;
                    // sign-extend vy_next to 10 bits when adding to y
                    next_y    = player_y + {{2{vy_next[7]}}, vy_next};
                    was_in_air <= 1'b1;
                end
                else begin
                    if (!on_ground) begin
                        // apply gravity to velocity first
                        vy_next = vy + GRAVITY;

                        // clamp downward speed so we don't fall too fast
                        if (vy_next > MAX_FALL_VEL)
                            vy_next = MAX_FALL_VEL;

                        // compute next y using the clamped velocity
                        next_y = player_y + {{2{vy_next[7]}}, vy_next};

                        // prevent going into platform bottoms
                        if (hit_ceiling && vy_next < 0) begin
                            vy_next = 0;
                            next_y  = player_y;  // stop at current y
                        end
                    end
                    else begin
                        // standing on platform: snap to support height
                        next_y  = support_y - PLAYER_H;
                        vy_next = 0;

                        if (was_in_air) begin
                            jump_landed_pulse <= 1'b1;
                            was_in_air        <= 1'b0;
                        end
                    end
                end

                // Commit new y and velocity
                player_y <= next_y;
                vy       <= vy_next;

            end // !freeze
        end // game_tick
    end // always
endmodule