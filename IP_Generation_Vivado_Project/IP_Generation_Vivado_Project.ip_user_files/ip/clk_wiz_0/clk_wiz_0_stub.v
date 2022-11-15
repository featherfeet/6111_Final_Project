// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Sun Nov 13 23:26:33 2022
// Host        : olivers-debianvm running 64-bit Debian GNU/Linux 11 (bullseye)
// Command     : write_verilog -force -mode synth_stub
//               /home/oliver/6111_Final_Project/IP_Generation_Vivado_Project/IP_Generation_Vivado_Project.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(i2s_clk_out, sys_clk_out, reset, locked, clk_in)
/* synthesis syn_black_box black_box_pad_pin="i2s_clk_out,sys_clk_out,reset,locked,clk_in" */;
  output i2s_clk_out;
  output sys_clk_out;
  input reset;
  output locked;
  input clk_in;
endmodule
