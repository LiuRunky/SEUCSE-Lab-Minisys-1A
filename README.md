# SEUCSE-Lab-Minisys-1A

![avatar](https://gravatar.loli.net/avatar/21045a9dba2e8c4b064b00dab8254be0?d=mm&s=256)



# 概述

CPU:

采用五级流水：IF, ID, EX, MEM, WB，其中规定所有PC值修改在MEM阶段，所有寄存器组修改在WB阶段

为了方便调试，指令寄存器programrom为1x32bit

数据冒险采用转发法，阻塞需要通过软件辅助实现；分支默认顺序执行

汇编器:

只负责词法语法分析，主要使用Python ply包提供的lex / yacc工具



# 一些时间线

2021.10.11 完成基本要求，上板验证简单程序运行正确

2021.10.14 汇编器词法语法分析基本完成



# 参考材料

CPU:

[MOOC:东南大学-计算机系统综合设计](https://www.icourse163.org/course/SEU-1003566002)

计算机组成与设计:硬件/软件接口, David A. Patterson, John L. Hennessy

汇编器:

[Python PLY official documentation](http://www.dabeaz.com/ply/ply.html)



# 声明

项目仅用于存档，可以作为参考，请勿直接复制项目文件
