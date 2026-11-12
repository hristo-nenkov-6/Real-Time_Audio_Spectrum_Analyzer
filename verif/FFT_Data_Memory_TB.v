
`timescale 1ns/1ps

module tb_FFT_Data_Memory;

    // Parameters
    parameter FFT_SIZE = 16;
    parameter DATA_WIDTH = 16;

    // Clock and reset
    reg clk;
    reg reset;

    // Control signals
    reg read_enable;
    reg write_enable;

    // Addresses
    reg [3:0] read_addr_0;
    reg [3:0] read_addr_1;

    reg [3:0] write_addr_0;
    reg [3:0] write_addr_1;

    // Data
    reg [31:0] write_data_0;
    reg [31:0] write_data_1;

    wire [31:0] read_data_0;
    wire [31:0] read_data_1;

    // Test variables
    integer errors;

    // DUT: Device Under Test
    FFT_Data_Memory #(
        .FFT_SIZE(FFT_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),

        .read_enable(read_enable),
        .write_enable(write_enable),

        .read_addr_0(read_addr_0),
        .read_addr_1(read_addr_1),

        .write_addr_0(write_addr_0),
        .write_addr_1(write_addr_1),

        .write_data_0(write_data_0),
        .write_data_1(write_data_1),

        .read_data_0(read_data_0),
        .read_data_1(read_data_1)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Main test sequence
    initial begin

        // Initialize signals
        reset = 1'b1;
        read_enable = 1'b0;
        write_enable = 1'b0;

        read_addr_0 = 4'd0;
        read_addr_1 = 4'd0;

        write_addr_0 = 4'd0;
        write_addr_1 = 4'd0;

        write_data_0 = 32'd0;
        write_data_1 = 32'd0;

        errors = 0;

        $display("-----------------------------------------");
        $display(" FFT DATA MEMORY TESTBENCH");
        $display("-----------------------------------------");

        // -------------------------------------
        // TEST 1: Reset read outputs
        // -------------------------------------

        $display("\nTEST 1: Reset");

        #2;
        reset = 1'b0;

        @(posedge clk);
        #1;

        if (read_data_0 !== 32'd0 ||
            read_data_1 !== 32'd0) begin

            $display("ERROR: Reset failed.");
            errors = errors + 1;

        end else begin

            $display("PASS: Read outputs reset to zero.");

        end

        @(negedge clk);
        reset = 1'b1;

        // -------------------------------------
        // TEST 2: Simultaneous write
        // -------------------------------------

        $display("\nTEST 2: Simultaneous write");

        write_enable = 1'b1;

        write_addr_0 = 4'd0;
        write_addr_1 = 4'd1;

        write_data_0 = 32'h4000_2000;
        write_data_1 = 32'hE000_C000;

        @(posedge clk);
        #1;

        @(negedge clk);
        write_enable = 1'b0;

        $display("Wrote address 0: %h", write_data_0);
        $display("Wrote address 1: %h", write_data_1);

        // -------------------------------------
        // TEST 3: Simultaneous read
        // -------------------------------------

        $display("\nTEST 3: Simultaneous read");

        read_addr_0 = 4'd0;
        read_addr_1 = 4'd1;

        read_enable = 1'b1;

        @(posedge clk);
        #1;

        if (read_data_0 !== 32'h4000_2000) begin

            $display("ERROR: Read port 0 incorrect. Got %h",
                     read_data_0);
            errors = errors + 1;

        end else begin

            $display("PASS: Read port 0 = %h", read_data_0);

        end

        if (read_data_1 !== 32'hE000_C000) begin

            $display("ERROR: Read port 1 incorrect. Got %h",
                     read_data_1);
            errors = errors + 1;

        end else begin

            $display("PASS: Read port 1 = %h", read_data_1);

        end

        // -------------------------------------
        // TEST 4: Output hold
        // -------------------------------------

        $display("\nTEST 4: Output hold");

        @(negedge clk);
        read_enable = 1'b0;

        read_addr_0 = 4'd5;
        read_addr_1 = 4'd6;

        @(posedge clk);
        #1;

        if (read_data_0 !== 32'h4000_2000 ||
            read_data_1 !== 32'hE000_C000) begin

            $display("ERROR: Read outputs did not hold.");
            errors = errors + 1;

        end else begin

            $display("PASS: Read outputs held their values.");

        end

        // -------------------------------------
        // TEST 5: Write and read last addresses
        // -------------------------------------

        $display("\nTEST 5: First and last addresses");

        @(negedge clk);

        write_enable = 1'b1;

        write_addr_0 = 4'd15;
        write_addr_1 = 4'd14;

        write_data_0 = 32'h7FFF_0001;
        write_data_1 = 32'h8000_FFFF;

        @(posedge clk);
        #1;

        @(negedge clk);

        write_enable = 1'b0;
        read_enable = 1'b1;

        read_addr_0 = 4'd15;
        read_addr_1 = 4'd14;

        @(posedge clk);
        #1;

        if (read_data_0 !== 32'h7FFF_0001) begin

            $display("ERROR: Address 15 incorrect. Got %h",
                     read_data_0);
            errors = errors + 1;

        end else begin

            $display("PASS: Address 15 read correctly.");

        end

        if (read_data_1 !== 32'h8000_FFFF) begin

            $display("ERROR: Address 14 incorrect. Got %h",
                     read_data_1);
            errors = errors + 1;

        end else begin

            $display("PASS: Address 14 read correctly.");

        end

        // -------------------------------------
        // TEST 6: Read same address on both ports
        // -------------------------------------

        $display("\nTEST 6: Same address on both read ports");

        @(negedge clk);

        read_addr_0 = 4'd15;
        read_addr_1 = 4'd15;

        @(posedge clk);
        #1;

        if (read_data_0 !== 32'h7FFF_0001 ||
            read_data_1 !== 32'h7FFF_0001) begin

            $display("ERROR: Same-address read failed.");
            errors = errors + 1;

        end else begin

            $display("PASS: Both ports read the same address.");

        end

        // -------------------------------------
        // FINAL RESULTS
        // -------------------------------------

        @(negedge clk);
        read_enable = 1'b0;

        $display("\n-----------------------------------------");

        if (errors == 0) begin

            $display("ALL TESTS PASSED!");

        end else begin

            $display("TESTS FAILED: %0d error(s)", errors);

        end

        $display("-----------------------------------------");

        $finish;

    end

endmodule
