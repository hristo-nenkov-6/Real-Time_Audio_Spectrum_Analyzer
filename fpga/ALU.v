module ALU #(
	parameter DATA_WIDTH = 16
)(
	input wire 		  [1:0] 			   sel,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_i,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_i,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_r,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_i,
	output reg signed overflow_r,
	output reg signed overflow_i
);
	
	localparam ADD = 2'b00;
	localparam SUB = 2'b01;
	localparam MUL = 2'b10;

	wire signed [DATA_WIDTH - 1 : 0] data_out_r_add;
	wire signed [DATA_WIDTH - 1 : 0] data_out_i_add;
	wire signed overflow_r_add;
	wire signed overflow_i_add;

	wire signed [DATA_WIDTH - 1 : 0] data_out_r_sub;
	wire signed [DATA_WIDTH - 1 : 0] data_out_i_sub;
	wire signed overflow_r_sub;
	wire signed overflow_i_sub;

	wire signed [DATA_WIDTH - 1 : 0] data_out_r_mul;
	wire signed [DATA_WIDTH - 1 : 0] data_out_i_mul;
	wire signed overflow_r_mul;
	wire signed overflow_i_mul;


	Complex_Adder 
		#(.DATA_WIDTH(DATA_WIDTH)) 
			adder (
				.data_in_0_r(data_in_0_r),
				.data_in_0_i(data_in_0_i),
				.data_in_1_r(data_in_1_r),
				.data_in_1_i(data_in_1_i),
				.data_out_r(data_out_r_add),
				.data_out_i(data_out_i_add),
				.overflow_r(overflow_r_add),
				.overflow_i(overflow_i_add)
			);	

	Complex_Substractor 
		#(.DATA_WIDTH(DATA_WIDTH)) 
			substractor (
				.data_in_0_r(data_in_0_r),
				.data_in_0_i(data_in_0_i),
				.data_in_1_r(data_in_1_r),
				.data_in_1_i(data_in_1_i),
				.data_out_r(data_out_r_sub),
				.data_out_i(data_out_i_sub),
				.overflow_r(overflow_r_sub),
				.overflow_i(overflow_i_sub)
			);	
	
	Complex_Multiplier 
		#(.DATA_WIDTH(DATA_WIDTH)) 
			multiplier (
				.data_in_0_r(data_in_0_r),
				.data_in_0_i(data_in_0_i),
				.data_in_1_r(data_in_1_r),
				.data_in_1_i(data_in_1_i),
				.data_out_r(data_out_r_mul),
				.data_out_i(data_out_i_mul),
				.overflow_r(overflow_r_mul),
				.overflow_i(overflow_i_mul)
			);	

	always @(*) begin
		case(sel)
			ADD: begin
				data_out_r = data_out_r_add;
				data_out_i = data_out_i_add;
				overflow_r = overflow_r_add;
				overflow_i = overflow_i_add;			
			end

			SUB: begin
				data_out_r = data_out_r_sub;
				data_out_i = data_out_i_sub;
				overflow_r = overflow_r_sub;
				overflow_i = overflow_i_sub;	
			end

			MUL: begin
				data_out_r = data_out_r_mul;
				data_out_i = data_out_i_mul;
				overflow_r = overflow_r_mul;
				overflow_i = overflow_i_mul;	
			end

			default: begin
				data_out_r = '0;
				data_out_i = '0;
				overflow_r = 0;
				overflow_i = 0;
			end
		endcase
	end

endmodule