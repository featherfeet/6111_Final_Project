`timescale 1ns / 1ps
`default_nettype none

module sd_card_controller(
    input wire clk,
    input wire rst,
    output logic spi_cs_n,
    output logic spi_clk,
    output logic spi_dout,
    output logic spi_din
);

localparam PROGRAM_ROM_LENGTH = 1000;
localparam INSTRUCTION_WIDTH_BITS = 32;
localparam INSTRUCTION_LENGTH_BYTES = INSTRUCTION_WIDTH_BITS / 8;
localparam REGISTER_WIDTH = 32;
localparam NUM_REGISTERS = 8;

localparam OPERATION_NOP = 0;
localparam OPERATION_SET_CS = 1;
localparam OPERATION_SPI_TRANSACTION = 2;
localparam OPERATION_SD_COMMAND = 3;
localparam OPERATION_LOAD_LOWER_CONSTANT = 4;
localparam OPERATION_LOAD_UPPER_CONSTANT = 5;
localparam OPERATION_MOVE = 6;
localparam OPERATION_JMP = 7;
localparam OPERATION_CMP = 8;
localparam OPERATION_BITWISE_AND = 9;
localparam OPERATION_ERROR = 10;
localparam OPERATION_MULT = 11;
localparam OPERATION_ADD = 12;
localparam OPERATION_SUB = 13;
localparam OPERATION_CHECK_AXI = 14;
localparam OPERATION_READ_AXI = 15;
localparam OPERATION_WRITE_AXI = 16;

localparam REGISTER_IP = 0;
localparam REGISTER_COND = 1;

localparam COMPARISON_LESS_THAN = 0;
localparam COMPARISON_EQUAL = 1;
localparam COMPARISON_GREATER_THAN = 2;

localparam ERROR_CODE_INVALID_OPERATION = 1;

logic spi_axiiv;
logic [7:0] spi_axiid;
logic spi_axiov;
logic [7:0] spi_axiod;
logic spi_axiready;

spi_controller #(.TRANSACTION_LENGTH_BITS(8), .CLOCK_DIVISION(100)) spi_controller_inst(
    .clk(clk),
    .rst(rst),
    .axiiv(spi_axiiv),
    .axiid(spi_axiid),
    .axiov(spi_axiov),
    .axiod(spi_axiod),
    .axiready(spi_axiready),
    .spi_cs_n(), // Don't connect, we want to manipulate the CS pin manually without the usual SPI behaviors.
    .spi_clk(spi_clk),
    .spi_dout(spi_dout),
    .spi_din(spi_din)
);

logic [$clog2(PROGRAM_ROM_LENGTH) - 1:0] ram_read_addr;
logic [INSTRUCTION_WIDTH_BITS - 1:0] ram_read_data;

xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(INSTRUCTION_WIDTH_BITS), .RAM_DEPTH(PROGRAM_ROM_LENGTH), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE("sd_card_controller_toolchain/sd_card_controller_firmware.memh")) program_rom(
    .addra(ram_read_addr),
    .addrb(),
    .dina(),
    .dinb(),
    .clka(clk),
    .wea(1'b0),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b0),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b0),
    .douta(ram_read_data),
    .doutb()
);

reg [4:0] state;
localparam STATE_READ_INSTRUCTION = 5'b00001;
localparam STATE_WAIT_1           = 5'b00010;
localparam STATE_WAIT_2           = 5'b00100;
localparam STATE_EXECUTE          = 5'b01000;
localparam STATE_ERROR            = 5'b10000;

logic spi_transaction_state;

reg [REGISTER_WIDTH - 1:0] register_file [NUM_REGISTERS - 1:0];

reg [7:0] error_code;

always_ff @(posedge clk) begin
    if (rst) begin
        ram_read_addr <= 'b0;
        for (int i = 0; i < NUM_REGISTERS; i = i + 1) begin
            register_file[i] <= 'b0;
        end
        error_code <= 'b0;
        spi_cs_n <= 1'b1;
        spi_axiiv <= 'b0;
        spi_axiid <= 'b0;
        spi_transaction_state <= 'b0;
        state <= STATE_READ_INSTRUCTION;
    end
    else begin
        case (state)
            STATE_READ_INSTRUCTION: begin
                ram_read_addr <= register_file[REGISTER_IP] >> 2; // Memory is byte-addressable, but we store it in words for ease of reading in one step, so addresses are divided by 4.
                state <= STATE_WAIT_1;
            end
            STATE_WAIT_1: begin
                state <= STATE_WAIT_2;
            end
            STATE_WAIT_2: begin
                state <= STATE_EXECUTE;
            end
            STATE_EXECUTE: begin
                case (ram_read_data[31:24])
                    OPERATION_NOP: begin
                        $display("NOP");
                        register_file[REGISTER_IP] <= register_file[REGISTER_IP] + INSTRUCTION_LENGTH_BYTES;
                        state <= STATE_READ_INSTRUCTION;
                    end
                    OPERATION_SET_CS: begin
                        $display("SET_CS %d", ram_read_data[16]);
                        spi_cs_n <= ram_read_data[16];
                        register_file[REGISTER_IP] <= register_file[REGISTER_IP] + INSTRUCTION_LENGTH_BYTES;
                        state <= STATE_READ_INSTRUCTION;
                    end
                    OPERATION_SPI_TRANSACTION: begin
                        if (spi_transaction_state == 'd0 && spi_axiready) begin
                            $display("SPI_TRANSACTION r%d, r%d", ram_read_data[23:16], ram_read_data[15:8]);
                            $display("    Wrote byte 0x%h to SPI.", register_file[ram_read_data[23:16]][7:0]);
                            spi_axiiv <= 1'b1;
                            spi_axiid <= register_file[ram_read_data[23:16]];
                            spi_transaction_state <= 'd1;
                        end
                        else if (spi_transaction_state == 'd1) begin
                            spi_axiiv <= 1'b0;

                            if (spi_axiov) begin
                                register_file[ram_read_data[15:8]] <= spi_axiod;
                                $display("    Read byte 0x%h from SPI.", spi_axiod);
                                spi_transaction_state <= 'd0;
                                register_file[REGISTER_IP] <= register_file[REGISTER_IP] + INSTRUCTION_LENGTH_BYTES;
                                state <= STATE_READ_INSTRUCTION;
                            end
                        end
                    end
                    OPERATION_SD_COMMAND: begin

                    end
                    OPERATION_LOAD_LOWER_CONSTANT: begin
                        $display("LOAD_LOWER_CONSTANT %d, r%d", {ram_read_data[15:8], ram_read_data[23:16]}, ram_read_data[7:0]);
                        register_file[ram_read_data[7:0]] <= {register_file[ram_read_data[7:0]][31:16], {ram_read_data[15:8], ram_read_data[23:16]}};
                        register_file[REGISTER_IP] <= register_file[REGISTER_IP] + INSTRUCTION_LENGTH_BYTES;
                        state <= STATE_READ_INSTRUCTION;
                    end
                    OPERATION_LOAD_UPPER_CONSTANT: begin
                        $display("LOAD_UPPER_CONSTANT %d, r%d", {ram_read_data[15:8], ram_read_data[23:16]}, ram_read_data[7:0]);
                        register_file[ram_read_data[7:0]] <= {{ram_read_data[15:8], ram_read_data[23:16]}, register_file[ram_read_data[7:0]][15:0]};
                        register_file[REGISTER_IP] <= register_file[REGISTER_IP] + INSTRUCTION_LENGTH_BYTES;
                        state <= STATE_READ_INSTRUCTION;
                    end
                    OPERATION_MOVE: begin

                    end
                    OPERATION_JMP: begin

                    end
                    OPERATION_CMP: begin

                    end
                    OPERATION_BITWISE_AND: begin

                    end
                    OPERATION_ERROR: begin
                        $display("ERROR %d", ram_read_data[23:16]);
                        error_code <= ram_read_data[23:16];
                        state <= STATE_ERROR;
                    end
                    OPERATION_MULT: begin

                    end
                    OPERATION_ADD: begin

                    end
                    OPERATION_SUB: begin

                    end
                    OPERATION_CHECK_AXI: begin

                    end
                    OPERATION_READ_AXI: begin

                    end
                    OPERATION_WRITE_AXI: begin

                    end
                    default: begin
                        error_code <= ERROR_CODE_INVALID_OPERATION;
                        state <= STATE_ERROR;
                    end
                endcase
            end
            STATE_ERROR: begin
                $display("SD card controller error: %d", error_code);
                $finish;
            end
            default: begin
                state <= STATE_READ_INSTRUCTION;
            end
        endcase
    end
end

endmodule
