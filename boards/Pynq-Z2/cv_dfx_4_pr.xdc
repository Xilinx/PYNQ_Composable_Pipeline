# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

## HDMI signals
create_clock -period 8.334 -waveform {0.000 4.167} [get_ports hdmi_in_clk_p]

## HDMI RX
set_property -dict {PACKAGE_PIN P19 IOSTANDARD TMDS_33} [get_ports hdmi_in_clk_n]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD TMDS_33} [get_ports hdmi_in_clk_p]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[0]}]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[0]}]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[1]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[1]}]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[2]}]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[2]}]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports {hdmi_in_hpd[0]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports hdmi_in_ddc_scl_io]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports hdmi_in_ddc_sda_io]

## HDMI TX
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports hdmi_tx_0_tmds_clk_n]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports hdmi_tx_0_tmds_clk_p]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_0_tmds_data_n[0]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_0_tmds_data_p[0]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_0_tmds_data_n[1]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_0_tmds_data_p[1]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_0_tmds_data_n[2]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_0_tmds_data_p[2]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {hdmi_out_hpd[0]}]


## Switches
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sws_2bits_tri_i[0]}]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports {sws_2bits_tri_i[1]}]

## Buttons
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[2]}]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[3]}]

## LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[3]}]


create_pblock pblock_pr_0
add_cells_to_pblock [get_pblocks pblock_pr_0] [get_cells -quiet [list video_cp_i/pr_0]]
resize_pblock [get_pblocks pblock_pr_0] -add {SLICE_X26Y62:SLICE_X49Y149}
resize_pblock [get_pblocks pblock_pr_0] -add {DSP48_X2Y26:DSP48_X2Y59}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB18_X2Y26:RAMB18_X2Y59}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB36_X2Y13:RAMB36_X2Y29}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_0]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_0]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_0]

create_pblock pblock_pr_1
add_cells_to_pblock [get_pblocks pblock_pr_1] [get_cells -quiet [list video_cp_i/pr_1]]
resize_pblock [get_pblocks pblock_pr_1] -add {SLICE_X0Y0:SLICE_X49Y48}
resize_pblock [get_pblocks pblock_pr_1] -add {DSP48_X0Y0:DSP48_X2Y17}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB18_X0Y0:RAMB18_X2Y17}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB36_X0Y0:RAMB36_X2Y8}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_1]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_1]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_1]

create_pblock pblock_pr_join
add_cells_to_pblock [get_pblocks pblock_pr_join] [get_cells -quiet [list video_cp_i/pr_join]]
resize_pblock [get_pblocks pblock_pr_join] -add {SLICE_X94Y100:SLICE_X101Y149}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_join]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_join]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_join]

create_pblock pblock_pr_fork
add_cells_to_pblock [get_pblocks pblock_pr_fork] [get_cells -quiet [list video_cp_i/pr_fork]]
resize_pblock [get_pblocks pblock_pr_fork] -add {SLICE_X84Y100:SLICE_X93Y149}
resize_pblock [get_pblocks pblock_pr_fork] -add {DSP48_X3Y40:DSP48_X3Y59}
resize_pblock [get_pblocks pblock_pr_fork] -add {RAMB18_X4Y40:RAMB18_X4Y59}
resize_pblock [get_pblocks pblock_pr_fork] -add {RAMB36_X4Y20:RAMB36_X4Y29}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_fork]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_fork]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_fork]


