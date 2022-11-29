`timescale 1ns / 1ps
`default_nettype none

module sd_card_tb;

logic clk;
logic rst;

logic spi_cs_n;
logic spi_clk;
logic spi_dout;
logic spi_din;

/*spi_sd_model sd_card_model(
    .rstn(~rst),
    .ncs(spi_cs_n),
    .sclk(spi_clk),
    .miso(spi_din),
    .mosi(spi_dout)
);*/

sd_card_controller sd_card_controller_inst(
    .clk(clk),
    .rst(rst),
    .spi_cs_n(spi_cs_n),
    .spi_clk(spi_clk),
    .spi_dout(spi_dout),
    .spi_din(spi_din)
);

always begin
    #5;
    clk = ~clk;
end

initial begin
    $dumpfile("sd_card.vcd");
    $dumpvars(0, sd_card_tb);
    $display("Starting sim...");

    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
end

endmodule

`default_nettype wire
