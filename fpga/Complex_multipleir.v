module Complex_Multiplier #(
	parameter DATA_WIDTH = 16
)(
	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_i,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_i,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_r,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_i,
	output reg overflow_r,
	output reg overflow_i
);

	reg signed [2 * DATA_WIDTH - 1 : 0] a_c;
	reg signed [2 * DATA_WIDTH - 1 : 0] a_d_j;
	reg signed [2 * DATA_WIDTH - 1 : 0] b_c_j;
	reg signed [2 * DATA_WIDTH - 1 : 0] b_d;

	reg signed [2 * DATA_WIDTH : 0] real_part;
	reg signed [2 * DATA_WIDTH : 0] imag_part;

	reg signed [2 * DATA_WIDTH - 1 : 0] out_re;
	reg signed [2 * DATA_WIDTH - 1 : 0] out_im;


	always @(*) begin
		real_part = 0;
		overflow_r = 1'b0;
	
		a_c = data_in_0_r * data_in_1_r;
		b_d = data_in_0_i * data_in_1_i;

		real_part = $signed({a_c[2*DATA_WIDTH-1], a_c})
          		   - $signed({b_d[2*DATA_WIDTH-1], b_d});
		real_part = real_part >>> 15;
		
		if (real_part > (2 ** (DATA_WIDTH - 1)) - 1) begin
    			data_out_r = (2 ** (DATA_WIDTH - 1)) - 1;
    			overflow_r = 1'b1;
		end
		else if (real_part < -(2 ** (DATA_WIDTH - 1))) begin
   			data_out_r = -(2 ** (DATA_WIDTH - 1));
    			overflow_r = 1'b1;
		end 
		else data_out_r = real_part;
	end

	always @(*) begin
		imag_part = 0;
		overflow_i = 1'b0;

		a_d_j = data_in_0_r * data_in_1_i;
		b_c_j = data_in_0_i * data_in_1_r;

		imag_part = $signed({a_d_j[2*DATA_WIDTH-1], a_d_j})
         		   + $signed({b_c_j[2*DATA_WIDTH-1], b_c_j});
		imag_part = imag_part >>> 15;
		
		if (imag_part > (2 ** (DATA_WIDTH - 1)) - 1) begin
    			data_out_i = (2 ** (DATA_WIDTH - 1)) - 1;
    			overflow_i = 1'b1;
		end
		else if (imag_part < -(2 ** (DATA_WIDTH - 1))) begin
   			data_out_i = -(2 ** (DATA_WIDTH - 1));
    			overflow_i = 1'b1;
		end 
		else data_out_i = imag_part;
	end

endmodule
