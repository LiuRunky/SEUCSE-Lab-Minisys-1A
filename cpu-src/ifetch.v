`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: 取址单元
// Function:    1. 从指令寄存器inst_mem中取出指令
//              2. 根据各种跳转指令与标志生成next_PC
//              3. 修改PC并为idecode锁存PC+4
//////////////////////////////////////////////////////////////////////////////////


module Ifetch(
    Instruction,Instruction_ex_mem,
    PC_plus_4,PC_plus_4_latch,
    clock,reset,
    Jr,Jalr,Jmp,Jal,
    Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal,
    Zero,Positive,Negative,
    PC_add_result,Read_data_rs,
    Rom_adr_o,Jpadr,
    PC_exception,
    Nonflush_ex_mem,PC_plus_4_id_ex,flush_pipeline
    );
    
    output[31:0]    Instruction;
    input[31:0]     Instruction_ex_mem;                     //由EX/MEM流水寄存器传来的PC值
    output[31:0]    PC_plus_4;                              //一般意义上的PC+4，传给execute
    output[31:0]    PC_plus_4_latch;                        //对于jal/jalr锁存的PC+4，传给idecode
    
    input   clock;
    input   reset;
    input   Jr,Jalr,Jmp,Jal;
    input   Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal;
    input   Zero;                                           //execute单元计算出的相减Zero标志
    input   Positive;                                       //execute单元判断出的rs是否为正标志
    input   Negative;                                       //execute单元判断出的rs是否为负标志
    input[31:0] PC_add_result;                              //execute单元计算出的PC+4+offset<<2
    input[31:0] Read_data_rs;                               //idecode单元取出的(rs)
    
    //RAMROM引脚
    output[13:0]    Rom_adr_o;                              //给指令存储器单元的取值地址
    input[31:0] Jpadr;                                      //指令存储器中取出的指令
    
    input[31:0] PC_exception;                               //硬编码的中断处理程序入口地址/EPC
    
    input   Nonflush_ex_mem;
    input[31:0] PC_plus_4_id_ex;
    output  flush_pipeline;
    
    wire[31:0]  Instruction;
    
    reg[31:0]   PC;
    reg[31:0]   jump_PC;                                    //只考虑跳转的情况，否则为32'hFFFFFFFF
    reg[31:0]   next_PC;
    reg[31:0]   PC_plus_4_latch;
    
    reg         flush_pipeline;
    
/*  原本的指令ROM
    //64KB ROM
    inst_mem inst_mem(
        .clka(clock),
        .addra(PC[15:2]),
        .douta(Instruction)                                 //指令在这里被取出
    );
*/
    
    //64KB RAMROM
    assign Rom_adr_o = PC[15:2];
    assign Instruction = Jpadr;
    
    assign PC_plus_4 = {PC[31:2] + 1'b1,2'b00};
    
    //next_PC是右移2位后的PC，从而保证强制对齐
    always @(posedge clock)
    begin
        jump_PC = (Beq && Zero) || (Bne && !Zero) ||
                  (Bgez && !Negative) || (Bgtz && Positive) ||
                  (Blez && !Positive) || (Bltz && Negative) ||
                  (Bgezal && !Negative) || (Bltzal && Negative)
                  ? PC_add_result
                  : (
                        Jmp || Jal
                        ? Instruction_ex_mem & 32'h03FFFFFF
                        : (
                              Jr || Jalr
                              ? Read_data_rs >> 2
                              : (
                                    PC_exception == 32'hFFFFFFFF
                                    ? 32'hFFFFFFFF
                                    : PC_exception >> 2
                                )
                          )
                    );
        next_PC = (jump_PC == 32'hFFFFFFFF) ? PC_plus_4 >> 2 : jump_PC;
        flush_pipeline = (
                             jump_PC != 32'hFFFFFFFF ||
                             (Nonflush_ex_mem && (next_PC << 2) != PC_plus_4_id_ex + 8)
                         )
                         ? 1'b1 : 1'b0;
    end
    
    //修改PC
    always @(negedge clock)
    begin
        if (Jal || Jalr)
            PC_plus_4_latch = PC_plus_4;                    //需要在改变PC前锁存住之前的PC+4
        PC = reset ? 32'h00000000 : next_PC << 2;
    end
    
endmodule
