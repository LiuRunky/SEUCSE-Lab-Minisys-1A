`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


//counter in [0,threshold] ���1
//counter in [threshold+1,maximum] ���0
//��ֹ����ʱ ���1
module PWM(
    clock,reset,
    Write_enable,Select,Address,Write_data_in,
    PWM_output);
    
    input clock;
    input reset;
    input Write_enable;                 //д�ź�
    input Select;                       //PWMƬѡ�ź�
    input[2:0]  Address;                //��PWMģ��ĵ�ַ�Ͷˣ��˴�Ϊ30 or 32 or 34��
    
    input[15:0] Write_data_in;          //д��PWMģ�������
    output  PWM_output;
    
    
    reg PWM_output;
    reg[15:0]   maximum;                //���ֵ�Ĵ���
    reg[15:0]   threshold;              //�Ա�ֵ�Ĵ���
    reg[15:0]   counter;                //������
    reg[15:0]   flag;                   //ʹ�ܼĴ���
    
    
    always @(posedge clock)
    begin
        if (Select == 0 || reset == 1)
        begin
            maximum = 16'hFFFF;
            threshold = 16'h7FFF;
            counter = 16'h0000;
            flag = 16'h0000;
            PWM_output = 1'b1;
        end
        else if (Write_enable)
        begin
            case (Address)
                3'b000: maximum = Write_data_in;
                3'b010: threshold = Write_data_in;
                3'b100: flag = Write_data_in;
            endcase
        end
        else if (flag[0] == 1)          //�������
        begin
            if (counter >= maximum)
            begin
                counter = 16'h0000;
                PWM_output = 1'b1;
            end
            else
            begin
                counter = counter + 1'b1;
                if (counter > threshold)
                    PWM_output = 1'b0;
                else
                    PWM_output = 1'b1;
            end
        end
    end
endmodule