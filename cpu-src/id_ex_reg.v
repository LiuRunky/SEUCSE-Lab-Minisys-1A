`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ID/EX流水寄存器
//////////////////////////////////////////////////////////////////////////////////

/*
最终寄存器划分：
reg[31:0]	    PC_plus_4
reg[63:32]	    PC_plus_4_latch
reg[95:64]	    PC_exception
reg[127:96]	    CP0_data
reg[159:128]	Instruction
reg[191:160]	Read_data_1
reg[223:192]	Read_data_2
reg[255:224]	Immediate_extend
reg[260:256]	I_type, Jmp, Jr, Jal, Jalr
reg[268:261]	Beq, Bne, Bgez, Bgtz, Blez, Bltz, Bgezal, Bltzal
reg[269]	    Register_write
reg[274:270]	Write_back_address
reg[275]	    Memory_or_IO
reg[279:276]	Mfhi, Mflo, Mthi, Mtlo
reg[280]	    Shift
reg[282:281]	ALU_op
reg[283]	    ALU_src
reg[284]	    Memory_sign
reg[286:285]	Memory_data_width
reg[288:287]    L_type, S_type
reg[289]        Nonflush
*/

module ID_EX(
    clock,reset,
    
    PC_plus_4_in,PC_plus_4_latch_in,
    PC_exception_in,CP0_data_in,
    Instruction_in,
    Read_data_1_in,Read_data_2_in,Immediate_extend_in,
    I_type_in,Jmp_in,Jr_in,Jal_in,Jalr_in,
    Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,Bgezal_in,Bltzal_in,
    Register_write_in,Write_back_address_in,
    Memory_or_IO_in,
    Mfhi_in,Mflo_in,Mthi_in,Mtlo_in,
    Shift_in,ALU_op_in,ALU_src_in,
    Memory_sign_in,Memory_data_width_in,
    L_type_in,S_type_in,
    Nonflush_in,

    PC_plus_4_out,PC_plus_4_latch_out,
    PC_exception_out,CP0_data_out,
    Instruction_out,
    Read_data_1_out,Read_data_2_out,Immediate_extend_out,
    I_type_out,Jmp_out,Jr_out,Jal_out,Jalr_out,
    Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out,
    Register_write_out,Write_back_address_out,
    Memory_or_IO_out,
    Mfhi_out,Mflo_out,Mthi_out,Mtlo_out,
    Shift_out,ALU_op_out,ALU_src_out,
    Memory_sign_out,Memory_data_width_out,
    L_type_out,S_type_out,
    Nonflush_out
    );
    
    input   clock;
    input   reset;
    
    reg[289:0]  register;
    
    input[31:0] PC_plus_4_in;
    input[31:0] PC_plus_4_latch_in;
    input[31:0] PC_exception_in;
    input[31:0] CP0_data_in;
    input[31:0] Instruction_in;
    input[31:0] Read_data_1_in;
    input[31:0] Read_data_2_in;
    input[31:0] Immediate_extend_in;
    input       I_type_in,Jmp_in,Jr_in,Jal_in,Jalr_in;
    input       Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,Bgezal_in,Bltzal_in;
    input       Register_write_in;
    input[4:0]  Write_back_address_in;
    input       Memory_or_IO_in;
    input       Mfhi_in,Mflo_in,Mthi_in,Mtlo_in;
    input       Shift_in;
    input[1:0]  ALU_op_in;
    input       ALU_src_in;
    input       Memory_sign_in;
    input[1:0]  Memory_data_width_in;
    input       L_type_in,S_type_in;
    input      Nonflush_in;

    output[31:0] PC_plus_4_out;
    output[31:0] PC_plus_4_latch_out;
    output[31:0] PC_exception_out;
    output[31:0] CP0_data_out;
    output[31:0] Instruction_out;
    output[31:0] Read_data_1_out;
    output[31:0] Read_data_2_out;
    output[31:0] Immediate_extend_out;
    output       I_type_out,Jmp_out,Jr_out,Jal_out,Jalr_out;
    output       Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out;
    output       Register_write_out;
    output[4:0]  Write_back_address_out;
    output       Memory_or_IO_out;
    output       Mfhi_out,Mflo_out,Mthi_out,Mtlo_out;
    output       Shift_out;
    output[1:0]  ALU_op_out;
    output       ALU_src_out;
    output       Memory_sign_out;
    output[1:0]  Memory_data_width_out;
    output       L_type_out,S_type_out;
    output       Nonflush_out;
    
    
    assign PC_plus_4_out = register[31:0];
    assign PC_plus_4_latch_out = register[63:32];
    assign PC_exception_out = register[95:64];
    assign CP0_data_out = register[127:96];
    assign Instruction_out = register[159:128];
    assign Read_data_1_out = register[191:160];
    assign Read_data_2_out = register[223:192];
    assign Immediate_extend_out = register[255:224];
    assign {I_type_out,Jmp_out,Jr_out,Jal_out,Jalr_out} = register[260:256];
    assign {Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out}
            = register[268:261];
    assign Register_write_out = register[269];
    assign Write_back_address_out = register[274:270];
    assign Memory_or_IO_out = register[275];
    assign {Mfhi_out,Mflo_out,Mthi_out,Mtlo_out} = register[279:276];
    assign {ALU_src_out,ALU_op_out,Shift_out} = register[283:280];
    assign {Memory_data_width_out,Memory_sign_out} = register[286:284];
    assign {L_type_out,S_type_out} = register[288:287];
    assign Nonflush_out = register[289];

    always @(negedge clock)
    begin
        if (reset)
            register <= 290'h0_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_FFFF_FFFF_FFFF_FFFF_0000_0000_0000_0000;
        else
        begin
            register[31:0] <= PC_plus_4_in;
            register[63:32] <= PC_plus_4_latch_in;
            register[95:64] <= PC_exception_in;
            register[127:96] <= CP0_data_in;
            register[159:128] <= Instruction_in;
            register[191:160] <= Read_data_1_in;
            register[223:192] <= Read_data_2_in;
            register[255:224] <= Immediate_extend_in;
            register[260:256] <= {I_type_in,Jmp_in,Jr_in,Jal_in,Jalr_in};
            register[268:261] <= {Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,
                    Bgezal_in,Bltzal_in};
            register[269] <= Register_write_in;
            register[274:270] <= Write_back_address_in;
            register[275] <= Memory_or_IO_in;
            register[279:276] <= {Mfhi_in,Mflo_in,Mthi_in,Mtlo_in};
            register[283:280] <= {ALU_src_in,ALU_op_in,Shift_in};
            register[286:284] <= {Memory_data_width_in,Memory_sign_in};
            register[288:287] <= {L_type_in,S_type_in};
            register[289] <= Nonflush_in;
        end
    end
    
endmodule
