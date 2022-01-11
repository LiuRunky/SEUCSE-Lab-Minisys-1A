`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: 执行单元
// Function:    1. 加减与逻辑运算，产生ZeroFlag
//              2. 乘法器(考虑流水级数)
//              3. 除法器(考虑是否阻塞)
//              4. 各类移位
//
//Notes:        1. 除法结果为负时，是对商和余数同时取反的
//              2. inverse_mul_div寄存器并不会锁存
//              3. 有符号加法产生Overflow后，会继续将数据存入寄存器
//              4. 除了beq/bne以外的b-type判断不在execute中进行
//////////////////////////////////////////////////////////////////////////////////


module Execute(
    clock,Instruction,
    ALU_src,ALU_op,Shift,I_type,
    Read_data_1,Read_data_2,Immediate_extend,PC_plus_4,
    ALU_result,PC_add_result,
    Zero,Positive,Negative,Overflow,Divide_zero,
    Mfhi,Mflo,Mthi,Mtlo,
    L_type,S_type,
    Memory_read,Memory_write,IO_read,IO_write,
    Register_write_ex_mem,Write_back_address_ex_mem,
    Register_write_mem_wb,Write_back_address_mem_wb,Memory_or_IO_mem_wb,
    ALU_result_ex_mem,ALU_result_mem_wb,Read_data_mem_wb,
    Forwarded_data_1,Forwarded_data_2
    );
    
    input       clock;                          //clk
    input[31:0] Instruction;
    
    input       ALU_src;                        //选择ALU操作数2(0寄存器/1立即数)
    input[1:0]  ALU_op;                         //选择ALU进行的运算类型
    input       Shift;                          //是否移位运算
    input       I_type;                         //是否为I指令
    input[31:0] Read_data_1;                    //rs
    input[31:0] Read_data_2;                    //rt
    input[31:0] Immediate_extend;               //imme
    input[31:0] PC_plus_4;                      //PC+4的值【无任何处理】
    
    output[31:0]    ALU_result;                 //ALU运算结果
    output[31:0]    PC_add_result;              //对于PC+4+(imme<<2)的运算结果【已除以4】
    output          Zero;                       //结果是否为0
    output          Positive;                   //rs是否为正
    output          Negative;                   //rs是否为负
    output          Overflow;                   //是否产生加减法溢出
    output          Divide_zero;                //是否除0
    
    input       Mfhi,Mflo,Mthi,Mtlo;            //是否为读写HI/LO寄存器的指令
    
    input       L_type,S_type;
    output      Memory_read,Memory_write,IO_read,IO_write;
    
    //处理数据转发
    input       Register_write_ex_mem,Register_write_mem_wb,Memory_or_IO_mem_wb;
    input[4:0]  Write_back_address_ex_mem,Write_back_address_mem_wb;
    input[31:0] ALU_result_ex_mem,ALU_result_mem_wb,Read_data_mem_wb;
    
    output[31:0]    Forwarded_data_1,Forwarded_data_2;
    
    
    
    wire[31:0]  Forwarded_data_1,Forwarded_data_2;  //考虑流水中数据转发后的read_data_1/2
    wire[31:0]  a_input,b_input;
    wire[5:0]   opcode;
    wire[4:0]   rs,rt;
    wire[4:0]   shamt;
    wire[5:0]   func;
    
    wire[6:0]   exec_code;                      //辅助计算ALU_ctrl
    wire[2:0]   ALU_ctrl;                       //用于进行ALU的算数逻辑运算选择
    
    wire        signed_mul_div;                 //是否为有符号乘除法
    wire[31:0]  transformed_data_1,transformed_data_2;  //转为正数的a/b_input
    
    wire        mul_sel;                        //是否为乘法
    wire        div_sel;                        //是否为除法
    wire[63:0]  unsigned_mul_result;
    wire        divu_divisor_tvalid;
    wire        divu_dividend_tvalid;
    wire        divu_dout_tvalid;
    wire        divu_dout_tuser;
    wire[63:0]  unsigned_div_result;
    
    reg         inverse_mul_div_result;         //根据原符号位，确定是否需要反转结果
    reg[31:0]   ALU_output;                     //算数逻辑运算结果
    reg[31:0]   shift_result;                   //移位运算结果
    reg[31:0]   hi,lo;
    reg[31:0]   ALU_result;                     //最终运算结果
    
    
    
    assign opcode = Instruction[31:26];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    assign shamt = Instruction[10:6];
    assign func = Instruction[5:0];
    
    /*
    this version forget to consider bgezal/bltzal/jal/jalr command which also write register
    assign Forwarded_data_1 =
                     (Register_write_ex_mem && Write_back_address_ex_mem != 0 && 
                         Write_back_address_ex_mem == rs)
                     ? ALU_result_ex_mem
                     : (Register_write_mem_wb && Write_back_address_mem_wb != 0 &&
                           Write_back_address_ex_mem != rs && Write_back_address_mem_wb == rs)
                       ? (Memory_or_IO_mem_wb ? Read_data_mem_wb : ALU_result_mem_wb)
                       : Read_data_1;
    assign Forwarded_data_2 =
                     (Register_write_ex_mem && Write_back_address_ex_mem != 0 && 
                         Write_back_address_ex_mem == rt)
                     ? ALU_result_ex_mem
                     : (Register_write_mem_wb && Write_back_address_mem_wb != 0 &&
                           Write_back_address_ex_mem != rs && Write_back_address_mem_wb == rt)
                       ? (Memory_or_IO_mem_wb ? Read_data_mem_wb : ALU_result_mem_wb)
                       : Read_data_2;
    */
    
    //this version take those commands into consideration, but not tested
    assign Forwarded_data_1 =
                     (
                         Register_write_ex_mem && Write_back_address_ex_mem != 5'd0 && 
                         Write_back_address_ex_mem == rs && 
                         !Bgezal_ex_mem && !Bltzal_ex_mem && !Jal_ex_mem
                     )
                     ? (Jalr_ex_mem ? PC_plus_4_latch_ex_mem : ALU_result_ex_mem)
                     : (
                         Register_write_ex_mem && rs == 5'd31 &&
                         (Bgezal_ex_mem || Bltzal_ex_mem || Jal_ex_mem)
                       )
                       ? PC_plus_4_latch_ex_mem
                       : (
                           Register_write_mem_wb && Write_back_address_mem_wb != 5'd0 &&
                           Write_back_address_ex_mem != rs && Write_back_address_mem_wb == rs &&
                           !Bgezal_mem_wb && !Bltzal_mem_wb && !Jal_mem_wb
                         )
                         ? (
                             Jalr_mem_wb ? PC_plus_4_latch_mem_wb
                                         : (Memory_or_IO_mem_wb ? Read_data_mem_wb : ALU_result_mem_wb)
                           )
                         : (
                             Register_write_mem_wb && Write_back_address_mem_wb != 5'd31 && rs == 5'd31 &&
                             (Bgezal_mem_wb || Bltzal_mem_wb || Jal_mem_wb)
                           )
                           ? PC_plus_4_latch_mem_wb
                           : Read_data_1;
    assign Forwarded_data_2 =
                     (
                         Register_write_ex_mem && Write_back_address_ex_mem != 5'd0 && 
                         Write_back_address_ex_mem == rt && 
                         !Bgezal_ex_mem && !Bltzal_ex_mem && !Jal_ex_mem
                     )
                     ? (Jalr_ex_mem ? PC_plus_4_latch_ex_mem : ALU_result_ex_mem)
                     : (
                         Register_write_ex_mem && rt == 5'd31 &&
                         (Bgezal_ex_mem || Bltzal_ex_mem || Jal_ex_mem)
                       )
                       ? PC_plus_4_latch_ex_mem
                       : (
                           Register_write_mem_wb && Write_back_address_mem_wb != 5'd0 &&
                           Write_back_address_ex_mem != rt && Write_back_address_mem_wb == rt &&
                           !Bgezal_mem_wb && !Bltzal_mem_wb && !Jal_mem_wb
                         )
                         ? (
                             Jalr_mem_wb ? PC_plus_4_latch_mem_wb
                                         : (Memory_or_IO_mem_wb ? Read_data_mem_wb : ALU_result_mem_wb)
                           )
                         : (
                             Register_write_mem_wb && Write_back_address_mem_wb != 5'd31 && rt == 5'd31 &&
                             (Bgezal_mem_wb || Bltzal_mem_wb || Jal_mem_wb)
                           )
                           ? PC_plus_4_latch_mem_wb
                           : Read_data_2;
    
    assign a_input = Forwarded_data_1;
    assign b_input = ALU_src == 0 ? Forwarded_data_2 : Immediate_extend;
    
    //进行ALU_ctrl的选择
    assign exec_code = (I_type == 1'b0) ? func : {3'b000, opcode[2:0]};
    assign ALU_ctrl[0] = (exec_code[0] | exec_code[3]) & ALU_op[1];
    assign ALU_ctrl[1] = (!exec_code[2]) | (!ALU_op[1]);
    assign ALU_ctrl[2] = (exec_code[1] & ALU_op[1]) | ALU_op[0];
    
    //进行算数逻辑运算
    always @(ALU_ctrl or a_input or b_input)
    begin
        case (ALU_ctrl)
            3'b000: ALU_output = a_input & b_input;
            3'b001: ALU_output = a_input | b_input;
            3'b010: ALU_output = a_input + b_input;     //signed
            3'b011: ALU_output = a_input + b_input;     //unsigned
            3'b100: ALU_output = a_input ^ b_input;
            3'b101: ALU_output = ~(a_input | b_input);
            3'b110: ALU_output = a_input - b_input;     //signed
            3'b111: ALU_output = a_input - b_input;     //unsigned
            default:    ALU_output = 32'hZZZZZZZZ;
        endcase
    end
    
    //对于b_type指令的新PC计算
    assign PC_add_result = PC_plus_4[31:2] + Immediate_extend[31:0];
    
    //Zero标志
    assign Zero = (ALU_output == 32'h00000000) ? 1'b1 : 1'b0;
    //Positive标志
    assign Positive = (Forwarded_data_1[31] == 1'b0 &&
                       Forwarded_data_1 != 32'h00000000)
                      ? 1'b1 : 1'b0;
    //Negative标志
    assign Negative = Forwarded_data_1[31];
    
    //Overflow标志
    assign Overflow = (ALU_ctrl[1:0] != 2'b10) ? 1'b0 : //若不是有符号加减，则不产生Overflow
                          (ALU_ctrl[2] == 1'b0)
                          ? (a_input[31] == b_input[31] && a_input[31] != ALU_output[31])  //+
                          : (a_input[31] != b_input[31] && a_input[31] != ALU_output[31]); //-
    
    //对于有符号乘除法，对于两个操作数进行转化去符号
    assign signed_mul_div = (opcode == 6'b000000 && func[5:2] == 4'b0110 && func[0] == 1'b0)
                            ? 1'b1 : 1'b0;
    assign transformed_data_1 = (signed_mul_div && a_input[31])
                                 ? (~a_input) + 1 : a_input;
    assign transformed_data_2 = (signed_mul_div && b_input[31])
                                 ? (~b_input) + 1 : b_input;
    always @(*)
    begin
        inverse_mul_div_result = signed_mul_div ? a_input[31] ^ b_input[31] : 1'b0;
    end
    
    
    //无符号乘法器的实例化
    assign mul_sel = (opcode == 6'b000000 && func[5:1] == 5'b01100) ? 1'b1 : 1'b0;
    
    multu multu(
        .A(transformed_data_1),                             //data_1
        .B(transformed_data_2),                             //data_2
        .P(unsigned_mul_result)                             //result
    );
    
    //无符号除法器的实例化
    assign div_sel = (opcode == 6'b000000 && func[5:1] == 5'b01101) ? 1'b1 : 1'b0;
    assign divu_divisor_tvalid = div_sel;
    assign divu_dividend_tvalid = div_sel;
    assign Divide_zero = (div_sel && transformed_data_2 == 32'h00000000) ? 1'b1 : 1'b0;
    
    divu divu(
        .aclk(clock),                                       //[I]上升沿时钟
        .s_axis_divisor_tvalid(divu_divisor_tvalid),        //[I]除数tvalid
        .s_axis_divisor_tdata(transformed_data_2),          //[I]除数(32位)
        .s_axis_dividend_tvalid(divu_dividend_tvalid),      //[I]被除数tvalid
        .s_axis_dividend_tdata(transformed_data_1),         //[I]被除数(32位)
        .m_axis_dout_tvalid(divu_dout_tvalid),              //[O]产生结果时tvalid变1
        .m_axis_dout_tuser(divu_dout_tuser),                //[O]
        .m_axis_dout_tdata(unsigned_div_result)             //[O](32{商},32{余数})
    );
    
    //乘除运算/mt赋值结果写入HI/LO
    always @(*)
    begin
        if (Mthi)
            hi <= a_input;
        else if (Mtlo)
            lo <= a_input;
        else if (mul_sel)
        begin
            {hi,lo} <= inverse_mul_div_result
                       ? (~unsigned_mul_result) + 1
                       : unsigned_mul_result;
        end
        else if (div_sel && divu_dout_tvalid)
        begin
            hi <= inverse_mul_div_result
                  ? (~unsigned_div_result[31:0]) + 1
                  : unsigned_div_result[31:0];
            lo <= inverse_mul_div_result
                  ? (~unsigned_div_result[63:32]) + 1
                  : unsigned_div_result[63:32];
        end
    end
    
    //执行6种移位指令
    //根据之前的测试>>>并不会做算数右移，故暂采用逻辑移位组合的方式实现
    always @(*)
    begin
        if (Shift)
            case (func[2:0])
                3'b000: shift_result = b_input << shamt;    //sll
                3'b010: shift_result = b_input >> shamt;    //srl
                3'b100: shift_result = b_input << a_input;  //sllv
                3'b110: shift_result = b_input >> a_input;  //srlv
                3'b011: shift_result = (b_input >> shamt) |
                            ({32{b_input[31]}} & ~({32{1'b1}} >> shamt));   //sra
                3'b111: shift_result = (b_input >> a_input) |
                            ({32{b_input[31]}} & ~({32{1'b1}} >> a_input)); //srlv
                default:    shift_result = b_input;
            endcase
        else
            shift_result = b_input;
    end
        
    //进行各种结果的综合
    always @(*)
    begin
        //mfhi
        if (Mfhi)
            ALU_result = hi;
        //mflo
        else if (Mflo)
            ALU_result = lo;
        //lui
        else if (opcode == 6'b001111)
            ALU_result = Immediate_extend[15:0] << 16;          //也许会出事？
        //移位
        else if (Shift)
            ALU_result = shift_result;
        //slt
        else if (func[5:1] == 5'b10101 || opcode[5:1] == 5'b00101)
        begin
            if (func[5:0] == 6'b101010 || opcode[5:0] == 6'b001010) //slt/slti
                ALU_result = ALU_output[31] == 1'b1 ? 1'b1 : 1'b0;
            else                                                    //sltu/sltiu
        //  a   b   o   res
        //  0   0   0   0
        //  0   0   1   1
        //  0   1   x   1
        //  1   0   x   0
        //  1   1   0   0
        //  1   1   1   1
                ALU_result = a_input[31] == b_input[31]
                                 ? a_input[31] ^ b_input[31] ^ ALU_output[31]
                                 : b_input[31];
        end
        else
            ALU_result = ALU_output;
    end
    
    //Memory_read
    //为l_type且ALU_result高22位不全为1
    assign Memory_read = (L_type && ALU_result[31:10] != 22'h3FFFFF) ? 1'b1 : 1'b0;
    
    //Memory_write
    //为s_type且ALU_result高22位不全为1
    assign Memory_write = (S_type && ALU_result[31:10] != 22'h3FFFFF) ? 1'b1 : 1'b0;
    
    //IO_read
    //为l_type且ALU_result高22位全为1
    assign IO_read = (L_type && ALU_result[31:10] == 22'h3FFFFF) ? 1'b1 : 1'b0;
    
    //IO_write
    //为s_type且ALU_result高22位全为1
    assign IO_write = (S_type && ALU_result[31:10] == 22'h3FFFFF) ? 1'b1 : 1'b0;
    
endmodule
