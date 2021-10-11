`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: EX/MEMÁ÷Ë®¼Ä´æÆ÷
//////////////////////////////////////////////////////////////////////////////////

/*
reg[31:0]	    PC_add_result
reg[63:32]	    PC_plus_4_latch
reg[95:64]	    PC_exception
reg[127:96]	    CP0_data
reg[159:128]	Instruction
reg[191:160]	ALU_result
reg[223:192]	Read_data_rs
reg[255:224]	Memory_or_IO_write_data
reg[259:256]	Jmp, Jr, Jal, Jalr
reg[267:260]	Beq, Bne, Bgez, Bgtz, Blez, Bltz, Bgezal, Bltzal
reg[270:268]	Zero, Positive, Negative
reg[271]	    Register_write
reg[276:272]    Write_back_address
reg[281:277]	Memory_or_IO, Memory_read, Memory_write, IO_read, IO_write
reg[282]	    Memory_sign
reg[284:283]	Memory_data_width
*/

module EX_MEM(
    clock,reset,
    
    PC_add_result_in,PC_plus_4_latch_in,
    PC_exception_in,CP0_data_in,
    Instruction_in,ALU_result_in,
    Read_data_rs_in,Memory_or_IO_write_data_in,
    Jmp_in,Jr_in,Jal_in,Jalr_in,
    Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,Bgezal_in,Bltzal_in,
    Zero_in,Positive_in,Negative_in,
    Register_write_in,Write_back_address_in,
    Memory_or_IO_in,Memory_read_in,Memory_write_in,IO_read_in,IO_write_in,
    Memory_sign_in,Memory_data_width_in,
 
    PC_add_result_out,PC_plus_4_latch_out,
    PC_exception_out,CP0_data_out,
    Instruction_out,ALU_result_out,
    Read_data_rs_out,Memory_or_IO_write_data_out,
    Jmp_out,Jr_out,Jal_out,Jalr_out,
    Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out,
    Zero_out,Positive_out,Negative_out,
    Register_write_out,Write_back_address_out,
    Memory_or_IO_out,Memory_read_out,Memory_write_out,IO_read_out,IO_write_out,
    Memory_sign_out,Memory_data_width_out
    );
    
    input   clock;
    input   reset;
    
    reg[284:0]  register;
    
    input[31:0] PC_add_result_in;
    input[31:0] PC_plus_4_latch_in;
    input[31:0] PC_exception_in;
    input[31:0] CP0_data_in;
    input[31:0] Instruction_in;
    input[31:0] ALU_result_in;
    input[31:0] Read_data_rs_in;
    input[31:0] Memory_or_IO_write_data_in;
    input       Jmp_in,Jr_in,Jal_in,Jalr_in;
    input       Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,Bgezal_in,Bltzal_in;
    input       Zero_in,Positive_in,Negative_in;
    input       Register_write_in;
    input[4:0]  Write_back_address_in;
    input       Memory_or_IO_in,Memory_read_in,Memory_write_in,IO_read_in,IO_write_in;
    input       Memory_sign_in;
    input[1:0]  Memory_data_width_in;

    output[31:0] PC_add_result_out;
    output[31:0] PC_plus_4_latch_out;
    output[31:0] PC_exception_out;
    output[31:0] CP0_data_out;
    output[31:0] Instruction_out;
    output[31:0] ALU_result_out;
    output[31:0] Read_data_rs_out;
    output[31:0] Memory_or_IO_write_data_out;
    output       Jmp_out,Jr_out,Jal_out,Jalr_out;
    output       Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out;
    output       Zero_out,Positive_out,Negative_out;
    output       Register_write_out;
    output[4:0]  Write_back_address_out;
    output       Memory_or_IO_out,Memory_read_out,Memory_write_out,IO_read_out,IO_write_out;
    output       Memory_sign_out;
    output[1:0]  Memory_data_width_out;
    
    
    
    assign PC_add_result_out = register[31:0];
    assign PC_plus_4_latch_out = register[63:32];
    assign PC_exception_out = register[95:64];
    assign CP0_data_out = register[127:96];
    assign Instruction_out = register[159:128];
    assign ALU_result_out = register[191:160];
    assign Read_data_rs_out = register[223:192];
    assign Memory_or_IO_write_data_out = register[255:224];
    assign {Jmp_out,Jr_out,Jal_out,Jalr_out} = register[259:256];
    assign {Beq_out,Bne_out,Bgez_out,Bgtz_out,Blez_out,Bltz_out,Bgezal_out,Bltzal_out}
            = register[267:260];
    assign {Zero_out,Positive_out,Negative_out} = register[270:268];
    assign Register_write_out = register[271];
    assign Write_back_address_out = register[276:272];
    assign {Memory_or_IO_out,Memory_read_out,Memory_write_out,IO_read_out,IO_write_out}
            = register[281:277];
    assign {Memory_data_width_out,Memory_sign_out} = register[284:282];
    
    always @(negedge clock,posedge reset)
    begin
        if (reset)
            register <= 285'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_FFFF_FFFF_FFFF_FFFF_0000_0000_0000_0000;
        else
        begin
            register[31:0] <= PC_add_result_in;
            register[63:32] <= PC_plus_4_latch_in;
            register[95:64] <= PC_exception_in;
            register[127:96] <= CP0_data_in;
            register[159:128] <= Instruction_in;
            register[191:160] <= ALU_result_in;
            register[223:192] <= Read_data_rs_in;
            register[255:224] <= Memory_or_IO_write_data_in;
            register[259:256] <= {Jmp_in,Jr_in,Jal_in,Jalr_in};
            register[267:260] <= {Beq_in,Bne_in,Bgez_in,Bgtz_in,Blez_in,Bltz_in,
                    Bgezal_in,Bltzal_in};
            register[270:268] <= {Zero_in,Positive_in,Negative_in};
            register[271] <= Register_write_in;
            register[276:272] <= Write_back_address_in;
            register[281:277] <= {Memory_or_IO_in,Memory_read_in,Memory_write_in,
                    IO_read_in,IO_write_in};
            register[284:282] <= {Memory_data_width_in,Memory_sign_in};
        end
    end
    
endmodule
