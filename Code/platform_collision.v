module platform_collision (
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,

    // ground support info
    output wire       on_ground,
    output wire [9:0] support_y,

    // extra collisions
    output wire       hit_ceiling,
    output wire       hit_left_wall,
    output wire       hit_right_wall,

    // game events
    output wire       at_goal_region,
    output wire       in_lava
);
    localparam PLAYER_W = 10'd16;
    localparam PLAYER_H = 10'd16;

    localparam LAVA_Y   = 10'd380;

    // ----------------------------------------------------------------
    // PLATFORM DEFINITIONS (must match renderer)
    // ----------------------------------------------------------------

    // Platform 1: Small left step (0–60, 360–380)
    localparam P1_X_MIN = 10'd0;
    localparam P1_X_MAX = 10'd60;
    localparam P1_Y_TOP = 10'd360;
    localparam P1_Y_BOT = 10'd380;

    // Platform 2: Long ground platform (90–270, 360–380)
    localparam P2_X_MIN = 10'd90;
    localparam P2_X_MAX = 10'd270;
    localparam P2_Y_TOP = 10'd360;
    localparam P2_Y_BOT = 10'd380;

    // Platform 3: Middle ledge (130–200, 295–310)
    localparam P3_X_MIN = 10'd130;
    localparam P3_X_MAX = 10'd200;
    localparam P3_Y_TOP = 10'd295;
    localparam P3_Y_BOT = 10'd310;

    // Platform 4: Floating mid tiny platform (175–210, 240–255)
    localparam P4_X_MIN = 10'd175;
    localparam P4_X_MAX = 10'd210;
    localparam P4_Y_TOP = 10'd240;
    localparam P4_Y_BOT = 10'd255;

    // Platform 5: Tall block (240–270, 220–380)
    localparam P5_X_MIN = 10'd240;
    localparam P5_X_MAX = 10'd270;
    localparam P5_Y_TOP = 10'd220;
    localparam P5_Y_BOT = 10'd380;

    // Platform 6: Right of tall block (330–380, 360–380)
    localparam P6_X_MIN = 10'd330;
    localparam P6_X_MAX = 10'd380;
    localparam P6_Y_TOP = 10'd360;
    localparam P6_Y_BOT = 10'd380;

    // Platform 7: Mid ledge (380–430, 295–310)
    localparam P7_X_MIN = 10'd380;
    localparam P7_X_MAX = 10'd430;
    localparam P7_Y_TOP = 10'd295;
    localparam P7_Y_BOT = 10'd310;

    // Platform 8: Higher small ledge (345–380, 230–245)
    localparam P8_X_MIN = 10'd345;
    localparam P8_X_MAX = 10'd380;
    localparam P8_Y_TOP = 10'd230;
    localparam P8_Y_BOT = 10'd245;

    // Platform 9: High ledge (370–430, 165–180)
    localparam P9_X_MIN = 10'd370;
    localparam P9_X_MAX = 10'd430;
    localparam P9_Y_TOP = 10'd165;
    localparam P9_Y_BOT = 10'd180;

    // Platform 10: Elevated platform (475–550, 190–240)
    localparam P10_X_MIN = 10'd475;
    localparam P10_X_MAX = 10'd550;
    localparam P10_Y_TOP = 10'd190;
    localparam P10_Y_BOT = 10'd240;

    // Platform 11: Far right ground (540–639, 360–380)
    localparam P11_X_MIN = 10'd540;
    localparam P11_X_MAX = 10'd639;
    localparam P11_Y_TOP = 10'd360;
    localparam P11_Y_BOT = 10'd380;

    // Goal platform: Gold podium (580–630, 355–360)
    localparam PG_X_MIN = 10'd580;
    localparam PG_X_MAX = 10'd630;
    localparam PG_Y_TOP = 10'd355;
    localparam PG_Y_BOT = 10'd360;

    //-----------------------------------------------------------------
    // Helper geometry
    //-----------------------------------------------------------------
    wire [9:0] feet_y   = player_y + PLAYER_H;
    wire [9:0] head_y   = player_y;
    wire [9:0] px_left  = player_x;
    wire [9:0] px_right = player_x + PLAYER_W - 1;

    reg        r_has_support;
    reg [9:0]  r_support_y;
    reg        r_hit_left;
    reg        r_hit_right;
    reg        r_hit_ceiling;

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

    // ============================================================
    //  ONE-PASS COLLISION LOGIC (combinational)
    //  All platforms follow the same structure; side collisions fixed.
    // ============================================================
    always @(*) begin
        r_has_support = 1'b0;
        r_support_y   = 10'd0;
        r_hit_left    = 1'b0;
        r_hit_right   = 1'b0;
        r_hit_ceiling = 1'b0;

        // --- MACRO FOR EACH PLATFORM ---
        `define HANDLE_PLATFORM(PX_MIN, PX_MAX, PY_TOP, PY_BOT)         \
            if (overlap_x(px_left, px_right, PX_MIN, PX_MAX)) begin    \
                if (feet_y >= PY_TOP && feet_y <= PY_TOP + 2) begin    \
                    if (!r_has_support || (PY_TOP > r_support_y)) begin\
                        r_has_support = 1'b1;                           \
                        r_support_y   = PY_TOP;                         \
                    end                                                 \
                end                                                     \
                if (head_y <= PY_BOT && head_y >= PY_BOT - 2 &&         \
                    overlap_y(head_y, feet_y, PY_TOP, PY_BOT)) begin   \
                    r_hit_ceiling = 1'b1;                               \
                end                                                     \
            end                                                         \
            if (overlap_y(head_y, feet_y, PY_TOP, PY_BOT)) begin        \
                /* LEFT wall */                                         \
                if (px_left <= PX_MAX && px_left >= PX_MAX - 2)         \
                    r_hit_left = 1'b1;                                  \
                /* RIGHT wall */                                        \
                if (px_right >= PX_MIN && px_right <= PX_MIN + 2)       \
                    r_hit_right = 1'b1;                                 \
            end

        // Apply to each platform
        `HANDLE_PLATFORM(P1_X_MIN,  P1_X_MAX,  P1_Y_TOP,  P1_Y_BOT)
        `HANDLE_PLATFORM(P2_X_MIN,  P2_X_MAX,  P2_Y_TOP,  P2_Y_BOT)
        `HANDLE_PLATFORM(P3_X_MIN,  P3_X_MAX,  P3_Y_TOP,  P3_Y_BOT)
        `HANDLE_PLATFORM(P4_X_MIN,  P4_X_MAX,  P4_Y_TOP,  P4_Y_BOT)
        `HANDLE_PLATFORM(P5_X_MIN,  P5_X_MAX,  P5_Y_TOP,  P5_Y_BOT)
        `HANDLE_PLATFORM(P6_X_MIN,  P6_X_MAX,  P6_Y_TOP,  P6_Y_BOT)
        `HANDLE_PLATFORM(P7_X_MIN,  P7_X_MAX,  P7_Y_TOP,  P7_Y_BOT)
        `HANDLE_PLATFORM(P8_X_MIN,  P8_X_MAX,  P8_Y_TOP,  P8_Y_BOT)
        `HANDLE_PLATFORM(P9_X_MIN,  P9_X_MAX,  P9_Y_TOP,  P9_Y_BOT)
        `HANDLE_PLATFORM(P10_X_MIN, P10_X_MAX, P10_Y_TOP, P10_Y_BOT)
        `HANDLE_PLATFORM(P11_X_MIN, P11_X_MAX, P11_Y_TOP, P11_Y_BOT)
        `HANDLE_PLATFORM(PG_X_MIN,  PG_X_MAX,  PG_Y_TOP,  PG_Y_BOT)

        `undef HANDLE_PLATFORM
    end

    // ============================================================
    // Final outputs
    // ============================================================
    assign support_y = r_support_y;
    assign on_ground = r_has_support &&
                       (feet_y >= r_support_y) &&
                       (feet_y <= r_support_y + 2);

    assign hit_ceiling    = r_hit_ceiling;
    assign hit_left_wall  = r_hit_left;
    assign hit_right_wall = r_hit_right;

    assign at_goal_region =
        overlap_x(px_left, px_right, PG_X_MIN, PG_X_MAX) &&
        (feet_y >= PG_Y_TOP) &&
        (feet_y <= PG_Y_TOP + 5);
		  
		  
    assign in_lava = 1'b0;//(feet_y >= LAVA_Y) && !on_ground;

endmodule
