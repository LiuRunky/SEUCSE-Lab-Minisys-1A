`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: RAM
//////////////////////////////////////////////////////////////////////////////////


module DataMEM(
    clock,
    Memory_write,Address,Read_data,Write_data
    );
    
    input       clock;
    input       Memory_write;
    input[31:0] Address;
    input[31:0] Write_data;                                 //写进RAM的数据
    output[31:0]    Read_data;                              //从RAM读出的数据
    
    wire clk;
    assign clk = !clock;                                    //为了解决时钟延迟问题
    
    //64KB RAM
    ram ram(
        .clka(clk),
        .wea(Memory_write),
        .addra(Address[15:2]),
        .dina(Write_data),
        .douta(Read_data)
    );
    
endmodule