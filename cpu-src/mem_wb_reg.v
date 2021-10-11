`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: MEM/WB流水寄存器
//////////////////////////////////////////////////////////////////////////////////

/*
最终寄存器划分：
reg[31:0]	    PC_plus_4_latch
reg[63:32]	    CP0_data
reg[95:64]	    ALU_result
reg[127:96]	    Memory_or_IO_read_data
reg[129:128]	Jal, Jalr
reg[131:130]	Bgezal, Bltzal
reg[134:132]	Zero, Positive, Negative
reg[135]	    Register_write
reg[140:136]    Write_back_address
*/

module MEM_WB(
    clock,reset,
    
    PC_plus_4_latch_in,CP0_data_in,
    ALU_result_in,
    Memory_or_IO_read_data_in,
    Jal_in,Jalr_in,
    Bgezal_in,Bltzal_in,
    Memory_or_IO_in,
    Zero_in,Positive_in,Negative_in,
    Register_write_in,Write_back_address_in,
    
    PC_plus_4_latch_out,CP0_data_out,
    ALU_result_out,
    Memory_or_IO_read_data_out,
    Jal_out,Jalr_out,
    Bgezal_out,Bltzal_out,
    Memory_or_IO_out,
    Zero_out,Positive_out,Negative_out,
    Register_write_out,Write_back_address_out
    );
    
    input   clock;
    input   reset;
    
    reg[141:0]  register;
    
    input[31:0] PC_plus_4_latch_in;
    input[31:0] CP0_data_in;
    input[31:0] ALU_result_in;
    input[31:0] Memory_or_IO_read_data_in;
    input       Jal_in,Jalr_in;
    input       Bgezal_in,Bltzal_in;
    input       Memory_or_IO_in;
    input       Zero_in,Positive_in,Negative_in;
    input       Register_write_in;
    input[4:0]  Write_back_address_in;
    
    output[31:0] PC_plus_4_latch_out;
    output[31:0] CP0_data_out;
    output[31:0] ALU_result_out;
    output[31:0] Memory_or_IO_read_data_out;
    output       Jal_out,Jalr_out;
    output       Bgezal_out,Bltzal_out;
    output       Memory_or_IO_out;
    output       Zero_out,Positive_out,Negative_out;
    output       Register_write_out;
    output[4:0]  Write_back_address_out;
    
    
    
    assign PC_plus_4_latch_out = register[31:0];
    assign CP0_data_out = register[63:32];
    assign ALU_result_out = register[95:64];
    assign Memory_or_IO_read_data_out = register[127:96];
    assign {Jal_out,Jalr_out} = register[129:128];
    assign {Bgezal_out,Bltzal_out} = register[131:130];
    assign Memory_or_IO_out = register[132];
    assign {Zero_out,Positive_out,Negative_out} = register[135:133];
    assign Register_write_out = register[136];
    assign Write_back_address_out = register[141:137];
    
    always @(negedge clock)
    begin
        if (reset)
            register <= 142'h0000_0000_0000_0000_0000_FFFF_FFFF_0000_0000;
        else
        begin
            register[31:0] <= PC_plus_4_latch_in;
            register[63:32] <= CP0_data_in;
            register[95:64] <= ALU_result_in;
            register[127:96] <= Memory_or_IO_read_data_in;
            register[129:128] <= {Jal_in,Jalr_in};
            register[131:130] <= {Bgezal_in,Bltzal_in};
            register[132] <= Memory_or_IO_in;
            register[135:133] <= {Zero_in,Positive_in,Negative_in};
            register[136] <= Register_write_in;
            register[141:137] <= Write_back_address_in;
        end
    end
    
endmodule
