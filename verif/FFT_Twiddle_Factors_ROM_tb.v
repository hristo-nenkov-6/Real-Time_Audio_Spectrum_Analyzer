
`timescale 1ns/1ps

module tb_FFT_Twiddle_Factors_ROM;

    reg clk;
    reg [3:0] twiddle_index;

    wire signed [15:0] W_r;
    wire signed [15:0] W_i;

    integer errors;
    integer i;

    // Expected Q1.15 twiddle coefficients
    reg signed [15:0] expected_r [0:15];
    reg signed [15:0] expected_i [0:15];

    // Device Under Test (DUT)
    FFT_Twiddle_Factors_ROM dut (
        .twiddle_index(twiddle_index),
        .clk(clk),
        .W_r(W_r),
        .W_i(W_i)
    );

    // 100 MHz clock: period = 10 ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        errors = 0;
        twiddle_index = 4'd0;

        // Expected real coefficients
        expected_r[0]  =  32767;
        expected_r[1]  =  30274;
        expected_r[2]  =  23170;
        expected_r[3]  =  12540;
        expected_r[4]  =      0;
        expected_r[5]  = -12540;
        expected_r[6]  = -23170;
        expected_r[7]  = -30274;
        expected_r[8]  = -32768;
        expected_r[9]  = -30274;
        expected_r[10] = -23170;
        expected_r[11] = -12540;
        expected_r[12] =      0;
        expected_r[13] =  12540;
        expected_r[14] =  23170;
        expected_r[15] =  30274;

        // Expected imaginary coefficients
        expected_i[0]  =      0;
        expected_i[1]  = -12540;
        expected_i[2]  = -23170;
        expected_i[3]  = -30274;
        expected_i[4]  = -32768;
        expected_i[5]  = -30274;
        expected_i[6]  = -23170;
        expected_i[7]  = -12540;
        expected_i[8]  =      0;
        expected_i[9]  =  12540;
        expected_i[10] =  23170;
        expected_i[11] =  30274;
        expected_i[12] =  32767;
        expected_i[13] =  30274;
        expected_i[14] =  23170;
        expected_i[15] =  12540;

        $display("==============================================");
        $display(" FFT Twiddle Factors ROM Testbench");
        $display("==============================================");

        // Test every ROM address
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            twiddle_index = i;

            // Wait for the ROM's rising-edge update
            @(posedge clk);
            #1;

            if ((W_r !== expected_r[i]) ||
                (W_i !== expected_i[i])) begin

                $display(
                    "FAIL: index=%0d | W_r=%0d expected=%0d | W_i=%0d expected=%0d",
                    i, W_r, expected_r[i], W_i, expected_i[i]
                );

                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: index=%0d | W_r=%0d | W_i=%0d",
                    i, W_r, W_i
                );
            end
        end

        $display("----------------------------------------------");

        if (errors == 0)
            $display("TEST PASSED: All 16 twiddle factors are correct.");
        else
            $display("TEST FAILED: %0d error(s) detected.", errors);

        $display("==============================================");

        $finish;
    end

endmodule
