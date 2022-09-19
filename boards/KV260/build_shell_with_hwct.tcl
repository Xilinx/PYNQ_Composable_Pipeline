if { $argc != 1 } {
  puts "Need to specify the project name."
  exit 1  
}


############### setttings #####################
# Should only change this section
#
# set which hwct to use, rp1 is the most preferable and then rp0
#set hwct ../hw_contract_usepr1.dcp  resutling in some unrouted net (GND)
# hw_contract_userp1_d2af from new function WriteCheckpointOfCell
#set hwct ./hw_contract_userpr1_rw.dcp
set hwct ./hwctdirect_pr1.dcp
#set hwct ../hwct/[lindex $argv 0]
# the name of resulting full shell DCP and bit
set full_shell_name     full_shell
# the name of resulting abstract shell DCP will be affixed with RP2.
set abstract_shell_name abstract_shell
set store_checkpoint 1
###############################################

#set project_dir "/group/zircon/pongstorn/projects/PYNQ_overlay_sep2022/PYNQ_Composable_Pipeline/boards/KV260/cv_dfx_3_pr"
set project_name [lindex $argv 0]
set post_opt_dcp "${project_name}/${project_name}.runs/impl_1/video_cp_wrapper_opt.dcp"
set src_dir ./

# use post_opt not post_synth because hwct is build from post_route. Thus some of the unnecessary logics are trimmed.
# using post_synth with hwct will create mismatch and opt_design with report error that some luts have no driver. 
# Those luts are trimmed in original opt_design along with logic in hwct. inserting hwct in post_synth leave those input dangling.
open_checkpoint $post_opt_dcp

# Update hw_contract with an implemented version extracted using RapidWright. See run.sh.
update_design -black_box  -cells [get_cells video_cp_i/composable/dfx_decouplers/hw_contract]
read_checkpoint           -cell [get_cells video_cp_i/composable/dfx_decouplers/hw_contract]    ${hwct} 


lock_design -level routing  

# additional constraints for relocation
#source ${src_dir}/cv_dfx_3_pr_reloc.xdc
# remove this after rerun the project ********************************
#source clock.xdc

opt_design -verbose
if {$store_checkpoint} {
  write_checkpoint post_opt.dcp -force
}


# to assign only cells connect to static to pblock_static_core
#source ${src_dir}/assign_intf_cells_to_pblock.tcl

## TO be removed after doing it in RW
#set_property PROHIBIT 1 [get_bels { \
#                            SLICE_X34Y34/F5LUT SLICE_X34Y34/F6LUT  SLICE_X34Y32/G6LUT SLICE_X34Y32/G5LUT \
#                            SLICE_X34Y94/F5LUT SLICE_X34Y94/F6LUT  SLICE_X34Y92/G6LUT SLICE_X34Y92/G5LUT \
#                            SLICE_X34Y154/F5LUT SLICE_X34Y154/F6LUT  SLICE_X34Y152/G6LUT SLICE_X34Y152/G5LUT \
#                        }]


# use different directive, if needed to close timing. 
place_design -directive Explore
if {$store_checkpoint} {
  write_checkpoint post_place.dcp -force
}

#source ${src_dir}/adjust_pblock_preroute.tcl -notrace

## downgrade the check for containment of nets in static. The check is permanantly disable in 21.2
##set_msg_config -id {[Constraints  18-4638]} -new_severity INFO
#set_msg_config -suppress -id {[Constraints  18-4638]}
#set_msg_config -suppress -id {[Constraints  18-901]}
##ERROR: [Constraints 18-901] HDPostRouteDRC-04: the net GND (or <const0>) does not honor the contain/exclude routing due to routing nodes: 



# use different directive, if needed to close timing. 
#route_design -directive Explore
#route_design -directive AggressiveExplore
# Suppressing [Constraints  18-901] above won't work.
if { [catch {route_design -directive AggressiveExplore}] } {
  puts stderr "CRITICAL WARNING: route_design may found some problem. Please check log file."
}

if {$store_checkpoint} {
  write_checkpoint post_route.dcp -force
  report_route_status
}
#
#
#
## only bit for static is needed.  Bits for RPs are just for testing and can be omitted. 
#write_bitstream ${full_shell_name}.bit -force
#
#
##############################################################################
## Write abstract and full shell
##############################################################################
#write_abstract_shell -cell video_cp_i/composable/pr_0 abs_shell_PR0.dcp
#
##update_design -cell video_cp_i/composable/pr_0 -black_box
##update_design -cell video_cp_i/composable/pr_1 -black_box
##update_design -cell video_cp_i/composable/pr_2 -black_box
##lock_design -level routing
##write_checkpoint ${full_shell_name}.dcp



