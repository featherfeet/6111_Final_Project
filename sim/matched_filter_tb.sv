`timescale 1ns / 1ps
`default_nettype none

module matched_filter_tb;

localparam CAPTURE_LENGTH = 1000;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

logic axiiv;
logic [7:0] axiid;

matched_filter #(.SAMPLE_DATA_WIDTH(8), .CAPTURE_LENGTH(CAPTURE_LENGTH), .FINGERPRINT_MEMORY_FILE("sim/FT70D_bufferdump_1_zero_mean.memh")) matched_filter_inst(
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid),
    .axiov(),
    .axiod()
);

logic [7:0] test_signal_buffer [0:CAPTURE_LENGTH - 1];

initial begin
    $dumpfile("matched_filter.vcd");
    $dumpvars(0, matched_filter_tb);
    $display("Starting sim...");

    $readmemh("sim/FT70D_bufferdump_2.memh", test_signal_buffer);
    //$readmemh("sim/FT3D_bufferdump_1.memh", test_signal_buffer);

    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    axiiv = 0;
    axiid = 0;

    #100;

    axiiv = 1;
    for (int i = 0; i < CAPTURE_LENGTH; i = i + 1) begin
        axiid = test_signal_buffer[i];
        #10;
    end
    axiiv = 0;
    for (int phase_shift = -CAPTURE_LENGTH; phase_shift < CAPTURE_LENGTH; phase_shift = phase_shift + 1) begin
        axiiv = 1;
        for (int i = 0; i < CAPTURE_LENGTH; i = i + 1) begin
            axiid = test_signal_buffer[i];
            #10;
        end
        axiiv = 0;
    end
    #1000;

    $finish;
end

endmodule

`default_nettype wire
