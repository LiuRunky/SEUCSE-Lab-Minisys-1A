`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module Switch(
    clock,reset,
    Read_enable,Select,Address,Read_data_in,Read_data_out
    );
    
    input clock;
    input reset;                        //��λ�ź�
    input Read_enable;                  //д�ź�
    input Select;                       //SwitchƬѡ�ź�
    input[1:0]  Address;                //��Switchģ��ĵ�ַ�Ͷˣ��˴�Ϊ70 or 72��
    input[23:0] Read_data_in;           //�Ӱ��Ӷ���24λ���뿪������
    output[15:0]    Read_data_out;      //�͵�CPU�Ĳ��뿪��ֵ
    
    reg[15:0]   Read_data_out;
    
    
    //Switch����ʵ��
    always @(posedge clock or posedge reset)
    begin
        if (Select == 0 || reset == 1)
            Read_data_out = 16'h0000;
        else
            if (Read_enable)
                case (Address)
                    2'b00: Read_data_out = Read_data_in[15:0];
                    2'b10: Read_data_out = {8'h00, Read_data_in[23:16]};
                    default: Read_data_out = 16'hZZZZ;
                endcase
    end
endmodule
