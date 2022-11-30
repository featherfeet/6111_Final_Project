#!/usr/bin/env python3

from assembler import *

firmware = Assembler()

firmware.set_cs(1)

firmware.load_lower_constant(0, REGISTER_R2)
firmware.load_lower_constant(1, REGISTER_R3)
firmware.load_lower_constant(74, REGISTER_R4)
firmware.load_lower_constant(255, REGISTER_R5)

# Send 74 0xFF bytes (actually only probably need like 10 since we're supposed to send 74 clock cycles, not 74 bytes, but this matched what worked before).
firmware.spi_transaction(REGISTER_R5, REGISTER_R6, label = "start_of_loop1")
firmware.add(REGISTER_R2, REGISTER_R3, REGISTER_R2)
firmware.cmp(REGISTER_R2, REGISTER_R4)
firmware.jmp(COMPARISON_LESS_THAN, "start_of_loop1")

firmware.set_cs(0)

# Send CMD0 = 0 with arg 0 until we get a response of R1_IDLE_STATE = 1.
firmware.load_lower_constant(0, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.sd_command(REGISTER_R2, REGISTER_R2, REGISTER_R4, label = "start_of_loop2")
firmware.cmp(REGISTER_R4, REGISTER_R3) # REGISTER_R3 = 1
firmware.jmp(COMPARISON_LESS_THAN, "start_of_loop2")
firmware.jmp(COMPARISON_GREATER_THAN, "start_of_loop2")

# Card is now in idle state.

# Check the SD card version.
firmware.load_lower_constant(8, REGISTER_R2)
firmware.load_lower_constant(0x1AA, REGISTER_R4)
firmware.sd_command(REGISTER_R2, REGISTER_R4, REGISTER_R4)

# Bitwise-AND returned value with R1_ILLEGAL_COMMAND = 0x04 to check if command was illegal.
firmware.load_lower_constant(4, REGISTER_R2)
firmware.bitwise_and(REGISTER_R4, REGISTER_R2, REGISTER_R4)

# If REGISTER_R4 != 0, set REGISTER_R7 (henceforth used to store sd_card_type) to 1:
firmware.load_lower_constant(0, REGISTER_R5)
firmware.load_upper_constant(0, REGISTER_R5)
firmware.cmp(REGISTER_R4, REGISTER_R5)
firmware.jmp(COMPARISON_EQUAL, "sd_card_not_type_1")
firmware.load_lower_constant(1, REGISTER_R7)
# If REGISTER_R4 == 0, receive 4 bytes and set sd_card_type to 2 if the last byte is 0xAA (any other byte is an error).
firmware.load_lower_constant(0xFF, REGISTER_R5, label = "sd_card_not_type_1")
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.load_lower_constant(0xAA, REGISTER_R5)
firmware.cmp(REGISTER_R6, REGISTER_R5)
firmware.jmp(COMPARISON_EQUAL, "sd_card_type_2")
firmware.error(2)
firmware.load_lower_constant(2, REGISTER_R7, label = "sd_card_type_2")

firmware.error(0)

binary = firmware.get_program()

with open("sd_card_controller_firmware.memh", 'w') as fout:
    for i in range(0, len(binary), 4):
        word = binary[i : i + 4]
        word = int.from_bytes(word, "big")
        word = hex(word).replace("0x", '')
        word = word.zfill(8)
        fout.write(word + '\n')
