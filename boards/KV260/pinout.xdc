# Copyright (C) 2021 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause

################################################################
# Kria Vision Started Kit KV260 Composable Overlay Constraints File
################################################################

#MIPI
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_clk_p}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_clk_n}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_data_p[*]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_data_n[*]}]

# MIPI
# CAM_SCL and CAM_SDA are driven by Channel 3 of I2C MUX
set_property PACKAGE_PIN AH7 [get_ports {cam_gpio_tri_o[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_gpio_tri_o[0]}]
