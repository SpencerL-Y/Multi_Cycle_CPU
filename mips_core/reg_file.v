`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement 4 4-bit registers
    `define DATA_WIDTH 4
	`define ADDR_WIDTH 2
`else
    `define DATA_WIDTH 32
	`define ADDR_WIDTH 5
`endif
`timescale 1 ps / 1 ps
module reg_file(
	input clk,
	input rst,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);

	// TODO: insert your code
        reg [`DATA_WIDTH-1:0] r [(1<<`ADDR_WIDTH) -1:0];
        reg [`ADDR_WIDTH:0] i;
        assign rdata1 = r[raddr1];
        assign rdata2 = r[raddr2];
        always@(posedge clk)begin
            if(rst)begin
              for(i=0;i<(1<<`ADDR_WIDTH);i=i+1) begin
                    r[i]<= 32'b0;//Initialize register file
              end
            end
            else if(wen && waddr != 0) begin
                r[waddr] <= wdata;
            end
        end
endmodule

