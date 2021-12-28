`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: 4x8 RAM
//////////////////////////////////////////////////////////////////////////////////


module DataMEM_4x8(
    clock,
    Memory_write,Address,Read_data,Write_data,
    Signed_extend,Memory_data_width,Bit_error,
    Upg_rst_i,Upg_clk_i,Upg_wen_i,Upg_adr_i,Upg_dat_i,Upg_done_i
    );
    
    input       clock;
    input       Memory_write;
    input[31:0] Address;
    input[31:0] Write_data;                                 //д��RAM������
    output[31:0]    Read_data;                              //��RAM����������
    
    input       Signed_extend;                              //�Ƿ���Ҫ������չ
    input[1:0]  Memory_data_width;                          //��д�Ŀ��
                                                            //(00: 8bit, 01: 16bit, 10: 32bit)
    output      Bit_error;                                  //��д����Ƿ�����
    
    //UART���������
    input       Upg_rst_i;                                  //UPG reset(��Ϊactive)
    input       Upg_clk_i;                                  //UPGʱ��(clk2)
    input       Upg_wen_i;                                  //UPGдʹ��
    input[13:0] Upg_adr_i;                                  //UPGд��ַ
    input[31:0] Upg_dat_i;                                  //UPGд����
    input       Upg_done_i;                                 //��������ɺ�Ϊ��

    
    wire clk;
    assign clk = clock/*!clock*/;                           //Ϊ�˽��ʱ���ӳ�����
    
    wire kickoff = Upg_rst_i | ((~Upg_rst_i) & Upg_done_i);
    
    
    reg[3:0]    memory_write_split;
    wire[31:0]  read_data_split;
    reg[31:0]   write_data_split;
    
    reg         Bit_error;
    reg[31:0]   Read_data;
    
    
    //8bit RAM #0
    ram0 ram0(
        .clka(kickoff ? clk : Upg_clk_i),
        .wea(kickoff ? memory_write_split[0] : Upg_wen_i),
        .addra(kickoff ? Address[15:2] : Upg_adr_i),
        .dina(kickoff ? write_data_split[7:0] : Upg_dat_i[7:0]),
        .douta(read_data_split[7:0])
    );

    //8bit RAM #1
    ram1 ram1(
        .clka(kickoff ? clk : Upg_clk_i),
        .wea(kickoff ? memory_write_split[1] : Upg_wen_i),
        .addra(kickoff ? Address[15:2] : Upg_adr_i),
        .dina(kickoff ? write_data_split[15:8] : Upg_dat_i[15:8]),
        .douta(read_data_split[15:8])
    );

    //8bit RAM #2
    ram2 ram2(
        .clka(kickoff ? clk : Upg_clk_i),
        .wea(kickoff ? memory_write_split[2] : Upg_wen_i),
        .addra(kickoff ? Address[15:2] : Upg_adr_i),
        .dina(kickoff ? write_data_split[23:16] : Upg_dat_i[23:16]),
        .douta(read_data_split[23:16])
    );
    
    //8bit RAM #3
    ram3 ram3(
        .clka(kickoff ? clk : Upg_clk_i),
        .wea(kickoff ? memory_write_split[3] : Upg_wen_i),
        .addra(kickoff ? Address[15:2] : Upg_adr_i),
        .dina(kickoff ? write_data_split[31:24] : Upg_dat_i[31:24]),
        .douta(read_data_split[31:24])
    );
    
    always @(*)
    begin
        Bit_error = 1'b0;
        memory_write_split = 4'b0000;
        case (Memory_data_width)
            //8bit
            2'b00:
            begin
                case (Address[1:0])
                    //��дRAM #0
                    2'b00:
                    begin
                        memory_write_split = 4'b0001 & {4{Memory_write}};
                        write_data_split[7:0] = Write_data[7:0];
                        Read_data[7:0] = read_data_split[7:0];
                    end
                    //��дRAM #1
                    2'b01:
                    begin
                        memory_write_split = 4'b0010 & {4{Memory_write}};
                        write_data_split[15:8] = Write_data[7:0];
                        Read_data[7:0] = read_data_split[15:8];
                    end
                    //��дRAM #2
                    2'b10:
                    begin
                        memory_write_split = 4'b0100 & {4{Memory_write}};
                        write_data_split[23:16] = Write_data[7:0];
                        Read_data[7:0] = read_data_split[23:16];
                    end
                    //��дRAM #3
                    2'b11:
                    begin
                         memory_write_split = 4'b1000 & {4{Memory_write}};
                         write_data_split[31:24] = Write_data[7:0];
                         Read_data[7:0] = read_data_split[31:24];
                    end
                endcase
                Read_data[31:8] = {24{Signed_extend & Read_data[7]}};
            end
            //16bit
            2'b01:
            begin
                Bit_error = Address[0] & Memory_write;
                case (Address[1])
                    //��дRAM #0, #1
                    1'b0:
                    begin
                        memory_write_split = 4'b0011 & {4{Memory_write}};
                        write_data_split[15:0] = Write_data[15:0];
                        Read_data[15:0] = read_data_split[15:0];
                    end
                    //��дRAM #2, #3
                    1'b1:
                    begin
                        memory_write_split = 4'b1100 & {4{Memory_write}};
                        write_data_split[31:16] = Write_data[15:0];
                        Read_data[15:0] = read_data_split[31:16];
                    end
                endcase
                Read_data[31:16] = {16{Signed_extend & Read_data[15]}};
            end
            //32bit
            2'b11:
            begin
                Bit_error = (Address[1:0] == 2'b00 ? 1'b0 : 1'b1) & Memory_write;
                if (Bit_error == 1'b0)
                begin
                    memory_write_split = 4'b1111 & {4{Memory_write}};
                    write_data_split = Write_data;
                    Read_data = read_data_split;
                end
            end
            default: Bit_error = 1'b1 & Memory_write;
        endcase
    end
endmodule
