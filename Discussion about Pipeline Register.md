<h3>关于流水寄存器的讨论</h3>

<h4>1. 流水寄存器的基本原理</h4>

对于简单的两个模块，如果在初始时第一个模块值为 value，第二个模块值为 undefined。

![simple_before](https://github.com/LiuRunky/SEUCSE-Lab-Minisys-1A/blob/main/img/simple_before.png)

如果在其中添加流水寄存器，我们希望在一个时钟之后，第一个模块的值为 value'，流水寄存器与第二个模块的值为 value。

![simple_after](https://github.com/LiuRunky/SEUCSE-Lab-Minisys-1A/blob/main/img/simple_after.png)

这在 Vivado 中是很容易实现的。假如 sensitivity list 为时钟的 posedge 或 negedge（我选择了 negedge），那么在触发的时刻，可以认为所有寄存器的值是不变的，于是流水寄存器可以在第一个模块的值变为 value' 之前获得其原本的值 value。

在 MOOC 课件中，提到了**访存需要错开半个时钟**，也是因为类似的道理：如果在流水寄存器更新的同时访存，那么访问到的地址是流水寄存器**更新前**的地址，导致并没有完成**这一个指令周期**的指令。与之对应的是一般的运算（比如ALU的加减逻辑运算等），我们可以认为处理运算在**一个瞬间**完成，于是在**这一个指令周期**的运算结果对应的就是流水寄存器**更新后**的指令。

<h4>2. 多周期 CPU 中的流水寄存器</h4>

考虑 negedge 前的时刻，流水寄存器的情况如下：

![CPU_before](https://github.com/LiuRunky/SEUCSE-Lab-Minisys-1A/blob/main/img/CPU_before.png)

此时需要根据 EX/MEM 流水寄存器中的结果（比如 beq/j 等指令）来推断是否需要清空流水，所以我们认为 EX/MEM 及之后所有部分的 PC 值是正确的，即流水线中 PC-12 及之前的 PC 都是正确的。

假设根据 EX/MEM 重新计算后的 PC 为 PC'，那么在一个 negedge 后，流水寄存器的情况如下：

![CPU_after](https://github.com/LiuRunky/SEUCSE-Lab-Minisys-1A/blob/main/img/CPU_after.png)

根据之前的讨论，**PC' / PC-12 是正确的，而 PC ~ PC-8 都不一定正确**，所以我们需要保证能够在下一个 negedge 之前得出清空流水线的信号 flush_pipeline，可能被清空的流水寄存器包括 **IF/ID，ID/EX 以及 EX/MEM**。

如果 flush_pipeline 信号在 negedge 给出，那么在 negedge 的时刻 flush_pipeline = 0，则 PC-8 必然进入 MEM/IO 模块，可能导致错误的读写。而根据 flush_pipeline 的需求，其所需要的所有信号（包括 ID 中的 PC 及 EX/MEM 中的各种信号）在 posedge 也是稳定的，所以可以考虑**在 posedge 更新 flush_pipeline 信号的值**，而真正的 PC 修改仍然保留到 negedge。

<h4> 3. 判断清空流水线的条件</h4>

假如不做分支预测，认为顺序执行的话，可以认为 PC' = PC+4，那么考虑与最后一个不安全的 PC 进行比较，即 ID/EX 中的 PC_plus_4。根据上图，在 negedge 之前，ID/EX_PC_plus_4 = PC-4 （注意这里有一个 plus_4），那么可以很轻易地写出条件 PC' != ID/EX_PC_plus_4 + 8。

不过在测试中，遇到了如下 cornercase：

```
...
	j label_name
	instruction_1
	instruction_2
	instruction_3
label_name:
	instruction_4
```

如果标上序号，各流水寄存器中指令的位置为：

```
...
	j label_name	[EX/MEM]
	instruction_1	[ID/EX]
	instruction_2	[IF/ID]
	instruction_3	[PC]
label_name:
	instruction_4	[PC']
```

这里的 PC'，既是顺序执行的结果，又是跳转的结果。但是两者的区别在于，如果顺序执行，那么 instruction_1 ~ instruction_3 均被执行；而在跳转的时候，这三条指令因为清空流水线而被忽略，而这正是我们需要的。

于是 PC' != ID/EX_PC_plus_4 + 8 的判断条件对于与跳转位置间隔 3 的情况时就失效了。暂时想的紧急补救办法是，对于每个流水寄存器增设 1bit 的 Nonflush 位，记录该流水寄存器是否被清空（我在情况流水线时默认将指令清成 32'h0000_0000，不过这也是我定义的 nop，所以需要加以区分）。假如 EX/MEM 未被清空，且指令产生跳转，就强制令 flush_pipeline = 1。简单来说就是有跳转就清空。

对于动态分支预测，暂时没仔细想，不知道能不能在此基础上简单实现扩展。
