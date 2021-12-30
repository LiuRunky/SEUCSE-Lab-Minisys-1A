`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


//写init的时候会自动开始计时/计数
//所以写mode要提前于写init
//读counter读到的是倒计时
//读status后最后两位标志会清除

//计时和计数时，周期为init，counter中循环的值为1~init
//只有计时会产生CTC_output，低电平出现在值为init时（除了赋值那次）
module CTC(
    clock,reset,
    Read_enable,Write_enable,Select,Address,
    Write_data_in,Read_data_out,
    Pulse0_in,Pulse1_in,
    CTC0_output,CTC1_output
    );
    
    input clock;
    input reset;
    input Read_enable;                  //读信号
    input Write_enable;                 //写信号
    input Select;                       //CTC片选信号
    input[2:0]  Address;                //到CTC模块的地址低端（此处为20 or 22 or 24 or 26）
    
    input Pulse0_in;                    //CT0的外部脉冲
    input Pulse1_in;                    //CT1的外部脉冲
    input[15:0] Write_data_in;          //写到CTC模块的数据
    output[15:0]    Read_data_out;      //从CTC模块读到CPU的数据
    
    output      CTC0_output;
    output      CTC1_output;
    
    
    reg     CTC0_output;
    reg     CTC1_output;
    reg[15:0]   Read_data_out;
    
    reg[15:0]   mode0,mode1;            //工作模式寄存器
    reg[15:0]   stat0_0,stat1_0;        //在定时模式下的状态寄存器
    reg[15:0]   stat0_1,stat1_1;        //在计数模式下的状态寄存器
    reg[15:0]   status0,status1;        //状态寄存器
    
    reg[15:0]   init0,init1;            //初始值寄存器
    reg[15:0]   cnt0_0,cnt1_0;          //在定时模式下的计数器
    reg[15:0]   cnt0_1,cnt1_1;          //在计数模式下的计数器
    reg[15:0]   counter0,counter1;      //减一计数器
    
    
    initial
    begin
        mode0 = 16'h0000;
        mode1 = 16'h0000;
        status0 = 16'h0000;
        status1 = 16'h0000;
        counter0 = 16'h0000;
        counter1 = 16'h0000;
    end
    
    //CTC模块实现
    always @(posedge clock)
    begin
        if (Select == 0 || reset == 1)      //初始化
        begin
            CTC0_output = 1;
            CTC1_output = 1;
            init0 = 16'h0000;
            init1 = 16'h0000;
            cnt0_0 = 16'h0000;
            cnt1_0 = 16'h0000;
            stat0_0 = 16'h0000;
            stat1_0 = 16'h0000;
        end
        else
        begin
            if (Read_enable == 1)
            begin
                case (Address)
                    //读CTC0状态并清零
                    3'b000:
                    begin
                        Read_data_out = status0;
                        stat0_0 = status0 & 16'hFFFC;
                    end
                    //读CTC1状态并清零
                    3'b010:
                    begin
                        Read_data_out = status1;
                        stat1_0 = status1 & 16'hFFFC;
                    end
                    //读CTC0计数值
                    3'b100: Read_data_out = counter0;
                    //读CTC1计数值
                    3'b110: Read_data_out = counter1;
                    default: Read_data_out = 16'hZZZZ;
                endcase
            end
            else if (Write_enable == 1)
            begin
                case (Address)
                    //写CTC0方式寄存器
                    3'b000:
                    begin
                        mode0 = Write_data_in;
                        stat0_0 = status0 & 16'h7FFC;
                    end
                    //写CTC1方式寄存器
                    3'b010:
                    begin
                        mode1 = Write_data_in;
                        stat1_0 = status1 & 16'h7FFC;
                    end
                    //写CTC0初始值寄存器
                    3'b100:
                    begin
                        init0 = Write_data_in;
                        stat0_0 = status0 | 16'h8000;
                    end
                    //写CTC1初始值寄存器
                    3'b110:
                    begin
                        init1 = Write_data_in;
                        stat1_0 = status1 | 16'h8000;
                    end
                    //default:
                endcase
            end
        end
        
        //CTC0定时
        if (status0[15] == 1'b0)        //计数值无效，保持输出为高电平
            CTC0_output = 1'b1;
        else
            if (mode0[0] == 1'b0)       //定时
            begin
                if (counter0 == 16'h0001)           //定时到1，输出低电平
                begin
                    CTC0_output = 1'b0;
                    stat0_0 = status0 | 16'h0001;   //定时已到
                    
                    if (mode0[1] == 1'b1)           //如果重复定时，重新设定为初始值
                        cnt0_0 = init0;
                    else                            //否则，设置状态寄存器为计数值无效
                    begin
                        stat0_0 = stat0_0 & 16'h7FFF;
                        cnt0_0 = 16'h0000;
                    end
                end
                else
                begin
                    CTC0_output = 1'b1;
                    cnt0_0 = counter0 - 1'b1;
                    stat0_0 = status0 | 16'h8000;
                end
            end
        
        //CTC1定时
        if (status1[15] == 1'b0)        //计数值无效，保持输出为高电平
            CTC1_output = 1'b1;
        else
            if (mode1[0] == 1'b0)       //定时
            begin
                 if (counter1 == 16'h0001)          //定时到1，输出低电平
                begin
                    CTC1_output = 1'b0;
                    stat1_0 = status1 | 16'h0001;   //定时已到
                    
                    if (mode1[1] == 1'b1)           //如果重复定时，重新设定为初始值
                        cnt1_0 = init1;
                    else                            //否则，设置状态寄存器为计数值无效
                    begin
                        stat1_0 = stat1_0 & 16'h7FFF;
                        cnt1_0 = 16'h0000;
                    end
                end
                else
                begin
                    CTC1_output = 1'b1;
                    cnt1_0 = counter1 - 1'b1;
                    stat1_0 = status1 | 16'h8000;
                end
            end
    end
    
    //CTC0计数
    always @(posedge Pulse0_in)
    begin
        if (status0[15] == 1'b1 && mode0[0] == 1'b1)    //如果计数有效且为计数模式
            if (counter0 == 16'h0001)           //计数到1
            begin
                stat0_1 = status0 | 16'h0002;   //置计数已到标志
                
                if (mode0[1] == 1'b1)           //如果为重复计数，重新设定为初始值
                    cnt0_1 = init0;
                else                            //否则，设置状态寄存器为计数值无效
                begin
                    stat0_1 = stat0_1 & 16'h7FFF;
                    cnt0_1 = 16'h0000;
                end
            end
            else
            begin
                cnt0_1 = counter0 - 1'b1;
                stat0_1 = status0 | 16'h8000;
            end
    end
    
    //CTC1计数
    always @(posedge Pulse1_in)
    begin
        if (status1[15] == 1'b1 && mode1[0] == 1'b1)    //如果计数有效且为计数模式
            if (counter1 == 16'h0001)           //计数到1
            begin
                stat1_1 = status1 | 16'h0002;   //置计数已到标志
                
                if (mode1[1] == 1'b1)           //如果为重复计数，重新设定为初始值
                    cnt1_1 = init1;
                else                            //否则，设置状态寄存器为计数值无效
                begin
                    stat1_1 = stat1_1 & 16'h7FFF;
                    cnt1_1 = 16'h0000;
                end
            end
            else
            begin
                cnt1_1 = counter1 - 1'b1;
                stat1_1 = status1 | 16'h8000;
            end
    end

    //根据stat0_0与stat0_1对于status0赋值
    always @(stat0_0,stat0_1)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && ((Read_enable && Address == 3'b000) || (Write_enable && Address[1:0] == 2'b00)))
                status0 = stat0_0;          //对CTC0读写时
            else
                if (mode0[0] == 0)
                    status0 = stat0_0;      //定时时
                else
                    status0 = stat0_1;      //计数时
        end
    end
    
    //根据stat1_0与stat1_1对于status1赋值
    always @(stat1_0,stat1_1)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && ((Read_enable && Address == 3'b010) || (Write_enable && Address[1:0] == 2'b10)))
                status1 = stat1_0;          //对CTC1读写时
            else
                if (mode1[0] == 0)
                    status1 = stat1_0;      //定时时
                else
                    status1 = stat1_1;      //计数时
        end
    end
    
    //根据cnt0_0与cnt0_1对于counter0赋值
    always @(*)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && (Write_enable == 1 && Address == 4'b100))
                counter0 = init0;           //对CTC0读写时
            else
                if (mode0[0] == 0)
                    counter0 = cnt0_0;      //定时时
                else
                    counter0 = cnt0_1;      //计数时
        end
    end
    
    //根据cnt1_0与cnt1_1对于counter1赋值
    always @(*)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && (Write_enable == 1 && Address == 4'b110))
                counter1 = init1;           //对CTC1读写时
            else
                if (mode1[0] == 0)
                    counter1 = cnt1_0;      //定时时
                else
                    counter1 = cnt1_1;      //计数时
        end
    end
endmodule