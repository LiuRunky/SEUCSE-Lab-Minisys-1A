`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: 译码单元
// Function:    1. 读/写寄存器组
//              2. 实现零扩展/位扩展
//////////////////////////////////////////////////////////////////////////////////


module Idecode(
    Instruction,Received_data,PC_plus_4,PC_plus_4_latch,ALU_result,CP0_data_latch,
    clock,reset,
    Jal,Jalr,Bgezal,Bltzal,
    Memory_or_IO,Register_write,Write_back_address,
    Read_data_1,Read_data_2,Immediate_extend,
    Mfc0,Mtc0,
    Break,Syscall,Eret,
    Positive,Negative,
    Overflow,Divide_zero,Reserved_instruction,
    Cause_write,Cause_write_data,Cause_read_data,
    Status_write,Status_write_data,Status_read_data,
    EPC_write,EPC_write_data,EPC_read_data,
    CP0_data,PC_exception
    );

    input[31:0]     Instruction;        //指令
    input[31:0]     Received_data;      //从DATA RAM或I/O端口取出的数据
    input[31:0]     PC_plus_4;          //真正的PC+4(当前指令的下一条)
    input[31:0]     PC_plus_4_latch;    //在ifetch中被锁存住的PC+4值
    input[31:0]     ALU_result;         //ALU计算结果
    input[31:0]     CP0_data_latch;     //锁存的CP0数据
    
    input       clock;
    input       reset;
    
    input       Jal,Jalr;
    input       Bgezal,Bltzal;
    input       Memory_or_IO;           //数据来源是否为DATA RAM或I/O端口
    input       Register_write;         //是否写寄存器
    input[4:0]  Write_back_address;     //用于指定待写寄存器
    
    output[31:0]    Read_data_1;        //从寄存器中取出的第一个数，一般为rs
    output[31:0]    Read_data_2;        //从寄存器中取出的第二个数，一般为rt（R指令）
    output[31:0]    Immediate_extend;   //经过零扩展/符号扩展后的立即数
    
    input       Mfc0,Mtc0;
    
    input       Break,Syscall,Eret;
    input       Positive,Negative;
    input       Overflow,Divide_zero,Reserved_instruction;
    
    output          Cause_write,Status_write,EPC_write;
    output[31:0]    Cause_write_data,Status_write_data,EPC_write_data;
    input[31:0] Cause_read_data,Status_read_data,EPC_read_data;
    
    output[31:0]    CP0_data;
    output[31:0]    PC_exception;
    
    
    wire[5:0]   opcode;
    wire[4:0]   rs;
    wire[4:0]   rt;
    wire[4:0]   rd;                     //大多数R指令中的目的寄存器号
    wire[15:0]  immediate;              //I指令中的immediate / offset
    
    wire        sign;                   //立即数的符号位
    
    
    reg[31:0]   register[0:31];         //32x32寄存器组
    
    reg[31:0]   write_data;             //锁存待写数据
    reg[4:0]    write_address;           //锁存待写寄存器号
    
    reg[31:0]   cp0_data;
    reg         Cause_write,Status_write,EPC_write;
    reg[31:0]   Cause_write_data,Status_write_data,EPC_write_data;
    
    reg[31:0]   PC_exception;           //硬编码的中断处理程序入口地址/EPC
    
    
    
    //分离指令分量
    assign opcode = Instruction[31:26];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    assign rd = Instruction[15:11];
    assign immediate = Instruction[15:0];
    
    //寄存器读
    assign Read_data_1 = register[rs];
    assign Read_data_2 = register[rt];
    
    assign CP0_data = cp0_data;
    
    always @(*)
    begin
        case ({Mfc0,rd})
            6'b101100: cp0_data = Status_read_data;
            6'b101101: cp0_data = Cause_read_data;
            6'b101110: cp0_data = EPC_read_data;
            default: cp0_data = 32'hFFFFFFFF;
        endcase
        
        //准备要写的寄存器号
        write_address = (Jal || (Bgezal && !Negative) || (Bltzal && Negative))
            ? 5'd31
            : ((Bgezal || Bltzal) ? 5'd00 : Write_back_address);
                
        //准备要写的数据
        write_data = (Jal || Jalr || Bgezal || Bltzal)
            ? PC_plus_4_latch
            : (
                  Memory_or_IO 
                  ? Received_data
                  : (CP0_data_latch != 32'hFFFFFFFF ? CP0_data_latch : ALU_result)
              );
        
        //开始中断响应步骤
        if (Break || Syscall || Overflow || Reserved_instruction)
        begin
            //修改CP0.Status.IE
            Status_write_data = {Status_read_data[31:1],1'b0};
            
            //修改CP0.Cause.ExcCode
            case ({Break,Syscall,Overflow,Reserved_instruction})
                4'b1000: Cause_write_data = {Cause_read_data[31:7],7'b01001_00};
                4'b0100: Cause_write_data = {Cause_read_data[31:7],7'b01000_00};
                4'b0010: Cause_write_data = {Cause_read_data[31:7],7'b01100_00};
                4'b0001: Cause_write_data = {Cause_read_data[31:7],7'b01010_00};
                default: Cause_write_data = {Cause_read_data[31:7],7'b00000_00};
            endcase
            
            //修改CP0.EPC
            EPC_write_data = PC_plus_4;                         //指向下一条指令
            
            //PC_exception为中断处理程序入口地址0xF000
            PC_exception = 32'h0000F000;
            
            //写使能有效
            Status_write = 1'b1;
            Cause_write = 1'b1;
            EPC_write = 1'b1;
        end
        //开始中断返回处理
        else if (Eret)
        begin
            //修改CP0.Status.IE
            Status_write_data = {Status_read_data[31:1],1'b1};
            
            PC_exception = EPC_read_data;
            
            //Status写使能有效
            Status_write = 1'b1;
        end
        //执行Mtc0指令
        else if (Mtc0)
        begin
            case (rd)
                5'd12:
                begin
                    Status_write_data = Read_data_2;
                    Status_write = 1'b1;
                end
                5'd13:
                begin
                    Cause_write_data = Read_data_2;
                    Cause_write = 1'b1;
                end
                5'd14:
                begin
                    EPC_write_data = Read_data_2;
                    EPC_write = 1'b1;
                end
                default:
                begin
                    Status_write = 1'b0;
                    Cause_write = 1'b0;
                    EPC_write = 1'b0;
                end
            endcase
        end
        else
        //与中断无关，PC_exception为0xFFFFFFFF
        begin
            PC_exception = 32'hFFFFFFFF;
            
            //写使能无效
            Status_write = 1'b0;
            Cause_write = 1'b0;
            EPC_write = 1'b0;
        end
    end
    
    //写寄存器
    integer i;
    always @(posedge clock)
    begin
        if (reset) //初始化寄存器组
        begin
            for (i = 0; i < 32; i = i + 1)
                register[i] <= i;
        end
        else if (Register_write && write_address != 5'd00) //写寄存器
        begin
            register[write_address] = write_data;
        end
    end
    
    //根据需求完成对16位立即数的32位扩展
    assign sign = immediate[15];
    assign Immediate_extend[31:16] =
        (opcode == 6'b001100 /*andi*/ || opcode == 6'b001101 /*ori*/ ||
            opcode == 6'b001110 /*xori*/ || opcode == 6'b001011 /*sltiu*/)
            ? 16'h0000      //零扩展
            : {16{sign}};   //符号扩展
    assign Immediate_extend[15:0] = immediate;
    
endmodule