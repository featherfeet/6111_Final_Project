#!/bin/bash

iverilog -g2012 -o sim/matched_filter_sim.out sim/matched_filter_tb.sv src/matched_filter.sv src/xilinx_true_dual_port_read_first_1_clock_ram.v && vvp sim/matched_filter_sim.out && gtkwave matched_filter.vcd matched_filter_savefile.gtkw
