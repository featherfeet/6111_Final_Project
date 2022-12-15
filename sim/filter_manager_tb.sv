`timescale 1ns / 1ps
`default_nettype none

module filter_manager_tb;

localparam CAPTURE_LENGTH = 1000;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

logic trigger;
logic axiiv;
logic [7:0] axiid;

filter_manager #(.SAMPLE_DATA_WIDTH(8), .CAPTURE_LENGTH(1000)) filter_manager_inst(
    .clk(clk),
    .rst(rst),
    .trigger(trigger),
    .axiiv(axiiv),
    .axiid(axiid)
);

logic [7:0] test_signal_buffer [0:CAPTURE_LENGTH - 1];

initial begin
    $dumpfile("filter_manager.vcd");
    $dumpvars(0, filter_manager_tb);
    $display("Starting sim...");

    $readmemh("sim/FT70D_bufferdump_2.memh", test_signal_buffer);

    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    axiiv = 0;
    axiid = 0;
    trigger = 0;

    #100;

    trigger = 1;
    #10;
    trigger = 0;

    #100;

    for (int i = 0; i < 1000; i = i + 1) begin
        axiiv = 1;
        axiid = test_signal_buffer[i];
        #10;
        axiiv = 0;
        #20_000; // 2k clock cycles on the 100 MHz clock, approximate time between samples
    end

    #40_000_000;

    $readmemh("sim/FT3D_bufferdump_2.memh", test_signal_buffer);

    #100;

    trigger = 1;
    #10;
    trigger = 0;

    #100;

    for (int i = 0; i < 1000; i = i + 1) begin
        axiiv = 1;
        axiid = test_signal_buffer[i];
        #10;
        axiiv = 0;
        #20_000; // 2k clock cycles on the 100 MHz clock, approximate time between samples
    end

    #40_000_000;

    $finish;
end

endmodule

`default_nettype wire
