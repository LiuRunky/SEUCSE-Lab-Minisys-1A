`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module WDT(
    clock,reset,
    Write_enable,Select,Write_data_in,
    WDT_output
    );

    input clock;
    input reset;
    input Write_enable;                 //д�ź�
    input Select;                       //WDTƬѡ�ź�
    input[15:0] Write_data_in;          //д��WDTģ������ݣ�ʵ���ò��ϣ�
    output      WDT_output;             //����ĸ�λ�ź�
    
    
    reg WDT_output;
    reg[15:0]   counter;                //������
    reg[2:0]    mini_cnt;               //С��������ʹ�ø�λ�źų���4��ʱ��
    
    
    //WDTģ��ʵ��
    always @(posedge clock)
    begin
        if (Select == 0 || reset == 1)
        begin
            counter = 16'hFFFF;
            mini_cnt = 3'b000;
            WDT_output = 1'b0;
        end
        else
        begin
            if (counter == 16'd0000)    //�Ѿ�������0
            begin
                counter = 16'hFFFF;
                mini_cnt = 3'b100;
                WDT_output = 1'b1;
            end
            else
                counter = counter - 1'b1;
            
            if (mini_cnt == 3'b000)
                WDT_output = 1'b0;
            else
                mini_cnt = mini_cnt - 1'b1;
            
            if (Write_enable)
            begin
                counter = 16'hFFFF;
                mini_cnt = 3'b000;
                WDT_output = 1'b0;
            end
        end
    end
endmodule
