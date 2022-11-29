#!/usr/bin/env python3

from assembler import *

firmware = Assembler()

firmware.set_cs(1)
firmware.nop()
firmware.nop()
firmware.nop()
firmware.nop()
firmware.nop()
firmware.nop()
firmware.nop()
firmware.nop()
firmware.nop()
firmware.nop()
firmware.set_cs(0)
firmware.load_lower_constant(0xFF, REGISTER_R2)
firmware.spi_transaction(REGISTER_R2, REGISTER_R3)
firmware.set_cs(1)
firmware.error(0)

binary = firmware.get_program()

with open("sd_card_controller_firmware.memh", 'w') as fout:
    for i in range(0, len(binary), 4):
        word = binary[i : i + 4]
        word = int.from_bytes(word, "big")
        word = hex(word).replace("0x", '')
        word = word.zfill(8)
        fout.write(word + '\n')
