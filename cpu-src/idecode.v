`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ���뵥Ԫ
// Function:    1. ��/д�Ĵ�����
//              2. ʵ������չ/λ��չ
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

    input[31:0]     Instruction;        //ָ��
    input[31:0]     Received_data;      //��DATA RAM��I/O�˿�ȡ��������
    input[31:0]     PC_plus_4;          //������PC+4(��ǰָ�����һ��)
    input[31:0]     PC_plus_4_latch;    //��ifetch�б�����ס��PC+4ֵ
    input[31:0]     ALU_result;         //ALU������
    input[31:0]     CP0_data_latch;     //�����CP0����
    
    input       clock;
    input       reset;
    
    input       Jal,Jalr;
    input       Bgezal,Bltzal;
    input       Memory_or_IO;           //������Դ�Ƿ�ΪDATA RAM��I/O�˿�
    input       Register_write;         //�Ƿ�д�Ĵ���
    input[4:0]  Write_back_address;     //����ָ����д�Ĵ���
    
    output[31:0]    Read_data_1;        //�ӼĴ�����ȡ���ĵ�һ������һ��Ϊrs
    output[31:0]    Read_data_2;        //�ӼĴ�����ȡ���ĵڶ�������һ��Ϊrt��Rָ�
    output[31:0]    Immediate_extend;   //��������չ/������չ���������
    
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
    wire[4:0]   rd;                     //�����Rָ���е�Ŀ�ļĴ�����
    wire[15:0]  immediate;              //Iָ���е�immediate / offset
    
    wire        sign;                   //�������ķ���λ
    
    
    reg[31:0]   register[0:31];         //32x32�Ĵ�����
    
    reg[31:0]   write_data;             //�����д����
    reg[4:0]    write_address;           //�����д�Ĵ�����
    
    reg[31:0]   cp0_data;
    reg         Cause_write,Status_write,EPC_write;
    reg[31:0]   Cause_write_data,Status_write_data,EPC_write_data;
    
    reg[31:0]   PC_exception;           //Ӳ������жϴ��������ڵ�ַ/EPC
    
    
    
    //����ָ�����
    assign opcode = Instruction[31:26];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    assign rd = Instruction[15:11];
    assign immediate = Instruction[15:0];
    
    //�Ĵ�����
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
        
        //׼��Ҫд�ļĴ�����
        write_address = (Jal || (Bgezal && !Negative) || (Bltzal && Negative))
            ? 5'd31
            : ((Bgezal || Bltzal) ? 5'd00 : Write_back_address);
                
        //׼��Ҫд������
        write_data = (Jal || Jalr || Bgezal || Bltzal)
            ? PC_plus_4_latch
            : (
                  Memory_or_IO 
                  ? Received_data
                  : (CP0_data_latch != 32'hFFFFFFFF ? CP0_data_latch : ALU_result)
              );
        
        //��ʼ�ж���Ӧ����
        if (Break || Syscall || Overflow || Reserved_instruction)
        begin
            //�޸�CP0.Status.IE
            Status_write_data = {Status_read_data[31:1],1'b0};
            
            //�޸�CP0.Cause.ExcCode
            case ({Break,Syscall,Overflow,Reserved_instruction})
                4'b1000: Cause_write_data = {Cause_read_data[31:7],7'b01001_00};
                4'b0100: Cause_write_data = {Cause_read_data[31:7],7'b01000_00};
                4'b0010: Cause_write_data = {Cause_read_data[31:7],7'b01100_00};
                4'b0001: Cause_write_data = {Cause_read_data[31:7],7'b01010_00};
                default: Cause_write_data = {Cause_read_data[31:7],7'b00000_00};
            endcase
            
            //�޸�CP0.EPC
            EPC_write_data = PC_plus_4;                         //ָ����һ��ָ��
            
            //PC_exceptionΪ�жϴ��������ڵ�ַ0xF000
            PC_exception = 32'h0000F000;
            
            //дʹ����Ч
            Status_write = 1'b1;
            Cause_write = 1'b1;
            EPC_write = 1'b1;
        end
        //��ʼ�жϷ��ش���
        else if (Eret)
        begin
            //�޸�CP0.Status.IE
            Status_write_data = {Status_read_data[31:1],1'b1};
            
            PC_exception = EPC_read_data;
            
            //Statusдʹ����Ч
            Status_write = 1'b1;
        end
        //ִ��Mtc0ָ��
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
        //���ж��޹أ�PC_exceptionΪ0xFFFFFFFF
        begin
            PC_exception = 32'hFFFFFFFF;
            
            //дʹ����Ч
            Status_write = 1'b0;
            Cause_write = 1'b0;
            EPC_write = 1'b0;
        end
    end
    
    //д�Ĵ���
    integer i;
    always @(posedge clock)
    begin
        if (reset) //��ʼ���Ĵ�����
        begin
            for (i = 0; i < 32; i = i + 1)
                register[i] <= i;
        end
        else if (Register_write && write_address != 5'd00) //д�Ĵ���
        begin
            register[write_address] = write_data;
        end
    end
    
    //����������ɶ�16λ��������32λ��չ
    assign sign = immediate[15];
    assign Immediate_extend[31:16] =
        (opcode == 6'b001100 /*andi*/ || opcode == 6'b001101 /*ori*/ ||
            opcode == 6'b001110 /*xori*/ || opcode == 6'b001011 /*sltiu*/)
            ? 16'h0000      //����չ
            : {16{sign}};   //������չ
    assign Immediate_extend[15:0] = immediate;
    
endmodule