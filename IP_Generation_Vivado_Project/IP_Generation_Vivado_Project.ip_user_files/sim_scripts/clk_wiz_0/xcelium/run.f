-makelib xcelium_lib/xpm -sv \
  "/home/oliver/xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "/home/oliver/xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../IP_Generation_Vivado_Project.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
  "../../../../IP_Generation_Vivado_Project.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

