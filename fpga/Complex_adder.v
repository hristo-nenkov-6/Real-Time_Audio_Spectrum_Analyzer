module Complex_adder #
(
	parameter DATA_WIDTH = 8
)(
	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_i,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_i,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_r,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_i,
	output reg signed overflow_r,
	output reg signed overflow_i
);
	reg signed [DATA_WIDTH : 0] data_real;
	reg signed [DATA_WIDTH : 0] data_imag;
	
	always @(*) begin
		overflow_r = 0;
		overflow_i = 0;
		data_real = '0;
		data_imag = '0;
		data_out_r = '0;
		data_out_i = '0;

		data_real =
    			{data_in_0_r[DATA_WIDTH-1], data_in_0_r} +
    			{data_in_1_r[DATA_WIDTH-1], data_in_1_r};

		data_imag =
    			{data_in_0_i[DATA_WIDTH-1], data_in_0_i} +
    			{data_in_1_i[DATA_WIDTH-1], data_in_1_i};
		
		data_out_r = data_real[DATA_WIDTH - 1 : 0];
		data_out_i = data_imag[DATA_WIDTH - 1 : 0];
		
		overflow_r = ((~data_in_0_r[DATA_WIDTH - 1]) & (~data_in_1_r[DATA_WIDTH - 1]) & (data_out_r[DATA_WIDTH - 1]) |
				(data_in_0_r[DATA_WIDTH - 1]) & (data_in_1_r[DATA_WIDTH - 1]) & (~data_out_r[DATA_WIDTH - 1]));
		overflow_i = ((~data_in_0_i[DATA_WIDTH - 1]) & (~data_in_1_i[DATA_WIDTH - 1]) & (data_out_i[DATA_WIDTH - 1]) |
				(data_in_0_i[DATA_WIDTH - 1]) & (data_in_1_i[DATA_WIDTH - 1]) & (~data_out_i[DATA_WIDTH - 1]));
	end

endmodule