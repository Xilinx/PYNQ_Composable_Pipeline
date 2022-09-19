set TIME_start [clock seconds]
# usage
# vivado -source implement_rm.tcl -tclargs /group/zircon2/pongsto/projects/PYNQ_pipeline/homogeneous_3rp/implementation/project/cv_dfx_3_12k16kfifo composable_pr_1_cornerharris_fifo
# 

#if { $argc != 1 } {
#  puts "Need RM module name, eg., AES128."
#}
#
#;# set rm_inst to match the name under synth_1 directory
#set rm_inst  [lindex $argv 0]_rp2_inst_0
#;# any name
#set bit_name [lindex $argv 0]_rp2_RP2
##set rm_inst  AES128_rp2_inst_0
##set bit_name AES128_rp2_RP2
#
# make this two into args
if { $argc != 2 } {
  puts "Need the project name under projects directory to collect design and the function name."
# cv_dfx_3_12k16kfifo_2   and composable_pr_1_cornerharris_fifo    
}


set prj_name [file tail [lindex $argv 0]]
set proj_dir [file dirname [lindex $argv 0]]
set function [lindex $argv 1]
set root_dir "../../"

puts "proj_dir $proj_dir"
puts "prj_name $prj_name"
puts "function $function"

set bit_name $function

#set script_dir [file dirname [info script]]

set TIME_step_start [clock seconds]
set part xck26-sfvc784-2LV-c
create_project -in_memory -part $part

# how to get video_cp more elegantly
set bd_dir    ${root_dir}/${prj_name}/${prj_name}.gen/sources_1/bd/video_cp/bd/
set synth_dir ${root_dir}/${prj_name}/${prj_name}.runs/


add_files -quiet ${root_dir}/abs_shell_PR0.dcp
set_param project.isImplRun true
add_files -quiet ${bd_dir}/${function}/${function}.bd
add_files -quiet ${synth_dir}/${function}_synth_1/${function}.dcp
set_param project.isImplRun false
set_property SCOPED_TO_CELLS video_cp_i/composable/pr_0 [get_files ${synth_dir}/${function}_synth_1/${function}.dcp]
set_param project.isImplRun true
link_design -top video_cp_wrapper -part xck26-sfvc784-2LV-c -reconfig_partitions {video_cp_i/composable/pr_0} 
set_param project.isImplRun false


set time_create_proj [expr {([clock seconds] - $TIME_step_start)}]

set TIME_step_start [clock seconds]
opt_design -directive Explore
set time_opt [expr {([clock seconds] - $TIME_step_start)}]


set TIME_step_start [clock seconds]
#place_design -quiet;
place_design -directive ExtraNetDelay_low 
set time_place [expr {([clock seconds] - $TIME_step_start)}]
#write_checkpoint post_place.dcp
#set_param hd.numberOfProgrammingUnitsForHorizontalExpansion 1
#set pips [get_pips_from_file   "../pips.txt"]
#puts "Disable [llength $pips] from routing."
#route_design -disable_arcs $pips -quiet
# to implement in RP2, need to disable uturn on the top
#set pips [get_pips_from_file   "./top_uturn_arcs.txt"]
#puts "Disable [llength $pips] of uturn on the top from routing."
#route_design -disable_arcs $pips -quiet
 

set TIME_step_start [clock seconds]
#route_design -quiet
route_design -directive NoTimingRelaxation
#write_checkpoint post_route.dcp
set time_route [expr {([clock seconds] - $TIME_step_start)}]

#report_route_status
#report_timing
#write_checkpoint post_route.dcp

## Need this only to relocate dcp for checking
#set TIME_step_start [clock seconds]
#write_checkpoint -quiet -cell video_cp_i/composable/pr_0 ${bit_name}.dcp
#set time_dcp [expr {([clock seconds] - $TIME_step_start)}]



set TIME_step_start [clock seconds]
write_bitstream -cell video_cp_i/composable/pr_0 ${bit_name}.bit
set time_bitstream [expr {([clock seconds] - $TIME_step_start)}]

set time_total [expr {([clock seconds] - $TIME_start)}]

puts "\n"
puts "Create project   time : $time_create_proj seconds."
puts "opt_design       time : $time_opt seconds."
puts "place_design     time : $time_place seconds."
puts "rouite_design    time : $time_route seconds."
#puts "Write checkpoint time : $time_dcp seconds."
puts "Write bitstream  time : $time_bitstream seconds."
puts "Total time            : $time_total seconds."



