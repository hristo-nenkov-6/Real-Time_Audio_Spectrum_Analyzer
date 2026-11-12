
`timescale 1ns / 1ps

module tb_Complex_Multiplier_1;

    // Inputs
    reg signed [15:0] data_in_0_r;
    reg signed [15:0] data_in_0_i;
    reg signed [15:0] data_in_1_r;
    reg signed [15:0] data_in_1_i;

    // Outputs
    wire signed [15:0] data_out_r;
    wire signed [15:0] data_out_i;
    wire overflow_r;
    wire overflow_i;

    integer errors;

    // DUT
    Complex_Multiplier #(
        .DATA_WIDTH(16)
    ) DUT (
        .data_in_0_r(data_in_0_r),
        .data_in_0_i(data_in_0_i),
        .data_in_1_r(data_in_1_r),
        .data_in_1_i(data_in_1_i),
        .data_out_r(data_out_r),
        .data_out_i(data_out_i),
        .overflow_r(overflow_r),
        .overflow_i(overflow_i)
    );

    // Test procedure
    task check_result;
        input [8*40-1:0] test_name;
        input signed [15:0] expected_r;
        input signed [15:0] expected_i;
        input expected_overflow_r;
        input expected_overflow_i;

        begin
            #10;

            $display("----------------------------------------");
            $display("Test: %0s", test_name);
            $display("Real:      %d (0x%04h)", data_out_r, data_out_r);
            $display("Imaginary: %d (0x%04h)", data_out_i, data_out_i);
            $display("Overflow R: %b", overflow_r);
            $display("Overflow I: %b", overflow_i);

            if ((data_out_r !== expected_r) ||
                (data_out_i !== expected_i) ||
                (overflow_r !== expected_overflow_r) ||
                (overflow_i !== expected_overflow_i)) begin

                $display("ERROR: Test failed!");
                $display("Expected R: 0x%04h, I: 0x%04h",
                         expected_r, expected_i);
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
        end
    endtask

    initial begin

        errors = 0;

        // ====================================
        // TEST 1: Unity twiddle multiplication
        // ====================================

        data_in_0_r = 16'h0400;  // 0.03125
        data_in_0_i = 16'h0000;

        data_in_1_r = 16'h7FFF;  // Approximately 1.0
        data_in_1_i = 16'h0000;

        check_result(
            "Constant input * unity",
            16'h03FF,
            16'h0000,
            1'b0,
            1'b0
        );

        // ====================================
        // TEST 2: Real number multiplication
        // ====================================

        data_in_0_r = 16'h4000;  // 0.5
        data_in_0_i = 16'h0000;

        data_in_1_r = 16'h4000;  // 0.5
        data_in_1_i = 16'h0000;

        check_result(
            "0.5 * 0.5",
            16'h2000,            // 0.25
            16'h0000,
            1'b0,
            1'b0
        );

        // ====================================
        // TEST 3: Imaginary multiplication
        // ====================================

        data_in_0_r = 16'h0000;
        data_in_0_i = 16'h4000;  // j0.5

        data_in_1_r = 16'h0000;
        data_in_1_i = 16'h4000;  // j0.5

        check_result(
            "j0.5 * j0.5",
            16'hE000,            // -0.25
            16'h0000,
            1'b0,
            1'b0
        );

        // ====================================
        // TEST 4: Complex multiplication
        // ====================================

        data_in_0_r = 16'h4000;  // 0.5 + j0.25
        data_in_0_i = 16'h2000;

        data_in_1_r = 16'h4000;  // 0.5 + j0.5
        data_in_1_i = 16'h4000;

        check_result(
            "Complex multiplication",
            16'h1000,            // 0.125
            16'h3000,            // 0.375
            1'b0,
            1'b0
        );

        // ====================================
        // TEST 5: Negative real multiplication
        // ====================================

        data_in_0_r = -16'sh4000; // -0.5
        data_in_0_i = 16'h0000;

        data_in_1_r = 16'h4000;   // 0.5
        data_in_1_i = 16'h0000;

        check_result(
            "Negative real multiplication",
            16'hE000,             // -0.25
            16'h0000,
            1'b0,
            1'b0
        );

        // ====================================
        // TEST 6: Zero multiplication
        // ====================================

        data_in_0_r = 16'h0000;
        data_in_0_i = 16'h0000;

        data_in_1_r = 16'h7FFF;
        data_in_1_i = 16'h7FFF;

        check_result(
            "Zero multiplication",
            16'h0000,
            16'h0000,
            1'b0,
            1'b0
        );

        // ====================================
        // FINAL RESULT
        // ====================================

        $display("\n========================================");

        if (errors == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("TESTBENCH FAILED: %0d errors", errors);

        $display("========================================");

        $finish;
    end

endmodule
