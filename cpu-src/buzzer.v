`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module Buzzer(
    clock,reset,
    Write_enable,Select,Address,Write_data_in,
    Buzzer_output
    );
    
    input clock;
    input reset;
    input Write_enable;                 //д�ź�
    input Select;                       //BuzzerƬѡ�ź�
    input[1:0]  Address;                //��Buzzerģ��ĵ�ַ�Ͷˣ��˴�Ϊ40 or 42��
    input[15:0] Write_data_in;          //д��Buzzerģ������ݣ�ʵ���ò��ϣ�
    output      Buzzer_output;          //����ķ������ź�
    
    
    reg     Buzzer_output;
    reg     status;                     //���ƿ���
    reg[15:0]   maximum;                //ʵ��������һ����ʱ��
    reg[15:0]   counter;
    
    
    //Buzzerģ��ʵ��
    always @(posedge clock)
    begin
        if (Select == 0 || reset == 1)
        begin
            status = 1'b0;
            maximum = 16'hFFFF;
            counter = 16'h0000;
            Buzzer_output = 1'b0;
        end
        else
            if (Write_enable)
                case (Address)
                    2'b00:
                    begin
                        maximum = Write_data_in;
                        counter = 16'h0000;
                    end
                    2'b10: status = Write_data_in[0];
                    default: status = 1'b0;
                endcase
        
        if (status == 1'b1)
        begin
            if (counter == maximum)
            begin
                counter = 1'b0;
                Buzzer_output = ~Buzzer_output;
            end
            counter = counter + 1'b1;
        end
    end
endmodule
