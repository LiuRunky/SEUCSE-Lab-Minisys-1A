`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: 数据选择单元
// Function:    1. 从各个接口中读/写数据
//              2. 产生接口的片选信号
//////////////////////////////////////////////////////////////////////////////////


module MEMorIO(
    Address,Memory_read,Memory_write,IO_read,IO_write,
    Memory_read_data,IO_read_data,Write_data_in,
    Memory_sign,Memory_data_width,
    Read_data,Write_data_latch,
    Display_ctrl,Key_ctrl,CTC_ctrl,PWM_ctrl,Buzzer_ctrl,WDT_ctrl,LED_ctrl,Switch_ctrl
    );
    
    input[31:0] Address;
    input       Memory_read,Memory_write,IO_read,IO_write;  //从control来的控制信号
    input       Memory_sign;
    input[1:0]  Memory_data_width;
    
    input[31:0] Memory_read_data;                       //从MEM中读出的数据
    input[15:0] IO_read_data;                           //从IO中读出的数据
    input[31:0] Write_data_in;                          //传入选择单元、要写到MEM/IO中的数据
    
    output[31:0]    Read_data;                          //从MEM/IO中读取的数据
    output[31:0]    Write_data_latch;                   //传出选择单元、要写到MEM/IO中的数据
    output          Display_ctrl;                       //8位7段数码管
    output          Key_ctrl;                           //4x4键盘
    output          CTC_ctrl;                           //定时器or计时器
    output          PWM_ctrl;                           //PWM脉冲宽度调制
    output          Buzzer_ctrl;                        //蜂鸣器
    output          WDT_ctrl;                           //看门狗计数器
    output          LED_ctrl;                           //3x8颜色为RYG的LED
    output          Switch_ctrl;                        //24个拨码开关
        
    reg[31:0]   Write_data_latch;                      //锁存要写入MEM/IO的数据
    
    wire    io_sel;                                    //是否为IO操作
    
    
    //io_sel
    assign io_sel = (IO_read || IO_write);
    
    //若读取的数据来自IO，则进行零扩展
    assign Read_data = Memory_read ? Memory_read_data : {16'h0000,IO_read_data};
    
    //接口的地址
    assign Display_ctrl = (io_sel && Address[31:3] == 29'h1FFFFF80) ? 1'b1 : 1'b0;
    assign Key_ctrl = (io_sel && Address[31:2] == 30'h3FFFFF04) ? 1'b1 : 1'b0;
    assign CTC_ctrl = (io_sel && Address[31:3] == 29'h1FFFFF84) ? 1'b1 : 1'b0;
    assign PWM_ctrl = (io_sel && Address[31:3] == 29'h1FFFFF86) ? 1'b1 : 1'b0;
    assign Buzzer_ctrl = (io_sel && Address[31:2] == 30'h3FFFFF10) ? 1'b1 : 1'b0;
    assign WDT_ctrl = (io_sel && Address == 32'hFFFFFC50) ? 1'b1 : 1'b0;
    assign LED_ctrl = (io_sel && Address[31:2] == 30'h3FFFFF18) ? 1'b1 : 1'b0;
    assign Switch_ctrl = (io_sel && Address[31:2] == 30'h3FFFFF1C) ? 1'b1 : 1'b0;
    
    //设置Write_data_latch
    always @(*)
    begin
        Write_data_latch = (Memory_write || IO_write) ? Write_data_in : 32'hZZZZZZZZ;
    end
    
endmodule
