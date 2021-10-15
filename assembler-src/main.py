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
    'IDNAME', 'PIDNAME'
)


# when state = 0: check variables, add labels
# when state = 1: check labels
lex_yacc_analyze_state = 0


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

t_VALUE = r"""(0[xX][0-9a-fA-F]+)|([0-9]+)|([01]+[bB])"""
t_STRING = r"""\"[\s\S]*\""""

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
                beq|bne|bgez|bgtz|blez|bltz|bgezal|bltzal
            )[0-9a-zA-Z_\$\.]+
        )|
        (
            (addi|sub|mult|div|slti|lb|lh)[0-9a-tw-zA-TW-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            (and|or|xor)[0-9a-hj-zA-HJ-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            (sll|srl|sra)[0-9a-uw-zA-UW-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            jal[0-9a-qs-zA-QS-Z_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            (add|slt)[0-9a-hj-zA-H_\$\.][0-9a-zA-Z_\$\.]*
        )|
        (
            j([0-9b-qs-zB-QS-Z_\$\.]|a[0-9a-km-zA-KM-Z_\$\.])[0-9a-zA-Z_\$\.]*
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
    r"""[a-zA-Z][0-9a-zA-Z]*"""
    return t


t_ignore = ' \t'


def t_error(t):
    raise Exception('error {} at line {}'.format(t.value[0], t.lineno))


###############################
# Yacc components declaration #
###############################

start = 'program'

dict_label = {}
dict_variable = {}


def p_empty(p):
    """empty :"""
    pass


def p_program(p):
    """program : data text"""


def p_data(p):
    """data : empty
            | data_segment variables"""


def p_data_segment(p):
    """data_segment : DATA ENDL
                    | DATA VALUE ENDL"""


def p_variables(p):
    """variables : empty
                 | variables variable"""


def p_variable(p):
    """variable : ENDL
                | IDNAME COLON variable_data ENDL"""
    if lex_yacc_analyze_state == 0 and len(p) > 1:
        if p[1] in dict_variable:
            raise Exception('redefinition of variable at line {}'.format(p.lineno(1)))
        dict_variable[p[1]] = p.lineno(1)


def p_variable_data(p):
    """variable_data : variable_data COMMA VALUE
                     | BYTE VALUE
                     | HALF VALUE
                     | WORD VALUE
                     | FLOAT VALUE
                     | DOUBLE VALUE
                     | ASCII VALUE
                     | variable_data COMMA STRING"""


def p_text(p):
    """text : text_segment code"""


def p_text_segment(p):
    """text_segment : TEXT ENDL
                    | TEXT VALUE ENDL"""


def p_code(p):
    """code : start_label instructions"""


def p_start_label(p):
    """start_label : IDNAME COLON"""
    if lex_yacc_analyze_state == 0:
        if p[1] in dict_label:
            raise Exception('redefinition of label at line {}'.format(p.lineno(1)))
        dict_label[p[1]] = p.lineno(1)


def p_instructions(p):
    """instructions : empty
                    | instructions instruction
                    | instructions label instruction"""


def p_label(p):
    """label : IDNAME COLON
             | PIDNAME COLON"""
    if lex_yacc_analyze_state == 0:
        if p[1] in dict_variable:
            raise Exception('label definition conflicts with variable at line'.
                            format(p.lineno(1)))
        if p[1] in dict_label:
            raise Exception('redefinition of label at line {}'.format(p.lineno(1)))
        dict_label[p[1]] = p.lineno(1)


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


def p_immediate(p):
    """immediate : IDNAME
                 | PIDNAME
                 | VALUE"""
    if lex_yacc_analyze_state == 1:
        if not p[1][0].isdigit():
            if p[1] not in dict_variable and p[1] not in dict_label:
                raise Exception('undefined variable or label at line {}'.format(p.lineno(1)))


def get_index(str):
    if str[0:2] == '0x' or str[0:2] == '0X':
        return 16
    elif str[-1] == 'b' or str[-1] == 'B':
        return 2
    else:
        return 10


def get_value(str):
    if get_index(str) == 16:
        return int(str, 16)
    elif get_index(str) == 2:
        return int(str[0:-1], 2)
    else:
        return int(str, 10)


if __name__ == '__main__':
    file = open('input.txt', 'r')
    data = file.read()
    file.close()

    data = data.lower() + '\n'

    lexer = lex.lex()
    parser = yacc.yacc(debug=True)
    parser.parse(data)

    lexer.lineno = 1
    lex_yacc_analyze_state = 1
    parser.parse(data)

    lex_list = []

    lexer.input(data)
    lexer.lineno = 1
    while True:
        token = lexer.token()
        if not token:
            break
        lex_list.append([token.type, token.value, token.lineno, token.lexpos])

    # 文法分析之外的检查：
    # 1. 变量/标号的重复定义/未定义 [OK]
    # 2. VALUE的范围 [OK,但未对variable检查]
    # 3. STRING的检查，是否准备支持混合？
    # 4. 浮点数？不一定准备支持
    # 5. 注释的支持

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

                if get_value(nxt_value) >= (1 << 8) or\
                        (get_index(nxt_value) == 2 and len(nxt_value) > 8+1) or\
                        (get_index(nxt_value) == 10 and len(nxt_value) > 3) or\
                        (get_index(nxt_value) == 16 and len(nxt_value) > 2+2):
                    raise Exception('data exceed BYTE at line {}'.format(nxt_lineno))

                j = j + 1
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]
                if nxt_type == 'ENDL':
                    break
                j = j + 1
            i = j

        elif cur_type == 'HALF':
            j = i + 1
            while True:
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]

                if get_value(nxt_value) >= (1 << 16) or\
                        (get_index(nxt_value) == 2 and len(nxt_value) > 16+1) or\
                        (get_index(nxt_value) == 10 and len(nxt_value) > 5) or\
                        (get_index(nxt_value) == 16 and len(nxt_value) > 4+2):
                    raise Exception('data exceed HALF at line {}'.format(nxt_lineno))

                j = j + 1
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]
                if nxt_type == 'ENDL':
                    break
                j = j + 1
            i = j

        elif cur_type == 'WORD':
            j = i + 1
            while True:
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]

                if get_value(nxt_value) >= (1 << 32) or\
                        (get_index(nxt_value) == 2 and len(nxt_value) > 32+1) or\
                        (get_index(nxt_value) == 10 and len(nxt_value) > 9) or\
                        (get_index(nxt_value) == 16 and len(nxt_value) > 8+2):
                    raise Exception('data exceed WORD at line {}'.format(nxt_lineno))

                j = j + 1
                [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[j]
                if nxt_type == 'ENDL':
                    break
                j = j + 1
            i = j

        elif cur_type == 'ICOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+5]
            if nxt_type != 'VALUE':
                raise Exception('invalid immediate at line {}'.format(nxt_lineno))
            elif get_value(nxt_value) >= (1 << 16) or \
                    (get_index(nxt_value) == 2 and len(nxt_value) > 16+1) or \
                    (get_index(nxt_value) == 10 and len(nxt_value) > 5) or \
                    (get_index(nxt_value) == 16 and len(nxt_value) > 4+2):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i = i + 5

        elif cur_type == 'JCOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+1]
            if nxt_type != 'VALUE':
                if nxt_value in dict_variable:
                    raise Exception('mistake variable as label at line {}'.format(nxt_lineno))
            elif get_value(nxt_value) >= (1 << 26) or \
                    (get_index(nxt_value) == 2 and len(nxt_value) > 26+1) or \
                    (get_index(nxt_value) == 10 and len(nxt_value) > 8) or \
                    (get_index(nxt_value) == 16 and len(nxt_value) > 7+2):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i = i + 5

        elif cur_type == 'LWICOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+3]
            if nxt_type != 'VALUE':
                if nxt_value in dict_label:
                    raise Exception('mistake label as variable at line {}'.format(nxt_lineno))
            elif get_value(nxt_value) >= (1 << 16) or \
                    (get_index(nxt_value) == 2 and len(nxt_value) > 16+1) or \
                    (get_index(nxt_value) == 10 and len(nxt_value) > 5) or \
                    (get_index(nxt_value) == 16 and len(nxt_value) > 4+2):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i = i + 4

        elif cur_type == 'BZICOM' or cur_type == 'SICOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+3]
            if nxt_type != 'VALUE':
                raise Exception('invalid immediate at line {}'.format(nxt_lineno))
            elif get_value(nxt_value) >= (1 << 16) or \
                    (get_index(nxt_value) == 2 and len(nxt_value) > 16+1) or \
                    (get_index(nxt_value) == 10 and len(nxt_value) > 5) or \
                    (get_index(nxt_value) == 16 and len(nxt_value) > 4+2):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i = i + 3

        elif cur_type == 'BICOM' or cur_type == 'JBCOM':
            [nxt_type, nxt_value, nxt_lineno, nxt_pos] = lex_list[i+5]
            if nxt_type != 'VALUE':
                if nxt_type in dict_variable:
                    raise Exception('mistake variable as label at line {}'.format(nxt_lineno))
            elif get_value(nxt_value) >= (1 << 16) or \
                    (get_index(nxt_value) == 2 and len(nxt_value) > 16+1) or \
                    (get_index(nxt_value) == 10 and len(nxt_value) > 5) or \
                    (get_index(nxt_value) == 16 and len(nxt_value) > 4+2):
                raise Exception('immediate exceed limit at line {}'.format(nxt_lineno))
            i = i + 5
