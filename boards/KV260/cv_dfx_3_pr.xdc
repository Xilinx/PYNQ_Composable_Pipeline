# Copyright (C) 2021 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause




# Create and add cell to static.
# TODO: remove some sites from static to make PR pblock look cleaner.
create_pblock pblock_static
resize_pblock [get_pblocks pblock_static] -add {CLOCKREGION_X0Y0:CLOCKREGION_X2Y3}
#pblock_pr_0
resize_pblock [get_pblocks pblock_static] -remove {SLICE_X40Y120:SLICE_X60Y179}
resize_pblock [get_pblocks pblock_static] -remove {DSP48E2_X11Y48:DSP48E2_X12Y71}
resize_pblock [get_pblocks pblock_static] -remove {RAMB18_X1Y48:RAMB18_X2Y71}
resize_pblock [get_pblocks pblock_static] -remove {RAMB36_X1Y24:RAMB36_X2Y35}
resize_pblock [get_pblocks pblock_static] -remove {URAM288_X0Y32:URAM288_X0Y47}
#pblock_pr_1
resize_pblock [get_pblocks pblock_static] -remove {SLICE_X40Y60:SLICE_X60Y119}
resize_pblock [get_pblocks pblock_static] -remove {DSP48E2_X11Y24:DSP48E2_X12Y47}
resize_pblock [get_pblocks pblock_static] -remove {RAMB18_X1Y24:RAMB18_X2Y47}
resize_pblock [get_pblocks pblock_static] -remove {RAMB36_X1Y12:RAMB36_X2Y23}
resize_pblock [get_pblocks pblock_static] -remove {URAM288_X0Y16:URAM288_X0Y31}
#pblock_pr_2
resize_pblock [get_pblocks pblock_static] -remove {SLICE_X40Y0:SLICE_X60Y59}
resize_pblock [get_pblocks pblock_static] -remove {DSP48E2_X11Y0:DSP48E2_X12Y23}
resize_pblock [get_pblocks pblock_static] -remove {RAMB18_X1Y0:RAMB18_X2Y23}
resize_pblock [get_pblocks pblock_static] -remove {RAMB36_X1Y0:RAMB36_X2Y11}
resize_pblock [get_pblocks pblock_static] -remove {URAM288_X0Y0:URAM288_X0Y15}

resize_pblock pblock_static -add [get_sites -of [get_tiles CMT_L_X16Y0]]
resize_pblock pblock_static -add [get_sites -of [get_tiles CMT_L_X16Y60]]
resize_pblock pblock_static -add [get_sites -of [get_tiles CMT_L_X16Y120]]  

set_property CONTAIN_ROUTING 1   [get_pblocks pblock_static]
#set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_static]
set_property IS_SOFT FALSE       [get_pblocks pblock_static]



create_pblock pblock_core
resize_pblock [get_pblocks pblock_core] -add {CLOCKREGION_X0Y0:CLOCKREGION_X2Y3}
#pblock_pr_0
resize_pblock [get_pblocks pblock_core] -remove {SLICE_X37Y120:SLICE_X60Y179}
resize_pblock [get_pblocks pblock_core] -remove {DSP48E2_X10Y48:DSP48E2_X12Y71}
resize_pblock [get_pblocks pblock_core] -remove {RAMB18_X1Y48:RAMB18_X2Y71}
resize_pblock [get_pblocks pblock_core] -remove {RAMB36_X1Y24:RAMB36_X2Y35}
resize_pblock [get_pblocks pblock_core] -remove {URAM288_X0Y32:URAM288_X0Y47}
#pblock_pr_1
resize_pblock [get_pblocks pblock_core] -remove {SLICE_X37Y60:SLICE_X60Y119}
resize_pblock [get_pblocks pblock_core] -remove {DSP48E2_X10Y24:DSP48E2_X12Y47}
resize_pblock [get_pblocks pblock_core] -remove {RAMB18_X1Y24:RAMB18_X2Y47}
resize_pblock [get_pblocks pblock_core] -remove {RAMB36_X1Y12:RAMB36_X2Y23}
resize_pblock [get_pblocks pblock_core] -remove {URAM288_X0Y16:URAM288_X0Y31}
#pblock_pr_2
resize_pblock [get_pblocks pblock_core] -remove {SLICE_X37Y0:SLICE_X60Y59}
resize_pblock [get_pblocks pblock_core] -remove {DSP48E2_X10Y0:DSP48E2_X12Y23}
resize_pblock [get_pblocks pblock_core] -remove {RAMB18_X1Y0:RAMB18_X2Y23}
resize_pblock [get_pblocks pblock_core] -remove {RAMB36_X1Y0:RAMB36_X2Y11}
resize_pblock [get_pblocks pblock_core] -remove {URAM288_X0Y0:URAM288_X0Y15}

# to leave one empty column to make routing to prebuilt hardware contract flexible.
resize_pblock pblock_core -remove {SLICE_X35Y0:SLICE_X36Y179 DSP48E2_X9Y0:DSP48E2_X9Y71}


set_property CONTAIN_ROUTING 1    [get_pblocks pblock_core]
set_property EXCLUDE_PLACEMENT 1  [get_pblocks pblock_core]
set_property IS_SOFT FALSE        [get_pblocks pblock_core]
set_property PARENT pblock_static [get_pblocks pblock_core]


create_pblock pblock_s_intf_pr0
resize_pblock [get_pblocks pblock_s_intf_pr0] -add {SLICE_X35Y125:SLICE_X36Y174}
set_property CONTAIN_ROUTING 1 [get_pblocks pblock_s_intf_pr0]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_s_intf_pr0]
set_property SNAPPING_MODE OFF [get_pblocks pblock_s_intf_pr0]
set_property IS_SOFT FALSE [get_pblocks pblock_s_intf_pr0]

create_pblock pblock_s_intf_pr1
resize_pblock [get_pblocks pblock_s_intf_pr1] -add {SLICE_X35Y65:SLICE_X36Y114}
set_property CONTAIN_ROUTING 1 [get_pblocks pblock_s_intf_pr1]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_s_intf_pr1]
set_property SNAPPING_MODE OFF [get_pblocks pblock_s_intf_pr1]
set_property IS_SOFT FALSE [get_pblocks pblock_s_intf_pr1]

create_pblock pblock_s_intf_pr2
resize_pblock [get_pblocks pblock_s_intf_pr2] -add {SLICE_X35Y5:SLICE_X36Y54}
set_property CONTAIN_ROUTING 1 [get_pblocks pblock_s_intf_pr2]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_s_intf_pr2]
set_property SNAPPING_MODE OFF [get_pblocks pblock_s_intf_pr2]
set_property IS_SOFT FALSE [get_pblocks pblock_s_intf_pr2]


create_pblock pblock_rp_intf_pr0
resize_pblock [get_pblocks pblock_rp_intf_pr0] -add {SLICE_X37Y125:SLICE_X39Y174}
set_property CONTAIN_ROUTING 1 [get_pblocks pblock_rp_intf_pr0]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_rp_intf_pr0]
set_property SNAPPING_MODE OFF [get_pblocks pblock_rp_intf_pr0]
set_property IS_SOFT FALSE [get_pblocks pblock_rp_intf_pr0]

create_pblock pblock_rp_intf_pr1
resize_pblock [get_pblocks pblock_rp_intf_pr1] -add {SLICE_X37Y65:SLICE_X39Y114}
set_property CONTAIN_ROUTING 1 [get_pblocks pblock_rp_intf_pr1]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_rp_intf_pr1]
set_property SNAPPING_MODE OFF [get_pblocks pblock_rp_intf_pr1]
set_property IS_SOFT FALSE [get_pblocks pblock_rp_intf_pr1]

create_pblock pblock_rp_intf_pr2
resize_pblock [get_pblocks pblock_rp_intf_pr2] -add {SLICE_X37Y5:SLICE_X39Y54}
set_property CONTAIN_ROUTING 1 [get_pblocks pblock_rp_intf_pr2]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_rp_intf_pr2]
set_property SNAPPING_MODE OFF [get_pblocks pblock_rp_intf_pr2]
set_property IS_SOFT FALSE [get_pblocks pblock_rp_intf_pr2]


create_pblock pblock_pr_0
resize_pblock [get_pblocks pblock_pr_0] -add {SLICE_X40Y120:SLICE_X60Y179}
resize_pblock [get_pblocks pblock_pr_0] -add {DSP48E2_X11Y48:DSP48E2_X12Y71}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB18_X1Y48:RAMB18_X2Y71}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB36_X1Y24:RAMB36_X2Y35}
resize_pblock [get_pblocks pblock_pr_0] -add {URAM288_X0Y32:URAM288_X0Y47}
set_property CONTAIN_ROUTING 1   [get_pblocks pblock_pr_0]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_pr_0]
set_property IS_SOFT FALSE       [get_pblocks pblock_pr_0]

create_pblock pblock_pr_1
resize_pblock [get_pblocks pblock_pr_1] -add {SLICE_X40Y60:SLICE_X60Y119}
resize_pblock [get_pblocks pblock_pr_1] -add {DSP48E2_X11Y24:DSP48E2_X12Y47}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB18_X1Y24:RAMB18_X2Y47}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB36_X1Y12:RAMB36_X2Y23}
resize_pblock [get_pblocks pblock_pr_1] -add {URAM288_X0Y16:URAM288_X0Y31}
set_property CONTAIN_ROUTING 1   [get_pblocks pblock_pr_1]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_pr_1]
set_property IS_SOFT FALSE       [get_pblocks pblock_pr_1]

create_pblock pblock_pr_2
resize_pblock [get_pblocks pblock_pr_2] -add {SLICE_X40Y0:SLICE_X60Y59}
resize_pblock [get_pblocks pblock_pr_2] -add {DSP48E2_X11Y0:DSP48E2_X12Y23}
resize_pblock [get_pblocks pblock_pr_2] -add {RAMB18_X1Y0:RAMB18_X2Y23}
resize_pblock [get_pblocks pblock_pr_2] -add {RAMB36_X1Y0:RAMB36_X2Y11}
resize_pblock [get_pblocks pblock_pr_2] -add {URAM288_X0Y0:URAM288_X0Y15}
set_property CONTAIN_ROUTING 1   [get_pblocks pblock_pr_2]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_pr_2]
set_property IS_SOFT FALSE       [get_pblocks pblock_pr_2]


add_cells_to_pblock pblock_core [get_cells -quiet [list video_cp_i]]
add_cells_to_pblock pblock_s_intf_pr0 [get_cells [list video_cp_i/composable/dfx_decouplers/hw_contract/hw_contract_pr0]]
add_cells_to_pblock pblock_s_intf_pr1 [get_cells [list video_cp_i/composable/dfx_decouplers/hw_contract/hw_contract_pr1]]
add_cells_to_pblock pblock_s_intf_pr2 [get_cells [list video_cp_i/composable/dfx_decouplers/hw_contract/hw_contract_pr2]]
add_cells_to_pblock pblock_pr_0 [get_cells -quiet [list video_cp_i/composable/pr_0]]
add_cells_to_pblock pblock_pr_1 [get_cells -quiet [list video_cp_i/composable/pr_1]]
add_cells_to_pblock pblock_pr_2 [get_cells -quiet [list video_cp_i/composable/pr_2]]
add_cells_to_pblock pblock_static [get_cells video_cp_i/composable/clk_buf_rp*]
add_cells_to_pblock pblock_static [get_cells [list {ap1302_rst_b_OBUF[0]_inst} {ap1302_standby_OBUF[0]_inst} {cam_gpiorpi_OBUF[0]_inst} {fan_en_b_OBUF[0]_inst} iic_scl_iobuf iic_sda_iobuf]]


#############################   TODO: move to a file ###############################
set_property DONT_TOUCH TRUE [get_cells video_cp_i/composable/dfx_decouplers/hw_contract/hw_contract_pr*]
set_property DONT_TOUCH TRUE [get_cells video_cp_i/composable/clk_buf_rp*/U0/USE_BUFG.GEN_BUFG[0].BUFG_U]


create_generated_clock -name clk_rp0 -divide_by 1 -source [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_1.PL_CLK_1_BUFG/O]    [get_pins video_cp_i/composable/clk_buf_rp0/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]
create_generated_clock -name clk_rp1 -divide_by 1 -source [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_1.PL_CLK_1_BUFG/O]    [get_pins video_cp_i/composable/clk_buf_rp1/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]
create_generated_clock -name clk_rp2 -divide_by 1 -source [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_1.PL_CLK_1_BUFG/O]    [get_pins video_cp_i/composable/clk_buf_rp2/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]



set_clock_groups -asynchronous \
-group [get_clocks -of [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_1.PL_CLK_1_BUFG/O]] \
-group [get_clocks -of [get_pins video_cp_i/composable/clk_buf_rp0/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]] \
-group [get_clocks -of [get_pins video_cp_i/composable/clk_buf_rp1/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]] \
-group [get_clocks -of [get_pins video_cp_i/composable/clk_buf_rp2/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]]

############################ To make sure that these clocks in static regions have clock root in static region
set_property USER_CLOCK_ROOT X0Y2 [get_nets video_cp_i/ps_e/inst/pl_clk*]


############################ To make sure these clocks use the same clock track number #######################################
place_cell [get_cells video_cp_i/composable/clk_buf_rp0/U0/USE_BUFG.GEN_BUFG[0].BUFG_U]  BUFGCE_X0Y60
place_cell [get_cells video_cp_i/composable/clk_buf_rp1/U0/USE_BUFG.GEN_BUFG[0].BUFG_U]  BUFGCE_X0Y36
place_cell [get_cells video_cp_i/composable/clk_buf_rp2/U0/USE_BUFG.GEN_BUFG[0].BUFG_U]  BUFGCE_X0Y12 
 


 

