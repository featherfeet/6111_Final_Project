`default_nettype none
`timescale 1ns / 1ps

module uart #(parameter BAUD_RATE = 115200) (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [7:0] axiid,
    output logic axiready,
    output logic uart_tx
);

localparam CLOCK_CYCLES_PER_BIT = 100_000_000 / BAUD_RATE; // Number of 100 MHz clock cycles per bit period.

logic axiid_parity;
assign axiid_parity = ^axiid; // Odd parity

logic [$clog2(CLOCK_CYCLES_PER_BIT) - 1:0] tx_clock_counter;
logic [4:0] tx_bit_counter;
logic [15:0] tx_buffer; // start bit + 8 data bits + parity bit + stop bit + 5 bits idle time = 16 bits

localparam STATE_START = 2'b01;
localparam STATE_TRANSMIT = 2'b10;
logic [1:0] state;

always_ff @(posedge clk) begin
    if (rst) begin
        tx_buffer <= 'b0;
        tx_clock_counter <= 'b0;
        tx_bit_counter <= 5'd16;
        state <= STATE_START;
    end
    else begin
        case (state)
            STATE_START: begin
                if (axiiv) begin
                    tx_buffer <= {1'b0, axiid[0], axiid[1], axiid[2], axiid[3], axiid[4], axiid[5], axiid[6], axiid[7], axiid_parity, 1'b1, 5'b11111};
                    tx_clock_counter <= 'b0;
                    tx_bit_counter <= 5'd16;
                    axiready <= 'b0;
                    $display("UART transmitting decimal %d hex %h.", axiid, axiid);
                    state <= STATE_TRANSMIT;
                end
                else begin
                    uart_tx <= 1'b1;
                    axiready <= 'b1;
                end
            end
            STATE_TRANSMIT: begin
                if (tx_clock_counter == 'b0) begin
                    if (tx_bit_counter == 'b0) begin
                        state <= STATE_START;
                    end
                    else begin
                        uart_tx <= tx_buffer[tx_bit_counter - 'd1];
                        tx_bit_counter <= tx_bit_counter - 'd1;
                        tx_clock_counter <= tx_clock_counter + 'b1;
                    end
                end
                else if (tx_clock_counter == CLOCK_CYCLES_PER_BIT) begin
                    tx_clock_counter <= 'b0;
                end
                else begin
                    tx_clock_counter <= tx_clock_counter + 'b1;
                end
            end
            default: begin
                state <= STATE_START;
            end
        endcase
    end
end

endmodule
