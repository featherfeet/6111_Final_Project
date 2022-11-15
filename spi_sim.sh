#!/bin/bash

iverilog -g2012 -o sim/spi_sim.out sim/spi_tb.sv src/spi_controller.sv && vvp sim/spi_sim.out && gtkwave spi.vcd spi_savefile.gtkw
