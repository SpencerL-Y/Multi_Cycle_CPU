/* =========================================
* Ideal Memory Module for MIPS CPU Core
* Synchronize write (clock enable)
* Asynchronize read (do not use clock signal)
*
* Author: Yisong Chang (changyisong@ict.ac.cn)
* Date: 31/05/2016
* Version: v0.0.1
*===========================================
*/

`timescale 1 ps / 1 ps

module ideal_mem #(
	parameter ADDR_WIDTH = 10,	// 1KB
	parameter MEM_WIDTH = 2 ** (ADDR_WIDTH - 2)
	) (
	input			clk,			//source clock of the MIPS CPU Evaluation Module

	input [ADDR_WIDTH - 1:0]	Waddr,			//Memory write port address
	input [ADDR_WIDTH - 1:0]	Raddr1,			//Read port 1 address
	input [ADDR_WIDTH - 1:0]	Raddr2,			//Read port 2 address

	input			Wren,			//write enable
	input			Rden1,			//port 1 read enable
	input			Rden2,			//port 2 read enable

	input [31:0]	Wdata,			//Memory write data
	output [31:0]	Rdata1,			//Memory read data 1
	output [31:0]	Rdata2			//Memory read data 2
);

reg [31:0]	mem [MEM_WIDTH - 1:0];

`define ADDIU(rt, rs, imm) {6'b001001, rs, rt, imm}
`define LW(rt, base, off) {6'b100011, base, rt, off}
`define SW(rt, base, off) {6'b101011, base, rt, off}
`define BNE(rs, rt, off) {6'b000101, rs, rt, off}
`define ADDU(rs, rt, rd) {6'b000000, rs, rt, rd, 5'b00000, 6'b100001}
`define BEQ(rs, rt, offset) {6'b000100, rs, rt, offset}
`define B(offset) {6'b000100, 5'b00000, 5'b00000, offset}
`define J(instr_index) {6'b000010, instr_index}
`define JAL(instr_index) {6'b000011, instr_index}
`define JR(rs, hint) {6'b000000, rs, 5'b00000, 5'b00000, hint, 6'b001000}
`define LUI(rt, imme) {6'b001111, 5'b00000, rt, imme}
`define OR(rd, rs, rt) {6'b000000, rs, rt, rd, 11'b00000100101} 
`define SLL(rt, rd, ra) {11'b00000000000, rt, rd, ra, 6'b000000}
`define SLT(rd, rs, rt) {6'b000000, rs, rt, rd, 11'b00000101010}
`define SLTI(rs,rt, imme) {6'b001010, rs, rt, imme}
`define SLTIU(rs, rt, imme) {6'b001011, rs, rt, imme}
`ifdef MIPS_CPU_SIM
	//Add memory initialization here
	initial begin
	/*
		// fill memory region [100, 200) with [0, 100)
		mem[0] = `ADDIU(5'd1, 5'd0, 16'd100);
		mem[1] = `ADDIU(5'd2, 5'd0, 16'd0);
		mem[2] = `SW(5'd2, 5'd2, 16'd100);
		mem[3] = `ADDIU(5'd2, 5'd2, 16'd4);
		mem[4] = `BNE(5'd1, 5'd2, 16'hfffd);

		// copy memory region [100, 200) to memory region [200, 300)
		mem[5] = `ADDIU(5'd2, 5'd0, 16'd0);
		mem[6] = `LW(5'd3, 5'd2, 16'd100);
		mem[7] = `SW(5'd3, 5'd2, 16'd200);
		mem[8] = `ADDIU(5'd2, 5'd2, 16'd4);
		mem[9] = `BNE(5'd1, 5'd2, 16'hfffc);

		mem[10] = `BNE(5'd1, 5'd0, 16'hffff);
		*/
		
		// Origin
		/*
		mem[0] = `ADDIU(5'd1, 5'd0, 16'd12);
        mem[1] = `ADDIU(5'd2, 5'd0, 16'b0);
	    mem[2] = `ADDU(5'd1, 5'd2, 5'd3);
	    mem[3] = `BEQ(5'd1, 5'd1, 16'd9);
	    //mem[4] = `B(16'b1111111111111011);
	    //mem[5] = `J(26'd3);
	    //mem[6] = `JAL(26'd3);
	    //mem[7] = `JR(5'd1, 5'b00000);
	    //mem[8] = `LUI(5'd4, 16'd1);
	    //mem[9] = `OR(5'd5, 5'd1, 5'd2);
	    //mem[10] = `SLL(5'd1, 5'd6, 5'd2);
	    //mem[11] = `SLT(5'd7, 5'd2, 5'd1);
	    //mem[12] = `SLTI(5'd2, 5'd8, 16'd1);
	    mem[13] = `SLTIU(5'd2, 5'd9, 16'd1);
	    
	    */
	    //Singel Debug
	    
	    `include "C:/Users/My-PC/Desktop/project3_on_board_flow_student/ready_for_test/sim/pascal.vh"
	end
	always@(posedge clk) begin
	         if(mem[3] == 32'b0) begin
	                      $display("pass");
	                      $finish;
	         end         
	         else if(mem[3] == 32'b1) begin
	                      $display("fail");
	                      $finish;         
	         end     
     end
`endif

always @ (posedge clk)
begin
	if (Wren)
		mem[Waddr] <= Wdata;
end

assign Rdata1 = {32{Rden1}} & mem[Raddr1];
assign Rdata2 = {32{Rden2}} & mem[Raddr2];

endmodule
