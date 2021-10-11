`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: ����ѡ��Ԫ
// Function:    1. �Ӹ����ӿ��ж�/д����
//              2. �����ӿڵ�Ƭѡ�ź�
//////////////////////////////////////////////////////////////////////////////////


module MEMorIO(
    Address,Memory_read,Memory_write,IO_read,IO_write,
    Memory_read_data,IO_read_data,Write_data_in,
    Memory_sign,Memory_data_width,
    Read_data,Write_data_latch,
    Disp_ctrl,Key_ctrl,CTC_ctrl,PWM_ctrl,UART_ctrl,WDT_ctrl,LED_ctrl,Switch_ctrl
    );
    
    input[31:0] Address;
    input       Memory_read,Memory_write,IO_read,IO_write;  //��control���Ŀ����ź�
    input       Memory_sign;
    input[1:0]  Memory_data_width;
    
    input[31:0] Memory_read_data;                       //��MEM�ж���������
    input[15:0] IO_read_data;                           //��IO�ж���������
    input[31:0] Write_data_in;                          //����ѡ��Ԫ��Ҫд��MEM/IO�е�����
    
    output[31:0]    Read_data;                          //��MEM/IO�ж�ȡ������
    output[31:0]    Write_data_latch;                   //����ѡ��Ԫ��Ҫд��MEM/IO�е�����
    output          Disp_ctrl;                          //8λ7�������
    output          Key_ctrl;                           //4x4����
    output          CTC_ctrl;                           //��ʱ��or��ʱ��
    output          PWM_ctrl;                           //PWM�����ȵ���
    output          UART_ctrl;                          //����
    output          WDT_ctrl;                           //���Ź�������
    output          LED_ctrl;                           //3x8��ɫΪRYG��LED
    output          Switch_ctrl;                        //24�����뿪��
        
    reg[31:0]   Write_data_latch;                      //����Ҫд��MEM/IO������
    
    wire    io_sel;                                    //�Ƿ�ΪIO����
    
    
    //io_sel
    assign io_sel = (IO_read || IO_write);
    
    //����ȡ����������IO�����������չ
    assign Read_data = Memory_read ? Memory_read_data : {16'h0000,IO_read_data};
    
    //�ӿڵĵ�ַ��������Ҫ�ġ�
    assign Disp_ctrl = (io_sel && Address == 32'hFFFFFC00) ? 1'b1 : 1'b0;
    assign Key_ctrl = (io_sel && Address == 32'hFFFFFC10) ? 1'b1 : 1'b0;
    assign CTC_ctrl = (io_sel && Address == 32'hFFFFFC20) ? 1'b1 : 1'b0;
    assign PWM_ctrl = (io_sel && Address == 32'hFFFFFC30) ? 1'b1 : 1'b0;
    assign UART_ctrl = (io_sel && Address == 32'hFFFFFC40) ? 1'b1 : 1'b0;
    assign WDT_ctrl = (io_sel && Address == 32'hFFFFFC50) ? 1'b1 : 1'b0;
    assign LED_ctrl = (io_sel && Address == 32'hFFFFFC60) ? 1'b1 : 1'b0;
    assign Switch_ctrl = (io_sel && Address == 32'hFFFFFC70) ? 1'b1 : 1'b0;
    
    //����Write_data_latch
    always @(*)
    begin
        Write_data_latch = (Memory_write || IO_write) ? Write_data_in : 32'hZZZZZZZZ;
    end
    
endmodule