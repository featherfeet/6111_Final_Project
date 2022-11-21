`default_nettype none
`timescale 1ns / 1ps

module filter_manager #(parameter SAMPLE_DATA_WIDTH = 8, parameter CAPTURE_LENGTH = 1000) (
    input wire clk,
    input wire rst,
    input wire trigger,
    input wire axiiv,
    input wire [SAMPLE_DATA_WIDTH - 1:0] axiid,
    output logic uart_tx
);

logic [$clog2(CAPTURE_LENGTH) - 1:0] ram_write_addr;
logic [$clog2(CAPTURE_LENGTH) - 1:0] ram_read_addr;
logic [SAMPLE_DATA_WIDTH - 1:0] ram_write_data;
logic [SAMPLE_DATA_WIDTH - 1:0] ram_read_data;
logic capturing;

xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(SAMPLE_DATA_WIDTH), .RAM_DEPTH(CAPTURE_LENGTH), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .NAME("Filter manager capture buffer")) capture_buffer (
    .addra(ram_write_addr),
    .addrb(ram_read_addr),
    .dina(axiid),
    .dinb(),
    .clka(clk),
    .wea(axiiv && capturing),
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

logic uart_axiiv;
logic [7:0] uart_axiid;
logic uart_axiready;

uart uart_inst(
    .clk(clk),
    .rst(rst),
    .axiiv(uart_axiiv),
    .axiid(uart_axiid),
    .axiready(uart_axiready),
    .uart_tx(uart_tx)
);

localparam STATE_START = 4'b0001;
localparam STATE_CAPTURE = 4'b0010;
localparam STATE_DUMP = 4'b0100;
localparam STATE_FILTER = 4'b1000;
logic [3:0] state;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= STATE_START;
        ram_write_addr <= 'b0;
        ram_read_addr <= 'b0;
        capturing <= 'b0;
        uart_axiiv <= 'b0;
        uart_axiid <= 'b0;
    end
    else begin
        case (state)
            STATE_START: begin
                if (trigger) begin
                    capturing <= 'b1;
                    $display("Filter manager entering CAPTURE state.");
                    state <= STATE_CAPTURE;
                end
            end
            STATE_CAPTURE: begin
                if (ram_write_addr == CAPTURE_LENGTH) begin
                    ram_write_addr <= 'b0;
                    ram_read_addr <= 'b0;
                    capturing <= 'b0;
                    $display("Filter manager entering DUMP state.");
                    state <= STATE_DUMP;
                end
                else if (axiiv) begin
                    ram_write_addr <= ram_write_addr + 'b1;
                end
            end
            STATE_DUMP: begin
                if (ram_read_addr == CAPTURE_LENGTH) begin
                    ram_read_addr <= 'b0;
                    uart_axiiv <= 1'b0;
                    $display("Filter manager entering FILTER state.");
                    state <= STATE_FILTER;
                end
                else if (uart_axiready && ~uart_axiiv) begin
                    uart_axiiv <= 1'b1;
                    uart_axiid <= ram_read_data; // The RAM takes 2 clock cycles to read, which is much shorter than sending one byte over UART, so we don't have to worry about pipelining.
                    ram_read_addr <= ram_read_addr + 'b1;
                end
                else begin
                    uart_axiiv <= 1'b0;
                end
            end
            STATE_FILTER: begin
                $display("Running filters..."); // TODO
                $display("Filter manager entering START state.");
                state <= STATE_START;
            end
            default: begin
                state <= STATE_START;
            end
        endcase
    end
end

endmodule
