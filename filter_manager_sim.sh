#!/bin/bash

iverilog -g2012 -o sim/filter_manager_sim.out sim/filter_manager_tb.sv src/filter_manager.sv src/uart.sv src/matched_filter.sv src/xilinx_true_dual_port_read_first_1_clock_ram.v && vvp sim/filter_manager_sim.out && gtkwave filter_manager.vcd filter_manager_savefile.gtkw
