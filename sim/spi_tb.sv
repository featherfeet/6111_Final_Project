`timescale 1ns / 1ps
`default_nettype none

module spi_tb;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

logic axiiv;
logic [16:0] axiid;
logic spi_din;

spi_controller #(.TRANSACTION_LENGTH_BITS(17), .CLOCK_DIVISION(100)) spi_inst(
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid),
    .spi_cs_n(),
    .spi_clk(),
    .spi_dout(),
    .spi_din(spi_din)
);

initial begin
    $dumpfile("spi.vcd");
    $dumpvars(0, spi_tb);
    $display("Starting sim...");

    clk = 0;
    rst = 0;
    axiid = 0;
    axiiv = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    axiid = 17'b10101010101010101;
    axiiv = 1'b1;
    #10;
    axiiv = 1'b0;

    #1485;
    spi_din = 1'bX;
    #500;
    spi_din = 1'b1;

    #100000;

    $finish;
end

endmodule

`default_nettype wire
