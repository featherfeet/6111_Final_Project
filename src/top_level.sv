`default_nettype none
`timescale 1ns / 1ps

module top_level(
    input wire clk,
    input wire btnc,
    input wire btnr,
    output logic [6:0] ja,
    input wire ja7,
    output logic [7:0] jb,
    output logic [15:0] led
//    output logic led16_r
);

localparam SAMPLE_DATA_WIDTH = 8;

logic rst;
assign rst = btnc;

logic sys_clk;

clk_wiz_0_clk_wiz clock_generator(
    .clk_in(clk),
    .i2s_clk_out(),
    .sys_clk_out(sys_clk),
    .reset(rst),
    .locked()
);

logic adc_axiov;
logic [9:0] adc_axiod;

mcp3008_adc adc(
    .clk(sys_clk),
    .rst(rst),
    .axiov(adc_axiov),
    .axiod(adc_axiod),
    .spi_cs_n(ja[0]),
    .spi_clk(ja[1]),
    .spi_dout(ja[2]),
    .spi_din(ja7)
);

logic [SAMPLE_DATA_WIDTH - 1:0] adc_axiod_downsampled;
assign adc_axiod_downsampled = adc_axiod[9:2];

/*
always_ff @(posedge sys_clk) begin
    if (rst) begin
        led <= 'b0;
    end
    else begin
        if (adc_axiov) begin
            led <= adc_axiod[9:2];
        end
    end
end
*/

logic transmission_detected;

minmax_filter #(.SAMPLE_DATA_WIDTH(SAMPLE_DATA_WIDTH), .LOOK_BACK(50), .LOW_THRESHOLD(2), .HIGH_THRESHOLD(9)) (
    .clk(sys_clk),
    .rst(rst),
    .axiiv(adc_axiov),
    .axiid(adc_axiod_downsampled),
    .triggered(transmission_detected),
    .btnr(btnr),
);

assign jb = {7'b0, transmission_detected};

endmodule
