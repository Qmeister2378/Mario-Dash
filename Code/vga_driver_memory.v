module vga_driver_memory (
	input 		          		CLOCK_50,

	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,

	input 		     [3:0]		KEY,
	output		     [9:0]		LEDR,
	input 		     [9:0]		SW,

	output		          		VGA_BLANK_N,
	output reg	     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output reg	     [7:0]		VGA_G,
	output		          		VGA_HS,
	output reg	     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS
);

	// Turn off 7-seg displays
	assign HEX0 = 7'h00;
	assign HEX1 = 7'h00;
	assign HEX2 = 7'h00;
	assign HEX3 = 7'h00;

	// VGA driver signals
	wire active_pixels;
	wire [9:0]x; // current x
	wire [9:0]y; // current y - 10 bits = 1024 ... a little bit more than we need

	wire clk = CLOCK_50;
	wire rst = SW[0];

	assign LEDR[0] = active_pixels;
	assign LEDR[1] = flag;

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

// PIXEL COLOR GENERATOR — MARIO-STYLE LEVEL MAP

	reg [23:0] vga_color;

	always @(*) begin

	// DEFAULT SKY COLOR (background)
		vga_color = 24'h87CEEB;   // light blue sky

	// GROUND + GRASS STRIP
		if (y >= 380 && y < 400)
			vga_color = 24'h228B22;  // grass green

		if (y >= 400 && y < 480)
			vga_color = 24'h8B4513;  // dirt brown

	// LAVA PITS (3 pits)
		// pit 1
		if (x >= 100 && x <= 200 && y >= 400)
			vga_color = 24'hFF4500;  // lava orange-red

		// pit 2
		if (x >= 350 && x <= 450 && y >= 400)
			vga_color = 24'hFF4500;

		// pit 3
		if (x >= 520 && x <= 600 && y >= 400)
			vga_color = 24'hFF4500;

	// LAVA "HEAT GLOW" ABOVE PITS
		if ((x >= 100 && x <= 200 && y >= 380 && y < 400) ||
		    (x >= 350 && x <= 450 && y >= 380 && y < 400) ||
		    (x >= 520 && x <= 600 && y >= 380 && y < 400))
			vga_color = 24'hFF8C00;  // bright orange glow

	// FLOATING PLATFORMS (wood)
		// platform 1
		if (x >= 250 && x <= 330 && y >= 250 && y <= 260)
			vga_color = 24'hA0522D;

		// platform 2
		if (x >= 450 && x <= 530 && y >= 300 && y <= 310)
			vga_color = 24'hA0522D;

	end


// OUTPUT RGB to VGA pins
	always @(*) begin
		VGA_R = vga_color[23:16];
		VGA_G = vga_color[15:8];
		VGA_B = vga_color[7:0];
	end

endmodule
