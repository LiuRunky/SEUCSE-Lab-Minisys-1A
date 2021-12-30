`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


//counter in [0,threshold] 输出1
//counter in [threshold+1,maximum] 输出0
//禁止计数时 输出1
module PWM(
    clock,reset,
    Write_enable,Select,Address,Write_data_in,
    PWM_output);
    
    input clock;
    input reset;
    input Write_enable;                 //写信号
    input Select;                       //PWM片选信号
    input[2:0]  Address;                //到PWM模块的地址低端（此处为30 or 32 or 34）
    
    input[15:0] Write_data_in;          //写到PWM模块的数据
    output  PWM_output;
    
    
    reg PWM_output;
    reg[15:0]   maximum;                //最大值寄存器
    reg[15:0]   threshold;              //对比值寄存器
    reg[15:0]   counter;                //计数器
    reg[15:0]   flag;                   //使能寄存器
    
    
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
        else if (flag[0] == 1)          //允许计数
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