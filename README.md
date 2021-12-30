# SEUCSE-Lab-Minisys-1A

![avatar](https://gravatar.loli.net/avatar/21045a9dba2e8c4b064b00dab8254be0?d=mm&s=256)

综合课程设计中，我个人做的部分的存档，按照基础要求进行实现



# 概述

**CPU:**

采用五级流水：IF, ID, EX, MEM, WB，其中规定所有 PC 值修改在 MEM 阶段，所有寄存器组修改在 WB 阶段

~~为了方便调试，指令寄存器 programrom 和数据寄存器 ram 均为 1x32bit，近期会将 ram 改到 4x8bit~~ 已完成

数据冒险采用转发法，阻塞需要通过软件辅助实现；分支默认顺序执行

**接口:**

负责所有接口设计，除了 MOOC 中包括的 LED, Switch 之外，额外设计了 Display, Key, CTC, Buzzer, PWM, WDT 模块。

除了 Key 在除颤方面不是很完善之外，所有接口经过测试应该都没有问题。具体地址和读写时的说明详见 "Discussion about Interface.md"

**汇编器:**

负责词法语法分析，主要使用 Python ply 包提供的 lex / yacc 工具

在进行汇编代码语法检查的基础上，能够获得汇编代码数据段的布局，同时对于宏指令进行展开，将分析结果传给链接器

**链接器:**

实现 BIOS、应用程序选择程序 main 及综合应用的链接，各文件的输入输出格式分析及实现方法在文档中有具体说明

对于 data 段保证将不同程序间进行强制对齐；对于 text 段做了比较简单的假设（命令数不超过 256），可能需要后续修改，再议

汇编器及链接器的数据传递形式详见 "Discussion about Linker.md"


# 一些时间线

2021.10.11 完成基本要求，上板验证简单程序运行正确

2021.10.14 汇编器词法语法分析基本完成

2021.11.04 加强了汇编器的功能，基本完成与链接器、汇编翻译器的衔接

2021.12.16 根据综合应用检查硬件，找到几个锅，对于这些问题专门说明了一下，详见 "Discussion about Pipeline Register.md"

2021.12.16 接口基本完成

2021.12.30 链接器（+组员的汇编器）调试完成，目前链接的方法详见 "Discussion about Linker.md"


# 参考材料

**CPU:**

[MOOC:东南大学-计算机系统综合设计](https://www.icourse163.org/course/SEU-1003566002)

计算机组成与设计:硬件/软件接口, David A. Patterson, John L. Hennessy

**接口：**

计算机系统综合课程设计, 杨全胜 （只能参考框架，书中代码的细节问题很多）

**汇编器:**

[Python PLY official documentation](http://www.dabeaz.com/ply/ply.html)

[我的翻译+整理版本](https://www.cnblogs.com/LiuRunky/p/Python_Ply_Tutorial.html)

**链接器:**

无，纯脑补


# 声明

项目仅用于存档，可以作为参考，请勿直接复制项目文件
