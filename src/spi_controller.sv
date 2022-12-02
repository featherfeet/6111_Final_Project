`default_nettype none
`timescale 1ns / 1ps

module spi_controller #(parameter TRANSACTION_LENGTH_BITS = 8, parameter CLOCK_DIVISION = 100) (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [TRANSACTION_LENGTH_BITS - 1:0] axiid,
    output logic axiov,
    output logic [TRANSACTION_LENGTH_BITS - 1:0] axiod,
    output logic axiready,
    output logic spi_cs_n,
    output logic spi_clk,
    output logic spi_dout,
    input wire spi_din
);

// Clock-domain-crossing synchronizer to prevent metastability.
logic spi_din_buffer_1;
logic spi_din_buffered;
always_ff @(posedge clk) begin
    spi_din_buffer_1 <= spi_din;
    spi_din_buffered <= spi_din_buffer_1;
end

localparam CLOCK_DIVISION_COUNT_MAX = (CLOCK_DIVISION / 2) - 1;

logic [$clog2(CLOCK_DIVISION + 1) - 1:0] clock_divider;
logic [$clog2(TRANSACTION_LENGTH_BITS + 1) - 1:0] bits_counter;
logic [TRANSACTION_LENGTH_BITS - 1:0] data_to_send;

localparam STATE_IDLE     = 4'b0001;
localparam STATE_RECEIVE  = 4'b0010;
localparam STATE_TRANSMIT = 4'b0100;
localparam STATE_WAIT     = 4'b1000;

logic [3:0] state;

always_ff @(posedge clk) begin
    if (rst) begin
        clock_divider <= 'b0;
        bits_counter <= 'b0;
        state <= STATE_IDLE;
        axiod <= 'b0;
        axiov <= 'b0;
        spi_dout <= 'b1;
        spi_clk <= 'b1;
        spi_cs_n <= 'b1;
    end
    else begin
        case (state)
            STATE_IDLE: begin
                if (axiiv) begin
                    $display("SPI sending byte 0x%h", axiid);
                    spi_cs_n <= 1'b0;
                    axiready <= 1'b0;
                    spi_clk <= 1'b0;
                    spi_dout <= axiid[TRANSACTION_LENGTH_BITS - 1];
                    data_to_send <= axiid;
                    bits_counter <= 'b1;
                    clock_divider <= 'b0;
                    state <= STATE_RECEIVE;
                end
                else begin
                    spi_cs_n <= 1'b1;
                    axiready <= 1'b1;
                    spi_clk <= 1'b1;
                end
            end
            STATE_RECEIVE: begin
                if (clock_divider == CLOCK_DIVISION_COUNT_MAX) begin
                    spi_clk <= 1'b1;
                    axiod <= {axiod[TRANSACTION_LENGTH_BITS - 2:0], spi_din_buffered};
                    clock_divider <= 'b0;
                    state <= STATE_TRANSMIT;
                end
                else begin
                    clock_divider <= clock_divider + 'b1;
                end
            end
            STATE_TRANSMIT: begin
                if (bits_counter == TRANSACTION_LENGTH_BITS) begin
                    spi_cs_n <= 1'b1;
                    axiov <= 1'b1;
                    state <= STATE_WAIT;
                end
                else begin
                    if (clock_divider == CLOCK_DIVISION_COUNT_MAX) begin
                        spi_clk <= 1'b0;
                        spi_dout <= data_to_send[TRANSACTION_LENGTH_BITS - 1 - bits_counter];
                        bits_counter <= bits_counter + 'b1;
                        clock_divider <= 'b0;
                        state <= STATE_RECEIVE;
                    end
                    else begin
                        clock_divider <= clock_divider + 'b1;
                    end
                end
            end
            STATE_WAIT: begin
                if (clock_divider == CLOCK_DIVISION) begin
                    state <= STATE_IDLE;
                end
                else begin
                    clock_divider <= clock_divider + 'b1;
                end
                axiov <= 1'b0;
            end
            default: begin
                state <= STATE_IDLE;
            end
        endcase
    end
end

endmodule
