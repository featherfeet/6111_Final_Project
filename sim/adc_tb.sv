`timescale 1ns / 1ps
`default_nettype none

module adc_tb;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

mcp3008_adc mcp3008_adc_inst(
    .clk(clk),
    .rst(rst),
    .spi_cs_n(),
    .spi_clk(),
    .spi_dout(),
    .spi_din()
);

initial begin
    $dumpfile("adc.vcd");
    $dumpvars(0, adc_tb);
    $display("Starting sim...");

    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    #100000;

    $finish;
end

endmodule

`default_nettype wire
