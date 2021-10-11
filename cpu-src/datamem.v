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
    input[31:0] Write_data;                                 //д��RAM������
    output[31:0]    Read_data;                              //��RAM����������
    
    wire clk;
    assign clk = !clock;                                    //Ϊ�˽��ʱ���ӳ�����
    
    //64KB RAM
    ram ram(
        .clka(clk),
        .wea(Memory_write),
        .addra(Address[15:2]),
        .dina(Write_data),
        .douta(Read_data)
    );
    
endmodule