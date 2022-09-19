###############################################################################
# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause
###############################################################################
###############################################################################
#
#
# @file cv_dfx_3_pr.tcl
#
# Vivado tcl script to generate composable pipeline full and partial bitstreams 
# for Kria Vision Started Kit KV260 board
#
# <pre>
# MODIFICATION HISTORY:
#
# Ver   Who  Date     Changes
# ----- --- -------- -----------------------------------------------
# 1.00a mr   7/20/2021 Initial design
#
# 1.10a mr   8/23/2021 Fix FIFOs for forked pipelines
#
# 1.20a mr   9/12/2021 Enable MIPI, add IIC and merge soft reset IP cores
#
# 1.30  mr   11/26/2021 Reduce buffering in the MIPI hierarchy, use equal size FIFO
#                       in the branch.
#
# 1.40  mr   02/15/2022 update to 2021.2, remove any IP between the DFX decouplers
#                       and the PR regions
#
# 2.00  mr   03/30/2022 update to 2022.1, use BDC containers for the DFX regions
#
# 2.01  mr   04/11/2022 Move BDC and DFX commands to a separate file
#
# 3.00  mr   06/05/2022 Use 3 DFX regions, move duplicate to the static portion
#
# 3.10  mr   06/10/2022 Replace duplicate IP with AXI4-Stream broadcaster
#
# 3.11  mr   07/07/2022 Connect buffer FIFOs to the broadcaster output
#
# 3.20  mr   09/09/2022 Include HW contract to enable relocation
#
# 3.20  mr   09/19/2022 Add hw_contract cell hierarchy needed for relocation
#
# </pre>
#
###############################################################################


################################################################
# This is a generated script based on design: video_cp
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}

}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source cv_dfx_3_pr.tcl

# Add user local board path and check if the board file exists
set_param board.repoPaths [get_property LOCAL_ROOT_DIR [xhub::get_xstores xilinx_board_store]]

set board [get_board_parts "*:kv260*" -latest_file_version]
if { ${board} eq "" } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "${board} board file is not found. Please install the board file either manually or using the Xilinx Board Store"}
   return 1
}

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./${prj_name}/${prj_name}.xpr> in the current working folder.

set prj_name "cv_dfx_3_pr"
set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project ${prj_name} ${prj_name} -part xck26-sfvc784-2LV-c
   set_property BOARD_PART ${board} [current_project]
}

# Set IP repo
set_property ip_repo_paths "./../Pynq-ZU/ip/ ../ip/boards/ip" [current_project]
update_ip_catalog

# Add constraints files
add_files -fileset constrs_1 -norecurse cv_dfx_3_pr.xdc
add_files -fileset constrs_1 -norecurse pinout.xdc

# CHANGE DESIGN NAME HERE
variable design_name
set design_name "video_cp"
# cp stands for composable pipeline
# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\
xilinx.com:ip:axi_iic:2.1\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:zynq_ultra_ps_e:3.4\
xilinx.com:ip:dfx_axi_shutdown_manager:1.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:axi_register_slice:2.1\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:axis_dwidth_converter:1.1\
xilinx.com:ip:axis_switch:1.1\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:hls:colorthresholding_accel:1.0\
xilinx.com:hls:filter2d_accel:1.0\
xilinx.com:hls:gray2rgb_accel:1.0\
xilinx.com:hls:lut_accel:1.0\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:hls:rgb2gray_accel:1.0\
xilinx.com:hls:rgb2hsv_accel:1.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:axi_vdma:6.3\
xilinx.com:ip:axis_subset_converter:1.1\
xilinx.com:ip:v_demosaic:1.1\
xilinx.com:ip:v_gamma_lut:1.1\
xilinx.com:ip:mipi_csi2_rx_subsystem:5.1\
xilinx.com:hls:pixel_pack_2:1.0\
xilinx.com:ip:v_proc_ss:2.3\
xilinx.com:hls:pixel_unpack_2:1.0\
xilinx.com:ip:dfx_decoupler:1.0\
xilinx.com:ip:axis_register_slice:1.1\
xilinx.com:ip:xlslice:1.0\
xilinx.com:hls:fast_accel:1.0\
xilinx.com:hls:dilate_accel:1.0\
xilinx.com:hls:erode_accel:1.0\
xilinx.com:hls:subtract_accel:1.0\
xilinx.com:hls:rgb2xyz_accel:1.0\
xilinx.com:ip:axis_broadcaster:1.1\
xilinx.com:ip:util_ds_buf:2.2\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################

# Hierarchical cell: pr_homogeneous
proc create_hier_cell_dfx_homogeneous_interfaces { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_dfx_homogeneous_interfaces() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out1


  # Create pins
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn

  # Create instance: smartconnect, and set properties
  set smartconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {2} \
   CONFIG.NUM_SI {1}\
  ] $smartconnect

  set asr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 asr ]

  # Create instance: dilate_accel, and set properties
  set dilate_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:dilate_accel:1.0 dilate_accel ]

  # Create instance: erode_accel, and set properties
  set erode_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:erode_accel:1.0 erode_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_0 [get_bd_intf_pins stream_in0] [get_bd_intf_pins dilate_accel/stream_in]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_1 [get_bd_intf_pins stream_in1] [get_bd_intf_pins erode_accel/stream_in]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_lite_pr_0 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins asr/S_AXI]
  connect_bd_intf_net -intf_net asr_m_axi [get_bd_intf_pins asr/M_AXI] [get_bd_intf_pins smartconnect/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_m00 [get_bd_intf_pins smartconnect/M00_AXI] [get_bd_intf_pins dilate_accel/s_axi_control]
  connect_bd_intf_net -intf_net smartconnect_m01 [get_bd_intf_pins smartconnect/M01_AXI] [get_bd_intf_pins erode_accel/s_axi_control]
  connect_bd_intf_net -intf_net dilate_accel_stream_out [get_bd_intf_pins stream_out0] [get_bd_intf_pins dilate_accel/stream_out]
  connect_bd_intf_net -intf_net erode_accel_stream_out [get_bd_intf_pins stream_out1] [get_bd_intf_pins erode_accel/stream_out]

  # Create port connections
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins dilate_accel/ap_clk] [get_bd_pins erode_accel/ap_clk] [get_bd_pins smartconnect/aclk] [get_bd_pins asr/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins dilate_accel/ap_rst_n] [get_bd_pins erode_accel/ap_rst_n] [get_bd_pins smartconnect/aresetn] [get_bd_pins asr/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: dfx_decouplers
proc create_hier_cell_dfx_decouplers { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_dfx_decouplers() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S05_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_0_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_0_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_1_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_2_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_2_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_0_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_0_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_1_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_2_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_2_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_lite_pr_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_lite_pr_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_lite_pr_2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_0_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_0_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_1_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_1_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_2_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_2_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_0_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_0_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_1_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_1_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_2_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_2_1


  # Create pins
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type clk clk_300MHz_pr_0
  create_bd_pin -dir I -type clk clk_300MHz_pr_1
  create_bd_pin -dir I -type clk clk_300MHz_pr_2
  create_bd_pin -dir O -type rst rp_resetn_pr_0
  create_bd_pin -dir O -type rst rp_resetn_pr_1
  create_bd_pin -dir O -type rst rp_resetn_pr_2
  create_bd_pin -dir I -type rst clk_300MHz_aresetn
  create_bd_pin -dir I -from 5 -to 0 dfx_decouple
  create_bd_pin -dir O -from 5 -to 0 dfx_status
  create_bd_pin -dir I -type rst soft_rst_n

  # Create instance: axi_register_slice, and set properties
  set axi_register_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice ]

  # Create instance: axisreg_m_pr_0_0, and set properties
  set axisreg_m_pr_0_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axisreg_m_pr_0_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axisreg_m_pr_0_0

  # Create instance: axisreg_m_pr_0_1, and set properties
  set axisreg_m_pr_0_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axisreg_m_pr_0_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axisreg_m_pr_0_1

  # Create instance: axisreg_m_pr_1_0, and set properties
  set axisreg_m_pr_1_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axisreg_m_pr_1_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axisreg_m_pr_1_0

  # Create instance: axisreg_m_pr_1_1, and set properties
  set axisreg_m_pr_1_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axisreg_m_pr_1_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axisreg_m_pr_1_1

  # Create instance: axisreg_m_pr_2_0, and set properties
  set axisreg_m_pr_2_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axisreg_m_pr_2_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axisreg_m_pr_2_0

  # Create instance: axisreg_m_pr_2_1, and set properties
  set axisreg_m_pr_2_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axisreg_m_pr_2_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axisreg_m_pr_2_1

  # Create instance: axi_interconnect, and set properties
  set axi_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {1} \
 ] $axi_interconnect

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {6} \
 ] $xlconcat_0

  # Create instance: xlslice_pr_0, and set properties
  set xlslice_pr_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_pr_0 ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {6} \
 ] $xlslice_pr_0

  # Create instance: xlslice_pr_1, and set properties
  set xlslice_pr_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_pr_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {6} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_pr_1

  # Create instance: xlslice_pr_2, and set properties
  set xlslice_pr_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_pr_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {6} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_pr_2

  create_hier_cell_hw_contract $hier_obj hw_contract {0x8012 0x8013 0x8014}

  # Create interface connections
  connect_bd_intf_net -intf_net hw_contract_0_rp_in_0 [get_bd_intf_pins hw_contract/rp_in_0] [get_bd_intf_pins m_axis_pr_0_0]
  connect_bd_intf_net -intf_net hw_contract_0_rp_in_1 [get_bd_intf_pins hw_contract/rp_in_1] [get_bd_intf_pins m_axis_pr_0_1]
  connect_bd_intf_net -intf_net hw_contract_1_rp_in_0 [get_bd_intf_pins hw_contract/rp_in_2] [get_bd_intf_pins m_axis_pr_1_0]
  connect_bd_intf_net -intf_net hw_contract_1_rp_in_1 [get_bd_intf_pins hw_contract/rp_in_3] [get_bd_intf_pins m_axis_pr_1_1]
  connect_bd_intf_net -intf_net hw_contract_2_rp_in_0 [get_bd_intf_pins hw_contract/rp_in_4] [get_bd_intf_pins m_axis_pr_2_0]
  connect_bd_intf_net -intf_net hw_contract_2_rp_in_1 [get_bd_intf_pins hw_contract/rp_in_5] [get_bd_intf_pins m_axis_pr_2_1]

  connect_bd_intf_net -intf_net s_axis_pr_0_0 [get_bd_intf_pins s_axis_pr_0_0] [get_bd_intf_pins hw_contract/rp_out_0]
  connect_bd_intf_net -intf_net s_axis_pr_0_1 [get_bd_intf_pins s_axis_pr_0_1] [get_bd_intf_pins hw_contract/rp_out_1]
  connect_bd_intf_net -intf_net s_axis_pr_1_0 [get_bd_intf_pins s_axis_pr_1_0] [get_bd_intf_pins hw_contract/rp_out_2]
  connect_bd_intf_net -intf_net s_axis_pr_1_1 [get_bd_intf_pins s_axis_pr_1_1] [get_bd_intf_pins hw_contract/rp_out_3]
  connect_bd_intf_net -intf_net s_axis_pr_2_0 [get_bd_intf_pins s_axis_pr_2_0] [get_bd_intf_pins hw_contract/rp_out_4]
  connect_bd_intf_net -intf_net s_axis_pr_2_1 [get_bd_intf_pins s_axis_pr_2_1] [get_bd_intf_pins hw_contract/rp_out_5]

  connect_bd_intf_net -intf_net axi_interconnect_M00_AXI [get_bd_intf_pins axi_interconnect/M00_AXI] [get_bd_intf_pins hw_contract/S_AXI0]
  connect_bd_intf_net -intf_net axi_interconnect_M01_AXI [get_bd_intf_pins axi_interconnect/M01_AXI] [get_bd_intf_pins hw_contract/S_AXI1]
  connect_bd_intf_net -intf_net axi_interconnect_M02_AXI [get_bd_intf_pins axi_interconnect/M02_AXI] [get_bd_intf_pins hw_contract/S_AXI2]

  connect_bd_intf_net -intf_net hw_contract_0_s_out_0 [get_bd_intf_pins m_axis_dfx_pr_0_0] [get_bd_intf_pins hw_contract/M_AXIS_rp_2_s_0]
  connect_bd_intf_net -intf_net hw_contract_0_s_out_1 [get_bd_intf_pins m_axis_dfx_pr_0_1] [get_bd_intf_pins hw_contract/M_AXIS_rp_2_s_1]
  connect_bd_intf_net -intf_net hw_contract_1_s_out_0 [get_bd_intf_pins m_axis_dfx_pr_1_0] [get_bd_intf_pins hw_contract/M_AXIS_rp_2_s_2]
  connect_bd_intf_net -intf_net hw_contract_1_s_out_1 [get_bd_intf_pins m_axis_dfx_pr_1_1] [get_bd_intf_pins hw_contract/M_AXIS_rp_2_s_3]
  connect_bd_intf_net -intf_net hw_contract_2_s_out_0 [get_bd_intf_pins m_axis_dfx_pr_2_0] [get_bd_intf_pins hw_contract/M_AXIS_rp_2_s_4]
  connect_bd_intf_net -intf_net hw_contract_2_s_out_1 [get_bd_intf_pins m_axis_dfx_pr_2_1] [get_bd_intf_pins hw_contract/M_AXIS_rp_2_s_5]

  connect_bd_intf_net -intf_net axisreg_m_pr_0_0_m_axis [get_bd_intf_pins axisreg_m_pr_0_0/M_AXIS] [get_bd_intf_pins hw_contract/s_axis_s_2_rp_0]
  connect_bd_intf_net -intf_net axisreg_m_pr_0_1_m_axis [get_bd_intf_pins axisreg_m_pr_0_1/M_AXIS] [get_bd_intf_pins hw_contract/s_axis_s_2_rp_1]
  connect_bd_intf_net -intf_net axisreg_m_pr_1_0_m_axis [get_bd_intf_pins axisreg_m_pr_1_0/M_AXIS] [get_bd_intf_pins hw_contract/s_axis_s_2_rp_2]
  connect_bd_intf_net -intf_net axisreg_m_pr_1_1_m_axis [get_bd_intf_pins axisreg_m_pr_1_1/M_AXIS] [get_bd_intf_pins hw_contract/s_axis_s_2_rp_3]
  connect_bd_intf_net -intf_net axisreg_m_pr_2_0_m_axis [get_bd_intf_pins axisreg_m_pr_2_0/M_AXIS] [get_bd_intf_pins hw_contract/s_axis_s_2_rp_4]
  connect_bd_intf_net -intf_net axisreg_m_pr_2_1_m_axis [get_bd_intf_pins axisreg_m_pr_2_1/M_AXIS] [get_bd_intf_pins hw_contract/s_axis_s_2_rp_5]

  connect_bd_intf_net -intf_net hw_contract_pr0_s_axi_lite [get_bd_intf_pins hw_contract/s_axi_lite0] [get_bd_intf_pins s_axi_lite_pr_0]
  connect_bd_intf_net -intf_net hw_contract_pr1_s_axi_lite [get_bd_intf_pins hw_contract/s_axi_lite1] [get_bd_intf_pins s_axi_lite_pr_1]
  connect_bd_intf_net -intf_net hw_contract_pr2_s_axi_lite [get_bd_intf_pins hw_contract/s_axi_lite2] [get_bd_intf_pins s_axi_lite_pr_2]

  connect_bd_intf_net -intf_net s_axis_dfx_pr_0_0 [get_bd_intf_pins s_axis_dfx_pr_0_0] [get_bd_intf_pins axisreg_m_pr_0_0/S_AXIS]
  connect_bd_intf_net -intf_net s_axis_dfx_pr_0_1 [get_bd_intf_pins s_axis_dfx_pr_0_1] [get_bd_intf_pins axisreg_m_pr_0_1/S_AXIS]
  connect_bd_intf_net -intf_net s_axis_dfx_pr_1_0 [get_bd_intf_pins s_axis_dfx_pr_1_0] [get_bd_intf_pins axisreg_m_pr_1_0/S_AXIS]
  connect_bd_intf_net -intf_net s_axis_dfx_pr_1_1 [get_bd_intf_pins s_axis_dfx_pr_1_1] [get_bd_intf_pins axisreg_m_pr_1_1/S_AXIS]
  connect_bd_intf_net -intf_net s_axis_dfx_pr_2_0 [get_bd_intf_pins s_axis_dfx_pr_2_0] [get_bd_intf_pins axisreg_m_pr_2_0/S_AXIS]
  connect_bd_intf_net -intf_net s_axis_dfx_pr_2_1 [get_bd_intf_pins s_axis_dfx_pr_2_1] [get_bd_intf_pins axisreg_m_pr_2_1/S_AXIS]

  connect_bd_intf_net -intf_net S_AXI_INTERCONNECT_1 [get_bd_intf_pins S05_AXI] [get_bd_intf_pins axi_register_slice/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins axi_register_slice/M_AXI] [get_bd_intf_pins axi_interconnect/S00_AXI]


  # Create port connections
  connect_bd_net -net main_clk [get_bd_pins clk_300MHz] [get_bd_pins axi_register_slice/aclk] [get_bd_pins axi_interconnect/ACLK] [get_bd_pins axi_interconnect/S00_ACLK] [get_bd_pins axi_interconnect/M00_ACLK] [get_bd_pins axi_interconnect/M01_ACLK] [get_bd_pins axi_interconnect/M02_ACLK] [get_bd_pins axi_interconnect/M03_ACLK] [get_bd_pins axi_interconnect/M04_ACLK] [get_bd_pins axi_interconnect/M05_ACLK] [get_bd_pins axisreg_m_pr_0_0/aclk] [get_bd_pins axisreg_m_pr_0_1/aclk] [get_bd_pins axisreg_m_pr_1_0/aclk] [get_bd_pins axisreg_m_pr_1_1/aclk] [get_bd_pins axisreg_m_pr_2_0/aclk] [get_bd_pins axisreg_m_pr_2_1/aclk] [get_bd_pins hw_contract/clk_300MHz]
  connect_bd_net -net decouple [get_bd_pins dfx_decouple] [get_bd_pins xlslice_pr_0/Din] [get_bd_pins xlslice_pr_1/Din] [get_bd_pins xlslice_pr_2/Din]
  connect_bd_net -net peripheral_aresetn [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axi_register_slice/aresetn] [get_bd_pins axi_interconnect/ARESETN] [get_bd_pins axi_interconnect/S00_ARESETN] [get_bd_pins axi_interconnect/M00_ARESETN] [get_bd_pins axi_interconnect/M01_ARESETN] [get_bd_pins axi_interconnect/M02_ARESETN] [get_bd_pins axi_interconnect/M03_ARESETN] [get_bd_pins axi_interconnect/M04_ARESETN] [get_bd_pins axi_interconnect/M05_ARESETN] [get_bd_pins hw_contract/clk_300MHz_aresetn]
  connect_bd_net -net soft_reset [get_bd_pins soft_rst_n] [get_bd_pins axisreg_m_pr_0_0/aresetn] [get_bd_pins axisreg_m_pr_0_1/aresetn] [get_bd_pins axisreg_m_pr_1_0/aresetn] [get_bd_pins axisreg_m_pr_1_1/aresetn] [get_bd_pins axisreg_m_pr_2_0/aresetn] [get_bd_pins axisreg_m_pr_2_1/aresetn] [get_bd_pins hw_contract/soft_rst_n]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins dfx_status] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlslice_pr_0_Dout [get_bd_pins xlslice_pr_0/Dout] [get_bd_pins hw_contract/decouple_pr0]
  connect_bd_net -net xlslice_pr_1_Dout [get_bd_pins xlslice_pr_1/Dout] [get_bd_pins hw_contract/decouple_pr1]
  connect_bd_net -net xlslice_pr_2_Dout [get_bd_pins xlslice_pr_2/Dout] [get_bd_pins hw_contract/decouple_pr2]
  connect_bd_net -net hw_contract_rp_resetn_rp0 [get_bd_pins rp_resetn_pr_0] [get_bd_pins hw_contract/rp_resetn_rp0]
  connect_bd_net -net hw_contract_rp_resetn_rp1 [get_bd_pins rp_resetn_pr_1] [get_bd_pins hw_contract/rp_resetn_rp1]
  connect_bd_net -net hw_contract_rp_resetn_rp2 [get_bd_pins rp_resetn_pr_2] [get_bd_pins hw_contract/rp_resetn_rp2]
  connect_bd_net -net clk_300MHz_rp0 [get_bd_pins clk_300MHz_pr_0] [get_bd_pins hw_contract/clk_300MHz_rp0]
  connect_bd_net -net clk_300MHz_rp1 [get_bd_pins clk_300MHz_pr_1] [get_bd_pins hw_contract/clk_300MHz_rp1]
  connect_bd_net -net clk_300MHz_rp2 [get_bd_pins clk_300MHz_pr_2] [get_bd_pins hw_contract/clk_300MHz_rp2]
  connect_bd_net -net dfx_decoupler_0_decouple_status [get_bd_pins hw_contract/decouple_status_rp0] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net dfx_decoupler_1_decouple_status [get_bd_pins hw_contract/decouple_status_rp1] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net dfx_decoupler_2_decouple_status [get_bd_pins hw_contract/decouple_status_rp2] [get_bd_pins xlconcat_0/In5]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: video
proc create_hier_cell_video { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_video() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MM2S

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_INTERCONNECT


  # Create pins
  create_bd_pin -dir I -type clk clk_100MHz
  create_bd_pin -dir I -type rst clk_100MHz_aresetn
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn
  create_bd_pin -dir O -type intr mm2s_introut
  create_bd_pin -dir O -type intr s2mm_introut

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
 ] $axi_interconnect_0

  # Create instance: axi_vdma, and set properties
  set axi_vdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma ]
  set_property -dict [ list \
   CONFIG.c_addr_width {32} \
   CONFIG.c_m_axi_mm2s_data_width {128} \
   CONFIG.c_m_axi_s2mm_data_width {128} \
   CONFIG.c_m_axis_mm2s_tdata_width {64} \
   CONFIG.c_mm2s_linebuffer_depth {2048} \
   CONFIG.c_mm2s_max_burst_length {256} \
   CONFIG.c_num_fstores {4} \
   CONFIG.c_s2mm_linebuffer_depth {4096} \
   CONFIG.c_s2mm_max_burst_length {256} \
 ] $axi_vdma

  # Create instance: axis_dwidth_48_24, and set properties
  set axis_dwidth_48_24 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_48_24 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {3} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_dwidth_48_24

  # Create instance: axis_dwidth_24_48, and set properties
  set axis_dwidth_24_48 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_24_48 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_dwidth_24_48

  # Create instance: pixel_pack, and set properties
  set pixel_pack [ create_bd_cell -type ip -vlnv xilinx.com:hls:pixel_pack_2:1.0 pixel_pack ]

  # Create instance: pixel_reorder_s2mm, and set properties
  set pixel_reorder_s2mm [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 pixel_reorder_s2mm ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TDATA_REMAP {tdata[47:40],tdata[31:24],tdata[39:32],tdata[23:16],tdata[7:0],tdata[15:8]} \
 ] $pixel_reorder_s2mm

  # Create instance: pixel_reorder_mm2s, and set properties
  set pixel_reorder_mm2s [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 pixel_reorder_mm2s ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TDATA_REMAP {tdata[47:40],tdata[31:24],tdata[39:32],tdata[23:16],tdata[7:0],tdata[15:8]} \
 ] $pixel_reorder_mm2s

  # Create instance: pixel_unpack, and set properties
  set pixel_unpack [ create_bd_cell -type ip -vlnv xilinx.com:hls:pixel_unpack_2:1.0 pixel_unpack ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_dwidth_48_24/M_AXIS]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_dwidth_24_48/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_24_48_m [get_bd_intf_pins axis_dwidth_24_48/M_AXIS] [get_bd_intf_pins pixel_reorder_s2mm/S_AXIS]
  connect_bd_intf_net -intf_net S_AXI_CPU_IN_2 [get_bd_intf_pins S_AXI_INTERCONNECT] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_vdma/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins axi_vdma/M_AXIS_MM2S] [get_bd_intf_pins pixel_unpack/stream_in_64]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins M_AXI_MM2S] [get_bd_intf_pins axi_vdma/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_vdma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net pixel_pack_0_stream_out_64 [get_bd_intf_pins axi_vdma/S_AXIS_S2MM] [get_bd_intf_pins pixel_pack/stream_out_64]
  connect_bd_intf_net -intf_net pixel_reorder_M_AXIS [get_bd_intf_pins pixel_pack/stream_in_48] [get_bd_intf_pins pixel_reorder_s2mm/M_AXIS]
  connect_bd_intf_net -intf_net pixel_unpack_stream_out_48 [get_bd_intf_pins pixel_unpack/stream_out_48] [get_bd_intf_pins pixel_reorder_mm2s/S_AXIS]
  connect_bd_intf_net -intf_net pixel_pixel_reorder_mm2s [get_bd_intf_pins pixel_reorder_mm2s/M_AXIS] [get_bd_intf_pins axis_dwidth_48_24/S_AXIS]
  connect_bd_intf_net -intf_net s_axi_control1_1 [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins pixel_pack/s_axi_control]
  connect_bd_intf_net -intf_net s_axi_control_2 [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins pixel_unpack/s_axi_control]
  # Create port connections
  connect_bd_net -net axi_vdma_0_mm2s_introut [get_bd_pins mm2s_introut] [get_bd_pins axi_vdma/mm2s_introut]
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins axi_vdma/s2mm_introut]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_vdma/m_axi_mm2s_aclk] [get_bd_pins axi_vdma/m_axi_s2mm_aclk] [get_bd_pins axi_vdma/m_axis_mm2s_aclk] [get_bd_pins axi_vdma/s_axis_s2mm_aclk] [get_bd_pins axis_dwidth_48_24/aclk] [get_bd_pins axis_dwidth_24_48/aclk] [get_bd_pins pixel_pack/ap_clk] [get_bd_pins pixel_reorder_s2mm/aclk] [get_bd_pins pixel_reorder_mm2s/aclk] [get_bd_pins pixel_unpack/ap_clk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axis_dwidth_48_24/aresetn] [get_bd_pins axis_dwidth_24_48/aresetn] [get_bd_pins pixel_pack/ap_rst_n] [get_bd_pins pixel_reorder_s2mm/aresetn] [get_bd_pins pixel_reorder_mm2s/aresetn] [get_bd_pins pixel_unpack/ap_rst_n]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins clk_100MHz_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_vdma/axi_resetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins clk_100MHz] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_vdma/s_axi_lite_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mipi
proc create_hier_cell_mipi { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_mipi() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_INTERCONNECT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 cam_gpiorpi
  create_bd_pin -dir I -type clk clk_100MHz
  create_bd_pin -dir I -type rst clk_100MHz_aresetn
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn
  create_bd_pin -dir O -type intr csirxss_csi_irq
  create_bd_pin -dir I -type clk dphy_clk_200M
  create_bd_pin -dir O -type intr s2mm_introut

  # Create instance: axi_interconnect, and set properties
  set axi_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $axi_interconnect

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {7} \
 ] $axi_interconnect_1

  # Create instance: axi_vdma, and set properties
  set axi_vdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_m_axi_s2mm_data_width {128} \
   CONFIG.c_mm2s_genlock_mode {0} \
   CONFIG.c_num_fstores {8} \
   CONFIG.c_s2mm_linebuffer_depth {2048} \
   CONFIG.c_s2mm_max_burst_length {256} \
 ] $axi_vdma

  # Create instance: axis_channel_swap, and set properties
  set axis_channel_swap [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_channel_swap ]
  set_property -dict [ list \
   CONFIG.M_HAS_TKEEP {0} \
   CONFIG.M_HAS_TLAST {1} \
   CONFIG.M_HAS_TREADY {1} \
   CONFIG.M_HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.M_TUSER_WIDTH {1} \
   CONFIG.S_HAS_TKEEP {0} \
   CONFIG.S_HAS_TLAST {1} \
   CONFIG.S_HAS_TREADY {1} \
   CONFIG.S_HAS_TSTRB {0} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.S_TUSER_WIDTH {1} \
   CONFIG.TDATA_REMAP {tdata[39:24], tdata[47:40], tdata[15:0], tdata[23:16]} \
   CONFIG.TLAST_REMAP {tlast[0]} \
   CONFIG.TUSER_REMAP {tuser[0:0]} \
 ] $axis_channel_swap

  # Create instance: axis_dwidth_24_48, and set properties
  set axis_dwidth_24_48 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_24_48 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_dwidth_24_48

  # Create instance: axis_dwidth_48_24, and set properties
  set axis_dwidth_48_24 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_48_24 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {3} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_dwidth_48_24

  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [ list \
   CONFIG.M_HAS_TLAST {1} \
   CONFIG.M_TDATA_NUM_BYTES {2} \
   CONFIG.M_TDEST_WIDTH {10} \
   CONFIG.M_TUSER_WIDTH {1} \
   CONFIG.S_HAS_TLAST {1} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.S_TDEST_WIDTH {10} \
   CONFIG.S_TUSER_WIDTH {1} \
   CONFIG.TDATA_REMAP {tdata[19:12],tdata[9:2]} \
   CONFIG.TDEST_REMAP {tdest[9:0]} \
   CONFIG.TLAST_REMAP {tlast[0]} \
   CONFIG.TUSER_REMAP {tuser[0:0]} \
 ] $axis_subset_converter

  # Create instance: demosaic, and set properties
  set demosaic [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_demosaic:1.1 demosaic ]
  set_property -dict [ list \
   CONFIG.MAX_COLS {3840} \
   CONFIG.MAX_ROWS {2160} \
   CONFIG.SAMPLES_PER_CLOCK {2} \
   CONFIG.USE_URAM {1} \
 ] $demosaic

  # Create instance: gamma_lut, and set properties
  set gamma_lut [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_gamma_lut:1.1 gamma_lut ]
  set_property -dict [ list \
   CONFIG.MAX_COLS {3840} \
   CONFIG.MAX_ROWS {2160} \
   CONFIG.SAMPLES_PER_CLOCK {2} \
 ] $gamma_lut

  # Create instance: gpio_ip_reset, and set properties
  set gpio_ip_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 gpio_ip_reset ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_ALL_OUTPUTS_2 {1} \
   CONFIG.C_DOUT_DEFAULT {0x00000001} \
   CONFIG.C_DOUT_DEFAULT_2 {0x00000001} \
   CONFIG.C_GPIO2_WIDTH {1} \
   CONFIG.C_GPIO_WIDTH {1} \
   CONFIG.C_IS_DUAL {1} \
 ] $gpio_ip_reset

  # Create instance: mipi_csi2_rx_subsyst, and set properties
  set mipi_csi2_rx_subsyst [ create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem:5.1 mipi_csi2_rx_subsyst ]
  set_property -dict [ list \
   CONFIG.CLK_LANE_IO_LOC {D7} \
   CONFIG.CLK_LANE_IO_LOC_NAME {IO_L13P_T2L_N0_GC_QBC_66} \
   CONFIG.CMN_NUM_LANES {2} \
   CONFIG.CMN_NUM_PIXELS {2} \
   CONFIG.CMN_PXL_FORMAT {RAW10} \
   CONFIG.CSI_BUF_DEPTH {4096} \
   CONFIG.C_CLK_LANE_IO_POSITION {26} \
   CONFIG.C_CSI_FILTER_USERDATATYPE {true} \
   CONFIG.C_DATA_LANE0_IO_POSITION {28} \
   CONFIG.C_DATA_LANE1_IO_POSITION {30} \
   CONFIG.C_DPHY_LANES {2} \
   CONFIG.C_EN_BG0_PIN0 {false} \
   CONFIG.C_EN_BG1_PIN0 {false} \
   CONFIG.C_HS_LINE_RATE {672} \
   CONFIG.C_HS_SETTLE_NS {149} \
   CONFIG.DATA_LANE0_IO_LOC {E5} \
   CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L14P_T2L_N2_GC_66} \
   CONFIG.DATA_LANE1_IO_LOC {G6} \
   CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L15P_T2L_N4_AD11P_66} \
   CONFIG.DPY_EN_REG_IF {true} \
   CONFIG.DPY_LINE_RATE {672} \
   CONFIG.HP_IO_BANK_SELECTION {66} \
   CONFIG.SupportLevel {1} \
 ] $mipi_csi2_rx_subsyst

  # Create instance: pixel_pack, and set properties
  set pixel_pack [ create_bd_cell -type ip -vlnv xilinx.com:hls:pixel_pack_2:1.0 pixel_pack ]

  # Create instance: soft_reset, and set properties
  set soft_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 soft_reset ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {0} \
 ] $soft_reset

  # Create instance: v_proc_sys, and set properties
  set v_proc_sys [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_proc_ss:2.3 v_proc_sys ]
  set_property -dict [ list \
   CONFIG.C_COLORSPACE_SUPPORT {2} \
   CONFIG.C_CSC_ENABLE_WINDOW {false} \
   CONFIG.C_MAX_COLS {3840} \
   CONFIG.C_MAX_DATA_WIDTH {8} \
   CONFIG.C_MAX_ROWS {2160} \
   CONFIG.C_TOPOLOGY {3} \
 ] $v_proc_sys

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_dwidth_24_48/S_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_dwidth_48_24/M_AXIS]
  connect_bd_intf_net -intf_net axis_channel_swap_M_AXIS [get_bd_intf_pins axis_channel_swap/M_AXIS] [get_bd_intf_pins axis_dwidth_48_24/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_24_48_M_AXIS [get_bd_intf_pins axis_dwidth_24_48/M_AXIS] [get_bd_intf_pins pixel_pack/stream_in_48]
  connect_bd_intf_net -intf_net S_AXI_INTERCONNECT_1 [get_bd_intf_pins S_AXI_INTERCONNECT] [get_bd_intf_pins axi_interconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins pixel_pack/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins demosaic/s_axi_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_1_M02_AXI [get_bd_intf_pins axi_interconnect_1/M02_AXI] [get_bd_intf_pins gamma_lut/s_axi_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_1_M03_AXI [get_bd_intf_pins axi_interconnect_1/M03_AXI] [get_bd_intf_pins v_proc_sys/s_axi_ctrl]
  connect_bd_intf_net -intf_net axi_interconnect_1_M04_AXI [get_bd_intf_pins axi_interconnect_1/M04_AXI] [get_bd_intf_pins gpio_ip_reset/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M05_AXI [get_bd_intf_pins axi_interconnect_1/M05_AXI] [get_bd_intf_pins axi_vdma/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_1_M06_AXI [get_bd_intf_pins axi_interconnect_1/M06_AXI] [get_bd_intf_pins mipi_csi2_rx_subsyst/csirxss_s_axi]
  connect_bd_intf_net -intf_net axi_vdma_M_AXI_S2MM [get_bd_intf_pins axi_interconnect/S00_AXI] [get_bd_intf_pins axi_vdma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axi_interconnect_M_AXI_S2MM [get_bd_intf_pins axi_interconnect/M00_AXI] [get_bd_intf_pins M_AXI_S2MM]
  connect_bd_intf_net -intf_net axis_subset_converter_0_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins demosaic/s_axis_video]
  connect_bd_intf_net -intf_net dm0_m_axis_video [get_bd_intf_pins demosaic/m_axis_video] [get_bd_intf_pins gamma_lut/s_axis_video]
  connect_bd_intf_net -intf_net mipi_csi2_rx_subsyst_0_video_out [get_bd_intf_pins axis_subset_converter/S_AXIS] [get_bd_intf_pins mipi_csi2_rx_subsyst/video_out]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_pins mipi_phy_if] [get_bd_intf_pins mipi_csi2_rx_subsyst/mipi_phy_if]
  connect_bd_intf_net -intf_net pixel_pack_stream_out_64 [get_bd_intf_pins axi_vdma/S_AXIS_S2MM] [get_bd_intf_pins pixel_pack/stream_out_64]
  connect_bd_intf_net -intf_net v_proc_sys_m_axis [get_bd_intf_pins axis_channel_swap/S_AXIS] [get_bd_intf_pins v_proc_sys/m_axis]
  connect_bd_intf_net -intf_net vg0_m_axis_video [get_bd_intf_pins gamma_lut/m_axis_video] [get_bd_intf_pins v_proc_sys/s_axis]

  # Create port connections
  connect_bd_net -net soft_peripheral_aresetn [get_bd_pins axis_channel_swap/aresetn] [get_bd_pins demosaic/ap_rst_n] [get_bd_pins gamma_lut/ap_rst_n] [get_bd_pins pixel_pack/ap_rst_n] [get_bd_pins soft_reset/peripheral_aresetn] [get_bd_pins v_proc_sys/aresetn] [get_bd_pins axis_dwidth_24_48/aresetn] [get_bd_pins axis_dwidth_48_24/aresetn]
  connect_bd_net -net axi_vdma_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins axi_vdma/s2mm_introut]
  connect_bd_net -net ps_pl_clk1 [get_bd_pins dphy_clk_200M] [get_bd_pins mipi_csi2_rx_subsyst/dphy_clk_200M]
  connect_bd_net -net gpio_ip_reset_gpio2_io_o [get_bd_pins cam_gpiorpi] [get_bd_pins gpio_ip_reset/gpio2_io_o]
  connect_bd_net -net gpio_ip_reset_gpio_io_o [get_bd_pins gpio_ip_reset/gpio_io_o] [get_bd_pins soft_reset/aux_reset_in]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_csirxss_csi_irq [get_bd_pins csirxss_csi_irq] [get_bd_pins mipi_csi2_rx_subsyst/csirxss_csi_irq]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins axi_interconnect/ACLK] [get_bd_pins axi_interconnect/M00_ACLK] [get_bd_pins axi_interconnect/S00_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_1/M02_ACLK] [get_bd_pins axi_interconnect_1/M03_ACLK] [get_bd_pins axi_interconnect_1/M04_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_vdma/m_axi_s2mm_aclk] [get_bd_pins axi_vdma/s_axis_s2mm_aclk] [get_bd_pins axis_channel_swap/aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins demosaic/ap_clk] [get_bd_pins gamma_lut/ap_clk] [get_bd_pins gpio_ip_reset/s_axi_aclk] [get_bd_pins mipi_csi2_rx_subsyst/video_aclk] [get_bd_pins pixel_pack/ap_clk] [get_bd_pins soft_reset/slowest_sync_clk] [get_bd_pins v_proc_sys/aclk] [get_bd_pins axis_dwidth_24_48/aclk] [get_bd_pins axis_dwidth_48_24/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_1/M02_ARESETN] [get_bd_pins axi_interconnect_1/M03_ARESETN] [get_bd_pins axi_interconnect_1/M04_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins gpio_ip_reset/s_axi_aresetn] [get_bd_pins mipi_csi2_rx_subsyst/video_aresetn] [get_bd_pins soft_reset/ext_reset_in] [get_bd_pins axi_interconnect/ARESETN] [get_bd_pins axi_interconnect/M00_ARESETN] [get_bd_pins axi_interconnect/S00_ARESETN]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins clk_100MHz_aresetn] [get_bd_pins axi_interconnect_1/M05_ARESETN] [get_bd_pins axi_interconnect_1/M06_ARESETN] [get_bd_pins axi_vdma/axi_resetn] [get_bd_pins mipi_csi2_rx_subsyst/lite_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins clk_100MHz] [get_bd_pins axi_interconnect_1/M05_ACLK] [get_bd_pins axi_interconnect_1/M06_ACLK] [get_bd_pins axi_vdma/s_axi_lite_aclk] [get_bd_pins mipi_csi2_rx_subsyst/lite_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: composable
proc create_hier_cell_composable { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_composable() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS


  # Create pins
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn

  # Create instance: axi_register_slice, and set properties
  set axi_register_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice ]

  # Create instance: axis_data_fifo_branch_0_0, and set properties
  set axis_data_fifo_branch_0_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_branch_0_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {8192} \
   CONFIG.FIFO_MEMORY_TYPE {block} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {6} \
 ] $axis_data_fifo_branch_0_0

   # Create instance: axis_data_fifo_branch_0_1, and set properties
  set axis_data_fifo_branch_0_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_branch_0_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {4096} \
   CONFIG.FIFO_MEMORY_TYPE {block} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {6} \
 ] $axis_data_fifo_branch_0_1

  # Create instance: axis_data_fifo_branch_1_0, and set properties
  set axis_data_fifo_branch_1_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_branch_1_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16384} \
   CONFIG.FIFO_MEMORY_TYPE {ultra} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {6} \
 ] $axis_data_fifo_branch_1_0

  # Create instance: axis_downconv_branch_0, and set properties
  set axis_downconv_branch_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_downconv_branch_0 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {0} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {3} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_downconv_branch_0

  # Create instance: axis_downconv_branch_1, and set properties
  set axis_downconv_branch_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_downconv_branch_1 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {0} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {3} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_downconv_branch_1

  # Create instance: axis_switch, and set properties
  set axis_switch [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch ]
  set_property -dict [ list \
   CONFIG.DECODER_REG {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.NUM_MI {15} \
   CONFIG.NUM_SI {16} \
   CONFIG.ROUTING_MODE {1} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_switch

  # Create instance: axis_upconv_branch_0, and set properties
  set axis_upconv_branch_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_upconv_branch_0 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_upconv_branch_0

  # Create instance: axis_upconv_branch_1, and set properties
  set axis_upconv_branch_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_upconv_branch_1 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_upconv_branch_1

  # Create instance: clk_buf_rp0, clk_buf_rp1, clk_buf_rp2  and set properties
  for {set i 0} {$i < 3} {incr i} {
    set name "clk_buf_rp${i}"
    set ${name} [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 ${name} ]
    set_property -dict [ list CONFIG.C_BUF_TYPE {BUFG} ] [get_bd_cells ${name} ]
  }

  # Create instance: colorthresholding_accel, and set properties
  set colorthresholding_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:colorthresholding_accel:1.0 colorthresholding_accel ]

  # Create instance: dfx_decouplers
  create_hier_cell_dfx_decouplers $hier_obj dfx_decouplers

  # Create instance: filter2d_accel, and set properties
  set filter2d_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:filter2d_accel:1.0 filter2d_accel ]

  # Create instance: gray2rgb_accel, and set properties
  set gray2rgb_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:gray2rgb_accel:1.0 gray2rgb_accel ]

  # Create instance: lut_accel, and set properties
  set lut_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:lut_accel:1.0 lut_accel ]

  # Create instance: duplicate_accel, and set properties
  set duplicate_accel [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 duplicate_accel ]
  set_property -dict [ list \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.M00_TDATA_REMAP {tdata[23:0]} \
    CONFIG.M00_TUSER_REMAP {tuser[0:0]} \
    CONFIG.M01_TDATA_REMAP {tdata[23:0]} \
    CONFIG.M01_TUSER_REMAP {tuser[0:0]} \
    CONFIG.M_TDATA_NUM_BYTES {3} \
    CONFIG.M_TUSER_WIDTH {1} \
    CONFIG.S_TDATA_NUM_BYTES {3} \
    CONFIG.S_TUSER_WIDTH {1} \
 ] $duplicate_accel

  # Create instance: pipeline_control, and set properties
  set pipeline_control [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 pipeline_control ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO2_WIDTH {6} \
   CONFIG.C_GPIO_WIDTH {1} \
   CONFIG.C_IS_DUAL {1} \
 ] $pipeline_control

  # Create instance: pr_0
  create_hier_cell_dfx_homogeneous_interfaces $hier_obj pr_0

  # Create instance: pr_1
  create_hier_cell_dfx_homogeneous_interfaces $hier_obj pr_1

  # Create instance: pr_2
  create_hier_cell_dfx_homogeneous_interfaces $hier_obj pr_2

  # Create instance: ps_user_soft_reset, and set properties
  set ps_user_soft_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 ps_user_soft_reset ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH {1} \
] $ps_user_soft_reset

  # Create instance: rgb2gray_accel, and set properties
  set rgb2gray_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:rgb2gray_accel:1.0 rgb2gray_accel ]

  # Create instance: rgb2hsv_accel, and set properties
  set rgb2hsv_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:rgb2hsv_accel:1.0 rgb2hsv_accel ]

  # Create instance: smartconnect, and set properties
  set smartconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {9} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect

  # Create interface connections
  connect_bd_intf_net -intf_net lut_accel_stream_out [get_bd_intf_pins axis_switch/S03_AXIS] [get_bd_intf_pins lut_accel/stream_out]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_register_slice/S_AXI]
  connect_bd_intf_net -intf_net S01_AXIS_1 [get_bd_intf_pins S01_AXIS] [get_bd_intf_pins axis_switch/S01_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_VIDEO_IN_1 [get_bd_intf_pins S00_AXIS] [get_bd_intf_pins axis_switch/S00_AXIS]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins axi_register_slice/M_AXI] [get_bd_intf_pins smartconnect/S00_AXI]
  connect_bd_intf_net -intf_net axis_switch_M00_AXIS [get_bd_intf_pins axis_switch/M00_AXIS] [get_bd_intf_pins M00_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M01_AXIS [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins axis_switch/M01_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M02_AXIS [get_bd_intf_pins axis_switch/M02_AXIS] [get_bd_intf_pins filter2d_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M03_AXIS [get_bd_intf_pins axis_switch/M03_AXIS] [get_bd_intf_pins lut_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M04_AXIS [get_bd_intf_pins axis_switch/M04_AXIS] [get_bd_intf_pins rgb2gray_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M05_AXIS [get_bd_intf_pins axis_switch/M05_AXIS] [get_bd_intf_pins gray2rgb_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M06_AXIS [get_bd_intf_pins axis_switch/M06_AXIS] [get_bd_intf_pins rgb2hsv_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M07_AXIS [get_bd_intf_pins axis_switch/M07_AXIS] [get_bd_intf_pins colorthresholding_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M08_AXIS [get_bd_intf_pins axis_switch/M08_AXIS] [get_bd_intf_pins duplicate_accel/S_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M09_AXIS [get_bd_intf_pins axis_switch/M09_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_0_0]
  connect_bd_intf_net -intf_net axis_switch_M10_AXIS [get_bd_intf_pins axis_switch/M10_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_0_1]
  connect_bd_intf_net -intf_net axis_switch_M11_AXIS [get_bd_intf_pins axis_switch/M11_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_1_0]
  connect_bd_intf_net -intf_net axis_switch_M12_AXIS [get_bd_intf_pins axis_switch/M12_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_1_1]
  connect_bd_intf_net -intf_net axis_switch_M13_AXIS [get_bd_intf_pins axis_switch/M13_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_2_0]
  connect_bd_intf_net -intf_net axis_switch_M14_AXIS [get_bd_intf_pins axis_switch/M14_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_2_1]
  connect_bd_intf_net -intf_net duplicate_accel_stream_out  [get_bd_intf_pins axis_upconv_branch_0/S_AXIS] [get_bd_intf_pins duplicate_accel/M00_AXIS]
  connect_bd_intf_net -intf_net duplicate_accel_stream_out1 [get_bd_intf_pins axis_upconv_branch_1/S_AXIS] [get_bd_intf_pins duplicate_accel/M01_AXIS]
  connect_bd_intf_net -intf_net axis_downconv_branch_0_M_AXIS [get_bd_intf_pins axis_downconv_branch_0/M_AXIS] [get_bd_intf_pins axis_switch/S08_AXIS]
  connect_bd_intf_net -intf_net axis_downconv_branch_1_M_AXIS [get_bd_intf_pins axis_downconv_branch_1/M_AXIS] [get_bd_intf_pins axis_switch/S09_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_branch_0_0_M_AXIS [get_bd_intf_pins axis_data_fifo_branch_0_0/M_AXIS] [get_bd_intf_pins axis_data_fifo_branch_0_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_branch_0_1_M_AXIS [get_bd_intf_pins axis_data_fifo_branch_0_1/M_AXIS] [get_bd_intf_pins axis_downconv_branch_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_branch_1_0_M_AXIS [get_bd_intf_pins axis_data_fifo_branch_1_0/M_AXIS] [get_bd_intf_pins axis_downconv_branch_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_1_M_AXIS [get_bd_intf_pins axis_data_fifo_branch_0_0/S_AXIS] [get_bd_intf_pins axis_upconv_branch_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_2_M_AXIS [get_bd_intf_pins axis_data_fifo_branch_1_0/S_AXIS] [get_bd_intf_pins axis_upconv_branch_1/M_AXIS]
  connect_bd_intf_net -intf_net colorthresholding_accel_stream_out [get_bd_intf_pins axis_switch/S07_AXIS] [get_bd_intf_pins colorthresholding_accel/stream_out]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_0_0 [get_bd_intf_pins axis_switch/S10_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_0_0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_0_1 [get_bd_intf_pins axis_switch/S11_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_0_1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_1_0 [get_bd_intf_pins axis_switch/S12_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_1_0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_1_1 [get_bd_intf_pins axis_switch/S13_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_1_1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_2_0 [get_bd_intf_pins axis_switch/S14_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_2_0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_2_1 [get_bd_intf_pins axis_switch/S15_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_2_1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_0 [get_bd_intf_pins dfx_decouplers/m_axis_pr_0_0] [get_bd_intf_pins pr_0/stream_in0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_0_1] [get_bd_intf_pins pr_0/stream_in1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_1_0 [get_bd_intf_pins dfx_decouplers/m_axis_pr_1_0] [get_bd_intf_pins pr_1/stream_in0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_1_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_1_1] [get_bd_intf_pins pr_1/stream_in1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_2_0 [get_bd_intf_pins dfx_decouplers/m_axis_pr_2_0] [get_bd_intf_pins pr_2/stream_in0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_2_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_2_1] [get_bd_intf_pins pr_2/stream_in1]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_lite_pr_0 [get_bd_intf_pins dfx_decouplers/s_axi_lite_pr_0] [get_bd_intf_pins pr_0/s_axi_control]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_lite_pr_1 [get_bd_intf_pins dfx_decouplers/s_axi_lite_pr_1] [get_bd_intf_pins pr_1/s_axi_control]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_lite_pr_2 [get_bd_intf_pins dfx_decouplers/s_axi_lite_pr_2] [get_bd_intf_pins pr_2/s_axi_control]
  connect_bd_intf_net -intf_net filter2d_accel_stream_out [get_bd_intf_pins axis_switch/S02_AXIS] [get_bd_intf_pins filter2d_accel/stream_out]
  connect_bd_intf_net -intf_net gray2rgb_accel_stream_out [get_bd_intf_pins axis_switch/S05_AXIS] [get_bd_intf_pins gray2rgb_accel/stream_out]
  connect_bd_intf_net -intf_net rgb2gray_accel_stream_out [get_bd_intf_pins axis_switch/S04_AXIS] [get_bd_intf_pins rgb2gray_accel/stream_out]
  connect_bd_intf_net -intf_net rgb2hsv_accel_stream_out [get_bd_intf_pins axis_switch/S06_AXIS] [get_bd_intf_pins rgb2hsv_accel/stream_out]
  connect_bd_intf_net -intf_net s_axis_pr_0_0_1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_0_0] [get_bd_intf_pins pr_0/stream_out0]
  connect_bd_intf_net -intf_net s_axis_pr_0_1_1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_0_1] [get_bd_intf_pins pr_0/stream_out1]
  connect_bd_intf_net -intf_net s_axis_pr_1_0_1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_1_0] [get_bd_intf_pins pr_1/stream_out0]
  connect_bd_intf_net -intf_net s_axis_pr_1_1_1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_1_1] [get_bd_intf_pins pr_1/stream_out1]
  connect_bd_intf_net -intf_net s_axis_pr_2_1_0 [get_bd_intf_pins dfx_decouplers/s_axis_pr_2_0] [get_bd_intf_pins pr_2/stream_out0]
  connect_bd_intf_net -intf_net s_axis_pr_2_1_1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_2_1] [get_bd_intf_pins pr_2/stream_out1]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins axis_switch/S_AXI_CTRL] [get_bd_intf_pins smartconnect/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins filter2d_accel/s_axi_control] [get_bd_intf_pins smartconnect/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins rgb2gray_accel/s_axi_control] [get_bd_intf_pins smartconnect/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins gray2rgb_accel/s_axi_control] [get_bd_intf_pins smartconnect/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins rgb2hsv_accel/s_axi_control] [get_bd_intf_pins smartconnect/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins colorthresholding_accel/s_axi_control] [get_bd_intf_pins smartconnect/M05_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M06_AXI [get_bd_intf_pins lut_accel/s_axi_control] [get_bd_intf_pins smartconnect/M06_AXI]
  connect_bd_intf_net -intf_net smartconnect_M08_AXI [get_bd_intf_pins dfx_decouplers/S05_AXI] [get_bd_intf_pins smartconnect/M07_AXI]
  connect_bd_intf_net -intf_net smartconnect_M09_AXI [get_bd_intf_pins pipeline_control/S_AXI] [get_bd_intf_pins smartconnect/M08_AXI]

  # Create port connections
  connect_bd_net -net dfx_decouplers_gpio_out [get_bd_pins dfx_decouplers/dfx_status] [get_bd_pins pipeline_control/gpio2_io_i]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins axi_register_slice/aclk] [get_bd_pins axis_data_fifo_branch_0_0/s_axis_aclk] [get_bd_pins axis_data_fifo_branch_0_1/s_axis_aclk] [get_bd_pins axis_data_fifo_branch_1_0/s_axis_aclk] [get_bd_pins axis_downconv_branch_0/aclk] [get_bd_pins axis_downconv_branch_1/aclk] [get_bd_pins axis_switch/aclk] [get_bd_pins axis_switch/s_axi_ctrl_aclk] [get_bd_pins axis_upconv_branch_0/aclk] [get_bd_pins axis_upconv_branch_1/aclk] [get_bd_pins colorthresholding_accel/ap_clk] [get_bd_pins dfx_decouplers/clk_300MHz] [get_bd_pins filter2d_accel/ap_clk] [get_bd_pins gray2rgb_accel/ap_clk] [get_bd_pins lut_accel/ap_clk] [get_bd_pins duplicate_accel/aclk] [get_bd_pins pipeline_control/s_axi_aclk] [get_bd_pins ps_user_soft_reset/slowest_sync_clk] [get_bd_pins rgb2gray_accel/ap_clk] [get_bd_pins rgb2hsv_accel/ap_clk] [get_bd_pins smartconnect/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axi_register_slice/aresetn] [get_bd_pins axis_switch/aresetn] [get_bd_pins axis_switch/s_axi_ctrl_aresetn]  [get_bd_pins dfx_decouplers/clk_300MHz_aresetn] [get_bd_pins pipeline_control/s_axi_aresetn] [get_bd_pins ps_user_soft_reset/ext_reset_in] [get_bd_pins smartconnect/aresetn]
  connect_bd_net -net net_zynq_us_ss_soft_reset [get_bd_pins ps_user_soft_reset/peripheral_aresetn] [get_bd_pins axis_data_fifo_branch_0_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_branch_0_1/s_axis_aresetn] [get_bd_pins axis_data_fifo_branch_1_0/s_axis_aresetn] [get_bd_pins axis_downconv_branch_0/aresetn] [get_bd_pins axis_downconv_branch_1/aresetn] [get_bd_pins axis_upconv_branch_0/aresetn] [get_bd_pins axis_upconv_branch_1/aresetn] [get_bd_pins colorthresholding_accel/ap_rst_n] [get_bd_pins dfx_decouplers/soft_rst_n] [get_bd_pins filter2d_accel/ap_rst_n] [get_bd_pins gray2rgb_accel/ap_rst_n] [get_bd_pins lut_accel/ap_rst_n] [get_bd_pins duplicate_accel/aresetn] [get_bd_pins rgb2gray_accel/ap_rst_n] [get_bd_pins rgb2hsv_accel/ap_rst_n]
  connect_bd_net -net dfx_decouplers_rp_resetn_pr_0 [get_bd_pins dfx_decouplers/rp_resetn_pr_0] [get_bd_pins pr_0/clk_300MHz_aresetn]
  connect_bd_net -net dfx_decouplers_rp_resetn_pr_1 [get_bd_pins dfx_decouplers/rp_resetn_pr_1] [get_bd_pins pr_1/clk_300MHz_aresetn]
  connect_bd_net -net dfx_decouplers_rp_resetn_pr_2 [get_bd_pins dfx_decouplers/rp_resetn_pr_2] [get_bd_pins pr_2/clk_300MHz_aresetn]
  connect_bd_net -net pipeline_control_gpio2_io_o [get_bd_pins dfx_decouplers/dfx_decouple] [get_bd_pins pipeline_control/gpio2_io_o]
  connect_bd_net -net pipeline_control_gpio_io_o [get_bd_pins pipeline_control/gpio_io_o] [get_bd_pins ps_user_soft_reset/aux_reset_in]

  for {set i 0} {$i < 3} {incr i} {
    connect_bd_net [get_bd_pins clk_300MHz] [get_bd_pins clk_buf_rp${i}/BUFG_I]
    connect_bd_net [get_bd_pins clk_buf_rp${i}/BUFG_O] [get_bd_pins dfx_decouplers/clk_300MHz_pr_${i}] [get_bd_pins pr_${i}/clk_300MHz]
  }

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set iic [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic ]

  set mipi_phy_if_raspi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_raspi ]


  # Create ports
  set ap1302_rst_b [ create_bd_port -dir O -from 0 -to 0 ap1302_rst_b ]
  set ap1302_standby [ create_bd_port -dir O -from 0 -to 0 ap1302_standby ]
  set cam_gpiorpi [ create_bd_port -dir O -from 0 -to 0 cam_gpiorpi ]
  set fan_en_b [ create_bd_port -dir O -from 0 -to 0 fan_en_b ]

  # Create instance: axi_intc, and set properties
  set axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc ]
  set_property -dict [ list \
   CONFIG.C_IRQ_CONNECTION {1} \
 ] $axi_intc

  # Create instance: main_axi_interconnect, and set properties
  set main_axi_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 main_axi_interconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {8} \
 ] $main_axi_interconnect

  # Create instance: composable
  create_hier_cell_composable [current_bd_instance .] composable

  # Create instance: mipi
  create_hier_cell_mipi [current_bd_instance .] mipi

  # Create instance: proc_sys_reset_plclk0, and set properties
  set proc_sys_reset_plclk0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_plclk0 ]

  # Create instance: proc_sys_reset_plclk1, and set properties
  set proc_sys_reset_plclk1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_plclk1 ]

  # Create instance: ps_e, and set properties
  set ps_e [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 ps_e ]
  set_property -dict [ list \
   CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_DDR_RAM_HIGHADDR {0xFFFFFFFF} \
   CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
   CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
   CONFIG.PSU_DYNAMIC_DDR_CONFIG_EN {0} \
   CONFIG.PSU_MIO_0_DIRECTION {out} \
   CONFIG.PSU_MIO_0_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_0_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_0_POLARITY {Default} \
   CONFIG.PSU_MIO_0_SLEW {slow} \
   CONFIG.PSU_MIO_10_DIRECTION {inout} \
   CONFIG.PSU_MIO_10_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_10_POLARITY {Default} \
   CONFIG.PSU_MIO_10_SLEW {slow} \
   CONFIG.PSU_MIO_11_DIRECTION {inout} \
   CONFIG.PSU_MIO_11_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_11_POLARITY {Default} \
   CONFIG.PSU_MIO_11_SLEW {slow} \
   CONFIG.PSU_MIO_12_DIRECTION {inout} \
   CONFIG.PSU_MIO_12_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_12_POLARITY {Default} \
   CONFIG.PSU_MIO_12_SLEW {slow} \
   CONFIG.PSU_MIO_13_DIRECTION {inout} \
   CONFIG.PSU_MIO_13_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_13_POLARITY {Default} \
   CONFIG.PSU_MIO_13_SLEW {slow} \
   CONFIG.PSU_MIO_14_DIRECTION {inout} \
   CONFIG.PSU_MIO_14_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_14_POLARITY {Default} \
   CONFIG.PSU_MIO_14_SLEW {slow} \
   CONFIG.PSU_MIO_15_DIRECTION {inout} \
   CONFIG.PSU_MIO_15_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_15_POLARITY {Default} \
   CONFIG.PSU_MIO_15_SLEW {slow} \
   CONFIG.PSU_MIO_16_DIRECTION {inout} \
   CONFIG.PSU_MIO_16_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_16_POLARITY {Default} \
   CONFIG.PSU_MIO_16_SLEW {slow} \
   CONFIG.PSU_MIO_17_DIRECTION {inout} \
   CONFIG.PSU_MIO_17_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_17_POLARITY {Default} \
   CONFIG.PSU_MIO_17_SLEW {slow} \
   CONFIG.PSU_MIO_18_DIRECTION {inout} \
   CONFIG.PSU_MIO_18_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_18_POLARITY {Default} \
   CONFIG.PSU_MIO_18_SLEW {slow} \
   CONFIG.PSU_MIO_19_DIRECTION {inout} \
   CONFIG.PSU_MIO_19_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_19_POLARITY {Default} \
   CONFIG.PSU_MIO_19_SLEW {slow} \
   CONFIG.PSU_MIO_1_DIRECTION {inout} \
   CONFIG.PSU_MIO_1_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_1_POLARITY {Default} \
   CONFIG.PSU_MIO_1_SLEW {slow} \
   CONFIG.PSU_MIO_20_DIRECTION {inout} \
   CONFIG.PSU_MIO_20_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_20_POLARITY {Default} \
   CONFIG.PSU_MIO_20_SLEW {slow} \
   CONFIG.PSU_MIO_21_DIRECTION {inout} \
   CONFIG.PSU_MIO_21_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_21_POLARITY {Default} \
   CONFIG.PSU_MIO_21_SLEW {slow} \
   CONFIG.PSU_MIO_22_DIRECTION {inout} \
   CONFIG.PSU_MIO_22_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_22_POLARITY {Default} \
   CONFIG.PSU_MIO_22_SLEW {slow} \
   CONFIG.PSU_MIO_23_DIRECTION {inout} \
   CONFIG.PSU_MIO_23_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_23_POLARITY {Default} \
   CONFIG.PSU_MIO_23_SLEW {slow} \
   CONFIG.PSU_MIO_24_DIRECTION {inout} \
   CONFIG.PSU_MIO_24_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_24_POLARITY {Default} \
   CONFIG.PSU_MIO_24_SLEW {slow} \
   CONFIG.PSU_MIO_25_DIRECTION {inout} \
   CONFIG.PSU_MIO_25_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_25_POLARITY {Default} \
   CONFIG.PSU_MIO_25_SLEW {slow} \
   CONFIG.PSU_MIO_26_DIRECTION {in} \
   CONFIG.PSU_MIO_26_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_26_POLARITY {Default} \
   CONFIG.PSU_MIO_26_SLEW {fast} \
   CONFIG.PSU_MIO_27_DIRECTION {inout} \
   CONFIG.PSU_MIO_27_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_27_POLARITY {Default} \
   CONFIG.PSU_MIO_27_SLEW {slow} \
   CONFIG.PSU_MIO_28_DIRECTION {inout} \
   CONFIG.PSU_MIO_28_POLARITY {Default} \
   CONFIG.PSU_MIO_29_DIRECTION {inout} \
   CONFIG.PSU_MIO_29_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_29_POLARITY {Default} \
   CONFIG.PSU_MIO_29_SLEW {slow} \
   CONFIG.PSU_MIO_2_DIRECTION {inout} \
   CONFIG.PSU_MIO_2_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_2_POLARITY {Default} \
   CONFIG.PSU_MIO_2_SLEW {slow} \
   CONFIG.PSU_MIO_30_DIRECTION {inout} \
   CONFIG.PSU_MIO_30_POLARITY {Default} \
   CONFIG.PSU_MIO_31_DIRECTION {in} \
   CONFIG.PSU_MIO_31_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_31_POLARITY {Default} \
   CONFIG.PSU_MIO_31_SLEW {fast} \
   CONFIG.PSU_MIO_32_DIRECTION {out} \
   CONFIG.PSU_MIO_32_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_32_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_32_POLARITY {Default} \
   CONFIG.PSU_MIO_32_SLEW {slow} \
   CONFIG.PSU_MIO_33_DIRECTION {out} \
   CONFIG.PSU_MIO_33_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_33_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_33_POLARITY {Default} \
   CONFIG.PSU_MIO_33_SLEW {slow} \
   CONFIG.PSU_MIO_34_DIRECTION {out} \
   CONFIG.PSU_MIO_34_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_34_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_34_POLARITY {Default} \
   CONFIG.PSU_MIO_34_SLEW {slow} \
   CONFIG.PSU_MIO_35_DIRECTION {out} \
   CONFIG.PSU_MIO_35_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_35_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_35_POLARITY {Default} \
   CONFIG.PSU_MIO_35_SLEW {slow} \
   CONFIG.PSU_MIO_36_DIRECTION {inout} \
   CONFIG.PSU_MIO_36_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_36_POLARITY {Default} \
   CONFIG.PSU_MIO_36_SLEW {slow} \
   CONFIG.PSU_MIO_37_DIRECTION {inout} \
   CONFIG.PSU_MIO_37_POLARITY {Default} \
   CONFIG.PSU_MIO_38_DIRECTION {inout} \
   CONFIG.PSU_MIO_38_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_38_POLARITY {Default} \
   CONFIG.PSU_MIO_38_SLEW {slow} \
   CONFIG.PSU_MIO_39_DIRECTION {inout} \
   CONFIG.PSU_MIO_39_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_39_POLARITY {Default} \
   CONFIG.PSU_MIO_39_SLEW {slow} \
   CONFIG.PSU_MIO_3_DIRECTION {inout} \
   CONFIG.PSU_MIO_3_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_3_POLARITY {Default} \
   CONFIG.PSU_MIO_3_SLEW {slow} \
   CONFIG.PSU_MIO_40_DIRECTION {inout} \
   CONFIG.PSU_MIO_40_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_40_POLARITY {Default} \
   CONFIG.PSU_MIO_40_SLEW {slow} \
   CONFIG.PSU_MIO_41_DIRECTION {inout} \
   CONFIG.PSU_MIO_41_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_41_POLARITY {Default} \
   CONFIG.PSU_MIO_41_SLEW {slow} \
   CONFIG.PSU_MIO_42_DIRECTION {inout} \
   CONFIG.PSU_MIO_42_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_42_POLARITY {Default} \
   CONFIG.PSU_MIO_42_SLEW {slow} \
   CONFIG.PSU_MIO_43_DIRECTION {inout} \
   CONFIG.PSU_MIO_43_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_43_POLARITY {Default} \
   CONFIG.PSU_MIO_43_SLEW {slow} \
   CONFIG.PSU_MIO_44_DIRECTION {inout} \
   CONFIG.PSU_MIO_44_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_44_POLARITY {Default} \
   CONFIG.PSU_MIO_44_SLEW {slow} \
   CONFIG.PSU_MIO_45_DIRECTION {inout} \
   CONFIG.PSU_MIO_45_POLARITY {Default} \
   CONFIG.PSU_MIO_46_DIRECTION {inout} \
   CONFIG.PSU_MIO_46_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_46_POLARITY {Default} \
   CONFIG.PSU_MIO_46_SLEW {slow} \
   CONFIG.PSU_MIO_47_DIRECTION {inout} \
   CONFIG.PSU_MIO_47_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_47_POLARITY {Default} \
   CONFIG.PSU_MIO_47_SLEW {slow} \
   CONFIG.PSU_MIO_48_DIRECTION {inout} \
   CONFIG.PSU_MIO_48_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_48_POLARITY {Default} \
   CONFIG.PSU_MIO_48_SLEW {slow} \
   CONFIG.PSU_MIO_49_DIRECTION {inout} \
   CONFIG.PSU_MIO_49_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_49_POLARITY {Default} \
   CONFIG.PSU_MIO_49_SLEW {slow} \
   CONFIG.PSU_MIO_4_DIRECTION {inout} \
   CONFIG.PSU_MIO_4_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_4_POLARITY {Default} \
   CONFIG.PSU_MIO_4_SLEW {slow} \
   CONFIG.PSU_MIO_50_DIRECTION {inout} \
   CONFIG.PSU_MIO_50_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_50_POLARITY {Default} \
   CONFIG.PSU_MIO_50_SLEW {slow} \
   CONFIG.PSU_MIO_51_DIRECTION {inout} \
   CONFIG.PSU_MIO_51_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_51_POLARITY {Default} \
   CONFIG.PSU_MIO_51_SLEW {slow} \
   CONFIG.PSU_MIO_54_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_54_SLEW {slow} \
   CONFIG.PSU_MIO_56_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_56_SLEW {slow} \
   CONFIG.PSU_MIO_57_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_57_SLEW {slow} \
   CONFIG.PSU_MIO_58_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_58_SLEW {slow} \
   CONFIG.PSU_MIO_59_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_59_SLEW {slow} \
   CONFIG.PSU_MIO_5_DIRECTION {out} \
   CONFIG.PSU_MIO_5_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_5_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_5_POLARITY {Default} \
   CONFIG.PSU_MIO_5_SLEW {slow} \
   CONFIG.PSU_MIO_60_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_60_SLEW {slow} \
   CONFIG.PSU_MIO_61_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_61_SLEW {slow} \
   CONFIG.PSU_MIO_62_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_62_SLEW {slow} \
   CONFIG.PSU_MIO_63_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_63_SLEW {slow} \
   CONFIG.PSU_MIO_64_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_64_SLEW {slow} \
   CONFIG.PSU_MIO_65_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_65_SLEW {slow} \
   CONFIG.PSU_MIO_66_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_66_SLEW {slow} \
   CONFIG.PSU_MIO_67_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_67_SLEW {slow} \
   CONFIG.PSU_MIO_68_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_68_SLEW {slow} \
   CONFIG.PSU_MIO_69_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_69_SLEW {slow} \
   CONFIG.PSU_MIO_6_DIRECTION {inout} \
   CONFIG.PSU_MIO_6_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_6_POLARITY {Default} \
   CONFIG.PSU_MIO_6_SLEW {slow} \
   CONFIG.PSU_MIO_76_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_76_SLEW {slow} \
   CONFIG.PSU_MIO_77_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_77_SLEW {slow} \
   CONFIG.PSU_MIO_7_DIRECTION {inout} \
   CONFIG.PSU_MIO_7_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_7_POLARITY {Default} \
   CONFIG.PSU_MIO_7_SLEW {slow} \
   CONFIG.PSU_MIO_8_DIRECTION {inout} \
   CONFIG.PSU_MIO_8_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_8_POLARITY {Default} \
   CONFIG.PSU_MIO_8_SLEW {slow} \
   CONFIG.PSU_MIO_9_DIRECTION {inout} \
   CONFIG.PSU_MIO_9_DRIVE_STRENGTH {4} \
   CONFIG.PSU_MIO_9_POLARITY {Default} \
   CONFIG.PSU_MIO_9_SLEW {slow} \
   CONFIG.PSU_MIO_TREE_PERIPHERALS {Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#SPI 1#GPIO0 MIO#GPIO0 MIO#SPI 1#SPI 1#SPI 1#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#I2C 1#I2C 1#PMU GPI 0#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#PMU GPI 5#PMU GPO 0#PMU GPO 1#PMU GPO 2#PMU GPO 3#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO##########################} \
   CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#miso_mo1#mo2#mo3#mosi_mi0#n_ss_out#sclk_out#gpio0[7]#gpio0[8]#n_ss_out[0]#miso#mosi#gpio0[12]#gpio0[13]#gpio0[14]#gpio0[15]#gpio0[16]#gpio0[17]#gpio0[18]#gpio0[19]#gpio0[20]#gpio0[21]#gpio0[22]#gpio0[23]#scl_out#sda_out#gpi[0]#gpio1[27]#gpio1[28]#gpio1[29]#gpio1[30]#gpi[5]#gpo[0]#gpo[1]#gpo[2]#gpo[3]#gpio1[36]#gpio1[37]#gpio1[38]#gpio1[39]#gpio1[40]#gpio1[41]#gpio1[42]#gpio1[43]#gpio1[44]#gpio1[45]#gpio1[46]#gpio1[47]#gpio1[48]#gpio1[49]#gpio1[50]#gpio1[51]##########################} \
   CONFIG.PSU__ACT_DDR_FREQ_MHZ {1066.656006} \
   CONFIG.PSU__CAN1__GRP_CLK__ENABLE {0} \
   CONFIG.PSU__CAN1__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1333.333008} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0 {1} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ {1333.333} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__SRCSEL {APLL} \
   CONFIG.PSU__CRF_APB__ACPU__FRAC_ENABLED {1} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FBDIV {80} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FRACDATA {0.000778} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FRACFREQ {1333.333} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__APLL_FRAC_CFG__ENABLED {1} \
   CONFIG.PSU__CRF_APB__APLL_TO_LPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {533.328003} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1200} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {444.444336} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__FREQMHZ {600} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__SRCSEL {APLL} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__FBDIV {64} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__DPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__DPLL_TO_LPD_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR0 {63} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR1 {10} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__SRCSEL {VPLL} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {533.328003} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__FREQMHZ {600} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__ACT_FREQMHZ {499.994995} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__DIVISOR0 {1} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__FREQMHZ {600} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {533.328003} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__FREQMHZ {533.33} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__FBDIV {90} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__VPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__VPLL_TO_LPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {499.994995} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {49.999500} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR0 {20} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {499.994995} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__FREQMHZ {533.333} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {999.989990} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR0 {10} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__FBDIV {60} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRL_APB__IOPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRL_APB__IOPLL_TO_FPD_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {249.997498} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__DIVISOR0 {10} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {499.994995} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {199.998001} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR0 {10} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ {299.997009} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {300} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ {299.997009} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__FREQMHZ {300} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__ACT_FREQMHZ {124.998749} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR0 {8} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__FREQMHZ {125} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__FBDIV {90} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRL_APB__RPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRL_APB__RPLL_TO_FPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR0 {7} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR0 {7} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR0 {7} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__ACT_FREQMHZ {199.998001} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__DIVISOR0 {10} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR1 {15} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__FREQMHZ {20} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CSUPMU__PERIPHERAL__VALID {1} \
   CONFIG.PSU__DDRC__ADDR_MIRROR {0} \
   CONFIG.PSU__DDRC__BANK_ADDR_COUNT {2} \
   CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
   CONFIG.PSU__DDRC__BRC_MAPPING {ROW_BANK_COL} \
   CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
   CONFIG.PSU__DDRC__CL {16} \
   CONFIG.PSU__DDRC__CLOCK_STOP_EN {0} \
   CONFIG.PSU__DDRC__COL_ADDR_COUNT {10} \
   CONFIG.PSU__DDRC__COMPONENTS {Components} \
   CONFIG.PSU__DDRC__CWL {14} \
   CONFIG.PSU__DDRC__DDR3L_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__DDR3_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING {0} \
   CONFIG.PSU__DDRC__DDR4_CAL_MODE_ENABLE {0} \
   CONFIG.PSU__DDRC__DDR4_CRC_CONTROL {0} \
   CONFIG.PSU__DDRC__DDR4_T_REF_MODE {0} \
   CONFIG.PSU__DDRC__DDR4_T_REF_RANGE {Normal (0-85)} \
   CONFIG.PSU__DDRC__DEEP_PWR_DOWN_EN {0} \
   CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
   CONFIG.PSU__DDRC__DIMM_ADDR_MIRROR {0} \
   CONFIG.PSU__DDRC__DM_DBI {DM_NO_DBI} \
   CONFIG.PSU__DDRC__DQMAP_0_3 {0} \
   CONFIG.PSU__DDRC__DQMAP_12_15 {0} \
   CONFIG.PSU__DDRC__DQMAP_16_19 {0} \
   CONFIG.PSU__DDRC__DQMAP_20_23 {0} \
   CONFIG.PSU__DDRC__DQMAP_24_27 {0} \
   CONFIG.PSU__DDRC__DQMAP_28_31 {0} \
   CONFIG.PSU__DDRC__DQMAP_32_35 {0} \
   CONFIG.PSU__DDRC__DQMAP_36_39 {0} \
   CONFIG.PSU__DDRC__DQMAP_40_43 {0} \
   CONFIG.PSU__DDRC__DQMAP_44_47 {0} \
   CONFIG.PSU__DDRC__DQMAP_48_51 {0} \
   CONFIG.PSU__DDRC__DQMAP_4_7 {0} \
   CONFIG.PSU__DDRC__DQMAP_52_55 {0} \
   CONFIG.PSU__DDRC__DQMAP_56_59 {0} \
   CONFIG.PSU__DDRC__DQMAP_60_63 {0} \
   CONFIG.PSU__DDRC__DQMAP_64_67 {0} \
   CONFIG.PSU__DDRC__DQMAP_68_71 {0} \
   CONFIG.PSU__DDRC__DQMAP_8_11 {0} \
   CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
   CONFIG.PSU__DDRC__ECC {Disabled} \
   CONFIG.PSU__DDRC__ENABLE_LP4_HAS_ECC_COMP {0} \
   CONFIG.PSU__DDRC__ENABLE_LP4_SLOWBOOT {0} \
   CONFIG.PSU__DDRC__FGRM {1X} \
   CONFIG.PSU__DDRC__LPDDR3_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__LPDDR4_T_REF_RANGE {NA} \
   CONFIG.PSU__DDRC__LP_ASR {manual normal} \
   CONFIG.PSU__DDRC__MEMORY_TYPE {DDR 4} \
   CONFIG.PSU__DDRC__PARITY_ENABLE {0} \
   CONFIG.PSU__DDRC__PER_BANK_REFRESH {0} \
   CONFIG.PSU__DDRC__PHY_DBI_MODE {0} \
   CONFIG.PSU__DDRC__RANK_ADDR_COUNT {0} \
   CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
   CONFIG.PSU__DDRC__SB_TARGET {16-16-16} \
   CONFIG.PSU__DDRC__SELF_REF_ABORT {0} \
   CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400R} \
   CONFIG.PSU__DDRC__STATIC_RD_MODE {0} \
   CONFIG.PSU__DDRC__TRAIN_DATA_EYE {1} \
   CONFIG.PSU__DDRC__TRAIN_READ_GATE {1} \
   CONFIG.PSU__DDRC__TRAIN_WRITE_LEVEL {1} \
   CONFIG.PSU__DDRC__T_FAW {30.0} \
   CONFIG.PSU__DDRC__T_RAS_MIN {33} \
   CONFIG.PSU__DDRC__T_RC {47.06} \
   CONFIG.PSU__DDRC__T_RCD {16} \
   CONFIG.PSU__DDRC__T_RP {16} \
   CONFIG.PSU__DDRC__VENDOR_PART {OTHERS} \
   CONFIG.PSU__DDRC__VREF {1} \
   CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {1} \
   CONFIG.PSU__DDR__INTERFACE__FREQMHZ {600.000} \
   CONFIG.PSU__DP__REF_CLK_FREQ {<Select>} \
   CONFIG.PSU__DP__REF_CLK_SEL {<Select>} \
   CONFIG.PSU__FPD_SLCR__WDT1__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__FPD_SLCR__WDT1__FREQMHZ {99.999001} \
   CONFIG.PSU__FPD_SLCR__WDT_CLK_SEL__SELECT {APB} \
   CONFIG.PSU__FPGA_PL0_ENABLE {1} \
   CONFIG.PSU__FPGA_PL1_ENABLE {1} \
   CONFIG.PSU__FPGA_PL2_ENABLE {0} \
   CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
   CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO1_MIO__IO {MIO 26 .. 51} \
   CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO_EMIO_WIDTH {92} \
   CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO_EMIO__PERIPHERAL__IO {92} \
   CONFIG.PSU__HIGH_ADDRESS__ENABLE {1} \
   CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 24 .. 25} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC0_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC1_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC2_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC3_SEL {APB} \
   CONFIG.PSU__IOU_SLCR__TTC0__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC0__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC1__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC1__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC2__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC2__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC3__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__TTC3__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__WDT0__ACT_FREQMHZ {99.999001} \
   CONFIG.PSU__IOU_SLCR__WDT0__FREQMHZ {99.999001} \
   CONFIG.PSU__IOU_SLCR__WDT_CLK_SEL__SELECT {APB} \
   CONFIG.PSU__LPD_SLCR__CSUPMU__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__LPD_SLCR__CSUPMU__FREQMHZ {100.000000} \
   CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
   CONFIG.PSU__MAXIGP1__DATA_WIDTH {128} \
   CONFIG.PSU__MAXIGP2__DATA_WIDTH {32} \
   CONFIG.PSU__OVERRIDE__BASIC_CLOCK {0} \
   CONFIG.PSU__PL_CLK0_BUF {TRUE} \
   CONFIG.PSU__PL_CLK1_BUF {TRUE} \
   CONFIG.PSU__PL_CLK2_BUF {TRUE} \
   CONFIG.PSU__PMU_COHERENCY {0} \
   CONFIG.PSU__PMU__AIBACK__ENABLE {0} \
   CONFIG.PSU__PMU__EMIO_GPI__ENABLE {0} \
   CONFIG.PSU__PMU__EMIO_GPO__ENABLE {0} \
   CONFIG.PSU__PMU__GPI0__ENABLE {1} \
   CONFIG.PSU__PMU__GPI0__IO {MIO 26} \
   CONFIG.PSU__PMU__GPI1__ENABLE {0} \
   CONFIG.PSU__PMU__GPI2__ENABLE {0} \
   CONFIG.PSU__PMU__GPI3__ENABLE {0} \
   CONFIG.PSU__PMU__GPI4__ENABLE {0} \
   CONFIG.PSU__PMU__GPI5__ENABLE {1} \
   CONFIG.PSU__PMU__GPI5__IO {MIO 31} \
   CONFIG.PSU__PMU__GPO0__ENABLE {1} \
   CONFIG.PSU__PMU__GPO0__IO {MIO 32} \
   CONFIG.PSU__PMU__GPO1__ENABLE {1} \
   CONFIG.PSU__PMU__GPO1__IO {MIO 33} \
   CONFIG.PSU__PMU__GPO2__ENABLE {1} \
   CONFIG.PSU__PMU__GPO2__IO {MIO 34} \
   CONFIG.PSU__PMU__GPO2__POLARITY {high} \
   CONFIG.PSU__PMU__GPO3__ENABLE {1} \
   CONFIG.PSU__PMU__GPO3__IO {MIO 35} \
   CONFIG.PSU__PMU__GPO3__POLARITY {low} \
   CONFIG.PSU__PMU__GPO4__ENABLE {0} \
   CONFIG.PSU__PMU__GPO5__ENABLE {0} \
   CONFIG.PSU__PMU__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__PMU__PLERROR__ENABLE {0} \
   CONFIG.PSU__PRESET_APPLIED {1} \
   CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;0|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;1|S_AXI_HP0_FPD:NA;1|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;0|SD0:NonSecure;0|SATA1:NonSecure;0|SATA0:NonSecure;0|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;0|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;0|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1} \
   CONFIG.PSU__PROTECTION__SLAVES { \
     LPD;USB3_1_XHCI;FE300000;FE3FFFFF;0|LPD;USB3_1;FF9E0000;FF9EFFFF;0|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;0|LPD;USB3_0;FF9D0000;FF9DFFFF;0|LPD;UART1;FF010000;FF01FFFF;0|LPD;UART0;FF000000;FF00FFFF;0|LPD;TTC3;FF140000;FF14FFFF;1|LPD;TTC2;FF130000;FF13FFFF;1|LPD;TTC1;FF120000;FF12FFFF;1|LPD;TTC0;FF110000;FF11FFFF;1|FPD;SWDT1;FD4D0000;FD4DFFFF;1|LPD;SWDT0;FF150000;FF15FFFF;1|LPD;SPI1;FF050000;FF05FFFF;1|LPD;SPI0;FF040000;FF04FFFF;0|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;0|LPD;SD0;FF160000;FF16FFFF;0|FPD;SATA;FD0C0000;FD0CFFFF;0|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;1|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;0|FPD;GPU;FD4B0000;FD4BFFFF;1|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;0|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;0|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display Port;FD4A0000;FD4AFFFF;0|FPD;DPDMA;FD4C0000;FD4CFFFF;0|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;87FFFFFFF;1|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;1|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;0|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1 \
   } \
   CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333} \
   CONFIG.PSU__QSPI_COHERENCY {0} \
   CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {0} \
   CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
   CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 5} \
   CONFIG.PSU__QSPI__PERIPHERAL__MODE {Single} \
   CONFIG.PSU__SATA__REF_CLK_FREQ {<Select>} \
   CONFIG.PSU__SATA__REF_CLK_SEL {<Select>} \
   CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} \
   CONFIG.PSU__SPI1__GRP_SS0__ENABLE {1} \
   CONFIG.PSU__SPI1__GRP_SS0__IO {MIO 9} \
   CONFIG.PSU__SPI1__GRP_SS1__ENABLE {0} \
   CONFIG.PSU__SPI1__GRP_SS2__ENABLE {0} \
   CONFIG.PSU__SPI1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SPI1__PERIPHERAL__IO {MIO 6 .. 11} \
   CONFIG.PSU__SWDT0__CLOCK__ENABLE {0} \
   CONFIG.PSU__SWDT0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SWDT0__RESET__ENABLE {0} \
   CONFIG.PSU__SWDT1__CLOCK__ENABLE {0} \
   CONFIG.PSU__SWDT1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SWDT1__RESET__ENABLE {0} \
   CONFIG.PSU__TTC0__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC0__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__TTC1__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC1__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__TTC2__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC2__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC2__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__TTC3__CLOCK__ENABLE {0} \
   CONFIG.PSU__TTC3__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__TTC3__WAVEOUT__ENABLE {0} \
   CONFIG.PSU__USB0__REF_CLK_FREQ {<Select>} \
   CONFIG.PSU__USB0__REF_CLK_SEL {<Select>} \
   CONFIG.PSU__USE__IRQ0 {1} \
   CONFIG.PSU__USE__IRQ1 {1} \
   CONFIG.PSU__USE__M_AXI_GP0 {0} \
   CONFIG.PSU__USE__M_AXI_GP1 {0} \
   CONFIG.PSU__USE__M_AXI_GP2 {1} \
   CONFIG.PSU__USE__S_AXI_GP2 {1} \
   CONFIG.PSU__USE__S_AXI_GP3 {1} \
   CONFIG.PSU__USE__S_AXI_GP4 {1} \
   CONFIG.PSU__USE__S_AXI_GP5 {0} \
   CONFIG.SUBPRESET1 {Custom} \
 ] $ps_e

  # Create instance: shutdown_HP0_FPD, and set properties
  set shutdown_HP0_FPD [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_axi_shutdown_manager:1.0 shutdown_HP0_FPD ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_DATA_WIDTH {128} \
 ] $shutdown_HP0_FPD

  # Create instance: shutdown_HP1_FPD, and set properties
  set shutdown_HP1_FPD [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_axi_shutdown_manager:1.0 shutdown_HP1_FPD ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_DATA_WIDTH {128} \
 ] $shutdown_HP1_FPD

  # Create instance: shutdown_HP2_FPD, and set properties
  set shutdown_HP2_FPD [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_axi_shutdown_manager:1.0 shutdown_HP2_FPD ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_DATA_WIDTH {128} \
 ] $shutdown_HP2_FPD

  # Create instance: video
  create_hier_cell_video [current_bd_instance .] video

  # Create instance: xlconcat, and set properties
  set xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {4} \
 ] $xlconcat

  # Create instance: xlconcat_int, and set properties
  set xlconcat_int [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_int ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {1} \
 ] $xlconcat_int

  # Create instance: axi_iic, and set properties
  set axi_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 axi_iic ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0


  # Create instance: xlconstant_0, and set properties
  set clk_wiz_200 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_200 ]
  set_property -dict [list \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
   CONFIG.USE_LOCKED {false} \
   CONFIG.USE_RESET {false} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {6.000} \
   CONFIG.CLKOUT1_JITTER {102.086}\
  ] $clk_wiz_200

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_2 [get_bd_intf_pins composable/M01_AXIS] [get_bd_intf_pins mipi/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_VIDEO_IN_1 [get_bd_intf_pins composable/S00_AXIS] [get_bd_intf_pins video/M_AXIS]
  connect_bd_intf_net -intf_net S_AXI_INTERCONNECT_1 [get_bd_intf_pins main_axi_interconnect/M05_AXI] [get_bd_intf_pins mipi/S_AXI_INTERCONNECT]
  connect_bd_intf_net -intf_net axi_interconnect_M00_AXI [get_bd_intf_pins axi_intc/s_axi] [get_bd_intf_pins main_axi_interconnect/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M01_AXI [get_bd_intf_pins main_axi_interconnect/M01_AXI] [get_bd_intf_pins video/S_AXI_INTERCONNECT]
  connect_bd_intf_net -intf_net axi_interconnect_M02_AXI [get_bd_intf_pins main_axi_interconnect/M02_AXI] [get_bd_intf_pins shutdown_HP2_FPD/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_M08_AXI [get_bd_intf_pins main_axi_interconnect/M06_AXI] [get_bd_intf_pins shutdown_HP1_FPD/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_M03_AXI [get_bd_intf_pins main_axi_interconnect/M03_AXI] [get_bd_intf_pins shutdown_HP0_FPD/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_M04_AXI [get_bd_intf_pins main_axi_interconnect/M04_AXI] [get_bd_intf_pins composable/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M07_AXI [get_bd_intf_pins main_axi_interconnect/M07_AXI] [get_bd_intf_pins axi_iic/S_AXI] 
  connect_bd_intf_net -intf_net video_m_axi_s2mm [get_bd_intf_pins video/M_AXI_S2MM] [get_bd_intf_pins shutdown_HP2_FPD/S_AXI]
  connect_bd_intf_net -intf_net mipi_m_axi_s2mm [get_bd_intf_pins mipi/M_AXI_S2MM] [get_bd_intf_pins shutdown_HP1_FPD/S_AXI]
  connect_bd_intf_net -intf_net video_m_axi_mm2s [get_bd_intf_pins video/M_AXI_MM2S] [get_bd_intf_pins shutdown_HP0_FPD/S_AXI]
  connect_bd_intf_net -intf_net composable_M_AXIS_VIDEO_OUT [get_bd_intf_pins composable/M00_AXIS] [get_bd_intf_pins video/S_AXIS]
  connect_bd_intf_net -intf_net intf_net_zynq_us_M_AXI_HPM0_LPD [get_bd_intf_pins main_axi_interconnect/S00_AXI] [get_bd_intf_pins ps_e/M_AXI_HPM0_LPD]
  connect_bd_intf_net -intf_net mipi_phy_if_0_0_1 [get_bd_intf_ports mipi_phy_if_raspi] [get_bd_intf_pins mipi/mipi_phy_if]
  connect_bd_intf_net -intf_net raspi_M_AXIS [get_bd_intf_pins composable/S01_AXIS] [get_bd_intf_pins mipi/M_AXIS]
  connect_bd_intf_net -intf_net shutdown_HP0_M_AXI [get_bd_intf_pins ps_e/S_AXI_HP0_FPD] [get_bd_intf_pins shutdown_HP0_FPD/M_AXI]
  connect_bd_intf_net -intf_net shutdown_HP1_M_AXI [get_bd_intf_pins ps_e/S_AXI_HP1_FPD] [get_bd_intf_pins shutdown_HP1_FPD/M_AXI]
  connect_bd_intf_net -intf_net shutdown_HP2_M_AXI [get_bd_intf_pins ps_e/S_AXI_HP2_FPD] [get_bd_intf_pins shutdown_HP2_FPD/M_AXI]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports iic] [get_bd_intf_pins axi_iic/IIC]

  # Create port connections
  connect_bd_net -net mipi_cam_gpiorpi [get_bd_ports cam_gpiorpi] [get_bd_pins mipi/cam_gpiorpi]
  connect_bd_net -net axi_intc_0_irq [get_bd_pins axi_intc/irq] [get_bd_pins xlconcat_int/In0]
  connect_bd_net -net mipi_csirxss_csi_irq [get_bd_pins mipi/csirxss_csi_irq] [get_bd_pins xlconcat/In2]
  connect_bd_net -net mipi_s2mm_introut [get_bd_pins mipi/s2mm_introut] [get_bd_pins xlconcat/In3]
  connect_bd_net -net net_bdry_in_reset [get_bd_pins proc_sys_reset_plclk0/ext_reset_in] [get_bd_pins proc_sys_reset_plclk1/ext_reset_in] [get_bd_pins ps_e/pl_resetn0]
  connect_bd_net -net net_rst_processor_1_100M_interconnect_aresetn [get_bd_pins main_axi_interconnect/ARESETN] [get_bd_pins proc_sys_reset_plclk0/interconnect_aresetn]
  connect_bd_net -net ps_e_0_pl_clk1 [get_bd_pins ps_e/pl_clk1] [get_bd_pins main_axi_interconnect/M02_ACLK] [get_bd_pins main_axi_interconnect/M03_ACLK] [get_bd_pins main_axi_interconnect/M04_ACLK] [get_bd_pins main_axi_interconnect/M05_ACLK] [get_bd_pins main_axi_interconnect/M06_ACLK] [get_bd_pins main_axi_interconnect/M08_ACLK] [get_bd_pins main_axi_interconnect/M09_ACLK] [get_bd_pins composable/clk_300MHz] [get_bd_pins mipi/clk_300MHz] [get_bd_pins proc_sys_reset_plclk1/slowest_sync_clk] [get_bd_pins ps_e/saxihp0_fpd_aclk] [get_bd_pins ps_e/saxihp1_fpd_aclk] [get_bd_pins ps_e/saxihp2_fpd_aclk] [get_bd_pins ps_e/saxihp3_fpd_aclk] [get_bd_pins shutdown_HP0_FPD/clk] [get_bd_pins shutdown_HP1_FPD/clk] [get_bd_pins shutdown_HP2_FPD/clk] [get_bd_pins video/clk_300MHz]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins main_axi_interconnect/M02_ARESETN] [get_bd_pins main_axi_interconnect/M03_ARESETN] [get_bd_pins main_axi_interconnect/M04_ARESETN] [get_bd_pins main_axi_interconnect/M05_ARESETN] [get_bd_pins main_axi_interconnect/M06_ARESETN] [get_bd_pins main_axi_interconnect/M08_ARESETN] [get_bd_pins main_axi_interconnect/M09_ARESETN] [get_bd_pins composable/clk_300MHz_aresetn] [get_bd_pins mipi/clk_300MHz_aresetn] [get_bd_pins proc_sys_reset_plclk1/peripheral_aresetn] [get_bd_pins shutdown_HP0_FPD/resetn] [get_bd_pins shutdown_HP1_FPD/resetn] [get_bd_pins shutdown_HP2_FPD/resetn] [get_bd_pins video/clk_300MHz_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins axi_intc/s_axi_aresetn] [get_bd_pins main_axi_interconnect/M00_ARESETN] [get_bd_pins main_axi_interconnect/M01_ARESETN] [get_bd_pins main_axi_interconnect/M07_ARESETN] [get_bd_pins axi_iic/s_axi_aresetn] [get_bd_pins main_axi_interconnect/S00_ARESETN] [get_bd_pins mipi/clk_100MHz_aresetn] [get_bd_pins proc_sys_reset_plclk0/peripheral_aresetn] [get_bd_pins video/clk_100MHz_aresetn]
  connect_bd_net -net ps_e_0_pl_clk0 [get_bd_pins ps_e/pl_clk0]  [get_bd_pins axi_intc/s_axi_aclk] [get_bd_pins main_axi_interconnect/ACLK] [get_bd_pins main_axi_interconnect/M00_ACLK] [get_bd_pins main_axi_interconnect/M01_ACLK] [get_bd_pins main_axi_interconnect/M07_ACLK] [get_bd_pins axi_iic/s_axi_aclk] [get_bd_pins main_axi_interconnect/S00_ACLK] [get_bd_pins mipi/clk_100MHz] [get_bd_pins proc_sys_reset_plclk0/slowest_sync_clk] [get_bd_pins ps_e/maxihpm0_lpd_aclk] [get_bd_pins video/clk_100MHz] [get_bd_pins clk_wiz_200/clk_in1]
  connect_bd_net -net clk_wiz_200_clk_out1 [get_bd_pins clk_wiz_200/clk_out1] [get_bd_pins mipi/dphy_clk_200M]
  connect_bd_net -net video_mm2s_introut [get_bd_pins video/mm2s_introut] [get_bd_pins xlconcat/In1]
  connect_bd_net -net video_s2mm_introut [get_bd_pins video/s2mm_introut] [get_bd_pins xlconcat/In0]
  connect_bd_net -net xlconcat0_dout [get_bd_pins axi_intc/intr] [get_bd_pins xlconcat/dout]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins ps_e/pl_ps_irq0] [get_bd_pins xlconcat_int/dout]
  connect_bd_net -net axi_iic_iic2intc_irpt [get_bd_pins axi_iic/iic2intc_irpt] [get_bd_pins ps_e/pl_ps_irq1]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_ports ap1302_standby] [get_bd_ports fan_en_b] [get_bd_ports ap1302_rst_b]

  # Create address segments
  assign_bd_address -offset 0x80043000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x80030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs axi_iic/S_AXI/Reg] -force
  assign_bd_address -offset 0x800A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/lut_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x800B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/axis_switch/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x800C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/filter2d_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x800D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/gray2rgb_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x800E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/rgb2gray_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x800F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/rgb2hsv_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/colorthresholding_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/pipeline_control/S_AXI/Reg] -force
  assign_bd_address -offset 0x80120000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/pr_0/dilate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80128000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/pr_0/erode_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80130000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/pr_1/dilate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80138000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/pr_1/erode_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80140000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/pr_2/dilate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80148000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs composable/pr_2/erode_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs mipi/axi_vdma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80210000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs mipi/mipi_csi2_rx_subsyst/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x80220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs mipi/demosaic/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x80230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs mipi/gamma_lut/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x80240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs mipi/gpio_ip_reset/S_AXI/Reg] -force
  assign_bd_address -offset 0x80250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs mipi/pixel_pack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs mipi/v_proc_sys/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0x80060000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs video/axi_vdma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80070000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs video/pixel_pack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80080000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs video/pixel_unpack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs shutdown_HP0_FPD/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x80310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs shutdown_HP1_FPD/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x80320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e/Data] [get_bd_addr_segs shutdown_HP2_FPD/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces mipi/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e/SAXIGP3/HP1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S] [get_bd_addr_segs ps_e/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e/SAXIGP4/HP2_DDR_LOW] -force
  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces mipi/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e/SAXIGP3/HP1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces mipi/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e/SAXIGP3/HP1_LPS_OCM]
  exclude_bd_addr_seg -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S] [get_bd_addr_segs ps_e/SAXIGP2/HP0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S] [get_bd_addr_segs ps_e/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e/SAXIGP4/HP2_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e/SAXIGP4/HP2_LPS_OCM]
  exclude_bd_addr_seg [get_bd_addr_segs ps_e/SAXIGP3/HP1_QSPI] -target_address_space [get_bd_addr_spaces mipi/axi_vdma/Data_S2MM]
  exclude_bd_addr_seg [get_bd_addr_segs ps_e/SAXIGP2/HP0_QSPI] -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S]
  exclude_bd_addr_seg [get_bd_addr_segs ps_e/SAXIGP4/HP2_QSPI] -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM]

  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx.com:xd:${overlay_name}:1.0} [get_files [current_bd_design].bd]
  set_property PFM.AXI_PORT {  M_AXI_HPM0_FPD {memport "M_AXI_GP"}  M_AXI_HPM0_LPD {memport "M_AXI_GP"}  S_AXI_HPC0_FPD {memport "S_AXI_HPC"}  S_AXI_HPC1_FPD {memport "S_AXI_HPC"}  S_AXI_HP0_FPD {memport "S_AXI_HP"}  S_AXI_HP1_FPD {memport "S_AXI_HP"}  S_AXI_HP2_FPD {memport "S_AXI_HP"}  S_AXI_HP3_FPD {memport "S_AXI_HP"}  
    S_AXI_LPD {memport "S_AXI_HP"}  } [get_bd_cells /ps_e]
  set_property PFM.CLOCK {  pl_clk0 {id "0" is_default "true"  proc_sys_reset "proc_sys_reset_plclk0" status "fixed"}  pl_clk1 {id "1" is_default "false"  proc_sys_reset "proc_sys_reset_plclk1" status "fixed"} } [get_bd_cells /ps_e]
  set_property PFM.IRQ {In1 {} In2 {} In3 {} In4 {} In5 {} In6 {} In7 {}} [get_bd_cells /xlconcat_int]

  # Update addr_prefixes variable if these adress change
  set_property APERTURES {{0x8012_0000 64K}} [get_bd_intf_pins /composable/pr_0/s_axi_control]
  set_property APERTURES {{0x8013_0000 64K}} [get_bd_intf_pins /composable/pr_1/s_axi_control]
  set_property APERTURES {{0x8014_0000 64K}} [get_bd_intf_pins /composable/pr_2/s_axi_control]

  save_bd_design
  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

source ./hw_contract.tcl

create_root_design ""

source ./bdc_dfx.tcl
