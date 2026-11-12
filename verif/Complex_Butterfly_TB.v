`timescale 1ns / 1ps

module tb_Complex_Butterfly;

    parameter DATA_WIDTH = 16;

    // Inputs
    reg clk;
    reg reset;
    reg start;

    reg signed [DATA_WIDTH-1:0] data_in_0_r;
    reg signed [DATA_WIDTH-1:0] data_in_0_i;
    reg signed [DATA_WIDTH-1:0] data_in_1_r;
    reg signed [DATA_WIDTH-1:0] data_in_1_i;
    reg signed [DATA_WIDTH-1:0] data_in_W_r;
    reg signed [DATA_WIDTH-1:0] data_in_W_i;

    // Outputs
    wire done;

    wire signed [DATA_WIDTH-1:0] data_out_X_r;
    wire signed [DATA_WIDTH-1:0] data_out_X_i;
    wire signed [DATA_WIDTH-1:0] data_out_Y_r;
    wire signed [DATA_WIDTH-1:0] data_out_Y_i;

    integer errors;
    integer test_number;
    integer cycles;

    // Device under test
    Complex_Butterfly #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),

        .data_in_0_r(data_in_0_r),
        .data_in_0_i(data_in_0_i),
        .data_in_1_r(data_in_1_r),
        .data_in_1_i(data_in_1_i),
        .data_in_W_r(data_in_W_r),
        .data_in_W_i(data_in_W_i),

        .done(done),

        .data_out_X_r(data_out_X_r),
        .data_out_X_i(data_out_X_i),
        .data_out_Y_r(data_out_Y_r),
        .data_out_Y_i(data_out_Y_i)
    );

    // 100 MHz clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;


    // --------------------------------------------------
    // Task: Run one butterfly operation and verify results
    // --------------------------------------------------
    task run_test;

        input signed [15:0] a_r;
        input signed [15:0] a_i;
        input signed [15:0] b_r;
        input signed [15:0] b_i;
        input signed [15:0] w_r;
        input signed [15:0] w_i;

        input signed [15:0] exp_x_r;
        input signed [15:0] exp_x_i;
        input signed [15:0] exp_y_r;
        input signed [15:0] exp_y_i;

        input [255:0] test_name;

        begin

            test_number = test_number + 1;

            $display("");
            $display("======================================");
            $display("TEST %0d: %0s", test_number, test_name);
            $display("======================================");

            // Apply inputs on a falling edge
            @(negedge clk);

            data_in_0_r = a_r;
            data_in_0_i = a_i;

            data_in_1_r = b_r;
            data_in_1_i = b_i;

            data_in_W_r = w_r;
            data_in_W_i = w_i;

            // Start pulse
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait for done, with timeout
            cycles = 0;

            while ((done !== 1'b1) && (cycles < 10)) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            // Check completion
            if (done !== 1'b1) begin

                $display("FAIL: Timeout waiting for done.");
                errors = errors + 1;

            end
            else begin

                $display("Completion detected after %0d wait cycles.",
                         cycles);

                // Check X output
                if ((data_out_X_r !== exp_x_r) ||
                    (data_out_X_i !== exp_x_i)) begin

                    $display("FAIL: X output incorrect.");
                    $display("  Expected X = (%0d, %0d)",
                             exp_x_r, exp_x_i);
                    $display("  Actual   X = (%0d, %0d)",
                             $signed(data_out_X_r),
                             $signed(data_out_X_i));

                    errors = errors + 1;

                end
                else begin

                    $display("PASS: X = (%0d, %0d)",
                             $signed(data_out_X_r),
                             $signed(data_out_X_i));

                end

                // Check Y output
                if ((data_out_Y_r !== exp_y_r) ||
                    (data_out_Y_i !== exp_y_i)) begin

                    $display("FAIL: Y output incorrect.");
                    $display("  Expected Y = (%0d, %0d)",
                             exp_y_r, exp_y_i);
                    $display("  Actual   Y = (%0d, %0d)",
                             $signed(data_out_Y_r),
                             $signed(data_out_Y_i));

                    errors = errors + 1;

                end
                else begin

                    $display("PASS: Y = (%0d, %0d)",
                             $signed(data_out_Y_r),
                             $signed(data_out_Y_i));

                end

            end

            // After done, check that done deasserts and
            // all outputs retain their values.
            @(posedge clk);
            #1;

            if (done !== 1'b0) begin

                $display("FAIL: done did not return LOW.");
                errors = errors + 1;

            end
            else begin

                $display("PASS: done returned LOW.");

            end

            if ((data_out_X_r !== exp_x_r) ||
                (data_out_X_i !== exp_x_i) ||
                (data_out_Y_r !== exp_y_r) ||
                (data_out_Y_i !== exp_y_i)) begin

                $display("FAIL: Outputs did not retain their values.");
                $display("  X = (%0d, %0d)",
                         $signed(data_out_X_r),
                         $signed(data_out_X_i));
                $display("  Y = (%0d, %0d)",
                         $signed(data_out_Y_r),
                         $signed(data_out_Y_i));

                errors = errors + 1;

            end
            else begin

                $display("PASS: Outputs retained their values.");

            end

            // Return to falling edge before next transaction
            @(negedge clk);

        end

    endtask


    // --------------------------------------------------
    // Main test sequence
    // --------------------------------------------------
    initial begin

        errors = 0;
        test_number = 0;
        cycles = 0;

        start = 1'b0;
        reset = 1'b0;

        data_in_0_r = 0;
        data_in_0_i = 0;
        data_in_1_r = 0;
        data_in_1_i = 0;
        data_in_W_r = 0;
        data_in_W_i = 0;

        $display("");
        $display("======================================");
        $display(" COMPLEX BUTTERFLY TESTBENCH");
        $display(" DATA_WIDTH = %0d", DATA_WIDTH);
        $display("======================================");

        // Apply active-low synchronous reset
        repeat (2) @(negedge clk);
        reset = 1'b1;

        @(negedge clk);

        // TEST 1
        // A = 0.25 + j0.125
        // B = 0.5  + j0.25
        // W = 0.5  + j0
        //
        // T = B*W = 0.25 + j0.125
        // X = A+T = 0.5  + j0.25
        // Y = A-T = 0    + j0
        //
        // Q1.15:
        // X = (16384, 8192)
        // Y = (0, 0)

        run_test(
            16'sd8192,    16'sd4096,
            16'sd16384,   16'sd8192,
            16'sd16384,   16'sd0,

            16'sd16384,   16'sd8192,
            16'sd0,       16'sd0,

            "Positive complex values"
        );


        // TEST 2
        // A = 0.125 - j0.25
        // B = 0.5
        // W = 0.5
        //
        // T = 0.25
        // X = 0.375 - j0.25
        // Y = -0.125 - j0.25
        //
        // Q1.15:
        // X = (12288, -8192)
        // Y = (-4096, -8192)

        run_test(
            16'sd4096,    -16'sd8192,
            16'sd16384,    16'sd0,
            16'sd16384,    16'sd0,

            16'sd12288,   -16'sd8192,
            -16'sd4096,   -16'sd8192,

            "Negative imaginary values"
        );


        // TEST 3
        // A = 0
        // B = 0.5 + j0.25
        // W = 0.5 + j0.5
        //
        // T = 0.125 + j0.375
        // X = 0.125 + j0.375
        // Y = -0.125 - j0.375
        //
        // Q1.15:
        // X = (4096, 12288)
        // Y = (-4096, -12288)

        run_test(
            16'sd0,       16'sd0,
            16'sd16384,   16'sd8192,
            16'sd16384,   16'sd16384,

            16'sd4096,    16'sd12288,
            -16'sd4096,   -16'sd12288,

            "Complex multiplication with imaginary terms"
        );


        // TEST 4
        // All inputs zero.
        // X = 0, Y = 0.

        run_test(
            16'sd0, 16'sd0,
            16'sd0, 16'sd0,
            16'sd0, 16'sd0,

            16'sd0, 16'sd0,
            16'sd0, 16'sd0,

            "Zero inputs"
        );


        // TEST 5
        // A = 0.5
        // B = 0
        // W = 0.5
        //
        // T = 0
        // X = 0.5
        // Y = 0.5
        //
        // Q1.15:
        // X = (16384, 0)
        // Y = (16384, 0)

        run_test(
            16'sd16384, 16'sd0,
            16'sd0,     16'sd0,
            16'sd16384, 16'sd0,

            16'sd16384, 16'sd0,
            16'sd16384, 16'sd0,

            "Zero product"
        );


        // TEST 6: Reset behavior
        $display("");
        $display("======================================");
        $display("TEST 6: Reset behavior");
        $display("======================================");

        @(negedge clk);
        reset = 1'b0;

        @(posedge clk);
        #1;

        if ((done !== 1'b0) ||
            (data_out_X_r !== 0) ||
            (data_out_X_i !== 0) ||
            (data_out_Y_r !== 0) ||
            (data_out_Y_i !== 0)) begin

            $display("FAIL: Reset did not clear outputs.");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Reset cleared outputs.");
        end

        // Release reset
        @(negedge clk);
        reset = 1'b1;

        @(negedge clk);

        // Final report
        $display("");
        $display("======================================");
        $display(" FINAL TEST REPORT");
        $display(" Tests executed: %0d", test_number + 1);
        $display(" Errors detected: %0d", errors);
        $display("======================================");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTBENCH FAILED");

        $finish;

    end

    // Independent simulation timeout
    initial begin
        #10000;
        $display("FATAL: Simulation timeout.");
        $finish;
    end

endmodule

