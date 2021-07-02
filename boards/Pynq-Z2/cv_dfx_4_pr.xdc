# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

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


