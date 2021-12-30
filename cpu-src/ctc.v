`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


//дinit��ʱ����Զ���ʼ��ʱ/����
//����дmodeҪ��ǰ��дinit
//��counter�������ǵ���ʱ
//��status�������λ��־�����

//��ʱ�ͼ���ʱ������Ϊinit��counter��ѭ����ֵΪ1~init
//ֻ�м�ʱ�����CTC_output���͵�ƽ������ֵΪinitʱ�����˸�ֵ�ǴΣ�
module CTC(
    clock,reset,
    Read_enable,Write_enable,Select,Address,
    Write_data_in,Read_data_out,
    Pulse0_in,Pulse1_in,
    CTC0_output,CTC1_output
    );
    
    input clock;
    input reset;
    input Read_enable;                  //���ź�
    input Write_enable;                 //д�ź�
    input Select;                       //CTCƬѡ�ź�
    input[2:0]  Address;                //��CTCģ��ĵ�ַ�Ͷˣ��˴�Ϊ20 or 22 or 24 or 26��
    
    input Pulse0_in;                    //CT0���ⲿ����
    input Pulse1_in;                    //CT1���ⲿ����
    input[15:0] Write_data_in;          //д��CTCģ�������
    output[15:0]    Read_data_out;      //��CTCģ�����CPU������
    
    output      CTC0_output;
    output      CTC1_output;
    
    
    reg     CTC0_output;
    reg     CTC1_output;
    reg[15:0]   Read_data_out;
    
    reg[15:0]   mode0,mode1;            //����ģʽ�Ĵ���
    reg[15:0]   stat0_0,stat1_0;        //�ڶ�ʱģʽ�µ�״̬�Ĵ���
    reg[15:0]   stat0_1,stat1_1;        //�ڼ���ģʽ�µ�״̬�Ĵ���
    reg[15:0]   status0,status1;        //״̬�Ĵ���
    
    reg[15:0]   init0,init1;            //��ʼֵ�Ĵ���
    reg[15:0]   cnt0_0,cnt1_0;          //�ڶ�ʱģʽ�µļ�����
    reg[15:0]   cnt0_1,cnt1_1;          //�ڼ���ģʽ�µļ�����
    reg[15:0]   counter0,counter1;      //��һ������
    
    
    initial
    begin
        mode0 = 16'h0000;
        mode1 = 16'h0000;
        status0 = 16'h0000;
        status1 = 16'h0000;
        counter0 = 16'h0000;
        counter1 = 16'h0000;
    end
    
    //CTCģ��ʵ��
    always @(posedge clock)
    begin
        if (Select == 0 || reset == 1)      //��ʼ��
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
                    //��CTC0״̬������
                    3'b000:
                    begin
                        Read_data_out = status0;
                        stat0_0 = status0 & 16'hFFFC;
                    end
                    //��CTC1״̬������
                    3'b010:
                    begin
                        Read_data_out = status1;
                        stat1_0 = status1 & 16'hFFFC;
                    end
                    //��CTC0����ֵ
                    3'b100: Read_data_out = counter0;
                    //��CTC1����ֵ
                    3'b110: Read_data_out = counter1;
                    default: Read_data_out = 16'hZZZZ;
                endcase
            end
            else if (Write_enable == 1)
            begin
                case (Address)
                    //дCTC0��ʽ�Ĵ���
                    3'b000:
                    begin
                        mode0 = Write_data_in;
                        stat0_0 = status0 & 16'h7FFC;
                    end
                    //дCTC1��ʽ�Ĵ���
                    3'b010:
                    begin
                        mode1 = Write_data_in;
                        stat1_0 = status1 & 16'h7FFC;
                    end
                    //дCTC0��ʼֵ�Ĵ���
                    3'b100:
                    begin
                        init0 = Write_data_in;
                        stat0_0 = status0 | 16'h8000;
                    end
                    //дCTC1��ʼֵ�Ĵ���
                    3'b110:
                    begin
                        init1 = Write_data_in;
                        stat1_0 = status1 | 16'h8000;
                    end
                    //default:
                endcase
            end
        end
        
        //CTC0��ʱ
        if (status0[15] == 1'b0)        //����ֵ��Ч���������Ϊ�ߵ�ƽ
            CTC0_output = 1'b1;
        else
            if (mode0[0] == 1'b0)       //��ʱ
            begin
                if (counter0 == 16'h0001)           //��ʱ��1������͵�ƽ
                begin
                    CTC0_output = 1'b0;
                    stat0_0 = status0 | 16'h0001;   //��ʱ�ѵ�
                    
                    if (mode0[1] == 1'b1)           //����ظ���ʱ�������趨Ϊ��ʼֵ
                        cnt0_0 = init0;
                    else                            //��������״̬�Ĵ���Ϊ����ֵ��Ч
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
        
        //CTC1��ʱ
        if (status1[15] == 1'b0)        //����ֵ��Ч���������Ϊ�ߵ�ƽ
            CTC1_output = 1'b1;
        else
            if (mode1[0] == 1'b0)       //��ʱ
            begin
                 if (counter1 == 16'h0001)          //��ʱ��1������͵�ƽ
                begin
                    CTC1_output = 1'b0;
                    stat1_0 = status1 | 16'h0001;   //��ʱ�ѵ�
                    
                    if (mode1[1] == 1'b1)           //����ظ���ʱ�������趨Ϊ��ʼֵ
                        cnt1_0 = init1;
                    else                            //��������״̬�Ĵ���Ϊ����ֵ��Ч
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
    
    //CTC0����
    always @(posedge Pulse0_in)
    begin
        if (status0[15] == 1'b1 && mode0[0] == 1'b1)    //���������Ч��Ϊ����ģʽ
            if (counter0 == 16'h0001)           //������1
            begin
                stat0_1 = status0 | 16'h0002;   //�ü����ѵ���־
                
                if (mode0[1] == 1'b1)           //���Ϊ�ظ������������趨Ϊ��ʼֵ
                    cnt0_1 = init0;
                else                            //��������״̬�Ĵ���Ϊ����ֵ��Ч
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
    
    //CTC1����
    always @(posedge Pulse1_in)
    begin
        if (status1[15] == 1'b1 && mode1[0] == 1'b1)    //���������Ч��Ϊ����ģʽ
            if (counter1 == 16'h0001)           //������1
            begin
                stat1_1 = status1 | 16'h0002;   //�ü����ѵ���־
                
                if (mode1[1] == 1'b1)           //���Ϊ�ظ������������趨Ϊ��ʼֵ
                    cnt1_1 = init1;
                else                            //��������״̬�Ĵ���Ϊ����ֵ��Ч
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

    //����stat0_0��stat0_1����status0��ֵ
    always @(stat0_0,stat0_1)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && ((Read_enable && Address == 3'b000) || (Write_enable && Address[1:0] == 2'b00)))
                status0 = stat0_0;          //��CTC0��дʱ
            else
                if (mode0[0] == 0)
                    status0 = stat0_0;      //��ʱʱ
                else
                    status0 = stat0_1;      //����ʱ
        end
    end
    
    //����stat1_0��stat1_1����status1��ֵ
    always @(stat1_0,stat1_1)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && ((Read_enable && Address == 3'b010) || (Write_enable && Address[1:0] == 2'b10)))
                status1 = stat1_0;          //��CTC1��дʱ
            else
                if (mode1[0] == 0)
                    status1 = stat1_0;      //��ʱʱ
                else
                    status1 = stat1_1;      //����ʱ
        end
    end
    
    //����cnt0_0��cnt0_1����counter0��ֵ
    always @(*)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && (Write_enable == 1 && Address == 4'b100))
                counter0 = init0;           //��CTC0��дʱ
            else
                if (mode0[0] == 0)
                    counter0 = cnt0_0;      //��ʱʱ
                else
                    counter0 = cnt0_1;      //����ʱ
        end
    end
    
    //����cnt1_0��cnt1_1����counter1��ֵ
    always @(*)
    begin
        if (reset == 0)
        begin
            if (Select == 1 && (Write_enable == 1 && Address == 4'b110))
                counter1 = init1;           //��CTC1��дʱ
            else
                if (mode1[0] == 0)
                    counter1 = cnt1_0;      //��ʱʱ
                else
                    counter1 = cnt1_1;      //����ʱ
        end
    end
endmodule