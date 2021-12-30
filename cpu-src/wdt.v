`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module WDT(
    clock,reset,
    Write_enable,Select,Write_data_in,
    WDT_output
    );

    input clock;
    input reset;
    input Write_enable;                 //写信号
    input Select;                       //WDT片选信号
    input[15:0] Write_data_in;          //写到WDT模块的数据（实际用不上）
    output      WDT_output;             //输出的复位信号
    
    
    reg WDT_output;
    reg[15:0]   counter;                //计数器
    reg[2:0]    mini_cnt;               //小计数器，使得复位信号持续4个时钟
    
    
    //WDT模块实现
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
            if (counter == 16'd0000)    //已经计数到0
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
