
`timescale 1ns / 1ps

module tb_FFT_Random;

    parameter FFT_SIZE = 16;
    parameter DATA_WIDTH = 16;
    parameter TOLERANCE = 20;

    reg clk;
    reg reset;
    reg start;

    wire done;

    integer errors;
    integer timeout;

    reg signed [15:0] input_real [0:15];
    reg signed [15:0] input_imag [0:15];

    reg signed [15:0] ref_real [0:15];
    reg signed [15:0] ref_imag [0:15];

    integer signed actual_real;
    integer signed actual_imag;
    integer signed expected_real;
    integer signed expected_imag;

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

            repeat (3) @(negedge clk);

            reset = 1;

            repeat (2) @(negedge clk);
        end
    endtask

    // =========================================
    // BIT REVERSAL
    // =========================================

    function integer bit_reverse;
        input integer value;
        begin
            bit_reverse = {
                value[0],
                value[1],
                value[2],
                value[3]
            };
        end
    endfunction

    // =========================================
    // INITIALIZE INPUT VECTOR
    // =========================================

    task initialize_input;
        begin
            input_real[0]  = 16'h1000;
            input_imag[0]  = 16'h0800;

            input_real[1]  = 16'hF000;
            input_imag[1]  = 16'h0400;

            input_real[2]  = 16'h0800;
            input_imag[2]  = 16'hF800;

            input_real[3]  = 16'hE000;
            input_imag[3]  = 16'h1000;

            input_real[4]  = 16'h0400;
            input_imag[4]  = 16'hFC00;

            input_real[5]  = 16'hF800;
            input_imag[5]  = 16'h0C00;

            input_real[6]  = 16'h1800;
            input_imag[6]  = 16'hE800;

            input_real[7]  = 16'hE800;
            input_imag[7]  = 16'h0800;

            input_real[8]  = 16'h0C00;
            input_imag[8]  = 16'h0400;

            input_real[9]  = 16'hF400;
            input_imag[9]  = 16'hF000;

            input_real[10] = 16'h1400;
            input_imag[10] = 16'hFC00;

            input_real[11] = 16'hEC00;
            input_imag[11] = 16'h0C00;

            input_real[12] = 16'h0800;
            input_imag[12] = 16'hE000;

            input_real[13] = 16'hF800;
            input_imag[13] = 16'h1000;

            input_real[14] = 16'h1000;
            input_imag[14] = 16'hF400;

            input_real[15] = 16'hE400;
            input_imag[15] = 16'h0400;
        end
    endtask

    // =========================================
    // LOAD DUT RAM IN BIT-REVERSED ORDER
    // =========================================

    task load_dut_memory;
        integer n;
        integer address;
        begin
            for (n = 0; n < FFT_SIZE; n = n + 1) begin
                DUT.RAM.RAM[n] = 32'h0000_0000;
            end

            for (n = 0; n < FFT_SIZE; n = n + 1) begin
                address = bit_reverse(n);

                DUT.RAM.RAM[address] = {
                    input_real[n],
                    input_imag[n]
                };
            end
        end
    endtask

    // =========================================
    // Q1.15 SATURATION
    // Used ONLY for complex multiplication
    // =========================================

    function integer signed saturate;
        input integer signed value;
        begin
            if (value > 32767)
                saturate = 32767;
            else if (value < -32768)
                saturate = -32768;
            else
                saturate = value;
        end
    endfunction

    // =========================================
    // TWIDDLE FACTORS
    // =========================================

    task get_twiddle;
        input integer index;
        output integer signed wr;
        output integer signed wi;

        begin
            case (index)
                0: begin
                    wr = 32767;
                    wi = 0;
                end

                1: begin
                    wr = 30274;
                    wi = -12540;
                end

                2: begin
                    wr = 23170;
                    wi = -23170;
                end

                3: begin
                    wr = 12540;
                    wi = -30274;
                end

                4: begin
                    wr = 0;
                    wi = -32768;
                end

                5: begin
                    wr = -12540;
                    wi = -30274;
                end

                6: begin
                    wr = -23170;
                    wi = -23170;
                end

                7: begin
                    wr = -30274;
                    wi = -12540;
                end

                default: begin
                    wr = 32767;
                    wi = 0;
                end
            endcase
        end
    endtask

    // =========================================
    // FIXED-POINT REFERENCE FFT
    // =========================================

    task calculate_reference;

        integer s;
        integer b;

        integer distance;
        integer group_size;
        integer group;
        integer offset;

        integer addr_a;
        integer addr_b;
        integer twiddle_index;

        integer signed ar;
        integer signed ai;
        integer signed br;
        integer signed bi;

        integer signed wr;
        integer signed wi;

        reg signed [31:0] product_rr;
        reg signed [31:0] product_ii;
        reg signed [31:0] product_ri;
        reg signed [31:0] product_ir;

        reg signed [32:0] real_sum;
        reg signed [32:0] imag_sum;

        integer signed tr;
        integer signed ti;

        reg signed [16:0] butterfly_x_r;
        reg signed [16:0] butterfly_x_i;
        reg signed [16:0] butterfly_y_r;
        reg signed [16:0] butterfly_y_i;

        integer signed xr;
        integer signed xi;
        integer signed yr;
        integer signed yi;

        begin

            // ---------------------------------
            // Bit-reversed input initialization
            // ---------------------------------

            for (s = 0; s < FFT_SIZE; s = s + 1) begin
                ref_real[bit_reverse(s)] = input_real[s];
                ref_imag[bit_reverse(s)] = input_imag[s];
            end

            // ---------------------------------
            // Four radix-2 DIT FFT stages
            // ---------------------------------

            for (s = 0; s < 4; s = s + 1) begin

                distance = 2 ** s;
                group_size = 2 ** (s + 1);

                for (b = 0; b < 8; b = b + 1) begin

                    group = b / distance;
                    offset = b % distance;

                    addr_a = group * group_size + offset;
                    addr_b = addr_a + distance;

                    twiddle_index =
                        offset * (FFT_SIZE / group_size);

                    // ---------------------------------
                    // Read reference operands
                    // ---------------------------------

                    ar = ref_real[addr_a];
                    ai = ref_imag[addr_a];

                    br = ref_real[addr_b];
                    bi = ref_imag[addr_b];

                    get_twiddle(twiddle_index, wr, wi);

                    // =================================
                    // COMPLEX MULTIPLICATION
                    //
                    // T = B * W
                    //
                    // Matches Complex_Multiplier:
                    // full-precision products,
                    // shift by 15, then saturation
                    // =================================

                    product_rr = br * wr;
                    product_ii = bi * wi;

                    product_ri = br * wi;
                    product_ir = bi * wr;

                    real_sum =
                        $signed({
                            product_rr[31],
                            product_rr
                        }) -
                        $signed({
                            product_ii[31],
                            product_ii
                        });

                    imag_sum =
                        $signed({
                            product_ri[31],
                            product_ri
                        }) +
                        $signed({
                            product_ir[31],
                            product_ir
                        });

                    tr = saturate(real_sum >>> 15);
                    ti = saturate(imag_sum >>> 15);

                    // =================================
                    // BUTTERFLY ADDITION/SUBTRACTION
                    //
                    // X = A + T
                    // Y = A - T
                    //
                    // Matches Complex_adder and
                    // Complex_Substractor:
                    // 17-bit intermediate, then
                    // truncate to signed 16 bits.
                    //
                    // NO saturation here.
                    // =================================

                    butterfly_x_r = ar + tr;
                    butterfly_x_i = ai + ti;

                    butterfly_y_r = ar - tr;
                    butterfly_y_i = ai - ti;

                    // ---------------------------------
                    // CORRECTED: 16-bit wraparound
                    // ---------------------------------

                    xr = $signed(butterfly_x_r[15:0]);
                    xi = $signed(butterfly_x_i[15:0]);

                    yr = $signed(butterfly_y_r[15:0]);
                    yi = $signed(butterfly_y_i[15:0]);

                    // ---------------------------------
                    // Store reference butterfly outputs
                    // ---------------------------------

                    ref_real[addr_a] = xr;
                    ref_imag[addr_a] = xi;

                    ref_real[addr_b] = yr;
                    ref_imag[addr_b] = yi;

                end
            end
        end
    endtask

    // =========================================
    // RUN FFT
    // =========================================

    task run_fft;
        begin

            @(negedge clk);
            start = 1;

            @(negedge clk);
            start = 0;

            timeout = 0;

            while ((done !== 1'b1) &&
                   (timeout < 10000)) begin

                @(negedge clk);
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display("ERROR: FFT timeout!");
                errors = errors + 1;
            end
            else begin
                $display(
                    "FFT completed in %0d cycles.",
                    timeout
                );
            end

            @(negedge clk);
        end
    endtask

    // =========================================
    // COMPARE RESULTS
    // =========================================

    task compare_results;

        integer bin;

        integer signed diff_real;
        integer signed diff_imag;

        begin

            $display("");
            $display("==============================================");
            $display("REFERENCE COMPARISON");
            $display("==============================================");

            for (bin = 0; bin < FFT_SIZE; bin = bin + 1) begin

                actual_real =
                    $signed(DUT.RAM.RAM[bin][31:16]);

                actual_imag =
                    $signed(DUT.RAM.RAM[bin][15:0]);

                expected_real = ref_real[bin];
                expected_imag = ref_imag[bin];

                diff_real = actual_real - expected_real;
                diff_imag = actual_imag - expected_imag;

                if (diff_real < 0)
                    diff_real = -diff_real;

                if (diff_imag < 0)
                    diff_imag = -diff_imag;

                $display(
                    "Bin %2d | DUT=(%6d,%6d) | REF=(%6d,%6d) | Error=(%0d,%0d)",
                    bin,
                    actual_real,
                    actual_imag,
                    expected_real,
                    expected_imag,
                    diff_real,
                    diff_imag
                );

                if ((diff_real > TOLERANCE) ||
                    (diff_imag > TOLERANCE)) begin

                    $display("  FAIL: Bin %0d", bin);
                    errors = errors + 1;
                end
                else begin
                    $display("  PASS: Bin %0d", bin);
                end

            end
        end
    endtask

    // =========================================
    // MAIN TEST
    // =========================================

    initial begin

        errors = 0;
        timeout = 0;

        reset = 0;
        start = 0;

        $display("");
        $display("==============================================");
        $display("16-POINT FFT RANDOM COMPLEX INPUT TEST");
        $display("==============================================");

        apply_reset();

        initialize_input();

        load_dut_memory();

        calculate_reference();

        $display("");
        $display("Reference FFT calculated.");

        run_fft();

        compare_results();

        $display("");
        $display("==============================================");

        if (errors == 0)
            $display(
                "TEST PASSED: ALL 16 BINS MATCH REFERENCE."
            );
        else
            $display(
                "TEST FAILED: %0d ERRORS.",
                errors
            );

        $display("==============================================");

        $finish;
    end

endmodule

