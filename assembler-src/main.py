import os
import math
from ply import lex, yacc

tokens = (
    'DATA', 'TEXT',
    'BYTE', 'HALF', 'WORD', 'FLOAT', 'DOUBLE', 'ASCII', 'ASCIIZ',
    'VALUE', "STRING",
    'REG', 'OFFSET',
    'NOP', 'ALIGN', 'SPACE', 'COMMA', 'COLON', 'ENDL',
    'RCOM', 'ICOM', 'JCOM', 'PCOM',
    'LWICOM', 'DRCOM', 'BZICOM', 'SLLRCOM',
    'SICOM', 'BICOM', 'SRCOM', 'JBCOM',
    'BREAK', 'SYSCALL', 'ERET',
    'IDNAME', 'PIDNAME',
    'COMMENT'
)


# when state = 0: add and check variables, add labels
# when state = 1: check labels
lex_yacc_analyze_state = 0

# store data in format of [data, width, offset]
# data is transformed to hexadecimal
data_storage = []
data_segment_offset = 0
data_relative_offset = 0

# MIPS assembly code in format of [code, offset]
code_storage = []
code_segment_offset = 0
code_relative_offset = 0
# expand pseudo code in format of [code, pseudo offset]
expand_pseudo = []
# variable definition in format of [variable, offset]
variable_definition = []
# label definition in format of [label, offset]
label_definition = []

# current filename
current_filename = ''

##############################
# Lex components declaration #
##############################

t_DATA = r"""\.data"""
t_TEXT = r"""\.text"""

t_BYTE = r"""\.byte"""
t_HALF = r"""\.half"""
t_WORD = r"""\.word"""
t_FLOAT = r"""\.float"""
t_DOUBLE = r"""\.double"""
t_ASCII = r"""\.ascii"""
t_ASCIIZ = r"""\.asciiz"""

t_REG = r"""\$(zero|at|v[01]|a[0-3]|t[0-9]|s[0-7]|k[01]|gp|sp|s8|fp|ra|
            ([1-2][0-9]|3[01]|[0-9]))"""
t_OFFSET = r"""\(\$
               (zero|at|v[01]|a[0-3]|t[0-9]|s[0-7]|k[01]|gp|sp|s8|fp|ra|([1-2][0-9]|3[01]|[0-9]))
               \)"""

t_ALIGN = r"""\.align"""
t_SPACE = r"""\.space"""
t_COMMA = r""","""
t_COLON = r""":"""


def t_ENDL(t):
    r"""\n+"""
    t.lexer.lineno += len(t.value)
    return t


def t_PIDNAME(t):
    r"""(
            (
                addiu|addu|subu|
                andi|ori|xori|nor|
                multu|divu|
                mfhi|mflo|mthi|mtlo|mfc0|mtc0|
                sltiu|sltu|
                sllv|srlv|srav|
                jalr|jr|
                break|syscall|eret|
                lui|
                lbu|lhu|lw|sb|sh|sw|
                beq|bne|bgtz|blez|bgezal|bltzal|
                push|pop|
                jlu|jleu|jgu|jgeu
            )[0-9a-zA-Z_\$\.]+
        )|
        (
            (addi|sub|mult|div|slti|lb|lh|jle|jge)[0-9a-tv-zA-TV-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            (and|or|xor)[0-9a-hj-zA-HJ-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            (sll|srl|sra)[0-9a-uw-zA-UW-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            (bgez|bltz)([0-9b-zB-Z_\$\.]|a[0-9a-km-zA-KM-Z_\$\.])[0-9a-zA-Z_\$\.]*
        )|
        (
            jal[0-9a-qs-zA-QS-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            j(g|l)[0-9a-df-tv-zA-DF-TV-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            (add|slt)[0-9a-hj-zA-H_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            j([0-9b-fh-km-qs-zB-FH-KM-QS-Z_\$\.]|a[0-9a-km-zA-KM-Z_\$\.])[0-9a-zA-Z_\$\.]*
        )
        """
    return t


def t_ICOM(t):
    r"""addiu|addi|andi|ori|xori|sltiu|slti"""
    return t


def t_RCOM(t):
    r"""addu|add|subu|sub|and|or|xor|nor|sltu|slt|sllv|srlv|srav"""
    return t


def t_PCOM(t):
    r"""push|pop"""
    return t


def t_LWICOM(t):
    r"""lbu|lb|lhu|lh|sb|sh|lw|sw"""
    return t


def t_DRCOM(t):
    r"""multu|mult|divu|div|mfc0|mtc0|jalr"""
    return t


def t_BZICOM(t):
    r"""bgez|bgtz|blez|bltz|bgezal|bltzal"""
    return t


def t_SLLRCOM(t):
    r"""sll|srl|sra"""
    return t


def t_BICOM(t):
    r"""beq|bne"""
    return t


def t_SICOM(t):
    r"""lui"""
    return t


def t_SRCOM(t):
    r"""mfhi|mflo|mthi|mtlo|jr"""
    return t


def t_JBCOM(t):
    r"""jle|jl|jge|jg"""
    return t


def t_BREAK(t):
    r"""break"""
    return t


def t_SYSCALL(t):
    r"""syscall"""
    return t


def t_ERET(t):
    r"""eret"""
    return t


def t_JCOM(t):
    r"""jal|j"""
    return t


def t_NOP(t):
    r"""nop"""
    return t


def t_IDNAME(t):
    r"""[a-zA-Z_][0-9a-zA-Z_]*"""
    return t


def t_VALUE(t):
    r"""(0[xX][0-9a-fA-F]+)|([0-9]+)|([01]+[bB])"""
    return t


def t_STRING(t):
    r"""\"[^\n\r\"]*\""""
    return t


def t_COMMENT(t):
    r"""\#[^\n\r]*"""
    return t


t_ignore = ' \t'


def t_error(t):
    raise Exception('Lex error {} at line {}, illegal character {}'
                    .format(t.value[0], t.lineno, t.value[0]))


###############################
# Yacc components declaration #
###############################


start = 'program'


# definition info of labels and variables
dict_label = {}
dict_variable = {}


def p_empty(p):
    """empty :"""
    pass


def p_program(p):
    """program : data text
               | ENDL data text"""


def p_data(p):
    """data : empty
            | data_segment variables"""


def p_data_segment(p):
    """data_segment : DATA ENDL
                    | DATA VALUE ENDL"""
    global data_segment_offset
    if len(p) == 4:
        data_segment_offset = get_value(p[2])


def p_variables(p):
    """variables : empty
                 | variables variable
                 | variables SPACE VALUE ENDL
                 | variables ALIGN VALUE ENDL"""
    global data_storage
    global data_relative_offset

    if len(p) == 5:
        if p[2] == '.space':
            for i in range(get_value(p[3])):
                data_storage.append([0, 1, data_relative_offset])
                data_relative_offset += 1
        if p[2] == '.align':
            rem = data_relative_offset % (1 << get_value(p[3]))
            if rem != 0:
                rem = (1 << get_value(p[3])) - rem
            for i in range(rem):
                data_storage.append([0, 1, data_relative_offset])
                data_relative_offset += 1


def p_variable(p):
    """variable : ENDL
                | IDNAME COLON variable_data ENDL"""
    global variable_definition
    global data_relative_offset

    if lex_yacc_analyze_state == 0 and len(p) == 5:
        p[1] = current_filename + '$' + p[1]
        if p[1] in dict_variable:
            raise Exception('redefinition of variable at line {}'.format(p.lineno(1)))
        dict_variable[p[1]] = p.lineno(1)
        variable_definition.append([p[1], data_relative_offset])


def p_variable_data(p):
    """variable_data : empty
                     | variable_data COMMA VALUE
                     | variable_data COMMA STRING
                     | BYTE VALUE
                     | HALF VALUE
                     | WORD VALUE
                     | FLOAT VALUE
                     | DOUBLE VALUE
                     | ASCII VALUE
                     | ASCII STRING"""
    global data_storage
    global data_relative_offset

    width = -1
    if len(p) == 3:
        if p[1] == '.byte':
            width = 1
            if invalid_value(p[2], 8):
                raise Exception('data exceed BYTE at line {}'.format(p.lineno(2)))
            data_storage.append([get_value(p[2]), 1, data_relative_offset])
            data_relative_offset += 1
        elif p[1] == '.half':
            width = 2
            if data_relative_offset % width != 0:
                raise Exception('data not aligned to HALF at line {}'.format(p.lineno(2)))
            if invalid_value(p[2], 16):
                raise Exception('data exceed HALF at line {}'.format(p.lineno(2)))
            data_storage.append([get_value(p[2]), 2, data_relative_offset])
            data_relative_offset += 2
        elif p[1] == '.word':
            width = 4
            if data_relative_offset % width != 0:
                raise Exception('data not aligned to WORD at line {}'.format(p.lineno(2)))
            if invalid_value(p[2], 32):
                raise Exception('data exceed WORD at line {}'.format(p.lineno(2)))
            data_storage.append([get_value(p[2]), 4, data_relative_offset])
            data_relative_offset += 4
        elif p[1] == '.ascii':
            width = 5
            if len(p[2]) >= 2 and p[2][0] == p[2][-1] == '\"':
                for i in range(1, len(p[2])-1):
                    data_storage.append([ord(p[2][i]), 1, data_relative_offset])
                    data_relative_offset += 1
            else:
                if invalid_value(p[2], 8):
                    raise Exception('data exceed ASCII at line {}'.format(p.lineno(2)))
                data_storage.append([get_value(p[2]), 1, data_relative_offset])
                data_relative_offset += 1

    if len(p) == 4:
        width = p[1]
        if len(p[3]) >= 2 and p[3][0] == p[3][-1] == '\"':
            if width != 5:
                raise Exception('incompatible value type at line {}'.format(p.lineno))
            for i in range(1, len(p[3]) - 1):
                data_storage.append([ord(p[3][i]), 1, data_relative_offset])
                data_relative_offset += 1
        else:
            data_type = 'BYTE'
            if width == 1:
                data_type = 'BYTE'
            elif width == 2:
                data_type = 'HALF'
            elif width == 4:
                data_type = 'WORD'
            elif width == 5:
                data_type = 'ASCII'
            if invalid_value(p[3], upmod(width*8, 32)):
                raise Exception('data exceed {} at line {}'.format(data_type, p.lineno(3)))
            data_storage.append([get_value(p[3]), upmod(width, 4), data_relative_offset])
            data_relative_offset += upmod(width, 4)

    if width < 0:
        raise Exception('unexpected error of data width at line {}'.format(p.lineno(3)))
    p[0] = width


def p_text(p):
    """text : text_segment code"""


def p_text_segment(p):
    """text_segment : TEXT ENDL
                    | TEXT VALUE ENDL"""
    global code_segment_offset
    if len(p) == 4:
        code_segment_offset = get_value(p[2])


def p_code(p):
    """code : instructions"""


def p_instructions(p):
    """instructions : empty
                    | instructions instruction
                    | instructions label instruction"""


def p_label(p):
    """label : IDNAME COLON
             | PIDNAME COLON"""
    global code_relative_offset
    global label_definition

    p[1] = current_filename + '$' + p[1]
    if lex_yacc_analyze_state == 0:
        if p[1] in dict_variable:
            raise Exception('label definition conflicts with variable at line'.
                            format(p.lineno(1)))
        if p[1] in dict_label:
            raise Exception('redefinition of label at line {}'.format(p.lineno(1)))
        dict_label[p[1]] = p.lineno(1)

    label_definition.append([p[1] + p[2], code_relative_offset])


def p_instruction(p):
    """instruction : ENDL
                   | command ENDL"""


def p_command(p):
    """command : RCOM REG COMMA REG COMMA REG
               | ICOM REG COMMA REG COMMA immediate
               | JCOM immediate
               | PCOM REG
               | LWICOM REG COMMA immediate OFFSET
               | DRCOM REG COMMA REG
               | BZICOM REG COMMA immediate
               | SLLRCOM REG COMMA REG COMMA VALUE
               | BICOM REG COMMA REG COMMA immediate
               | SICOM REG COMMA immediate
               | SRCOM REG
               | JBCOM REG COMMA REG COMMA immediate
               | BREAK
               | SYSCALL
               | ERET
               | NOP"""
    global code_relative_offset
    global expand_pseudo

    if p[1] == 'push':
        expand_pseudo.append(['addi $sp,$sp,-4', code_relative_offset])
        expand_pseudo.append(['sw {},0($sp)'.format(p[2]), code_relative_offset])
    if p[1] == 'pop':
        expand_pseudo.append(['lw {},0($sp)'.format(p[2]), code_relative_offset])
        expand_pseudo.append(['addi $sp,$sp,4', code_relative_offset])
    if p[1] == 'jg':
        expand_pseudo.append(['slt $1,{},{}'.format(p[4], p[2]), code_relative_offset])
        expand_pseudo.append(['bne $1,$0,{}'.format(p[6]), code_relative_offset])
    if p[1] == 'jge':
        expand_pseudo.append(['slt $1,{},{}'.format(p[2], p[4]), code_relative_offset])
        expand_pseudo.append(['beq $1,$0,{}'.format(p[6]), code_relative_offset])
    if p[1] == 'jl':
        expand_pseudo.append(['slt $1,{},{}'.format(p[2], p[4]), code_relative_offset])
        expand_pseudo.append(['bne $1,$0,{}'.format(p[6]), code_relative_offset])
    if p[1] == 'jle':
        expand_pseudo.append(['slt $1,{},{}'.format(p[4], p[2]), code_relative_offset])
        expand_pseudo.append(['beq $1,$0,{}'.format(p[6]), code_relative_offset])
    if p[1] == 'jgu':
        expand_pseudo.append(['sltu $1,{},{}'.format(p[4], p[2]), code_relative_offset])
        expand_pseudo.append(['bne $1,$0,{}'.format(p[6]), code_relative_offset])
    if p[1] == 'jgeu':
        expand_pseudo.append(['sltu $1,{},{}'.format(p[2], p[4]), code_relative_offset])
        expand_pseudo.append(['beq $1,$0,{}'.format(p[6]), code_relative_offset])
    if p[1] == 'jlu':
        expand_pseudo.append(['sltu $1,{},{}'.format(p[2], p[4]), code_relative_offset])
        expand_pseudo.append(['bne $1,$0,{}'.format(p[6]), code_relative_offset])
    if p[1] == 'jleu':
        expand_pseudo.append(['sltu $1,{},{}'.format(p[4], p[2]), code_relative_offset])
        expand_pseudo.append(['beq $1,$0,{}'.format(p[6]), code_relative_offset])

    temp_string = p[1]
    if len(p) > 2:
        temp_string += ' '
        for i in range(2, len(p)):
            temp_string += p[i]
    code_storage.append([temp_string, code_relative_offset])
    code_relative_offset += 1


def p_immediate(p):
    """immediate : IDNAME
                 | PIDNAME
                 | VALUE"""
    if not p[1][0].isdigit():
        p[1] = current_filename + '$' + p[1]
        if lex_yacc_analyze_state == 1:
            if p[1] not in dict_variable and p[1] not in dict_label:
                raise Exception('undefined variable or label at line {}'.format(p.lineno(1)))
    p[0] = p[1]


# get result ranging from [1, MOD]
def upmod(x, mod):
    return (x - 1) % mod + 1


# get radix
def get_radix(str):
    if str[0:2] == '0x' or str[0:2] == '0X':
        return 16
    elif str[-1] == 'b' or str[-1] == 'B':
        return 2
    else:
        return 10


# convert every radix to decimal
def get_value(str):
    if get_radix(str) == 16:
        return int(str, 16)
    elif get_radix(str) == 2:
        return int(str[0:-1], 2)
    else:
        return int(str, 10)


# judge whether given #str is a valid #width number
def invalid_value(str, width):
    decimal_width = math.ceil(math.log10(1 << width))
    if get_value(str) >= (1 << width) or \
            (get_radix(str) == 2 and len(str) > width + 1) or \
            (get_radix(str) == 10 and len(str) > decimal_width) or \
            (get_radix(str) == 16 and len(str) > width / 4 + 2):
        return True
    else:
        return False


def assembly_analyze(filename):
    global lex_yacc_analyze_state
    global data_storage
    global data_segment_offset
    global data_relative_offset
    global code_storage
    global code_segment_offset
    global code_relative_offset
    global expand_pseudo
    global variable_definition
    global label_definition
    global dict_label
    global dict_variable
    global current_filename

    # initialize
    lex_yacc_analyze_state = 0
    data_storage = []
    data_segment_offset = 0
    data_relative_offset = 0
    code_storage = []
    code_segment_offset = 0
    code_relative_offset = 0
    expand_pseudo = []
    variable_definition = []
    label_definition = []
    dict_label = {}
    dict_variable = {}
    current_filename = str(filename).split('\\')[-1][0:-4]
    current_file_prefix = filename[0:-4]

    # file input
    file = open(filename, 'r')
    data = file.read()
    file.close()

    # convert MIPS assembly code to lowercase
    data = data.lower() + '\n'

    lexer = lex.lex()
    parser = yacc.yacc(debug=True)

    lex_list = []
    no_comment_data = ''

    # conduct preliminary lexical analysis to obtain token list
    lexer.input(data)
    lexer.lineno = 1
    while True:
        token = lexer.token()
        if not token:
            break
        lex_list.append([token.type, token.value, token.lineno, token.lexpos])

    # preprocess using token list, delete comment and redundant end-lines
    for i in range(len(lex_list)-1, -1, -1):
        if lex_list[i][0] == 'ENDL':
            if i == 0 or lex_list[i-1][0] == 'COLON' or lex_list[i-1][0] == 'COMMENT':
                lex_list.remove(lex_list[i])
        if lex_list[i][0] == 'COMMENT':
            lex_list.remove(lex_list[i])

    for i in range(len(lex_list)):
        if lex_list[i][0] == 'ENDL':
            no_comment_data += '\n'
        else:
            if lex_list[i][1] != ':':
                no_comment_data += ' '
            no_comment_data += lex_list[i][1]

    # formatted_code = open("formatted_code.txt", 'w')
    # formatted_code.write(no_comment_data)
    # formatted_code.close()

    # first syntax analysis, acquire and check variable definitions, acquire label definitions
    lexer.lineno = 1
    lex_yacc_analyze_state = 0
    parser.parse(no_comment_data)

    # second syntax analysis, check label definitions
    data_storage.clear()
    data_relative_offset = 0
    code_storage.clear()
    expand_pseudo.clear()
    label_definition.clear()
    code_relative_offset = 0
    lexer.lineno = 1
    lex_yacc_analyze_state = 1
    parser.parse(no_comment_data)

    # print data storage layout of data segment
    data_output = open(current_file_prefix + '_data_output.txt', 'w')
    data_output.write('\\\\segment offset\n')
    data_output.write('{}\n'.format(data_segment_offset))
    data_output.write('\\\\variable definition in format of [name, end_offset]\n')
    for [name, offset] in variable_definition:
        data_output.write(name + ' ' + str(offset) + '\n')
    data_output.write('\\\\data storage info in format of [value, width, offset]\n')
    for i in range(len(data_storage)):
        for j in range(3):
            data_output.write(str(data_storage[i][j]) + ' ')
        data_output.write('\n')
    data_output.write('\\\\end of output\n')
    data_output.close()

    # 文法分析之外的检查：
    # 1. 变量/标号的重复定义/未定义 [OK]
    # 2. VALUE的范围（数据段与代码段） [OK]
    # 3. STRING的检查，是否准备支持混合？ [OK,支持混合]
    # 4. 浮点数？不准备支持
    # 5. 注释的支持 [OK]
    # 6. 对于.space和.align的支持，以及数据对齐的检查 [OK, 要求单开一行]
    # 7. 对于代码的预处理：删回车删注释等 [大概OK]

    for i in range(len(lex_list)):
        [cur_type, cur_value, cur_lineno, cur_pos] = lex_list[i]

        if cur_type == 'DATA' or cur_type == 'TEXT':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+1]
            if get_value(nxt_value) >= 16384 * 4:
                raise Exception('offset exceed memory limit at line {}'.format(nxt_lineno))

        elif cur_type == 'BYTE':
            j = i + 1
            while True:
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]

                if invalid_value(nxt_value, 8):
                    raise Exception('data exceed BYTE at line {}'.format(nxt_lineno))

                j += 1
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]
                if nxt_type == 'ENDL':
                    break
                j += 1
            i = j

        elif cur_type == 'HALF':
            j = i + 1
            while True:
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]

                if invalid_value(nxt_value, 16):
                    raise Exception('data exceed HALF at line {}'.format(nxt_lineno))

                j += 1
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]
                if nxt_type == 'ENDL':
                    break
                j += 1
            i = j

        elif cur_type == 'WORD':
            j = i + 1
            while True:
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]

                if invalid_value(nxt_value, 32):
                    raise Exception('data exceed WORD at line {}'.format(nxt_lineno))

                j += 1
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]
                if nxt_type == 'ENDL':
                    break
                j += 1
            i = j

        elif cur_type == 'ICOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+5]
            if nxt_type != 'VALUE':
                raise Exception('invalid immediate at line {}'.format(nxt_lineno))
            elif invalid_value(nxt_value, 16):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i += 5

        elif cur_type == 'JCOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+1]
            if nxt_type != 'VALUE':
                if nxt_value in dict_variable:
                    raise Exception('mistake variable as label at line {}'.format(nxt_lineno))
            elif invalid_value(nxt_value, 26):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i += 5

        elif cur_type == 'LWICOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+3]
            if nxt_type != 'VALUE':
                if nxt_value in dict_label:
                    raise Exception('mistake label as variable at line {}'.format(nxt_lineno))
            elif invalid_value(nxt_value, 16):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i += 4

        elif cur_type == 'BZICOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+3]
            if nxt_type != 'VALUE':
                if nxt_type in dict_variable:
                    raise Exception('mistake variable as label at line {}'.format(nxt_lineno))
            elif invalid_value(nxt_value, 16):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))

        elif cur_type == 'SICOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+3]
            if nxt_type != 'VALUE':
                raise Exception('invalid immediate at line {}'.format(nxt_lineno) + nxt_type)
            elif invalid_value(nxt_value, 16):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i += 3

        elif cur_type == 'BICOM' or cur_type == 'JBCOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+5]
            if nxt_type != 'VALUE':
                if nxt_type in dict_variable:
                    raise Exception('mistake variable as label at line {}'.format(nxt_lineno))
            elif invalid_value(nxt_value, 16):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i += 5

    # print code storage layout of code segment
    j = 0
    k = 0
    code_output = open(current_file_prefix + '_code_output.txt', 'w')
    code_output.write('\\\\segment offset\n')
    code_output.write('{}\n'.format(code_segment_offset))
    code_output.write('\\\\variable definition in format of [name, end_offset]\n')
    for [name, offset] in variable_definition:
        code_output.write(name + ' ' + str(offset) + '\n')
    code_output.write('\\\\code storage info in format of [code]\n')
    # code_output.write('.text {}\n'.format(code_segment_offset))
    for i in range(len(code_storage)):
        while k < len(label_definition) and label_definition[k][1] == code_storage[i][1]:
            code_output.write(label_definition[k][0] + ' ')
            k += 1
        if j == len(expand_pseudo) or code_storage[i][1] != expand_pseudo[j][1]:
            code_output.write(code_storage[i][0] + '\n')
        while j < len(expand_pseudo) and expand_pseudo[j][1] == code_storage[i][1]:
            code_output.write(expand_pseudo[j][0] + '\n')
            j += 1
    code_output.write('\\\\end of output\n')
    code_output.close()

# todo: 1. 是否能在jl/jle/jg/jge中用$1
#       reply: 大概是可以的，$1用作临时变量
#       2. 准备一下链接器
#       reply: 已完成


file_list = []


def is_folder(filename):
    for i in range(len(filename)):
        if filename[i] == '.':
            return False
    return True


def format_of(filename):
    n = len(filename)
    for i in range(n):
        if filename[n-i-1] == '.':
            return filename[n-i: n]


def get_file_list(current_path):
    global file_list

    current_list = os.listdir(current_path)
    for filename in current_list:
        if not is_folder(filename) and format_of(filename) == 'asm':
            file_list.append(current_path + filename)


if __name__ == '__main__':
    file_list = []
    get_file_list('.\\test\\')

    for filename in file_list:
        assembly_analyze(filename)
