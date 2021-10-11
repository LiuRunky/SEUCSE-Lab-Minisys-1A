`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: IF/ID流水寄存器
//////////////////////////////////////////////////////////////////////////////////

/*
最终寄存器划分：
reg[31:0]	     PC_plus_4
reg[63:32]	     PC_plus_4_latch
reg[95:64]	     Instruction
reg[100:96]	     I_type, Jmp, Jr, Jal, Jalr
reg[108:101]	 Beq, Bne, Bgez, Bgtz, Blez, Bltz, Bgezal, Bltzal
reg[109]	     Register_write
reg[114:110]	 Write_back_address
reg[115]	     Memory_or_IO
reg[121:116]	 Mfhi, Mflo, Mfc0, Mthi, Mtlo, Mtc0
reg[125:122]	 Break, Syscall, Eret, Reserved_instruction
reg[126]	     Shift
reg[128:127]	 ALU_op
reg[129]	     ALU_src
reg[130]	     Memory_sign
reg[132:131]	 Memory_data_width
reg[134:133]     L_type, S_type
*/

module IF_ID(
    clock,reset,
    
    PC_plus_4_in,PC_plus_4_latch_in,Instruction_in,
    I_type_in,Jmp_in,Jr_in,Jal_in,Jalr_in,
    Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,Bgezal_in,Bltzal_in,
    Register_write_in,Write_back_address_in,
    Memory_or_IO_in,
    Mfhi_in,Mflo_in,Mfc0_in,Mthi_in,Mtlo_in,Mtc0_in,
    Break_in,Syscall_in,Eret_in,Reserved_instruction_in,
    Shift_in,ALU_op_in,ALU_src_in,
    Memory_sign_in,Memory_data_width_in,
    L_type_in,S_type_in,

    PC_plus_4_out,PC_plus_4_latch_out,Instruction_out,
    I_type_out,Jmp_out,Jr_out,Jal_out,Jalr_out,
    Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out,
    Register_write_out,Write_back_address_out,
    Memory_or_IO_out,
    Mfhi_out,Mflo_out,Mfc0_out,Mthi_out,Mtlo_out,Mtc0_out,
    Break_out,Syscall_out,Eret_out,Reserved_instruction_out,
    Shift_out,ALU_op_out,ALU_src_out,
    Memory_sign_out,Memory_data_width_out,
    L_type_out,S_type_out
    );
    
    input   clock;
    input   reset;
    
    reg[134:0]   register;
    
    input[31:0] PC_plus_4_in;
    input[31:0] PC_plus_4_latch_in;
    input[31:0] Instruction_in;
    input       I_type_in,Jmp_in,Jr_in,Jal_in,Jalr_in;
    input       Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,Bgezal_in,Bltzal_in;
    input       Register_write_in;
    input[4:0]  Write_back_address_in;
    input       Memory_or_IO_in;
    input       Mfhi_in,Mflo_in,Mfc0_in,Mthi_in,Mtlo_in,Mtc0_in;
    input       Break_in,Syscall_in,Eret_in,Reserved_instruction_in;
    input       Shift_in;
    input[1:0]  ALU_op_in;
    input       ALU_src_in;
    input       Memory_sign_in;
    input[1:0]  Memory_data_width_in;
    input       L_type_in,S_type_in;
    
    output[31:0] PC_plus_4_out;
    output[31:0] PC_plus_4_latch_out;
    output[31:0] Instruction_out;
    output       I_type_out,Jmp_out,Jr_out,Jal_out,Jalr_out;
    output       Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out;
    output       Register_write_out;
    output[4:0]  Write_back_address_out;
    output       Memory_or_IO_out;
    output       Mfhi_out,Mflo_out,Mfc0_out,Mthi_out,Mtlo_out,Mtc0_out;
    output       Break_out,Syscall_out,Eret_out,Reserved_instruction_out;
    output       Shift_out;
    output[1:0]  ALU_op_out;
    output       ALU_src_out;
    output       Memory_sign_out;
    output[1:0]  Memory_data_width_out;
    output       L_type_out,S_type_out;



    assign PC_plus_4_out = register[31:0];
    assign PC_plus_4_latch_out = register[63:32];
    assign Instruction_out = register[95:64];
    assign {I_type_out,Jmp_out,Jr_out,Jal_out,Jalr_out} = register[100:96];
    assign {Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out}
            = register[108:101];
    assign Register_write_out = register[109];
    assign Write_back_address_out = register[114:110];
    assign Memory_or_IO_out = register[115];
    assign {Mfhi_out,Mflo_out,Mfc0_out,Mthi_out,Mtlo_out,Mtc0_out} = register[121:116];
    assign {Break_out,Syscall_out,Eret_out,Reserved_instruction_out} = register[125:122];
    assign {ALU_src_out,ALU_op_out,Shift_out} = register[129:126];
    assign {Memory_data_width_out,Memory_sign_out} = register[132:130];
    assign {L_type_out,S_type_out} = register[134:133];
    
    always @(negedge clock)
    begin
        if (reset)
            register <= 135'h00_0000_0000_0000_0000_0000_0000_0000_0000;
        else
        begin
            register[31:0] <= PC_plus_4_in;
            register[63:32] <= PC_plus_4_latch_in;
            register[95:64] <= Instruction_in;
            register[100:96] <= {I_type_in,Jmp_in,Jr_in,Jal_in,Jalr_in};
            register[108:101] <= {Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,
                    Bgezal_in,Bltzal_in};
            register[109] <= Register_write_in;
            register[114:110] <= Write_back_address_in;
            register[115] <= Memory_or_IO_in;
            register[121:116] <= {Mfhi_in,Mflo_in,Mfc0_in,Mthi_in,Mtlo_in,Mtc0_in};
            register[125:122] <= {Break_in,Syscall_in,Eret_in,Reserved_instruction_in};
            register[129:126] <= {ALU_src_in,ALU_op_in,Shift_in};
            register[132:130] <= {Memory_data_width_in,Memory_sign_in};
            register[134:133] <= {L_type_in,S_type_in};
        end
    end
    
endmodule
