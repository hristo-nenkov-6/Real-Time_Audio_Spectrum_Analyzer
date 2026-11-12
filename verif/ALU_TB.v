

`timescale 1ns / 1ps

module tb_ALU;

    parameter DATA_WIDTH = 16;

    reg [1:0] sel;
    reg signed [DATA_WIDTH-1:0] data_in_0_r;
    reg signed [DATA_WIDTH-1:0] data_in_0_i;
    reg signed [DATA_WIDTH-1:0] data_in_1_r;
    reg signed [DATA_WIDTH-1:0] data_in_1_i;

    wire signed [DATA_WIDTH-1:0] data_out_r;
    wire signed [DATA_WIDTH-1:0] data_out_i;
    wire overflow_r;
    wire overflow_i;

    integer passed = 0;
    integer failed = 0;

    localparam ADD = 2'b00;
    localparam SUB = 2'b01;
    localparam MUL = 2'b10;

    ALU #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .sel(sel),
        .data_in_0_r(data_in_0_r),
        .data_in_0_i(data_in_0_i),
        .data_in_1_r(data_in_1_r),
        .data_in_1_i(data_in_1_i),
        .data_out_r(data_out_r),
        .data_out_i(data_out_i),
        .overflow_r(overflow_r),
        .overflow_i(overflow_i)
    );

    task check_result;
        input signed [DATA_WIDTH-1:0] expected_r;
        input signed [DATA_WIDTH-1:0] expected_i;
        input expected_overflow_r;
        input expected_overflow_i;
        input [255:0] test_name;
        begin
            #10;

            if (data_out_r === expected_r &&
                data_out_i === expected_i &&
                overflow_r === expected_overflow_r &&
                overflow_i === expected_overflow_i) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s", test_name);
                $display("  Real: got %0d, expected %0d",
                         data_out_r, expected_r);
                $display("  Imag: got %0d, expected %0d",
                         data_out_i, expected_i);
                $display("  Overflow: got (%b,%b), expected (%b,%b)",
                         overflow_r, overflow_i,
                         expected_overflow_r, expected_overflow_i);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        $display("Starting ALU testbench");
        $display("----------------------------------------");

        // Test 1: Complex addition
        // (0.5 + j0.25) + (0.25 + j0.125)
        // Expected: 0.75 + j0.375
        sel = ADD;
        data_in_0_r = 16'sd16384;
        data_in_0_i = 16'sd8192;
        data_in_1_r = 16'sd8192;
        data_in_1_i = 16'sd4096;

        check_result(16'sd24576, 16'sd12288, 1'b0, 1'b0,
                     "Complex addition");

        // Test 2: Complex subtraction
        // (0.5 + j0.25) - (0.25 + j0.125)
        // Expected: 0.25 + j0.125
        sel = SUB;
        data_in_0_r = 16'sd16384;
        data_in_0_i = 16'sd8192;
        data_in_1_r = 16'sd8192;
        data_in_1_i = 16'sd4096;

        check_result(16'sd8192, 16'sd4096, 1'b0, 1'b0,
                     "Complex subtraction");

        // Test 3: Complex multiplication
        // (0.5 + j0.25) * (0.5 + j0.5)
        // Expected: 0.125 + j0.375
        sel = MUL;
        data_in_0_r = 16'sd16384;
        data_in_0_i = 16'sd8192;
        data_in_1_r = 16'sd16384;
        data_in_1_i = 16'sd16384;

        check_result(16'sd4096, 16'sd12288, 1'b0, 1'b0,
                     "Complex multiplication");

        // Test 4: Default selection
        sel = 2'b11;
        data_in_0_r = 16'sd16384;
        data_in_0_i = 16'sd8192;
        data_in_1_r = 16'sd16384;
        data_in_1_i = 16'sd16384;

        check_result(16'sd0, 16'sd0, 1'b0, 1'b0,
                     "Default selection");

        // Test 5: Addition with real overflow
        // 30000 + 10000 wraps in signed 16-bit arithmetic.
        sel = ADD;
        data_in_0_r = 16'sd30000;
        data_in_0_i = 16'sd0;
        data_in_1_r = 16'sd10000;
        data_in_1_i = 16'sd0;

        check_result(-16'sd25536, 16'sd0, 1'b1, 1'b0,
                     "Addition real overflow");

        // Test 6: Multiplication with imaginary saturation
        // (MAX + jMAX) * (MAX + jMAX)
        sel = MUL;
        data_in_0_r = 16'sd32767;
        data_in_0_i = 16'sd32767;
        data_in_1_r = 16'sd32767;
        data_in_1_i = 16'sd32767;

        check_result(16'sd0, 16'sd32767, 1'b0, 1'b1,
                     "Multiplication imaginary saturation");

        $display("----------------------------------------");
        $display("Tests passed: %0d", passed);
        $display("Tests failed: %0d", failed);

        if (failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
