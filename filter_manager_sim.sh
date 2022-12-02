#!/bin/bash

iverilog -g2012 -o sim/filter_manager_sim.out sim/filter_manager_tb.sv src/filter_manager.sv src/uart.sv src/spi_controller.sv src/matched_filter.sv src/xilinx_true_dual_port_read_first_1_clock_ram.v && vvp sim/filter_manager_sim.out -lxt-speed && gtkwave filter_manager.lxt filter_manager_savefile.gtkw
