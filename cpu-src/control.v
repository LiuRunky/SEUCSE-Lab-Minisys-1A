`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: 控制单元
// Function:    1. 根据指令生成各种信号
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
    
    output      I_type;                                     //是否为I指令
    output      Jmp,Jr,Jal,Jalr;                            //无条件跳转
    output      Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal;  //条件跳转
    output      Register_write;                             //写寄存器
    output[4:0] Register_write_sel;                         //选择写rt还是rd
    output      Memory_or_IO;                               //数据来源是否为存储器或I/O端口
    output      Mfhi,Mflo,Mfc0,Mthi,Mtlo,Mtc0;              //读写HI/LO外部寄存器
    output      Shift;                                      //移位运算
    output[1:0] ALU_op;                                     //ALU使用的运算符
    output      ALU_src;                                    //ALU操作数2来源是寄存器或立即数
    output      Memory_sign;                                //lb/lbu/lh/lhu的处理
    output[1:0] Memory_data_width;                          //读写存储器的数据宽度(00/01/11)
    output      Break,Syscall,Eret;                         //中断/异常相关指令
    output      Reserved_instruction;                       //是否为保留指令
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
    
    
    
    //将Instruction进行拆分
    assign opcode = Instruction[31:26];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    assign rd = Instruction[15:11];
    assign shamt = Instruction[10:6];
    assign func = Instruction[5:0];
    assign immediate = Instruction[15:0];
    
    
    
    //R指令特征：opcode=0
    assign r_format = (opcode == 6'b000000 || opcode == 6'b010000/*CP0相关*/) ? 1'b1 : 1'b0;
    
    //I指令特征：
    //1.i_type：加减、逻辑、lui、slti/sltiu
    //2.l_type：从存储器读出数据
    //3.s_type：向存储器存入数据
    //4.b_type：条件跳转【并不严格，包含了J指令】
    assign i_type = opcode[5:3] == 3'b001 ? 1'b1 : 1'b0;
    assign l_type = opcode[5:3] == 3'b100 ? 1'b1 : 1'b0;
    assign s_type = opcode[5:3] == 3'b101 ? 1'b1 : 1'b0;
    assign b_type = opcode[5:3] == 3'b000 ? 1'b1 : 1'b0;
    assign I_type = i_type;
    
    //几种无条件跳转指令：Jmp,Jr,Jal,Jalr
    assign Jmp = (opcode == 6'b000010) ? 1'b1 : 1'b0;
    assign Jal = (opcode == 6'b000011) ? 1'b1 : 1'b0;
    assign Jr = (opcode == 6'b000000 && func == 6'b001000) ? 1'b1 : 1'b0;
    assign Jalr = (opcode == 6'b000000 && func == 6'b001001) ? 1'b1 : 1'b0;
    
    //几种有条件跳转指令：Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal
    assign Beq = (opcode == 6'b000100) ? 1'b1 : 1'b0;
    assign Bne = (opcode == 6'b000101) ? 1'b1 : 1'b0;
    assign Bgez = (opcode == 6'b000001 && rt == 5'b00001) ? 1'b1 : 1'b0;
    assign Bgtz = (opcode == 6'b000111 && rt == 5'b00000) ? 1'b1 : 1'b0;
    assign Blez = (opcode == 6'b000110 && rt == 5'b00000) ? 1'b1 : 1'b0;
    assign Bltz = (opcode == 6'b000001 && rt == 5'b00000) ? 1'b1 : 1'b0;
    assign Bgezal = (opcode == 6'b000001 && rt == 5'b10001) ? 1'b1 : 1'b0;
    assign Bltzal = (opcode == 6'b000001 && rt == 5'b10000) ? 1'b1 : 1'b0;
    
    //几种读写外部存储器：Mfhi,Mflo,Mfc0,Mthi,Mtlo,Mtc0
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
    //对于R指令：数值逻辑计算(func=100xxx)、读HI/LO/C0(mfhi/mflo/mfc0)
    //           移位(shift)、Slt/Sltu(func=10101x)、Jalr
    //对于I指令：i_type、l_type、Bgezal、Bltzal
    //对于J指令：Jal
    assign Register_write = r_format 
        ? (
            (func[5:3] == 3'b100 || Mfhi || Mflo || Mfc0 || Shift ||
             func[5:1] == 5'b10101 || Jalr) ? 1'b1 : 1'b0
          )
        : (
            (i_type || l_type || Bgezal || Bltzal || Jal) ? 1'b1 : 1'b0
          );
    
    //Register_write_sel
    //只有为R指令时为rd
    assign Register_write_sel = Mfc0 ? rt : (r_format ? rd : rt);
    
    //Memory_or_IO
    //l_type
    assign Memory_or_IO = l_type;
    
    //Shift
    //opcode全0，func高3位为0，低3位不为001
    assign Shift = (opcode == 6'b000000 && func[5:3] == 3'b000 && func[2:0] != 3'b001)
                   ? 1'b1 : 1'b0;
    
    //ALU_op
    //抄的mooc，对的
    assign ALU_op = {
                        (r_format || i_type),
                        (Beq || Bne || Bgez || Bgtz || Blez ||Bltz || Bgezal || Bltzal)
                    };
    
    //ALU_src
    //i_type、l_type、s_type
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
                            //数值逻辑
                            func[5:3] == 3'b100 ||
                            //乘除
                            (func[5:2] == 4'b0110 && rd == 5'b00000 && shamt == 5'b00000) ||
                            //HI/LO相关
                            Mfhi || Mflo || Mthi || Mtlo ||
                            //slt/sltu
                            (func[5:1] == 5'b10101 && shamt == 5'b00000) ||
                            //移位
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
                    Instruction == 32'h00000000         //保留的nop
                )
            )
            ? 1'b0 : 1'b1;
    
    assign L_type = l_type;
    assign S_type = s_type;
    
endmodule