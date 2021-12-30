`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


//mask为高时，对应位置的数码管被禁用
module Display(
    clock,reset,
    Write_enable,Select,Address,Write_data_in,
    Enable,Value
    );
    
    input clock;
    input reset;
    input Write_enable;                 //写信号
    input Select;                       //Display片选信号
    input[2:0]  Address;                //到Display模块的地址低端（此处为00 or 02 or 04）
    
    input[15:0] Write_data_in;          //写到Display模块的数据
    output[8:0] Enable;                 //8位信号A0-A7，低电平有效
    output[8:0] Value;                  //8位信号CA-DP，低电平有效
    
    reg[31:0]   data;
    reg[7:0]    mask;
    
    reg[3:0]    raw;
    reg[8:0]    current;
    reg[7:0]    Enable,Value;
    
    
    //分频，降低刷新速率，否则会出现显示不全/错误的情况
    reg         refresh;
    reg[15:0]    counter;
    
    initial
    begin
        current = 9'hFE;
        counter = 16'h0800;
        refresh = 1'b0;
    end
    
    always @(posedge clock)
    begin
        if (counter != 16'h0000)
            counter = counter - 1;
        else
        begin
            counter = 16'h0800;
            refresh = ~refresh;
        end
    end
    
    
    always @(raw)
    begin
        case (raw)
            4'b0000: Value = 8'b1100_0000;
            4'b0001: Value = 8'b1111_1001;
            4'b0010: Value = 8'b1010_0100;
            4'b0011: Value = 8'b1011_0000;
            4'b0100: Value = 8'b1001_1001;
            4'b0101: Value = 8'b1001_0010;
            4'b0110: Value = 8'b1000_0010;
            4'b0111: Value = 8'b1111_1000;
            4'b1000: Value = 8'b1000_0000;
            4'b1001: Value = 8'b1001_0000;
            4'b1010: Value = 8'b1000_1000;
            4'b1011: Value = 8'b1000_0011;
            4'b1100: Value = 8'b1100_0110;
            4'b1101: Value = 8'b1010_0001;
            4'b1110: Value = 8'b1000_0110;
            4'b1111: Value = 8'b1000_1110;
        endcase
    end
    
    //Display显示
    always @(posedge refresh or posedge reset)
    begin
        if (Select == 0 || reset == 1)
        begin
            current = 9'h0FE;
        end
        else
        begin
            case (current)
                9'h0FE: begin
                            raw = data[3:0];
                            Enable = current[7:0] | mask;
                            current = 9'h1FE;
                        end
                9'h1FE: current = 9'h0FD;
                9'h0FD: begin
                            raw = data[7:4];
                            Enable = current[7:0] | mask;
                            current = 9'h1FD;
                        end
                9'h1FD: current = 9'h0FB;
                9'h0FB: begin
                            raw = data[11:8];
                            Enable = current[7:0] | mask;
                            current = 9'h1FB;
                        end
                9'h1FB: current = 9'h0F7;
                9'h0F7: begin
                            raw = data[15:12];
                            Enable = current[7:0] | mask;
                            current = 9'h1F7;
                        end
                9'h1F7: current = 9'h0EF;
                9'h0EF: begin
                            raw = data[19:16];
                            Enable = current[7:0] | mask;
                            current = 9'h1EF;
                        end
                9'h1EF: current = 9'h0DF;
                9'h0DF: begin
                            raw = data[23:20];
                            Enable = current[7:0] | mask;
                            current = 9'h1DF;
                        end
                9'h1DF: current = 9'h0BF;
                9'h0BF: begin
                            raw = data[27:24];
                            Enable = current[7:0] | mask;
                            current = 9'h1BF;
                        end
                9'h1BF: current = 9'h07F;
                9'h07F: begin
                            raw = data[31:28];
                            Enable = current[7:0] | mask;
                            current = 9'h17F;
                        end
                9'h17F: current = 9'h0FE;
                default: current = 9'h000;
            endcase
        end
    end
    
    always @(posedge clock)
    begin
        if (Select == 0 || reset == 1)
        begin
            data = 32'h0000_0000;
            mask = 8'h00;
        end
        else
            if (Write_enable == 1)
                case (Address)
                    3'b000: data[15:0] = Write_data_in;
                    3'b010: data[31:16] = Write_data_in;
                    3'b100: mask = Write_data_in[7:0];
                    default: data[31:0] = 32'hFFFFFFFF;
                endcase
    end
endmodule
