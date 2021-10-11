`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module LED(
    clock,reset,
    Write_enable,Select,Address,Write_data_in,Write_data_out
    );
    
    input clock;
    input reset;                        //复位信号
    input Write_enable;                 //写信号
    input Select;                       //LED片选信号
    input[1:0]  Address;                //到LED模块的地址低端（此处为60 or 62）
    input[15:0] Write_data_in;          //写到LED模块的数据
    output[23:0]    Write_data_out;     //向板子输出的24位LED信号
    
    reg[23:0]      Write_data_out;
    
    
    //LED功能实现
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