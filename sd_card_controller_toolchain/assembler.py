OPERATION_NOP = 0
OPERATION_SET_CS = 1
OPERATION_SPI_TRANSACTION = 2
OPERATION_SD_COMMAND = 3
OPERATION_LOAD_LOWER_CONSTANT = 4
OPERATION_LOAD_UPPER_CONSTANT = 5
OPERATION_MOVE = 6
OPERATION_JMP = 7
OPERATION_CMP = 8
OPERATION_BITWISE_AND = 9
OPERATION_ERROR = 10
OPERATION_MULT = 11
OPERATION_ADD = 12
OPERATION_SUB = 13
OPERATION_CHECK_AXI = 14
OPERATION_READ_AXI = 15
OPERATION_WRITE_AXI = 16

REGISTER_IP = 0
REGISTER_R0 = REGISTER_IP
REGISTER_COND = 1
REGISTER_R1 = REGISTER_COND
REGISTER_R2 = 2
REGISTER_R3 = 3
REGISTER_R4 = 4
REGISTER_R5 = 5
REGISTER_R6 = 6
REGISTER_R7 = 7

COMPARISON_LESS_THAN = 0
COMPARISON_EQUAL = 1
COMPARISON_GREATER_THAN = 2

INSTRUCTION_LENGTH = 4

class Assembler:
    def __init__(self):
        self.address_counter = 0
        self.program = b''

    def nop(self):
        self.program += bytes([OPERATION_NOP, 0, 0, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def set_cs(self, state):
        self.program += bytes([OPERATION_SET_CS, state, 0, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def spi_transaction(self, source_reg, dest_reg):
        self.program += bytes([OPERATION_SPI_TRANSACTION, source_reg, dest_reg, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def sd_command(self, cmd_reg, arg_reg, dest_reg):
        self.program += bytes([OPERATION_SD_COMMAND, cmd_reg, arg_reg, dest_reg])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def load_lower_constant(self, constant, dest_reg):
        if constant > 0xFFFF:
            raise ValueError(f"Constant {hex(constant)} is too large. Must fit in two bytes.")
        self.program += bytes([OPERATION_LOAD_LOWER_CONSTANT, (constant & 0x00FF), (constant & 0xFF00) >> 8, dest_reg])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def load_upper_constant(self, constant, dest_reg):
        if constant > 0xFFFF:
            raise ValueError(f"Constant {hex(constant)} is too large. Must fit in two bytes.")
        self.program += bytes([OPERATION_LOAD_UPPER_CONSTANT, (constant & 0x00FF), (constant & 0xFF00) >> 8, dest_reg])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def move(self, source_reg, dest_reg):
        self.program += bytes([OPERATION_MOVE, source_reg, dest_reg, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def jmp(self, comparison, address):
        if address > 0xFFFF:
            raise ValueError(f"Address {hex(address)} is too large. Must fit in two bytes.")
        self.program += bytes([OPERATION_JMP, comparison, (address & 0x00FF), (address & 0xFF00) >> 8])
        addr = self.address_counter
        self.address_counter += INSTRUCTION_LENGTH
        return addr

    def cmp(self, reg_a, reg_b):
        self.program += bytes([OPERATION_CMP, reg_a, reg_b, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def bitwise_and(self, reg_a, reg_b, dest_reg):
        self.program += bytes([OPERATION_BITWISE_AND, reg_a, reg_b, dest_reg])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def error(self, error_code):
        self.program += bytes([OPERATION_ERROR, error_code, 0, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def mult(self, reg_a, reg_b, dest_reg):
        self.program += bytes([OPERATION_MULT, reg_a, reg_b, dest_reg])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def add(self, reg_a, reg_b, dest_reg):
        self.program += bytes([OPERATION_ADD, reg_a, reg_b, dest_reg])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def sub(self, reg_a, reg_b, dest_reg):
        self.program += bytes([OPERATION_SUB, reg_a, reg_b, dest_reg])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def check_axi(self):
        self.program += bytes([OPERATION_CHECK_AXI, 0, 0, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def read_axi(self, dest_reg):
        self.program += bytes([OPERATION_READ_AXI, dest_reg, 0, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def write_axi(self, src_reg):
        self.program += bytes([OPERATION_WRITE_AXI, src_reg, 0, 0])
        self.address_counter += INSTRUCTION_LENGTH
        return self.address_counter - INSTRUCTION_LENGTH

    def get_program(self):
        return self.program
