-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Sun Nov 13 23:26:34 2022
-- Host        : olivers-debianvm running 64-bit Debian GNU/Linux 11 (bullseye)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/oliver/6111_Final_Project/IP_Generation_Vivado_Project/IP_Generation_Vivado_Project.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.vhdl
-- Design      : clk_wiz_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_wiz_0 is
  Port ( 
    i2s_clk_out : out STD_LOGIC;
    sys_clk_out : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in : in STD_LOGIC
  );

end clk_wiz_0;

architecture stub of clk_wiz_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "i2s_clk_out,sys_clk_out,reset,locked,clk_in";
begin
end;
