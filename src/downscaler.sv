`default_nettype none
`timescale 1ns / 1ps

module downscaler #(parameter SAMPLE_DATA_WIDTH = 8) (
    input wire clk,
    input wire rst,
    input wire signed [31:0] i2s_data,
    input wire i2s_data_valid,
    output logic axiov,
    output logic signed [SAMPLE_DATA_WIDTH - 1:0] axiod
);

// Clock-domain-crossing synchronizer
logic [31:0] i2s_data_buffer_1;
logic [31:0] i2s_data_buffer_2;
logic i2s_data_valid_buffer_1;
logic i2s_data_valid_buffer_2;
always_ff @(posedge clk) begin
    i2s_data_buffer_1 <= i2s_data;
    i2s_data_buffer_2 <= i2s_data_buffer_1;
    i2s_data_valid_buffer_1 <= i2s_data_valid;
    i2s_data_valid_buffer_2 <= i2s_data_valid_buffer_1;
end

logic prev_i2s_data_valid;
logic i2s_data_valid_rising;
assign i2s_data_valid_rising = ~prev_i2s_data_valid && i2s_data_valid_buffer_2;

always_ff @(posedge clk) begin
    if (rst) begin
        prev_i2s_data_valid <= 'b0;
    end
    else begin
        if (i2s_data_valid_rising) begin
            axiov <= 'b1;
            axiod <= i2s_data_buffer_2 >>> (24 - SAMPLE_DATA_WIDTH);
        end
        else begin
            axiov <= 'b0;
        end
        prev_i2s_data_valid <= i2s_data_valid_buffer_2;
    end
end

endmodule
