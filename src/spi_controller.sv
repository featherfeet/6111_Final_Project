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

logic [$clog2(CLOCK_DIVISION_COUNT_MAX) - 1:0] clock_divider;

logic spi_clk_falling;
logic spi_clk_rising;
logic prev_spi_clk;

assign spi_clk_falling = prev_spi_clk && !spi_clk;
assign spi_clk_rising = !prev_spi_clk && spi_clk;

localparam STATE_IDLE = 4'b0001;
localparam STATE_SEND = 4'b0010;
localparam STATE_FINISH = 4'b0100;
localparam STATE_WAIT = 4'b1000;
logic [3:0] state;

logic [TRANSACTION_LENGTH_BITS - 1:0] data_to_send;
logic [TRANSACTION_LENGTH_BITS - 1:0] data_received;

logic [$clog2(TRANSACTION_LENGTH_BITS) - 1:0] bit_counter;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= STATE_IDLE;
        spi_clk <= 'b0;
        clock_divider <= 'b0;
        prev_spi_clk <= 'b0;
        spi_cs_n <= 'b1;
        bit_counter <= 'b0;
        data_to_send <= 'b0;
        spi_dout <= 'b0;
        data_received <= 'b0;
        axiov <= 'b0;
        axiod <= 'b0;
        axiready <= 'b1;
    end
    else begin
        // Clock division logic.
        if (clock_divider == CLOCK_DIVISION_COUNT_MAX) begin
            clock_divider <= 'b0;
            spi_clk <= ~spi_clk;
        end
        else begin
            clock_divider <= clock_divider + 'b1;
        end
        prev_spi_clk <= spi_clk;

        // SPI protocol logic.
        case (state)
            STATE_IDLE: begin
                if (axiiv) begin
                    data_to_send <= axiid;
                    bit_counter <= 'b0;
                    axiready <= 'b0;
                    state <= STATE_SEND;
                end
                else begin
                    axiready <= 'b1;
                end
            end
            STATE_SEND: begin
                if (bit_counter == TRANSACTION_LENGTH_BITS) begin
                    state <= STATE_FINISH;
                end
                else begin
                    if (spi_clk_falling) begin
                        spi_dout <= data_to_send[TRANSACTION_LENGTH_BITS - 1 - bit_counter];
                        spi_cs_n <= 'b0;
                        bit_counter <= bit_counter + 'b1;
                    end
                    else if (spi_clk_rising && ~spi_cs_n) begin
                        data_received[TRANSACTION_LENGTH_BITS - bit_counter] <= spi_din_buffered;
                    end
                end
            end
            STATE_FINISH: begin
                axiov <= 'b0;
                if (spi_clk_falling) begin
                    spi_cs_n <= 'b1;
                    state <= STATE_WAIT;
                end
                else if (spi_clk_rising) begin
                    axiod <= {data_received[TRANSACTION_LENGTH_BITS - 1:1], spi_din_buffered};
                    axiov <= 'b1;
                end
                else begin
                    axiov <= 'b0;
                end
            end
            STATE_WAIT: begin
                if (spi_clk_falling) begin
                    state <= STATE_IDLE;
                end
            end
            default: begin
                state <= STATE_IDLE;
            end
        endcase
    end
end

endmodule
