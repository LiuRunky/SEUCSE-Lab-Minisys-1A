`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ָ��Ĵ�����Ԫ
// Function:    1. ����ָ��Ĵ����Ķ�д����
//////////////////////////////////////////////////////////////////////////////////


module InstMEM(
    Rom_clk_i,Rom_adr_i,Jpadr,
    Upg_rst_i,Upg_clk_i,Upg_wen_i,Upg_adr_i,Upg_dat_i,Upg_done_i
    );
    
    //ָ��Ĵ�������
    input       Rom_clk_i;                                  //ROMʱ��(clk1)
    input[13:0] Rom_adr_i;                                  //��ifetch����PC
    output[31:0]    Jpadr;                                  //ȡ����ָ�����ifetch
    
    //UART���������
    input       Upg_rst_i;                                  //UPG reset(��Ϊactive)
    input       Upg_clk_i;                                  //UPGʱ��(clk2)
    input       Upg_wen_i;                                  //UPGдʹ��
    input[13:0] Upg_adr_i;                                  //UPGд��ַ
    input[31:0] Upg_dat_i;                                  //UPGд����
    input       Upg_done_i;                                 //��������ɺ�Ϊ��
    
    wire kickoff;                                          //��ʾCPU��������(=1)�򴮿����س���(=0)
    
    
    assign kickoff = Upg_rst_i | ((~Upg_rst_i) & Upg_done_i);
    
    //����64KB ROM
    programrom programrom(
        .clka(kickoff ? Rom_clk_i : Upg_clk_i),
        .wea(kickoff ? 1'b0 : Upg_wen_i),
        .addra(kickoff ? Rom_adr_i : Upg_adr_i),
        .dina(kickoff ? 32'h00000000 : Upg_dat_i),
        .douta(Jpadr)
    );
    
endmodule