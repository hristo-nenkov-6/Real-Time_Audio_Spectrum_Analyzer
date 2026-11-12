module FFT_Data_Memory #(
        parameter FFT_SIZE = 16,
        parameter DATA_WIDTH = 16
	)(
        input wire clk,
		input wire reset,

        input wire read_enable,
        input wire write_enable,

        input wire [3:0] read_addr_0,
        input wire [3:0] read_addr_1,

        input wire [3:0] write_addr_0,
        input wire [3:0] write_addr_1,

        input wire [31:0] write_data_0,
        input wire [31:0] write_data_1,

        output reg [31:0] read_data_0,
        output reg [31:0] read_data_1
    );
	
	reg [31:0] RAM [0:15];
    
	//Read data logic
    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            read_data_0 <= '0;
			read_data_1 <= '0;
        end else if (read_enable) begin
			read_data_0 <= RAM[read_addr_0];
			read_data_1 <= RAM[read_addr_1];
		end
    end
    
    //Write data logic
    always @(posedge clk) begin     
        if (write_enable) begin
			RAM[write_addr_0] <= write_data_0;
			RAM[write_addr_1] <= write_data_1;
		end
    end
	
endmodule