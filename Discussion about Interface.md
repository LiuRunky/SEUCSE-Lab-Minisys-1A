<h3>数码管Display</h3>

32位数值，8位mask，**低电平为有效**

需要显示数字时，每次只能拉高一位并显示，故<font color='red'>**需要考虑通过硬件还是软件实现**</font>

1. 刷新频率要降
2. 刷新频率与更新频率不同
3. 赋值data的时序



<h3>4x4键盘Key</h3>

1. 需要扫描
2. **防抖动**



<h3>定时/计数器CTC</h3>

看一下MOOC，规定有点多。可以对于同一端口读或者写。

1. 初始化mode, status, counter

2. 对于初始状态（counter = 16'h0000）需要将init送进counter

   解决方案：直接判断counter==16'h0000应该就可以了，具体见注释

3. 在读counter的时候，stat\*\_0的更新需要在clock上升沿，而stat\*\_0更新status*在read_enable时就完成：**sensitivity list里面只加上stat\*\_0即可**



<h3>PWM</h3>

没啥问题，和LED一样。**使能寄存器需要看一下MOOC**。

抄就完事了。



<h3>看门狗WDT</h3>

抄就完事了，大概用不上？



<h3>蜂鸣器</h3>

D大调

do 9560H

re 8517H

mi 768DH

fa 6FEDH

so 63C6H

la 58C7H

ti 4F27H

![image-20211214171803700](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20211214171803700.png)

应该取0000_8517，但慢了

暂时先把clk = !clock改成clk = clock了，也和IO读写统一







<h3>Display</h3>

0xFC00: 16bit，写低位 4 个数码管的值

0xFC02: 16bit，写高位 4 个数码管的值

0xFC04: 16bit，低 8bit 有效，写数码管的有效信号（0 有效，1 无效，默认 0000_0000）

真正使用时写接口的顺序任意



<h3>Key</h3>

0xFC10: 16bit，低 4bit 有效，读按下的键的值（0 ~ F）

0xFC12: 16bit，低 1bit 有效，读是否有键被按下（0 无键，1 有键）

真正使用时，需要先 lw 0xFC12，当不为 0 时才 lw 0xFC10

当一个键被按下而没有抬起时，在读取键值之后认为没有键被按下，直到下一个键被按下才认为有键



<h3>CTC</h3>

0xFC20: 16bit，写 CTC0 方式寄存器（定时 or 计数，重复 or 无重复），读 CTC0 状态并清零

0xFC22: 16bit，写 CTC1 方式寄存器（定时 or 计数，重复 or 无重复），读 CTC1 状态并清零

0xFC24: 16bit，写 CTC0 初始值寄存器，读 CTC0 计数值

0xFC26: 16bit，写 CTC1 初始值寄存器，读 CTC1 计数值

真正使用时，需要先 sw 0xFC20 / 0xFC22，再 sw 0xFC24 / 0xFC26，因为做前者时会禁止计数，做后者时才会重新允许计数

读操作没有上述限制



<h3>PWM</h3>

0xFC30: 16bit，写最大值寄存器

0xFC32: 16bit，写阈值寄存器

0xFC34: 16bit，低 1bit 有效，写标志寄存器（0 无效，1 有效）

真正使用时，需要先分别 sw 0xFC30 与 0xFC34（顺序任意），最后 sw 0xFC34 允许计数



<h3>Buzzer</h3>

0xFC40: 16bit，写蜂鸣器计数最大值 maximum（主时钟 20MHz，真实频率为 40M / maximum）

0xFC42: 16bit，低 1bit 有效，写蜂鸣器状态（0 无效，1 有效）

真正使用时，需要先 sw 0xFC42，再 sw 0xFC40；使用结束后需要 sw 0xFC42 关掉蜂鸣器



<h3>WDT</h3>

0xFC50: 16bit，实际均无效，只要写该端口就会重置计数

真正使用时，推荐 sw \$zero, 0xFC50(​\$zero) 来避免产生任何影响



<h3>LED</h3>

0xFC60: 16bit，其中低 8bit 写绿灯，高 8bit 写黄灯（实验板上绿灯 #7 坏了）

0xFC62: 16bit，其中低 8bit 有效，写红灯



<h3>Switch</h3>

0xFC70: 16bit，读前 16 个拨码开关

0xFC72: 16bit，其中低 8bit 有效，读后 8 个拨码开关