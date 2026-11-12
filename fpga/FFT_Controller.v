module FFT_Controller #(
    parameter FFT_SIZE = 16,
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire reset,
    input wire start,

    // Butterfly handshake
    input wire butterfly_done,
    output reg butterfly_start,

    // Twiddle ROM interface
    output wire [3:0] twiddle_index,

    // Data RAM interface
    output reg [3:0] read_addr_data_in_0,
    output reg [3:0] read_addr_data_in_1,
    output reg RAM_read_enable,

    output reg [3:0] write_addr_data_in_0,
    output reg [3:0] write_addr_data_in_1,
    output reg RAM_write_enable,

    // Completion
    output reg done
);

    //------------------------------------------------------
    // Butterfly status
    reg butterfly_working;

    //------------------------------------------------------
    // FSM states
    localparam IDLE        = 3'b000;
    localparam INIT        = 3'b001;
    localparam LOAD_VALUES = 3'b010;
    localparam GET_TWIDDLE = 3'b011;
    localparam COMPUTE     = 3'b100;
    localparam STORE_BACK  = 3'b101;
    localparam NEXT        = 3'b110;
    localparam DONE        = 3'b111;

    reg [2:0] current_state;
    reg [2:0] next_state;

    //------------------------------------------------------
    // Stage and butterfly counters
    reg [1:0] stage_count;
    reg [2:0] butterfly_per_stage_count;

    //------------------------------------------------------
    // Address generation intermediates
    reg [3:0] distance;
    reg [4:0] group_size;
    reg [2:0] current_group;
    reg [2:0] ingroup_offset;

    //------------------------------------------------------
    // FSM state register
    always @(posedge clk or negedge reset) begin
        if (!reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    //------------------------------------------------------
    // Next-state logic
    always @(*) begin
        next_state = current_state;

        case (current_state)

            IDLE:
                if (start)
                    next_state = INIT;

            INIT:
                next_state = LOAD_VALUES;

            LOAD_VALUES:
                next_state = GET_TWIDDLE;

            GET_TWIDDLE:
                if (butterfly_start)
                    next_state = COMPUTE;

            COMPUTE:
                if (butterfly_done)
                    next_state = STORE_BACK;

            STORE_BACK:
                next_state = NEXT;

            NEXT:
                if (butterfly_per_stage_count == 7 &&
                    stage_count == 3)
                    next_state = DONE;
                else
                    next_state = LOAD_VALUES;

            DONE:
                next_state = IDLE;

            default:
                next_state = IDLE;

        endcase
    end

    //------------------------------------------------------
    // Butterfly counter
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            butterfly_per_stage_count <= 0;
        end
        else if (current_state == INIT ||
                 current_state == DONE) begin
            butterfly_per_stage_count <= 0;
        end
        else if (current_state == NEXT) begin
            if (butterfly_per_stage_count == 7) begin
                if (stage_count < 3)
                    butterfly_per_stage_count <= 0;
            end
            else begin
                butterfly_per_stage_count <=
                    butterfly_per_stage_count + 1'b1;
            end
        end
    end

    //------------------------------------------------------
    // Stage counter
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            stage_count <= 0;
        end
        else if (current_state == INIT ||
                 current_state == DONE) begin
            stage_count <= 0;
        end
        else if (current_state == NEXT) begin
            if (butterfly_per_stage_count == 7) begin
                if (stage_count < 3)
                    stage_count <= stage_count + 1'b1;
            end
        end
    end

    //------------------------------------------------------
    // Data memory address generation
    always @(*) begin
        distance = 2 ** stage_count;
        group_size = 2 ** (stage_count + 1);

        current_group = butterfly_per_stage_count / distance;
        ingroup_offset = butterfly_per_stage_count % distance;

        read_addr_data_in_0 = current_group * group_size + ingroup_offset;

        read_addr_data_in_1 = read_addr_data_in_0 + distance;

        // Read and Write addresses are the same
        write_addr_data_in_0 = read_addr_data_in_0;
        write_addr_data_in_1 = read_addr_data_in_1;
    end

    //------------------------------------------------------
    // Twiddle index generation
    assign twiddle_index =
        ingroup_offset * (FFT_SIZE / group_size);

    //------------------------------------------------------
    // Butterfly start pulse
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            butterfly_start <= 1'b0;
        end
        else begin
            butterfly_start <= 1'b0;

            if (current_state == GET_TWIDDLE &&
                !butterfly_done &&
                !butterfly_working) begin
                butterfly_start <= 1'b1;
            end
        end
    end

    //------------------------------------------------------
    // Butterfly working flag
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            butterfly_working <= 1'b0;
        end
        else begin
            if (current_state == GET_TWIDDLE &&
                !butterfly_done &&
                !butterfly_working) begin
                butterfly_working <= 1'b1;
            end
            else if (current_state == COMPUTE &&
                     butterfly_done) begin
                butterfly_working <= 1'b0;
            end
            else if (current_state != GET_TWIDDLE &&
                     current_state != COMPUTE) begin
                butterfly_working <= 1'b0;
            end
        end
    end

    //------------------------------------------------------
    // RAM read enable
    always @(*) begin
        RAM_read_enable = 1'b0;

        if (current_state == LOAD_VALUES)
            RAM_read_enable = 1'b1;
    end

    //------------------------------------------------------
    // RAM write enable
    always @(*) begin
        RAM_write_enable = 1'b0;

        if (current_state == STORE_BACK)
            RAM_write_enable = 1'b1;
    end

    //------------------------------------------------------
    // Done output
    always @(*) begin
        done = 1'b0;

        if (current_state == DONE)
            done = 1'b1;
    end

endmodule
