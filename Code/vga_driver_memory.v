module vga_driver_memory (
	input CLOCK_50,

	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:7] HEX2,
	output [6:0] HEX3,

	input [3:0] KEY,
	output [9:0] LEDR,
	input [9:0] SW,

	output VGA_BLANK_N,
	output reg [7:0] VGA_B,
	output VGA_CLK,
	output reg [7:0] VGA_G,
	output VGA_HS,
	output reg [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS
);

	assign HEX0 = 7'h00;
	assign HEX1 = 7'h00;
	assign HEX2 = 7'h00;
	assign HEX3 = 7'h00;

	//-------------------------------------------------------
	// VGA driver signals
	//-------------------------------------------------------
	wire active_pixels;
	wire [9:0] x;
	wire [9:0] y;
	wire clk = CLOCK_50;
	wire rst = SW[0];

	vga_driver the_vga(
		.clk(clk),
		.rst(rst),
		.vga_clk(VGA_CLK),
		.hsync(VGA_HS),
		.vsync(VGA_VS),
		.active_pixels(active_pixels),
		.xPixel(x),
		.yPixel(y),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N)
	);

	//-------------------------------------------------------
	// COLOR REGISTERS
	//-------------------------------------------------------
	reg [23:0] vga_color;

	localparam LIGHT_GRAY = 24'hC0C0C0;
	localparam DARK_GRAY  = 24'h505050;
	localparam LAVA_RED   = 24'hFF4500;
	localparam LAVA_GLOW  = 24'hFF8C00;
	localparam GOLD       = 24'hFFD700;

	//-------------------------------------------------------
	// LEVEL RENDERING LOGIC — MATCHES YOUR DRAWING
	//-------------------------------------------------------
	always @(*) begin
		// Default background
		vga_color = LIGHT_GRAY;

		//---------------------------------------------------
		// CEILING (top 100 px)
		//---------------------------------------------------
		if (y < 75)
			vga_color = DARK_GRAY;

		//---------------------------------------------------
		// LAVA FLOOR (380–480)
		//---------------------------------------------------
		if (y >= 380)
			vga_color = LAVA_RED;

		//---------------------------------------------------
		// LAVA GLOW (350–380) unless stone here
		//---------------------------------------------------
		//if (y >= 350 && y < 380)
			//vga_color = LAVA_GLOW;

		//---------------------------------------------------
		// PLATFORMS (dark gray) — based on drawing
		//---------------------------------------------------

		// Small left step
		if (x >= 0 && x <= 60 && y >= 360 && y <= 380)
			vga_color = DARK_GRAY;
			
		// Long platfoorm
		if (x >= 90 && x <= 270 && y >= 360 && y <= 380)
			vga_color = DARK_GRAY;

		// Middle ledge
		if (x >= 130 && x <= 200 && y >= 295 && y <= 310)
			vga_color = DARK_GRAY;

		// Floating mid tiny platform
		if (x >= 175 && x <= 210 && y >= 240 && y <= 255)
			vga_color = DARK_GRAY;

		// Tall block
		if (x >= 240 && x <= 270 && y >= 220 && y <= 380)
			vga_color = DARK_GRAY;
			
		// Right of tall block
		if (x >= 330 && x <= 380 && y >= 360 && y <= 380)
			vga_color = DARK_GRAY;	

		// 7
		if (x >= 380 && x <= 430 && y >= 295 && y <= 310)
			vga_color = DARK_GRAY;
			
		//8
		if (x >= 345 && x <= 380 && y >= 230 && y <= 245)
			vga_color = DARK_GRAY;
			
		// 9
		if (x >= 370 && x <= 430 && y >= 165 && y <= 180)
			vga_color = DARK_GRAY;
		//10
		if (x >= 475 && x <= 550 && y >= 190 && y <= 240)
			vga_color = DARK_GRAY;		
		//11
		if (x >= 540 && y >= 360 && y <= 380)
			vga_color = DARK_GRAY;

		// GOAL PLATFORM (gold podium)
		if (x >= 580 && x <= 630 && y >= 355 && y <= 360)
			vga_color = GOLD;

	end

	// OUTPUT RGB
	always @(*) begin
		VGA_R = vga_color[23:16];
		VGA_G = vga_color[15:8];
		VGA_B = vga_color[7:0];
	end

endmodule
