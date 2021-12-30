`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module Buzzer(
    clock,reset,
    Write_enable,Select,Address,Write_data_in,
    Buzzer_output
    );
    
    input clock;
    input reset;
    input Write_enable;                 //写信号
    input Select;                       //Buzzer片选信号
    input[1:0]  Address;                //到Buzzer模块的地址低端（此处为40 or 42）
    input[15:0] Write_data_in;          //写到Buzzer模块的数据
    output      Buzzer_output;          //输出的蜂鸣器信号
    
    
    reg     Buzzer_output;
    reg     status;                     //控制开关
    reg[15:0]   maximum;                //实际上类似一个计时器
    reg[15:0]   counter;
    
    
    //Buzzer模块实现
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
