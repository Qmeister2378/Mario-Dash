module platform_collision (
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire [1:0] level,
    input  wire [9:0] lava_height,
	 input  wire 		 hit_lava_wall,

    output wire       on_ground,
    output wire [9:0] support_y,

    output wire       hit_ceiling,
    output wire       hit_left_wall,
    output wire       hit_right_wall,

    output wire       at_goal_region,
    output wire       in_lava
);

    // ---------------- CONSTANTS ----------------
    localparam PLAYER_W = 10'd16;
    localparam PLAYER_H = 10'd16;

    localparam LAVA_Y   = 10'd380;
    localparam LANDING_TOL = 10'd8;
    localparam CEILING_TOL = 10'd12;

    localparam SCREEN_HEIGHT = 10'd480;
    localparam LAVA_X_START  = 270;
    localparam LAVA_WIDTH    = 40;

    // ---------------- PLATFORM STORAGE ----------------
    reg [9:0] PX_MIN [0:11];
    reg [9:0] PX_MAX [0:11];
    reg [9:0] PY_TOP [0:11];
    reg [9:0] PY_BOT [0:11];

    // Goal region
    reg [9:0] PG_X_MIN, PG_X_MAX, PG_Y_TOP, PG_Y_BOT;

    integer i;

    // ---------------- PLATFORM DEFINITIONS ----------------
    always @(*) begin
        // Clear everything first
        for (i = 0; i < 12; i = i + 1) begin
            PX_MIN[i] = 10'd0;
            PX_MAX[i] = 10'd0;
            PY_TOP[i] = 10'd0;
            PY_BOT[i] = 10'd0;
        end

        if (level == 2'd0) begin
            // LEVEL 1
            PX_MIN[0]  = 0;   PX_MAX[0]  = 60;  PY_TOP[0]  = 360; PY_BOT[0]  = 380;
            PX_MIN[1]  = 90;  PX_MAX[1]  = 270; PY_TOP[1]  = 360; PY_BOT[1]  = 380;
            PX_MIN[2]  = 130; PX_MAX[2]  = 200; PY_TOP[2]  = 295; PY_BOT[2]  = 310;
            PX_MIN[3]  = 175; PX_MAX[3]  = 210; PY_TOP[3]  = 240; PY_BOT[3]  = 255;
            PX_MIN[4]  = 240; PX_MAX[4]  = 270; PY_TOP[4]  = 220; PY_BOT[4]  = 380;
            PX_MIN[5]  = 330; PX_MAX[5]  = 380; PY_TOP[5]  = 360; PY_BOT[5]  = 380;
            PX_MIN[6]  = 380; PX_MAX[6]  = 430; PY_TOP[6]  = 295; PY_BOT[6]  = 310;
            PX_MIN[7]  = 345; PX_MAX[7]  = 380; PY_TOP[7]  = 230; PY_BOT[7]  = 245;
            PX_MIN[8]  = 370; PX_MAX[8]  = 430; PY_TOP[8]  = 165; PY_BOT[8]  = 180;
            PX_MIN[9]  = 475; PX_MAX[9]  = 550; PY_TOP[9]  = 190; PY_BOT[9]  = 240;
            PX_MIN[10] = 540; PX_MAX[10] = 639; PY_TOP[10] = 360; PY_BOT[10] = 380;
            // PX[11] stays zero
            PG_X_MIN = 580; PG_X_MAX = 630; PG_Y_TOP = 355; PG_Y_BOT = 360;
        end else begin
            // LEVEL 2
            PX_MIN[0] = 0;   PX_MAX[0] = 100; PY_TOP[0] = 400; PY_BOT[0] = 480;
            PX_MIN[1] = 200; PX_MAX[1] = 300; PY_TOP[1] = 400; PY_BOT[1] = 480;
            PX_MIN[2] = 400; PX_MAX[2] = 500; PY_TOP[2] = 400; PY_BOT[2] = 480;
            PX_MIN[3] = 550; PX_MAX[3] = 639; PY_TOP[3] = 400; PY_BOT[3] = 480;

            PX_MIN[4] = 120; PX_MAX[4] = 180; PY_TOP[4] = 370; PY_BOT[4] = 385;
            PX_MIN[5] = 350; PX_MAX[5] = 400; PY_TOP[5] = 350; PY_BOT[5] = 365;
            PX_MIN[6] = 550; PX_MAX[6] = 639; PY_TOP[6] = 50;  PY_BOT[6] = 65;

            PG_X_MIN = 10; PG_X_MAX = 60; PG_Y_TOP = 395; PG_Y_BOT = 400;
        end
    end

    // ---------------- PLAYER BOUNDS ----------------
    wire [9:0] feet_y   = player_y + PLAYER_H;
    wire [9:0] head_y   = player_y;
    wire [9:0] px_left  = player_x;
    wire [9:0] px_right = player_x + PLAYER_W - 1;

    wire [9:0] lava_band_y_min = SCREEN_HEIGHT - lava_height;
    wire [9:0] lava_band_y_max = SCREEN_HEIGHT - 1;

    // ---------------- COLLISION REGISTERS ----------------
    reg       r_has_support;
    reg [9:0] r_support_y;
    reg       r_hit_left;
    reg       r_hit_right;
    reg       r_hit_ceiling;

    // ---------------- OVERLAP FUNCTIONS ----------------
    function overlap_x;
        input [9:0] a_min, a_max, b_min, b_max;
        begin
            overlap_x = (a_max >= b_min) && (a_min <= b_max);
        end
    endfunction

    function overlap_y;
        input [9:0] a_min, a_max, b_min, b_max;
        begin
            overlap_y = (a_max >= b_min) && (a_min <= b_max);
        end
    endfunction

    // ---------------- MAIN COLLISION CHECK ----------------
    always @(*) begin
        r_has_support = 1'b0;
        r_support_y   = 10'd0;
        r_hit_left    = 1'b0;
        r_hit_right   = 1'b0;
        r_hit_ceiling = 1'b0;

        for (i = 0; i < 12; i = i + 1) begin
            if (overlap_x(px_left, px_right, PX_MIN[i], PX_MAX[i])) begin
                // ground / platform support
                if (feet_y >= PY_TOP[i] && feet_y <= PY_TOP[i] + LANDING_TOL) begin
                    if (!r_has_support || (PY_TOP[i] > r_support_y)) begin
                        r_has_support = 1'b1;
                        r_support_y   = PY_TOP[i];
                    end
                end

                // ceiling hit
                if ( head_y <= PY_BOT[i] &&
                     head_y >= (PY_BOT[i] - CEILING_TOL) &&
                     overlap_y(head_y, feet_y, PY_TOP[i], PY_BOT[i]) ) begin
                    r_hit_ceiling = 1'b1;
                end
            end

            // side walls
            if (overlap_y(head_y, feet_y, PY_TOP[i], PY_BOT[i])) begin
                if (px_left  <= PX_MAX[i] && px_left  >= PX_MAX[i] - 2) r_hit_left  = 1'b1;
                if (px_right >= PX_MIN[i] && px_right <= PX_MIN[i] + 2) r_hit_right = 1'b1;
            end
        end
    end

    // ---------------- ASSIGN OUTPUT COLLISIONS ----------------
    assign support_y = r_support_y;
    assign on_ground =
        r_has_support &&
        (feet_y >= r_support_y) &&
        (feet_y <= r_support_y + LANDING_TOL);

    assign hit_ceiling   = r_hit_ceiling;
    assign hit_left_wall = r_hit_left;
    assign hit_right_wall= r_hit_right;

    // ---------------- GOAL DETECTION ----------------
    assign at_goal_region =
        overlap_x(px_left, px_right, PG_X_MIN, PG_X_MAX) &&
        overlap_y(head_y, feet_y, PG_Y_TOP, PG_Y_BOT);

    // Rising lava hit (level 0)
    wire rising_lava_hit =
        (level == 2'd0) && (lava_height != 10'd0) &&
        overlap_x(px_left, px_right, LAVA_X_START, LAVA_X_START + LAVA_WIDTH - 1) &&
        overlap_y(head_y, feet_y, lava_band_y_min, lava_band_y_max);

    // Water pits (level 2)
    wire in_water_l2 =
        (feet_y >= 10'd400) && (
            (px_left >= 10'd101 && px_right < 10'd200) ||
            (px_left >= 10'd301 && px_right < 10'd400) ||
            (px_left >= 10'd501 && px_right < 10'd550)
        );

    reg r_in_lava;
    always @(*) begin
        case (level)
            2'd0: r_in_lava = ((feet_y >= LAVA_Y) && !on_ground) || rising_lava_hit || hit_lava_wall;
            2'd1: r_in_lava = in_water_l2;
            default: r_in_lava = 1'b0;
        endcase
    end

    assign in_lava = r_in_lava;

endmodule