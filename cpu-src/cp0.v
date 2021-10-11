`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: CP0协处理器
// Function:    1. 维护CP0寄存器组
//////////////////////////////////////////////////////////////////////////////////


module CP0(
    clock,reset,
    Cause_write,Cause_write_data,Cause_read_data,
    Status_write,Status_write_data,Status_read_data,
    EPC_write,EPC_write_data,EPC_read_data
    );
    
    input       clock;
    input       reset;
    
    input       Cause_write,Status_write,EPC_write;
    input[31:0] Cause_write_data,Status_write_data,EPC_write_data;
    output[31:0]    Cause_read_data,Status_read_data,EPC_read_data;
    
    reg[31:0]  cause,status,epc;
    
    
    
    //read_data一直可用
    assign Cause_read_data = cause;
    assign Status_read_data = status;
    assign EPC_read_data = epc;
    
    //write_data在write=1时写入
    always @(negedge clock)
    begin
        if (reset)
        begin
            //IM[7:2] = 1, IE = 1
            //KSU: kernel(=00), supervisor(=01), user(=10)
            status <= 32'b0000_0000_0000_0000_111111_00_000_00_00_1;
            
            //IP = 000000
            //ExcCode: 00000(外部中断), 01000(syscall), 01001(break),
            //         01010(preserved), 01100(overflow)
            cause <= 32'b0000_0000_0000_0000_00_000000_0_000000_00;
            
            //Address = 0x00000000
            epc <= 32'h00000000;
        end
        else
        begin
            if (Status_write)
                status <= Status_write_data;
            if (Cause_write)
                cause <= Cause_write_data;
            if (EPC_write)
                epc <= EPC_write_data;
        end
    end
    
endmodule
