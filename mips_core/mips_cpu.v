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
   reg [31:0]MDR;
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
   reg [1:0]ALUSrcA;
   reg RegWrite;
   reg [1:0]RegDst;
   reg PCWriteCond;
   reg PCWrite;
   /*reg MemRead;*/
   /*reg MemWrite;*/
   reg [1:0]MemtoReg;
   reg IRWrite;
   
//INSTRUCTION REGISTER & MDR WIRES
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
    assign jumpAddr = {PC[31:28],ext_low26};
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
    assign wdata = ((MemtoReg[1])? PC+4 :((MemtoReg[0])? MDR: ALUOut));
    assign waddr = ((RegDst[1])? 5'd31 : ((RegDst[0])? Instruction_reg[15:11]: Instruction_reg[20:16]));
    assign inputA = ((ALUSrcA[1])? Instruction_reg[10:6] : ((ALUSrcA[0])? A: PC));
    assign inputB = (ALUSrcB[1] == 0)? ((ALUSrcB[0]==0)?B: 4) : ((ALUSrcB[0]== 0)?imme_ext : imme_ext_shift2);
    assign Write_data = B;
    assign Address = ALUOut;
    assign Op = Instruction_reg[31:26];
    always@(posedge clk)begin
            if(IRWrite)begin
                    Instruction_reg <= Instruction;
             end
             
        end
    always @(posedge clk) begin
        if(rst) begin
                PC <= 32'd0;
        end
        else begin
            if(PCWrite || (PCWriteCond && !Zero && (Op == 6'b000101)) || (PCWriteCond && Zero && Op == 6'b000100)) 
            begin
                PC <= newPC;
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
                newPC = jumpAddr;
            end
            default: begin
                newPC = Result;
            end
        endcase
    end
    always@(posedge clk)begin
        MDR <= Read_data;
        A <= rdata1; B <= rdata2; ALUOut <= Result;
    end
	always@(*) begin
	   case(state)
	       4'b0000: begin
	           MemRead = 1; ALUSrcA = 2'b00; IRWrite = 1; ALUSrcB = 2'b01;
	           ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 1; PCWriteCond = 0;
	           MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b0001: begin
	           ALUSrcA = 2'b00; ALUSrcB = 2'b11; ALUOp = 2'b00;
	           MemRead = 0;  IRWrite = 0; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b0010: begin//SW LW
	           ALUSrcA = 2'b01; ALUSrcB = 2'b10; ALUOp = 2'b00; 
	           MemRead = 0;  IRWrite = 0; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b0011: begin//LW
	           MemRead = 1;
	           ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b0100: begin//LW
	           RegDst = 2'b00; RegWrite = 1; MemtoReg = 2'b01; 
	           MemRead = 0; ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; 
	       end
	       4'b0101: begin//SW
	           MemWrite = 1; 
	           MemRead = 0; ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b0110: begin//ADDIU
	           ALUSrcA = 2'b01; ALUSrcB = 2'b10; ALUOp = 2'b00; 
	           MemRead = 0; IRWrite = 0;PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b0111: begin//ADDIU + R-type: ADDU, OR, SLL, SLT, LUI, SLTI
	           RegDst = (Op == 6'b000000)? 2'b01 : 2'b00;
	           RegWrite = 1; MemtoReg = 2'b00;
	           MemRead = 0; ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0;
	       end
	       4'b1000: begin//BNE, BEQ
	           ALUSrcA = 2'b01; ALUSrcB = 2'b00; ALUOp = 2'b01; PCWriteCond = 1; PCSource = 2'b01;
	           MemRead = 0; IRWrite = 0; PCWrite = 0; 
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b1001: begin//JUMP, JAL
	           PCWrite = 1; PCSource = 2'b10; 
	           MemRead = 0; ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCWriteCond = 0;
               MemWrite = 0; MemtoReg[1]=(Op == 6'b000011)? 1: 0;MemtoReg[0] = 0; RegWrite = (Op == 6'b000011)?1:0; RegDst = (Op == 6'b000011)?2'b10 : 2'b00;
	       end
	       4'b1010: begin//R-type:ADDU, JR, SLL, SLT, 
	           MemRead = 0; IRWrite = 0; ALUSrcB = 2'b00;
	           ALUSrcA[0] = 1; ALUSrcA[1] = (Instruction_reg[5:0] == 6'b000000)?1:0;
               ALUOp = 2'b10; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b1011: begin//R-type: JR
	           MemRead = 0; ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b01; PCWrite = 1; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       4'b1100: begin//LUI
	           MemRead = 0; ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b10;
               ALUOp = 2'b10; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;	           
	       end
	       4'b1101: begin//STLI
               MemRead = 0; IRWrite = 0; ALUSrcB = 2'b10;
               ALUSrcA[0] = 1; ALUSrcA[1] = 0;
               ALUOp = 2'b10; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
	       end
	       
	       default: begin//NOP
	           MemRead = 0; ALUSrcA = 2'b00; IRWrite = 0; ALUSrcB = 2'b00;
               ALUOp = 2'b00; PCSource = 2'b00; PCWrite = 0; PCWriteCond = 0;
               MemWrite = 0; MemtoReg = 2'b00; RegWrite = 0; RegDst = 2'b00;
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
	       case(Op)
	           6'b001010: begin
	               ALUop = 3'b111;//STLI
	           end
	           6'b001011: begin
	               ALUop = 3'b101;//STLIU
	           end
	           6'b001111: begin
	               ALUop = 3'b100;//LUI
	           end
	           6'b000000: begin
	               case(Instruction_reg[5:0])
	                   6'b100000: begin
	                       ALUop = 3'b010;
	                   end
	                   6'b000000: begin
                           ALUop = 3'b011;//SLL Rtype
                       end
	                   6'b100001: begin
	                       ALUop = 3'b010;//ADDU Rtype
	                   end
	                   6'b001000: begin
	                       ALUop = 3'b010;//JR Rtype
	                   end
	                   6'b100010: begin
	                       ALUop = 3'b110;//SUB Rtype
	                   end
	                   6'b100100: begin
	                       ALUop = 3'b000;//AND Rtype
	                   end
	                   6'b100101: begin   //OR Rtype
	                       ALUop = 3'b001;
	                   end
	                   6'b101010: begin
                           ALUop = 3'b111;//SLT, SLTI
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
                        6'b000101, 6'b000100: begin
                            newState = 4'b1000;
                        end//BNE, BEQ
                        6'b000000: begin
                            newState = 4'b1010;
                        end//R-type
                        6'b000010, 6'b000011: begin
                            newState = 4'b1001;
                        end//JUMP, JAL
                        6'b001111: begin
                            newState = 4'b1100;
                        end//LUI
                        6'b001010, 6'b001011: begin
                            newState = 4'b1101;
                        end//SLTI
                        default: begin
                            newState = 4'b0000;
                        end
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
                         default: begin
                            newState = 4'b0000;
                         end
                     endcase
                end
                4'b0011: begin
                    newState = 4'b0100;
                end
                4'b0110, 4'b1100: begin
                    newState = 4'b0111;
                end
                4'b1010: begin//R-type
                    case(Instruction_reg[5:0]) 
                        6'b100001,6'b100101, 6'b000000,6'b101010: begin
                            newState = 4'b0111;
                        end//ADDU, OR, SLL, SLT
                        6'b001000: begin
                            newState = 4'b1011;
                        end//JR
                        default: begin
                            newState = 4'b0000;
                        end
                    endcase
                end
                4'b1101: begin
                    newState = 4'b0111;
                end
                4'b0100, 4'b0101, 4'b0111, 4'b1000, 4'b1001,4'b1011: begin
                    newState = 4'b0000;
                end
                default: begin
                    newState = 4'b0000;
                end
            endcase
        end     
    end
    always@(posedge clk) begin
        if(rst) begin
            state <= 4'b0000;
        end
        else begin
            state <= newState;
        end
    end 
endmodule