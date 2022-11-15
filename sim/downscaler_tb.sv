`timescale 1ns / 1ps
`default_nettype none

module downscaler_tb;

logic clk;
logic rst;

always begin
    #5;
    clk = ~clk;
end

logic signed [31:0] i2s_data;
logic i2s_data_valid;

downscaler #(.SAMPLE_DATA_WIDTH(8)) downscaler_inst(
    .clk(clk),
    .rst(rst),
    .i2s_data(i2s_data),
    .i2s_data_valid(i2s_data_valid),
    .axiov(),
    .axiod()
);

real x;
real y;

initial begin
    $dumpfile("downscaler.vcd");
    $dumpvars(0, downscaler_tb);
    $display("Starting sim...");

    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    for (x = 0.0; x < 2 * 3.1415; x = x + 0.1) begin
        y = $sin(x) * $signed(2 ** 23);
        i2s_data = $rtoi(y);
        i2s_data_valid = 1;
        #90; // 9 clock cycles at 100 MHz, which is approximately 2 clock cycles at 22.59001 MHz
        i2s_data_valid = 0;
        #500;
    end

    $finish;
end

endmodule

`default_nettype wire
