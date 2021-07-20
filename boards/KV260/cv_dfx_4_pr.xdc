# Copyright (C) 2021 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause


create_pblock pblock_pr_0
add_cells_to_pblock [get_pblocks pblock_pr_0] [get_cells -quiet [list video_cp_i/composable/pr_0]]
resize_pblock [get_pblocks pblock_pr_0] -add {SLICE_X40Y180:SLICE_X60Y239}
resize_pblock [get_pblocks pblock_pr_0] -add {DSP48E2_X11Y72:DSP48E2_X12Y95}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB18_X1Y72:RAMB18_X2Y95}
resize_pblock [get_pblocks pblock_pr_0] -add {RAMB36_X1Y36:RAMB36_X2Y47}
resize_pblock [get_pblocks pblock_pr_0] -add {URAM288_X0Y48:URAM288_X0Y63}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_0]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_0]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_0]


create_pblock pblock_pr_1
add_cells_to_pblock [get_pblocks pblock_pr_1] [get_cells -quiet [list video_cp_i/composable/pr_1]]
resize_pblock [get_pblocks pblock_pr_1] -add {SLICE_X40Y120:SLICE_X60Y179}
resize_pblock [get_pblocks pblock_pr_1] -add {DSP48E2_X11Y48:DSP48E2_X12Y71}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB18_X1Y48:RAMB18_X2Y71}
resize_pblock [get_pblocks pblock_pr_1] -add {RAMB36_X1Y24:RAMB36_X2Y35}
resize_pblock [get_pblocks pblock_pr_1] -add {URAM288_X0Y32:URAM288_X0Y47}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_1]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_1]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_1]


create_pblock pblock_pr_join
add_cells_to_pblock [get_pblocks pblock_pr_join] [get_cells -quiet [list video_cp_i/composable/pr_join]]
resize_pblock [get_pblocks pblock_pr_join] -add {SLICE_X27Y120:SLICE_X32Y179}
resize_pblock [get_pblocks pblock_pr_join] -add {DSP48E2_X7Y48:DSP48E2_X8Y71}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_join]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_join]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_join]


create_pblock pblock_pr_fork
add_cells_to_pblock [get_pblocks pblock_pr_fork] [get_cells -quiet [list video_cp_i/composable/pr_fork]]
resize_pblock [get_pblocks pblock_pr_fork] -add {SLICE_X27Y180:SLICE_X34Y239}
resize_pblock [get_pblocks pblock_pr_fork] -add {DSP48E2_X7Y72:DSP48E2_X8Y95}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_pr_fork]
set_property SNAPPING_MODE ON [get_pblocks pblock_pr_fork]
set_property IS_SOFT FALSE [get_pblocks pblock_pr_fork]