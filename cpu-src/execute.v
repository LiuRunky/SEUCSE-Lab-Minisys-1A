`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ִ�е�Ԫ
// Function:    1. �Ӽ����߼����㣬����ZeroFlag
//              2. �˷���(������ˮ����)
//              3. ������(�����Ƿ�����)
//              4. ������λ
//
//Notes:        1. �������Ϊ��ʱ���Ƕ��̺�����ͬʱȡ����
//              2. inverse_mul_div�Ĵ�������������
//              3. �з��żӷ�����Overflow�󣬻���������ݴ���Ĵ���
//              4. ����beq/bne�����b-type�жϲ���execute�н���
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
    
    input       ALU_src;                        //ѡ��ALU������2(0�Ĵ���/1������)
    input[1:0]  ALU_op;                         //ѡ��ALU���е���������
    input       Shift;                          //�Ƿ���λ����
    input       I_type;                         //�Ƿ�ΪIָ��
    input[31:0] Read_data_1;                    //rs
    input[31:0] Read_data_2;                    //rt
    input[31:0] Immediate_extend;               //imme
    input[31:0] PC_plus_4;                      //PC+4��ֵ�����κδ���
    
    output[31:0]    ALU_result;                 //ALU������
    output[31:0]    PC_add_result;              //����PC+4+(imme<<2)�����������ѳ���4��
    output          Zero;                       //����Ƿ�Ϊ0
    output          Positive;                   //rs�Ƿ�Ϊ��
    output          Negative;                   //rs�Ƿ�Ϊ��
    output          Overflow;                   //�Ƿ�����Ӽ������
    output          Divide_zero;                //�Ƿ��0
    
    input       Mfhi,Mflo,Mthi,Mtlo;            //�Ƿ�Ϊ��дHI/LO�Ĵ�����ָ��
    
    input       L_type,S_type;
    output      Memory_read,Memory_write,IO_read,IO_write;
    
    //��������ת��
    input       Register_write_ex_mem,Register_write_mem_wb,Memory_or_IO_mem_wb;
    input[4:0]  Write_back_address_ex_mem,Write_back_address_mem_wb;
    input[31:0] ALU_result_ex_mem,ALU_result_mem_wb,Read_data_mem_wb;
    
    output[31:0]    Forwarded_data_1,Forwarded_data_2;
    
    
    
    wire[31:0]  Forwarded_data_1,Forwarded_data_2;  //������ˮ������ת�����read_data_1/2
    wire[31:0]  a_input,b_input;
    wire[5:0]   opcode;
    wire[4:0]   rs,rt;
    wire[4:0]   shamt;
    wire[5:0]   func;
    
    wire[6:0]   exec_code;                      //��������ALU_ctrl
    wire[2:0]   ALU_ctrl;                       //���ڽ���ALU�������߼�����ѡ��
    
    wire        signed_mul_div;                 //�Ƿ�Ϊ�з��ų˳���
    wire[31:0]  transformed_data_1,transformed_data_2;  //תΪ������a/b_input
    
    wire        mul_sel;                        //�Ƿ�Ϊ�˷�
    wire        div_sel;                        //�Ƿ�Ϊ����
    wire[63:0]  unsigned_mul_result;
    wire        divu_divisor_tvalid;
    wire        divu_dividend_tvalid;
    wire        divu_dout_tvalid;
    wire        divu_dout_tuser;
    wire[63:0]  unsigned_div_result;
    
    reg         inverse_mul_div_result;         //����ԭ����λ��ȷ���Ƿ���Ҫ��ת���
    reg[31:0]   ALU_output;                     //�����߼�������
    reg[31:0]   shift_result;                   //��λ������
    reg[31:0]   hi,lo;
    reg[31:0]   ALU_result;                     //����������
    
    
    
    assign opcode = Instruction[31:26];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    assign shamt = Instruction[10:6];
    assign func = Instruction[5:0];
    
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
    
    assign a_input = Forwarded_data_1;
    assign b_input = ALU_src == 0 ? Forwarded_data_2 : Immediate_extend;
    
    //����ALU_ctrl��ѡ��
    assign exec_code = (I_type == 1'b0) ? func : {3'b000, opcode[2:0]};
    assign ALU_ctrl[0] = (exec_code[0] | exec_code[3]) & ALU_op[1];
    assign ALU_ctrl[1] = (!exec_code[2]) | (!ALU_op[1]);
    assign ALU_ctrl[2] = (exec_code[1] & ALU_op[1]) | ALU_op[0];
    
    //���������߼�����
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
    
    //����b_typeָ�����PC����
    assign PC_add_result = PC_plus_4[31:2] + Immediate_extend[31:0];
    
    //Zero��־
    assign Zero = (ALU_output == 32'h00000000) ? 1'b1 : 1'b0;
    //Positive��־
    assign Positive = (Forwarded_data_1[31] == 1'b0 &&
                       Forwarded_data_1 != 32'h00000000)
                      ? 1'b1 : 1'b0;
    //Negative��־
    assign Negative = Forwarded_data_1[31];
    
    //Overflow��־
    assign Overflow = (ALU_ctrl[1:0] != 2'b10) ? 1'b0 : //�������з��żӼ����򲻲���Overflow
                          (ALU_ctrl[2] == 1'b0)
                          ? (a_input[31] == b_input[31] && a_input[31] != ALU_output[31])  //+
                          : (a_input[31] != b_input[31] && a_input[31] != ALU_output[31]); //-
    
    //�����з��ų˳�����������������������ת��ȥ����
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
    
    
    //�޷��ų˷�����ʵ����
    assign mul_sel = (opcode == 6'b000000 && func[5:1] == 5'b01100) ? 1'b1 : 1'b0;
    
    multu multu(
        .A(transformed_data_1),                             //data_1
        .B(transformed_data_2),                             //data_2
        .P(unsigned_mul_result)                             //result
    );
    
    //�޷��ų�������ʵ����
    assign div_sel = (opcode == 6'b000000 && func[5:1] == 5'b01101) ? 1'b1 : 1'b0;
    assign divu_divisor_tvalid = div_sel;
    assign divu_dividend_tvalid = div_sel;
    assign Divide_zero = (div_sel && transformed_data_2 == 32'h00000000) ? 1'b1 : 1'b0;
    
    divu divu(
        .aclk(clock),                                       //[I]������ʱ��
        .s_axis_divisor_tvalid(divu_divisor_tvalid),        //[I]����tvalid
        .s_axis_divisor_tdata(transformed_data_2),          //[I]����(32λ)
        .s_axis_dividend_tvalid(divu_dividend_tvalid),      //[I]������tvalid
        .s_axis_dividend_tdata(transformed_data_1),         //[I]������(32λ)
        .m_axis_dout_tvalid(divu_dout_tvalid),              //[O]�������ʱtvalid��1
        .m_axis_dout_tuser(divu_dout_tuser),                //[O]
        .m_axis_dout_tdata(unsigned_div_result)             //[O](32{��},32{����})
    );
    
    //�˳�����/mt��ֵ���д��HI/LO
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
    
    //ִ��6����λָ��
    //����֮ǰ�Ĳ���>>>���������������ƣ����ݲ����߼���λ��ϵķ�ʽʵ��
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
        
    //���и��ֽ�����ۺ�
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
            ALU_result = Immediate_extend[15:0] << 16;          //Ҳ�����£�
        //��λ
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
    //Ϊl_type��ALU_result��22λ��ȫΪ1
    assign Memory_read = (L_type && ALU_result[31:10] != 22'h3FFFFF) ? 1'b1 : 1'b0;
    
    //Memory_write
    //Ϊs_type��ALU_result��22λ��ȫΪ1
    assign Memory_write = (S_type && ALU_result[31:10] != 22'h3FFFFF) ? 1'b1 : 1'b0;
    
    //IO_read
    //Ϊl_type��ALU_result��22λȫΪ1
    assign IO_read = (L_type && ALU_result[31:10] == 22'h3FFFFF) ? 1'b1 : 1'b0;
    
    //IO_write
    //Ϊs_type��ALU_result��22λȫΪ1
    assign IO_write = (S_type && ALU_result[31:10] == 22'h3FFFFF) ? 1'b1 : 1'b0;
    
endmodule