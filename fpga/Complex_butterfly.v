module Complex_Butterfly #(
	parameter DATA_WIDTH = 16
)(
	input wire 				clk,
	input wire 				reset,
	input wire 				start,

	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_0_i,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_1_i,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_W_r,
	input wire signed [DATA_WIDTH - 1 : 0] data_in_W_i,

	output reg 				done,

	output reg signed [DATA_WIDTH - 1 : 0] data_out_X_r,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_X_i,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_Y_r,
	output reg signed [DATA_WIDTH - 1 : 0] data_out_Y_i
);

	//FSM states
	localparam IDLE = 2'b00;
	localparam ADD  = 2'b01;
	localparam SUB  = 2'b10;
	localparam MULT = 2'b11;
	
	//ALU FSM state bits
	localparam ALU_ADD = 2'b00;
	localparam ALU_SUB = 2'b01;
	localparam ALU_MUL = 2'b10;

	//FSM state regs
	reg [1:0] curr_state;
    reg [1:0] next_state;

	//ALU select bit
	reg signed [1 : 0] 		sel;

	//ALU interface
	reg  signed [DATA_WIDTH - 1 : 0] alu_in_0_r;
	reg  signed [DATA_WIDTH - 1 : 0] alu_in_0_i;
	reg  signed [DATA_WIDTH - 1 : 0] alu_in_1_r;
	reg  signed [DATA_WIDTH - 1 : 0] alu_in_1_i;

	wire signed [DATA_WIDTH - 1 : 0] alu_out_r;
	wire signed [DATA_WIDTH - 1 : 0] alu_out_i;
	wire signed overflow_r;
	wire signed overflow_i;

	//intermediate results register
	reg signed [DATA_WIDTH - 1 : 0] temp_r;
	reg signed [DATA_WIDTH - 1 : 0] temp_i;

	ALU #(.DATA_WIDTH(DATA_WIDTH)) 
		alu_dut(
			.sel(sel),
			.data_in_0_r(alu_in_0_r),
			.data_in_0_i(alu_in_0_i),
			.data_in_1_r(alu_in_1_r),
			.data_in_1_i(alu_in_1_i),
			.data_out_r(alu_out_r),
			.data_out_i(alu_out_i),
			.overflow_r(overflow_r),
			.overflow_i(overflow_i)
		);

	//NEXT STATE LOGIC
	always @(*) begin
	  next_state = curr_state;
	
          case (curr_state) 
            IDLE: begin
                if (start) next_state = MULT;
		else 	   next_state = IDLE;
            end
            
            MULT: next_state = ADD;
            
            ADD: next_state = SUB;
            
            SUB: next_state = IDLE;
            
            default: next_state = IDLE;
          endcase
        end

	//ALU input select logic
	always @(*) begin
	  sel = ALU_ADD;

	  alu_in_0_r = '0;
	  alu_in_0_i = '0;
	  alu_in_1_r = '0;
	  alu_in_1_i = '0;

          case (curr_state)         
            MULT: begin
				sel = ALU_MUL;

                alu_in_0_r = data_in_1_r;
				alu_in_0_i = data_in_1_i;	
				alu_in_1_r = data_in_W_r;
				alu_in_1_i = data_in_W_i;
            end
            
            ADD: begin
				sel = ALU_ADD;

                alu_in_0_r = data_in_0_r;
				alu_in_0_i = data_in_0_i;
				alu_in_1_r = temp_r;
				alu_in_1_i = temp_i;
            end
            
            SUB: begin
				sel = ALU_SUB;

                alu_in_0_r = data_in_0_r;
				alu_in_0_i = data_in_0_i;
				alu_in_1_r = temp_r;
				alu_in_1_i = temp_i;
            end
            
            default: begin
				sel = ALU_ADD;

				alu_in_0_r = '0;
				alu_in_0_i = '0;
				alu_in_1_r = '0;
				alu_in_1_i = '0;
	    end
          endcase
        end

	//NEXT STATE ASSIGNMENT
	always @(posedge clk) begin
    	  if (~reset) curr_state <= IDLE;
    	  else curr_state <= next_state;
	end	
	
	//TEMPORARY AND RESULT REGISTERS ASSIGNMENT
	always @(posedge clk) begin
	  if (~reset) begin
	  	temp_r      <= '0;
        	temp_i      <= '0;

        	data_out_X_r <= '0;
        	data_out_X_i <= '0;
        	data_out_Y_r <= '0;
        	data_out_Y_i <= '0;

        	done <= 1'b0;
	  end
          else begin
		
		done <= 1'b0;

		case (curr_state)         
            	MULT: begin
					temp_r <= alu_out_r;
					temp_i <= alu_out_i;
            	end
            
            	ADD: begin
					data_out_X_r <= alu_out_r;
					data_out_X_i <= alu_out_i;
            	end
            
            	SUB: begin
                	data_out_Y_r <= alu_out_r;
					data_out_Y_i <= alu_out_i;

					done <= 1'b1;
            	end
            
            	default: begin
                	temp_r <= temp_r;
        			temp_i <= temp_i;

        			data_out_X_r <= data_out_X_r;
        			data_out_X_i <= data_out_X_i;
        			data_out_Y_r <= data_out_Y_r;
        			data_out_Y_i <= data_out_Y_i;
            	end
        endcase
		  end
    end

endmodule