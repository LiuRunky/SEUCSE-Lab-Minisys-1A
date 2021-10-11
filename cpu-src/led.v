`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module LED(
    clock,reset,
    Write_enable,Select,Address,Write_data_in,Write_data_out
    );
    
    input clock;
    input reset;                        //��λ�ź�
    input Write_enable;                 //д�ź�
    input Select;                       //LEDƬѡ�ź�
    input[1:0]  Address;                //��LEDģ��ĵ�ַ�Ͷˣ��˴�Ϊ60 or 62��
    input[15:0] Write_data_in;          //д��LEDģ�������
    output[23:0]    Write_data_out;     //����������24λLED�ź�
    
    reg[23:0]      Write_data_out;
    
    
    //LED����ʵ��
    always @(posedge clock or posedge reset)
    begin
        if (Select == 0 || reset == 1)
            Write_data_out = 24'h000000;
        else
            if (Write_enable)
                case (Address)
                    2'b00: begin
                               Write_data_out[7:0] = Write_data_in[7:0];            //G
                               Write_data_out[15:8] = Write_data_in[15:8];          //Y
                           end
                    2'b10: Write_data_out[23:16] = Write_data_in[7:0];              //R
                    default: Write_data_out = 24'hZZZZZZ;
                endcase
    end
endmodule