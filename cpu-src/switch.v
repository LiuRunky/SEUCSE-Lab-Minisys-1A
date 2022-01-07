`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module Switch(
    clock,reset,
    Read_enable,Select,Address,Read_data_in,Read_data_out
    );
    
    input clock;
    input reset;                        //复位信号
    input Read_enable;                  //写信号
    input Select;                       //Switch片选信号
    input[1:0]  Address;                //到Switch模块的地址低端（此处为70 or 72）
    input[23:0] Read_data_in;           //从板子读的24位拨码开关数据
    output[15:0]    Read_data_out;      //送到CPU的拨码开关值
    
    reg[15:0]   Read_data_out;
    
    
    //Switch功能实现
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
