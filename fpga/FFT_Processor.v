module FFT_Processor #(
    parameter FFT_SIZE = 16,
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire reset,
    input wire start,
    output wire  done
);

    //------------------------------------------------------
    // Controller <-> Butterfly
    wire butterfly_start;
    wire butterfly_done;

    //------------------------------------------------------
    // Controller <-> Twiddle ROM
    wire [3:0] twiddle_index;
    wire signed [DATA_WIDTH-1:0] W_r;
    wire signed [DATA_WIDTH-1:0] W_i;

    //------------------------------------------------------
    // Controller <-> Data RAM
    wire [3:0] read_addr_data_in_0;
    wire [3:0] read_addr_data_in_1;

    wire [3:0] write_addr_data_in_0;
    wire [3:0] write_addr_data_in_1;

    wire RAM_read_enable;
    wire RAM_write_enable;

    wire [31:0] RAM_read_data_0;
    wire [31:0] RAM_read_data_1;

    wire [31:0] RAM_write_data_0;
    wire [31:0] RAM_write_data_1;

    //------------------------------------------------------
    // RAM data unpacking: real and imaginary components
    wire signed [DATA_WIDTH-1:0] data_in_0_r;
    wire signed [DATA_WIDTH-1:0] data_in_0_i;
    wire signed [DATA_WIDTH-1:0] data_in_1_r;
    wire signed [DATA_WIDTH-1:0] data_in_1_i;

    //------------------------------------------------------
    // Butterfly outputs
    wire signed [DATA_WIDTH-1:0] data_out_X_r;
    wire signed [DATA_WIDTH-1:0] data_out_X_i;
    wire signed [DATA_WIDTH-1:0] data_out_Y_r;
    wire signed [DATA_WIDTH-1:0] data_out_Y_i;

    //------------------------------------------------------
    // RAM data packing and unpacking

    assign data_in_0_r = RAM_read_data_0[31:16];
    assign data_in_0_i = RAM_read_data_0[15:0];

    assign data_in_1_r = RAM_read_data_1[31:16];
    assign data_in_1_i = RAM_read_data_1[15:0];

    assign RAM_write_data_0 = {data_out_X_r, data_out_X_i};
    assign RAM_write_data_1 = {data_out_Y_r, data_out_Y_i};

    //------------------------------------------------------
    // FFT Controller

    FFT_Controller #(
        .FFT_SIZE(FFT_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) Controller (
        .clk(clk),
        .reset(reset),
        .start(start),

        .butterfly_done(butterfly_done),
        .butterfly_start(butterfly_start),

        .twiddle_index(twiddle_index),

        .read_addr_data_in_0(read_addr_data_in_0),
        .read_addr_data_in_1(read_addr_data_in_1),
        .RAM_read_enable(RAM_read_enable),

        .write_addr_data_in_0(write_addr_data_in_0),
        .write_addr_data_in_1(write_addr_data_in_1),
        .RAM_write_enable(RAM_write_enable),

        .done(done)
    );

    //------------------------------------------------------
    // Twiddle Factor ROM

    FFT_Twiddle_Factors_ROM #(
        .DATA_WIDTH(DATA_WIDTH)
    ) ROM (
        .clk(clk),
        .twiddle_index(twiddle_index),
        .W_r(W_r),
        .W_i(W_i)
    );

    //------------------------------------------------------
    // Data Memory

    FFT_Data_Memory #(
        .FFT_SIZE(FFT_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) RAM (
        .clk(clk),
		.reset(reset),

        .read_enable(RAM_read_enable),
        .write_enable(RAM_write_enable),

        .read_addr_0(read_addr_data_in_0),
        .read_addr_1(read_addr_data_in_1),

        .write_addr_0(write_addr_data_in_0),
        .write_addr_1(write_addr_data_in_1),

        .write_data_0(RAM_write_data_0),
        .write_data_1(RAM_write_data_1),

        .read_data_0(RAM_read_data_0),
        .read_data_1(RAM_read_data_1)
    );

    //------------------------------------------------------
    // Complex Butterfly

    Complex_Butterfly #(
        .DATA_WIDTH(DATA_WIDTH)
    ) Butterfly (
        .clk(clk),
        .reset(reset),
        .start(butterfly_start),

        .data_in_0_r(data_in_0_r),
        .data_in_0_i(data_in_0_i),

        .data_in_1_r(data_in_1_r),
        .data_in_1_i(data_in_1_i),

        .data_in_W_r(W_r),
        .data_in_W_i(W_i),

        .done(butterfly_done),

        .data_out_X_r(data_out_X_r),
        .data_out_X_i(data_out_X_i),

        .data_out_Y_r(data_out_Y_r),
        .data_out_Y_i(data_out_Y_i)
    );

endmodule
