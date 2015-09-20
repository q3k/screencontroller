`timescale 1ns / 1ps

module top(
    input clk,
	 input reset,
    output reg led0,
    output reg led1,
	 
	 output LED_DR1,
	 output LED_DR2,
	 output LED_DG1,
	 output LED_DG2,
	 output LED_DB1,
	 output LED_DB2,
	 
	 output LED_S0,
	 output LED_S1,
	 output LED_S2,
	 
	 output LED_CLK,
	 output reg LED_STB,
	 output LED_OE
    );

reg [25:0] counter;

always @(posedge clk)
begin
	if (~reset) begin
		counter <= 0;
	end else begin
		if (counter == 50000000) begin
			counter <= 0;
			led0 <= ~led0;
			led1 <= 0;
		end else begin
			counter <= (counter + 1) & {26{1'b1}};
		end
	end
end

reg [2:0] bank;
assign LED_S0 = bank[0];
assign LED_S1 = bank[1];
assign LED_S2 = bank[2];

`define WIDTH 64
wire pixel_clock = counter[2];

reg [6:0] pixel_counter;

wire pixel_burst = (pixel_counter < `WIDTH);
assign LED_CLK = pixel_burst ? counter[3] : 0;

`define STATE_IDLE               3'b000
`define STATE_WAIT_FOR_BURST_END 3'b001
`define STATE_LATCH1             3'b010
`define STATE_LATCH2             3'b011
`define STATE_LATCH3             3'b100
`define STATE_LATCH4             3'b101
`define STATE_LATCH5             3'b110
reg [2:0] state;

reg LED_OE;

reg [3:0] cur_bit;
reg [11:0] delay;
wire [11:0] brightness = 3000;
reg [11:0] brightness_delay;

always @(posedge pixel_clock or negedge reset) begin
	if (~reset) begin
		pixel_counter <= `WIDTH;
		bank <= 0;
		state <= `STATE_IDLE;
		LED_STB <= 0;
		cur_bit <= 11;
		delay <= 0;
		LED_OE <= 1;
	end else begin
		// Pixel clock iteration
		if (counter[3] == 1) begin
			if (pixel_counter < `WIDTH) begin
				pixel_counter <= pixel_counter + 1;
			end
		end
		
		// Row logic
		case (state)
			`STATE_IDLE: begin
				state <= `STATE_WAIT_FOR_BURST_END;
				pixel_counter <= 0;
				LED_STB <= 0;
				LED_OE <= 0;
			end
			`STATE_WAIT_FOR_BURST_END: begin
				if (delay > 0)
					delay <= delay - 1;
				
				if (brightness_delay > 0)
					brightness_delay <= brightness_delay - 1;
				else
					LED_OE <= 1;
					
				if (delay == 0 && ~pixel_burst) begin
					state <= `STATE_LATCH1;
					LED_OE <= 1;
					delay <= (1 << (cur_bit));
					brightness_delay <= (1 << (cur_bit))/16;
				end
				LED_STB <= 0;
			end
			`STATE_LATCH1: begin
				LED_STB <= 0;
				state <= `STATE_LATCH2;
			end
			`STATE_LATCH2: begin
				LED_STB <= 1;
				state <= `STATE_LATCH3;
			end
			`STATE_LATCH3: begin
				LED_STB <= 1;
				state <= `STATE_LATCH4;
			end
			`STATE_LATCH4: begin
				LED_STB <= 0;
				state <= `STATE_LATCH5;
			end
			`STATE_LATCH5: begin
				LED_STB <= 0;
				state <= `STATE_IDLE;
				bank <= bank + 1;
				if (bank == 7) begin
					if (cur_bit == 0) begin
						cur_bit <= 11;
					end else begin
						cur_bit <= cur_bit - 1;
					end
				end
			end
		endcase
	end
end

reg [20:0] animation_counter;
always @(posedge clk) begin
	if (~reset) begin
		animation_counter <= 0;
	end else begin
		if (animation_counter < 2000000)
			animation_counter <= animation_counter + 1;
		else
			animation_counter <= 0;
	end
end
reg [4:0] color_cycle;
always @(posedge animation_counter[20] or negedge reset) begin
	if (~reset) begin
		color_cycle <= 0;
	end else begin
		color_cycle <= color_cycle + 1;
	end
end

wire [4:0] cur_x = pixel_burst ? (31-pixel_counter[4:0]) : 0;
wire [2:0] cur_row = 7-(bank+1);
wire cur_screen = pixel_burst ? pixel_counter[5] : 0;

wire [4:0] cur_y1 = (cur_screen << 4) + cur_row + 8;
wire [4:0] cur_y2 = (cur_screen << 4) + cur_row;

//wire [7:0] color_r1 = (cur_y1 == 31) ? 150 : 0;
//wire [7:0] color_g1 = 0;
//wire [7:0] color_b1 = 0;
//wire [7:0] color_r2 = 0;
//wire [7:0] color_g2 = (cur_y2 == 0) ? 150 : 0;
//wire [7:0] color_b2 = 0;

wire [7:0] color_r1;
wire [7:0] color_g1;
wire [7:0] color_b1;
wire [7:0] color_r2;
wire [7:0] color_g2;
wire [7:0] color_b2;


image image1(
	.x(cur_x+color_cycle),
	.y(cur_y1+(color_cycle<<1)),
	.r(color_r1),
	.g(color_g1),
	.b(color_b1)
);

image image2(
	.x(cur_x+color_cycle),
	.y(cur_y2+(color_cycle<<1)),
	.r(color_r2),
	.g(color_g2),
	.b(color_b2)
);

wire [11:0] color_r1_gamma;
wire [11:0] color_g1_gamma;
wire [11:0] color_b1_gamma;
wire [11:0] color_r2_gamma;
wire [11:0] color_g2_gamma;
wire [11:0] color_b2_gamma;

gamma gamma_r1(
	.in(color_r1),
	.out(color_r1_gamma)
);
gamma gamma_g1(
	.in(color_g1),
	.out(color_g1_gamma)
);
gamma gamma_b1(
	.in(color_b1),
	.out(color_b1_gamma)
);

gamma gamma_r2(
	.in(color_r2),
	.out(color_r2_gamma)
);
gamma gamma_g2(
	.in(color_g2),
	.out(color_g2_gamma)
);
gamma gamma_b2(
	.in(color_b2),
	.out(color_b2_gamma)
);
	

assign LED_DR1 = pixel_burst ? (color_r1_gamma >> cur_bit) : 0;
assign LED_DR2 = pixel_burst ? (color_r2_gamma >> cur_bit) : 0;
assign LED_DG1 = pixel_burst ? (color_g1_gamma >> cur_bit) : 0;
assign LED_DG2 = pixel_burst ? (color_g2_gamma >> cur_bit) : 0;
assign LED_DB1 = pixel_burst ? (color_b1_gamma >> cur_bit) : 0;
assign LED_DB2 = pixel_burst ? (color_b2_gamma >> cur_bit) : 0;

endmodule
