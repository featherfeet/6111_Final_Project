#!/bin/bash

iverilog -g2012 -o sim/uart_sim.out sim/uart_tb.sv src/uart.sv && vvp sim/uart_sim.out && gtkwave uart.vcd uart_savefile.gtkw
