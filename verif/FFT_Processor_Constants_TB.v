
`timescale 1ns / 1ps

module tb_FFT_Processor;

    parameter FFT_SIZE = 16;
    parameter DATA_WIDTH = 16;

    // Q1.15 numerical tolerances
    parameter DC_TOLERANCE = 30;
    parameter AC_TOLERANCE = 10;
    parameter IMPULSE_TOLERANCE = 10;

    reg clk;
    reg reset;
    reg start;

    wire done;

    integer errors;
    integer i;
    integer timeout;
    integer signed real_value;
    integer signed imag_value;
    integer signed max_bin;
    integer signed second_bin;

    // =========================================
    // DUT
    // =========================================

    FFT_Processor #(
        .FFT_SIZE(FFT_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done)
    );

    // =========================================
    // CLOCK
    // =========================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // =========================================
    // RESET
    // =========================================

    task apply_reset;
        begin
            @(negedge clk);
            reset = 0;
            start = 0;

            repeat(3) @(negedge clk);

            reset = 1;

            repeat(2) @(negedge clk);
        end
    endtask

    // =========================================
    // CLEAR RAM
    // =========================================

    task clear_ram;
        integer k;
        begin
            for (k = 0; k < FFT_SIZE; k = k + 1)
                DUT.RAM.RAM[k] = 32'h0000_0000;
        end
    endtask

    // =========================================
    // START FFT AND WAIT FOR COMPLETION
    // =========================================

    task run_fft;
        begin
            @(negedge clk);
            start = 1;

            @(negedge clk);
            start = 0;

            timeout = 0;

            while ((done !== 1'b1) && (timeout < 10000)) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display("ERROR: FFT timeout!");
                errors = errors + 1;
            end
            else begin
                $display("PASS: FFT completed in %0d cycles.", timeout);
            end

            // Allow completion state and outputs to settle
            @(negedge clk);
        end
    endtask

    // =========================================
    // DISPLAY OUTPUT
    // =========================================

    task display_results;
        integer k;
        begin
            $display("-----------------------------------------------");
            $display("Bin | Real      | Imaginary | Combined");
            $display("-----------------------------------------------");

            for (k = 0; k < FFT_SIZE; k = k + 1) begin
                $display(
                    "%2d  | %h    | %h     | %h",
                    k,
                    DUT.RAM.RAM[k][31:16],
                    DUT.RAM.RAM[k][15:0],
                    DUT.RAM.RAM[k]
                );
            end

            $display("-----------------------------------------------");
        end
    endtask

    // =========================================
    // CHECK BIN WITH TOLERANCE
    // =========================================

    task check_bin;
        input integer bin;
        input integer signed expected_real;
        input integer signed expected_imag;
        input integer tolerance;

        integer signed actual_real;
        integer signed actual_imag;

        begin
            actual_real = $signed(DUT.RAM.RAM[bin][31:16]);
            actual_imag = $signed(DUT.RAM.RAM[bin][15:0]);

            if ((actual_real < expected_real - tolerance) ||
                (actual_real > expected_real + tolerance) ||
                (actual_imag < expected_imag - tolerance) ||
                (actual_imag > expected_imag + tolerance)) begin

                $display("ERROR: Bin %0d outside tolerance.", bin);
                $display("Expected: R=%0d I=%0d",
                         expected_real, expected_imag);
                $display("Actual:   R=%0d I=%0d",
                         actual_real, actual_imag);

                errors = errors + 1;
            end
            else begin
                $display("PASS: Bin %0d", bin);
            end
        end
    endtask

    // =========================================
    // TEST 1: IMPULSE INPUT
    // =========================================

    task test_impulse;
        begin
            $display("\n======================================");
            $display("TEST 1: IMPULSE INPUT");
            $display("======================================");

            apply_reset();
            clear_ram();

            // x[0] = 0.5
            DUT.RAM.RAM[0] = 32'h4000_0000;

            run_fft();
            display_results();

            // Every bin should be approximately 0.5
            for (i = 0; i < FFT_SIZE; i = i + 1)
                check_bin(i, 16384, 0, IMPULSE_TOLERANCE);
        end
    endtask

    // =========================================
    // TEST 2: CONSTANT INPUT
    // =========================================

    task test_constant;
        begin
            $display("\n======================================");
            $display("TEST 2: CONSTANT INPUT");
            $display("======================================");

            apply_reset();
            clear_ram();

            // x[n] = 0.03125 + j0
            // Q1.15 = 0x0400

            for (i = 0; i < FFT_SIZE; i = i + 1)
                DUT.RAM.RAM[i] = 32'h0400_0000;

            run_fft();
            display_results();

            // DC should be approximately 0.5
            check_bin(0, 16384, 0, DC_TOLERANCE);

            // AC bins should be close to zero
            for (i = 1; i < FFT_SIZE; i = i + 1)
                check_bin(i, 0, 0, AC_TOLERANCE);
        end
    endtask

    // =========================================
    // TEST 3: SINGLE-FREQUENCY COSINE
    // =========================================

    task test_single_frequency;
        begin
            $display("\n======================================");
            $display("TEST 3: SINGLE-FREQUENCY COSINE");
            $display("======================================");

            apply_reset();
            clear_ram();

            // x[n] = 0.125*cos(2*pi*n/16)
            //
            // The ideal FFT has dominant bins 1 and 15.
            // Their magnitudes are approximately 1.0.
            //
            // Input is in natural sample order.
            // This processor expects bit-reversed input
            // for natural-order DIT FFT output.

            DUT.RAM.RAM[0]  = 32'h1000_0000;
            DUT.RAM.RAM[1]  = 32'h0EC8_0000;
            DUT.RAM.RAM[2]  = 32'h0B50_0000;
            DUT.RAM.RAM[3]  = 32'h061F_0000;
            DUT.RAM.RAM[4]  = 32'h0000_0000;
            DUT.RAM.RAM[5]  = 32'hF9E1_0000;
            DUT.RAM.RAM[6]  = 32'hF4B0_0000;
            DUT.RAM.RAM[7]  = 32'hF138_0000;
            DUT.RAM.RAM[8]  = 32'hF000_0000;
            DUT.RAM.RAM[9]  = 32'hF138_0000;
            DUT.RAM.RAM[10] = 32'hF4B0_0000;
            DUT.RAM.RAM[11] = 32'hF9E1_0000;
            DUT.RAM.RAM[12] = 32'h0000_0000;
            DUT.RAM.RAM[13] = 32'h061F_0000;
            DUT.RAM.RAM[14] = 32'h0B50_0000;
            DUT.RAM.RAM[15] = 32'h0EC8_0000;

            // Convert natural sample order to bit-reversed
            // physical memory order for this DIT processor.
            begin : bit_reverse_load
                reg [31:0] temp [0:15];
                integer k;
                integer reversed;

                for (k = 0; k < 16; k = k + 1)
                    temp[k] = DUT.RAM.RAM[k];

                for (k = 0; k < 16; k = k + 1) begin
                    reversed = {k[0], k[1], k[2], k[3]};
                    DUT.RAM.RAM[reversed] = temp[k];
                end
            end

            run_fft();
            display_results();

            // Dominant frequency should be at bins 1 and 15.
            // Check that these bins have significant energy.
            real_value = $signed(DUT.RAM.RAM[1][31:16]);
            imag_value = $signed(DUT.RAM.RAM[1][15:0]);

            if ((real_value * real_value +
                 imag_value * imag_value) < 900000000) begin
                $display("ERROR: Bin 1 does not contain sufficient energy.");
                errors = errors + 1;
            end
            else begin
                $display("PASS: Bin 1 contains significant energy.");
            end

            real_value = $signed(DUT.RAM.RAM[15][31:16]);
            imag_value = $signed(DUT.RAM.RAM[15][15:0]);

            if ((real_value * real_value +
                 imag_value * imag_value) < 900000000) begin
                $display("ERROR: Bin 15 does not contain sufficient energy.");
                errors = errors + 1;
            end
            else begin
                $display("PASS: Bin 15 contains significant energy.");
            end
        end
    endtask

    // =========================================
    // TEST 4: ZERO INPUT
    // =========================================

    task test_zero;
        begin
            $display("\n======================================");
            $display("TEST 4: ZERO INPUT");
            $display("======================================");

            apply_reset();
            clear_ram();

            run_fft();
            display_results();

            for (i = 0; i < FFT_SIZE; i = i + 1)
                check_bin(i, 0, 0, 0);
        end
    endtask

    // =========================================
    // MAIN
    // =========================================

    initial begin

        errors = 0;
        reset = 0;
        start = 0;

        $display("\n======================================");
        $display("16-POINT FFT PROCESSOR TESTBENCH");
        $display("======================================");

        test_impulse();
        test_constant();
        test_single_frequency();
        test_zero();

        $display("\n======================================");

        if (errors == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("TESTBENCH FAILED: %0d errors", errors);

        $display("======================================");

        $finish;
    end

endmodule
