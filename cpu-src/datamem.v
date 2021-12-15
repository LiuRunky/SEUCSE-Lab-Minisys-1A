`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: RAM
//////////////////////////////////////////////////////////////////////////////////


module DataMEM(
    clock,
    Memory_write,Address,Read_data,Write_data,
    Upg_rst_i,Upg_clk_i,Upg_wen_i,Upg_adr_i,Upg_dat_i,Upg_done_i
    );
    
    input       clock;
    input       Memory_write;
    input[31:0] Address;
    input[31:0] Write_data;                                 //写进RAM的数据
    output[31:0]    Read_data;                              //从RAM读出的数据
    
    //UART编程器引脚
    input       Upg_rst_i;                                  //UPG reset(高为active)
    input       Upg_clk_i;                                  //UPG时钟(clk2)
    input       Upg_wen_i;                                  //UPG写使能
    input[13:0] Upg_adr_i;                                  //UPG写地址
    input[31:0] Upg_dat_i;                                  //UPG写数据
    input       Upg_done_i;                                 //当传输完成后为高
    
    wire clk;
    assign clk = clock/*!clock*/;                                    //为了解决时钟延迟问题
    
    wire kickoff = Upg_rst_i | ((~Upg_rst_i) & Upg_done_i);
    
    //64KB RAM
    ram ram(
        .clka(kickoff ? clk : Upg_clk_i),
        .wea(kickoff ? Memory_write : Upg_wen_i),
        .addra(kickoff ? Address[15:2] : Upg_adr_i),
        .dina(kickoff ? Write_data : Upg_dat_i),
        .douta(Read_data)
    );
    
endmodule
