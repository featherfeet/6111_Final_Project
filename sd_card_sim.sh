#!/bin/bash

#iverilog -g2012 -o sim/sd_card_sim.out sim/sd_card_tb.sv src/spi_controller.sv src/sd_card_controller.sv sim/spi_sd_model/spi_sd_model.v && vvp sim/sd_card_sim.out && gtkwave sd_card.vcd sd_card_savefile.gtkw
iverilog -g2012 -o sim/sd_card_sim.out sim/sd_card_tb.sv src/spi_controller.sv src/sd_card_controller.sv src/xilinx_true_dual_port_read_first_1_clock_ram.v && vvp sim/sd_card_sim.out && gtkwave sd_card.vcd sd_card_savefile.gtkw
