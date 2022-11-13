`timescale 1ns / 1ps
`default_nettype none

module minmax_filter_tb;

localparam BIN_FILE_LENGTH = 7000;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

logic triggered;
logic filter_axiiv;
logic [7:0] filter_axiid;

minmax_filter #(.SAMPLE_DATA_WIDTH(8), .LOOK_BACK(500), .LOW_THRESHOLD(37), .HIGH_THRESHOLD(74)) dut (
    .clk(clk),
    .rst(rst),
    .axiiv(filter_axiiv),
    .axiid(filter_axiid),
    .triggered(triggered)
);

logic signed [7:0] signal [BIN_FILE_LENGTH:0];

int f;
int bytes_read;

initial begin
    f = $fopen("sim/FT3D_keyup_2MSPS_shorter.bin", "rb");
    bytes_read = $fread(signal, f);
    assert (bytes_read == BIN_FILE_LENGTH) else $error("Failed to read full .bin file.");

    $dumpfile("minmax_filter.vcd");
    $dumpvars(0, minmax_filter_tb);
    $display("Starting sim...");

    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    for (int i = 0; i < BIN_FILE_LENGTH; i++) begin
        filter_axiid = signal[i];
        filter_axiiv = 1'b1;
        #10;
        filter_axiiv = 1'b0;
        i = i + 1;
        
        if (i % 1000 == 0) begin
            $display("i = %d", i);
        end

        //#100_000; // 10k clock cycles (which happens to be what the gap between samples would be at 10 kSps if clk is 100 MHz)
        #8000; // 800 clock cycles
    end

    $finish;
end

endmodule
