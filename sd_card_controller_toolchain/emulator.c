#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define OPERATION_NOP 0
#define OPERATION_SET_CS 1
#define OPERATION_SPI_TRANSACTION 2
#define OPERATION_SD_COMMAND 3
#define OPERATION_LOAD_LOWER_CONSTANT 4
#define OPERATION_LOAD_UPPER_CONSTANT 5
#define OPERATION_MOVE 6
#define OPERATION_JMP 7
#define OPERATION_CMP 8
#define OPERATION_BITWISE_AND 9
#define OPERATION_ERROR 10
#define OPERATION_MULT 11
#define OPERATION_ADD 12
#define OPERATION_SUB 13
#define OPERATION_CHECK_AXI 14
#define OPERATION_READ_AXI 15
#define OPERATION_WRITE_AXI 16

#define REGISTER_IP 0
#define REGISTER_COND 1
#define NUM_REGISTERS 11

#define COMPARISON_LESS_THAN 0
#define COMPARISON_EQUAL 1
#define COMPARISON_GREATER_THAN 2

#define INSTRUCTION_LENGTH 4

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: ./emulator program.bin\n");
        return -1;
    }

    FILE *input_file = fopen(argv[1], "rb");
    fseek(input_file, 0, SEEK_END);
    long file_size = ftell(input_file);
    fseek(input_file, 0, SEEK_SET);
    uint8_t *program = (uint8_t *) malloc(file_size);
    fread(program, 1, file_size, input_file);
    fclose(input_file);

    uint32_t registers[NUM_REGISTERS] = { 0 };

    while (1) {
        printf("%d: ", registers[REGISTER_IP]);

        uint8_t operation = *(program + registers[REGISTER_IP]);

        if (operation == OPERATION_NOP) {
            printf("NOP\n");
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_SET_CS) {
            uint8_t state = *(program + registers[REGISTER_IP] + 1);
            printf("SET_CS %d\n", state);
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_SPI_TRANSACTION) {
            uint8_t source_reg = *(program + registers[REGISTER_IP] + 1);
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 2);
            printf("SPI_TRANSACTION r%d, r%d\n", source_reg, dest_reg);
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_SD_COMMAND) {
            uint8_t cmd_reg = *(program + registers[REGISTER_IP] + 1);
            uint8_t arg_reg = *(program + registers[REGISTER_IP] + 2);
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 3);
            printf("SD_COMMAND r%d, r%d, r%d\n", cmd_reg, arg_reg, dest_reg);
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_LOAD_LOWER_CONSTANT) {
            uint16_t constant = *((uint16_t *) (program + registers[REGISTER_IP] + 1));
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 3);
            printf("LOAD_LOWER_CONSTANT %d, r%d\n", constant, dest_reg);
            registers[dest_reg] = (registers[dest_reg] & 0xFF00) | constant;
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_LOAD_UPPER_CONSTANT) {
            uint16_t constant = *((uint16_t *) (program + registers[REGISTER_IP] + 1));
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 3);
            printf("LOAD_UPPER_CONSTANT %d, r%d\n", constant, dest_reg);
            registers[dest_reg] = (registers[dest_reg] & 0x00FF) | (constant << 8);
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_MOVE) {
            uint8_t source_reg = *(program + registers[REGISTER_IP] + 1);
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 2);
            printf("MOVE r%d, r%d\n", source_reg, dest_reg);
            registers[dest_reg] = registers[source_reg];
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_JMP) {
            uint8_t comparison = *(program + registers[REGISTER_IP] + 1);
            uint16_t addr = *((uint16_t *) (program + registers[REGISTER_IP] + 2));
            if (comparison == COMPARISON_LESS_THAN) {
                printf("JMP (if less than) %d\n", addr);
            }
            else if (comparison == COMPARISON_EQUAL) {
                printf("JMP (if equal) %d\n", addr);
            }
            else {
                printf("JMP (if greater than) %d\n", addr);
            }

            if (comparison == registers[REGISTER_COND]) {
                registers[REGISTER_IP] = addr;
                printf("    Branch taken.\n");
            }
            else {
                registers[REGISTER_IP] += INSTRUCTION_LENGTH;
                printf("    Branch not taken.\n");
            }
        }
        else if (operation == OPERATION_CMP) {
            uint8_t reg_a = *(program + registers[REGISTER_IP] + 1);
            uint8_t reg_b = *(program + registers[REGISTER_IP] + 2);
            if (registers[reg_a] < registers[reg_b]) {
                registers[REGISTER_COND] = COMPARISON_LESS_THAN;
            }
            else if (registers[reg_a] == registers[reg_b]) {
                registers[REGISTER_COND] = COMPARISON_EQUAL;
            }
            else {
                registers[REGISTER_COND] = COMPARISON_GREATER_THAN;
            }

            printf("CMP r%d, r%d\n", reg_a, reg_b);

            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_BITWISE_AND) {
            uint8_t reg_a = *(program + registers[REGISTER_IP] + 1);
            uint8_t reg_b = *(program + registers[REGISTER_IP] + 2);
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 3);

            registers[dest_reg] = registers[reg_a] & registers[reg_b];

            printf("AND r%d, r%d, r%d\n", reg_a, reg_b, dest_reg);

            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_ERROR) {
            uint8_t error_code = *(program + registers[REGISTER_IP] + 1);

            printf("ERROR %d\n", error_code);

            free(program);
            return -1;
        }
        else if (operation == OPERATION_MULT) {
            uint8_t reg_a = *(program + registers[REGISTER_IP] + 1);
            uint8_t reg_b = *(program + registers[REGISTER_IP] + 2);
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 3);

            registers[dest_reg] = registers[reg_a] * registers[reg_b];

            printf("MULT r%d, r%d, r%d\n", reg_a, reg_b, dest_reg);

            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_ADD) {
            uint8_t reg_a = *(program + registers[REGISTER_IP] + 1);
            uint8_t reg_b = *(program + registers[REGISTER_IP] + 2);
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 3);

            printf("ADD r%d, r%d, r%d\n", reg_a, reg_b, dest_reg);

            registers[dest_reg] = registers[reg_a] + registers[reg_b];

            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_SUB) {
            uint8_t reg_a = *(program + registers[REGISTER_IP] + 1);
            uint8_t reg_b = *(program + registers[REGISTER_IP] + 2);
            uint8_t dest_reg = *(program + registers[REGISTER_IP] + 3);

            printf("SUB r%d, r%d, r%d\n", reg_a, reg_b, dest_reg);

            registers[dest_reg] = registers[reg_a] - registers[reg_b];

            registers[REGISTER_IP] += INSTRUCTION_LENGTH;
        }
        else if (operation == OPERATION_CHECK_AXI) {
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;

            printf("CHECK_AXI\n");
        }
        else if (operation == OPERATION_READ_AXI) {
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;

            printf("READ_AXI\n");
        }
        else if (operation == OPERATION_WRITE_AXI) {
            registers[REGISTER_IP] += INSTRUCTION_LENGTH;

            printf("WRITE_AXI\n");
        }

        printf("r2 = %d, r3 = %d, r4 = %d, r5 = %d, r6 = %d, r7 = %d\n", registers[2], registers[3], registers[4], registers[5], registers[6], registers[7]);
    }

    free(program);
    return 0;
}
