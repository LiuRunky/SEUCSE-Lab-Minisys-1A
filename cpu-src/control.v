`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ���Ƶ�Ԫ
// Function:    1. ����ָ�����ɸ����ź�
//////////////////////////////////////////////////////////////////////////////////


module Control(
    Instruction,
    I_type,Jmp,Jr,Jal,Jalr,
    Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal,
    Register_write,Register_write_sel,
    Memory_or_IO,
    Mfhi,Mflo,Mfc0,Mthi,Mtlo,Mtc0,
    Shift,ALU_op,ALU_src,Memory_sign,Memory_data_width,
    Break,Syscall,Eret,
    Reserved_instruction,
    L_type,S_type
    );

    input[31:0] Instruction;
    
    output      I_type;                                     //�Ƿ�ΪIָ��
    output      Jmp,Jr,Jal,Jalr;                            //��������ת
    output      Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal;  //������ת
    output      Register_write;                             //д�Ĵ���
    output[4:0] Register_write_sel;                         //ѡ��дrt����rd
    output      Memory_or_IO;                               //������Դ�Ƿ�Ϊ�洢����I/O�˿�
    output      Mfhi,Mflo,Mfc0,Mthi,Mtlo,Mtc0;              //��дHI/LO�ⲿ�Ĵ���
    output      Shift;                                      //��λ����
    output[1:0] ALU_op;                                     //ALUʹ�õ������
    output      ALU_src;                                    //ALU������2��Դ�ǼĴ�����������
    output      Memory_sign;                                //lb/lbu/lh/lhu�Ĵ���
    output[1:0] Memory_data_width;                          //��д�洢�������ݿ��(00/01/11)
    output      Break,Syscall,Eret;                         //�ж�/�쳣���ָ��
    output      Reserved_instruction;                       //�Ƿ�Ϊ����ָ��
    output      L_type,S_type;
    
    wire[6:0]   opcode,func;
    wire[5:0]   rs,rt, rd,shamt;
    wire[16:0]  immediate;
    
    wire r_format;
    wire i_type,l_type,s_type,b_type;
    wire Jmp,Jr,Jal,Jalr;
    wire Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal;
    wire Mfhi,Mflo,Mfc0,Mthi,Mtlo,Mtc0;
    wire Shift;
    
    
    
    //��Instruction���в��
    assign opcode = Instruction[31:26];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    assign rd = Instruction[15:11];
    assign shamt = Instruction[10:6];
    assign func = Instruction[5:0];
    assign immediate = Instruction[15:0];
    
    
    
    //Rָ��������opcode=0
    assign r_format = (opcode == 6'b000000 || opcode == 6'b010000/*CP0���*/) ? 1'b1 : 1'b0;
    
    //Iָ��������
    //1.i_type���Ӽ����߼���lui��slti/sltiu
    //2.l_type���Ӵ洢����������
    //3.s_type����洢����������
    //4.b_type��������ת�������ϸ񣬰�����Jָ�
    assign i_type = opcode[5:3] == 3'b001 ? 1'b1 : 1'b0;
    assign l_type = opcode[5:3] == 3'b100 ? 1'b1 : 1'b0;
    assign s_type = opcode[5:3] == 3'b101 ? 1'b1 : 1'b0;
    assign b_type = opcode[5:3] == 3'b000 ? 1'b1 : 1'b0;
    assign I_type = i_type;
    
    //������������תָ�Jmp,Jr,Jal,Jalr
    assign Jmp = (opcode == 6'b000010) ? 1'b1 : 1'b0;
    assign Jal = (opcode == 6'b000011) ? 1'b1 : 1'b0;
    assign Jr = (opcode == 6'b000000 && func == 6'b001000) ? 1'b1 : 1'b0;
    assign Jalr = (opcode == 6'b000000 && func == 6'b001001) ? 1'b1 : 1'b0;
    
    //������������תָ�Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal
    assign Beq = (opcode == 6'b000100) ? 1'b1 : 1'b0;
    assign Bne = (opcode == 6'b000101) ? 1'b1 : 1'b0;
    assign Bgez = (opcode == 6'b000001 && rt == 5'b00001) ? 1'b1 : 1'b0;
    assign Bgtz = (opcode == 6'b000111 && rt == 5'b00000) ? 1'b1 : 1'b0;
    assign Blez = (opcode == 6'b000110 && rt == 5'b00000) ? 1'b1 : 1'b0;
    assign Bltz = (opcode == 6'b000001 && rt == 5'b00000) ? 1'b1 : 1'b0;
    assign Bgezal = (opcode == 6'b000001 && rt == 5'b10001) ? 1'b1 : 1'b0;
    assign Bltzal = (opcode == 6'b000001 && rt == 5'b10000) ? 1'b1 : 1'b0;
    
    //���ֶ�д�ⲿ�洢����Mfhi,Mflo,Mfc0,Mthi,Mtlo,Mtc0
    assign Mfhi = (opcode == 6'b000000 && rs == 5'b00000 && rt == 5'b00000 &&
                   shamt == 5'b00000 && func == 6'b010000) ? 1'b1 : 1'b0;
    assign Mflo = (opcode == 6'b000000 && rs == 5'b00000 && rt == 5'b00000 &&
                   shamt == 5'b00000 && func == 6'b010010) ? 1'b1 : 1'b0;
    assign Mfc0 = (opcode == 6'b010000 && rs == 5'b00000 && shamt == 5'b00000 &&
                   func[5:3] == 3'b000) ? 1'b1 : 1'b0;
    assign Mthi = (opcode == 6'b000000 && rt == 5'b00000 && rd == 5'b00000 &&
                   shamt == 5'b00000 && func == 6'b010001) ? 1'b1 : 1'b0;
    assign Mtlo = (opcode == 6'b000000 && rt == 5'b00000 && rd == 5'b00000 &&
                   shamt == 5'b00000 && func == 6'b010011) ? 1'b1 : 1'b0;
    assign Mtc0 = (opcode == 6'b010000 && rs == 5'b00100 && shamt == 5'b00000 &&
                   func[5:3] == 3'b000) ? 1'b1 : 1'b0;
    
    //Register_write
    //����Rָ���ֵ�߼�����(func=100xxx)����HI/LO/C0(mfhi/mflo/mfc0)
    //           ��λ(shift)��Slt/Sltu(func=10101x)��Jalr
    //����Iָ�i_type��l_type��Bgezal��Bltzal
    //����Jָ�Jal
    assign Register_write = r_format 
        ? (
            (func[5:3] == 3'b100 || Mfhi || Mflo || Mfc0 || Shift ||
             func[5:1] == 5'b10101 || Jalr) ? 1'b1 : 1'b0
          )
        : (
            (i_type || l_type || Bgezal || Bltzal || Jal) ? 1'b1 : 1'b0
          );
    
    //Register_write_sel
    //ֻ��ΪRָ��ʱΪrd
    assign Register_write_sel = Mfc0 ? rt : (r_format ? rd : rt);
    
    //Memory_or_IO
    //l_type
    assign Memory_or_IO = l_type;
    
    //Shift
    //opcodeȫ0��func��3λΪ0����3λ��Ϊ001
    assign Shift = (opcode == 6'b000000 && func[5:3] == 3'b000 && func[2:0] != 3'b001)
                   ? 1'b1 : 1'b0;
    
    //ALU_op
    //����mooc���Ե�
    assign ALU_op = {
                        (r_format || i_type),
                        (Beq || Bne || Bgez || Bgtz || Blez ||Bltz || Bgezal || Bltzal)
                    };
    
    //ALU_src
    //i_type��l_type��s_type
    assign ALU_src = i_type || l_type || s_type;
    
    //Memory_sign
    assign Memory_sign = opcode[2];
    
    //Memory_data_width
    assign Memory_data_width = opcode[1:0];
    
    //Break
    assign Break = (opcode == 6'b000000 && func == 6'b001101) ? 1'b1 : 1'b0;
    
    //Syscall
    assign Syscall = (opcode == 6'b000000 && func == 6'b001100) ? 1'b1 : 1'b0;
    
    //Eret
    assign Eret = (Instruction == 32'b010000_1000_0000_0000_0000_0000_011000) ? 1'b1 : 1'b0;
    
    //Reserved_instruction
    assign Reserved_instruction =
            (
                (r_format && 
                    (opcode == 6'b000000 &&
                        (
                            //��ֵ�߼�
                            func[5:3] == 3'b100 ||
                            //�˳�
                            (func[5:2] == 4'b0110 && rd == 5'b00000 && shamt == 5'b00000) ||
                            //HI/LO���
                            Mfhi || Mflo || Mthi || Mtlo ||
                            //slt/sltu
                            (func[5:1] == 5'b10101 && shamt == 5'b00000) ||
                            //��λ
                            (func[5:2] == 4'b0000 && rs == 5'b00000) ||
                            (func[5:2] == 4'b0001 && shamt == 5'b00000)
                        ) ||
                        Mfc0 || Mtc0 || Jr || Jalr || Break || Syscall || Eret
                    )
                ) ||
                (
                    i_type || l_type || s_type ||
                    Beq || Bne || Bgez || Bgtz || Blez || Bltz || Bgezal || Bltzal
                ) ||
                (
                    Jmp || Jal
                ) ||
                (
                    Instruction == 32'h00000000         //������nop
                )
            )
            ? 1'b0 : 1'b1;
    
    assign L_type = l_type;
    assign S_type = s_type;
    
endmodule