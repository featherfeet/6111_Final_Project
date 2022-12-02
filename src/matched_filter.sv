`default_nettype none
`timescale 1ns / 1ps

module matched_filter #(parameter SAMPLE_DATA_WIDTH = 8, parameter MATCH_SCORE_WIDTH = 32, parameter CAPTURE_LENGTH = 1000, parameter FINGERPRINT_MEMORY_FILE = "") (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [SAMPLE_DATA_WIDTH - 1:0] axiid,
    output logic axiov,
    output logic [MATCH_SCORE_WIDTH - 1:0] axiod,
    output logic signed [MATCH_SCORE_WIDTH - 1:0] dot_product_out,
    output logic signed [MATCH_SCORE_WIDTH - 1:0] similarity_out
);

    logic [$clog2(CAPTURE_LENGTH) - 1:0] ram_read_addr;
    logic ram_read_addr_was_valid;
    logic ram_read_addr_was_valid_pipe_1;
    logic ram_read_addr_was_valid_pipe_2;
    logic [$clog2(CAPTURE_LENGTH) - 1:0] ram_write_addr;
    logic signed [SAMPLE_DATA_WIDTH - 1:0] ram_write_data;
    logic signed [SAMPLE_DATA_WIDTH - 1:0] ram_read_data;
    logic signed [SAMPLE_DATA_WIDTH - 1:0] ram_read_data_if_valid;
    logic signed [MATCH_SCORE_WIDTH - 1:0] similarity_sum;
    logic ram_write_enable;

    assign ram_read_data_if_valid = ram_read_addr_was_valid_pipe_2 ? ram_read_data : 'sd0;
    logic signed [SAMPLE_DATA_WIDTH - 1:0] ram_read_data_if_valid_pipe_1;

    xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(SAMPLE_DATA_WIDTH), .RAM_DEPTH(CAPTURE_LENGTH), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE(FINGERPRINT_MEMORY_FILE), .NAME("Matched filter fingerprint buffer")) fingerprint_buffer (
        .addra(ram_read_addr),
        .addrb(ram_write_addr),
        .dina(),
        .dinb(ram_write_data),
        .clka(clk),
        .wea(1'b0),
        .web(ram_write_enable),
        .ena(1'b1),
        .enb(1'b1),
        .rsta(1'b0),
        .rstb(1'b0),
        .regcea(1'b1),
        .regceb(1'b1),
        .douta(ram_read_data),
        .doutb()
    );

    localparam SUM_WIDTH = $clog2(CAPTURE_LENGTH * {SAMPLE_DATA_WIDTH{1'b1}});
    logic [SUM_WIDTH - 1:0] sum_accumulator;

    logic [SAMPLE_DATA_WIDTH - 1:0] axiid_pipe_1;
    logic [SAMPLE_DATA_WIDTH - 1:0] axiid_pipe_2;
    logic signed [$clog2(CAPTURE_LENGTH) + 1:0] sample_counter;
    logic signed [$clog2(CAPTURE_LENGTH * 2) + 1:0] phase_shift;
    logic signed [MATCH_SCORE_WIDTH - 1:0] dot_product;
    logic signed [SAMPLE_DATA_WIDTH:0] subtraction_result;
    logic signed [SAMPLE_DATA_WIDTH * 2 - 1:0] multiplication_result;
    logic signed [MATCH_SCORE_WIDTH - 1:0] max_dot_product;
    logic signed [$clog2(CAPTURE_LENGTH * 2) + 1:0] max_dot_product_phase_shift;

    logic [3:0] state;
    localparam STATE_SUM        = 4'b0001;
    localparam STATE_FILTER     = 4'b0010;
    localparam STATE_SIMILARITY = 4'b0100;
    localparam STATE_OUTPUT     = 4'b1000;

    always_ff @(posedge clk) begin
        if (rst) begin
            sum_accumulator <= 'b0;
            ram_read_addr <= 'b0;
            ram_write_addr <= 'b0;
            ram_write_data <= 'b0;
            ram_write_enable <= 'b0;
            axiid_pipe_1 <= 'b0;
            axiid_pipe_2 <= 'b0;
            dot_product <= 'b0;
            max_dot_product <= 'b0;
            sample_counter <= 'sd0;
            phase_shift <= -CAPTURE_LENGTH;
            ram_read_addr_was_valid <= 'b0;
            ram_read_addr_was_valid_pipe_1 <= 'b0;
            ram_read_addr_was_valid_pipe_2 <= 'b0;
            max_dot_product_phase_shift <= 'b0;
            multiplication_result <= 'b0;
            similarity_sum <= 'b0;
            ram_read_data_if_valid_pipe_1 <= 'b0;
            state <= STATE_SUM;
        end
        else begin
            case (state)
                STATE_SUM: begin
                    if (sample_counter == CAPTURE_LENGTH) begin
                        sum_accumulator <= sum_accumulator / CAPTURE_LENGTH; // TODO: Make this more efficient.
                        $display("Mean of signal computed: %d", sum_accumulator / CAPTURE_LENGTH);
                        phase_shift <= -CAPTURE_LENGTH;
                        sample_counter <= 'sd0;
                        dot_product <= 'b0;
                        max_dot_product <= 'b0;
                        $display("Matched filter transitioning to STATE_FILTER.");
                        state <= STATE_FILTER;
                    end
                    else begin
                        if (axiiv) begin
                            sum_accumulator <= sum_accumulator + axiid;
                            sample_counter <= sample_counter + 'b1;
                        end
                        else begin
                            sum_accumulator <= 'b0;
                            sample_counter <= 'b0;
                        end
                    end
                    axiov <= 1'b0;
                end
                STATE_FILTER: begin
                    if (phase_shift == CAPTURE_LENGTH) begin
                        $display("Matched filter transitioning to STATE_SIMILARITY.");
                        sample_counter <= 'b0;
                        similarity_sum <= 'b0;
                        state <= STATE_SIMILARITY;
                    end

                    if (sample_counter == CAPTURE_LENGTH) begin
                        $display("Dot product for phase shift %d is %d.", phase_shift, dot_product);
                        dot_product_out <= dot_product;
                        if (dot_product > max_dot_product) begin
                            max_dot_product <= dot_product;
                            max_dot_product_phase_shift <= phase_shift;
                        end
                        dot_product <= 'sd0;
                        phase_shift <= phase_shift + 'b1;
                        sample_counter <= 'b0;
                    end
                    else if (axiiv) begin
                        ram_read_addr <= (phase_shift > sample_counter) ? 'b0 : sample_counter - phase_shift;

                        ram_read_addr_was_valid <= (phase_shift < sample_counter && sample_counter - phase_shift < CAPTURE_LENGTH);
                        ram_read_addr_was_valid_pipe_1 <= ram_read_addr_was_valid;
                        ram_read_addr_was_valid_pipe_2 <= ram_read_addr_was_valid_pipe_1;

                        axiid_pipe_1 <= axiid;
                        axiid_pipe_2 <= axiid_pipe_1; // Delay axiid by 2 clock cycles because the RAM takes 2 clock cycles to read.

                        subtraction_result <= $signed(axiid_pipe_2) - $signed(sum_accumulator);
                        ram_read_data_if_valid_pipe_1 <= ram_read_data_if_valid;
                        multiplication_result <= $signed(ram_read_data_if_valid_pipe_1 * subtraction_result);

                        dot_product <= dot_product + multiplication_result;

                        sample_counter <= sample_counter + 'b1;
                    end
                end
                STATE_SIMILARITY: begin
                    if (sample_counter == CAPTURE_LENGTH) begin
                        sample_counter <= 'b0;
                        state <= STATE_OUTPUT;
                    end
                    else if (axiiv) begin
                        ram_read_addr <= ($signed(max_dot_product_phase_shift) > $signed(sample_counter)) ? 'sd0 : $signed(sample_counter) - $signed(max_dot_product_phase_shift);

                        ram_read_addr_was_valid <= ($signed(max_dot_product_phase_shift) < $signed(sample_counter) && $signed(sample_counter) - $signed(max_dot_product_phase_shift) < $signed(CAPTURE_LENGTH));
                        ram_read_addr_was_valid_pipe_1 <= ram_read_addr_was_valid;
                        ram_read_addr_was_valid_pipe_2 <= ram_read_addr_was_valid_pipe_1;

                        axiid_pipe_1 <= axiid;
                        axiid_pipe_2 <= axiid_pipe_1; // Delay axiid by 2 clock cycles because the RAM takes 2 clock cycles to read.

                        subtraction_result <= ($signed(axiid_pipe_2) - $signed(sum_accumulator)) - $signed(ram_read_data_if_valid);
                        multiplication_result <= subtraction_result * subtraction_result;

                        similarity_sum <= similarity_sum + multiplication_result;
                        similarity_out <= multiplication_result;
                        $display("Similarity for index %d is: %d", sample_counter - 1, multiplication_result);

                        sample_counter <= sample_counter + 'b1;
                    end
                end
                STATE_OUTPUT: begin
                    $display("max_dot_product for %s: %d", FINGERPRINT_MEMORY_FILE, $signed(max_dot_product));
                    $display("similarity_sum for %s: %d", FINGERPRINT_MEMORY_FILE, $signed(similarity_sum));
                    $display("Matched filter transitioning to STATE_SUM.");
                    axiov <= 1'b1;
                    axiod <= similarity_sum;
                    state <= STATE_SUM;
                end
                default: begin
                    state <= STATE_SUM;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
