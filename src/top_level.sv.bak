`default_nettype none
`timescale 1ns / 1ps

module top_level(
    input wire clk,
    input wire btnc,
    output logic [6:0] ja,
    input wire ja7,
    output logic [7:0] jb,
    output logic [15:0] led,
    output logic led16_r
);

localparam SAMPLE_DATA_WIDTH = 8;

logic rst;
assign rst = btnc;

logic sys_clk;
logic i2s_clk;

clk_wiz_0_clk_wiz clock_generator(
    .clk_in(clk),
    .i2s_clk_out(i2s_clk),
    .sys_clk_out(sys_clk),
    .reset(rst),
    .locked()
);

logic signed [31:0] i2s_data;
logic i2s_data_valid;

axis_i2s2 i2s_adc_controller(
    .axis_clk(i2s_clk),
    .axis_resetn(~rst),
    .tx_mclk(ja[0]),
    .tx_lrck(ja[1]),
    .tx_sclk(ja[2]),
    .tx_sdout(ja[3]),
    .rx_mclk(ja[4]),
    .rx_lrck(ja[5]),
    .rx_sclk(ja[6]),
    .rx_sdin(ja7),
    .rx_axis_m_data(i2s_data),
    .rx_axis_m_valid(i2s_data_valid),
    .rx_axis_m_ready(1'b1),
    .rx_axis_m_last()
);

always_ff @(posedge i2s_clk) begin
    if (i2s_data_valid) begin
        led <= i2s_data >>> (24 - 16);
        led16_r <= (i2s_data >= 'sd0);
    end
end

logic downscaler_axiov;
logic signed [SAMPLE_DATA_WIDTH - 1:0] downscaler_axiod;

downscaler #(.SAMPLE_DATA_WIDTH(SAMPLE_DATA_WIDTH)) downscaler_inst(
    .clk(sys_clk),
    .rst(rst),
    .i2s_data(i2s_data),
    .i2s_data_valid(i2s_data_valid),
    .axiov(downscaler_axiov),
    .axiod(downscaler_axiod)
);

logic transmission_detected;

minmax_filter #(.SAMPLE_DATA_WIDTH(SAMPLE_DATA_WIDTH), .LOOK_BACK(50), .LOW_THRESHOLD(37), .HIGH_THRESHOLD(74)) (
    .clk(sys_clk),
    .rst(rst),
    .axiiv(downscaler_axiov),
    .axiid(downscaler_axiod),
    .triggered(transmission_detected)
);

assign jb = {7'b0, transmission_detected};

endmodule
