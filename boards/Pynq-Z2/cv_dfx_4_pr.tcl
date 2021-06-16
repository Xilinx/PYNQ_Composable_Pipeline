# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

###############################################################################
###############################################################################
 #
 #
 # @file cv_dfx_4_pr.tcl
 #
 # Vivado tcl script to generate full and partial bitstreams
 #
 # <pre>
 # MODIFICATION HISTORY:
 #
 # Ver   Who  Date     Changes
 # ----- --- -------- -----------------------------------------------
 # 1.00a pp   2/5/2021 Design having AXIS switch, four PR rgeions, rgb2gray,
 #                     gray2rgb, colorthresholding, in static region; filter2d,
 #                     dilate, erode, 4 KB FIFO, 
 #	                 
 # 1.00b pp	  2/9/2021 Removed colorthresholding, erode and dilate from the 
 #					   static part. 
 #					   Renamed pr_merge to pr_join and pr_split to pr_fork
 #					   Added FIFO (4K words) at the input of pr_join for 
 #					   the pipeline synchronization
 # 1.00c pp	  2/11/2021 Replaced fifo_generator with axis_data_fifo
 #
 # 1.00d mr   2/12/2021 Replace fifo_generator in RM and remove keep and strb from slices.
 #              Use different name for the FIFOs in the same PR region to get different keys
 #              from the composable class
 #              Add color thresholding as reconfigurable module into pr_join and pr_fork
 # 
 # 1.00e mr   2/19/2021 Include LUT IP in static portion and remove _0 from IP's name
 #                      Set dilate and erode as default IP in pr_0 and pr_1. Add two 
 #                      axi4-lite interfaces to pr_0 and pr_1 to workaround addressing
 #                      issues, to that end the add two more interfaces in the axi interconnect
 #                      an connect them to the corresponding dfx decoupler
 # 
 # 1.00f mr   2/25/2021 Move DFX related IP to a unique hierarchy, add GPIO IP for leds, 
 #                      switches and buttons
 #
 # 1.20  mr   03/03/2021 Rename composable_pipeline hierarchy to composable, include rgb2xyz_accel
 #                       into static IP. Move color thresholding IP instance from pr_join to
 #                       pr_fork. Include absdiff_accel and add_accel IP instances into pr_join
 #
 # 1.30  mr   03/12/2021 Remove colorThresholding from pr_1 and thresholding from pr_fork
 #
 # 1.40  mr   04/15/2021 Move color thresholding to the static region, and rgb2xyz to the pr_fork.
 #                       Additionally add bitwise-and on pr_join
 #
 # 1.50  mr   04/20/2021 Add logic for soft reset to flush pipeline. Set FIFO size to 16384 for 
 #                       both input path to the pr_join hierarchy
 #
 # 1.51  mr   05/27/2021 Double FIFO HDMI out storage size by using width converters
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
set scripts_vivado_version 2020.2
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
# source cv_dfx_4_pr.tcl
# Use the following parameters to create a PR design
set_param project.enablePRFlowIPI 1
set_param project.enablePRFlowIPIOOC 1

# Add user local board path and check if the board file exists
set repo_path "$::env(HOME)/.Xilinx/Vivado/${scripts_vivado_version}/xhub/board_store/xilinx_board_store/XilinxBoardStore/Vivado/${scripts_vivado_version}/boards/"
set_param board.repoPaths ${repo_path}
set board [get_board_parts "*:pynq-z2:*" -latest_file_version]
if { ${board} eq "" } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "${board} board file is not found. Please install the board file either manually or using the Xilinx Board Store"}
   return 1
}

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./${prj_name}/${prj_name}.xpr> in the current working folder.

set prj_name "cv_dfx_4_pr"
set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project ${prj_name} ${prj_name} -part xc7z020clg400-1
   set_property BOARD_PART ${board} [current_project]
}

set_property ip_repo_paths "./ip/ ../ip/boards/ip" [current_project]
update_ip_catalog

add_files -fileset constrs_1 -norecurse cv_dfx_4_pr.xdc


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
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:processing_system7:5.5\
xilinx.com:ip:dfx_decoupler:1.0\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:axis_register_slice:1.1\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlslice:1.0\
xilinx.com:hls:dilate_accel:1.0\
xilinx.com:hls:erode_accel:1.0\
xilinx.com:hls:duplicate_accel:1.0\
xilinx.com:hls:subtract_accel:1.0\
xilinx.com:ip:axi_vdma:6.3\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:axis_switch:1.1\
xilinx.com:hls:filter2d_accel:1.0\
xilinx.com:hls:gray2rgb_accel:1.0\
xilinx.com:hls:LUT_accel:1.0\
xilinx.com:hls:rgb2gray_accel:1.0\
xilinx.com:hls:rgb2hsv_accel:1.0\
xilinx.com:hls:colorthresholding_accel:1.0\
xilinx.com:hls:color_convert:1.0\
xilinx.com:hls:pixel_pack:1.0\
xilinx.com:hls:pixel_unpack:1.0\
xilinx.com:user:color_swap:1.1\
digilentinc.com:ip:dvi2rgb:1.7\
xilinx.com:ip:v_vid_in_axi4s:4.0\
xilinx.com:ip:v_tc:6.2\
digilentinc.com:ip:axi_dynclk:1.0\
realdigital.org:realdigital:hdmi_tx:1.1\
xilinx.com:ip:v_axi4s_vid_out:4.0\
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


# Hierarchical cell: frontend
proc create_hier_cell_frontend_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_frontend_1() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:vid_io_rtl:1.0 RGB

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXILite

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:hdmi_rtl:2.0 hdmi_tx

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 video_in


  # Create pins
  create_bd_pin -dir I -type clk clk_100M
  create_bd_pin -dir I -type clk clk_142M
  create_bd_pin -dir O -from 0 -to 0 hdmi_out_hpd
  create_bd_pin -dir O -type intr hdmi_out_hpd_irq
  create_bd_pin -dir I -from 0 -to 0 -type rst periph_resetn_clk100M
  create_bd_pin -dir I -type rst rst
  create_bd_pin -dir O -type intr vtc_out_irq

  # Create instance: axi_dynclk, and set properties
  set axi_dynclk [ create_bd_cell -type ip -vlnv digilentinc.com:ip:axi_dynclk:1.0 axi_dynclk ]

  # Create instance: color_swap_0, and set properties
  set color_swap_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:color_swap:1.1 color_swap_0 ]
  set_property -dict [ list \
   CONFIG.output_format {rgb} \
 ] $color_swap_0

  # Create instance: hdmi_out_hpd_video, and set properties
  set hdmi_out_hpd_video [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 hdmi_out_hpd_video ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {1} \
   CONFIG.C_INTERRUPT_PRESENT {1} \
 ] $hdmi_out_hpd_video

  # Create instance: hdmi_tx_0, and set properties
  set hdmi_tx_0 [ create_bd_cell -type ip -vlnv realdigital.org:realdigital:hdmi_tx:1.1 hdmi_tx_0 ]
  set_property -dict [ list \
   CONFIG.C_DATA_WIDTH {24} \
   CONFIG.MODE {DVI} \
 ] $hdmi_tx_0

  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out:4.0 v_axi4s_vid_out_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {11} \
   CONFIG.C_HAS_ASYNC_CLK {1} \
   CONFIG.C_HYSTERESIS_LEVEL {1024} \
   CONFIG.C_VTG_MASTER_SLAVE {1} \
 ] $v_axi4s_vid_out_0

  # Create instance: vtc_out, and set properties
  set vtc_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.2 vtc_out ]
  set_property -dict [ list \
   CONFIG.GEN_F0_VBLANK_HEND {400} \
   CONFIG.GEN_F0_VBLANK_HSTART {400} \
   CONFIG.GEN_F0_VFRAME_SIZE {525} \
   CONFIG.GEN_F0_VSYNC_HEND {420} \
   CONFIG.GEN_F0_VSYNC_HSTART {420} \
   CONFIG.GEN_F0_VSYNC_VEND {496} \
   CONFIG.GEN_F0_VSYNC_VSTART {493} \
   CONFIG.GEN_F1_VFRAME_SIZE {750} \
   CONFIG.GEN_F1_VSYNC_VEND {729} \
   CONFIG.GEN_F1_VSYNC_VSTART {724} \
   CONFIG.GEN_HACTIVE_SIZE {800} \
   CONFIG.GEN_HFRAME_SIZE {928} \
   CONFIG.GEN_HSYNC_END {840} \
   CONFIG.GEN_HSYNC_START {840} \
   CONFIG.GEN_VACTIVE_SIZE {480} \
   CONFIG.VIDEO_MODE {Custom} \
   CONFIG.enable_detection {false} \
 ] $vtc_out

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins hdmi_tx] [get_bd_intf_pins hdmi_tx_0/hdmi_tx]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S02_AXILite] [get_bd_intf_pins vtc_out/ctrl]
  connect_bd_intf_net -intf_net color_swap_0_pixel_output [get_bd_intf_pins color_swap_0/pixel_output] [get_bd_intf_pins hdmi_tx_0/RGB]
  connect_bd_intf_net -intf_net [get_bd_intf_nets color_swap_0_pixel_output] [get_bd_intf_pins RGB] [get_bd_intf_pins hdmi_tx_0/RGB]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M06_AXI [get_bd_intf_pins S00_AXILite] [get_bd_intf_pins hdmi_out_hpd_video/S_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M08_AXI [get_bd_intf_pins S04_AXILite] [get_bd_intf_pins axi_dynclk/s00_axi]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins color_swap_0/pixel_input] [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in] [get_bd_intf_pins vtc_out/vtiming_out]
  connect_bd_intf_net -intf_net video_in_1 [get_bd_intf_pins video_in] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins clk_100M] [get_bd_pins axi_dynclk/REF_CLK_I] [get_bd_pins axi_dynclk/s00_axi_aclk] [get_bd_pins hdmi_out_hpd_video/s_axi_aclk] [get_bd_pins vtc_out/s_axi_aclk]
  connect_bd_net -net Net1 [get_bd_pins periph_resetn_clk100M] [get_bd_pins axi_dynclk/s00_axi_aresetn] [get_bd_pins hdmi_out_hpd_video/s_axi_aresetn] [get_bd_pins vtc_out/s_axi_aresetn]
  connect_bd_net -net aclk_1 [get_bd_pins clk_142M] [get_bd_pins v_axi4s_vid_out_0/aclk]
  connect_bd_net -net axi_dynclk_0_LOCKED_O [get_bd_pins axi_dynclk/LOCKED_O] [get_bd_pins hdmi_tx_0/pix_clk_locked]
  connect_bd_net -net axi_dynclk_0_PXL_CLK_5X_O [get_bd_pins axi_dynclk/PXL_CLK_5X_O] [get_bd_pins hdmi_tx_0/pix_clkx5]
  connect_bd_net -net axi_dynclk_0_PXL_CLK_O [get_bd_pins axi_dynclk/PXL_CLK_O] [get_bd_pins hdmi_tx_0/pix_clk] [get_bd_pins v_axi4s_vid_out_0/vid_io_out_clk] [get_bd_pins vtc_out/clk]
  connect_bd_net -net hdmi_out_hpd_video_gpio_io_o [get_bd_pins hdmi_out_hpd] [get_bd_pins hdmi_out_hpd_video/gpio_io_o]
  connect_bd_net -net hdmi_out_hpd_video_ip2intc_irpt [get_bd_pins hdmi_out_hpd_irq] [get_bd_pins hdmi_out_hpd_video/ip2intc_irpt]
  connect_bd_net -net rst_1 [get_bd_pins rst] [get_bd_pins hdmi_tx_0/rst]
  connect_bd_net -net v_tc_0_irq [get_bd_pins vtc_out_irq] [get_bd_pins vtc_out/irq]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: frontend
proc create_hier_cell_frontend { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_frontend() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 DDC

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXILite

  create_bd_intf_pin -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS_in

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 video_out


  # Create pins
  create_bd_pin -dir O -type clk PixelClk
  create_bd_pin -dir O aPixelClkLckd
  create_bd_pin -dir I -type clk clk_100M
  create_bd_pin -dir I -type clk clk_142M
  create_bd_pin -dir I -type clk clk_200M
  create_bd_pin -dir O -from 0 -to 0 hdmi_in_hpd
  create_bd_pin -dir O -type intr hdmi_in_hpd_irq
  create_bd_pin -dir I -from 0 -to 0 -type rst periph_resetn_clk100M
  create_bd_pin -dir I -from 0 -to 0 -type rst resetn
  create_bd_pin -dir I -from 0 -to 0 -type rst vid_io_in_reset
  create_bd_pin -dir O -type intr vtc_in_irq

  # Create instance: axi_gpio_hdmiin, and set properties
  set axi_gpio_hdmiin [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_hdmiin ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS_2 {1} \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO2_WIDTH {1} \
   CONFIG.C_GPIO_WIDTH {1} \
   CONFIG.C_INTERRUPT_PRESENT {1} \
   CONFIG.C_IS_DUAL {1} \
 ] $axi_gpio_hdmiin

  # Create instance: color_swap_0, and set properties
  set color_swap_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:color_swap:1.1 color_swap_0 ]
  set_property -dict [ list \
   CONFIG.input_format {rbg} \
   CONFIG.output_format {rgb} \
 ] $color_swap_0

  # Create instance: dvi2rgb_0, and set properties
  set dvi2rgb_0 [ create_bd_cell -type ip -vlnv digilentinc.com:ip:dvi2rgb:1.7 dvi2rgb_0 ]
  set_property -dict [ list \
   CONFIG.kAddBUFG {false} \
   CONFIG.kClkRange {1} \
   CONFIG.kEdidFileName {720p_edid.data} \
   CONFIG.kRstActiveHigh {false} \
 ] $dvi2rgb_0

  # Create instance: v_vid_in_axi4s_0, and set properties
  set v_vid_in_axi4s_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_vid_in_axi4s:4.0 v_vid_in_axi4s_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {12} \
   CONFIG.C_HAS_ASYNC_CLK {1} \
 ] $v_vid_in_axi4s_0

  # Create instance: vtc_in, and set properties
  set vtc_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.2 vtc_in ]
  set_property -dict [ list \
   CONFIG.HAS_INTC_IF {true} \
   CONFIG.enable_generation {false} \
   CONFIG.horizontal_blank_detection {false} \
   CONFIG.max_lines_per_frame {2048} \
   CONFIG.vertical_blank_detection {false} \
 ] $vtc_in

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins DDC] [get_bd_intf_pins dvi2rgb_0/DDC]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins TMDS_in] [get_bd_intf_pins dvi2rgb_0/TMDS]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S02_AXILite] [get_bd_intf_pins vtc_in/ctrl]
  connect_bd_intf_net -intf_net color_swap_0_pixel_output [get_bd_intf_pins color_swap_0/pixel_output] [get_bd_intf_pins v_vid_in_axi4s_0/vid_io_in]
  connect_bd_intf_net -intf_net dvi2rgb_0_RGB [get_bd_intf_pins color_swap_0/pixel_input] [get_bd_intf_pins dvi2rgb_0/RGB]
  connect_bd_intf_net -intf_net hdmi_in_video_out [get_bd_intf_pins video_out] [get_bd_intf_pins v_vid_in_axi4s_0/video_out]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M07_AXI [get_bd_intf_pins S00_AXILite] [get_bd_intf_pins axi_gpio_hdmiin/S_AXI]
  connect_bd_intf_net -intf_net v_vid_in_axi4s_0_vtiming_out [get_bd_intf_pins v_vid_in_axi4s_0/vtiming_out] [get_bd_intf_pins vtc_in/vtiming_in]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins clk_100M] [get_bd_pins axi_gpio_hdmiin/s_axi_aclk] [get_bd_pins vtc_in/s_axi_aclk]
  connect_bd_net -net Net1 [get_bd_pins periph_resetn_clk100M] [get_bd_pins axi_gpio_hdmiin/s_axi_aresetn] [get_bd_pins dvi2rgb_0/aRst_n] [get_bd_pins vtc_in/s_axi_aresetn]
  connect_bd_net -net RefClk_1 [get_bd_pins clk_200M] [get_bd_pins dvi2rgb_0/RefClk]
  connect_bd_net -net aclk_1 [get_bd_pins clk_142M] [get_bd_pins v_vid_in_axi4s_0/aclk]
  connect_bd_net -net axi_gpio_video_gpio_io_o [get_bd_pins hdmi_in_hpd] [get_bd_pins axi_gpio_hdmiin/gpio_io_o]
  connect_bd_net -net axi_gpio_video_ip2intc_irpt [get_bd_pins hdmi_in_hpd_irq] [get_bd_pins axi_gpio_hdmiin/ip2intc_irpt]
  connect_bd_net -net dvi2rgb_0_PixelClk1 [get_bd_pins PixelClk] [get_bd_pins dvi2rgb_0/PixelClk] [get_bd_pins v_vid_in_axi4s_0/vid_io_in_clk] [get_bd_pins vtc_in/clk]
  connect_bd_net -net dvi2rgb_0_aPixelClkLckd [get_bd_pins aPixelClkLckd] [get_bd_pins axi_gpio_hdmiin/gpio2_io_i] [get_bd_pins dvi2rgb_0/aPixelClkLckd]
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins vtc_in/resetn]
  connect_bd_net -net v_tc_1_irq [get_bd_pins vtc_in_irq] [get_bd_pins vtc_in/irq]
  connect_bd_net -net vid_io_in_reset_1 [get_bd_pins vid_io_in_reset] [get_bd_pins v_vid_in_axi4s_0/vid_io_in_reset]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: hdmi_out
proc create_hier_cell_hdmi_out { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_hdmi_out() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:vid_io_rtl:1.0 RGB

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXILite

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:hdmi_rtl:2.0 hdmi_tx_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 in_stream

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in_24


  # Create pins
  create_bd_pin -dir I -type clk clk_100M
  create_bd_pin -dir I -type clk clk_142M
  create_bd_pin -dir O -from 0 -to 0 hdmi_out_hpd
  create_bd_pin -dir O -type intr hdmi_out_hpd_irq
  create_bd_pin -dir I -from 0 -to 0 -type rst periph_resetn_clk100M
  create_bd_pin -dir I -from 0 -to 0 -type rst periph_resetn_clk142M
  create_bd_pin -dir I -type rst rst
  create_bd_pin -dir O -type intr vtc_out_irq

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]

  # Create instance: color_convert, and set properties
  set color_convert [ create_bd_cell -type ip -vlnv xilinx.com:hls:color_convert:1.0 color_convert ]

  # Create instance: frontend
  create_hier_cell_frontend_1 $hier_obj frontend

  # Create instance: pixel_unpack, and set properties
  set pixel_unpack [ create_bd_cell -type ip -vlnv xilinx.com:hls:pixel_unpack:1.0 pixel_unpack ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins RGB] [get_bd_intf_pins frontend/RGB]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S02_AXILite] [get_bd_intf_pins frontend/S02_AXILite]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins hdmi_tx_0] [get_bd_intf_pins frontend/hdmi_tx]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_register_slice_0/M_AXIS]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins stream_in_24] [get_bd_intf_pins color_convert/stream_in_24]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins S03_AXILite] [get_bd_intf_pins color_convert/s_axi_control]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins S01_AXILite] [get_bd_intf_pins pixel_unpack/s_axi_control]
  connect_bd_intf_net -intf_net color_convert_stream_out_24 [get_bd_intf_pins color_convert/stream_out_24] [get_bd_intf_pins frontend/video_in]
  connect_bd_intf_net -intf_net in_stream_1 [get_bd_intf_pins in_stream] [get_bd_intf_pins pixel_unpack/stream_in_32]
  connect_bd_intf_net -intf_net pixel_unpack_stream_out_24 [get_bd_intf_pins axis_register_slice_0/S_AXIS] [get_bd_intf_pins pixel_unpack/stream_out_24]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M06_AXI [get_bd_intf_pins S00_AXILite] [get_bd_intf_pins frontend/S00_AXILite]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M08_AXI [get_bd_intf_pins S04_AXILite] [get_bd_intf_pins frontend/S04_AXILite]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins clk_100M] [get_bd_pins frontend/clk_100M]
  connect_bd_net -net Net1 [get_bd_pins periph_resetn_clk100M] [get_bd_pins frontend/periph_resetn_clk100M]
  connect_bd_net -net aclk_1 [get_bd_pins clk_142M] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins color_convert/ap_clk] [get_bd_pins color_convert/control] [get_bd_pins frontend/clk_142M] [get_bd_pins pixel_unpack/ap_clk] [get_bd_pins pixel_unpack/control]
  connect_bd_net -net hdmi_out_hpd_video_gpio_io_o [get_bd_pins hdmi_out_hpd] [get_bd_pins frontend/hdmi_out_hpd]
  connect_bd_net -net hdmi_out_hpd_video_ip2intc_irpt [get_bd_pins hdmi_out_hpd_irq] [get_bd_pins frontend/hdmi_out_hpd_irq]
  connect_bd_net -net rst_1 [get_bd_pins rst] [get_bd_pins frontend/rst]
  connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_pins periph_resetn_clk142M] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins color_convert/ap_rst_n] [get_bd_pins color_convert/ap_rst_n_control] [get_bd_pins pixel_unpack/ap_rst_n] [get_bd_pins pixel_unpack/ap_rst_n_control]
  connect_bd_net -net v_tc_0_irq [get_bd_pins vtc_out_irq] [get_bd_pins frontend/vtc_out_irq]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: hdmi_in
proc create_hier_cell_hdmi_in { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_hdmi_in() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 DDC

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S02_AXILite

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S03_AXILite

  create_bd_intf_pin -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS_in

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 out_stream

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in_24


  # Create pins
  create_bd_pin -dir O -type clk PixelClk
  create_bd_pin -dir O aPixelClkLckd
  create_bd_pin -dir I -type clk clk_100M
  create_bd_pin -dir I -type clk clk_142M
  create_bd_pin -dir I -type clk clk_200M
  create_bd_pin -dir O -from 0 -to 0 hdmi_in_hpd
  create_bd_pin -dir O -type intr hdmi_in_hpd_irq
  create_bd_pin -dir I -from 0 -to 0 -type rst periph_resetn_clk100M
  create_bd_pin -dir I -from 0 -to 0 -type rst periph_resetn_clk142M
  create_bd_pin -dir I -from 0 -to 0 -type rst resetn
  create_bd_pin -dir I -from 0 -to 0 -type rst vid_io_in_reset
  create_bd_pin -dir O -type intr vtc_in_irq

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]

  # Create instance: color_convert, and set properties
  set color_convert [ create_bd_cell -type ip -vlnv xilinx.com:hls:color_convert:1.0 color_convert ]

  # Create instance: frontend
  create_hier_cell_frontend $hier_obj frontend

  # Create instance: pixel_pack, and set properties
  set pixel_pack [ create_bd_cell -type ip -vlnv xilinx.com:hls:pixel_pack:1.0 pixel_pack ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_register_slice_0/M_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins stream_in_24] [get_bd_intf_pins pixel_pack/stream_in_24]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S02_AXILite] [get_bd_intf_pins frontend/S02_AXILite]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins S03_AXILite] [get_bd_intf_pins pixel_pack/s_axi_control]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins S01_AXILite] [get_bd_intf_pins color_convert/s_axi_control]
  connect_bd_intf_net -intf_net TMDS_1 [get_bd_intf_pins TMDS_in] [get_bd_intf_pins frontend/TMDS_in]
  connect_bd_intf_net -intf_net color_convert_stream_out_24 [get_bd_intf_pins axis_register_slice_0/S_AXIS] [get_bd_intf_pins color_convert/stream_out_24]
  connect_bd_intf_net -intf_net frontend_DDC [get_bd_intf_pins DDC] [get_bd_intf_pins frontend/DDC]
  connect_bd_intf_net -intf_net frontend_video_out [get_bd_intf_pins color_convert/stream_in_24] [get_bd_intf_pins frontend/video_out]
  connect_bd_intf_net -intf_net pixel_pack_stream_out_32 [get_bd_intf_pins out_stream] [get_bd_intf_pins pixel_pack/stream_out_32]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M07_AXI [get_bd_intf_pins S00_AXILite] [get_bd_intf_pins frontend/S00_AXILite]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins clk_100M] [get_bd_pins frontend/clk_100M]
  connect_bd_net -net RefClk_1 [get_bd_pins clk_200M] [get_bd_pins frontend/clk_200M]
  connect_bd_net -net aclk_1 [get_bd_pins clk_142M] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins color_convert/ap_clk] [get_bd_pins color_convert/control] [get_bd_pins frontend/clk_142M] [get_bd_pins pixel_pack/ap_clk] [get_bd_pins pixel_pack/control]
  connect_bd_net -net axi_gpio_video_gpio_io_o [get_bd_pins hdmi_in_hpd] [get_bd_pins frontend/hdmi_in_hpd]
  connect_bd_net -net axi_gpio_video_ip2intc_irpt [get_bd_pins hdmi_in_hpd_irq] [get_bd_pins frontend/hdmi_in_hpd_irq]
  connect_bd_net -net dvi2rgb_0_PixelClk [get_bd_pins PixelClk] [get_bd_pins frontend/PixelClk]
  connect_bd_net -net dvi2rgb_0_aPixelClkLckd [get_bd_pins aPixelClkLckd] [get_bd_pins frontend/aPixelClkLckd]
  connect_bd_net -net periph_resetn_clk100M_1 [get_bd_pins periph_resetn_clk100M] [get_bd_pins frontend/periph_resetn_clk100M]
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins frontend/resetn]
  connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_pins periph_resetn_clk142M] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins color_convert/ap_rst_n] [get_bd_pins color_convert/ap_rst_n_control] [get_bd_pins pixel_pack/ap_rst_n] [get_bd_pins pixel_pack/ap_rst_n_control]
  connect_bd_net -net v_tc_1_irq [get_bd_pins vtc_in_irq] [get_bd_pins frontend/vtc_in_irq]
  connect_bd_net -net vid_io_in_reset_1 [get_bd_pins vid_io_in_reset] [get_bd_pins frontend/vid_io_in_reset]

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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M06_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M07_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M08_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M09_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M10_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M11_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M12_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S06_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S07_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S08_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S09_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S10_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S11_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S12_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CTRL

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control4
  
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control_lut


  # Create pins
  create_bd_pin -dir I clk_142M
  create_bd_pin -dir I -type rst periph_resetn_clk142M
  create_bd_pin -dir I -type rst soft_rst_n

  # Create instance: axis_fifo_hdmi_out, and set properties
  set axis_fifo_hdmi_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_fifo_hdmi_out ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {4096} \
   CONFIG.FIFO_MEMORY_TYPE {block} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {6} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_fifo_hdmi_out

  # Create instance: axis_switch, and set properties
  set axis_switch [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch ]
  set_property -dict [ list \
   CONFIG.DECODER_REG {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.NUM_MI {15} \
   CONFIG.NUM_SI {15} \
   CONFIG.ROUTING_MODE {1} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_switch

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


  # Create instance: filter2d_accel, and set properties
  set filter2d_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:filter2d_accel:1.0 filter2d_accel ]

  # Create instance: gray2rgb_accel, and set properties
  set gray2rgb_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:gray2rgb_accel:1.0 gray2rgb_accel ]

  # Create instance: lut_accel, and set properties
  set lut_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:LUT_accel:1.0 lut_accel ]

  # Create instance: rgb2gray_accel, and set properties
  set rgb2gray_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:rgb2gray_accel:1.0 rgb2gray_accel ]

  # Create instance: rgb2hsv_accel, and set properties
  set rgb2hsv_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:rgb2hsv_accel:1.0 rgb2hsv_accel ]

  # Create instance: colorthresholding_accel, and set properties
  set colorthresholding_accel [create_bd_cell -type ip -vlnv xilinx.com:hls:colorthresholding_accel:1.0 colorthresholding_accel]

  # Create interface connections
  connect_bd_intf_net -intf_net S06_AXIS_1 [get_bd_intf_pins S06_AXIS] [get_bd_intf_pins axis_switch/S06_AXIS]
  connect_bd_intf_net -intf_net S07_AXIS_1 [get_bd_intf_pins S07_AXIS] [get_bd_intf_pins axis_switch/S07_AXIS]
  connect_bd_intf_net -intf_net S08_AXIS_1 [get_bd_intf_pins S08_AXIS] [get_bd_intf_pins axis_switch/S08_AXIS]
  connect_bd_intf_net -intf_net S09_AXIS_1 [get_bd_intf_pins S09_AXIS] [get_bd_intf_pins axis_switch/S09_AXIS]
  connect_bd_intf_net -intf_net S10_AXIS_1 [get_bd_intf_pins S10_AXIS] [get_bd_intf_pins axis_switch/S10_AXIS]
  connect_bd_intf_net -intf_net S11_AXIS_1 [get_bd_intf_pins S11_AXIS] [get_bd_intf_pins axis_switch/S11_AXIS]
  connect_bd_intf_net -intf_net S12_AXIS_1 [get_bd_intf_pins S12_AXIS] [get_bd_intf_pins axis_switch/S12_AXIS]
  connect_bd_intf_net -intf_net axi_interconnect_0_M10_AXI [get_bd_intf_pins S_AXI_CTRL] [get_bd_intf_pins axis_switch/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_0_M11_AXI [get_bd_intf_pins s_axi_control3] [get_bd_intf_pins gray2rgb_accel/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_0_M12_AXI [get_bd_intf_pins s_axi_control] [get_bd_intf_pins rgb2gray_accel/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_0_M13_AXI [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins rgb2hsv_accel/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_0_M17_AXI [get_bd_intf_pins s_axi_control4] [get_bd_intf_pins filter2d_accel/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_0_M20_AXI [get_bd_intf_pins s_axi_control_lut] [get_bd_intf_pins lut_accel/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_0_M23_AXI [get_bd_intf_pins s_axi_control5] [get_bd_intf_pins colorthresholding_accel/s_axi_control]
  connect_bd_intf_net -intf_net axis_dwidth_24_48_M_AXIS [get_bd_intf_pins axis_fifo_hdmi_out/S_AXIS] [get_bd_intf_pins axis_dwidth_24_48/M_AXIS]
  connect_bd_intf_net -intf_net axis_fifo_hdmi_out_M_AXIS [get_bd_intf_pins axis_dwidth_48_24/S_AXIS] [get_bd_intf_pins axis_fifo_hdmi_out/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_48_24_M_AXIS [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins axis_dwidth_48_24/M_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M00_AXIS [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_switch/M00_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M01_AXIS [get_bd_intf_pins axis_dwidth_24_48/S_AXIS] [get_bd_intf_pins axis_switch/M01_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M02_AXIS [get_bd_intf_pins axis_switch/M02_AXIS] [get_bd_intf_pins rgb2gray_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M03_AXIS [get_bd_intf_pins axis_switch/M03_AXIS] [get_bd_intf_pins gray2rgb_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M04_AXIS [get_bd_intf_pins axis_switch/M04_AXIS] [get_bd_intf_pins rgb2hsv_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M05_AXIS [get_bd_intf_pins axis_switch/M05_AXIS] [get_bd_intf_pins filter2d_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M14_AXIS [get_bd_intf_pins axis_switch/M14_AXIS] [get_bd_intf_pins colorthresholding_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M06_AXIS [get_bd_intf_pins M06_AXIS] [get_bd_intf_pins axis_switch/M06_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M07_AXIS [get_bd_intf_pins M07_AXIS] [get_bd_intf_pins axis_switch/M07_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M08_AXIS [get_bd_intf_pins M08_AXIS] [get_bd_intf_pins axis_switch/M08_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M09_AXIS [get_bd_intf_pins M09_AXIS] [get_bd_intf_pins axis_switch/M09_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M10_AXIS [get_bd_intf_pins M10_AXIS] [get_bd_intf_pins axis_switch/M10_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M11_AXIS [get_bd_intf_pins M11_AXIS] [get_bd_intf_pins axis_switch/M11_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M12_AXIS [get_bd_intf_pins M12_AXIS] [get_bd_intf_pins axis_switch/M12_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M13_AXIS [get_bd_intf_pins axis_switch/M13_AXIS] [get_bd_intf_pins lut_accel/stream_in]
  connect_bd_intf_net -intf_net filter2d_accel_stream_out [get_bd_intf_pins axis_switch/S05_AXIS] [get_bd_intf_pins filter2d_accel/stream_out]
  connect_bd_intf_net -intf_net gray2rgb_accel_stream_out [get_bd_intf_pins axis_switch/S03_AXIS] [get_bd_intf_pins gray2rgb_accel/stream_out]
  connect_bd_intf_net -intf_net hdmi_in_M_AXIS [get_bd_intf_pins S00_AXIS] [get_bd_intf_pins axis_switch/S00_AXIS]
  connect_bd_intf_net -intf_net hdmi_out_M_AXIS [get_bd_intf_pins S01_AXIS] [get_bd_intf_pins axis_switch/S01_AXIS]
  connect_bd_intf_net -intf_net lut_accel_accel_stream_out [get_bd_intf_pins axis_switch/S13_AXIS] [get_bd_intf_pins lut_accel/stream_out]
  connect_bd_intf_net -intf_net rgb2gray_accel_stream_out [get_bd_intf_pins axis_switch/S02_AXIS] [get_bd_intf_pins rgb2gray_accel/stream_out]
  connect_bd_intf_net -intf_net rgb2hsv_accel_stream_out [get_bd_intf_pins axis_switch/S04_AXIS] [get_bd_intf_pins rgb2hsv_accel/stream_out]
  connect_bd_intf_net -intf_net colorthresholding_accel_stream_out [get_bd_intf_pins axis_switch/S14_AXIS] [get_bd_intf_pins colorthresholding_accel/stream_out]

  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_pins clk_142M] [get_bd_pins axis_fifo_hdmi_out/s_axis_aclk] [get_bd_pins axis_switch/aclk] [get_bd_pins axis_switch/s_axi_ctrl_aclk] [get_bd_pins filter2d_accel/ap_clk] [get_bd_pins gray2rgb_accel/ap_clk] [get_bd_pins lut_accel/ap_clk] [get_bd_pins rgb2gray_accel/ap_clk] [get_bd_pins rgb2hsv_accel/ap_clk] [get_bd_pins colorthresholding_accel/ap_clk] [get_bd_pins axis_dwidth_24_48/aclk] [get_bd_pins axis_dwidth_48_24/aclk]
  connect_bd_net -net soft_peripheral_aresetn [get_bd_pins soft_rst_n] [get_bd_pins axis_fifo_hdmi_out/s_axis_aresetn] [get_bd_pins filter2d_accel/ap_rst_n] [get_bd_pins gray2rgb_accel/ap_rst_n] [get_bd_pins lut_accel/ap_rst_n] [get_bd_pins rgb2gray_accel/ap_rst_n] [get_bd_pins rgb2hsv_accel/ap_rst_n] [get_bd_pins colorthresholding_accel/ap_rst_n] [get_bd_pins axis_dwidth_24_48/aresetn] [get_bd_pins axis_dwidth_48_24/aresetn]
  connect_bd_net -net rst_ps7_0_fclk1_peripheral_aresetn [get_bd_pins periph_resetn_clk142M] [get_bd_pins axis_switch/aresetn] [get_bd_pins axis_switch/s_axi_ctrl_aresetn]

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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 DDC

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M06_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M07_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M08_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M09_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M10_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M11_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M12_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M16_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M17_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M18_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M19_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M21_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M22_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M24_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M25_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M26_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:vid_io_rtl:1.0 RGB

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S06_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S07_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S08_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S09_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S10_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S11_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S12_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS_in

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:hdmi_rtl:2.0 hdmi_tx_0


  # Create pins
  create_bd_pin -dir I -type rst FCLK_RESET0_N
  create_bd_pin -dir I -from 0 -to 0 btns_int
  create_bd_pin -dir I -type clk clk_100M
  create_bd_pin -dir I clk_142M
  create_bd_pin -dir I -type clk clk_200M
  create_bd_pin -dir O -from 0 -to 0 dout
  create_bd_pin -dir O -from 0 -to 0 hdmi_in_hpd
  create_bd_pin -dir O -from 0 -to 0 hdmi_out_hpd
  create_bd_pin -dir I -from 0 -to 0 leds_int
  create_bd_pin -dir O -from 0 -to 0 -type rst periph_resetn_clk100M
  create_bd_pin -dir O -from 0 -to 0 -type rst periph_resetn_clk142M
  create_bd_pin -dir O -from 0 -to 0 -type rst soft_rst_n
  create_bd_pin -dir I -from 0 -to 0 switches_int
  create_bd_pin -dir I -from 8 -to 0 gpio_in

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.M01_HAS_REGSLICE {1} \
   CONFIG.M02_HAS_REGSLICE {1} \
   CONFIG.M03_HAS_REGSLICE {1} \
   CONFIG.M04_HAS_REGSLICE {1} \
   CONFIG.M05_HAS_REGSLICE {1} \
   CONFIG.M06_HAS_REGSLICE {1} \
   CONFIG.M07_HAS_REGSLICE {1} \
   CONFIG.M08_HAS_REGSLICE {1} \
   CONFIG.M09_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {27} \
   CONFIG.S00_HAS_REGSLICE {1} \
 ] $axi_interconnect_0

  # Create instance: axi_mem_intercon, and set properties
  set axi_mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
 ] $axi_mem_intercon

  # Create instance: axi_vdma, and set properties
  set axi_vdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma ]
  set_property -dict [ list \
   CONFIG.c_m_axi_mm2s_data_width {32} \
   CONFIG.c_m_axis_mm2s_tdata_width {32} \
   CONFIG.c_mm2s_genlock_mode {1} \
   CONFIG.c_mm2s_linebuffer_depth {512} \
   CONFIG.c_mm2s_max_burst_length {32} \
   CONFIG.c_num_fstores {4} \
   CONFIG.c_s2mm_genlock_mode {0} \
   CONFIG.c_s2mm_linebuffer_depth {4096} \
   CONFIG.c_s2mm_max_burst_length {32} \
 ] $axi_vdma

  # Create instance: composable
  create_hier_cell_composable $hier_obj composable

  # Create instance: concat_interrupts, and set properties
  set concat_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_interrupts ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {1} \
 ] $concat_interrupts

  # Create instance: hdmi_in
  create_hier_cell_hdmi_in $hier_obj hdmi_in

  # Create instance: hdmi_out
  create_hier_cell_hdmi_out $hier_obj hdmi_out

  # Create instance: proc_sys_reset_pixelclk, and set properties
  set proc_sys_reset_pixelclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_pixelclk ]

  # Create instance: rst_ps7_0_fclk0, and set properties
  set rst_ps7_0_fclk0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_fclk0 ]

  # Create instance: rst_ps7_0_fclk1, and set properties
  set rst_ps7_0_fclk1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_fclk1 ]

  # Create instance: ps_user_soft_reset, and set properties
  set ps_user_soft_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 ps_user_soft_reset ]
  set_property -dict [ list \
   CONFIG.C_AUX_RESET_HIGH.VALUE_SRC USER \
   CONFIG.C_AUX_RESET_HIGH {1} \
 ] $ps_user_soft_reset

  # Create instance: system_interrupts, and set properties
  set system_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 system_interrupts ]

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {9} \
 ] $xlconcat_0

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {1} \
 ] $xlconcat_1

  # Create instance: xlslice, and set properties
  set xlslice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {8} \
   CONFIG.DIN_TO {8} \
   CONFIG.DIN_WIDTH {9} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins RGB] [get_bd_intf_pins hdmi_out/RGB]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins hdmi_tx_0] [get_bd_intf_pins hdmi_out/hdmi_tx_0]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S08_AXIS] [get_bd_intf_pins composable/S08_AXIS]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins M09_AXIS] [get_bd_intf_pins composable/M09_AXIS]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins M08_AXIS] [get_bd_intf_pins composable/M08_AXIS]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins S06_AXIS] [get_bd_intf_pins composable/S06_AXIS]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins M06_AXIS] [get_bd_intf_pins composable/M06_AXIS]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins S07_AXIS] [get_bd_intf_pins composable/S07_AXIS]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins M07_AXIS] [get_bd_intf_pins composable/M07_AXIS]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins S09_AXIS] [get_bd_intf_pins composable/S09_AXIS]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins M18_AXI] [get_bd_intf_pins axi_interconnect_0/M18_AXI]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins M19_AXI] [get_bd_intf_pins axi_interconnect_0/M19_AXI]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins M21_AXI] [get_bd_intf_pins axi_interconnect_0/M21_AXI]
  connect_bd_intf_net -intf_net Conn15 [get_bd_intf_pins M22_AXI] [get_bd_intf_pins axi_interconnect_0/M22_AXI]
  connect_bd_intf_net -intf_net S11_AXIS_1 [get_bd_intf_pins S10_AXIS] [get_bd_intf_pins composable/S10_AXIS]
  connect_bd_intf_net -intf_net S12_AXIS_1 [get_bd_intf_pins S11_AXIS] [get_bd_intf_pins composable/S11_AXIS]
  connect_bd_intf_net -intf_net S13_AXIS_1 [get_bd_intf_pins S12_AXIS] [get_bd_intf_pins composable/S12_AXIS]
  connect_bd_intf_net -intf_net TMDS_1 [get_bd_intf_pins TMDS_in] [get_bd_intf_pins hdmi_in/TMDS_in]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_vdma/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins hdmi_out/S01_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins hdmi_out/S03_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins hdmi_out/S04_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins hdmi_out/S02_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M05_AXI [get_bd_intf_pins axi_interconnect_0/M05_AXI] [get_bd_intf_pins hdmi_out/S00_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M06_AXI [get_bd_intf_pins axi_interconnect_0/M06_AXI] [get_bd_intf_pins hdmi_in/S01_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M07_AXI [get_bd_intf_pins axi_interconnect_0/M07_AXI] [get_bd_intf_pins hdmi_in/S03_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M08_AXI [get_bd_intf_pins axi_interconnect_0/M08_AXI] [get_bd_intf_pins hdmi_in/S00_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M09_AXI [get_bd_intf_pins axi_interconnect_0/M09_AXI] [get_bd_intf_pins hdmi_in/S02_AXILite]
  connect_bd_intf_net -intf_net axi_interconnect_0_M10_AXI [get_bd_intf_pins axi_interconnect_0/M10_AXI] [get_bd_intf_pins composable/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_0_M13_AXI [get_bd_intf_pins axi_interconnect_0/M13_AXI] [get_bd_intf_pins system_interrupts/s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_0_M15_AXI [get_bd_intf_pins axi_interconnect_0/M15_AXI] [get_bd_intf_pins composable/s_axi_control4]
  connect_bd_intf_net -intf_net axi_interconnect_0_M23_AXI [get_bd_intf_pins axi_interconnect_0/M23_AXI] [get_bd_intf_pins composable/s_axi_control5]
  connect_bd_intf_net -intf_net axi_interconnect_0_M16_AXI [get_bd_intf_pins M16_AXI] [get_bd_intf_pins axi_interconnect_0/M16_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M17_AXI [get_bd_intf_pins M17_AXI] [get_bd_intf_pins axi_interconnect_0/M17_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M24_AXI [get_bd_intf_pins M24_AXI] [get_bd_intf_pins axi_interconnect_0/M24_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M25_AXI [get_bd_intf_pins M25_AXI] [get_bd_intf_pins axi_interconnect_0/M25_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M26_AXI [get_bd_intf_pins M26_AXI] [get_bd_intf_pins axi_interconnect_0/M26_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_mem_intercon/M00_AXI]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins axi_vdma/M_AXIS_MM2S] [get_bd_intf_pins hdmi_out/in_stream]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins axi_mem_intercon/S01_AXI] [get_bd_intf_pins axi_vdma/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins axi_vdma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net composable_M11_AXIS [get_bd_intf_pins M10_AXIS] [get_bd_intf_pins composable/M10_AXIS]
  connect_bd_intf_net -intf_net composable_M12_AXIS [get_bd_intf_pins M11_AXIS] [get_bd_intf_pins composable/M11_AXIS]
  connect_bd_intf_net -intf_net composable_M13_AXIS [get_bd_intf_pins M12_AXIS] [get_bd_intf_pins composable/M12_AXIS]
  connect_bd_intf_net -intf_net frontend_DDC [get_bd_intf_pins DDC] [get_bd_intf_pins hdmi_in/DDC]
  connect_bd_intf_net -intf_net hdmi_in_M_AXIS [get_bd_intf_pins composable/S00_AXIS] [get_bd_intf_pins hdmi_in/M_AXIS]
  connect_bd_intf_net -intf_net hdmi_out_M_AXIS [get_bd_intf_pins composable/S01_AXIS] [get_bd_intf_pins hdmi_out/M_AXIS]
  connect_bd_intf_net -intf_net in_pixelformat_M00_AXIS [get_bd_intf_pins axi_vdma/S_AXIS_S2MM] [get_bd_intf_pins hdmi_in/out_stream]
  connect_bd_intf_net -intf_net s_axi_control1_1 [get_bd_intf_pins axi_interconnect_0/M12_AXI] [get_bd_intf_pins composable/s_axi_control1]
  connect_bd_intf_net -intf_net s_axi_control3_1 [get_bd_intf_pins axi_interconnect_0/M14_AXI] [get_bd_intf_pins composable/s_axi_control3]
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_pins axi_interconnect_0/M11_AXI] [get_bd_intf_pins composable/s_axi_control]
  connect_bd_intf_net -intf_net s_axi_control_lut [get_bd_intf_pins axi_interconnect_0/M20_AXI] [get_bd_intf_pins composable/s_axi_control_lut]
  connect_bd_intf_net -intf_net stream_in_24_1 [get_bd_intf_pins composable/M01_AXIS] [get_bd_intf_pins hdmi_out/stream_in_24]
  connect_bd_intf_net -intf_net stream_in_24_2 [get_bd_intf_pins composable/M00_AXIS] [get_bd_intf_pins hdmi_in/stream_in_24]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins axi_interconnect_0/M05_ARESETN] [get_bd_pins axi_interconnect_0/M08_ARESETN] [get_bd_pins axi_interconnect_0/M09_ARESETN] [get_bd_pins axi_interconnect_0/M13_ARESETN] [get_bd_pins axi_interconnect_0/M24_ARESETN] [get_bd_pins axi_interconnect_0/M25_ARESETN] [get_bd_pins axi_interconnect_0/M26_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins rst_ps7_0_fclk0/interconnect_aresetn]
  connect_bd_net -net ARESETN_2 [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins rst_ps7_0_fclk1/interconnect_aresetn]
  connect_bd_net -net In6_1 [get_bd_pins btns_int] [get_bd_pins xlconcat_0/In6]
  connect_bd_net -net In7_1 [get_bd_pins switches_int] [get_bd_pins xlconcat_0/In7]
  connect_bd_net -net In8_1 [get_bd_pins leds_int] [get_bd_pins xlconcat_0/In8]
  connect_bd_net -net Net [get_bd_pins clk_100M] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/M04_ACLK] [get_bd_pins axi_interconnect_0/M05_ACLK] [get_bd_pins axi_interconnect_0/M08_ACLK] [get_bd_pins axi_interconnect_0/M09_ACLK] [get_bd_pins axi_interconnect_0/M13_ACLK] [get_bd_pins axi_interconnect_0/M24_ACLK] [get_bd_pins axi_interconnect_0/M25_ACLK] [get_bd_pins axi_interconnect_0/M26_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_vdma/s_axi_lite_aclk] [get_bd_pins hdmi_in/clk_100M] [get_bd_pins hdmi_out/clk_100M] [get_bd_pins rst_ps7_0_fclk0/slowest_sync_clk] [get_bd_pins system_interrupts/s_axi_aclk]
  connect_bd_net -net Net1 [get_bd_pins periph_resetn_clk100M] [get_bd_pins axi_vdma/axi_resetn] [get_bd_pins hdmi_in/periph_resetn_clk100M] [get_bd_pins hdmi_out/periph_resetn_clk100M] [get_bd_pins rst_ps7_0_fclk0/peripheral_aresetn] [get_bd_pins system_interrupts/s_axi_aresetn]
  connect_bd_net -net RefClk_1 [get_bd_pins clk_200M] [get_bd_pins hdmi_in/clk_200M]
  connect_bd_net -net aclk_1 [get_bd_pins clk_142M] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M06_ACLK] [get_bd_pins axi_interconnect_0/M07_ACLK] [get_bd_pins axi_interconnect_0/M10_ACLK] [get_bd_pins axi_interconnect_0/M11_ACLK] [get_bd_pins axi_interconnect_0/M12_ACLK] [get_bd_pins axi_interconnect_0/M14_ACLK] [get_bd_pins axi_interconnect_0/M15_ACLK] [get_bd_pins axi_interconnect_0/M16_ACLK] [get_bd_pins axi_interconnect_0/M17_ACLK] [get_bd_pins axi_interconnect_0/M18_ACLK] [get_bd_pins axi_interconnect_0/M19_ACLK] [get_bd_pins axi_interconnect_0/M20_ACLK] [get_bd_pins axi_interconnect_0/M21_ACLK] [get_bd_pins axi_interconnect_0/M22_ACLK] [get_bd_pins axi_interconnect_0/M23_ACLK] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon/S01_ACLK] [get_bd_pins axi_vdma/m_axi_mm2s_aclk] [get_bd_pins axi_vdma/m_axi_s2mm_aclk] [get_bd_pins axi_vdma/m_axis_mm2s_aclk] [get_bd_pins axi_vdma/s_axis_s2mm_aclk] [get_bd_pins composable/clk_142M] [get_bd_pins hdmi_in/clk_142M] [get_bd_pins hdmi_out/clk_142M] [get_bd_pins rst_ps7_0_fclk1/slowest_sync_clk] [get_bd_pins ps_user_soft_reset/slowest_sync_clk]
  connect_bd_net -net axi_gpio_video_gpio_io_o [get_bd_pins hdmi_in_hpd] [get_bd_pins hdmi_in/hdmi_in_hpd]
  connect_bd_net -net axi_gpio_video_ip2intc_irpt [get_bd_pins hdmi_in/hdmi_in_hpd_irq] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net axi_vdma_0_mm2s_introut [get_bd_pins axi_vdma/mm2s_introut] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins axi_vdma/s2mm_introut] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net concat_interrupts_dout [get_bd_pins concat_interrupts/dout] [get_bd_pins system_interrupts/intr]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins FCLK_RESET0_N] [get_bd_pins proc_sys_reset_pixelclk/ext_reset_in] [get_bd_pins rst_ps7_0_fclk0/ext_reset_in] [get_bd_pins rst_ps7_0_fclk1/ext_reset_in] [get_bd_pins ps_user_soft_reset/ext_reset_in]
  connect_bd_net -net hdmi_in_PixelClk [get_bd_pins hdmi_in/PixelClk] [get_bd_pins proc_sys_reset_pixelclk/slowest_sync_clk]
  connect_bd_net -net hdmi_in_aPixelClkLckd [get_bd_pins hdmi_in/aPixelClkLckd] [get_bd_pins proc_sys_reset_pixelclk/aux_reset_in]
  connect_bd_net -net hdmi_out_hpd_video_gpio_io_o [get_bd_pins hdmi_out_hpd] [get_bd_pins hdmi_out/hdmi_out_hpd]
  connect_bd_net -net hdmi_out_hpd_video_ip2intc_irpt [get_bd_pins hdmi_out/hdmi_out_hpd_irq] [get_bd_pins xlconcat_0/In5]
  connect_bd_net -net rst_1 [get_bd_pins hdmi_out/rst] [get_bd_pins rst_ps7_0_fclk0/peripheral_reset]
  connect_bd_net -net rst_ps7_0_fclk1_peripheral_aresetn [get_bd_pins periph_resetn_clk142M] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M06_ARESETN] [get_bd_pins axi_interconnect_0/M07_ARESETN] [get_bd_pins axi_interconnect_0/M10_ARESETN] [get_bd_pins axi_interconnect_0/M11_ARESETN] [get_bd_pins axi_interconnect_0/M12_ARESETN] [get_bd_pins axi_interconnect_0/M14_ARESETN] [get_bd_pins axi_interconnect_0/M15_ARESETN] [get_bd_pins axi_interconnect_0/M16_ARESETN] [get_bd_pins axi_interconnect_0/M17_ARESETN] [get_bd_pins axi_interconnect_0/M18_ARESETN] [get_bd_pins axi_interconnect_0/M19_ARESETN] [get_bd_pins axi_interconnect_0/M20_ARESETN] [get_bd_pins axi_interconnect_0/M21_ARESETN] [get_bd_pins axi_interconnect_0/M22_ARESETN] [get_bd_pins axi_interconnect_0/M23_ARESETN] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon/S01_ARESETN] [get_bd_pins composable/periph_resetn_clk142M] [get_bd_pins hdmi_in/periph_resetn_clk142M] [get_bd_pins hdmi_out/periph_resetn_clk142M] [get_bd_pins rst_ps7_0_fclk1/peripheral_aresetn]
  connect_bd_net -net ps_user_soft_reset_peripheral_aresetn [get_bd_pins soft_rst_n] [get_bd_pins composable/soft_rst_n] [get_bd_pins ps_user_soft_reset/peripheral_aresetn]
  connect_bd_net -net system_interrupts_irq [get_bd_pins system_interrupts/irq] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net v_tc_0_irq [get_bd_pins hdmi_out/vtc_out_irq] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net v_tc_1_irq [get_bd_pins hdmi_in/vtc_in_irq] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net vid_io_in_reset_1 [get_bd_pins hdmi_in/vid_io_in_reset] [get_bd_pins proc_sys_reset_pixelclk/peripheral_reset]
  connect_bd_net -net vtc_in_resetn_1 [get_bd_pins hdmi_in/resetn] [get_bd_pins proc_sys_reset_pixelclk/peripheral_aresetn]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins concat_interrupts/In0] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins dout] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net ps7_0_GPIO_O [get_bd_pins gpio_in] [get_bd_pins xlslice/Din]
  connect_bd_net -net xlslice_soft_reset [get_bd_pins xlslice/Dout] [get_bd_pins ps_user_soft_reset/aux_reset_in]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pr_join
proc create_hier_cell_pr_join { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_pr_join() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out


  # Create pins
  create_bd_pin -dir I -type clk clk_142M
  create_bd_pin -dir I -type rst periph_resetn_clk142M

  # Create instance: subtract_accel, and set properties
  set subtract_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:subtract_accel:1.0 subtract_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins subtract_accel/s_axi_control]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins stream_in0] [get_bd_intf_pins subtract_accel/stream_in]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins stream_in1] [get_bd_intf_pins subtract_accel/stream_in1]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins stream_out] [get_bd_intf_pins subtract_accel/stream_out]

  # Create port connections
  connect_bd_net -net ps7_0_FCLK_CLK1 [get_bd_pins clk_142M] [get_bd_pins subtract_accel/ap_clk]
  connect_bd_net -net rst_ps7_0_fclk1_peripheral_aresetn [get_bd_pins periph_resetn_clk142M] [get_bd_pins subtract_accel/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pr_fork
proc create_hier_cell_pr_fork { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_pr_fork() - Empty argument(s)!"}
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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out1


  # Create pins
  create_bd_pin -dir I -type clk clk_142M
  create_bd_pin -dir I -type rst periph_resetn_clk142M

  # Create instance: duplicate_accel, and set properties
  set duplicate_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:duplicate_accel:1.0 duplicate_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins stream_in0] [get_bd_intf_pins duplicate_accel/stream_in]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins duplicate_accel/s_axi_control]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins stream_out0] [get_bd_intf_pins duplicate_accel/stream_out]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins stream_out1] [get_bd_intf_pins duplicate_accel/stream_out1]

  # Create port connections
  connect_bd_net -net ps7_0_FCLK_CLK1 [get_bd_pins clk_142M] [get_bd_pins duplicate_accel/ap_clk]
  connect_bd_net -net rst_ps7_0_fclk1_peripheral_aresetn [get_bd_pins periph_resetn_clk142M] [get_bd_pins duplicate_accel/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pr_1
proc create_hier_cell_pr_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_pr_1() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out1


  # Create pins
  create_bd_pin -dir I clk_142M
  create_bd_pin -dir I -type rst periph_resetn_clk142M

  # Create instance: dilate_accel, and set properties
  set dilate_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:dilate_accel:1.0 dilate_accel ]

  # Create instance: erode_accel, and set properties
  set erode_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:erode_accel:1.0 erode_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net dilate_accel_stream_out [get_bd_intf_pins stream_out0] [get_bd_intf_pins dilate_accel/stream_out]
  connect_bd_intf_net -intf_net erode_accel_stream_out [get_bd_intf_pins stream_out1] [get_bd_intf_pins erode_accel/stream_out]
  connect_bd_intf_net -intf_net s_axi_control0_1 [get_bd_intf_pins s_axi_control0] [get_bd_intf_pins dilate_accel/s_axi_control]
  connect_bd_intf_net -intf_net s_axi_control1_1 [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins erode_accel/s_axi_control]
  connect_bd_intf_net -intf_net stream_in0_1 [get_bd_intf_pins stream_in0] [get_bd_intf_pins dilate_accel/stream_in]
  connect_bd_intf_net -intf_net stream_in1_1 [get_bd_intf_pins stream_in1] [get_bd_intf_pins erode_accel/stream_in]

  # Create port connections
  connect_bd_net -net clk_142M_1 [get_bd_pins clk_142M] [get_bd_pins dilate_accel/ap_clk] [get_bd_pins erode_accel/ap_clk]
  connect_bd_net -net periph_resetn_clk142M_1 [get_bd_pins periph_resetn_clk142M] [get_bd_pins dilate_accel/ap_rst_n] [get_bd_pins erode_accel/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pr_0
proc create_hier_cell_pr_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_pr_0() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out1


  # Create pins
  create_bd_pin -dir I clk_142M
  create_bd_pin -dir I -type rst periph_resetn_clk142M

  # Create instance: dilate_accel, and set properties
  set dilate_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:dilate_accel:1.0 dilate_accel ]

  # Create instance: erode_accel, and set properties
  set erode_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:erode_accel:1.0 erode_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net dilate_accel_stream_out [get_bd_intf_pins stream_out0] [get_bd_intf_pins erode_accel/stream_out]
  connect_bd_intf_net -intf_net erode_accel_stream_out [get_bd_intf_pins stream_out1] [get_bd_intf_pins dilate_accel/stream_out]
  connect_bd_intf_net -intf_net s_axi_control0_1 [get_bd_intf_pins s_axi_control0] [get_bd_intf_pins erode_accel/s_axi_control]
  connect_bd_intf_net -intf_net s_axi_control1_1 [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins dilate_accel/s_axi_control]
  connect_bd_intf_net -intf_net stream_in0_1 [get_bd_intf_pins stream_in0] [get_bd_intf_pins erode_accel/stream_in]
  connect_bd_intf_net -intf_net stream_in1_1 [get_bd_intf_pins stream_in1] [get_bd_intf_pins dilate_accel/stream_in]

  # Create port connections
  connect_bd_net -net clk_142M_1 [get_bd_pins clk_142M] [get_bd_pins dilate_accel/ap_clk] [get_bd_pins erode_accel/ap_clk]
  connect_bd_net -net periph_resetn_clk142M_1 [get_bd_pins periph_resetn_clk142M] [get_bd_pins dilate_accel/ap_rst_n] [get_bd_pins erode_accel/ap_rst_n]

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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dfx_pr_0_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dfx_pr_0_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dfx_pr_1_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dfx_pr_1_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dfx_pr_fork

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dfx_pr_join

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_0_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_0_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_1_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_fork_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_fork_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_dfx_pr_join

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_0_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_0_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_1_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_fork

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_join_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_pr_join_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_pr_0_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_pr_0_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_pr_1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_pr_1_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_pr_fork

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_pr_join

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_0_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_0_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_1_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_1_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_fork

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_join_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_dfx_pr_join_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_0_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_0_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_1_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_1_1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_pr_join

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_pr_fork_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_pr_fork_1


  # Create pins
  create_bd_pin -dir I -type clk clk_142M
  create_bd_pin -dir I -from 8 -to 0 gpio_in
  create_bd_pin -dir O -from 8 -to 0 gpio_out
  create_bd_pin -dir I -type rst periph_resetn_clk142M

  # Create instance: dfx_decoupler_pr_0, and set properties
  set dfx_decoupler_pr_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_decoupler:1.0 dfx_decoupler_pr_0 ]
  set_property -dict [ list \
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} in_1 {ID 1 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24 MANAGEMENT manual} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_1 {ID 3 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite0 {ID 4 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}} axi_lite1 {ID 5 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 22} \
   CONFIG.GUI_INTERFACE_NAME {in_0} \
   CONFIG.GUI_INTERFACE_PROTOCOL {none} \
   CONFIG.GUI_SELECT_INTERFACE {0} \
   CONFIG.GUI_SELECT_MODE {slave} \
   CONFIG.GUI_SELECT_VLNV {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.GUI_SIGNAL_DECOUPLED_0 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_1 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_2 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_3 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_4 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_5 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_6 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_7 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_8 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_9 {false} \
   CONFIG.GUI_SIGNAL_MANAGEMENT_2 {auto} \
   CONFIG.GUI_SIGNAL_PRESENT_0 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_1 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_2 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_3 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_4 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_5 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_6 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_7 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_8 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_9 {false} \
   CONFIG.GUI_SIGNAL_SELECT_0 {TVALID} \
   CONFIG.GUI_SIGNAL_SELECT_1 {TREADY} \
   CONFIG.GUI_SIGNAL_SELECT_2 {TDATA} \
   CONFIG.GUI_SIGNAL_SELECT_3 {TUSER} \
   CONFIG.GUI_SIGNAL_SELECT_4 {TLAST} \
   CONFIG.GUI_SIGNAL_SELECT_5 {TID} \
   CONFIG.GUI_SIGNAL_SELECT_6 {TDEST} \
   CONFIG.GUI_SIGNAL_SELECT_7 {TSTRB} \
   CONFIG.GUI_SIGNAL_SELECT_8 {TKEEP} \
   CONFIG.GUI_SIGNAL_SELECT_9 {-1} \
   CONFIG.GUI_SIGNAL_WIDTH_2 {24} \
   CONFIG.GUI_SIGNAL_WIDTH_5 {0} \
   CONFIG.GUI_SIGNAL_WIDTH_6 {0} \
   CONFIG.GUI_SIGNAL_WIDTH_7 {3} \
   CONFIG.GUI_SIGNAL_WIDTH_8 {3} \
 ] $dfx_decoupler_pr_0

  # Create instance: dfx_decoupler_pr_1, and set properties
  set dfx_decoupler_pr_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_decoupler:1.0 dfx_decoupler_pr_1 ]
  set_property -dict [ list \
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} in_1 {ID 1 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_1 {ID 3 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite0 {ID 4 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}} axi_lite1 {ID 5 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 15} \
   CONFIG.GUI_INTERFACE_NAME {in_0} \
   CONFIG.GUI_INTERFACE_PROTOCOL {none} \
   CONFIG.GUI_SELECT_INTERFACE {0} \
   CONFIG.GUI_SELECT_MODE {slave} \
   CONFIG.GUI_SELECT_VLNV {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.GUI_SIGNAL_DECOUPLED_0 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_1 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_2 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_3 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_4 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_5 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_6 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_7 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_8 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_9 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_0 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_1 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_2 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_3 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_4 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_5 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_6 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_7 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_8 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_9 {false} \
   CONFIG.GUI_SIGNAL_SELECT_0 {TVALID} \
   CONFIG.GUI_SIGNAL_SELECT_1 {TREADY} \
   CONFIG.GUI_SIGNAL_SELECT_2 {TDATA} \
   CONFIG.GUI_SIGNAL_SELECT_3 {TUSER} \
   CONFIG.GUI_SIGNAL_SELECT_4 {TLAST} \
   CONFIG.GUI_SIGNAL_SELECT_5 {TID} \
   CONFIG.GUI_SIGNAL_SELECT_6 {TDEST} \
   CONFIG.GUI_SIGNAL_SELECT_7 {TSTRB} \
   CONFIG.GUI_SIGNAL_SELECT_8 {TKEEP} \
   CONFIG.GUI_SIGNAL_SELECT_9 {-1} \
   CONFIG.GUI_SIGNAL_WIDTH_2 {24} \
   CONFIG.GUI_SIGNAL_WIDTH_5 {0} \
   CONFIG.GUI_SIGNAL_WIDTH_6 {0} \
   CONFIG.GUI_SIGNAL_WIDTH_7 {3} \
   CONFIG.GUI_SIGNAL_WIDTH_8 {3} \
 ] $dfx_decoupler_pr_1

  # Create instance: dfx_decoupler_pr_fork, and set properties
  set dfx_decoupler_pr_fork [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_decoupler:1.0 dfx_decoupler_pr_fork ]
  set_property -dict [ list \
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 1 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_1 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite {ID 3 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 5} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 5} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 10} \
   CONFIG.GUI_INTERFACE_NAME {in_0} \
   CONFIG.GUI_INTERFACE_PROTOCOL {none} \
   CONFIG.GUI_SELECT_INTERFACE {0} \
   CONFIG.GUI_SELECT_MODE {slave} \
   CONFIG.GUI_SELECT_VLNV {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.GUI_SIGNAL_DECOUPLED_0 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_1 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_2 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_3 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_4 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_5 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_6 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_7 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_8 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_9 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_0 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_1 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_2 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_3 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_4 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_5 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_6 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_7 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_8 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_9 {false} \
   CONFIG.GUI_SIGNAL_SELECT_0 {TVALID} \
   CONFIG.GUI_SIGNAL_SELECT_1 {TREADY} \
   CONFIG.GUI_SIGNAL_SELECT_2 {TDATA} \
   CONFIG.GUI_SIGNAL_SELECT_3 {TUSER} \
   CONFIG.GUI_SIGNAL_SELECT_4 {TLAST} \
   CONFIG.GUI_SIGNAL_SELECT_5 {TID} \
   CONFIG.GUI_SIGNAL_SELECT_6 {TDEST} \
   CONFIG.GUI_SIGNAL_SELECT_7 {TSTRB} \
   CONFIG.GUI_SIGNAL_SELECT_8 {TKEEP} \
   CONFIG.GUI_SIGNAL_SELECT_9 {-1} \
   CONFIG.GUI_SIGNAL_WIDTH_2 {24} \
   CONFIG.GUI_SIGNAL_WIDTH_7 {3} \
   CONFIG.GUI_SIGNAL_WIDTH_8 {3} \
 ] $dfx_decoupler_pr_fork

  # Create instance: dfx_decoupler_pr_join, and set properties
  set dfx_decoupler_pr_join [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_decoupler:1.0 dfx_decoupler_pr_join ]
  set_property -dict [ list \
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} in_1 {ID 1 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite {ID 3 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 5} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 5} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 9} \
   CONFIG.GUI_INTERFACE_NAME {in_0} \
   CONFIG.GUI_INTERFACE_PROTOCOL {none} \
   CONFIG.GUI_SELECT_INTERFACE {0} \
   CONFIG.GUI_SELECT_MODE {slave} \
   CONFIG.GUI_SELECT_VLNV {xilinx.com:interface:axis_rtl:1.0} \
   CONFIG.GUI_SIGNAL_DECOUPLED_0 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_1 {true} \
   CONFIG.GUI_SIGNAL_DECOUPLED_2 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_3 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_4 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_5 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_6 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_7 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_8 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_9 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_0 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_1 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_2 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_3 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_4 {true} \
   CONFIG.GUI_SIGNAL_PRESENT_5 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_6 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_7 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_8 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_9 {false} \
   CONFIG.GUI_SIGNAL_SELECT_0 {TVALID} \
   CONFIG.GUI_SIGNAL_SELECT_1 {TREADY} \
   CONFIG.GUI_SIGNAL_SELECT_2 {TDATA} \
   CONFIG.GUI_SIGNAL_SELECT_3 {TUSER} \
   CONFIG.GUI_SIGNAL_SELECT_4 {TLAST} \
   CONFIG.GUI_SIGNAL_SELECT_5 {TID} \
   CONFIG.GUI_SIGNAL_SELECT_6 {TDEST} \
   CONFIG.GUI_SIGNAL_SELECT_7 {TSTRB} \
   CONFIG.GUI_SIGNAL_SELECT_8 {TKEEP} \
   CONFIG.GUI_SIGNAL_SELECT_9 {-1} \
   CONFIG.GUI_SIGNAL_WIDTH_2 {24} \
   CONFIG.GUI_SIGNAL_WIDTH_7 {3} \
   CONFIG.GUI_SIGNAL_WIDTH_8 {3} \
 ] $dfx_decoupler_pr_join

  # Create instance: logic_0, and set properties
  set logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $logic_0

  # Create instance: pr_0_in0, and set properties
  set pr_0_in0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_0_in0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_0_in0

  # Create instance: pr_0_in1, and set properties
  set pr_0_in1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_0_in1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_0_in1

  # Create instance: pr_0_out0, and set properties
  set pr_0_out0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_0_out0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_0_out0

  # Create instance: pr_0_out1, and set properties
  set pr_0_out1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_0_out1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_0_out1

  # Create instance: pr_1_in0, and set properties
  set pr_1_in0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_1_in0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_1_in0

  # Create instance: pr_1_in1, and set properties
  set pr_1_in1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_1_in1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_1_in1

  # Create instance: pr_1_out0, and set properties
  set pr_1_out0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_1_out0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_1_out0

  # Create instance: pr_1_out1, and set properties
  set pr_1_out1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_1_out1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_1_out1

  # Create instance: pr_fork_in0, and set properties
  set pr_fork_in0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_fork_in0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_fork_in0

  # Create instance: pr_fork_out0, and set properties
  set pr_fork_out0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_fork_out0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_fork_out0

  # Create instance: pr_fork_out1, and set properties
  set pr_fork_out1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_fork_out1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_fork_out1

  # Create instance: pr_join_fifo_in_0, and set properties
  set pr_join_fifo_in_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 pr_join_fifo_in_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16384} \
   CONFIG.FIFO_MEMORY_TYPE {block} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_join_fifo_in_0

  # Create instance: pr_join_fifo_in_1, and set properties
  set pr_join_fifo_in_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 pr_join_fifo_in_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16384} \
   CONFIG.FIFO_MEMORY_TYPE {block} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_join_fifo_in_1

  # Create instance: pr_join_in0, and set properties
  set pr_join_in0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_join_in0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_join_in0

  # Create instance: pr_join_in1, and set properties
  set pr_join_in1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_join_in1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_join_in1

  # Create instance: pr_join_out0, and set properties
  set pr_join_out0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 pr_join_out0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_join_out0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {9} \
 ] $xlconcat_0

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {9} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {9} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_1

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {9} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_2

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {9} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_3

  # Create interface connections
  connect_bd_intf_net -intf_net dfx_decoupler_0_rp_in_0 [get_bd_intf_pins dfx_decoupler_pr_0/rp_in_0] [get_bd_intf_pins pr_0_in0/S_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_0_rp_in_1 [get_bd_intf_pins dfx_decoupler_pr_0/rp_in_1] [get_bd_intf_pins pr_0_in1/S_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_0_s_out_0 [get_bd_intf_pins m_axis_dfx_pr_0_0] [get_bd_intf_pins dfx_decoupler_pr_0/s_out_0]
  connect_bd_intf_net -intf_net dfx_decoupler_0_s_out_1 [get_bd_intf_pins m_axis_dfx_pr_0_1] [get_bd_intf_pins dfx_decoupler_pr_0/s_out_1]
  connect_bd_intf_net -intf_net dfx_decoupler_1_rp_in_0 [get_bd_intf_pins dfx_decoupler_pr_1/rp_in_0] [get_bd_intf_pins pr_1_in0/S_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_1_rp_in_1 [get_bd_intf_pins dfx_decoupler_pr_1/rp_in_1] [get_bd_intf_pins pr_1_in1/S_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_1_s_out_0 [get_bd_intf_pins m_axis_dfx_pr_1_0] [get_bd_intf_pins dfx_decoupler_pr_1/s_out_0]
  connect_bd_intf_net -intf_net dfx_decoupler_1_s_out_1 [get_bd_intf_pins m_axis_dfx_pr_1_1] [get_bd_intf_pins dfx_decoupler_pr_1/s_out_1]
  connect_bd_intf_net -intf_net dfx_decoupler_2_rp_in_0 [get_bd_intf_pins dfx_decoupler_pr_join/rp_in_0] [get_bd_intf_pins pr_join_in0/S_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_2_rp_in_1 [get_bd_intf_pins dfx_decoupler_pr_join/rp_in_1] [get_bd_intf_pins pr_join_in1/S_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_2_s_axi_lite [get_bd_intf_pins s_axi_pr_join] [get_bd_intf_pins dfx_decoupler_pr_join/s_axi_lite]
  connect_bd_intf_net -intf_net dfx_decoupler_2_s_out_0 [get_bd_intf_pins m_axis_dfx_pr_join] [get_bd_intf_pins dfx_decoupler_pr_join/s_out_0]
  connect_bd_intf_net -intf_net dfx_decoupler_3_rp_in_0 [get_bd_intf_pins dfx_decoupler_pr_fork/rp_in_0] [get_bd_intf_pins pr_fork_in0/S_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_3_s_axi_lite [get_bd_intf_pins s_axi_pr_fork] [get_bd_intf_pins dfx_decoupler_pr_fork/s_axi_lite]
  connect_bd_intf_net -intf_net dfx_decoupler_3_s_out_0 [get_bd_intf_pins m_axis_dfx_pr_fork_0] [get_bd_intf_pins dfx_decoupler_pr_fork/s_out_0]
  connect_bd_intf_net -intf_net dfx_decoupler_3_s_out_1 [get_bd_intf_pins m_axis_dfx_pr_fork_1] [get_bd_intf_pins dfx_decoupler_pr_fork/s_out_1]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_0_s_axi_lite0 [get_bd_intf_pins s_axi_pr_0_0] [get_bd_intf_pins dfx_decoupler_pr_0/s_axi_lite0]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_0_s_axi_lite1 [get_bd_intf_pins s_axi_pr_0_1] [get_bd_intf_pins dfx_decoupler_pr_0/s_axi_lite1]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_1_s_axi_lite0 [get_bd_intf_pins s_axi_pr_1_0] [get_bd_intf_pins dfx_decoupler_pr_1/s_axi_lite0]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_1_s_axi_lite1 [get_bd_intf_pins s_axi_pr_1_1] [get_bd_intf_pins dfx_decoupler_pr_1/s_axi_lite1]
  connect_bd_intf_net -intf_net pr_0_in0_M_AXIS [get_bd_intf_pins m_axis_pr_0_0] [get_bd_intf_pins pr_0_in0/M_AXIS]
  connect_bd_intf_net -intf_net pr_0_in1_M_AXIS [get_bd_intf_pins m_axis_pr_0_1] [get_bd_intf_pins pr_0_in1/M_AXIS]
  connect_bd_intf_net -intf_net pr_0_out0_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_0/rp_out_0] [get_bd_intf_pins pr_0_out0/M_AXIS]
  connect_bd_intf_net -intf_net pr_0_out1_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_0/rp_out_1] [get_bd_intf_pins pr_0_out1/M_AXIS]
  connect_bd_intf_net -intf_net pr_0_stream_out0 [get_bd_intf_pins s_axis_pr_0_0] [get_bd_intf_pins pr_0_out0/S_AXIS]
  connect_bd_intf_net -intf_net pr_0_stream_out1 [get_bd_intf_pins s_axis_pr_0_1] [get_bd_intf_pins pr_0_out1/S_AXIS]
  connect_bd_intf_net -intf_net pr_1_in0_M_AXIS [get_bd_intf_pins m_axis_pr_1_0] [get_bd_intf_pins pr_1_in0/M_AXIS]
  connect_bd_intf_net -intf_net pr_1_in1_M_AXIS [get_bd_intf_pins m_axis_pr_1_1] [get_bd_intf_pins pr_1_in1/M_AXIS]
  connect_bd_intf_net -intf_net pr_1_out0_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_1/rp_out_0] [get_bd_intf_pins pr_1_out0/M_AXIS]
  connect_bd_intf_net -intf_net pr_1_out1_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_1/rp_out_1] [get_bd_intf_pins pr_1_out1/M_AXIS]
  connect_bd_intf_net -intf_net pr_1_stream_out0 [get_bd_intf_pins s_axis_pr_1_0] [get_bd_intf_pins pr_1_out0/S_AXIS]
  connect_bd_intf_net -intf_net pr_1_stream_out1 [get_bd_intf_pins s_axis_pr_1_1] [get_bd_intf_pins pr_1_out1/S_AXIS]
  connect_bd_intf_net -intf_net pr_decoupler_in_regs_M_AXIS [get_bd_intf_pins m_axis_pr_join_0] [get_bd_intf_pins pr_join_in0/M_AXIS]
  connect_bd_intf_net -intf_net pr_decoupler_in_regs_M_AXIS6 [get_bd_intf_pins m_axis_pr_join_1] [get_bd_intf_pins pr_join_in1/M_AXIS]
  connect_bd_intf_net -intf_net pr_fork_in0_M_AXIS [get_bd_intf_pins m_axis_pr_fork] [get_bd_intf_pins pr_fork_in0/M_AXIS]
  connect_bd_intf_net -intf_net pr_fork_out0_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_fork/rp_out_0] [get_bd_intf_pins pr_fork_out0/M_AXIS]
  connect_bd_intf_net -intf_net pr_fork_out1_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_fork/rp_out_1] [get_bd_intf_pins pr_fork_out1/M_AXIS]
  connect_bd_intf_net -intf_net pr_fork_stream_out0 [get_bd_intf_pins s_pr_fork_0] [get_bd_intf_pins pr_fork_out0/S_AXIS]
  connect_bd_intf_net -intf_net pr_fork_stream_out1 [get_bd_intf_pins s_pr_fork_1] [get_bd_intf_pins pr_fork_out1/S_AXIS]
  connect_bd_intf_net -intf_net pr_join_fifo_in_0_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_join/s_in_0] [get_bd_intf_pins pr_join_fifo_in_0/M_AXIS]
  connect_bd_intf_net -intf_net pr_join_fifo_in_1_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_join/s_in_1] [get_bd_intf_pins pr_join_fifo_in_1/M_AXIS]
  connect_bd_intf_net -intf_net pr_join_out0_M_AXIS [get_bd_intf_pins dfx_decoupler_pr_join/rp_out_0] [get_bd_intf_pins pr_join_out0/M_AXIS]
  connect_bd_intf_net -intf_net pr_join_stream_out [get_bd_intf_pins s_axis_pr_join] [get_bd_intf_pins pr_join_out0/S_AXIS]
  connect_bd_intf_net -intf_net s_in_5_1 [get_bd_intf_pins s_axis_dfx_pr_join_0] [get_bd_intf_pins pr_join_fifo_in_0/S_AXIS]
  connect_bd_intf_net -intf_net s_in_6_1 [get_bd_intf_pins s_axis_dfx_pr_join_1] [get_bd_intf_pins pr_join_fifo_in_1/S_AXIS]
  connect_bd_intf_net -intf_net video_M12_AXIS [get_bd_intf_pins s_axis_dfx_pr_0_0] [get_bd_intf_pins dfx_decoupler_pr_0/s_in_0]
  connect_bd_intf_net -intf_net video_M13_AXIS [get_bd_intf_pins s_axis_dfx_pr_0_1] [get_bd_intf_pins dfx_decoupler_pr_0/s_in_1]
  connect_bd_intf_net -intf_net video_M13_AXIS1 [get_bd_intf_pins s_axis_dfx_pr_fork] [get_bd_intf_pins dfx_decoupler_pr_fork/s_in_0]
  connect_bd_intf_net -intf_net video_M14_AXIS [get_bd_intf_pins s_axis_dfx_pr_1_0] [get_bd_intf_pins dfx_decoupler_pr_1/s_in_0]
  connect_bd_intf_net -intf_net video_M15_AXIS [get_bd_intf_pins s_axis_dfx_pr_1_1] [get_bd_intf_pins dfx_decoupler_pr_1/s_in_1]
  connect_bd_intf_net -intf_net video_M16_AXI [get_bd_intf_pins m_axi_dfx_pr_0_0] [get_bd_intf_pins dfx_decoupler_pr_0/rp_axi_lite0]
  connect_bd_intf_net -intf_net video_M17_AXI [get_bd_intf_pins m_axi_dfx_pr_1_0] [get_bd_intf_pins dfx_decoupler_pr_1/rp_axi_lite0]
  connect_bd_intf_net -intf_net video_M18_AXI [get_bd_intf_pins m_axi_dfx_pr_join] [get_bd_intf_pins dfx_decoupler_pr_join/rp_axi_lite]
  connect_bd_intf_net -intf_net video_M19_AXI [get_bd_intf_pins m_axi_dfx_pr_fork] [get_bd_intf_pins dfx_decoupler_pr_fork/rp_axi_lite]
  connect_bd_intf_net -intf_net video_M21_AXI [get_bd_intf_pins m_axi_dfx_pr_0_1] [get_bd_intf_pins dfx_decoupler_pr_0/rp_axi_lite1]
  connect_bd_intf_net -intf_net video_M22_AXI [get_bd_intf_pins m_axi_dfx_pr_1_1] [get_bd_intf_pins dfx_decoupler_pr_1/rp_axi_lite1]

  # Create port connections
  connect_bd_net -net dfx_decoupler_0_decouple_status [get_bd_pins dfx_decoupler_pr_0/decouple_status] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net dfx_decoupler_1_decouple_status [get_bd_pins dfx_decoupler_pr_1/decouple_status] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net dfx_decoupler_2_decouple_status [get_bd_pins dfx_decoupler_pr_join/decouple_status] [get_bd_pins xlconcat_0/In5]
  connect_bd_net -net dfx_decoupler_3_decouple_status [get_bd_pins dfx_decoupler_pr_fork/decouple_status] [get_bd_pins xlconcat_0/In7]
  connect_bd_net -net logic_0_dout [get_bd_pins logic_0/dout] [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconcat_0/In2] [get_bd_pins xlconcat_0/In4] [get_bd_pins xlconcat_0/In6] [get_bd_pins xlconcat_0/In8]
  connect_bd_net -net ps7_0_FCLK_CLK1 [get_bd_pins clk_142M] [get_bd_pins pr_0_in0/aclk] [get_bd_pins pr_0_in1/aclk] [get_bd_pins pr_0_out0/aclk] [get_bd_pins pr_0_out1/aclk] [get_bd_pins pr_1_in0/aclk] [get_bd_pins pr_1_in1/aclk] [get_bd_pins pr_1_out0/aclk] [get_bd_pins pr_1_out1/aclk] [get_bd_pins pr_fork_in0/aclk] [get_bd_pins pr_fork_out0/aclk] [get_bd_pins pr_fork_out1/aclk] [get_bd_pins pr_join_fifo_in_0/s_axis_aclk] [get_bd_pins pr_join_fifo_in_1/s_axis_aclk] [get_bd_pins pr_join_in0/aclk] [get_bd_pins pr_join_in1/aclk] [get_bd_pins pr_join_out0/aclk]
  connect_bd_net -net ps7_0_GPIO_O [get_bd_pins gpio_in] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din]
  connect_bd_net -net peripheral_aresetn [get_bd_pins periph_resetn_clk142M] [get_bd_pins pr_0_in0/aresetn] [get_bd_pins pr_0_in1/aresetn] [get_bd_pins pr_0_out0/aresetn] [get_bd_pins pr_0_out1/aresetn] [get_bd_pins pr_1_in0/aresetn] [get_bd_pins pr_1_in1/aresetn] [get_bd_pins pr_1_out0/aresetn] [get_bd_pins pr_1_out1/aresetn] [get_bd_pins pr_fork_in0/aresetn] [get_bd_pins pr_fork_out0/aresetn] [get_bd_pins pr_fork_out1/aresetn] [get_bd_pins pr_join_fifo_in_0/s_axis_aresetn] [get_bd_pins pr_join_fifo_in_1/s_axis_aresetn] [get_bd_pins pr_join_in0/aresetn] [get_bd_pins pr_join_in1/aresetn] [get_bd_pins pr_join_out0/aresetn]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins gpio_out] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins dfx_decoupler_pr_0/decouple] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins dfx_decoupler_pr_1/decouple] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins dfx_decoupler_pr_join/decouple] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins dfx_decoupler_pr_fork/decouple] [get_bd_pins xlslice_3/Dout]

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
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]

  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

  set btns_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 btns_4bits ]

  set hdmi_in [ create_bd_intf_port -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 hdmi_in ]

  set hdmi_in_ddc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 hdmi_in_ddc ]

  set hdmi_tx_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:hdmi_rtl:2.0 hdmi_tx_0 ]

  set leds_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 leds_4bits ]

  set sws_2bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 sws_2bits ]


  # Create ports
  set hdmi_in_hpd [ create_bd_port -dir O -from 0 -to 0 hdmi_in_hpd ]
  set hdmi_out_hpd [ create_bd_port -dir O -from 0 -to 0 hdmi_out_hpd ]

  # Create instance: btns_gpio, and set properties
  set btns_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 btns_gpio ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
   CONFIG.C_INTERRUPT_PRESENT {1} \
 ] $btns_gpio

  # Create instance: dfx_decouplers
  create_hier_cell_dfx_decouplers [current_bd_instance .] dfx_decouplers

  # Create instance: leds_gpio, and set properties
  set leds_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 leds_gpio ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
   CONFIG.C_INTERRUPT_PRESENT {1} \
   CONFIG.C_IS_DUAL {0} \
 ] $leds_gpio

  # Create instance: pr_0
  create_hier_cell_pr_0 [current_bd_instance .] pr_0

  # Create instance: pr_1
  create_hier_cell_pr_1 [current_bd_instance .] pr_1

  # Create instance: pr_fork
  create_hier_cell_pr_fork [current_bd_instance .] pr_fork

  # Create instance: pr_join
  create_hier_cell_pr_join [current_bd_instance .] pr_join

  # Create instance: ps7_0, and set properties
  set ps7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7_0 ]
  set_property -dict [ list \
   CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {650.000000} \
   CONFIG.PCW_ACT_CAN0_PERIPHERAL_FREQMHZ {23.8095} \
   CONFIG.PCW_ACT_CAN1_PERIPHERAL_FREQMHZ {23.8095} \
   CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.096154} \
   CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
   CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {142.857132} \
   CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_I2C_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {50.000000} \
   CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_ACT_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
   CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {650} \
   CONFIG.PCW_ARMPLL_CTRL_FBDIV {26} \
   CONFIG.PCW_CAN0_BASEADDR {0xE0008000} \
   CONFIG.PCW_CAN0_CAN0_IO {<Select>} \
   CONFIG.PCW_CAN0_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN0_GRP_CLK_IO {<Select>} \
   CONFIG.PCW_CAN0_HIGHADDR {0xE0008FFF} \
   CONFIG.PCW_CAN0_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN0_PERIPHERAL_FREQMHZ {-1} \
   CONFIG.PCW_CAN1_BASEADDR {0xE0009000} \
   CONFIG.PCW_CAN1_CAN1_IO {<Select>} \
   CONFIG.PCW_CAN1_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN1_GRP_CLK_IO {<Select>} \
   CONFIG.PCW_CAN1_HIGHADDR {0xE0009FFF} \
   CONFIG.PCW_CAN1_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN1_PERIPHERAL_FREQMHZ {-1} \
   CONFIG.PCW_CAN_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_CAN_PERIPHERAL_VALID {0} \
   CONFIG.PCW_CLK0_FREQ {100000000} \
   CONFIG.PCW_CLK1_FREQ {142857132} \
   CONFIG.PCW_CLK2_FREQ {200000000} \
   CONFIG.PCW_CLK3_FREQ {10000000} \
   CONFIG.PCW_CORE0_FIQ_INTR {0} \
   CONFIG.PCW_CORE0_IRQ_INTR {0} \
   CONFIG.PCW_CORE1_FIQ_INTR {0} \
   CONFIG.PCW_CORE1_IRQ_INTR {0} \
   CONFIG.PCW_CPU_CPU_6X4X_MAX_RANGE {667} \
   CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1300.000} \
   CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
   CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_DCI_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {52} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {2} \
   CONFIG.PCW_DCI_PERIPHERAL_FREQMHZ {10.159} \
   CONFIG.PCW_DDRPLL_CTRL_FBDIV {21} \
   CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1050.000} \
   CONFIG.PCW_DDR_HPRLPR_QUEUE_PARTITION {HPR(0)/LPR(32)} \
   CONFIG.PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL {15} \
   CONFIG.PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DDR_PORT0_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT1_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT2_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT3_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PRIORITY_READPORT_0 {<Select>} \
   CONFIG.PCW_DDR_PRIORITY_READPORT_1 {<Select>} \
   CONFIG.PCW_DDR_PRIORITY_READPORT_2 {<Select>} \
   CONFIG.PCW_DDR_PRIORITY_READPORT_3 {<Select>} \
   CONFIG.PCW_DDR_PRIORITY_WRITEPORT_0 {<Select>} \
   CONFIG.PCW_DDR_PRIORITY_WRITEPORT_1 {<Select>} \
   CONFIG.PCW_DDR_PRIORITY_WRITEPORT_2 {<Select>} \
   CONFIG.PCW_DDR_PRIORITY_WRITEPORT_3 {<Select>} \
   CONFIG.PCW_DDR_RAM_BASEADDR {0x00100000} \
   CONFIG.PCW_DDR_RAM_HIGHADDR {0x1FFFFFFF} \
   CONFIG.PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_DM_WIDTH {4} \
   CONFIG.PCW_DQS_WIDTH {4} \
   CONFIG.PCW_DQ_WIDTH {32} \
   CONFIG.PCW_ENET0_BASEADDR {0xE000B000} \
   CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
   CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
   CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
   CONFIG.PCW_ENET0_HIGHADDR {0xE000BFFF} \
   CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET0_RESET_ENABLE {0} \
   CONFIG.PCW_ENET0_RESET_IO {<Select>} \
   CONFIG.PCW_ENET1_BASEADDR {0xE000C000} \
   CONFIG.PCW_ENET1_ENET1_IO {<Select>} \
   CONFIG.PCW_ENET1_GRP_MDIO_ENABLE {0} \
   CONFIG.PCW_ENET1_GRP_MDIO_IO {<Select>} \
   CONFIG.PCW_ENET1_HIGHADDR {0xE000CFFF} \
   CONFIG.PCW_ENET1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_ENET1_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET1_RESET_ENABLE {0} \
   CONFIG.PCW_ENET1_RESET_IO {<Select>} \
   CONFIG.PCW_ENET_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_POLARITY {Active Low} \
   CONFIG.PCW_ENET_RESET_SELECT {<Select>} \
   CONFIG.PCW_EN_4K_TIMER {0} \
   CONFIG.PCW_EN_CAN0 {0} \
   CONFIG.PCW_EN_CAN1 {0} \
   CONFIG.PCW_EN_CLK0_PORT {1} \
   CONFIG.PCW_EN_CLK1_PORT {1} \
   CONFIG.PCW_EN_CLK2_PORT {1} \
   CONFIG.PCW_EN_CLK3_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG0_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG1_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG2_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG3_PORT {0} \
   CONFIG.PCW_EN_DDR {1} \
   CONFIG.PCW_EN_EMIO_CAN0 {0} \
   CONFIG.PCW_EN_EMIO_CAN1 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_ENET0 {0} \
   CONFIG.PCW_EN_EMIO_ENET1 {0} \
   CONFIG.PCW_EN_EMIO_GPIO {1} \
   CONFIG.PCW_EN_EMIO_I2C0 {0} \
   CONFIG.PCW_EN_EMIO_I2C1 {0} \
   CONFIG.PCW_EN_EMIO_MODEM_UART0 {0} \
   CONFIG.PCW_EN_EMIO_MODEM_UART1 {0} \
   CONFIG.PCW_EN_EMIO_PJTAG {0} \
   CONFIG.PCW_EN_EMIO_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_SPI0 {0} \
   CONFIG.PCW_EN_EMIO_SPI1 {0} \
   CONFIG.PCW_EN_EMIO_SRAM_INT {0} \
   CONFIG.PCW_EN_EMIO_TRACE {0} \
   CONFIG.PCW_EN_EMIO_TTC0 {0} \
   CONFIG.PCW_EN_EMIO_TTC1 {0} \
   CONFIG.PCW_EN_EMIO_UART0 {0} \
   CONFIG.PCW_EN_EMIO_UART1 {0} \
   CONFIG.PCW_EN_EMIO_WDT {0} \
   CONFIG.PCW_EN_EMIO_WP_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_WP_SDIO1 {0} \
   CONFIG.PCW_EN_ENET0 {1} \
   CONFIG.PCW_EN_ENET1 {0} \
   CONFIG.PCW_EN_GPIO {0} \
   CONFIG.PCW_EN_I2C0 {1} \
   CONFIG.PCW_EN_I2C1 {0} \
   CONFIG.PCW_EN_MODEM_UART0 {0} \
   CONFIG.PCW_EN_MODEM_UART1 {0} \
   CONFIG.PCW_EN_PJTAG {0} \
   CONFIG.PCW_EN_PTP_ENET0 {0} \
   CONFIG.PCW_EN_PTP_ENET1 {0} \
   CONFIG.PCW_EN_QSPI {1} \
   CONFIG.PCW_EN_RST0_PORT {1} \
   CONFIG.PCW_EN_RST1_PORT {0} \
   CONFIG.PCW_EN_RST2_PORT {0} \
   CONFIG.PCW_EN_RST3_PORT {0} \
   CONFIG.PCW_EN_SDIO0 {1} \
   CONFIG.PCW_EN_SDIO1 {0} \
   CONFIG.PCW_EN_SMC {0} \
   CONFIG.PCW_EN_SPI0 {0} \
   CONFIG.PCW_EN_SPI1 {0} \
   CONFIG.PCW_EN_TRACE {0} \
   CONFIG.PCW_EN_TTC0 {0} \
   CONFIG.PCW_EN_TTC1 {0} \
   CONFIG.PCW_EN_UART0 {1} \
   CONFIG.PCW_EN_UART1 {0} \
   CONFIG.PCW_EN_USB0 {1} \
   CONFIG.PCW_EN_USB1 {0} \
   CONFIG.PCW_EN_WDT {0} \
   CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {2} \
   CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {7} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK_CLK0_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK1_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK2_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK3_BUF {FALSE} \
   CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {142} \
   CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK2_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
   CONFIG.PCW_FTM_CTI_IN0 {<Select>} \
   CONFIG.PCW_FTM_CTI_IN1 {<Select>} \
   CONFIG.PCW_FTM_CTI_IN2 {<Select>} \
   CONFIG.PCW_FTM_CTI_IN3 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT0 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT1 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT2 {<Select>} \
   CONFIG.PCW_FTM_CTI_OUT3 {<Select>} \
   CONFIG.PCW_GPIO_BASEADDR {0xE000A000} \
   CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
   CONFIG.PCW_GPIO_EMIO_GPIO_IO {9} \
   CONFIG.PCW_GPIO_EMIO_GPIO_WIDTH {8} \
   CONFIG.PCW_GPIO_HIGHADDR {0xE000AFFF} \
   CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {0} \
   CONFIG.PCW_GPIO_MIO_GPIO_IO {<Select>} \
   CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C0_BASEADDR {0xE0004000} \
   CONFIG.PCW_I2C0_GRP_INT_ENABLE {1} \
   CONFIG.PCW_I2C0_GRP_INT_IO {EMIO} \
   CONFIG.PCW_I2C0_HIGHADDR {0xE0004FFF} \
   CONFIG.PCW_I2C0_I2C0_IO {MIO 50 .. 51} \
   CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_I2C0_RESET_ENABLE {0} \
   CONFIG.PCW_I2C0_RESET_IO {<Select>} \
   CONFIG.PCW_I2C1_BASEADDR {0xE0005000} \
   CONFIG.PCW_I2C1_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C1_GRP_INT_IO {<Select>} \
   CONFIG.PCW_I2C1_HIGHADDR {0xE0005FFF} \
   CONFIG.PCW_I2C1_I2C1_IO {<Select>} \
   CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C1_RESET_ENABLE {0} \
   CONFIG.PCW_I2C1_RESET_IO {<Select>} \
   CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {108.333336} \
   CONFIG.PCW_I2C_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_RESET_POLARITY {Active Low} \
   CONFIG.PCW_I2C_RESET_SELECT {<Select>} \
   CONFIG.PCW_IMPORT_BOARD_PRESET {None} \
   CONFIG.PCW_INCLUDE_ACP_TRANS_CHECK {0} \
   CONFIG.PCW_INCLUDE_TRACE_BUFFER {0} \
   CONFIG.PCW_IOPLL_CTRL_FBDIV {20} \
   CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
   CONFIG.PCW_IRQ_F2P_INTR {1} \
   CONFIG.PCW_IRQ_F2P_MODE {DIRECT} \
   CONFIG.PCW_MIO_0_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_0_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_0_PULLUP {<Select>} \
   CONFIG.PCW_MIO_0_SLEW {<Select>} \
   CONFIG.PCW_MIO_10_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_10_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_10_PULLUP {<Select>} \
   CONFIG.PCW_MIO_10_SLEW {<Select>} \
   CONFIG.PCW_MIO_11_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_11_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_11_PULLUP {<Select>} \
   CONFIG.PCW_MIO_11_SLEW {<Select>} \
   CONFIG.PCW_MIO_12_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_12_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_12_PULLUP {<Select>} \
   CONFIG.PCW_MIO_12_SLEW {<Select>} \
   CONFIG.PCW_MIO_13_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_13_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_13_PULLUP {<Select>} \
   CONFIG.PCW_MIO_13_SLEW {<Select>} \
   CONFIG.PCW_MIO_14_DIRECTION {in} \
   CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_14_PULLUP {enabled} \
   CONFIG.PCW_MIO_14_SLEW {slow} \
   CONFIG.PCW_MIO_15_DIRECTION {out} \
   CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_15_PULLUP {enabled} \
   CONFIG.PCW_MIO_15_SLEW {slow} \
   CONFIG.PCW_MIO_16_DIRECTION {out} \
   CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_16_PULLUP {enabled} \
   CONFIG.PCW_MIO_16_SLEW {slow} \
   CONFIG.PCW_MIO_17_DIRECTION {out} \
   CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_17_PULLUP {enabled} \
   CONFIG.PCW_MIO_17_SLEW {slow} \
   CONFIG.PCW_MIO_18_DIRECTION {out} \
   CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_18_PULLUP {enabled} \
   CONFIG.PCW_MIO_18_SLEW {slow} \
   CONFIG.PCW_MIO_19_DIRECTION {out} \
   CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_19_PULLUP {enabled} \
   CONFIG.PCW_MIO_19_SLEW {slow} \
   CONFIG.PCW_MIO_1_DIRECTION {out} \
   CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_1_PULLUP {enabled} \
   CONFIG.PCW_MIO_1_SLEW {slow} \
   CONFIG.PCW_MIO_20_DIRECTION {out} \
   CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_20_PULLUP {enabled} \
   CONFIG.PCW_MIO_20_SLEW {slow} \
   CONFIG.PCW_MIO_21_DIRECTION {out} \
   CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_21_PULLUP {enabled} \
   CONFIG.PCW_MIO_21_SLEW {slow} \
   CONFIG.PCW_MIO_22_DIRECTION {in} \
   CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_22_PULLUP {enabled} \
   CONFIG.PCW_MIO_22_SLEW {slow} \
   CONFIG.PCW_MIO_23_DIRECTION {in} \
   CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_23_PULLUP {enabled} \
   CONFIG.PCW_MIO_23_SLEW {slow} \
   CONFIG.PCW_MIO_24_DIRECTION {in} \
   CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_24_PULLUP {enabled} \
   CONFIG.PCW_MIO_24_SLEW {slow} \
   CONFIG.PCW_MIO_25_DIRECTION {in} \
   CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_25_PULLUP {enabled} \
   CONFIG.PCW_MIO_25_SLEW {slow} \
   CONFIG.PCW_MIO_26_DIRECTION {in} \
   CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_26_PULLUP {enabled} \
   CONFIG.PCW_MIO_26_SLEW {slow} \
   CONFIG.PCW_MIO_27_DIRECTION {in} \
   CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_27_PULLUP {enabled} \
   CONFIG.PCW_MIO_27_SLEW {slow} \
   CONFIG.PCW_MIO_28_DIRECTION {inout} \
   CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_28_PULLUP {enabled} \
   CONFIG.PCW_MIO_28_SLEW {slow} \
   CONFIG.PCW_MIO_29_DIRECTION {in} \
   CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_29_PULLUP {enabled} \
   CONFIG.PCW_MIO_29_SLEW {slow} \
   CONFIG.PCW_MIO_2_DIRECTION {inout} \
   CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_2_PULLUP {disabled} \
   CONFIG.PCW_MIO_2_SLEW {slow} \
   CONFIG.PCW_MIO_30_DIRECTION {out} \
   CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_30_PULLUP {enabled} \
   CONFIG.PCW_MIO_30_SLEW {slow} \
   CONFIG.PCW_MIO_31_DIRECTION {in} \
   CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_31_PULLUP {enabled} \
   CONFIG.PCW_MIO_31_SLEW {slow} \
   CONFIG.PCW_MIO_32_DIRECTION {inout} \
   CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_32_PULLUP {enabled} \
   CONFIG.PCW_MIO_32_SLEW {slow} \
   CONFIG.PCW_MIO_33_DIRECTION {inout} \
   CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_33_PULLUP {enabled} \
   CONFIG.PCW_MIO_33_SLEW {slow} \
   CONFIG.PCW_MIO_34_DIRECTION {inout} \
   CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_34_PULLUP {enabled} \
   CONFIG.PCW_MIO_34_SLEW {slow} \
   CONFIG.PCW_MIO_35_DIRECTION {inout} \
   CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_35_PULLUP {enabled} \
   CONFIG.PCW_MIO_35_SLEW {slow} \
   CONFIG.PCW_MIO_36_DIRECTION {in} \
   CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_36_PULLUP {enabled} \
   CONFIG.PCW_MIO_36_SLEW {slow} \
   CONFIG.PCW_MIO_37_DIRECTION {inout} \
   CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_37_PULLUP {enabled} \
   CONFIG.PCW_MIO_37_SLEW {slow} \
   CONFIG.PCW_MIO_38_DIRECTION {inout} \
   CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_38_PULLUP {enabled} \
   CONFIG.PCW_MIO_38_SLEW {slow} \
   CONFIG.PCW_MIO_39_DIRECTION {inout} \
   CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_39_PULLUP {enabled} \
   CONFIG.PCW_MIO_39_SLEW {slow} \
   CONFIG.PCW_MIO_3_DIRECTION {inout} \
   CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_3_PULLUP {disabled} \
   CONFIG.PCW_MIO_3_SLEW {slow} \
   CONFIG.PCW_MIO_40_DIRECTION {inout} \
   CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_40_PULLUP {enabled} \
   CONFIG.PCW_MIO_40_SLEW {slow} \
   CONFIG.PCW_MIO_41_DIRECTION {inout} \
   CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_41_PULLUP {enabled} \
   CONFIG.PCW_MIO_41_SLEW {slow} \
   CONFIG.PCW_MIO_42_DIRECTION {inout} \
   CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_42_PULLUP {enabled} \
   CONFIG.PCW_MIO_42_SLEW {slow} \
   CONFIG.PCW_MIO_43_DIRECTION {inout} \
   CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_43_PULLUP {enabled} \
   CONFIG.PCW_MIO_43_SLEW {slow} \
   CONFIG.PCW_MIO_44_DIRECTION {inout} \
   CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_44_PULLUP {enabled} \
   CONFIG.PCW_MIO_44_SLEW {slow} \
   CONFIG.PCW_MIO_45_DIRECTION {inout} \
   CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_45_PULLUP {enabled} \
   CONFIG.PCW_MIO_45_SLEW {slow} \
   CONFIG.PCW_MIO_46_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_46_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_46_PULLUP {<Select>} \
   CONFIG.PCW_MIO_46_SLEW {<Select>} \
   CONFIG.PCW_MIO_47_DIRECTION {in} \
   CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_47_PULLUP {enabled} \
   CONFIG.PCW_MIO_47_SLEW {slow} \
   CONFIG.PCW_MIO_48_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_48_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_48_PULLUP {<Select>} \
   CONFIG.PCW_MIO_48_SLEW {<Select>} \
   CONFIG.PCW_MIO_49_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_49_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_49_PULLUP {<Select>} \
   CONFIG.PCW_MIO_49_SLEW {<Select>} \
   CONFIG.PCW_MIO_4_DIRECTION {inout} \
   CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_4_PULLUP {disabled} \
   CONFIG.PCW_MIO_4_SLEW {slow} \
   CONFIG.PCW_MIO_50_DIRECTION {inout} \
   CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_50_PULLUP {enabled} \
   CONFIG.PCW_MIO_50_SLEW {slow} \
   CONFIG.PCW_MIO_51_DIRECTION {inout} \
   CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_51_PULLUP {enabled} \
   CONFIG.PCW_MIO_51_SLEW {slow} \
   CONFIG.PCW_MIO_52_DIRECTION {out} \
   CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_52_PULLUP {enabled} \
   CONFIG.PCW_MIO_52_SLEW {slow} \
   CONFIG.PCW_MIO_53_DIRECTION {inout} \
   CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_53_PULLUP {enabled} \
   CONFIG.PCW_MIO_53_SLEW {slow} \
   CONFIG.PCW_MIO_5_DIRECTION {inout} \
   CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_5_PULLUP {disabled} \
   CONFIG.PCW_MIO_5_SLEW {slow} \
   CONFIG.PCW_MIO_6_DIRECTION {out} \
   CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_6_PULLUP {disabled} \
   CONFIG.PCW_MIO_6_SLEW {slow} \
   CONFIG.PCW_MIO_7_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_7_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_7_PULLUP {<Select>} \
   CONFIG.PCW_MIO_7_SLEW {<Select>} \
   CONFIG.PCW_MIO_8_DIRECTION {out} \
   CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_8_PULLUP {disabled} \
   CONFIG.PCW_MIO_8_SLEW {slow} \
   CONFIG.PCW_MIO_9_DIRECTION {<Select>} \
   CONFIG.PCW_MIO_9_IOTYPE {<Select>} \
   CONFIG.PCW_MIO_9_PULLUP {<Select>} \
   CONFIG.PCW_MIO_9_SLEW {<Select>} \
   CONFIG.PCW_MIO_PRIMITIVE {54} \
   CONFIG.PCW_MIO_TREE_PERIPHERALS { \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#Enet 0 \
     0#I2C 0#Enet \
     0#SD 0#SD \
     0#SD 0#SD \
     0#SD 0#SD \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     0#USB 0#USB \
     0#unassigned#SD 0#unassigned#unassigned#I2C \
     Flash#Quad SPI \
     Flash#Quad SPI \
     Flash#Quad SPI \
     Flash#Quad SPI \
     Flash#Quad SPI \
     Flash#unassigned#Quad SPI \
     Flash#unassigned#unassigned#unassigned#unassigned#unassigned#UART 0#UART \
     unassigned#Quad SPI \
   } \
   CONFIG.PCW_MIO_TREE_SIGNALS {unassigned#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]/HOLD_B#qspi0_sclk#unassigned#qspi_fbclk#unassigned#unassigned#unassigned#unassigned#unassigned#rx#tx#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#unassigned#cd#unassigned#unassigned#scl#sda#mdc#mdio} \
   CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
   CONFIG.PCW_M_AXI_GP0_ID_WIDTH {12} \
   CONFIG.PCW_M_AXI_GP0_SUPPORT_NARROW_BURST {0} \
   CONFIG.PCW_M_AXI_GP0_THREAD_ID_WIDTH {12} \
   CONFIG.PCW_M_AXI_GP1_ENABLE_STATIC_REMAP {0} \
   CONFIG.PCW_M_AXI_GP1_ID_WIDTH {12} \
   CONFIG.PCW_M_AXI_GP1_SUPPORT_NARROW_BURST {0} \
   CONFIG.PCW_M_AXI_GP1_THREAD_ID_WIDTH {12} \
   CONFIG.PCW_NAND_CYCLES_T_AR {1} \
   CONFIG.PCW_NAND_CYCLES_T_CLR {1} \
   CONFIG.PCW_NAND_CYCLES_T_RC {11} \
   CONFIG.PCW_NAND_CYCLES_T_REA {1} \
   CONFIG.PCW_NAND_CYCLES_T_RR {1} \
   CONFIG.PCW_NAND_CYCLES_T_WC {11} \
   CONFIG.PCW_NAND_CYCLES_T_WP {1} \
   CONFIG.PCW_NAND_GRP_D8_ENABLE {0} \
   CONFIG.PCW_NAND_GRP_D8_IO {<Select>} \
   CONFIG.PCW_NAND_NAND_IO {<Select>} \
   CONFIG.PCW_NAND_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_CS0_T_PC {1} \
   CONFIG.PCW_NOR_CS0_T_RC {11} \
   CONFIG.PCW_NOR_CS0_T_TR {1} \
   CONFIG.PCW_NOR_CS0_T_WC {11} \
   CONFIG.PCW_NOR_CS0_T_WP {1} \
   CONFIG.PCW_NOR_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_CS1_T_PC {1} \
   CONFIG.PCW_NOR_CS1_T_RC {11} \
   CONFIG.PCW_NOR_CS1_T_TR {1} \
   CONFIG.PCW_NOR_CS1_T_WC {11} \
   CONFIG.PCW_NOR_CS1_T_WP {1} \
   CONFIG.PCW_NOR_CS1_WE_TIME {0} \
   CONFIG.PCW_NOR_GRP_A25_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_A25_IO {<Select>} \
   CONFIG.PCW_NOR_GRP_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS0_IO {<Select>} \
   CONFIG.PCW_NOR_GRP_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS1_IO {<Select>} \
   CONFIG.PCW_NOR_GRP_SRAM_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS0_IO {<Select>} \
   CONFIG.PCW_NOR_GRP_SRAM_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS1_IO {<Select>} \
   CONFIG.PCW_NOR_GRP_SRAM_INT_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_INT_IO {<Select>} \
   CONFIG.PCW_NOR_NOR_IO {<Select>} \
   CONFIG.PCW_NOR_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_SRAM_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_SRAM_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS1_WE_TIME {0} \
   CONFIG.PCW_OVERRIDE_BASIC_CLOCK {0} \
   CONFIG.PCW_P2F_CAN0_INTR {0} \
   CONFIG.PCW_P2F_CAN1_INTR {0} \
   CONFIG.PCW_P2F_CTI_INTR {0} \
   CONFIG.PCW_P2F_DMAC0_INTR {0} \
   CONFIG.PCW_P2F_DMAC1_INTR {0} \
   CONFIG.PCW_P2F_DMAC2_INTR {0} \
   CONFIG.PCW_P2F_DMAC3_INTR {0} \
   CONFIG.PCW_P2F_DMAC4_INTR {0} \
   CONFIG.PCW_P2F_DMAC5_INTR {0} \
   CONFIG.PCW_P2F_DMAC6_INTR {0} \
   CONFIG.PCW_P2F_DMAC7_INTR {0} \
   CONFIG.PCW_P2F_DMAC_ABORT_INTR {0} \
   CONFIG.PCW_P2F_ENET0_INTR {0} \
   CONFIG.PCW_P2F_ENET1_INTR {0} \
   CONFIG.PCW_P2F_GPIO_INTR {0} \
   CONFIG.PCW_P2F_I2C0_INTR {0} \
   CONFIG.PCW_P2F_I2C1_INTR {0} \
   CONFIG.PCW_P2F_QSPI_INTR {0} \
   CONFIG.PCW_P2F_SDIO0_INTR {0} \
   CONFIG.PCW_P2F_SDIO1_INTR {0} \
   CONFIG.PCW_P2F_SMC_INTR {0} \
   CONFIG.PCW_P2F_SPI0_INTR {0} \
   CONFIG.PCW_P2F_SPI1_INTR {0} \
   CONFIG.PCW_P2F_UART0_INTR {0} \
   CONFIG.PCW_P2F_UART1_INTR {0} \
   CONFIG.PCW_P2F_USB0_INTR {0} \
   CONFIG.PCW_P2F_USB1_INTR {0} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY0 {0.223} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY1 {0.212} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY2 {0.085} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY3 {0.092} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 {0.040} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 {0.058} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 {-0.009} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 {-0.033} \
   CONFIG.PCW_PACKAGE_NAME {clg400} \
   CONFIG.PCW_PCAP_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_PCAP_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_PERIPHERAL_BOARD_PRESET {None} \
   CONFIG.PCW_PJTAG_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_PJTAG_PJTAG_IO {<Select>} \
   CONFIG.PCW_PLL_BYPASSMODE_ENABLE {0} \
   CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
   CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
   CONFIG.PCW_PS7_SI_REV {PRODUCTION} \
   CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
   CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_IO1_IO {<Select>} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
   CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_SS1_IO {<Select>} \
   CONFIG.PCW_QSPI_INTERNAL_HIGHADDRESS {0xFCFFFFFF} \
   CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
   CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
   CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} \
   CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_POW_IO {<Select>} \
   CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_WP_IO {<Select>} \
   CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
   CONFIG.PCW_SD1_GRP_CD_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_CD_IO {<Select>} \
   CONFIG.PCW_SD1_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_POW_IO {<Select>} \
   CONFIG.PCW_SD1_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_WP_IO {<Select>} \
   CONFIG.PCW_SD1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SD1_SD1_IO {<Select>} \
   CONFIG.PCW_SDIO0_BASEADDR {0xE0100000} \
   CONFIG.PCW_SDIO0_HIGHADDR {0xE0100FFF} \
   CONFIG.PCW_SDIO1_BASEADDR {0xE0101000} \
   CONFIG.PCW_SDIO1_HIGHADDR {0xE0101FFF} \
   CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {20} \
   CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
   CONFIG.PCW_SINGLE_QSPI_DATA_MODE {x4} \
   CONFIG.PCW_SMC_CYCLE_T0 {NA} \
   CONFIG.PCW_SMC_CYCLE_T1 {NA} \
   CONFIG.PCW_SMC_CYCLE_T2 {NA} \
   CONFIG.PCW_SMC_CYCLE_T3 {NA} \
   CONFIG.PCW_SMC_CYCLE_T4 {NA} \
   CONFIG.PCW_SMC_CYCLE_T5 {NA} \
   CONFIG.PCW_SMC_CYCLE_T6 {NA} \
   CONFIG.PCW_SMC_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SMC_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_SMC_PERIPHERAL_VALID {0} \
   CONFIG.PCW_SPI0_BASEADDR {0xE0006000} \
   CONFIG.PCW_SPI0_GRP_SS0_ENABLE {0} \
   CONFIG.PCW_SPI0_GRP_SS0_IO {<Select>} \
   CONFIG.PCW_SPI0_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_SPI0_GRP_SS1_IO {<Select>} \
   CONFIG.PCW_SPI0_GRP_SS2_ENABLE {0} \
   CONFIG.PCW_SPI0_GRP_SS2_IO {<Select>} \
   CONFIG.PCW_SPI0_HIGHADDR {0xE0006FFF} \
   CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SPI0_SPI0_IO {<Select>} \
   CONFIG.PCW_SPI1_BASEADDR {0xE0007000} \
   CONFIG.PCW_SPI1_GRP_SS0_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS0_IO {<Select>} \
   CONFIG.PCW_SPI1_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS1_IO {<Select>} \
   CONFIG.PCW_SPI1_GRP_SS2_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS2_IO {<Select>} \
   CONFIG.PCW_SPI1_HIGHADDR {0xE0007FFF} \
   CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SPI1_SPI1_IO {<Select>} \
   CONFIG.PCW_SPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SPI_PERIPHERAL_FREQMHZ {166.666666} \
   CONFIG.PCW_SPI_PERIPHERAL_VALID {0} \
   CONFIG.PCW_S_AXI_ACP_ARUSER_VAL {31} \
   CONFIG.PCW_S_AXI_ACP_AWUSER_VAL {31} \
   CONFIG.PCW_S_AXI_ACP_ID_WIDTH {3} \
   CONFIG.PCW_S_AXI_GP0_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_GP1_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP0_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP1_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP1_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP2_ID_WIDTH {6} \
   CONFIG.PCW_S_AXI_HP3_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP3_ID_WIDTH {6} \
   CONFIG.PCW_TPIU_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TPIU_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_TRACE_BUFFER_CLOCK_DELAY {12} \
   CONFIG.PCW_TRACE_BUFFER_FIFO_SIZE {128} \
   CONFIG.PCW_TRACE_GRP_16BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_16BIT_IO {<Select>} \
   CONFIG.PCW_TRACE_GRP_2BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_2BIT_IO {<Select>} \
   CONFIG.PCW_TRACE_GRP_32BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_32BIT_IO {<Select>} \
   CONFIG.PCW_TRACE_GRP_4BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_4BIT_IO {<Select>} \
   CONFIG.PCW_TRACE_GRP_8BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_8BIT_IO {<Select>} \
   CONFIG.PCW_TRACE_INTERNAL_WIDTH {2} \
   CONFIG.PCW_TRACE_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TRACE_PIPELINE_WIDTH {8} \
   CONFIG.PCW_TRACE_TRACE_IO {<Select>} \
   CONFIG.PCW_TTC0_BASEADDR {0xE0104000} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_HIGHADDR {0xE0104fff} \
   CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TTC0_TTC0_IO {<Select>} \
   CONFIG.PCW_TTC1_BASEADDR {0xE0105000} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_HIGHADDR {0xE0105fff} \
   CONFIG.PCW_TTC1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TTC1_TTC1_IO {<Select>} \
   CONFIG.PCW_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_UART0_BASEADDR {0xE0000000} \
   CONFIG.PCW_UART0_BAUD_RATE {115200} \
   CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART0_GRP_FULL_IO {<Select>} \
   CONFIG.PCW_UART0_HIGHADDR {0xE0000FFF} \
   CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
   CONFIG.PCW_UART1_BASEADDR {0xE0001000} \
   CONFIG.PCW_UART1_BAUD_RATE {115200} \
   CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART1_GRP_FULL_IO {<Select>} \
   CONFIG.PCW_UART1_HIGHADDR {0xE0001FFF} \
   CONFIG.PCW_UART1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_UART1_UART1_IO {<Select>} \
   CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {10} \
   CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
   CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {525.000000} \
   CONFIG.PCW_UIPARAM_DDR_ADV_ENABLE {0} \
   CONFIG.PCW_UIPARAM_DDR_AL {0} \
   CONFIG.PCW_UIPARAM_DDR_BANK_ADDR_COUNT {3} \
   CONFIG.PCW_UIPARAM_DDR_BL {8} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.223} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.212} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.085} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.092} \
   CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {16 Bit} \
   CONFIG.PCW_UIPARAM_DDR_CL {7} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {25.8} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH {80.4535} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {25.8} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH {80.4535} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH {80.4535} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH {80.4535} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_STOP_EN {0} \
   CONFIG.PCW_UIPARAM_DDR_COL_ADDR_COUNT {10} \
   CONFIG.PCW_UIPARAM_DDR_CWL {6} \
   CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {15.6} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH {105.056} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {18.8} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH {66.904} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH {89.1715} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH {113.63} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.040} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.058} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {16.5} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH {98.503} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {18} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH {68.5855} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH {90.295} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH {103.977} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
   CONFIG.PCW_UIPARAM_DDR_ECC {Disabled} \
   CONFIG.PCW_UIPARAM_DDR_ENABLE {1} \
   CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {525} \
   CONFIG.PCW_UIPARAM_DDR_HIGH_TEMP {Normal (0-85)} \
   CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
   CONFIG.PCW_UIPARAM_DDR_PARTNO {Custom} \
   CONFIG.PCW_UIPARAM_DDR_ROW_ADDR_COUNT {15} \
   CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
   CONFIG.PCW_UIPARAM_DDR_T_FAW {40.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RC {50.625} \
   CONFIG.PCW_UIPARAM_DDR_T_RCD {13.125} \
   CONFIG.PCW_UIPARAM_DDR_T_RP {13.125} \
   CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {0} \
   CONFIG.PCW_UIPARAM_GENERATE_SUMMARY {NA} \
   CONFIG.PCW_USB0_BASEADDR {0xE0102000} \
   CONFIG.PCW_USB0_HIGHADDR {0xE0102fff} \
   CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB0_RESET_ENABLE {0} \
   CONFIG.PCW_USB0_RESET_IO {<Select>} \
   CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
   CONFIG.PCW_USB1_BASEADDR {0xE0103000} \
   CONFIG.PCW_USB1_HIGHADDR {0xE0103fff} \
   CONFIG.PCW_USB1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB1_RESET_ENABLE {0} \
   CONFIG.PCW_USB1_RESET_IO {<Select>} \
   CONFIG.PCW_USB1_USB1_IO {<Select>} \
   CONFIG.PCW_USB_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_POLARITY {Active Low} \
   CONFIG.PCW_USB_RESET_SELECT {<Select>} \
   CONFIG.PCW_USE_AXI_FABRIC_IDLE {0} \
   CONFIG.PCW_USE_AXI_NONSECURE {0} \
   CONFIG.PCW_USE_CORESIGHT {0} \
   CONFIG.PCW_USE_CROSS_TRIGGER {0} \
   CONFIG.PCW_USE_CR_FABRIC {1} \
   CONFIG.PCW_USE_DDR_BYPASS {0} \
   CONFIG.PCW_USE_DEBUG {0} \
   CONFIG.PCW_USE_DEFAULT_ACP_USER_VAL {0} \
   CONFIG.PCW_USE_DMA0 {0} \
   CONFIG.PCW_USE_DMA1 {0} \
   CONFIG.PCW_USE_DMA2 {0} \
   CONFIG.PCW_USE_DMA3 {0} \
   CONFIG.PCW_USE_EXPANDED_IOP {0} \
   CONFIG.PCW_USE_EXPANDED_PS_SLCR_REGISTERS {0} \
   CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
   CONFIG.PCW_USE_HIGH_OCM {0} \
   CONFIG.PCW_USE_M_AXI_GP0 {1} \
   CONFIG.PCW_USE_M_AXI_GP1 {0} \
   CONFIG.PCW_USE_PROC_EVENT_BUS {0} \
   CONFIG.PCW_USE_PS_SLCR_REGISTERS {0} \
   CONFIG.PCW_USE_S_AXI_ACP {0} \
   CONFIG.PCW_USE_S_AXI_GP0 {0} \
   CONFIG.PCW_USE_S_AXI_GP1 {0} \
   CONFIG.PCW_USE_S_AXI_HP0 {1} \
   CONFIG.PCW_USE_S_AXI_HP1 {0} \
   CONFIG.PCW_USE_S_AXI_HP2 {0} \
   CONFIG.PCW_USE_S_AXI_HP3 {0} \
   CONFIG.PCW_USE_TRACE {0} \
   CONFIG.PCW_USE_TRACE_DATA_EDGE_DETECTOR {0} \
   CONFIG.PCW_VALUE_SILVERSION {3} \
   CONFIG.PCW_WDT_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_WDT_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_WDT_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_WDT_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_WDT_WDT_IO {<Select>} \
 ] $ps7_0

  # Create instance: switches_gpio, and set properties
  set switches_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 switches_gpio ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_ALL_OUTPUTS_2 {0} \
   CONFIG.C_GPIO2_WIDTH {32} \
   CONFIG.C_GPIO_WIDTH {2} \
   CONFIG.C_INTERRUPT_PRESENT {1} \
   CONFIG.C_IS_DUAL {0} \
 ] $switches_gpio

  # Create instance: video
  create_hier_cell_video [current_bd_instance .] video

  # Create interface connections
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins ps7_0/S_AXI_HP0] [get_bd_intf_pins video/M_AXI]
  connect_bd_intf_net -intf_net btns_gpio_GPIO [get_bd_intf_ports btns_4bits] [get_bd_intf_pins btns_gpio/GPIO]
  connect_bd_intf_net -intf_net dfx_decoupler_0_s_out_0 [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_0_0] [get_bd_intf_pins video/S06_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_0_s_out_1 [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_0_1] [get_bd_intf_pins video/S07_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_1_s_out_0 [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_1_0] [get_bd_intf_pins video/S08_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_1_s_out_1 [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_1_1] [get_bd_intf_pins video/S09_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_2_s_axi_lite [get_bd_intf_pins dfx_decouplers/s_axi_pr_join] [get_bd_intf_pins pr_join/s_axi_control]
  connect_bd_intf_net -intf_net dfx_decoupler_2_s_out_0 [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_join] [get_bd_intf_pins video/S10_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_3_s_axi_lite [get_bd_intf_pins dfx_decouplers/s_axi_pr_fork] [get_bd_intf_pins pr_fork/s_axi_control]
  connect_bd_intf_net -intf_net dfx_decoupler_3_s_out_0 [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_fork_0] [get_bd_intf_pins video/S11_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_3_s_out_1 [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_fork_1] [get_bd_intf_pins video/S12_AXIS]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_0_s_axi_lite0 [get_bd_intf_pins dfx_decouplers/s_axi_pr_0_0] [get_bd_intf_pins pr_0/s_axi_control0]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_0_s_axi_lite1 [get_bd_intf_pins dfx_decouplers/s_axi_pr_0_1] [get_bd_intf_pins pr_0/s_axi_control1]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_1_s_axi_lite0 [get_bd_intf_pins dfx_decouplers/s_axi_pr_1_0] [get_bd_intf_pins pr_1/s_axi_control0]
  connect_bd_intf_net -intf_net dfx_decoupler_pr_1_s_axi_lite1 [get_bd_intf_pins dfx_decouplers/s_axi_pr_1_1] [get_bd_intf_pins pr_1/s_axi_control1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_join_0 [get_bd_intf_pins dfx_decouplers/m_axis_pr_join_0] [get_bd_intf_pins pr_join/stream_in0]
  connect_bd_intf_net -intf_net dvi2rgb_0_DDC [get_bd_intf_ports hdmi_in_ddc] [get_bd_intf_pins video/DDC]
  connect_bd_intf_net -intf_net hdmi_in_1 [get_bd_intf_ports hdmi_in] [get_bd_intf_pins video/TMDS_in]
  connect_bd_intf_net -intf_net leds_gpio_GPIO [get_bd_intf_ports leds_4bits] [get_bd_intf_pins leds_gpio/GPIO]
  connect_bd_intf_net -intf_net pr_0_in0_M_AXIS [get_bd_intf_pins dfx_decouplers/m_axis_pr_0_0] [get_bd_intf_pins pr_0/stream_in0]
  connect_bd_intf_net -intf_net pr_0_in1_M_AXIS [get_bd_intf_pins dfx_decouplers/m_axis_pr_0_1] [get_bd_intf_pins pr_0/stream_in1]
  connect_bd_intf_net -intf_net pr_0_stream_out0 [get_bd_intf_pins dfx_decouplers/s_axis_pr_0_0] [get_bd_intf_pins pr_0/stream_out0]
  connect_bd_intf_net -intf_net pr_0_stream_out1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_0_1] [get_bd_intf_pins pr_0/stream_out1]
  connect_bd_intf_net -intf_net pr_1_in0_M_AXIS [get_bd_intf_pins dfx_decouplers/m_axis_pr_1_0] [get_bd_intf_pins pr_1/stream_in0]
  connect_bd_intf_net -intf_net pr_1_in1_M_AXIS [get_bd_intf_pins dfx_decouplers/m_axis_pr_1_1] [get_bd_intf_pins pr_1/stream_in1]
  connect_bd_intf_net -intf_net pr_1_stream_out0 [get_bd_intf_pins dfx_decouplers/s_axis_pr_1_0] [get_bd_intf_pins pr_1/stream_out0]
  connect_bd_intf_net -intf_net pr_1_stream_out1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_1_1] [get_bd_intf_pins pr_1/stream_out1]
  connect_bd_intf_net -intf_net pr_fork_in0_M_AXIS [get_bd_intf_pins dfx_decouplers/m_axis_pr_fork] [get_bd_intf_pins pr_fork/stream_in0]
  connect_bd_intf_net -intf_net pr_fork_stream_out0 [get_bd_intf_pins dfx_decouplers/s_pr_fork_0] [get_bd_intf_pins pr_fork/stream_out0]
  connect_bd_intf_net -intf_net pr_fork_stream_out1 [get_bd_intf_pins dfx_decouplers/s_pr_fork_1] [get_bd_intf_pins pr_fork/stream_out1]
  connect_bd_intf_net -intf_net pr_join_stream_out [get_bd_intf_pins dfx_decouplers/s_axis_pr_join] [get_bd_intf_pins pr_join/stream_out]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins ps7_0/FIXED_IO]
  connect_bd_intf_net -intf_net ps7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins ps7_0/DDR]
  connect_bd_intf_net -intf_net ps7_0_M_AXI_GP0 [get_bd_intf_pins ps7_0/M_AXI_GP0] [get_bd_intf_pins video/S_AXI]
  connect_bd_intf_net -intf_net stream_in1_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_join_1] [get_bd_intf_pins pr_join/stream_in1]
  connect_bd_intf_net -intf_net switches_gpio_GPIO [get_bd_intf_ports sws_2bits] [get_bd_intf_pins switches_gpio/GPIO]
  connect_bd_intf_net -intf_net video_M11_AXIS [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_join_0] [get_bd_intf_pins video/M10_AXIS]
  connect_bd_intf_net -intf_net video_M12_AXIS [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_0_0] [get_bd_intf_pins video/M06_AXIS]
  connect_bd_intf_net -intf_net video_M12_AXIS1 [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_join_1] [get_bd_intf_pins video/M11_AXIS]
  connect_bd_intf_net -intf_net video_M13_AXIS [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_0_1] [get_bd_intf_pins video/M07_AXIS]
  connect_bd_intf_net -intf_net video_M13_AXIS1 [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_fork] [get_bd_intf_pins video/M12_AXIS]
  connect_bd_intf_net -intf_net video_M14_AXIS [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_1_0] [get_bd_intf_pins video/M08_AXIS]
  connect_bd_intf_net -intf_net video_M15_AXIS [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_1_1] [get_bd_intf_pins video/M09_AXIS]
  connect_bd_intf_net -intf_net video_M16_AXI [get_bd_intf_pins dfx_decouplers/m_axi_dfx_pr_0_0] [get_bd_intf_pins video/M16_AXI]
  connect_bd_intf_net -intf_net video_M17_AXI [get_bd_intf_pins dfx_decouplers/m_axi_dfx_pr_1_0] [get_bd_intf_pins video/M17_AXI]
  connect_bd_intf_net -intf_net video_M18_AXI [get_bd_intf_pins dfx_decouplers/m_axi_dfx_pr_join] [get_bd_intf_pins video/M18_AXI]
  connect_bd_intf_net -intf_net video_M19_AXI [get_bd_intf_pins dfx_decouplers/m_axi_dfx_pr_fork] [get_bd_intf_pins video/M19_AXI]
  connect_bd_intf_net -intf_net video_M21_AXI [get_bd_intf_pins dfx_decouplers/m_axi_dfx_pr_0_1] [get_bd_intf_pins video/M21_AXI]
  connect_bd_intf_net -intf_net video_M22_AXI [get_bd_intf_pins dfx_decouplers/m_axi_dfx_pr_1_1] [get_bd_intf_pins video/M22_AXI]
  connect_bd_intf_net -intf_net video_M26_AXI [get_bd_intf_pins switches_gpio/S_AXI] [get_bd_intf_pins video/M26_AXI]
  connect_bd_intf_net -intf_net video_M24_AXI [get_bd_intf_pins btns_gpio/S_AXI] [get_bd_intf_pins video/M24_AXI]
  connect_bd_intf_net -intf_net video_M25_AXI [get_bd_intf_pins leds_gpio/S_AXI] [get_bd_intf_pins video/M25_AXI]
  connect_bd_intf_net -intf_net video_hdmi_tx_0 [get_bd_intf_ports hdmi_tx_0] [get_bd_intf_pins video/hdmi_tx_0]

  # Create port connections
  connect_bd_net -net axi_gpio_video_gpio_io_o [get_bd_ports hdmi_in_hpd] [get_bd_pins video/hdmi_in_hpd]
  connect_bd_net -net btns_gpio_ip2intc_irpt [get_bd_pins btns_gpio/ip2intc_irpt] [get_bd_pins video/btns_int]
  connect_bd_net -net hdmi_out_hpd_video_gpio_io_o [get_bd_ports hdmi_out_hpd] [get_bd_pins video/hdmi_out_hpd]
  connect_bd_net -net leds_gpio_ip2intc_irpt [get_bd_pins leds_gpio/ip2intc_irpt] [get_bd_pins video/leds_int]
  connect_bd_net -net ps7_0_FCLK_CLK0 [get_bd_pins btns_gpio/s_axi_aclk] [get_bd_pins leds_gpio/s_axi_aclk] [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins ps7_0/M_AXI_GP0_ACLK] [get_bd_pins switches_gpio/s_axi_aclk] [get_bd_pins video/clk_100M]
  connect_bd_net -net ps7_0_FCLK_CLK1 [get_bd_pins dfx_decouplers/clk_142M] [get_bd_pins pr_0/clk_142M] [get_bd_pins pr_1/clk_142M] [get_bd_pins pr_fork/clk_142M] [get_bd_pins pr_join/clk_142M] [get_bd_pins ps7_0/FCLK_CLK1] [get_bd_pins ps7_0/S_AXI_HP0_ACLK] [get_bd_pins video/clk_142M]
  connect_bd_net -net ps7_0_FCLK_CLK2 [get_bd_pins ps7_0/FCLK_CLK2] [get_bd_pins video/clk_200M]
  connect_bd_net -net ps7_0_FCLK_RESET0_N [get_bd_pins ps7_0/FCLK_RESET0_N] [get_bd_pins video/FCLK_RESET0_N]
  connect_bd_net -net ps7_0_GPIO_O [get_bd_pins dfx_decouplers/gpio_in] [get_bd_pins video/gpio_in] [get_bd_pins ps7_0/GPIO_O]
  connect_bd_net -net switches_gpio_ip2intc_irpt [get_bd_pins switches_gpio/ip2intc_irpt] [get_bd_pins video/switches_int]
  connect_bd_net -net video_dout [get_bd_pins ps7_0/IRQ_F2P] [get_bd_pins video/dout]
  connect_bd_net -net video_peripheral_aresetn1 [get_bd_pins btns_gpio/s_axi_aresetn] [get_bd_pins leds_gpio/s_axi_aresetn] [get_bd_pins switches_gpio/s_axi_aresetn] [get_bd_pins video/periph_resetn_clk100M]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins dfx_decouplers/gpio_out] [get_bd_pins ps7_0/GPIO_I]
  connect_bd_net -net user_soft_reset_peripheral_aresetn [get_bd_pins dfx_decouplers/periph_resetn_clk142M] [get_bd_pins pr_0/periph_resetn_clk142M] [get_bd_pins pr_1/periph_resetn_clk142M] [get_bd_pins pr_fork/periph_resetn_clk142M] [get_bd_pins pr_join/periph_resetn_clk142M] [get_bd_pins video/soft_rst_n]

  # Create address segments
  assign_bd_address -offset 0x43C50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_out/frontend/axi_dynclk/s00_axi/reg0] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_in/frontend/axi_gpio_hdmiin/S_AXI/Reg] -force
  assign_bd_address -offset 0x43000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/axi_vdma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x43C00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/composable/axis_switch/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x41220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs btns_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x43C10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_in/color_convert/s_axi_control/Reg] -force
  assign_bd_address -offset 0x43C40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_out/color_convert/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40088000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs pr_0/dilate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40090000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs pr_1/dilate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x400A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs pr_fork/duplicate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40080000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs pr_0/erode_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40098000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs pr_1/erode_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/composable/filter2d_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/composable/gray2rgb_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x41210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_out/frontend/hdmi_out_hpd_video/S_AXI/Reg] -force
  assign_bd_address -offset 0x41230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs leds_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/composable/lut_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40050000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/composable/colorthresholding_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x43C30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_in/pixel_pack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x43C70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_out/pixel_unpack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/composable/rgb2gray_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/composable/rgb2hsv_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x400B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs pr_join/subtract_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x41240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs switches_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x41800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/system_interrupts/S_AXI/Reg] -force
  assign_bd_address -offset 0x43C20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_in/frontend/vtc_in/ctrl/Reg] -force
  assign_bd_address -offset 0x43C60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps7_0/Data] [get_bd_addr_segs video/hdmi_out/frontend/vtc_out/ctrl/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S] [get_bd_addr_segs ps7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM] [get_bd_addr_segs ps7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx.com:xd:${overlay_name}:1.0} [get_files [current_bd_design].bd]
  set_property PFM.AXI_PORT {  S_AXI_ACP {memport "S_AXI_ACP"}  S_AXI_HP1 {memport "S_AXI_HP"}  S_AXI_HP3 {memport "S_AXI_HP"}  } [get_bd_cells /ps7_0]
  set_property PFM.CLOCK {  FCLK_CLK0 {id "0" is_default "true"  proc_sys_reset "rst_ps7_0_fclk0" status "fixed"}  FCLK_CLK1 {id "1" is_default "false"  proc_sys_reset "rst_ps7_0_fclk1" status "fixed"}  FCLK_CLK3 {id "3" is_default "false"  proc_sys_reset "rst_ps7_0_fclk3" status "fixed"}  } [get_bd_cells /ps7_0]
  set_property PFM.IRQ {In1 {} In2 {} In3 {} In4 {} In5 {} In6 {} In7 {} In8 {} In9 {} In10 {} In11 {} In12 {} In13 {} In14 {} In15 {}} [get_bd_cells /video/xlconcat_1]


  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

set_property PR_FLOW 1 [current_project]

# PR_0 partition
set pr_0_dilate_erode "pr_0_dilate_erode"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /pr_0] $pr_0_dilate_erode
set new_pd [create_partition_def -name pr_0 -module $pr_0_dilate_erode]
create_reconfig_module -name $pr_0_dilate_erode -partition_def $new_pd -define_from $pr_0_dilate_erode
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd pr_0_temp]
replace_bd_cell  [get_bd_cells /pr_0] $new_pdcell
delete_bd_objs  [get_bd_cells /pr_0]
set_property name pr_0 $new_pdcell
## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_0_dilate_erode]
delete_bd_objs [get_bd_ports clk_142M]
create_bd_port -dir I -type clk -freq_hz 142857132 clk_142M
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins erode_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control0:s_axi_control1:stream_in0:stream_in1:stream_out0:stream_out1} [get_bd_ports /clk_142M]
assign_bd_address -target_address_space /s_axi_control1 -offset 0x00000000 -range 32K  [get_bd_addr_segs dilate_accel/s_axi_control/Reg] -force
assign_bd_address -target_address_space /s_axi_control0 -offset 0x00000000 -range 32K  [get_bd_addr_segs erode_accel/s_axi_control/Reg] -force

validate_bd_design
save_bd_design

# reconfigurable module
set pr_0_fast_fifo "pr_0_fast_fifo"
create_bd_design -boundary_from [get_files $pr_0_dilate_erode.bd] $pr_0_fast_fifo
create_reconfig_module -name $pr_0_fast_fifo -partition_def pr_0 -define_from $pr_0_fast_fifo
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:fast_accel:1.0 fast_accel
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0
endgroup

set_property -dict [list \
  CONFIG.TDATA_NUM_BYTES {3} \
  CONFIG.TUSER_WIDTH {1} \
  CONFIG.FIFO_DEPTH {4096} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.FIFO_MEMORY_TYPE {block} \
] [get_bd_cells axis_data_fifo_0]

connect_bd_intf_net [get_bd_intf_ports s_axi_control0] [get_bd_intf_pins fast_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins fast_accel/stream_in]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins fast_accel/ap_clk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins fast_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins fast_accel/stream_out]

connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]

assign_bd_address -offset 0x0000 -range 32K [get_bd_addr_segs {fast_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_0_filter2d_fifo "pr_0_filter2d_fifo"
create_bd_design -boundary_from [get_files $pr_0_dilate_erode.bd] $pr_0_filter2d_fifo
create_reconfig_module -name $pr_0_filter2d_fifo -partition_def pr_0 -define_from $pr_0_filter2d_fifo
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:filter2d_accel:1.0 filter2d_accel
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_1
endgroup

set_property -dict [list \
  CONFIG.TDATA_NUM_BYTES {3} \
  CONFIG.TUSER_WIDTH {1} \
  CONFIG.FIFO_DEPTH {4096} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.FIFO_MEMORY_TYPE {block} \
] [get_bd_cells axis_data_fifo_1]

connect_bd_intf_net [get_bd_intf_ports s_axi_control0] [get_bd_intf_pins filter2d_accel/s_axi_control]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins filter2d_accel/ap_clk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins filter2d_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins filter2d_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins filter2d_accel/stream_out]

connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins axis_data_fifo_1/s_axis_aresetn]

assign_bd_address -offset 0x0000 -range 32K [get_bd_addr_segs {filter2d_accel/s_axi_control/Reg}] 

validate_bd_design
save_bd_design

# PR 1 partition
set pr_1_dilate_erode "pr_1_dilate_erode"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /pr_1] $pr_1_dilate_erode
set new_pd [create_partition_def -name pr_1 -module $pr_1_dilate_erode]
create_reconfig_module -name $pr_1_dilate_erode -partition_def $new_pd -define_from $pr_1_dilate_erode
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd pr_1_temp]
replace_bd_cell  [get_bd_cells /pr_1] $new_pdcell
delete_bd_objs  [get_bd_cells /pr_1]
set_property name pr_1 $new_pdcell

## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_1_dilate_erode]
delete_bd_objs [get_bd_ports clk_142M]
create_bd_port -dir I -type clk -freq_hz 142857132 clk_142M
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins erode_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control0:s_axi_control1:stream_in0:stream_in1:stream_out0:stream_out1} [get_bd_ports /clk_142M]
assign_bd_address -target_address_space /s_axi_control0 -offset 0x00000000 -range 32K  [get_bd_addr_segs dilate_accel/s_axi_control/Reg] -force
assign_bd_address -target_address_space /s_axi_control1 -offset 0x00000000 -range 32K  [get_bd_addr_segs erode_accel/s_axi_control/Reg] -force

validate_bd_design
save_bd_design

# reconfigurable module
set pr_1_cornerharris "pr_1_cornerharris_fifo"
create_bd_design -boundary_from [get_files $pr_1_dilate_erode.bd] $pr_1_cornerharris
create_reconfig_module -name $pr_1_cornerharris -partition_def pr_1 -define_from $pr_1_cornerharris
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:cornerHarris_accel:1.0 cornerHarris_accel
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0
endgroup

set_property -dict [list \
  CONFIG.TDATA_NUM_BYTES {3} \
  CONFIG.TUSER_WIDTH {1} \
  CONFIG.FIFO_DEPTH {4096} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.FIFO_MEMORY_TYPE {block} \
] [get_bd_cells axis_data_fifo_0]

connect_bd_intf_net [get_bd_intf_ports s_axi_control0] [get_bd_intf_pins cornerHarris_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins cornerHarris_accel/stream_in]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins cornerHarris_accel/ap_clk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins cornerHarris_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins cornerHarris_accel/stream_out]

connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]

assign_bd_address -offset 0x0000 -range 32K [get_bd_addr_segs {cornerHarris_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design


# pr_join partition
set pr_join_subtract "pr_join_subtract"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /pr_join] $pr_join_subtract
set new_pd [create_partition_def -name pr_join -module $pr_join_subtract]
create_reconfig_module -name $pr_join_subtract -partition_def $new_pd -define_from $pr_join_subtract
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd pr_join_temp]
replace_bd_cell  [get_bd_cells /pr_join] $new_pdcell
delete_bd_objs  [get_bd_cells /pr_join]
set_property name pr_join $new_pdcell
## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_join_subtract]
delete_bd_objs [get_bd_ports clk_142M]
create_bd_port -dir I -type clk -freq_hz 142857132 clk_142M
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins subtract_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control:stream_in0:stream_in1:stream_out} [get_bd_ports /clk_142M]

assign_bd_address -offset 0x00000000 -range 64K [get_bd_addr_segs {s_axi_control/*_Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_join_absdiff "pr_join_absdiff"
create_bd_design -boundary_from [get_files $pr_join_subtract.bd] $pr_join_absdiff
create_reconfig_module -name $pr_join_absdiff -partition_def pr_join -define_from $pr_join_absdiff
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:absdiff_accel:1.0 absdiff_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins absdiff_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins absdiff_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins absdiff_accel/stream_in1]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins absdiff_accel/ap_clk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins absdiff_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out] [get_bd_intf_pins absdiff_accel/stream_out]

assign_bd_address -offset 0x0000 -range 64K [get_bd_addr_segs {absdiff_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_join_add "pr_join_add"
create_bd_design -boundary_from [get_files $pr_join_subtract.bd] $pr_join_add
create_reconfig_module -name $pr_join_add -partition_def pr_join -define_from $pr_join_add
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:add_accel:1.0 add_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins add_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins add_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins add_accel/stream_in1]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins add_accel/ap_clk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins add_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out] [get_bd_intf_pins add_accel/stream_out]

assign_bd_address -offset 0x0000 -range 64K [get_bd_addr_segs {add_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_join_bitand "pr_join_bitand"
create_bd_design -boundary_from [get_files $pr_join_subtract.bd] $pr_join_bitand
create_reconfig_module -name $pr_join_bitand -partition_def pr_join -define_from $pr_join_bitand
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:bitwise_and_accel:1.0 bitwise_and_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins bitwise_and_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins bitwise_and_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins bitwise_and_accel/stream_in1]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins bitwise_and_accel/ap_clk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins bitwise_and_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out] [get_bd_intf_pins bitwise_and_accel/stream_out]

assign_bd_address -offset 0x0000 -range 64K [get_bd_addr_segs {bitwise_and_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# pr_fork partition
set pr_fork_duplicate "pr_fork_duplicate"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /pr_fork] $pr_fork_duplicate
set new_pd [create_partition_def -name pr_fork -module $pr_fork_duplicate]
create_reconfig_module -name $pr_fork_duplicate -partition_def $new_pd -define_from $pr_fork_duplicate
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd pr_fork_temp]
replace_bd_cell  [get_bd_cells /pr_fork] $new_pdcell
delete_bd_objs  [get_bd_cells /pr_fork]
set_property name pr_fork $new_pdcell
## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_fork_duplicate]
delete_bd_objs [get_bd_ports clk_142M]
create_bd_port -dir I -type clk -freq_hz 142857132 clk_142M
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins duplicate_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control:stream_in0:stream_out0:stream_out1} [get_bd_ports /clk_142M]

assign_bd_address -offset 0x00000000 -range 64K [get_bd_addr_segs {s_axi_control/*_Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_fork_rgb2xyz "pr_fork_rgb2xyz"
create_bd_design -boundary_from [get_files $pr_fork_duplicate.bd] $pr_fork_rgb2xyz
create_reconfig_module -name $pr_fork_rgb2xyz -partition_def pr_fork -define_from $pr_fork_rgb2xyz
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:rgb2xyz_accel:1.0 rgb2xyz_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins rgb2xyz_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins rgb2xyz_accel/stream_in]
connect_bd_net [get_bd_ports clk_142M] [get_bd_pins rgb2xyz_accel/ap_clk]
connect_bd_net [get_bd_ports periph_resetn_clk142M] [get_bd_pins rgb2xyz_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins rgb2xyz_accel/stream_out]

assign_bd_address -offset 0x0000 -range 64K [get_bd_addr_segs {rgb2xyz_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# Save top-level and validate bd design
current_bd_design [get_bd_designs ${design_name}]
save_bd_design
validate_bd_design

# Make a wrapper file and add it
make_wrapper -files [get_files ./${prj_name}/${prj_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ./${prj_name}/${prj_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
set_property top ${design_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Create configurations and run the implementation
create_pr_configuration -name config_1 -partitions [list video_cp_i/pr_0:${pr_0_dilate_erode} video_cp_i/pr_1:${pr_1_dilate_erode} video_cp_i/pr_fork:${pr_fork_duplicate} video_cp_i/pr_join:${pr_join_subtract} ]
create_pr_configuration -name config_2 -partitions [list video_cp_i/pr_0:${pr_0_fast_fifo} video_cp_i/pr_1:${pr_1_cornerharris} video_cp_i/pr_fork:${pr_fork_rgb2xyz} video_cp_i/pr_join:${pr_join_absdiff} ]
create_pr_configuration -name config_3 -partitions [list video_cp_i/pr_0:${pr_0_filter2d_fifo} video_cp_i/pr_join:${pr_join_add} ] -greyboxes [list video_cp_i/pr_1 video_cp_i/pr_fork ]
create_pr_configuration -name config_4 -partitions [list video_cp_i/pr_join:${pr_join_bitand} ] -greyboxes [list video_cp_i/pr_0 video_cp_i/pr_1 video_cp_i/pr_fork ]
set_property PR_CONFIGURATION config_1 [get_runs impl_1]
create_run child_0_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2020} -strategy Performance_NetDelay_low -pr_config config_2
create_run child_1_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2020} -strategy Performance_NetDelay_low -pr_config config_3
create_run child_2_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2020} -strategy Performance_NetDelay_low -pr_config config_4


# Change global implementation strategy
set_property strategy Performance_NetDelay_low [get_runs impl_1]

launch_runs impl_1 child_0_impl_1 child_1_impl_1 child_2_impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
wait_on_run child_0_impl_1
wait_on_run child_1_impl_1
wait_on_run child_2_impl_1

# create bitstreams directory
set dest_dir "./overlay"
exec mkdir $dest_dir -p
# cp hwh files
# pr_0 related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_0_dilate_erode}/hw_handoff/${pr_0_dilate_erode}.hwh ./$dest_dir/${prj_name}_${pr_0_dilate_erode}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_0_fast_fifo}/hw_handoff/${pr_0_fast_fifo}.hwh ./$dest_dir/${prj_name}_${pr_0_fast_fifo}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_0_filter2d_fifo}/hw_handoff/${pr_0_filter2d_fifo}.hwh ./$dest_dir/${prj_name}_${pr_0_filter2d_fifo}_partial.hwh
# pr_1 related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_1_dilate_erode}/hw_handoff/${pr_1_dilate_erode}.hwh ./$dest_dir/${prj_name}_${pr_1_dilate_erode}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_1_cornerharris}/hw_handoff/${pr_1_cornerharris}.hwh ./$dest_dir/${prj_name}_${pr_1_cornerharris}_partial.hwh
# pr_join related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_subtract}/hw_handoff/${pr_join_subtract}.hwh ./$dest_dir/${prj_name}_${pr_join_subtract}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_absdiff}/hw_handoff/${pr_join_absdiff}.hwh ./$dest_dir/${prj_name}_${pr_join_absdiff}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_add}/hw_handoff/${pr_join_add}.hwh ./$dest_dir/${prj_name}_${pr_join_add}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_bitand}/hw_handoff/${pr_join_bitand}.hwh ./$dest_dir/${prj_name}_${pr_join_bitand}_partial.hwh
# pr_fork related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_fork_duplicate}/hw_handoff/${pr_fork_duplicate}.hwh ./$dest_dir/${prj_name}_${pr_fork_duplicate}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_fork_rgb2xyz}/hw_handoff/${pr_fork_rgb2xyz}.hwh ./$dest_dir/${prj_name}_${pr_fork_rgb2xyz}_partial.hwh
# top-level
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/$design_name/hw_handoff/$design_name.hwh ./$dest_dir/${prj_name}.hwh

# copy bitstreams
# impl1 having full and partial bitstreams
exec cp ./${prj_name}/${prj_name}.runs/impl_1/video_cp_i_pr_0_${pr_0_dilate_erode}_partial.bit ./$dest_dir/${prj_name}_${pr_0_dilate_erode}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/video_cp_i_pr_join_${pr_join_subtract}_partial.bit ./$dest_dir/${prj_name}_${pr_join_subtract}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/video_cp_i_pr_fork_${pr_fork_duplicate}_partial.bit ./$dest_dir/${prj_name}_${pr_fork_duplicate}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/video_cp_i_pr_1_${pr_1_dilate_erode}_partial.bit ./$dest_dir/${prj_name}_${pr_1_dilate_erode}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/video_cp_wrapper.bit ./$dest_dir/${prj_name}.bit
# child_0_impl_1
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/video_cp_i_pr_0_${pr_0_fast_fifo}_partial.bit ./$dest_dir/${prj_name}_${pr_0_fast_fifo}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/video_cp_i_pr_1_${pr_1_cornerharris}_partial.bit ./$dest_dir/${prj_name}_${pr_1_cornerharris}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/video_cp_i_pr_join_${pr_join_absdiff}_partial.bit ./$dest_dir/${prj_name}_${pr_join_absdiff}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/video_cp_i_pr_fork_${pr_fork_rgb2xyz}_partial.bit ./$dest_dir/${prj_name}_${pr_fork_rgb2xyz}_partial.bit
# child_1_impl_1
exec cp ./${prj_name}/${prj_name}.runs/child_1_impl_1/video_cp_i_pr_0_${pr_0_filter2d_fifo}_partial.bit ./$dest_dir/${prj_name}_${pr_0_filter2d_fifo}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_1_impl_1/video_cp_i_pr_join_${pr_join_add}_partial.bit ./$dest_dir/${prj_name}_${pr_join_add}_partial.bit
# child_2_impl_1
exec cp ./${prj_name}/${prj_name}.runs/child_2_impl_1/video_cp_i_pr_join_${pr_join_bitand}_partial.bit ./$dest_dir/${prj_name}_${pr_join_bitand}_partial.bit

