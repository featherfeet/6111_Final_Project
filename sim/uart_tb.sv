`timescale 1ns / 1ps
`default_nettype none

module uart_tb;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

logic axiiv;
logic [7:0] axiid;

uart uart_inst(
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid),
    .axiready(),
    .uart_tx()
);

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, uart_tb);
    $display("Starting sim...");

    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    axiiv = 0;
    axiid = 0;
    #1000;

    /*
    axiiv = 1;
    axiid = 8'b01010101;
    #10;
    axiiv = 0;

    #100000;

    axiiv = 1;
    axiid = 8'b11111111;
    #10;
    axiiv = 0;

    #100000;
    */

    axiiv = 1;
    axiid = 8'b01000001;
    #300000;

    $finish;
end

endmodule

`default_nettype wire
