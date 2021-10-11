`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ȡַ��Ԫ
// Function:    1. ��ָ��Ĵ���inst_mem��ȡ��ָ��
//              2. ���ݸ�����תָ�����־����next_PC
//              3. �޸�PC��Ϊidecode����PC+4
//////////////////////////////////////////////////////////////////////////////////


module Ifetch(
    Instruction,Instruction_latch,
    PC_plus_4,PC_plus_4_latch,
    clock,reset,
    Jr,Jalr,Jmp,Jal,
    Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal,
    Zero,Positive,Negative,
    PC_add_result,Read_data_rs,
    Rom_adr_o,Jpadr,
    PC_exception,
    PC_plus_4_id_ex,flush_pipeline
    );
    
    output[31:0]    Instruction;
    input[31:0]     Instruction_latch;                      //��EX/MEM��ˮ�Ĵ���������PCֵ
    output[31:0]    PC_plus_4;                              //һ�������ϵ�PC+4������execute
    output[31:0]    PC_plus_4_latch;                        //����jal/jalr�����PC+4������idecode
    
    input   clock;
    input   reset;
    input   Jr,Jalr,Jmp,Jal;
    input   Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal;
    input   Zero;                                           //execute��Ԫ����������Zero��־
    input   Positive;                                       //execute��Ԫ�жϳ���rs�Ƿ�Ϊ����־
    input   Negative;                                       //execute��Ԫ�жϳ���rs�Ƿ�Ϊ����־
    input[31:0] PC_add_result;                              //execute��Ԫ�������PC+4+offset<<2
    input[31:0] Read_data_rs;                               //idecode��Ԫȡ����(rs)
    
    //RAMROM����
    output[13:0]    Rom_adr_o;                              //��ָ��洢����Ԫ��ȡֵ��ַ
    input[31:0] Jpadr;                                      //ָ��洢����ȡ����ָ��
    
    input[31:0] PC_exception;                               //Ӳ������жϴ��������ڵ�ַ/EPC
    
    input[31:0] PC_plus_4_id_ex;
    output  flush_pipeline;
    
    wire[31:0]  Instruction;
    
    reg[31:0]   PC;
    reg[31:0]   next_PC;
    reg[31:0]   PC_plus_4_latch;
    
    reg         flush_pipeline;
    
/*  ԭ����ָ��ROM
    //64KB ROM
    inst_mem inst_mem(
        .clka(clock),
        .addra(PC[15:2]),
        .douta(Instruction)                                 //ָ�������ﱻȡ��
    );
*/
    
    //64KB RAMROM
    assign Rom_adr_o = PC[15:2];
    assign Instruction = Jpadr;
    
    assign PC_plus_4 = {PC[31:2] + 1'b1,2'b00};
    
    //next_PC������2λ���PC���Ӷ���֤ǿ�ƶ���
    always @(*)
    begin
        next_PC = (Beq && Zero) || (Bne && !Zero) ||
                  (Bgez && !Negative) || (Bgtz && Positive) ||
                  (Blez && !Positive) || (Bltz && Negative) ||
                  (Bgezal && !Negative) || (Bltzal && Negative)
                  ? PC_add_result
                  : (
                        Jr || Jalr
                        ? Read_data_rs >> 2
                        : (
                              PC_exception == 32'hFFFFFFFF
                              ? PC_plus_4 >> 2
                              : PC_exception >> 2
                          )
                    );
    end
    
    //�޸�PC
    always @(negedge clock)
    begin
        if (Jal || Jalr)
            PC_plus_4_latch = PC_plus_4;                    //��Ҫ�ڸı�PCǰ����ס֮ǰ��PC+4
        
        PC = reset
             ? 32'h00000000
             : (Jmp || Jal)
               ? (Instruction_latch & 32'h03FFFFFF) << 2
               : next_PC << 2;
        
        flush_pipeline = (Instruction_latch != 32'h00000000 && PC != PC_plus_4_id_ex + 8)
                         ? 1'b1 : 1'b0;
    end
    
endmodule