# Copyright (C) 2021 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause

# Get project name from the arguments
set proj_name [lindex $argv 2]

# Get FPGA part
set fpga_part [lindex $argv 3]

# Get period
set period [lindex $argv 4]

# Get vitis library path
set vitis_lib_include [lindex $argv 5]

# Get device macro
set device_macro [lindex $argv 6]

#Create Project
open_project ${proj_name}.vhlsprj

#Add source file, set top, set FPGA part, set clock period and name solution
set_top ${proj_name}_accel
add_files ../../../../src/${proj_name}/${proj_name}.cpp -cflags "-I${vitis_lib_include} -D${device_macro}"
open_solution "solution1" -flow_target vivado
set_part ${fpga_part}
create_clock -period ${period} -name default

#Synthesize and export IP using Vivado flow
config_export -format ip_catalog -rtl verilog
csynth_design
#export_design -flow impl -rtl verilog -format ip_catalog
export_design -rtl verilog -format ip_catalog
exit