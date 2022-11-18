#!/bin/bash

iverilog -g2012 -o sim/adc_sim.out sim/adc_tb.sv src/mcp3008_adc.sv src/spi_controller.sv && vvp sim/adc_sim.out && gtkwave adc.vcd adc_savefile.gtkw
