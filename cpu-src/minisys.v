`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 东南大学
// Engineer: 刘朗麒
//////////////////////////////////////////////////////////////////////////////////

module minisys(
    fpga_rst,fpga_clk,
    start_pg,rx,tx,
    LED2N4,Switch2N4,KeyRow0N4,KeyColumn0N4,DisplayEnable0N8,DisplayValue0N8,
    Buzzer0N1
    );

    input       fpga_rst;                                           //板上的reset信号，高电平复位
    input       fpga_clk;                                           //板上的100MHz时钟信号
    
    wire        clock;                                             //CPU主时钟
    wire        reset;                                             //reset需要同时考虑fpga_set与下载的reset
    wire        flush_pipeline;                                    //清空流水寄存器
    
    

    //UART编程器引脚
    input       start_pg;                                           //接线板上S3按键为下载启动键
    input       rx;                                                 //UART接收
    output      tx;                                                 //UART发送
    
    wire       upg_clk,upg_clk_o,upg_wen_o,upg_done_o;
    wire[14:0] upg_adr_o;
    wire[31:0] upg_dat_o;
    
    wire       spg_bufg;
    BUFG U1(                                                        //S3按键去抖
        .I(start_pg),
        .O(spg_bufg)
    );
    
    reg        upg_rst;
    always @(posedge fpga_clk)
    begin
        if (spg_bufg)
            upg_rst = 0;
        if (fpga_rst)
            upg_rst = 1;
    end
    assign reset = fpga_rst | !upg_rst;
                                                                    
    uart_bmpg_0 uartpg(
        .upg_clk_i(upg_clk),                                        //10MHz
        .upg_rst_i(upg_rst),                                        //高电平有效
        
        .upg_clk_o(upg_clk_o),
        .upg_wen_o(upg_wen_o),
        .upg_adr_o(upg_adr_o),
        .upg_dat_o(upg_dat_o),
        .upg_done_o(upg_done_o),
        
        .upg_rx_i(rx),
        .upg_tx_o(tx)
    );
    
    
    
    //其余CPU模块单元
    wire[1:0]   alu_op;
    wire        alu_src;
    wire[31:0]  alu_result;                                        //ALU运算结果
    wire[31:0]  pc_add_result;                                     //PC+4+offset<<2运算结果
    wire        zero;                                              //Zero标志，执行单元产生
    wire        positive;                                          //rs为正，执行单元产生
    wire        negative;                                          //rs为负，执行单元产生
    wire        overflow;                                          //Overflow标志，执行单元产生（有符号数加减）
    wire        divide_zero;                                       //Divide 0标志，执行单元产生（除法）
    
    wire[31:0]  pc_plus_4;                                         //PC+4
    wire[31:0]  pc_plus_4_latch;                                   //对于jal/jalr锁存的PC+4，传给idecode
    
    wire[31:0]  read_data_1;                                       //从寄存器读出的(rs)
    wire[31:0]  read_data_2;                                       //从寄存器读出的(rt)
    wire[31:0]  immediate_extend;                                  //立即数符号扩展
    
    wire[31:0]  instruction;
    wire[5:0]   opcode;
    wire[5:0]   func;
    wire[4:0]   shamt;
    
    wire        i_type,l_type,s_type;
    wire        jmp,jr,jal,jalr;
    wire        beq,bne,bgez,bgtz,blez,bltz,bgezal,bltzal;
    wire        register_write;
    wire[4:0]   register_write_sel;
    wire        memory_read,memory_write,io_read,io_write,memory_or_io;
    wire        mfhi,mflo,mfc0,mthi,mtlo,mtc0;
    wire        break,syscall,eret;
    wire        shift;
    wire        reserved_instruction;
    
    wire        memory_sign;                                       //从DATA RAM读出的数据进行零/符号扩展
    wire[1:0]   memory_data_width;                                 //从DATA RAM读写的粒度(00/01/11)
    wire[31:0]  data_from_memio;                                   //从MEM/IO选择单元取出的数据
    wire[31:0]  memory_read_data;                                  //从DATA RAM读出的数据
    wire[15:0]  io_read_data;                                      //从IO读出的数据
    wire[31:0]  write_data_latch;                                  //由MEM/IO选择单元锁存的待写数据
    
    wire[13:0]  rom_adr;                                           //指令寄存器的取址地址
    wire[31:0]  rom_dat;                                           //指令寄存器取出的数据
    
    wire        display_ctrl;
    wire        key_ctrl;
    wire[15:0]  io_read_data_key;
    wire        ctc_ctrl;
    wire        ctc0_output,ctc1_output;
    wire[15:0]  io_read_data_ctc;
    wire        pwm_ctrl;
    wire        pwm_output;
    wire        buzzer_ctrl;
    wire        wdt_ctrl;
    wire        wdt_output;
    wire        led_ctrl;
    wire        switch_ctrl;
    wire[15:0]  io_read_data_switch;
    
    wire        cause_write,status_write,epc_write;
    wire[31:0]  cause_write_data,status_write_data,epc_write_data;
    wire[31:0]  cause_read_data,status_read_data,epc_read_data;
    
    wire[31:0]  cp0_data;                                          //CP0寄存器中取出的数据
    wire[31:0]  pc_exception;                                      //中断处理程序入口地址/EPC
    
    wire[31:0]  forwarded_data_1,forwarded_data_2;                 //考虑数据转发后的read_data
    
    
    cpuclk cpuclk(
        .clk_in1(fpga_clk),                                         //100MHz
        .clk_out1(clock),                                           //CPU时钟(23MHz)
        .clk_out2(upg_clk)                                          //串口下载时钟(10MHz)
    );
    
    
    
    //流水寄存器相关连线
    wire[31:0]  if_id_pc_plus_4;
    wire[31:0]  if_id_pc_plus_4_latch;
    wire[31:0]  if_id_instruction;
    wire        if_id_i_type,if_id_jmp,if_id_jr,if_id_jal,if_id_jalr;
    wire        if_id_beq,if_id_bne,if_id_bgez,if_id_bgtz,if_id_blez,if_id_bltz,
                 if_id_bgezal,if_id_bltzal;
    wire        if_id_register_write;
    wire[4:0]   if_id_write_back_address;
    wire        if_id_memory_or_io;
    wire        if_id_mfhi,if_id_mflo,if_id_mfc0,if_id_mthi,if_id_mtlo,if_id_mtc0;
    wire        if_id_break,if_id_syscall,if_id_eret,if_id_reserved_instruction;
    wire        if_id_shift;
    wire[1:0]   if_id_alu_op;
    wire        if_id_alu_src;
    wire        if_id_memory_sign;
    wire[1:0]   if_id_memory_data_width;
    wire        if_id_l_type,if_id_s_type;
    wire        if_id_nonflush;
    
    wire[31:0]  id_ex_pc_plus_4;
    wire[31:0]  id_ex_pc_plus_4_latch;
    wire[31:0]  id_ex_pc_exception;
    wire[31:0]  id_ex_cp0_data;
    wire[31:0]  id_ex_instruction;
    wire[31:0]  id_ex_read_data_1;
    wire[31:0]  id_ex_read_data_2;
    wire[31:0]  id_ex_immediate_extend;
    wire        id_ex_i_type,id_ex_jmp,id_ex_jr,id_ex_jal,id_ex_jalr;
    wire        id_ex_beq,id_ex_bne,id_ex_bgez,id_ex_bgtz,id_ex_blez,id_ex_bltz,
                 id_ex_bgezal,id_ex_bltzal;
    wire        id_ex_register_write;
    wire[4:0]   id_ex_write_back_address;
    wire        id_ex_memory_or_io;
    wire        id_ex_mfhi,id_ex_mflo,id_ex_mthi,id_ex_mtlo;
    wire        id_ex_shift;
    wire[1:0]   id_ex_alu_op;
    wire        id_ex_alu_src;
    wire        id_ex_memory_sign;
    wire[1:0]   id_ex_memory_data_width;
    wire        id_ex_l_type,id_ex_s_type;
    wire        id_ex_nonflush;

    wire[31:0]  ex_mem_pc_add_result;
    wire[31:0]  ex_mem_pc_plus_4_latch;
    wire[31:0]  ex_mem_pc_exception;
    wire[31:0]  ex_mem_cp0_data;
    wire[31:0]  ex_mem_instruction;
    wire[31:0]  ex_mem_alu_result;
    wire[31:0]  ex_mem_read_data_rs;
    wire[31:0]  ex_mem_memory_or_io_write_data;
    wire        ex_mem_jmp,ex_mem_jr,ex_mem_jal,ex_mem_jalr;
    wire        ex_mem_beq,ex_mem_bne,ex_mem_bgez,ex_mem_bgtz,ex_mem_blez,ex_mem_bltz,
                 ex_mem_bgezal,ex_mem_bltzal;
    wire        ex_mem_zero,ex_mem_positive,ex_mem_negative;
    wire        ex_mem_register_write;
    wire[4:0]   ex_mem_write_back_address;
    wire        ex_mem_memory_or_io,ex_mem_memory_read,ex_mem_memory_write,
                 ex_mem_io_read,ex_mem_io_write;
    wire        ex_mem_memory_sign;
    wire[1:0]   ex_mem_memory_data_width;
    wire        ex_mem_nonflush;
    
    wire[31:0]  mem_wb_pc_plus_4_latch;
    wire[31:0]  mem_wb_cp0_data;
    wire[31:0]  mem_wb_alu_result;
    wire[31:0]  mem_wb_memory_or_io_read_data;
    wire        mem_wb_jal,mem_wb_jalr;
    wire        mem_wb_bgezal,mem_wb_bltzal;
    wire        mem_wb_memory_or_io;
    wire        mem_wb_zero,mem_wb_positive,mem_wb_negative;
    wire        mem_wb_register_write;
    wire[4:0]   mem_wb_write_back_address;
    
    
    
    //别看了，下面都是无聊的连线
    Ifetch ifetch(
        .Instruction(instruction),
        .Instruction_ex_mem(ex_mem_instruction),
        .PC_plus_4(pc_plus_4),
        .PC_plus_4_latch(pc_plus_4_latch),
        .PC_plus_4_id_ex(id_ex_pc_plus_4),
        .Nonflush_ex_mem(ex_mem_nonflush),
        
        .clock(clock),
        .reset(reset),
        .flush_pipeline(flush_pipeline),
        
        .Jr(ex_mem_jr),
        .Jalr(ex_mem_jalr),
        .Jmp(ex_mem_jmp),
        .Jal(ex_mem_jal),
        .Beq(ex_mem_beq),
        .Bne(ex_mem_bne),
        .Bgez(ex_mem_bgez),
        .Bgtz(ex_mem_bgtz),
        .Blez(ex_mem_blez),
        .Bltz(ex_mem_bltz),
        .Bgezal(ex_mem_bgezal),
        .Bltzal(ex_mem_bltzal),
        
        .Zero(ex_mem_zero),
        .Positive(ex_mem_positive),
        .Negative(ex_mem_negative),
        .PC_add_result(ex_mem_pc_add_result),
        .Read_data_rs(ex_mem_read_data_rs),
        
        .Rom_adr_o(rom_adr),
        .Jpadr(rom_dat),
        
        .PC_exception(ex_mem_pc_exception)
    );
    
    InstMEM instmem(
        .Rom_clk_i(clock),
        .Rom_adr_i(rom_adr),
        .Jpadr(rom_dat),
        
        .Upg_rst_i(upg_rst),
        .Upg_clk_i(upg_clk_o),
        .Upg_wen_i(upg_wen_o & !upg_adr_o[14]),
        .Upg_adr_i(upg_adr_o[13:0]),
        .Upg_dat_i(upg_dat_o),
        .Upg_done_i(upg_done_o)
    );
    
    Control control(
        .Instruction(instruction),
        
        .I_type(i_type),
        .L_type(l_type),
        .S_type(s_type),
        .Jmp(jmp),
        .Jr(jr),
        .Jal(jal),
        .Jalr(jalr),
        
        .Beq(beq),
        .Bne(bne),
        .Bgez(bgez),
        .Bgtz(bgtz),
        .Blez(blez),
        .Bltz(bltz),
        .Bgezal(bgezal),
        .Bltzal(bltzal),
        
        .Register_write(register_write),
        .Register_write_sel(register_write_sel),
        .Memory_or_IO(memory_or_io),
        .Memory_sign(memory_sign),
        .Memory_data_width(memory_data_width),
        
        .Mfhi(mfhi),
        .Mflo(mflo),
        .Mfc0(mfc0),
        .Mthi(mthi),
        .Mtlo(mtlo),
        .Mtc0(mtc0),
        
        .Shift(shift),
        
        .ALU_op(alu_op),
        .ALU_src(alu_src),
        
        .Break(break),
        .Syscall(syscall),
        .Eret(eret),
        
        .Reserved_instruction(reserved_instruction)
    );
                 
    IF_ID if_id(
        .clock(clock),
        .reset(reset | flush_pipeline),
        
        .PC_plus_4_in(pc_plus_4),
        .PC_plus_4_latch_in(pc_plus_4_latch),
        .Instruction_in(instruction),
        .I_type_in(i_type),
        .Jmp_in(jmp),
        .Jr_in(jr),
        .Jal_in(jal),
        .Jalr_in(jalr),
        .Beq_in(beq),
        .Bne_in(bne),
        .Bgez_in(bgez),
        .Bgtz_in(bgtz),
        .Blez_in(blez),
        .Bltz_in(bltz),
        .Bgezal_in(bgezal),
        .Bltzal_in(bltzal),
        .Register_write_in(register_write),
        .Write_back_address_in(register_write_sel),
        .Memory_or_IO_in(memory_or_io),
        .Mfhi_in(mfhi),
        .Mflo_in(mflo),
        .Mfc0_in(mfc0),
        .Mthi_in(mthi),
        .Mtlo_in(mtlo),
        .Mtc0_in(mtc0),
        .Break_in(break),
        .Syscall_in(syscall),
        .Eret_in(eret),
        .Reserved_instruction_in(reserved_instruction),
        .Shift_in(shift),
        .ALU_op_in(alu_op),
        .ALU_src_in(alu_src),
        .Memory_sign_in(memory_sign),
        .Memory_data_width_in(memory_data_width),
        .L_type_in(l_type),
        .S_type_in(s_type),
        
        .PC_plus_4_out(if_id_pc_plus_4),
        .PC_plus_4_latch_out(if_id_pc_plus_4_latch),
        .Instruction_out(if_id_instruction),
        .I_type_out(if_id_i_type),
        .Jmp_out(if_id_jmp),
        .Jr_out(if_id_jr),
        .Jal_out(if_id_jal),
        .Jalr_out(if_id_jalr),
        .Beq_out(if_id_beq),
        .Bne_out(if_id_bne),
        .Bgez_out(if_id_bgez),
        .Bgtz_out(if_id_bgtz),
        .Blez_out(if_id_blez),
        .Bltz_out(if_id_bltz),
        .Bgezal_out(if_id_bgezal),
        .Bltzal_out(if_id_bltzal),
        .Register_write_out(if_id_register_write),
        .Write_back_address_out(if_id_write_back_address),
        .Memory_or_IO_out(if_id_memory_or_io),
        .Mfhi_out(if_id_mfhi),
        .Mflo_out(if_id_mflo),
        .Mfc0_out(if_id_mfc0),
        .Mthi_out(if_id_mthi),
        .Mtlo_out(if_id_mtlo),
        .Mtc0_out(if_id_mtc0),
        .Break_out(if_id_break),
        .Syscall_out(if_id_syscall),
        .Eret_out(if_id_eret),
        .Reserved_instruction_out(if_id_reserved_instruction),
        .Shift_out(if_id_shift),
        .ALU_op_out(if_id_alu_op),
        .ALU_src_out(if_id_alu_src),
        .Memory_sign_out(if_id_memory_sign),
        .Memory_data_width_out(if_id_memory_data_width),
        .L_type_out(if_id_l_type),
        .S_type_out(if_id_s_type),
        .Nonflush_out(if_id_nonflush)
    );
    

    
    Idecode idecode(
        .clock(clock),
        .reset(reset),
        
        .Instruction(if_id_instruction),
        .Received_data(mem_wb_memory_or_io_read_data),
        .PC_plus_4(if_id_pc_plus_4),
        .PC_plus_4_latch(mem_wb_pc_plus_4_latch),
        .ALU_result(mem_wb_alu_result),
        .CP0_data_latch(mem_wb_cp0_data),
        
        .Jal(mem_wb_jal),
        .Jalr(mem_wb_jalr),
        .Bgezal(mem_wb_bgezal),
        .Bltzal(mem_wb_bltzal),
        
        .Memory_or_IO(mem_wb_memory_or_io),
        .Register_write(mem_wb_register_write),
        .Write_back_address(mem_wb_write_back_address),
        
        .Read_data_1(read_data_1),
        .Read_data_2(read_data_2),
        .Immediate_extend(immediate_extend),
        
        .Mfc0(if_id_mfc0),
        .Mtc0(if_id_mtc0),
        
        .Break(if_id_break),
        .Syscall(if_id_syscall),
        .Eret(if_id_eret),
        
        .Positive(mem_wb_positive),
        .Negative(mem_wb_negative),
        
        .Overflow(overflow),
        .Divide_zero(divide_zero),
        .Reserved_instruction(if_id_reserved_instruction),
        
        .Cause_write(cause_write),
        .Cause_write_data(cause_write_data),
        .Cause_read_data(cause_read_data),
        
        .Status_write(status_write),
        .Status_write_data(status_write_data),
        .Status_read_data(status_read_data),
        
        .EPC_write(epc_write),
        .EPC_write_data(epc_write_data),
        .EPC_read_data(epc_read_data),
        
        .CP0_data(cp0_data),
        .PC_exception(pc_exception)
    );
    
    CP0 cp0(
        .clock(clock),
        .reset(reset),
        
        .Cause_write(cause_write),
        .Cause_write_data(cause_write_data),
        .Cause_read_data(cause_read_data),
        
        .Status_write(status_write),
        .Status_write_data(status_write_data),
        .Status_read_data(status_read_data),
        
        .EPC_write(epc_write),
        .EPC_write_data(epc_write_data),
        .EPC_read_data(epc_read_data)
    );
    
    ID_EX id_ex(
        .clock(clock),
        .reset(reset | flush_pipeline),
        
        .PC_plus_4_in(if_id_pc_plus_4),
        .PC_plus_4_latch_in(if_id_pc_plus_4_latch),
        .PC_exception_in(pc_exception),
        .CP0_data_in(cp0_data),
        .Instruction_in(if_id_instruction),
        .Read_data_1_in(read_data_1),
        .Read_data_2_in(read_data_2),
        .Immediate_extend_in(immediate_extend),
        .I_type_in(if_id_i_type),
        .Jmp_in(if_id_jmp),
        .Jr_in(if_id_jr),
        .Jal_in(if_id_jal),
        .Jalr_in(if_id_jalr),
        .Beq_in(if_id_beq),
        .Bne_in(if_id_bne),
        .Bgez_in(if_id_bgez),
        .Bgtz_in(if_id_bgtz),
        .Blez_in(if_id_blez),
        .Bltz_in(if_id_bltz),
        .Bgezal_in(if_id_bgezal),
        .Bltzal_in(if_id_bltzal),
        .Register_write_in(if_id_register_write),
        .Write_back_address_in(if_id_write_back_address),
        .Memory_or_IO_in(if_id_memory_or_io),
        .Mfhi_in(if_id_mfhi),
        .Mflo_in(if_id_mflo),
        .Mthi_in(if_id_mthi),
        .Mtlo_in(if_id_mtlo),
        .Shift_in(if_id_shift),
        .ALU_op_in(if_id_alu_op),
        .ALU_src_in(if_id_alu_src),
        .Memory_sign_in(if_id_memory_sign),
        .Memory_data_width_in(if_id_memory_data_width),
        .L_type_in(if_id_l_type),
        .S_type_in(if_id_s_type),
        .Nonflush_in(if_id_nonflush),
        
        .PC_plus_4_out(id_ex_pc_plus_4),
        .PC_plus_4_latch_out(id_ex_pc_plus_4_latch),
        .PC_exception_out(id_ex_pc_exception),
        .CP0_data_out(id_ex_cp0_data),
        .Instruction_out(id_ex_instruction),
        .Read_data_1_out(id_ex_read_data_1),
        .Read_data_2_out(id_ex_read_data_2),
        .Immediate_extend_out(id_ex_immediate_extend),
        .I_type_out(id_ex_i_type),
        .Jmp_out(id_ex_jmp),
        .Jr_out(id_ex_jr),
        .Jal_out(id_ex_jal),
        .Jalr_out(id_ex_jalr),
        .Beq_out(id_ex_beq),
        .Bne_out(id_ex_bne),
        .Bgez_out(id_ex_bgez),
        .Bgtz_out(id_ex_bgtz),
        .Blez_out(id_ex_blez),
        .Bltz_out(id_ex_bltz),
        .Bgezal_out(id_ex_bgezal),
        .Bltzal_out(id_ex_bltzal),
        .Register_write_out(id_ex_register_write),
        .Write_back_address_out(id_ex_write_back_address),
        .Memory_or_IO_out(id_ex_memory_or_io),
        .Mfhi_out(id_ex_mfhi),
        .Mflo_out(id_ex_mflo),
        .Mthi_out(id_ex_mthi),
        .Mtlo_out(id_ex_mtlo),
        .Shift_out(id_ex_shift),
        .ALU_op_out(id_ex_alu_op),
        .ALU_src_out(id_ex_alu_src),
        .Memory_sign_out(id_ex_memory_sign),
        .Memory_data_width_out(id_ex_memory_data_width),
        .L_type_out(id_ex_l_type),
        .S_type_out(id_ex_s_type),
        .Nonflush_out(id_ex_nonflush)
    );
    
    
    
    Execute execute(
        .clock(clock),
        .Instruction(id_ex_instruction),
        
        .ALU_src(id_ex_alu_src),
        .ALU_op(id_ex_alu_op),
        
        .Shift(id_ex_shift),
        .I_type(id_ex_i_type),
        .Read_data_1(id_ex_read_data_1),
        .Read_data_2(id_ex_read_data_2),
        .Immediate_extend(id_ex_immediate_extend),
        .PC_plus_4(id_ex_pc_plus_4),
        
        .ALU_result(alu_result),
        .PC_add_result(pc_add_result),
        .Zero(zero),
        .Positive(positive),
        .Negative(negative),
        .Overflow(overflow),
        .Divide_zero(divide_zero),
        
        .Mfhi(id_ex_mfhi),
        .Mflo(id_ex_mflo),
        .Mthi(id_ex_mthi),
        .Mtlo(id_ex_mtlo),
        
        .L_type(id_ex_l_type),
        .S_type(id_ex_s_type),
        
        .Memory_read(memory_read),
        .Memory_write(memory_write),
        .IO_read(io_read),
        .IO_write(io_write),
        
        .Register_write_ex_mem(ex_mem_register_write),
        .Write_back_address_ex_mem(ex_mem_write_back_address),
        .Register_write_mem_wb(mem_wb_register_write),
        .Write_back_address_mem_wb(mem_wb_write_back_address),
        .Memory_or_IO_mem_wb(mem_wb_memory_or_io),
        
        .ALU_result_ex_mem(ex_mem_alu_result),
        .ALU_result_mem_wb(mem_wb_alu_result),
        .Read_data_mem_wb(mem_wb_memory_or_io_read_data),
        
        .Forwarded_data_1(forwarded_data_1),
        .Forwarded_data_2(forwarded_data_2)
    );
    
    EX_MEM ex_mem(
        .clock(clock),
        .reset(reset | flush_pipeline),
        
        .PC_add_result_in(pc_add_result),
        .PC_plus_4_latch_in(id_ex_pc_plus_4_latch),
        .PC_exception_in(id_ex_pc_exception),
        .CP0_data_in(id_ex_cp0_data),
        .Instruction_in(id_ex_instruction),
        .ALU_result_in(alu_result),
        .Read_data_rs_in(forwarded_data_1),
        .Memory_or_IO_write_data_in(forwarded_data_2),
        .Jmp_in(id_ex_jmp),
        .Jr_in(id_ex_jr),
        .Jal_in(id_ex_jal),
        .Jalr_in(id_ex_jalr),
        .Beq_in(id_ex_beq),
        .Bne_in(id_ex_bne),
        .Bgez_in(id_ex_bgez),
        .Bgtz_in(id_ex_bgtz),
        .Blez_in(id_ex_blez),
        .Bltz_in(id_ex_bltz),
        .Bgezal_in(id_ex_bgezal),
        .Bltzal_in(id_ex_bltzal),
        .Zero_in(zero),
        .Positive_in(positive),
        .Negative_in(negative),
        .Register_write_in(id_ex_register_write),
        .Write_back_address_in(id_ex_write_back_address),
        .Memory_or_IO_in(id_ex_memory_or_io),
        .Memory_read_in(memory_read),
        .Memory_write_in(memory_write),
        .IO_read_in(io_read),
        .IO_write_in(io_write),
        .Memory_sign_in(id_ex_memory_sign),
        .Memory_data_width_in(id_ex_memory_data_width),
        .Nonflush_in(id_ex_nonflush),
        
        .PC_add_result_out(ex_mem_pc_add_result),
        .PC_plus_4_latch_out(ex_mem_pc_plus_4_latch),
        .PC_exception_out(ex_mem_pc_exception),
        .CP0_data_out(ex_mem_cp0_data),
        .Instruction_out(ex_mem_instruction),
        .ALU_result_out(ex_mem_alu_result),
        .Read_data_rs_out(ex_mem_read_data_rs),
        .Memory_or_IO_write_data_out(ex_mem_memory_or_io_write_data),
        .Jmp_out(ex_mem_jmp),
        .Jr_out(ex_mem_jr),
        .Jal_out(ex_mem_jal),
        .Jalr_out(ex_mem_jalr),
        .Beq_out(ex_mem_beq),
        .Bne_out(ex_mem_bne),
        .Bgez_out(ex_mem_bgez),
        .Bgtz_out(ex_mem_bgtz),
        .Blez_out(ex_mem_blez),
        .Bltz_out(ex_mem_bltz),
        .Bgezal_out(ex_mem_bgezal),
        .Bltzal_out(ex_mem_bltzal),
        .Zero_out(ex_mem_zero),
        .Positive_out(ex_mem_positive),
        .Negative_out(ex_mem_negative),
        .Register_write_out(ex_mem_register_write),
        .Write_back_address_out(ex_mem_write_back_address),
        .Memory_or_IO_out(ex_mem_memory_or_io),
        .Memory_read_out(ex_mem_memory_read),
        .Memory_write_out(ex_mem_memory_write),
        .IO_read_out(ex_mem_io_read),
        .IO_write_out(ex_mem_io_write),
        .Memory_sign_out(ex_mem_memory_sign),
        .Memory_data_width_out(ex_mem_memory_data_width),
        .Nonflush_out(ex_mem_nonflush)
    );
    
    
    
    MEMorIO memorio(
        .Address(ex_mem_alu_result),
        .Memory_read(ex_mem_memory_read),
        .Memory_write(ex_mem_memory_write),
        .IO_read(ex_mem_io_read),
        .IO_write(ex_mem_io_write),
        .Memory_sign(ex_mem_memory_sign),
        .Memory_data_width(ex_mem_memory_data_width),
        .Memory_read_data(memory_read_data),
        .IO_read_data(io_read_data),
        .Write_data_in(ex_mem_memory_or_io_write_data),
        .Read_data(data_from_memio),                                //从MEM/IO读出的数据
        .Write_data_latch(write_data_latch),
        
        .Display_ctrl(display_ctrl),
        .Key_ctrl(key_ctrl),
        .CTC_ctrl(ctc_ctrl),
        .PWM_ctrl(pwm_ctrl),
        .Buzzer_ctrl(buzzer_ctrl),
        .WDT_ctrl(wdt_ctrl),
        .LED_ctrl(led_ctrl),
        .Switch_ctrl(switch_ctrl)
    );
    
    MultiIORead multiioread(
        .clock(clock),
        .reset(reset),
        
        .IO_read(ex_mem_io_read),
        .IO_read_data(io_read_data),
        
        .Key_ctrl(key_ctrl),
        .IO_read_data_key(io_read_data_key),
        
        .Switch_ctrl(switch_ctrl),
        .IO_read_data_switch(io_read_data_switch),
        
        .CTC_ctrl(ctc_ctrl),
        .IO_read_data_ctc(io_read_data_ctc)
    );
    
    DataMEM datamem(
        .clock(clock),
        .Memory_write(memory_write),
        .Address(ex_mem_alu_result),
        .Read_data(memory_read_data),
        .Write_data(write_data_latch),
        
        .Upg_rst_i(upg_rst),
        .Upg_clk_i(upg_clk_o),
        .Upg_wen_i(upg_wen_o & upg_adr_o[14]),
        .Upg_adr_i(upg_adr_o[13:0]),
        .Upg_dat_i(upg_dat_o),
        .Upg_done_i(upg_done_o)
    );
    
    output[23:0]    LED2N4;
    LED led(
        .clock(clock),
        .reset(reset),
        .Write_enable(led_ctrl),
        .Select(1'b1),
        .Address(ex_mem_alu_result[1:0]),
        .Write_data_in(write_data_latch[15:0]),
        .Write_data_out(LED2N4)
    );
    
    input[23:0]     Switch2N4;
    Switch switch(
        .clock(clock),
        .reset(reset),
        .Read_enable(switch_ctrl),
        .Select(1'b1),
        .Address(ex_mem_alu_result[1:0]),
        .Read_data_in(Switch2N4),
        .Read_data_out(io_read_data_switch)
    );
    
    output[3:0]     KeyRow0N4;
    input[3:0]      KeyColumn0N4;
    Key key(
        .clock(clock),
        .reset(reset),
        .Read_enable(key_ctrl),
        .Select(1'b1),
        .Address(ex_mem_alu_result[1:0]),
        .Row(KeyRow0N4),
        .Column(KeyColumn0N4),
        .Read_data_out(io_read_data_key)
    );
    
    output[7:0]     DisplayEnable0N8;
    output[7:0]     DisplayValue0N8;
    Display display(
        .clock(clock),
        .reset(reset),
        .Write_enable(display_ctrl),
        .Select(1'b1),
        .Address(ex_mem_alu_result[2:0]),
        .Write_data_in(write_data_latch[15:0]),
        .Enable(DisplayEnable0N8),
        .Value(DisplayValue0N8)
    );
    
    PWM pwm(
        .clock(clock),
        .reset(reset),
        .Write_enable(pwm_ctrl),
        .Select(1'b1),
        .Address(ex_mem_alu_result[2:0]),
        .Write_data_in(write_data_latch[15:0]),
        .PWM_output(pwm_output)
    );
    
    CTC ctc(
        .clock(clock),
        .reset(reset),
        .Read_enable(ex_mem_io_read & ctc_ctrl),
        .Write_enable(ex_mem_io_write & ctc_ctrl),
        .Select(1'b1),
        .Address(ex_mem_alu_result[2:0]),
        .Write_data_in(write_data_latch[15:0]),
        .Read_data_out(io_read_data_ctc),
        .CTC0_output(ctc0_output),
        .CTC1_output(ctc1_output),
        
        .Pulse0_in(),
        .Pulse1_in()
    );
    
    WDT wdt(
        .clock(clock),
        .reset(reset),
        .Write_enable(wdt_ctrl),
        .Select(1'b1),
        .Write_data_in(write_data_latch[15:0]),
        .WDT_output(wdt_output)
    );
    
    output      Buzzer0N1;
    Buzzer buzzer(
        .clock(clock),
        .reset(reset),
        .Write_enable(buzzer_ctrl),
        .Select(1'b1),
        .Address(ex_mem_alu_result[1:0]),
        .Write_data_in(write_data_latch[15:0]),
        .Buzzer_output(Buzzer0N1)
    );
    
    MEM_WB mem_wb(
        .clock(clock),
        .reset(reset),
        
        .PC_plus_4_latch_in(ex_mem_pc_plus_4_latch),
        .CP0_data_in(ex_mem_cp0_data),
        .ALU_result_in(ex_mem_alu_result),
        .Memory_or_IO_read_data_in(data_from_memio),
        .Jal_in(ex_mem_jal),
        .Jalr_in(ex_mem_jalr),
        .Bgezal_in(ex_mem_bgezal),
        .Bltzal_in(ex_mem_bltzal),
        .Memory_or_IO_in(ex_mem_memory_or_io),
        .Zero_in(ex_mem_zero),
        .Positive_in(ex_mem_positive),
        .Negative_in(ex_mem_negative),
        .Register_write_in(ex_mem_register_write),
        .Write_back_address_in(ex_mem_write_back_address),
        
        .PC_plus_4_latch_out(mem_wb_pc_plus_4_latch),
        .CP0_data_out(mem_wb_cp0_data),
        .ALU_result_out(mem_wb_alu_result),
        .Memory_or_IO_read_data_out(mem_wb_memory_or_io_read_data),
        .Jal_out(mem_wb_jal),
        .Jalr_out(mem_wb_jalr),
        .Bgezal_out(mem_wb_bgezal),
        .Bltzal_out(mem_wb_bltzal),
        .Memory_or_IO_out(mem_wb_memory_or_io),
        .Zero_out(mem_wb_zero),
        .Positive_out(mem_wb_positive),
        .Negative_out(mem_wb_negative),
        .Register_write_out(mem_wb_register_write),
        .Write_back_address_out(mem_wb_write_back_address)
    );
    
endmodule
