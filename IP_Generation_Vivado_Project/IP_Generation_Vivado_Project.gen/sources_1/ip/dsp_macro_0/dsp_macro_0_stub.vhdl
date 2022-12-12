-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Fri Dec  9 22:26:17 2022
-- Host        : olivers-asus running 64-bit Debian GNU/Linux bookworm/sid
-- Command     : write_vhdl -force -mode synth_stub {/home/oliver/Documents/School/Sophomore Year
--               MIT/6.111/6111_Final_Project/IP_Generation_Vivado_Project/IP_Generation_Vivado_Project.gen/sources_1/ip/dsp_macro_0/dsp_macro_0_stub.vhdl}
-- Design      : dsp_macro_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dsp_macro_0 is
  Port ( 
    CLK : in STD_LOGIC;
    A : in STD_LOGIC_VECTOR ( 8 downto 0 );
    B : in STD_LOGIC_VECTOR ( 8 downto 0 );
    C : in STD_LOGIC_VECTOR ( 31 downto 0 );
    P : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );

end dsp_macro_0;

architecture stub of dsp_macro_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "CLK,A[8:0],B[8:0],C[31:0],P[31:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "dsp_macro_v1_0_2,Vivado 2022.2";
begin
end;
