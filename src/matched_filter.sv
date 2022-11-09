`default_nettype none
`timescale 1ns / 1ps

module matched_filter #(parameter SAMPLE_DATA_WIDTH = 8, parameter MATCH_SCORE_WIDTH = 16, parameter SAMPLE_LENGTH = 2000) (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [SAMPLE_DATA_WIDTH - 1:0] axiid,
    output logic axiov,
    output logic [MATCH_SCORE_WIDTH - 1:0] axiod
);

    localparam SUM_WIDTH = $clog2(SAMPLE_LENGTH * {SAMPLE_DATA_WIDTH{1'b1}});
    logic [SUM_WIDTH - 1:0] sum_accumulator;

    logic [2:0] state;
    localparam STATE_SUM = 3'b001;

    always_ff @(posedge clk) begin
        if (rst) begin
            sum_accumulator <= 'b0;
            state <= STATE_SUM;
        end
        else begin
            case (state)
                STATE_SUM: begin
                    if (axiiv) begin
                        sum_accumulator <= sum_accumulator + axiid;
                    end
                    else begin
                        sum_accumulator <= 'b0;
                    end
                end
                default: begin
                    state <= STATE_SUM;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
