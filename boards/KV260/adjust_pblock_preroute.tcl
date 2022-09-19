# Purpose: To contain routing within static to not interfere with routing from PR.

# add 
resize_pblock pblock_core -add {SLICE_X35Y0:SLICE_X36Y179 DSP48E2_X9Y0:DSP48E2_X9Y71}
add_cells_to_pblock pblock_core [get_cells -of [get_pblocks pblock_static]]

#add_cells_to_pblock pblock_core [get_cells -of [get_pblocks pblock_s_intf_pr0]]
#add_cells_to_pblock pblock_core [get_cells -of [get_pblocks pblock_s_intf_pr1]]
#add_cells_to_pblock pblock_core [get_cells -of [get_pblocks pblock_s_intf_pr2]]
#
## Remove pblock_s_intf_pr0,1,2 to make the floorplan looks cleaner. They contain no cells. 
#delete_pblocks pblock_s_intf_*


############## somehow contain_routing property of pbblock_static is clear at thist point ##############
#set_property CONTAIN_ROUTING 1 [get_pblocks pblock_core]

