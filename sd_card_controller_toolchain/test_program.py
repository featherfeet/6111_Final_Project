#!/usr/bin/env python3

from assembler import *

test_program = Assembler()

test_program.load_lower_constant(5, REGISTER_R2)
test_program.load_lower_constant(1, REGISTER_R3)
start_of_loop = test_program.sub(REGISTER_R2, REGISTER_R3, REGISTER_R2)
test_program.cmp(REGISTER_R2, REGISTER_R4)
test_program.jmp(COMPARISON_GREATER_THAN, start_of_loop)
test_program.error(0)

with open("test_program.bin", "wb") as fout:
    fout.write(test_program.get_program())
