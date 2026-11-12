`timescale 1ns / 1ps

module tb_Complex_Multiplier;

    parameter DATA_WIDTH = 16;

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

    localparam signed [15:0] MAX_Q15 = 16'sd32767;
    localparam signed [15:0] MIN_Q15 = -16'sd32768;

    Complex_Multiplier #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
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
        input signed [15:0] expected_r;
        input signed [15:0] expected_i;
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
        $display("Starting Complex_Multiplier tests...");
        $display("Q1.15: 0.5 = 16384, 0.25 = 8192");
        $display("-------------------------------------");

        // Test 1: (0.5 + j0) * (0.5 + j0)
        data_in_0_r =  16'sd16384;
        data_in_0_i =  16'sd0;
        data_in_1_r =  16'sd16384;
        data_in_1_i =  16'sd0;

        check_result(16'sd8192, 16'sd0, 1'b0, 1'b0,
                     "Real-only multiplication");

        // Test 2: (0.5 + j0.25) * (0.5 + j0.5)
        // Expected: 0.125 + j0.375
        data_in_0_r =  16'sd16384;
        data_in_0_i =  16'sd8192;
        data_in_1_r =  16'sd16384;
        data_in_1_i =  16'sd16384;

        check_result(16'sd4096, 16'sd12288, 1'b0, 1'b0,
                     "Positive complex multiplication");

        // Test 3: (-0.5 + j0.25) * (0.5 + j0.5)
        // Expected: -0.375 - j0.125
        data_in_0_r = -16'sd16384;
        data_in_0_i =  16'sd8192;
        data_in_1_r =  16'sd16384;
        data_in_1_i =  16'sd16384;

        check_result(-16'sd12288, -16'sd4096, 1'b0, 1'b0,
                     "Negative real input");

        // Test 4: (0 + j0.5) * (0.5 + j0)
        // Expected: 0 + j0.25
        data_in_0_r =  16'sd0;
        data_in_0_i =  16'sd16384;
        data_in_1_r =  16'sd16384;
        data_in_1_i =  16'sd0;

        check_result(16'sd0, 16'sd8192, 1'b0, 1'b0,
                     "Imaginary-only multiplication");

        // Test 5: zero multiplied by a complex value
        data_in_0_r =  16'sd0;
        data_in_0_i =  16'sd0;
        data_in_1_r =  16'sd16384;
        data_in_1_i = -16'sd8192;

        check_result(16'sd0, 16'sd0, 1'b0, 1'b0,
                     "Zero input");

        // Test 6: (MAX + jMAX) * (MAX + jMAX)
        // Real output is approximately zero.
        // Imaginary output exceeds Q1.15 maximum and saturates.
        data_in_0_r = MAX_Q15;
        data_in_0_i = MAX_Q15;
        data_in_1_r = MAX_Q15;
        data_in_1_i = MAX_Q15;

        check_result(16'sd0, MAX_Q15, 1'b0, 1'b1,
                     "Imaginary saturation");

        // Test 7: (MAX + jMAX) * (MAX - jMAX)
        // Real output saturates positive; imaginary output is zero.
        data_in_0_r = MAX_Q15;
        data_in_0_i = MAX_Q15;
        data_in_1_r = MAX_Q15;
        data_in_1_i = MIN_Q15;

        check_result(MAX_Q15, -16'sd1, 1'b1, 1'b0,
                     "Real saturation");

        // Test 8: (-1 + j0) * (1 + j0)
        // Expected: -1 + j0, with no overflow.
        data_in_0_r = MIN_Q15;
        data_in_0_i = 16'sd0;
        data_in_1_r = MAX_Q15;
        data_in_1_i = 16'sd0;

        check_result(-16'sd32767, 16'sd0, 1'b0, 1'b0,
                     "Negative boundary multiplication");

        $display("-------------------------------------");
        $display("Tests passed: %0d", passed);
        $display("Tests failed: %0d", failed);

        if (failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
