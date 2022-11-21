`timescale 1ns / 1ps
`default_nettype none

module matched_filter_tb;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

logic axiiv;
logic [7:0] axiid;

matched_filter #(.SAMPLE_DATA_WIDTH(8), .CAPTURE_LENGTH(1000), .FINGERPRINT_MEMORY_FILE("sim/FT70D_bufferdump_1_zero_mean.memh")) matched_filter_inst(
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid)
);

logic [7:0] test_signal_buffer [0:999];

initial begin
    $dumpfile("matched_filter.vcd");
    $dumpvars(0, matched_filter_tb);
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

    #100;

    $finish;
end

endmodule

`default_nettype wire
