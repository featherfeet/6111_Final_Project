`default_nettype none
`timescale 1ns / 1ps

module filter_manager #(parameter SAMPLE_DATA_WIDTH = 8, parameter CAPTURE_LENGTH = 1000) (
    input wire clk,
    input wire rst,
    input wire trigger,
    input wire axiiv,
    input wire [SAMPLE_DATA_WIDTH - 1:0] axiid,
    output logic uart_tx,
    output logic [15:0] led,
    output logic [7:0] jd
);

localparam MATCH_SCORE_WIDTH = 32;

logic [$clog2(CAPTURE_LENGTH) - 1:0] ram_write_addr;
logic [$clog2(CAPTURE_LENGTH) + 2 - 1:0] ram_read_addr; // Slightly wider than necessary so that pipelined logic using this as a counter can work.
logic [SAMPLE_DATA_WIDTH - 1:0] ram_write_data;
logic [SAMPLE_DATA_WIDTH - 1:0] ram_read_data;
logic capturing;

logic [$clog2(CAPTURE_LENGTH * 2 + 2) - 1:0] filter_repetitions_counter;

xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(SAMPLE_DATA_WIDTH), .RAM_DEPTH(CAPTURE_LENGTH), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .NAME("Filter manager capture buffer")) capture_buffer (
    .addra(ram_write_addr),
    .addrb(ram_read_addr),
    .dina(axiid),
    .dinb(),
    .clka(clk),
    .wea(axiiv && capturing),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .douta(),
    .doutb(ram_read_data)
);

logic uart_axiiv;
logic [7:0] uart_axiid;
logic uart_axiready;

uart uart_inst(
    .clk(clk),
    .rst(rst),
    .axiiv(uart_axiiv),
    .axiid(uart_axiid),
    .axiready(uart_axiready),
    .uart_tx(uart_tx)
);

logic matched_filter_axiiv;
logic matched_filter_axiiv_pipe_1;
logic matched_filter_axiiv_pipe_2;
logic [SAMPLE_DATA_WIDTH - 1:0] matched_filter_axiid;

logic matched_filter_1_axiov;
logic [MATCH_SCORE_WIDTH - 1:0] matched_filter_1_axiod;
logic matched_filter_2_axiov;
logic [MATCH_SCORE_WIDTH - 1:0] matched_filter_2_axiod;
logic matched_filter_3_axiov;
logic [MATCH_SCORE_WIDTH - 1:0] matched_filter_3_axiod;
logic matched_filter_4_axiov;
logic [MATCH_SCORE_WIDTH - 1:0] matched_filter_4_axiod;

matched_filter #(.SAMPLE_DATA_WIDTH(SAMPLE_DATA_WIDTH), .MATCH_SCORE_WIDTH(MATCH_SCORE_WIDTH), .CAPTURE_LENGTH(CAPTURE_LENGTH), .FINGERPRINT_MEMORY_FILE("sim/FT70D_bufferdump_1_zero_mean.memh")) matched_filter_1(
    .clk(clk),
    .rst(rst),
    .axiiv(matched_filter_axiiv),
    .axiid(matched_filter_axiid),
    .axiov(matched_filter_1_axiov),
    .axiod(matched_filter_1_axiod)
);

matched_filter #(.SAMPLE_DATA_WIDTH(SAMPLE_DATA_WIDTH), .MATCH_SCORE_WIDTH(MATCH_SCORE_WIDTH), .CAPTURE_LENGTH(CAPTURE_LENGTH), .FINGERPRINT_MEMORY_FILE("sim/FT3D_bufferdump_1_zero_mean.memh")) matched_filter_2(
    .clk(clk),
    .rst(rst),
    .axiiv(matched_filter_axiiv),
    .axiid(matched_filter_axiid),
    .axiov(matched_filter_2_axiov),
    .axiod(matched_filter_2_axiod)
);

matched_filter #(.SAMPLE_DATA_WIDTH(SAMPLE_DATA_WIDTH), .MATCH_SCORE_WIDTH(MATCH_SCORE_WIDTH), .CAPTURE_LENGTH(CAPTURE_LENGTH), .FINGERPRINT_MEMORY_FILE("sim/FT50R_3_bufferdump_1_zero_mean.memh")) matched_filter_3(
    .clk(clk),
    .rst(rst),
    .axiiv(matched_filter_axiiv),
    .axiid(matched_filter_axiid),
    .axiov(matched_filter_3_axiov),
    .axiod(matched_filter_3_axiod)
);

matched_filter #(.SAMPLE_DATA_WIDTH(SAMPLE_DATA_WIDTH), .MATCH_SCORE_WIDTH(MATCH_SCORE_WIDTH), .CAPTURE_LENGTH(CAPTURE_LENGTH), .FINGERPRINT_MEMORY_FILE("sim/FT50R_3_bufferdump_3_zero_mean.memh")) matched_filter_4(
    .clk(clk),
    .rst(rst),
    .axiiv(matched_filter_axiiv),
    .axiid(matched_filter_axiid),
    .axiov(matched_filter_4_axiov),
    .axiod(matched_filter_4_axiod)
);

logic spi_axiiv;
logic spi_axiready;
logic [MATCH_SCORE_WIDTH - 1:0] spi_axiid;

localparam DEBUG_SPI_STATE_WAIT_FOR_SPI = 3'b001;
localparam DEBUG_SPI_STATE_SEND_FIRST_SCORE = 3'b010;
localparam DEBUG_SPI_STATE_SEND_SECOND_SCORE = 4'b100;
logic [2:0] debug_spi_state;
logic [2:0] next_debug_spi_state;

spi_controller #(.TRANSACTION_LENGTH_BITS(MATCH_SCORE_WIDTH), .CLOCK_DIVISION(100)) debug_spi_interface(
    .clk(clk),
    .rst(rst),
    .axiiv(spi_axiiv),
    .axiid(spi_axiid),
    .axiov(),
    .axiod(),
    .axiready(spi_axiready),
    .spi_cs_n(jd[1]),
    .spi_clk(jd[0]),
    .spi_dout(jd[2]),
    .spi_din()
);

localparam STATE_START = 4'b0001;
localparam STATE_CAPTURE = 4'b0010;
localparam STATE_DUMP = 4'b0100;
localparam STATE_FILTER = 4'b1000;
logic [3:0] state;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= STATE_START;
        ram_write_addr <= 'b0;
        ram_read_addr <= 'b0;
        capturing <= 'b0;
        uart_axiiv <= 'b0;
        uart_axiid <= 'b0;
        matched_filter_axiiv <= 'b0;
        matched_filter_axiiv_pipe_1 <= 'b0;
        matched_filter_axiiv_pipe_2 <= 'b0;
        matched_filter_axiid <= 'b0;
        filter_repetitions_counter <= 'b0;
        led <= 'b0;
        spi_axiiv <= 'b0;
        spi_axiid <= 'b0;
        debug_spi_state <= DEBUG_SPI_STATE_WAIT_FOR_SPI;
        next_debug_spi_state <= DEBUG_SPI_STATE_SEND_FIRST_SCORE;
    end
    else begin
        case (debug_spi_state)
            DEBUG_SPI_STATE_WAIT_FOR_SPI: begin
                spi_axiiv <= 1'b0;
                if (~spi_axiiv && spi_axiready) begin
                    debug_spi_state <= next_debug_spi_state;
                end
            end
            DEBUG_SPI_STATE_SEND_FIRST_SCORE: begin
                if (matched_filter_1_axiov) begin
                    spi_axiiv <= 1'b1;
                    spi_axiid <= matched_filter_1_axiod;
                    debug_spi_state <= DEBUG_SPI_STATE_WAIT_FOR_SPI;
                    next_debug_spi_state <= DEBUG_SPI_STATE_SEND_SECOND_SCORE;
                end
            end
            DEBUG_SPI_STATE_SEND_SECOND_SCORE: begin
                spi_axiiv <= 1'b1;
                spi_axiid <= matched_filter_2_axiod;
                debug_spi_state <= DEBUG_SPI_STATE_WAIT_FOR_SPI;
                next_debug_spi_state <= DEBUG_SPI_STATE_SEND_FIRST_SCORE;
            end
            default: begin
                state <= DEBUG_SPI_STATE_WAIT_FOR_SPI;
            end
        endcase

        if (matched_filter_1_axiov) begin
            if (matched_filter_1_axiod < matched_filter_2_axiod && matched_filter_1_axiod < matched_filter_3_axiod && matched_filter_1_axiod < matched_filter_4_axiod) begin
                led[0] <= 1'b1;
                led[1] <= 1'b0;
                led[2] <= 1'b0;
                led[3] <= 1'b0;
                led[15:2] <= 'b0;
            end
            else if (matched_filter_2_axiod < matched_filter_1_axiod && matched_filter_2_axiod < matched_filter_3_axiod && matched_filter_2_axiod < matched_filter_4_axiod) begin
                led[0] <= 1'b0;
                led[1] <= 1'b1;
                led[2] <= 1'b0;
                led[3] <= 1'b0;
                led[15:2] <= 'b0;
            end
            else if (matched_filter_3_axiod < matched_filter_1_axiod && matched_filter_3_axiod < matched_filter_2_axiod && matched_filter_3_axiod < matched_filter_4_axiod) begin
                led[0] <= 1'b0;
                led[1] <= 1'b0;
                led[2] <= 1'b1;
                led[3] <= 1'b0;
                led[15:2] <= 'b0;
            end
            else if (matched_filter_4_axiod < matched_filter_1_axiod && matched_filter_4_axiod < matched_filter_2_axiod && matched_filter_4_axiod < matched_filter_3_axiod) begin
                led[0] <= 1'b0;
                led[1] <= 1'b0;
                led[2] <= 1'b0;
                led[3] <= 1'b1;
                led[15:2] <= 'b0;
            end
            else begin
                led[0] <= 1'b0;
                led[1] <= 1'b0;
                led[2] <= 1'b0;
                led[3] <= 1'b0;
                led[15:2] <= 'b0;
            end
        end

        case (state)
            STATE_START: begin
                if (trigger) begin
                    capturing <= 'b1;
                    $display("Filter manager entering CAPTURE state.");
                    state <= STATE_CAPTURE;
                end
            end
            STATE_CAPTURE: begin
                if (ram_write_addr == CAPTURE_LENGTH) begin
                    ram_write_addr <= 'b0;
                    ram_read_addr <= 'b0;
                    capturing <= 'b0;
                    $display("Filter manager entering FILTER state, skipping DUMP.");
                    state <= STATE_FILTER; // TODO PUT BACK
                end
                else if (axiiv) begin
                    ram_write_addr <= ram_write_addr + 'b1;
                end
            end
            STATE_DUMP: begin
                if (ram_read_addr == CAPTURE_LENGTH) begin
                    ram_read_addr <= 'b0;
                    uart_axiiv <= 1'b0;
                    $display("Filter manager entering FILTER state.");
                    state <= STATE_FILTER;
                end
                else if (uart_axiready && ~uart_axiiv) begin
                    $display("Sending byte from address %d over UART.", ram_read_addr);
                    uart_axiiv <= 1'b1;
                    uart_axiid <= ram_read_data; // The RAM takes 2 clock cycles to read, which is much shorter than sending one byte over UART, so the RAM read will be long done by the time we get here.
                    ram_read_addr <= ram_read_addr + 'b1;
                end
                else begin
                    uart_axiiv <= 1'b0;
                end
            end
            STATE_FILTER: begin
                if (ram_read_addr == CAPTURE_LENGTH + 2) begin
                    if (filter_repetitions_counter == CAPTURE_LENGTH * 2 + 1) begin
                        $display("Filter manager entering START state.");
                        filter_repetitions_counter <= 'b0;
                        state <= STATE_START;
                    end
                    else begin
                        filter_repetitions_counter <= filter_repetitions_counter + 'b1;
                    end

                    ram_read_addr <= 'b0;
                    matched_filter_axiiv <= 'b0;
                end
                else begin
                    ram_read_addr <= ram_read_addr + 'b1;
                    matched_filter_axiiv_pipe_1 <= (ram_read_addr >= CAPTURE_LENGTH) ? 'b0 : 'b1;
                    matched_filter_axiiv_pipe_2 <= matched_filter_axiiv_pipe_1;
                    matched_filter_axiiv <= matched_filter_axiiv_pipe_2;
                    matched_filter_axiid <= ram_read_data;
                end
            end
            default: begin
                state <= STATE_START;
            end
        endcase
    end
end

endmodule
