#!/bin/bash

iverilog -g2012 -o sim/downscaler_sim.out sim/downscaler_tb.sv src/downscaler.sv && vvp sim/downscaler_sim.out && gtkwave downscaler.vcd downscaler_savefile.gtkw
