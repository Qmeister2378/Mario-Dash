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

    localparam H_SPEED  = 10'd3;
    localparam GRAVITY  = 8'sd1;
    localparam JUMP_VEL = -8'sd10;

    // Starting on Platform 1 (small left step)
    localparam P1_Y_TOP = 10'd360;
    localparam START_X  = 10'd20;

    reg signed [7:0] vy;
    reg              was_in_air;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            player_x          <= START_X;
            player_y          <= P1_Y_TOP - PLAYER_H;
            vy                <= 8'sd0;
            jump_landed_pulse <= 1'b0;
            was_in_air        <= 1'b0;
        end else if (game_tick) begin
            jump_landed_pulse <= 1'b0;

            if (freeze) begin
                // Everything frozen in WIN / GAME_OVER
            end else begin
                // ---------------- Horizontal movement ----------------
                if (move_left && !move_right && !hit_left_wall) begin
                    if (player_x > H_SPEED)
                        player_x <= player_x - H_SPEED;
                end else if (move_right && !move_left && !hit_right_wall) begin
                    if (player_x < SCREEN_W - PLAYER_W - H_SPEED)
                        player_x <= player_x + H_SPEED;
                end

                // ---------------- Jumping + Gravity ----------------
                if (jump && on_ground) begin
                    // start jump
                    vy         <= JUMP_VEL;
                    player_y   <= player_y + JUMP_VEL;
                    was_in_air <= 1'b1;
                end else begin
                    // apply gravity
                    if (!on_ground) begin
                        vy       <= vy + GRAVITY;
                        player_y <= player_y + vy;

                        // prevent going into platform bottoms
                        if (hit_ceiling && vy < 0) begin
                            vy <= 8'sd0;
                        end
                    end else begin
                        // standing on platform
                        player_y <= support_y - PLAYER_H;
                        vy       <= 8'sd0;

                        // detect landing after being in air
                        if (was_in_air) begin
                            jump_landed_pulse <= 1'b1;
                            was_in_air        <= 1'b0;
                        end
                    end
                end
            end
        end
    end

endmodule
