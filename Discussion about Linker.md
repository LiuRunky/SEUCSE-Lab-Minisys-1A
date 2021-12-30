<h3>链接器相关</h3>

需要链接的程序包括：BIOS，跳转程序，应用程序



汇编器语法分析产生结果：

data_output.txt

```
\\segment offset
#segment_offset
\\variable definition in format of [name, end_offset]
#name #end_offset
\\data storage info in format of [value, width, offset]
#value #width #offset
\\end of output
```

code_output.txt

```
\\segment offset
#segment_offset
\\variable definition in format of [name, end_offset]
#name #end_offset
\\code storage info in format of [code]
#formatted_MIPS_code
\\end of output
```



汇编翻译器需要的格式：

data.txt

```
\\variable definition
#name #start_offset
\\code start from here
.text 0
#formatted_MIPS_code
```



链接器要做的工作：

1. 使用汇编语法分析扫过所有 xx.asm，产生 xx_data_output.txt, xx_code_output.txt 等分析文件。**[OK]**
2. 将 bios 和 main 的优先级提前，重新排列文件列表。**[OK]**
3. 对于 xx_data_output.txt，自动排 offset，并对于所有变量加上文件前缀，直接生成 dmem32.coe 文件。**[变量加前缀在语法分析完成]** **[dmem32.coe生成完成，貌似没错]**
4. 对于 xx_code_output.txt，把标签和变量加上文件前缀，并重新排 offset，规则是 BIOS 为 0x0000，跳转程序为 0x0100，之后的应用程序为 0x0200, 0x0300... 需要在生成的时候将特殊的两个程序重新设置优先级。对于一些特殊的程序（比如中断处理程序）手动赋予了 offset，则不对于其进行变动。**[变量/标签加前缀在语法分析完成]**
5. 根据 offset 生成所有应用程序的代码段，空白部分用 nop 占位。**[OK]**