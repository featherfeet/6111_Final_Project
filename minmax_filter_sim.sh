#!/bin/bash

iverilog -g2012 -o sim/minmax_filter_sim.out sim/minmax_filter_tb.sv src/minmax_filter.sv src/xilinx_true_dual_port_read_first_1_clock_ram.v && vvp sim/minmax_filter_sim.out && gtkwave minmax_filter.vcd minmax_filter_savefile.gtkw
