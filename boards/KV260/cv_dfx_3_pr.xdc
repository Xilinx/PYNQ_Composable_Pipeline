# Copyright (C) 2021-2022 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause



create_pblock pblock_pr_0
add_cells_to_pblock [get_pblocks pblock_pr_0] [get_cells -quiet [list video_cp_i/composable/pr_0]]
resize_pblock [get_pblocks pblock_pr_0] -add {SLICE_X39Y120:SLICE_X60Y179}
resize_pblock [get_pblocks pblock_pr_0] -add {DSP48E2_X11Y48:DSP48E2_X12Y71}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB18_X1Y48:RAMB18_X2Y71}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB36_X1Y24:RAMB36_X2Y35}
resize_pblock [get_pblocks pblock_pr_0] -add {URAM288_X0Y32:URAM288_X0Y47}

create_pblock pblock_pr_1
add_cells_to_pblock [get_pblocks pblock_pr_1] [get_cells -quiet [list video_cp_i/composable/pr_1]]
resize_pblock [get_pblocks pblock_pr_1] -add {SLICE_X39Y60:SLICE_X60Y119}
resize_pblock [get_pblocks pblock_pr_1] -add {DSP48E2_X11Y24:DSP48E2_X12Y47}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB18_X1Y24:RAMB18_X2Y47}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB36_X1Y12:RAMB36_X2Y23}
resize_pblock [get_pblocks pblock_pr_1] -add {URAM288_X0Y16:URAM288_X0Y31}

create_pblock pblock_pr_2
add_cells_to_pblock [get_pblocks pblock_pr_2] [get_cells -quiet [list video_cp_i/composable/pr_2]]
resize_pblock [get_pblocks pblock_pr_2] -add {SLICE_X39Y0:SLICE_X60Y59}
resize_pblock [get_pblocks pblock_pr_2] -add {DSP48E2_X11Y0:DSP48E2_X12Y23}
resize_pblock [get_pblocks pblock_pr_2] -add {RAMB18_X1Y0:RAMB18_X2Y23}
resize_pblock [get_pblocks pblock_pr_2] -add {RAMB36_X1Y0:RAMB36_X2Y11}
resize_pblock [get_pblocks pblock_pr_2] -add {URAM288_X0Y0:URAM288_X0Y15}



#############################   TODO: move to a file ###############################
set_property DONT_TOUCH TRUE [get_cells video_cp_i/composable/dfx_decouplers/hw_contract/hw_contract_pr*]


create_generated_clock -name clk_rp0 -divide_by 1 -source [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_2.PL_CLK_2_BUFG/O]    [get_pins video_cp_i/composable/clk_buf_rp0/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]
create_generated_clock -name clk_rp1 -divide_by 1 -source [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_2.PL_CLK_2_BUFG/O]    [get_pins video_cp_i/composable/clk_buf_rp1/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]
create_generated_clock -name clk_rp2 -divide_by 1 -source [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_2.PL_CLK_2_BUFG/O]    [get_pins video_cp_i/composable/clk_buf_rp2/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]



set_clock_groups -asynchronous \
-group [get_clocks -of [get_pins video_cp_i/ps_e/inst/buffer_pl_clk_2.PL_CLK_2_BUFG/O]] \
-group [get_clocks -of [get_pins video_cp_i/composable/clk_buf_rp0/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]] \
-group [get_clocks -of [get_pins video_cp_i/composable/clk_buf_rp1/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]] \
-group [get_clocks -of [get_pins video_cp_i/composable/clk_buf_rp2/U0/USE_BUFG.GEN_BUFG[0].BUFG_U/O]]

