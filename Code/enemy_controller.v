module enemy_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire       game_tick,
    input  wire       freeze,
    input  wire [1:0] level,

    input  wire [9:0] player_x,
    input  wire [9:0] player_y,

    output reg  [9:0] enemy_x,
    output reg  [9:0] enemy_y,

    output reg  [9:0] proj0_x,
    output reg  [9:0] proj0_y,
    output reg        proj0_active,

    output reg  [9:0] proj1_x,
    output reg  [9:0] proj1_y,
    output reg        proj1_active,

    output reg  [9:0] proj2_x,
    output reg  [9:0] proj2_y,
    output reg        proj2_active,

    output reg  [9:0] proj3_x,
    output reg  [9:0] proj3_y,
    output reg        proj3_active,

    output wire       hit_enemy
);

    localparam SCREEN_H  = 10'd480;

    localparam PLAYER_W  = 10'd16;
    localparam PLAYER_H  = 10'd16;

    localparam ENEMY_W   = 10'd16;
    localparam ENEMY_H   = 10'd16;

    localparam PROJ_W    = 10'd5; //2
    localparam PROJ_H    = 10'd12; //5

    localparam NUM_PROJ  = 4;

    // Enemy bounds
    localparam ENEMY_Y_CONST    = 10'd120;
    localparam PATROL_X_MIN     = 10'd120;
    localparam PATROL_X_MAX     = 10'd580;
    localparam ENEMY_SPEED      = 10'd3;

    // Projectile
    localparam PROJ_SPEED       = 10'd6;
    localparam SHOOT_PERIOD_TCK = 8'd20;

    reg        dir_left;
    reg [7:0]  shoot_timer;

    // Internal projectile arrays
    reg [9:0] proj_x   [0:NUM_PROJ-1];
    reg [9:0] proj_y   [0:NUM_PROJ-1];
    reg       proj_act [0:NUM_PROJ-1];

    integer i;

    // Sequential movement / shooting
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            enemy_x     <= PATROL_X_MIN;
            enemy_y     <= ENEMY_Y_CONST;
            dir_left    <= 1'b0;

            for (i = 0; i < NUM_PROJ; i = i + 1) begin
                proj_x[i]   <= 10'd0;
                proj_y[i]   <= 10'd0;
                proj_act[i] <= 1'b0;
            end

            shoot_timer <= SHOOT_PERIOD_TCK;
        end else if (game_tick) begin
            if (level != 2'd1) begin
                // Enemy only active in Level 2 and reset when not on level 2
                enemy_x     <= PATROL_X_MIN;
                enemy_y     <= ENEMY_Y_CONST;
                dir_left    <= 1'b0;

                for (i = 0; i < NUM_PROJ; i = i + 1) begin
                    proj_x[i]   <= 10'd0;
                    proj_y[i]   <= 10'd0;
                    proj_act[i] <= 1'b0;
                end

                shoot_timer <= SHOOT_PERIOD_TCK;
            end else if (!freeze) begin
                // enemy movement
                if (!dir_left) begin
                    // moving right
                    if (enemy_x + ENEMY_W + ENEMY_SPEED <= PATROL_X_MAX)
                        enemy_x <= enemy_x + ENEMY_SPEED;
                    else begin
                        enemy_x  <= PATROL_X_MAX - ENEMY_W;
                        dir_left <= 1'b1;
                    end
                end else begin
                    // moving left
                    if (enemy_x >= PATROL_X_MIN + ENEMY_SPEED)
                        enemy_x <= enemy_x - ENEMY_SPEED;
                    else begin
                        enemy_x  <= PATROL_X_MIN;
                        dir_left <= 1'b0;
                    end
                end

                enemy_y <= ENEMY_Y_CONST;

                // shooting time
                if (shoot_timer > 0) begin
                    shoot_timer <= shoot_timer - 1'b1;
                end else begin
                    integer slot;
                    slot = -1;
                    for (i = 0; i < NUM_PROJ; i = i + 1) begin
                        if (!proj_act[i] && slot == -1)
                            slot = i;
                    end

                    if (slot != -1) begin
                        // Fire from enemy center
                        proj_act[slot] <= 1'b1;
                        proj_x[slot]   <= enemy_x + (ENEMY_W >> 1) - (PROJ_W >> 1);
                        proj_y[slot]   <= enemy_y + ENEMY_H;
                    end

                    // Reset timer afterwares
                    shoot_timer <= SHOOT_PERIOD_TCK;
                end

                // Falling Projectile
                for (i = 0; i < NUM_PROJ; i = i + 1) begin
                    if (proj_act[i]) begin
                        if (proj_y[i] + PROJ_H + PROJ_SPEED < SCREEN_H) begin
                            proj_y[i] <= proj_y[i] + PROJ_SPEED;
                        end else begin
                            proj_act[i] <= 1'b0; // off-screen
                        end
                    end
                end
            end
        end
    end

    // Drive individual outputs from arrays
    always @(*) begin
        proj0_x      = proj_x[0];
        proj0_y      = proj_y[0];
        proj0_active = proj_act[0];

        proj1_x      = proj_x[1];
        proj1_y      = proj_y[1];
        proj1_active = proj_act[1];

        proj2_x      = proj_x[2];
        proj2_y      = proj_y[2];
        proj2_active = proj_act[2];

        proj3_x      = proj_x[3];
        proj3_y      = proj_y[3];
        proj3_active = proj_act[3];
    end

    // checking collisons
    function automatic overlap_1d;
        input [9:0] a_min, a_max, b_min, b_max;
        begin
            overlap_1d = (a_max >= b_min) && (a_min <= b_max);
        end
    endfunction

    wire [9:0] player_x_min = player_x;
    wire [9:0] player_x_max = player_x + PLAYER_W - 1;
    wire [9:0] player_y_min = player_y;
    wire [9:0] player_y_max = player_y + PLAYER_H - 1;

    wire [9:0] enemy_x_min  = enemy_x;
    wire [9:0] enemy_x_max  = enemy_x + ENEMY_W - 1;
    wire [9:0] enemy_y_min  = enemy_y;
    wire [9:0] enemy_y_max  = enemy_y + ENEMY_H - 1;

    wire enemy_overlap =
        overlap_1d(player_x_min, player_x_max, enemy_x_min, enemy_x_max) &&
        overlap_1d(player_y_min, player_y_max, enemy_y_min, enemy_y_max);

    // Projectile overlaps
    reg proj_overlap_any;
    always @(*) begin
        proj_overlap_any = 1'b0;
        for (i = 0; i < NUM_PROJ; i = i + 1) begin
            if (proj_act[i]) begin
                if ( overlap_1d(player_x_min, player_x_max,
                                proj_x[i], proj_x[i] + PROJ_W - 1) &&
                     overlap_1d(player_y_min, player_y_max,
                                proj_y[i], proj_y[i] + PROJ_H - 1) ) begin
                    proj_overlap_any = 1'b1;
                end
            end
        end
    end

    assign hit_enemy = (level == 2'd1) && (enemy_overlap || proj_overlap_any);

endmodule

