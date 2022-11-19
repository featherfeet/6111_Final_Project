`default_nettype none
`timescale 1ns / 1ps

module minmax_filter #(parameter SAMPLE_DATA_WIDTH = 8, parameter LOOK_BACK = 500, LOW_THRESHOLD = 37, HIGH_THRESHOLD = 74) (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire signed [SAMPLE_DATA_WIDTH - 1:0] axiid,
    output logic triggered,
);

logic [$clog2(LOOK_BACK - 1) - 1:0] ram_write_addr;
logic [$clog2(LOOK_BACK - 1) - 1:0] ram_read_addr;
logic [SAMPLE_DATA_WIDTH - 1:0] ram_write_data;
logic [SAMPLE_DATA_WIDTH - 1:0] ram_read_data;
logic ram_write_enable;

xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(SAMPLE_DATA_WIDTH), .RAM_DEPTH(LOOK_BACK), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .NAME("Minmax filter lookback buffer")) lookback_buffer(
    .addra(ram_write_addr),
    .addrb(ram_read_addr),
    .dina(ram_write_data),
    .dinb(8'b0),
    .clka(clk),
    .wea(ram_write_enable),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .douta(),
    .doutb(ram_read_data)
);

logic signed [SAMPLE_DATA_WIDTH + 1:0] min;
logic signed [SAMPLE_DATA_WIDTH + 1:0] max;
logic signed [SAMPLE_DATA_WIDTH * 2:0] difference;
assign difference = max - min;

logic schmitt_trigger_state;
logic prev_schmitt_trigger_state;

assign triggered = prev_schmitt_trigger_state && ~schmitt_trigger_state;

always_ff @(posedge clk) begin
    if (rst) begin
        ram_write_addr <= 'b0;
        ram_read_addr <= 'b0;
        ram_write_data <= 'b0;
        ram_write_enable <= 'b0;
        min <= 'sd127;
        max <= -'sd128;
        schmitt_trigger_state <= 'b0;
        prev_schmitt_trigger_state <= 'b0;
    end
    else begin
        if (axiiv) begin
            if (ram_write_addr == LOOK_BACK) begin
                ram_write_addr <= 'b0;
            end
            else begin
                ram_write_addr <= ram_write_addr + 'b1;
            end
            ram_write_enable <= 'b1;
            ram_write_data <= axiid;
        end

        if (ram_read_addr == LOOK_BACK) begin
            if (difference < LOW_THRESHOLD) begin
                schmitt_trigger_state <= 'b0;
            end
            else if (difference > HIGH_THRESHOLD) begin
                schmitt_trigger_state <= 'b1;
            end

            ram_read_addr <= 'b0;
            min <= 'sd127;
            max <= -'sd128;
        end
        else begin
            ram_read_addr <= ram_read_addr + 'b1;
        end

        // RAM takes 2 clock cycles to read, but we don't care about
        // pipelining explicitly here because being off by 2 won't
        // significantly change where we find the dropoff point.

        if ($signed(ram_read_data) < min) begin
            min <= ram_read_data;
        end
        else if ($signed(ram_read_data) > max) begin
            max <= ram_read_data;
        end
        
        prev_schmitt_trigger_state <= schmitt_trigger_state;
    end
end

endmodule

`default_nettype wire
