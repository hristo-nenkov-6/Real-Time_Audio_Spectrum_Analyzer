module FFT_Twiddle_Factors_ROM #(
		parameter DATA_WIDTH = 16
	)(
		input wire [3:0]  twiddle_index,
		input wire clk,
		output reg signed [DATA_WIDTH - 1:0] W_r,
		output reg signed [DATA_WIDTH - 1:0] W_i
	);
	
	always @(posedge clk) begin
        case (twiddle_index)
            4'd0:  begin W_r <=  32767; W_i <=      0; end
            4'd1:  begin W_r <=  30274; W_i <= -12540; end
            4'd2:  begin W_r <=  23170; W_i <= -23170; end
            4'd3:  begin W_r <=  12540; W_i <= -30274; end
            4'd4:  begin W_r <=      0; W_i <= -32768; end
            4'd5:  begin W_r <= -12540; W_i <= -30274; end
            4'd6:  begin W_r <= -23170; W_i <= -23170; end
            4'd7:  begin W_r <= -30274; W_i <= -12540; end
            4'd8:  begin W_r <= -32768; W_i <=      0; end
            4'd9:  begin W_r <= -30274; W_i <=  12540; end
            4'd10: begin W_r <= -23170; W_i <=  23170; end
            4'd11: begin W_r <= -12540; W_i <=  30274; end
            4'd12: begin W_r <=      0; W_i <=  32767; end
            4'd13: begin W_r <=  12540; W_i <=  30274; end
            4'd14: begin W_r <=  23170; W_i <=  23170; end
            4'd15: begin W_r <=  30274; W_i <=  12540; end

            default: begin
                W_r <= 0;
                W_i <= 0;
            end
        endcase
    end
endmodule