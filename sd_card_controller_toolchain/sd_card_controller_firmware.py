#!/usr/bin/env python3

from assembler import *

NUM_BYTES_TO_READ = 512 * 10 # 10 Blocks (must always be a multiple of 512)

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
firmware.jmplt("start_of_loop1")

firmware.set_cs(0)

# Send CMD0 = 0 with arg 0 until we get a response of R1_IDLE_STATE = 1.
firmware.load_lower_constant(0, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.sd_command(REGISTER_R2, REGISTER_R2, REGISTER_R4, label = "start_of_loop2")
firmware.cmp(REGISTER_R4, REGISTER_R3) # REGISTER_R3 = 1
firmware.jmpneq("start_of_loop2")

# Card is now in idle state.

# Check the SD card version using CMD8.
firmware.load_lower_constant(8, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.load_lower_constant(0x1AA, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)
firmware.sd_command(REGISTER_R2, REGISTER_R4, REGISTER_R4)

# Bitwise-AND returned value with R1_ILLEGAL_COMMAND = 0x04 to check if command was illegal.
firmware.load_lower_constant(4, REGISTER_R2)
firmware.bitwise_and(REGISTER_R4, REGISTER_R2, REGISTER_R4)

# If REGISTER_R4 != 0, set REGISTER_R7 (henceforth used to store sd_card_type) to 1:
firmware.load_lower_constant(0, REGISTER_R5)
firmware.load_upper_constant(0, REGISTER_R5)
firmware.cmp(REGISTER_R4, REGISTER_R5)
firmware.jmpeq("sd_card_not_type_1")
firmware.load_lower_constant(1, REGISTER_R7)
firmware.jmp("prep_initialization_loop")
# If REGISTER_R4 == 0, receive 4 bytes and set sd_card_type to 2 if the last byte is 0xAA (any other byte is an error).
firmware.load_lower_constant(0xFF, REGISTER_R5, label = "sd_card_not_type_1")
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.load_lower_constant(0xAA, REGISTER_R5)
firmware.cmp(REGISTER_R6, REGISTER_R5)
firmware.jmpeq("sd_card_type_2")
firmware.error(2)
firmware.load_lower_constant(2, REGISTER_R7, label = "sd_card_type_2")

# Prepare timeout counter for initialization loop.
firmware.load_lower_constant(0, REGISTER_R8, label = "prep_initialization_loop")
firmware.load_upper_constant(0, REGISTER_R8)
firmware.load_lower_constant(1000, REGISTER_R9)
firmware.load_upper_constant(0, REGISTER_R9)
firmware.load_lower_constant(1, REGISTER_R10)
firmware.load_upper_constant(0, REGISTER_R10)

# Send CMD55 (application-specific command) and ACMD41 (initialize card and send host capacity support into) until card says it's ready.
firmware.load_lower_constant(55, REGISTER_R2, label = "initialization_loop")
firmware.load_upper_constant(0, REGISTER_R2)
firmware.load_lower_constant(0, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)
firmware.sd_command(REGISTER_R2, REGISTER_R4, REGISTER_R6)

firmware.load_lower_constant(41, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.load_lower_constant(0, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)

firmware.load_lower_constant(2, REGISTER_R3)
firmware.load_upper_constant(0, REGISTER_R3)
firmware.cmp(REGISTER_R7, REGISTER_R3) # Check if sd_card_type is 2.
firmware.jmpeq("sdhc_support") # If sd_card_type == 2, GOTO sdhc_support, which sets R4 to 0x40000000.
# Else, set R4 to 0.
firmware.load_lower_constant(0, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)
firmware.jmp("send_acmd41")
firmware.load_lower_constant(0x0000, REGISTER_R4, label = "sdhc_support")
firmware.load_upper_constant(0x4000, REGISTER_R4)
firmware.sd_command(REGISTER_R2, REGISTER_R4, REGISTER_R6, label = "send_acmd41")

# Increment counter. If it has reached 1000 iterations, jump out of the loop.
firmware.add(REGISTER_R8, REGISTER_R10, REGISTER_R8)
firmware.cmp(REGISTER_R8, REGISTER_R9)
firmware.jmpeq("try_cmd1")

# If return value of SD command was R1_READY_STATE = 0, jump out of the loop.
firmware.load_lower_constant(0, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)
firmware.cmp(REGISTER_R4, REGISTER_R6)
firmware.jmpeq("got_ready_state")

# Go back to start of loop.
firmware.jmp("initialization_loop")

# (Only executes if CMD55+ACMD41 sequence failed) send CMD1 to try to initialize the card.
firmware.load_lower_constant(1, REGISTER_R2, label = "try_cmd1")
firmware.load_upper_constant(0, REGISTER_R2)
firmware.load_lower_constant(0, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)
firmware.sd_command(REGISTER_R2, REGISTER_R4, REGISTER_R6)
firmware.cmp(REGISTER_R6, REGISTER_R4)
firmware.jmpeq("got_ready_state")
firmware.jmp("try_cmd1")

# TODO: Add SDHC card support here by checking the OCR register. If SDHC, set R7 to 3.

# Send a few extra 0xFF's to let the card rest, see https://stackoverflow.com/a/2375234.
firmware.load_lower_constant(0xFF, REGISTER_R2, label = "got_ready_state")
firmware.load_upper_constant(0, REGISTER_R2)
firmware.spi_transaction(REGISTER_R2, REGISTER_R4)
firmware.spi_transaction(REGISTER_R2, REGISTER_R4)
firmware.spi_transaction(REGISTER_R2, REGISTER_R4)
firmware.spi_transaction(REGISTER_R2, REGISTER_R4)
firmware.spi_transaction(REGISTER_R2, REGISTER_R4)
firmware.set_cs(1)

# Main loop where we read data from the card and send it out over AXI.
firmware.load_lower_constant(NUM_BYTES_TO_READ, REGISTER_R9) # R9 is total number of bytes to read.
firmware.load_upper_constant(0, REGISTER_R9)
firmware.load_lower_constant(0, REGISTER_R10) # R10 is read address. Gets incremented by 1 block (512 bytes) each loop until R10 >= R9.
firmware.load_upper_constant(0, REGISTER_R10)
firmware.set_cs(0, label = "main_loop")
# TODO: Add SDHC card support here by dividing read address by 512 to get a block address if R7 == 3.
# Send CMD17 to read a block at address 0.
firmware.load_lower_constant(17, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.sd_command(REGISTER_R2, REGISTER_R10, REGISTER_R6)
firmware.load_lower_constant(512, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)
firmware.add(REGISTER_R10, REGISTER_R4, REGISTER_R10)
firmware.load_lower_constant(0, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.cmp(REGISTER_R6, REGISTER_R2)
firmware.jmpneq("cmd17_error")
# Await start block token.
firmware.load_lower_constant(0xFF, REGISTER_R2, label = "await_start_block")
firmware.load_upper_constant(0, REGISTER_R2)
firmware.spi_transaction(REGISTER_R2, REGISTER_R4)
firmware.cmp(REGISTER_R2, REGISTER_R4) # If command return value is 255, keep waiting.
firmware.jmpeq("await_start_block")
# Check for read error.
firmware.load_lower_constant(0xFE, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.cmp(REGISTER_R2, REGISTER_R4)
firmware.jmpneq("read_error")
# Read 512 bytes.
firmware.load_lower_constant(0, REGISTER_R2)
firmware.load_upper_constant(0, REGISTER_R2)
firmware.load_lower_constant(1, REGISTER_R3)
firmware.load_upper_constant(0, REGISTER_R3)
firmware.load_lower_constant(511, REGISTER_R4)
firmware.load_upper_constant(0, REGISTER_R4)
firmware.load_lower_constant(0xFF, REGISTER_R5)
firmware.load_upper_constant(0, REGISTER_R5)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6, label = "read_loop")
#firmware.write_axi(REGISTER_R6) # Write byte out to AXI for rest of system to use.
firmware.add(REGISTER_R2, REGISTER_R3, REGISTER_R2)
firmware.cmp(REGISTER_R2, REGISTER_R4)
firmware.jmplt("read_loop")
# Read checksum.
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
# A few extra 0xFF's to let the card rest.
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
firmware.spi_transaction(REGISTER_R5, REGISTER_R6)
# Set CS high.
firmware.set_cs(1)
# Loop code.
firmware.cmp(REGISTER_R10, REGISTER_R9)
firmware.jmplt("main_loop")

firmware.error(0b101010)

firmware.error(17, label = "cmd17_error")
firmware.error(23, label = "read_error")

binary = firmware.get_program()

with open("sd_card_controller_firmware.memh", 'w') as fout:
    for i in range(0, len(binary), 4):
        word = binary[i : i + 4]
        word = int.from_bytes(word, "big")
        word = hex(word).replace("0x", '')
        word = word.zfill(8)
        fout.write(word + '\n')
