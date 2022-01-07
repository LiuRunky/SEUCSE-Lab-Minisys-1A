`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module MultiIORead(
    clock,reset,
    IO_read,IO_read_data,
    Switch_ctrl,IO_read_data_switch,
    Key_ctrl,IO_read_data_key,
    CTC_ctrl,IO_read_data_ctc
    );
    
    input clock;
    input reset;
    
    input IO_read;
    output[15:0]    IO_read_data;
    
    input Key_ctrl;
    input[15:0] IO_read_data_key;
    
    input CTC_ctrl;
    input[15:0] IO_read_data_ctc;

    input Switch_ctrl;
    input[15:0] IO_read_data_switch;
    
    
    reg[15:0]   IO_read_data;
    
    
    always @(*)
    begin
        if (reset == 1)
            IO_read_data = 16'b0000_0000_0000_0000;
        else
            if (IO_read == 1)
            begin
                if (Key_ctrl == 1)
                    IO_read_data = IO_read_data_key;    //Key
                else if (Switch_ctrl == 1)
                    IO_read_data = IO_read_data_switch; //Switch
                else if (CTC_ctrl == 1)
                    IO_read_data = IO_read_data_ctc;    //CTC
                else
                    IO_read_data = IO_read_data;        //Ä¬ÈÏÖµ
            end
    end
endmodule
