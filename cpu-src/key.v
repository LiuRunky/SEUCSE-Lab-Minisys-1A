`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module Key(
    clock,reset,
    Read_enable,Select,Address,
    Row,Column,
    Read_data_out
    );
    
    input clock;
    input reset;                        //��λ�ź�
    input Read_enable;                  //���ź�
    input Select;                       //KeyƬѡ�ź�
    input[1:0]  Address;                //��Keyģ��ĵ�ַ�Ͷˣ��˴�Ϊ10 or 12��
    
    output[3:0]  Row;                   //����
    input[3:0]  Column;                 //����
    
    output[15:0]    Read_data_out;      //�͵�CPU��4x4����ֵ
    
    
    reg[3:0]    Row;
    reg[15:0]   value;
    reg[15:0]   state;
    reg[15:0]   Read_data_out;
    

    reg still;                      //����һ�ΰ��º�δ�ɿ�����ô�ٴ�ɨ��ʱ�����value
    
    //Key����ʵ��
    always @(posedge clock or posedge reset)
    begin
        if (Select == 0 || reset == 1)
        begin
            Read_data_out = 16'h0000;
            value = 16'h0000;
            state = 16'h0000;
            Row = 4'b0000;
            still = 1'b0;
        end
        else
        begin
            case (Row)
                4'b0000: begin //��ʼɨ��
                             if (Column != 4'b1111) //�����߲�ȫΪ1ʱ��ʼɨ��
                                 Row = 4'b0111;
                             else
                                 still = 1'b0;
                         end
                4'b0111: begin //ɨ��0��
                             if (Column != 4'b1111)
                             begin
                                 if (still == 1'b0 || value[7:4] != Row || value[3:0] != Column)
                                 begin
                                     value[3:0] = Column;
                                     value[7:4] = Row;
                                     state = state | 16'h0001;
                                     Row = 4'b0000;
                                     still = 1'b1;
                                     case (Column)
                                         4'b0111: value[11:8] = 4'h1;
                                         4'b1011: value[11:8] = 4'h2;
                                         4'b1101: value[11:8] = 4'h3;
                                         4'b1110: value[11:8] = 4'hA;
                                     endcase
                                 end
                             end
                             else
                                 Row = 4'b1011;
                         end
                4'b1011: begin //ɨ��1��
                             if (Column != 4'b1111)
                             begin
                                 if (still == 1'b0 || value[7:4] != Row || value[3:0] != Column)
                                 begin
                                     value[3:0] = Column;
                                     value[7:4] = Row;
                                     state = state | 16'h0001;
                                     Row = 4'b0000;
                                     still = 1'b1;
                                     case (Column)
                                         4'b0111: value[11:8] = 4'h4;
                                         4'b1011: value[11:8] = 4'h5;
                                         4'b1101: value[11:8] = 4'h6;
                                         4'b1110: value[11:8] = 4'hB;
                                     endcase
                                 end
                             end
                             else
                                 Row = 4'b1101;
                         end
                4'b1101: begin //ɨ��2��
                             if (Column != 4'b1111)
                             begin
                                 if (still == 1'b0 || value[7:4] != Row || value[3:0] != Column)
                                 begin
                                     value[3:0] = Column;
                                     value[7:4] = Row;
                                     state = state | 16'h0001;
                                     Row = 4'b0000;
                                     still = 1'b1;
                                     case (Column)
                                         4'b0111: value[11:8] = 4'h7;
                                         4'b1011: value[11:8] = 4'h8;
                                         4'b1101: value[11:8] = 4'h9;
                                         4'b1110: value[11:8] = 4'hC;
                                     endcase
                                 end
                             end
                             else
                                 Row = 4'b1110;
                         end
                4'b1110: begin //ɨ��3��
                             if (Column != 4'b1111)
                             begin
                                 if (still == 1'b0 || value[7:4] != Row || value[3:0] != Column)
                                 begin
                                     value[3:0] = Column;
                                     value[7:4] = Row;
                                     state = state | 16'h0001;
                                     Row = 4'b0000;
                                     still = 1'b1;
                                     case (Column)
                                         4'b0111: value[11:8] = 4'hE;
                                         4'b1011: value[11:8] = 4'h0;
                                         4'b1101: value[11:8] = 4'hF;
                                         4'b1110: value[11:8] = 4'hD;
                                     endcase
                                 end
                             end
                             else
                             begin
                                 Row = 4'b0000;
                             end
                         end
                default: Row = 4'b0000;
            endcase

            if (Read_enable == 1)
                case (Address)
                    2'b00: Read_data_out = value;
                    2'b10: begin
                               Read_data_out = state;
                               state = state & 16'hFFFE;
                           end
                    default: Read_data_out = 16'hZZZZ;
                endcase
        end
    end
endmodule
