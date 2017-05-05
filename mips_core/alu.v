`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement a 4-bit ALU
    `define DATA_WIDTH 4
`else
    `define DATA_WIDTH 32
`endif

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [2:0] ALUop,
	output reg Overflow,
	output reg CarryOut,
	output reg Zero,
	output reg [`DATA_WIDTH - 1:0] Result
);

	// TODO: insert your code
	wire [`DATA_WIDTH-1:0] negA;
       wire [`DATA_WIDTH-1:0] negB;
       reg negCarry;
       assign negA = ~A+1;
       assign negB = ~B+1;    
       
       always@(*) begin
           case(ALUop[2:0])
                3'b000: begin
                /*TODO: 000 Function: And
                *           Operation: and
                */
                    Result[`DATA_WIDTH-1:0] = A & B;
                    CarryOut = 0; Overflow = 0;
                end
                3'b001: begin
                /*TODO: 001 Function: Or
                 *          Operation: or
                 */
                    Result[`DATA_WIDTH-1:0] = A | B;
                    CarryOut = 0; Overflow = 0;
                end
                3'b010: begin
                /*TODO: 010 Function: Add
                 *          Operation: add, lw, sw
                 */
                    {CarryOut,Result} = A+B;
                    if(A[`DATA_WIDTH-1] == B[`DATA_WIDTH-1]) begin
                        Overflow = CarryOut ^ Result[`DATA_WIDTH-1];
                    end
                    else begin
                        Overflow = 0;
                    end
                end
                3'b110: begin
                /*TODO: 110 Function: Substract
                *           Operation: sub, beq
                */  
                    {CarryOut,Result} = A+~B+1;
                    if(A[`DATA_WIDTH-1] == 0 && B[`DATA_WIDTH-1] == 1 && B[`DATA_WIDTH-2:0]==0) begin
                        Overflow = 1;
                    end
                    else if(A[`DATA_WIDTH-1] == negB [`DATA_WIDTH-1]) begin
                        Overflow = ALUop[2] ^ CarryOut ^ Result[`DATA_WIDTH-1];
                    end
                    else begin
                        Overflow = 0;
                    end
                end
                3'b111: begin
                /*TODO: 110 Function: Slt
                 *           Operation: slt
                 */
                 //Use shift code to judge the relative relationship
                if({~A[`DATA_WIDTH-1],A[`DATA_WIDTH-2:0]}<{~B[`DATA_WIDTH-1],B[`DATA_WIDTH-2:0]}) begin
                     Result = 1;
                     CarryOut = 0; Overflow = 0;
                end
                else begin
                     Result = 0;
                     CarryOut = 0; Overflow = 0;
                end
                end
                default: begin
                    Result = 0;
                    CarryOut = 0; Overflow = 0;
                end
            endcase
            //TODO: Zero judegement 
            if(Result[`DATA_WIDTH-1:0]== 0) begin
                 Zero = 1;
            end
            else begin
                Zero = 0;
            end
            
        end
endmodule
