`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: 指令寄存器单元
// Function:    1. 处理指令寄存器的读写控制
//////////////////////////////////////////////////////////////////////////////////


module InstMEM(
    Rom_clk_i,Rom_adr_i,Jpadr,
    Upg_rst_i,Upg_clk_i,Upg_wen_i,Upg_adr_i,Upg_dat_i,Upg_done_i
    );
    
    //指令寄存器引脚
    input       Rom_clk_i;                                  //ROM时钟(clk1)
    input[13:0] Rom_adr_i;                                  //从ifetch来的PC
    output[31:0]    Jpadr;                                  //取出的指令，传给ifetch
    
    //UART编程器引脚
    input       Upg_rst_i;                                  //UPG reset(高为active)
    input       Upg_clk_i;                                  //UPG时钟(clk2)
    input       Upg_wen_i;                                  //UPG写使能
    input[13:0] Upg_adr_i;                                  //UPG写地址
    input[31:0] Upg_dat_i;                                  //UPG写数据
    input       Upg_done_i;                                 //当传输完成后为高
    
    wire kickoff;                                          //表示CPU正常工作(=1)或串口下载程序(=0)
    
    
    assign kickoff = Upg_rst_i | ((~Upg_rst_i) & Upg_done_i);
    
    //分配64KB ROM
    programrom programrom(
        .clka(kickoff ? Rom_clk_i : Upg_clk_i),
        .wea(kickoff ? 1'b0 : Upg_wen_i),
        .addra(kickoff ? Rom_adr_i : Upg_adr_i),
        .dina(kickoff ? 32'h00000000 : Upg_dat_i),
        .douta(Jpadr)
    );
    
endmodule