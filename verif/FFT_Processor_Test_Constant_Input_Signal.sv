`timescale 1ns/1ps

module tb_FFT_Constant;

    parameter FFT_SIZE = 16;
    parameter DATA_WIDTH = 16;

    // Clock and control
    reg clk;
    reg reset;
    reg start;
    wire done;

    // Test variables
    integer i;
    integer errors;

    // DUT
    FFT_Processor #(
        .FFT_SIZE(FFT_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Main test
    initial begin

        errors = 0;

        reset = 1'b1;
        start = 1'b0;

        $display("========================================");
        $display("   FFT CONSTANT SIGNAL TESTBENCH");
        $display("========================================");

        // ------------------------------------
        // TEST 1: Reset
        // ------------------------------------

        $display("\nTEST 1: Reset");

        #2;
        reset = 1'b0;

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b1;

        $display("Reset completed.");

        // ------------------------------------
        // TEST 2: Initialize RAM
        // ------------------------------------

        $display("\nTEST 2: Initialize RAM");

        // Constant input:
        // x[n] = 0.03125 + j0
        //
        // Q1.15:
        // 0.03125 * 32768 = 1024 = 16'h0400
        //
        // All samples are identical, so bit reversal
        // does not change their order.

        for (i = 0; i < FFT_SIZE; i = i + 1) begin
            DUT.RAM.RAM[i] = 32'h0400_0000;
        end

        $display("All 16 samples initialized to 0.03125 + j0.");

        // ------------------------------------
        // TEST 3: Start FFT
        // ------------------------------------

        $display("\nTEST 3: Start FFT");

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // ------------------------------------
        // TEST 4: Wait for completion
        // ------------------------------------

        $display("\nTEST 4: Wait for FFT completion");

        fork
            begin
                wait (done == 1'b1);
                $display("FFT completed at %0t ns.", $time);
            end

            begin
                #1000000;
                $display("ERROR: FFT timeout!");
                errors = errors + 1;
            end
        join_any

        disable fork;

        @(negedge clk);

        // ------------------------------------
        // TEST 5: Display results
        // ------------------------------------

        $display("\nTEST 5: FFT OUTPUT");

        $display("----------------------------------------");
        $display("Bin | Real (hex) | Imaginary (hex)");
        $display("----------------------------------------");

        for (i = 0; i < FFT_SIZE; i = i + 1) begin

            $display(
                "%2d  |   %04h     |     %04h",
                i,
                DUT.RAM.RAM[i][31:16],
                DUT.RAM.RAM[i][15:0]
            );

        end

        $display("----------------------------------------");

        // ------------------------------------
        // TEST 6: Verify DC component
        // ------------------------------------

        $display("\nTEST 6: Verify DC component");

        // Expected:
        // X[0] = 16 * 0.03125 = 0.5
        // Q1.15 representation = 16'h4000

        if (
            $signed(DUT.RAM.RAM[0][31:16]) < 16'sd16380 ||
            $signed(DUT.RAM.RAM[0][31:16]) > 16'sd16388 ||
            DUT.RAM.RAM[0][15:0] !== 16'h0000
        ) begin

            $display(
                "ERROR: DC bin incorrect. Real=%h Imag=%h",
                DUT.RAM.RAM[0][31:16],
                DUT.RAM.RAM[0][15:0]
            );

            errors = errors + 1;

        end
        else begin

            $display("PASS: DC bin = approximately 0.5 + j0.");

        end

        // ------------------------------------
        // TEST 7: Verify remaining bins
        // ------------------------------------

        $display("\nTEST 7: Verify AC components");

        for (i = 1; i < FFT_SIZE; i = i + 1) begin

            if (DUT.RAM.RAM[i] !== 32'h0000_0000) begin

                $display(
                    "ERROR: Bin %0d should be zero. Got %h",
                    i,
                    DUT.RAM.RAM[i]
                );

                errors = errors + 1;

            end

        end

        if (errors == 0) begin
            $display("PASS: All AC bins are zero.");
        end

        // ------------------------------------
        // FINAL RESULTS
        // ------------------------------------

        $display("\n========================================");

        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
        end
        else begin
            $display("TESTBENCH FAILED: %0d error(s)", errors);
        end

        $display("========================================");

        $finish;

    end

endmodule

