`timescale 1 ps / 1 ps

module mips_cpu(
	input  rst,
	input  clk,

	output reg [31:0] PC,
	input  [31:0] Instruction,

	output [31:0] Address,
	output reg MemWrite,
	output [31:0] Write_data,

	input  [31:0] Read_data,
	output reg MemRead
);


//TODO: Insert your design of multi cycle MIPS CPU here
//STORE REGS DEFINITIONS
   reg [31:0]Instruction_reg;
   reg [31:0]MAR;
   reg [31:0]A;
   reg [31:0]B;
   reg [31:0]ALUOut;
   reg [31:0]newPC;
//CONTROL REGS DEFINITIONS
   reg [3:0]state;
   reg [3:0]newState;
   reg [1:0]PCSource;
   reg [1:0]ALUOp;
   reg [1:0]ALUSrcB;
   reg ALUSrcA;
   reg RegWrite;
   reg RegDst;
   reg PCWriteCond;
   reg PCWrite;
   /*reg MemRead;*/
   /*reg MemWrite;*/
   reg MemtoReg;
   reg IRWrite;

//INSTRUCTION REGISTER & MAR WIRES
    wire [5:0]Op;
    wire [15:0]immediate;
    wire [31:0]imme_ext;
    wire [31:0]imme_ext_shift2;
    wire [25:0]low26;
    wire [27:0]ext_low26;
    wire [31:0]jumpAddr;
    
    assign immediate = Instruction_reg[15:0];
    assign imme_ext = (immediate[15]) ? {16'b1111111111111111,immediate} : {16'b0000000000000000,immediate};
    assign imme_ext_shift2 = imme_ext << 2;
   
    assign low26 = Instruction_reg[25:0];
    assign ext_low26 = low26 << 2;
    assign jumAddr = {PC[31:28],ext_low26};
//REGISTER FILES WIRES
    wire [4:0]raddr1;
    wire [4:0]raddr2;
    wire [4:0]waddr;
    wire [31:0]wdata;
    wire [31:0]rdata1;
    wire [31:0]rdata2;
    
    assign raddr1 = Instruction_reg[25:21];
    assign raddr2 = Instruction_reg[20:16];
    
//REGISTER FILES DEFINITION
        reg_file cpu_reg_file(
            .clk(clk),
            .rst(rst),
            .waddr(waddr),
            .raddr1(raddr1),
            .raddr2(raddr2),
            .wen(RegWrite),
            .wdata(wdata),
            .rdata1(rdata1),
            .rdata2(rdata2)
        );    
//ALU WIRES
    wire [31:0]inputA;
    wire [31:0]inputB;
    wire Zero;
    wire [31:0]Result;
    reg [2:0]ALUop;
    
//ALU DEFINITION
    alu cpu_alu(
        .A(inputA),
        .B(inputB),
        .ALUop(ALUop),
        .Overflow(),
        .CarryOut(),
        .Zero(Zero),
        .Result(Result)
    );
//COMBINITIONAL LOGIC
    assign wdata = (MemtoReg)? MAR: ALUOut;
    assign waddr = (RegDst)? Instruction_reg[20:16]: Instruction_reg[15:11];
    assign inputA = (ALUSrcA)? A: PC;
    assign inputB = (ALUSrcB[1] == 0)? ((ALUSrcB[0]==0)?B: 4) : ((ALUSrcB[0]== 0)?imme_ext : imme_ext_shift2);
    assign Write_data = B;
    assign Address = ALUOut;
    assign Op = Instruction_reg[31:26];
    always@(posedge clk)begin
            if(IRWrite)begin
                    Instruction_reg = Instruction;
             end
             
        end
    always @(posedge clk) begin
        if(rst) begin
                PC = 32'd0;
        end
        else begin
            if(PCWrite || (PCWriteCond && !Zero)) begin
                PC = newPC;
            end
        end
    end
    always@(*)begin
        case(PCSource)
            2'b00: begin
                newPC = Result;
            end
            2'b01: begin
                newPC = ALUOut;
            end
            2'b10: begin
                newPC = jumAddr;
            end
            default: begin
                newPC = Result;
            end
        endcase
    end
    always@(posedge clk)begin
        MAR = Read_data;
        A = rdata1; B = rdata2; ALUOut = Result;
    end
	always@(*) begin
	   case(state)
	       4'b0000: begin
	           MemRead = 1; ALUSrcA = 0; IRWrite = 1; ALUSrcB = 2'b01;
	           ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 1; PCWriteCond = 0;
	           MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       4'b0001: begin
	           ALUSrcA = 0; ALUSrcB = 2'b11; ALUOp = 2'b00;
	           MemRead = 0;  IRWrite = 0; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       4'b0010: begin//SW LW
	           ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = 2'b00; 
	           MemRead = 0;  IRWrite = 0; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       4'b0011: begin//LW
	           MemRead = 1;
	           ALUSrcA = 0; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       4'b0100: begin//LW
	           RegDst = 0; RegWrite = 1; MemtoReg = 1; 
	           MemRead = 0; ALUSrcA = 0; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; 
	       end
	       4'b0101: begin//SW
	           MemWrite = 1; 
	           MemRead = 0; ALUSrcA = 0; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       4'b0110: begin//ADDIU
	           ALUSrcA = 1; ALUSrcB = 2'b10; ALUOp = 2'b00; 
	           MemRead = 0; IRWrite = 0;PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       4'b0111: begin//ADDIU
	           RegDst = 1; RegWrite = 1; MemtoReg = 0;
	           MemRead = 0; ALUSrcA = 0; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0;
	       end
	       4'b1000: begin//BNE
	           ALUSrcA = 1; ALUSrcB = 2'b00; ALUOp = 2'b01; PCWriteCond = 1; PCSource = 2'b01;
	           MemRead = 0; IRWrite = 0; PCWrite = 0; 
               MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       4'b1001: begin//JUMP
	           PCWrite = 1; PCSource = 2'b10; IRWrite = 0;
	           MemRead = 0; ALUSrcA = 0; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	       default: begin//NOP
	           
	           MemRead = 0; ALUSrcA = 0; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 0; RegWrite = 0; RegDst = 0;
	       end
	   endcase
	end
	
	always @(*) begin
	   case(ALUOp)
	       2'b00: begin
	           ALUop = 3'b010;
	       end
	       2'b01: begin
	           ALUop = 3'b110;
	       end
	       2'b10: begin
	           case(Instruction_reg[5:0])
	               6'b100000: begin
	                   ALUop = 3'b010;
	               end
	               6'b100010: begin
	                   ALUop = 3'b110;
	               end
	               6'b100100: begin
	                   ALUop = 3'b000;
	               end
	               6'b100101: begin
	                   ALUop = 3'b001;
	               end
	               6'b101010: begin
	                   ALUop = 3'b111;
	               end
	               default: begin
	                   ALUop = 3'b000;
	               end
	           endcase
	       end
	       default: begin
	           ALUop = 3'b000;
	       end
	   endcase
	end

    
//AUTOMATA
    always@(*) begin
        begin
            case(state) 
                4'b0000: begin
                    newState = 4'b0001;
                end
                4'b0001:begin
                    case(Op)
                        6'b100011, 6'b101011: begin
                            newState = 4'b0010;    
                        end//LW, SW
                        6'b001001: begin
                            newState = 4'b0110;
                        end//ADDIU
                        6'b000101: begin
                            newState = 4'b1000;
                        end//BNE
                        
                    endcase
                end
                4'b0010: begin
                     case(Op)
                         6'b100011: begin
                             newState = 4'b0011;    
                         end//LW
                         6'b101011: begin
                             newState = 4'b0101;
                         end//SW 
                     endcase
                end
                4'b0011: begin
                    newState = 4'b0100;
                end
                4'b0110: begin
                    newState = 4'b0111;
                end
                4'b0100, 4'b0101, 4'b0111, 4'b1000, 4'b1001: begin
                    newState = 4'b0000;
                end
            endcase
        end     
    end
    always@(posedge clk) begin
        if(rst) begin
            state = 4'b0000;
        end
        else begin
            state = newState;
        end
    end 
endmodule