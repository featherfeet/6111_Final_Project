`default_nettype none
`timescale 1ns / 1ps

module mcp3008_adc(
    input wire clk,
    input wire rst,
    output logic spi_cs_n,
    output logic spi_clk,
    output logic spi_dout,
    input wire spi_din,
    output logic axiov,
    output logic [9:0] axiod
);

logic spi_axiiv;
logic spi_axiov;
logic [16:0] spi_axiod;
logic spi_axiready;

spi_controller #(.TRANSACTION_LENGTH_BITS(17), .CLOCK_DIVISION(100)) spi (
    .clk(clk),
    .rst(rst),
    .axiiv(spi_axiiv),
    .axiid(17'b0_1_000_00_0000000000), // Read CH0 in single-ended mode.
    .axiov(spi_axiov),
    .axiod(spi_axiod),
    .axiready(spi_axiready),
    .spi_cs_n(spi_cs_n),
    .spi_clk(spi_clk),
    .spi_dout(spi_dout),
    .spi_din(spi_din)
);

assign axiov = spi_axiov;
assign axiod = spi_axiod;

localparam STATE_START = 2'b01;
localparam STATE_WAIT = 2'b10;
logic [1:0] state;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= STATE_START;
        spi_axiiv <= 'b0;
    end
    else begin
        case (state)
            STATE_START: begin
                spi_axiiv <= 1'b1;
                state <= STATE_WAIT;
            end
            STATE_WAIT: begin
                spi_axiiv <= 1'b0;
                if (spi_axiready) begin
                    state <= STATE_START;
                end
            end
            default: begin
                state <= STATE_START;
            end
        endcase
    end
end

endmodule

`default_nettype wire
