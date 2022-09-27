# Copyright (C) 2021 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause

################################################################
# Kria Vision Started Kit KV260 Composable Overlay Constraints File
################################################################

# these port does not exists
##MIPI
#set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_raspi_clk_p}]
#set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_raspi_clk_n}]
#set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_raspi_data_p[*]}]
#set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_raspi_data_n[*]}]

# MIPI RPI
## CAM_SCL and CAM_SDA are driven by Channel 2 of I2C MUX
set_property -dict {PACKAGE_PIN F11 IOSTANDARD LVCMOS33} [get_ports {cam_gpiorpi}]

set_property PACKAGE_PIN G11 [get_ports iic_scl_io]
set_property PACKAGE_PIN F10 [get_ports iic_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports iic_*]
set_property SLEW SLOW [get_ports iic_*]
set_property DRIVE 4 [get_ports iic_*]


#MIPI ISP
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_clk_p}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_clk_n}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_data_p[*]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_data_n[*]}]


#ISP AP1302_RST_B HDA02
set_property PACKAGE_PIN J11 [get_ports {ap1302_rst_b}]
set_property IOSTANDARD LVCMOS33 [get_ports {ap1302_rst_b}]
set_property SLEW SLOW [get_ports {ap1302_rst_b}]
set_property DRIVE 4 [get_ports {ap1302_rst_b}]

#ISP AP1302_STANDBY HDA03
set_property PACKAGE_PIN J10 [get_ports {ap1302_standby}]
set_property IOSTANDARD LVCMOS33 [get_ports {ap1302_standby}]
set_property SLEW SLOW [get_ports {ap1302_standby}]
set_property DRIVE 4 [get_ports {ap1302_standby}]

#Fan Speed Enable
set_property PACKAGE_PIN A12 [get_ports {fan_en_b}]
set_property IOSTANDARD LVCMOS33 [get_ports {fan_en_b}]
set_property SLEW SLOW [get_ports {fan_en_b}]
set_property DRIVE 4 [get_ports {fan_en_b}]

set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
