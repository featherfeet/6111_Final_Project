`default_nettype none
`timescale 1ns / 1ps

module mcp3008_adc(
    input wire clk,
    input wire rst,
    output logic spi_cs_n,
    output logic spi_clk,
    output logic spi_dout,
    input wire spi_din
);

spi_controller spi #(.TRANSACTION_LENGTH_BITS(17), .CLOCK_DIVISION(100)) (
    .clk(clk),
    .rst(rst),
    .spi_cs_n(spi_cs_n),
    .spi_clk(spi_clk),
    .spi_dout(spi_dout),
    .spi_din(spi_din)
);

endmodule

`default_nettype wire
