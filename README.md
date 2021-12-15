# SEUCSE-Lab-Minisys-1A

![avatar](https://gravatar.loli.net/avatar/21045a9dba2e8c4b064b00dab8254be0?d=mm&s=256)

综合课程设计中，我个人做的部分的存档，按照基础要求进行实现



# 概述

**CPU:**

采用五级流水：IF, ID, EX, MEM, WB，其中规定所有PC值修改在MEM阶段，所有寄存器组修改在WB阶段

为了方便调试，指令寄存器programrom和数据寄存器ram均为1x32bit，近期会将ram改到4x8bit

数据冒险采用转发法，阻塞需要通过软件辅助实现；分支默认顺序执行

**汇编器:**

负责词法语法分析，主要使用Python ply包提供的lex / yacc工具

在进行汇编代码语法检查的基础上，能够获得汇编代码数据段的布局，同时对于宏指令进行展开



# 一些时间线

2021.10.11 完成基本要求，上板验证简单程序运行正确

2021.10.14 汇编器词法语法分析基本完成

2021.11.04 加强了汇编器的功能，基本完成与链接器、汇编翻译器的衔接

2021.12.16 根据综合应用检查硬件，找到几个锅，对于这些问题专门说明了一下，详见"Discussion about Pipeline Register.md"



# 参考材料

**CPU:**

[MOOC:东南大学-计算机系统综合设计](https://www.icourse163.org/course/SEU-1003566002)

计算机组成与设计:硬件/软件接口, David A. Patterson, John L. Hennessy

**接口：**

计算机系统综合课程设计, 杨全胜 （只能参考框架，书中代码的细节问题很多）

**汇编器:**

[Python PLY official documentation](http://www.dabeaz.com/ply/ply.html)

[我的翻译+整理版本](https://www.cnblogs.com/LiuRunky/p/Python_Ply_Tutorial.html)



# 声明

项目仅用于存档，可以作为参考，请勿直接复制项目文件
