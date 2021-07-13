# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

###############################################################################
#
#
# @file cv_dfx_4_pr.tcl
#
# Vivado tcl script to generate composable pipeline full and partial bitstreams 
# for Pynq-ZU board
#
# <pre>
# MODIFICATION HISTORY:
#
# Ver   Who  Date     Changes
# ----- --- -------- -----------------------------------------------
# 1.00a mr   4/1/2021 Initial design, only HDMI path
#
# 1.10  mr   4/2/2021 Add mipi hierarchy and static portion of the composable overlay
#
# 1.20  mr   4/9/2021 Add DFX regions and reconfigurable modules
#
# 1.30  mr   4/21/2021 Move color thresholding to the static region, and rgb2xyz to the 
#                      pr_fork. Additionally add bitwise-and on pr_join
#                      Add logic for soft reset to flush pipeline. Set FIFO size to 16384
#                      for both input path to the pr_join hierarchy
#
# 1.40  mr   4/24/2021 Increase FIFO datapath to improve FIFO utilization
#
# 1.50  mr   4/29/2021 Include subset converter to format mipi pixels properly, include
#                      pixel pack, disable unaligned transfers, update implementation
#                      strategy to meet timing.
#
# 1.60  mr   7/02/2021 Move pipeline control inside the composable hierarchy, this includes
#                      the DFX control as well
#
# 2.00  mr   7/13/2021 Reorganize IPI, everything related to composable is within its
#                      own hierarchy.
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
set board [get_board_parts "*:pynqzu:*" -latest_file_version]
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
   create_project ${prj_name} ${prj_name} -part xczu5eg-sfvc784-1-e
   set_property BOARD_PART ${board} [current_project]
}

# Set IP repo
set_property ip_repo_paths "./ip/ ../ip/boards/ip" [current_project]
update_ip_catalog

# Add constraints files
add_files -fileset constrs_1 -norecurse cv_dfx_4_pr.xdc
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
xilinx.com:ip:axi_iic:2.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:zynq_ultra_ps_e:3.3\
xilinx.com:ip:dfx_axi_shutdown_manager:1.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlslice:1.0\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:axis_dwidth_converter:1.1\
xilinx.com:ip:axis_switch:1.1\
xilinx.com:hls:colorthresholding_accel:1.0\
xilinx.com:hls:filter2d_accel:1.0\
xilinx.com:hls:gray2rgb_accel:1.0\
xilinx.com:hls:LUT_accel:1.0\
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
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:axi_register_slice:2.1\
xilinx.com:ip:dfx_decoupler:1.0\
xilinx.com:ip:axis_register_slice:1.1\
xilinx.com:hls:dilate_accel:1.0\
xilinx.com:hls:erode_accel:1.0\
xilinx.com:hls:duplicate_accel:1.0\
xilinx.com:hls:subtract_accel:1.0\
xilinx.com:hls:color_convert_2:1.0\
xilinx.com:ip:v_hdmi_rx_ss:3.1\
xilinx.com:ip:v_hdmi_tx_ss:3.1\
xilinx.com:hls:pixel_unpack_2:1.0\
xilinx.com:ip:vid_phy_controller:2.2\
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


# Hierarchical cell: phy
proc create_hier_cell_phy { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_phy() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 vid_phy_axi4lite

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_rx_axi4s_ch0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_rx_axi4s_ch1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_rx_axi4s_ch2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_status_sb_rx

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_status_sb_tx

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_tx_axi4s_ch0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_tx_axi4s_ch1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 vid_phy_tx_axi4s_ch2


  # Create pins
  create_bd_pin -dir I -type clk HDMI_RX_CLK_N_IN
  create_bd_pin -dir I -type clk HDMI_RX_CLK_P_IN
  create_bd_pin -dir I -from 2 -to 0 HDMI_RX_DAT_N_IN
  create_bd_pin -dir I -from 2 -to 0 HDMI_RX_DAT_P_IN
  create_bd_pin -dir I HDMI_SI5324_LOL_IN
  create_bd_pin -dir O -type clk HDMI_TX_CLK_N_OUT
  create_bd_pin -dir O -type clk HDMI_TX_CLK_P_OUT
  create_bd_pin -dir O -from 2 -to 0 HDMI_TX_DAT_N_OUT
  create_bd_pin -dir O -from 2 -to 0 HDMI_TX_DAT_P_OUT
  create_bd_pin -dir O -type clk RX_REFCLK_N_OUT
  create_bd_pin -dir O -type clk RX_REFCLK_P_OUT
  create_bd_pin -dir I -type rst TX_EN_OUT
  create_bd_pin -dir I -type clk TX_REFCLK_N_IN
  create_bd_pin -dir I -type clk TX_REFCLK_P_IN
  create_bd_pin -dir I -type clk clk_100MHz
  create_bd_pin -dir I -type rst clk_100MHz_aresetn
  create_bd_pin -dir O -type intr irq2
  create_bd_pin -dir O -type clk rx_video_clk
  create_bd_pin -dir O -type clk tx_video_clk
  create_bd_pin -dir O -type clk vid_phy_rx_axi4s_aclk
  create_bd_pin -dir O -type clk vid_phy_tx_axi4s_aclk

  # Create instance: vid_phy_controller, and set properties
  set vid_phy_controller [ create_bd_cell -type ip -vlnv xilinx.com:ip:vid_phy_controller:2.2 vid_phy_controller ]
  set_property -dict [ list \
   CONFIG.CHANNEL_ENABLE {X0Y4 X0Y5 X0Y6} \
   CONFIG.CHANNEL_SITE {X0Y4} \
   CONFIG.C_INPUT_PIXELS_PER_CLOCK {2} \
   CONFIG.C_INT_HDMI_VER_CMPTBLE {3} \
   CONFIG.C_NIDRU {false} \
   CONFIG.C_NIDRU_REFCLK_SEL {0} \
   CONFIG.C_RX_PLL_SELECTION {0} \
   CONFIG.C_RX_REFCLK_SEL {1} \
   CONFIG.C_Rx_Protocol {HDMI} \
   CONFIG.C_TX_PLL_SELECTION {6} \
   CONFIG.C_TX_REFCLK_SEL {0} \
   CONFIG.C_Tx_Protocol {HDMI} \
   CONFIG.C_Txrefclk_Rdy_Invert {true} \
   CONFIG.C_Use_Oddr_for_Tmds_Clkout {true} \
   CONFIG.C_vid_phy_rx_axi4s_ch_INT_TDATA_WIDTH {20} \
   CONFIG.C_vid_phy_rx_axi4s_ch_TDATA_WIDTH {20} \
   CONFIG.C_vid_phy_rx_axi4s_ch_TUSER_WIDTH {1} \
   CONFIG.C_vid_phy_tx_axi4s_ch_INT_TDATA_WIDTH {20} \
   CONFIG.C_vid_phy_tx_axi4s_ch_TDATA_WIDTH {20} \
   CONFIG.C_vid_phy_tx_axi4s_ch_TUSER_WIDTH {1} \
   CONFIG.Rx_GT_Line_Rate {5.94} \
   CONFIG.Rx_GT_Ref_Clock_Freq {297} \
   CONFIG.Transceiver_Width {2} \
   CONFIG.Tx_GT_Line_Rate {5.94} \
   CONFIG.Tx_GT_Ref_Clock_Freq {297} \
 ] $vid_phy_controller

  # Create interface connections
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA0_OUT [get_bd_intf_pins vid_phy_tx_axi4s_ch0] [get_bd_intf_pins vid_phy_controller/vid_phy_tx_axi4s_ch0]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA1_OUT [get_bd_intf_pins vid_phy_tx_axi4s_ch1] [get_bd_intf_pins vid_phy_controller/vid_phy_tx_axi4s_ch1]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA2_OUT [get_bd_intf_pins vid_phy_tx_axi4s_ch2] [get_bd_intf_pins vid_phy_controller/vid_phy_tx_axi4s_ch2]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch0 [get_bd_intf_pins vid_phy_rx_axi4s_ch0] [get_bd_intf_pins vid_phy_controller/vid_phy_rx_axi4s_ch0]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch1 [get_bd_intf_pins vid_phy_rx_axi4s_ch1] [get_bd_intf_pins vid_phy_controller/vid_phy_rx_axi4s_ch1]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch2 [get_bd_intf_pins vid_phy_rx_axi4s_ch2] [get_bd_intf_pins vid_phy_controller/vid_phy_rx_axi4s_ch2]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_status_sb_rx [get_bd_intf_pins vid_phy_status_sb_rx] [get_bd_intf_pins vid_phy_controller/vid_phy_status_sb_rx]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_status_sb_tx [get_bd_intf_pins vid_phy_status_sb_tx] [get_bd_intf_pins vid_phy_controller/vid_phy_status_sb_tx]
  connect_bd_intf_net -intf_net intf_net_zynq_us_ss_0_M00_AXI [get_bd_intf_pins vid_phy_axi4lite] [get_bd_intf_pins vid_phy_controller/vid_phy_axi4lite]

  # Create port connections
  connect_bd_net -net net_bdry_in_HDMI_RX_CLK_N_IN [get_bd_pins HDMI_RX_CLK_N_IN] [get_bd_pins vid_phy_controller/mgtrefclk1_pad_n_in]
  connect_bd_net -net net_bdry_in_HDMI_RX_CLK_P_IN [get_bd_pins HDMI_RX_CLK_P_IN] [get_bd_pins vid_phy_controller/mgtrefclk1_pad_p_in]
  connect_bd_net -net net_bdry_in_HDMI_RX_DAT_N_IN [get_bd_pins HDMI_RX_DAT_N_IN] [get_bd_pins vid_phy_controller/phy_rxn_in]
  connect_bd_net -net net_bdry_in_HDMI_RX_DAT_P_IN [get_bd_pins HDMI_RX_DAT_P_IN] [get_bd_pins vid_phy_controller/phy_rxp_in]
  connect_bd_net -net net_bdry_in_HDMI_SI5324_LOL_IN [get_bd_pins HDMI_SI5324_LOL_IN] [get_bd_pins vid_phy_controller/tx_refclk_rdy]
  connect_bd_net -net net_bdry_in_TX_REFCLK_N_IN [get_bd_pins TX_REFCLK_N_IN] [get_bd_pins vid_phy_controller/mgtrefclk0_pad_n_in]
  connect_bd_net -net net_bdry_in_TX_REFCLK_P_IN [get_bd_pins TX_REFCLK_P_IN] [get_bd_pins vid_phy_controller/mgtrefclk0_pad_p_in]
  connect_bd_net -net net_vcc_const_dout [get_bd_pins TX_EN_OUT] [get_bd_pins vid_phy_controller/vid_phy_rx_axi4s_aresetn] [get_bd_pins vid_phy_controller/vid_phy_tx_axi4s_aresetn]
  connect_bd_net -net net_vid_phy_controller_irq [get_bd_pins irq2] [get_bd_pins vid_phy_controller/irq]
  connect_bd_net -net net_vid_phy_controller_phy_txn_out [get_bd_pins HDMI_TX_DAT_N_OUT] [get_bd_pins vid_phy_controller/phy_txn_out]
  connect_bd_net -net net_vid_phy_controller_phy_txp_out [get_bd_pins HDMI_TX_DAT_P_OUT] [get_bd_pins vid_phy_controller/phy_txp_out]
  connect_bd_net -net net_vid_phy_controller_rx_tmds_clk_n [get_bd_pins RX_REFCLK_N_OUT] [get_bd_pins vid_phy_controller/rx_tmds_clk_n]
  connect_bd_net -net net_vid_phy_controller_rx_tmds_clk_p [get_bd_pins RX_REFCLK_P_OUT] [get_bd_pins vid_phy_controller/rx_tmds_clk_p]
  connect_bd_net -net net_vid_phy_controller_rx_video_clk [get_bd_pins rx_video_clk] [get_bd_pins vid_phy_controller/rx_video_clk]
  connect_bd_net -net net_vid_phy_controller_rxoutclk [get_bd_pins vid_phy_rx_axi4s_aclk] [get_bd_pins vid_phy_controller/rxoutclk] [get_bd_pins vid_phy_controller/vid_phy_rx_axi4s_aclk]
  connect_bd_net -net net_vid_phy_controller_tx_tmds_clk_n [get_bd_pins HDMI_TX_CLK_N_OUT] [get_bd_pins vid_phy_controller/tx_tmds_clk_n]
  connect_bd_net -net net_vid_phy_controller_tx_tmds_clk_p [get_bd_pins HDMI_TX_CLK_P_OUT] [get_bd_pins vid_phy_controller/tx_tmds_clk_p]
  connect_bd_net -net net_vid_phy_controller_tx_video_clk [get_bd_pins tx_video_clk] [get_bd_pins vid_phy_controller/tx_video_clk]
  connect_bd_net -net net_vid_phy_controller_txoutclk [get_bd_pins vid_phy_tx_axi4s_aclk] [get_bd_pins vid_phy_controller/txoutclk] [get_bd_pins vid_phy_controller/vid_phy_tx_axi4s_aclk]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins clk_100MHz_aresetn] [get_bd_pins vid_phy_controller/vid_phy_axi4lite_aresetn] [get_bd_pins vid_phy_controller/vid_phy_sb_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins clk_100MHz] [get_bd_pins vid_phy_controller/drpclk] [get_bd_pins vid_phy_controller/vid_phy_axi4lite_aclk] [get_bd_pins vid_phy_controller/vid_phy_sb_aclk]

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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 LINK_DATA0_OUT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 LINK_DATA1_OUT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 LINK_DATA2_OUT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 SB_STATUS_IN

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CPU_IN

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 TX_DDC_OUT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 stream_in_64


  # Create pins
  create_bd_pin -dir I TX_HPD_IN
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk clk_100MHz
  create_bd_pin -dir I -type rst clk_100MHz_aresetn
  create_bd_pin -dir O -type intr irq1
  create_bd_pin -dir I -type clk link_clk
  create_bd_pin -dir I -type clk s_axis_audio_aclk
  create_bd_pin -dir I -type clk video_clk

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

  # Create instance: color_convert, and set properties
  set color_convert [ create_bd_cell -type ip -vlnv xilinx.com:hls:color_convert_2:1.0 color_convert ]

  # Create instance: frontend, and set properties
  set frontend [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_hdmi_tx_ss:3.1 frontend ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {13} \
   CONFIG.C_ADD_MARK_DBG {false} \
   CONFIG.C_EXDES_AXILITE_FREQ {100} \
   CONFIG.C_EXDES_NIDRU {true} \
   CONFIG.C_EXDES_RX_PLL_SELECTION {0} \
   CONFIG.C_EXDES_TOPOLOGY {0} \
   CONFIG.C_EXDES_TX_PLL_SELECTION {6} \
   CONFIG.C_HDMI_FAST_SWITCH {true} \
   CONFIG.C_HDMI_VERSION {3} \
   CONFIG.C_HPD_INVERT {false} \
   CONFIG.C_HYSTERESIS_LEVEL {12} \
   CONFIG.C_INCLUDE_HDCP_1_4 {false} \
   CONFIG.C_INCLUDE_HDCP_2_2 {false} \
   CONFIG.C_INCLUDE_LOW_RESO_VID {false} \
   CONFIG.C_INCLUDE_YUV420_SUP {false} \
   CONFIG.C_INPUT_PIXELS_PER_CLOCK {2} \
   CONFIG.C_MAX_BITS_PER_COMPONENT {8} \
   CONFIG.C_VALIDATION_ENABLE {false} \
   CONFIG.C_VIDEO_MASK_ENABLE {1} \
   CONFIG.C_VID_INTERFACE {0} \
 ] $frontend

  # Create instance: pixel_reorder, and set properties
  set pixel_reorder [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 pixel_reorder ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TDATA_REMAP {tdata[47:40],tdata[31:24],tdata[39:32],tdata[23:16],tdata[7:0],tdata[15:8]} \
 ] $pixel_reorder

  # Create instance: pixel_unpack, and set properties
  set pixel_unpack [ create_bd_cell -type ip -vlnv xilinx.com:hls:pixel_unpack_2:1.0 pixel_unpack ]

  # Create instance: tx_video_axis_reg_slice, and set properties
  set tx_video_axis_reg_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 tx_video_axis_reg_slice ]
  set_property -dict [ list \
   CONFIG.REG_CONFIG {8} \
 ] $tx_video_axis_reg_slice

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_dwidth_48_24/M_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins color_convert/stream_in_48]
  connect_bd_intf_net -intf_net axi_interconnect_M07_AXI [get_bd_intf_pins s_axi_control] [get_bd_intf_pins color_convert/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_M10_AXI [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins pixel_unpack/s_axi_control]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins stream_in_64] [get_bd_intf_pins pixel_unpack/stream_in_64]
  connect_bd_intf_net -intf_net axis_subset_converter_0_M_AXIS [get_bd_intf_pins frontend/VIDEO_IN] [get_bd_intf_pins pixel_reorder/M_AXIS]
  connect_bd_intf_net -intf_net color_convert_0_stream_out_48 [get_bd_intf_pins color_convert/stream_out_48] [get_bd_intf_pins tx_video_axis_reg_slice/S_AXIS]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_DDC_OUT [get_bd_intf_pins TX_DDC_OUT] [get_bd_intf_pins frontend/DDC_OUT]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA0_OUT [get_bd_intf_pins LINK_DATA0_OUT] [get_bd_intf_pins frontend/LINK_DATA0_OUT]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA1_OUT [get_bd_intf_pins LINK_DATA1_OUT] [get_bd_intf_pins frontend/LINK_DATA1_OUT]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA2_OUT [get_bd_intf_pins LINK_DATA2_OUT] [get_bd_intf_pins frontend/LINK_DATA2_OUT]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_status_sb_tx [get_bd_intf_pins SB_STATUS_IN] [get_bd_intf_pins frontend/SB_STATUS_IN]
  connect_bd_intf_net -intf_net intf_net_zynq_us_ss_0_M02_AXI [get_bd_intf_pins S_AXI_CPU_IN] [get_bd_intf_pins frontend/S_AXI_CPU_IN]
  connect_bd_intf_net -intf_net pixel_unpack_stream_out_48 [get_bd_intf_pins axis_dwidth_48_24/S_AXIS] [get_bd_intf_pins pixel_unpack/stream_out_48]
  connect_bd_intf_net -intf_net tx_video_axis_reg_slice_M_AXIS [get_bd_intf_pins pixel_reorder/S_AXIS] [get_bd_intf_pins tx_video_axis_reg_slice/M_AXIS]

  # Create port connections
  connect_bd_net -net net_bdry_in_TX_HPD_IN [get_bd_pins TX_HPD_IN] [get_bd_pins frontend/hpd]
  connect_bd_net -net net_v_hdmi_tx_ss_irq [get_bd_pins irq1] [get_bd_pins frontend/irq]
  connect_bd_net -net net_vid_phy_controller_tx_video_clk [get_bd_pins video_clk] [get_bd_pins frontend/video_clk]
  connect_bd_net -net net_vid_phy_controller_txoutclk [get_bd_pins link_clk] [get_bd_pins frontend/link_clk]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins aclk] [get_bd_pins axis_dwidth_48_24/aclk] [get_bd_pins color_convert/ap_clk] [get_bd_pins frontend/s_axis_video_aclk] [get_bd_pins pixel_reorder/aclk] [get_bd_pins pixel_unpack/ap_clk] [get_bd_pins tx_video_axis_reg_slice/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins aresetn] [get_bd_pins axis_dwidth_48_24/aresetn] [get_bd_pins color_convert/ap_rst_n] [get_bd_pins frontend/s_axis_video_aresetn] [get_bd_pins pixel_reorder/aresetn] [get_bd_pins pixel_unpack/ap_rst_n] [get_bd_pins tx_video_axis_reg_slice/aresetn]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins clk_100MHz_aresetn] [get_bd_pins frontend/s_axi_cpu_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins clk_100MHz] [get_bd_pins frontend/s_axi_cpu_aclk]
  connect_bd_net -net s_axis_audio_aclk_1 [get_bd_pins s_axis_audio_aclk] [get_bd_pins frontend/s_axis_audio_aclk]

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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 LINK_DATA0_IN

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 LINK_DATA1_IN

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 LINK_DATA2_IN

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 RX_DDC_OUT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 SB_STATUS_IN

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CPU_IN

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_control1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out_64


  # Create pins
  create_bd_pin -dir I RX_DET_IN
  create_bd_pin -dir O RX_HPD_OUT
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk clk_100MHz
  create_bd_pin -dir I -type rst clk_100MHz_aresetn
  create_bd_pin -dir O fid
  create_bd_pin -dir O -type intr irq
  create_bd_pin -dir I -type clk link_clk
  create_bd_pin -dir I -type clk s_axis_audio_aclk
  create_bd_pin -dir I -type clk video_clk

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

  # Create instance: color_convert, and set properties
  set color_convert [ create_bd_cell -type ip -vlnv xilinx.com:hls:color_convert_2:1.0 color_convert ]

  # Create instance: frontend, and set properties
  set frontend [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_hdmi_rx_ss:3.1 frontend ]
  set_property -dict [ list \
   CONFIG.C_ADDR_WIDTH {10} \
   CONFIG.C_ADD_MARK_DBG {false} \
   CONFIG.C_CD_INVERT {true} \
   CONFIG.C_EDID_RAM_SIZE {256} \
   CONFIG.C_HDMI_FAST_SWITCH {true} \
   CONFIG.C_HDMI_VERSION {3} \
   CONFIG.C_HPD_INVERT {false} \
   CONFIG.C_INCLUDE_HDCP_1_4 {false} \
   CONFIG.C_INCLUDE_HDCP_2_2 {false} \
   CONFIG.C_INCLUDE_LOW_RESO_VID {false} \
   CONFIG.C_INCLUDE_YUV420_SUP {false} \
   CONFIG.C_INPUT_PIXELS_PER_CLOCK {2} \
   CONFIG.C_MAX_BITS_PER_COMPONENT {8} \
   CONFIG.C_VALIDATION_ENABLE {false} \
   CONFIG.C_VID_INTERFACE {0} \
 ] $frontend

  # Create instance: pixel_pack, and set properties
  set pixel_pack [ create_bd_cell -type ip -vlnv xilinx.com:hls:pixel_pack_2:1.0 pixel_pack ]

  # Create instance: pixel_reorder, and set properties
  set pixel_reorder [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 pixel_reorder ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TDATA_REMAP {tdata[47:40],tdata[31:24],tdata[39:32],tdata[23:16],tdata[7:0],tdata[15:8]} \
 ] $pixel_reorder

  # Create instance: rx_video_axis_reg_slice, and set properties
  set rx_video_axis_reg_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 rx_video_axis_reg_slice ]
  set_property -dict [ list \
   CONFIG.REG_CONFIG {8} \
 ] $rx_video_axis_reg_slice

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_dwidth_48_24/M_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_dwidth_24_48/S_AXIS]
  connect_bd_intf_net -intf_net axi_interconnect_M08_AXI [get_bd_intf_pins s_axi_control] [get_bd_intf_pins color_convert/s_axi_control]
  connect_bd_intf_net -intf_net axi_interconnect_M09_AXI [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins pixel_pack/s_axi_control]
  connect_bd_intf_net -intf_net axis_dwidth_24_48_M_AXIS [get_bd_intf_pins axis_dwidth_24_48/M_AXIS] [get_bd_intf_pins pixel_pack/stream_in_48]
  connect_bd_intf_net -intf_net color_convert_stream_out_48 [get_bd_intf_pins axis_dwidth_48_24/S_AXIS] [get_bd_intf_pins color_convert/stream_out_48]
  connect_bd_intf_net -intf_net frontend_VIDEO_OUT [get_bd_intf_pins frontend/VIDEO_OUT] [get_bd_intf_pins pixel_reorder/S_AXIS]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_rx_ss_DDC_OUT [get_bd_intf_pins RX_DDC_OUT] [get_bd_intf_pins frontend/DDC_OUT]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch0 [get_bd_intf_pins LINK_DATA0_IN] [get_bd_intf_pins frontend/LINK_DATA0_IN]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch1 [get_bd_intf_pins LINK_DATA1_IN] [get_bd_intf_pins frontend/LINK_DATA1_IN]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch2 [get_bd_intf_pins LINK_DATA2_IN] [get_bd_intf_pins frontend/LINK_DATA2_IN]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_status_sb_rx [get_bd_intf_pins SB_STATUS_IN] [get_bd_intf_pins frontend/SB_STATUS_IN]
  connect_bd_intf_net -intf_net intf_net_zynq_us_ss_0_M01_AXI [get_bd_intf_pins S_AXI_CPU_IN] [get_bd_intf_pins frontend/S_AXI_CPU_IN]
  connect_bd_intf_net -intf_net pixel_pack_0_stream_out_64 [get_bd_intf_pins stream_out_64] [get_bd_intf_pins pixel_pack/stream_out_64]
  connect_bd_intf_net -intf_net pixel_reorder_M_AXIS [get_bd_intf_pins pixel_reorder/M_AXIS] [get_bd_intf_pins rx_video_axis_reg_slice/S_AXIS]
  connect_bd_intf_net -intf_net rx_video_axis_reg_slice_M_AXIS [get_bd_intf_pins color_convert/stream_in_48] [get_bd_intf_pins rx_video_axis_reg_slice/M_AXIS]

  # Create port connections
  connect_bd_net -net net_bdry_in_RX_DET_IN [get_bd_pins RX_DET_IN] [get_bd_pins frontend/cable_detect]
  connect_bd_net -net net_v_hdmi_rx_ss_fid [get_bd_pins fid] [get_bd_pins frontend/fid]
  connect_bd_net -net net_v_hdmi_rx_ss_hpd [get_bd_pins RX_HPD_OUT] [get_bd_pins frontend/hpd]
  connect_bd_net -net net_v_hdmi_rx_ss_irq [get_bd_pins irq] [get_bd_pins frontend/irq]
  connect_bd_net -net net_vid_phy_controller_rx_video_clk [get_bd_pins video_clk] [get_bd_pins frontend/video_clk]
  connect_bd_net -net net_vid_phy_controller_rxoutclk [get_bd_pins link_clk] [get_bd_pins frontend/link_clk]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins aclk] [get_bd_pins axis_dwidth_24_48/aclk] [get_bd_pins axis_dwidth_48_24/aclk] [get_bd_pins color_convert/ap_clk] [get_bd_pins frontend/s_axis_video_aclk] [get_bd_pins pixel_pack/ap_clk] [get_bd_pins pixel_reorder/aclk] [get_bd_pins rx_video_axis_reg_slice/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins aresetn] [get_bd_pins axis_dwidth_24_48/aresetn] [get_bd_pins axis_dwidth_48_24/aresetn] [get_bd_pins color_convert/ap_rst_n] [get_bd_pins frontend/s_axis_video_aresetn] [get_bd_pins pixel_pack/ap_rst_n] [get_bd_pins pixel_reorder/aresetn] [get_bd_pins rx_video_axis_reg_slice/aresetn]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins clk_100MHz_aresetn] [get_bd_pins frontend/s_axi_cpu_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins clk_100MHz] [get_bd_pins frontend/s_axi_cpu_aclk]
  connect_bd_net -net s_axis_audio_aclk_1 [get_bd_pins s_axis_audio_aclk] [get_bd_pins frontend/s_axis_audio_aclk]

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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 stream_out0


  # Create pins
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn

  # Create instance: subtract_accel, and set properties
  set subtract_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:subtract_accel:1.0 subtract_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins subtract_accel/s_axi_control]
  connect_bd_intf_net -intf_net stream_in0_1 [get_bd_intf_pins stream_in0] [get_bd_intf_pins subtract_accel/stream_in]
  connect_bd_intf_net -intf_net stream_in1_1 [get_bd_intf_pins stream_in1] [get_bd_intf_pins subtract_accel/stream_in1]
  connect_bd_intf_net -intf_net subtract_accel_stream_out [get_bd_intf_pins stream_out0] [get_bd_intf_pins subtract_accel/stream_out]

  # Create port connections
  connect_bd_net -net clk_300MHz_1 [get_bd_pins clk_300MHz] [get_bd_pins subtract_accel/ap_clk]
  connect_bd_net -net clk_300MHz_aresetn_1 [get_bd_pins clk_300MHz_aresetn] [get_bd_pins subtract_accel/ap_rst_n]

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
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn

  # Create instance: duplicate_accel, and set properties
  set duplicate_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:duplicate_accel:1.0 duplicate_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net duplicate_accel_stream_out [get_bd_intf_pins stream_out0] [get_bd_intf_pins duplicate_accel/stream_out]
  connect_bd_intf_net -intf_net duplicate_accel_stream_out1 [get_bd_intf_pins stream_out1] [get_bd_intf_pins duplicate_accel/stream_out1]
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_pins s_axi_control] [get_bd_intf_pins duplicate_accel/s_axi_control]
  connect_bd_intf_net -intf_net stream_in0_1 [get_bd_intf_pins stream_in0] [get_bd_intf_pins duplicate_accel/stream_in]

  # Create port connections
  connect_bd_net -net clk_300MHz_1 [get_bd_pins clk_300MHz] [get_bd_pins duplicate_accel/ap_clk]
  connect_bd_net -net clk_300MHz_aresetn_1 [get_bd_pins clk_300MHz_aresetn] [get_bd_pins duplicate_accel/ap_rst_n]

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
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn

  # Create instance: dilate_accel, and set properties
  set dilate_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:dilate_accel:1.0 dilate_accel ]

  # Create instance: erode_accel, and set properties
  set erode_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:erode_accel:1.0 erode_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_0 [get_bd_intf_pins stream_in1] [get_bd_intf_pins dilate_accel/stream_in]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_1 [get_bd_intf_pins stream_in0] [get_bd_intf_pins erode_accel/stream_in]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_0_0 [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins dilate_accel/s_axi_control]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_0_1 [get_bd_intf_pins s_axi_control0] [get_bd_intf_pins erode_accel/s_axi_control]
  connect_bd_intf_net -intf_net dilate_accel_stream_out [get_bd_intf_pins stream_out1] [get_bd_intf_pins dilate_accel/stream_out]
  connect_bd_intf_net -intf_net erode_accel_stream_out [get_bd_intf_pins stream_out0] [get_bd_intf_pins erode_accel/stream_out]

  # Create port connections
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins dilate_accel/ap_clk] [get_bd_pins erode_accel/ap_clk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins dilate_accel/ap_rst_n] [get_bd_pins erode_accel/ap_rst_n]

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
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn

  # Create instance: dilate_accel, and set properties
  set dilate_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:dilate_accel:1.0 dilate_accel ]

  # Create instance: erode_accel, and set properties
  set erode_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:erode_accel:1.0 erode_accel ]

  # Create interface connections
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_0 [get_bd_intf_pins stream_in0] [get_bd_intf_pins dilate_accel/stream_in]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_1 [get_bd_intf_pins stream_in1] [get_bd_intf_pins erode_accel/stream_in]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_0_0 [get_bd_intf_pins s_axi_control0] [get_bd_intf_pins dilate_accel/s_axi_control]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_0_1 [get_bd_intf_pins s_axi_control1] [get_bd_intf_pins erode_accel/s_axi_control]
  connect_bd_intf_net -intf_net dilate_accel_stream_out [get_bd_intf_pins stream_out0] [get_bd_intf_pins dilate_accel/stream_out]
  connect_bd_intf_net -intf_net erode_accel_stream_out [get_bd_intf_pins stream_out1] [get_bd_intf_pins erode_accel/stream_out]

  # Create port connections
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins dilate_accel/ap_clk] [get_bd_pins erode_accel/ap_clk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins dilate_accel/ap_rst_n] [get_bd_pins erode_accel/ap_rst_n]

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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S13_AXI

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
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn
  create_bd_pin -dir I -from 7 -to 0 dfx_decouple
  create_bd_pin -dir O -from 7 -to 0 dfx_status
  create_bd_pin -dir I -type rst soft_rst_n

  # Create instance: axi_register_slice, and set properties
  set axi_register_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice ]
  set_property -dict [ list \
   CONFIG.REG_AR {7} \
   CONFIG.REG_AW {7} \
 ] $axi_register_slice

  # Create instance: dfx_decoupler_pr_0, and set properties
  set dfx_decoupler_pr_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_decoupler:1.0 dfx_decoupler_pr_0 ]
  set_property -dict [ list \
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} in_1 {ID 1 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24 MANAGEMENT manual} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_1 {ID 3 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite0 {ID 4 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}} axi_lite1 {ID 5 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 28} \
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
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} in_1 {ID 1 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_1 {ID 3 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite0 {ID 4 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}} axi_lite1 {ID 5 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 7} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 7} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 23} \
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
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 1 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_1 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite {ID 3 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 9} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 9} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 16} \
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
   CONFIG.ALL_PARAMS {INTF {in_0 {ID 0 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} in_1 {ID 1 MODE slave VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 0 WIDTH 0} TDEST {PRESENT 0 WIDTH 0} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} out_0 {ID 2 VLNV xilinx.com:interface:axis_rtl:1.0 SIGNALS {TVALID {PRESENT 1 WIDTH 1} TREADY {PRESENT 1 WIDTH 1} TDATA {PRESENT 1 WIDTH 24} TUSER {PRESENT 1 WIDTH 1} TLAST {PRESENT 1 WIDTH 1} TID {PRESENT 1 WIDTH 1} TDEST {PRESENT 1 WIDTH 1} TSTRB {PRESENT 0 WIDTH 3} TKEEP {PRESENT 0 WIDTH 3}}} axi_lite {ID 3 VLNV xilinx.com:interface:aximm_rtl:1.0 PROTOCOL axi4lite SIGNALS {ARVALID {PRESENT 1 WIDTH 1} ARREADY {PRESENT 1 WIDTH 1} AWVALID {PRESENT 1 WIDTH 1} AWREADY {PRESENT 1 WIDTH 1} BVALID {PRESENT 1 WIDTH 1} BREADY {PRESENT 1 WIDTH 1} RVALID {PRESENT 1 WIDTH 1} RREADY {PRESENT 1 WIDTH 1} WVALID {PRESENT 1 WIDTH 1} WREADY {PRESENT 1 WIDTH 1} AWADDR {PRESENT 1 WIDTH 5} AWLEN {PRESENT 0 WIDTH 8} AWSIZE {PRESENT 0 WIDTH 3} AWBURST {PRESENT 0 WIDTH 2} AWLOCK {PRESENT 0 WIDTH 1} AWCACHE {PRESENT 0 WIDTH 4} AWPROT {PRESENT 1 WIDTH 3} WDATA {PRESENT 1 WIDTH 32} WSTRB {PRESENT 1 WIDTH 4} WLAST {PRESENT 0 WIDTH 1} BRESP {PRESENT 1 WIDTH 2} ARADDR {PRESENT 1 WIDTH 5} ARLEN {PRESENT 0 WIDTH 8} ARSIZE {PRESENT 0 WIDTH 3} ARBURST {PRESENT 0 WIDTH 2} ARLOCK {PRESENT 0 WIDTH 1} ARCACHE {PRESENT 0 WIDTH 4} ARPROT {PRESENT 1 WIDTH 3} RDATA {PRESENT 1 WIDTH 32} RRESP {PRESENT 1 WIDTH 2} RLAST {PRESENT 0 WIDTH 1} AWID {PRESENT 0 WIDTH 0} AWREGION {PRESENT 1 WIDTH 4} AWQOS {PRESENT 1 WIDTH 4} AWUSER {PRESENT 0 WIDTH 0} WID {PRESENT 0 WIDTH 0} WUSER {PRESENT 0 WIDTH 0} BID {PRESENT 0 WIDTH 0} BUSER {PRESENT 0 WIDTH 0} ARID {PRESENT 0 WIDTH 0} ARREGION {PRESENT 1 WIDTH 4} ARQOS {PRESENT 1 WIDTH 4} ARUSER {PRESENT 0 WIDTH 0} RID {PRESENT 0 WIDTH 0} RUSER {PRESENT 0 WIDTH 0}}}} IPI_PROP_COUNT 15} \
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
   CONFIG.FIFO_DEPTH {4096} \
   CONFIG.FIFO_MEMORY_TYPE {ultra} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_WIDTH {1} \
 ] $pr_join_fifo_in_0

  # Create instance: pr_join_fifo_in_1, and set properties
  set pr_join_fifo_in_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 pr_join_fifo_in_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {4096} \
   CONFIG.FIFO_MEMORY_TYPE {ultra} \
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

  # Create instance: smartconnect, and set properties
  set smartconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {6} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect

  # Create instance: status_xlconcat, and set properties
  set status_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 status_xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $status_xlconcat

  # Create instance: xlslice_pr_0, and set properties
  set xlslice_pr_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_pr_0 ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {8} \
 ] $xlslice_pr_0

  # Create instance: xlslice_pr_1, and set properties
  set xlslice_pr_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_pr_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_pr_1

  # Create instance: xlslice_pr_fork, and set properties
  set xlslice_pr_fork [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_pr_fork ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_pr_fork

  # Create instance: xlslice_pr_join, and set properties
  set xlslice_pr_join [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_pr_join ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_pr_join

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S13_AXI] [get_bd_intf_pins axi_register_slice/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins axi_register_slice/M_AXI] [get_bd_intf_pins smartconnect/S00_AXI]
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
  connect_bd_intf_net -intf_net s_axis_dfx_pr_1_1_1 [get_bd_intf_pins s_axis_dfx_pr_1_1] [get_bd_intf_pins dfx_decoupler_pr_1/s_in_1]
  connect_bd_intf_net -intf_net s_axis_pr_1_1_1 [get_bd_intf_pins s_axis_pr_1_1] [get_bd_intf_pins pr_1_out1/S_AXIS]
  connect_bd_intf_net -intf_net s_in_5_1 [get_bd_intf_pins s_axis_dfx_pr_join_0] [get_bd_intf_pins pr_join_fifo_in_0/S_AXIS]
  connect_bd_intf_net -intf_net s_in_6_1 [get_bd_intf_pins s_axis_dfx_pr_join_1] [get_bd_intf_pins pr_join_fifo_in_1/S_AXIS]
  connect_bd_intf_net -intf_net smartconnect1_M00_AXI [get_bd_intf_pins dfx_decoupler_pr_0/rp_axi_lite0] [get_bd_intf_pins smartconnect/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect1_M01_AXI [get_bd_intf_pins dfx_decoupler_pr_0/rp_axi_lite1] [get_bd_intf_pins smartconnect/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect1_M02_AXI [get_bd_intf_pins dfx_decoupler_pr_1/rp_axi_lite0] [get_bd_intf_pins smartconnect/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect1_M03_AXI [get_bd_intf_pins dfx_decoupler_pr_1/rp_axi_lite1] [get_bd_intf_pins smartconnect/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect1_M04_AXI [get_bd_intf_pins dfx_decoupler_pr_fork/rp_axi_lite] [get_bd_intf_pins smartconnect/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect1_M05_AXI [get_bd_intf_pins dfx_decoupler_pr_join/rp_axi_lite] [get_bd_intf_pins smartconnect/M05_AXI]
  connect_bd_intf_net -intf_net video_M12_AXIS [get_bd_intf_pins s_axis_dfx_pr_0_0] [get_bd_intf_pins dfx_decoupler_pr_0/s_in_0]
  connect_bd_intf_net -intf_net video_M13_AXIS [get_bd_intf_pins s_axis_dfx_pr_0_1] [get_bd_intf_pins dfx_decoupler_pr_0/s_in_1]
  connect_bd_intf_net -intf_net video_M13_AXIS1 [get_bd_intf_pins s_axis_dfx_pr_fork] [get_bd_intf_pins dfx_decoupler_pr_fork/s_in_0]
  connect_bd_intf_net -intf_net video_M14_AXIS [get_bd_intf_pins s_axis_dfx_pr_1_0] [get_bd_intf_pins dfx_decoupler_pr_1/s_in_0]

  # Create port connections
  connect_bd_net -net clk_300MHz_aresetn_1 [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axi_register_slice/aresetn] [get_bd_pins smartconnect/aresetn]
  connect_bd_net -net dfx_decoupler_0_decouple_status [get_bd_pins dfx_decoupler_pr_0/decouple_status] [get_bd_pins status_xlconcat/In4]
  connect_bd_net -net dfx_decoupler_1_decouple_status [get_bd_pins dfx_decoupler_pr_1/decouple_status] [get_bd_pins status_xlconcat/In5]
  connect_bd_net -net dfx_decoupler_2_decouple_status [get_bd_pins dfx_decoupler_pr_join/decouple_status] [get_bd_pins status_xlconcat/In6]
  connect_bd_net -net dfx_decoupler_3_decouple_status [get_bd_pins dfx_decoupler_pr_fork/decouple_status] [get_bd_pins status_xlconcat/In7]
  connect_bd_net -net ps7_0_FCLK_CLK1 [get_bd_pins clk_300MHz] [get_bd_pins axi_register_slice/aclk] [get_bd_pins pr_0_in0/aclk] [get_bd_pins pr_0_in1/aclk] [get_bd_pins pr_0_out0/aclk] [get_bd_pins pr_0_out1/aclk] [get_bd_pins pr_1_in0/aclk] [get_bd_pins pr_1_in1/aclk] [get_bd_pins pr_1_out0/aclk] [get_bd_pins pr_1_out1/aclk] [get_bd_pins pr_fork_in0/aclk] [get_bd_pins pr_fork_out0/aclk] [get_bd_pins pr_fork_out1/aclk] [get_bd_pins pr_join_fifo_in_0/s_axis_aclk] [get_bd_pins pr_join_fifo_in_1/s_axis_aclk] [get_bd_pins pr_join_in0/aclk] [get_bd_pins pr_join_in1/aclk] [get_bd_pins pr_join_out0/aclk] [get_bd_pins smartconnect/aclk]
  connect_bd_net -net ps7_0_GPIO_O [get_bd_pins dfx_decouple] [get_bd_pins xlslice_pr_0/Din] [get_bd_pins xlslice_pr_1/Din] [get_bd_pins xlslice_pr_fork/Din] [get_bd_pins xlslice_pr_join/Din]
  connect_bd_net -net rst_ps7_0_fclk1_soft_reset [get_bd_pins soft_rst_n] [get_bd_pins pr_0_in0/aresetn] [get_bd_pins pr_0_in1/aresetn] [get_bd_pins pr_0_out0/aresetn] [get_bd_pins pr_0_out1/aresetn] [get_bd_pins pr_1_in0/aresetn] [get_bd_pins pr_1_in1/aresetn] [get_bd_pins pr_1_out0/aresetn] [get_bd_pins pr_1_out1/aresetn] [get_bd_pins pr_fork_in0/aresetn] [get_bd_pins pr_fork_out0/aresetn] [get_bd_pins pr_fork_out1/aresetn] [get_bd_pins pr_join_fifo_in_0/s_axis_aresetn] [get_bd_pins pr_join_fifo_in_1/s_axis_aresetn] [get_bd_pins pr_join_in0/aresetn] [get_bd_pins pr_join_in1/aresetn] [get_bd_pins pr_join_out0/aresetn]
  connect_bd_net -net status_xlconcat_dout [get_bd_pins dfx_status] [get_bd_pins status_xlconcat/dout]
  connect_bd_net -net xlslice_pr_0_Dout [get_bd_pins dfx_decoupler_pr_0/decouple] [get_bd_pins xlslice_pr_0/Dout]
  connect_bd_net -net xlslice_pr_1_Dout [get_bd_pins dfx_decoupler_pr_1/decouple] [get_bd_pins xlslice_pr_1/Dout]
  connect_bd_net -net xlslice_pr_fork_Dout [get_bd_pins dfx_decoupler_pr_fork/decouple] [get_bd_pins xlslice_pr_fork/Dout]
  connect_bd_net -net xlslice_pr_join_Dout [get_bd_pins dfx_decoupler_pr_join/decouple] [get_bd_pins xlslice_pr_join/Dout]

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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M07_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M08_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MM2S

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 RX_DDC_OUT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_INTERCONNECT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 TX_DDC_OUT

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 vid_phy_axi4lite


  # Create pins
  create_bd_pin -dir I -type clk HDMI_RX_CLK_N_IN
  create_bd_pin -dir I -type clk HDMI_RX_CLK_P_IN
  create_bd_pin -dir I -from 2 -to 0 HDMI_RX_DAT_N_IN
  create_bd_pin -dir I -from 2 -to 0 HDMI_RX_DAT_P_IN
  create_bd_pin -dir I HDMI_SI5324_LOL_IN
  create_bd_pin -dir O -type clk HDMI_TX_CLK_N_OUT
  create_bd_pin -dir O -type clk HDMI_TX_CLK_P_OUT
  create_bd_pin -dir O -from 2 -to 0 HDMI_TX_DAT_N_OUT
  create_bd_pin -dir O -from 2 -to 0 HDMI_TX_DAT_P_OUT
  create_bd_pin -dir I RX_DET_IN
  create_bd_pin -dir O RX_HPD_OUT
  create_bd_pin -dir O -type clk RX_REFCLK_N_OUT
  create_bd_pin -dir O -type clk RX_REFCLK_P_OUT
  create_bd_pin -dir I -type rst TX_EN_OUT
  create_bd_pin -dir I TX_HPD_IN
  create_bd_pin -dir I -type clk TX_REFCLK_N_IN
  create_bd_pin -dir I -type clk TX_REFCLK_P_IN
  create_bd_pin -dir I -type clk clk_100MHz
  create_bd_pin -dir I -type rst clk_100MHz_aresetn
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn
  create_bd_pin -dir O -type intr irq_hdmi_in
  create_bd_pin -dir O -type intr irq_hdmi_out
  create_bd_pin -dir O -type intr irq_hdmi_phy
  create_bd_pin -dir O -type intr mm2s_introut
  create_bd_pin -dir O -type intr s2mm_introut

  # Create instance: axi_interconnect, and set properties
  set axi_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {9} \
 ] $axi_interconnect

  # Create instance: axi_vdma, and set properties
  set axi_vdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma ]
  set_property -dict [ list \
   CONFIG.c_addr_width {32} \
   CONFIG.c_m_axi_mm2s_data_width {128} \
   CONFIG.c_m_axi_s2mm_data_width {128} \
   CONFIG.c_m_axis_mm2s_tdata_width {64} \
   CONFIG.c_mm2s_linebuffer_depth {4096} \
   CONFIG.c_mm2s_max_burst_length {256} \
   CONFIG.c_num_fstores {4} \
   CONFIG.c_s2mm_linebuffer_depth {4096} \
   CONFIG.c_s2mm_max_burst_length {256} \
 ] $axi_vdma

  # Create instance: const_gnd, and set properties
  set const_gnd [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_gnd ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $const_gnd

  # Create instance: axi_register_slice, and set properties
  set axi_register_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice ]
  set_property -dict [ list \
   CONFIG.REG_AR {7} \
   CONFIG.REG_AW {7} \
 ] $axi_register_slice

  # Create instance: hdmi_in
  create_hier_cell_hdmi_in $hier_obj hdmi_in

  # Create instance: hdmi_out
  create_hier_cell_hdmi_out $hier_obj hdmi_out

  # Create instance: phy
  create_hier_cell_phy $hier_obj phy

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M07_AXI] [get_bd_intf_pins axi_interconnect/M07_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins M08_AXI] [get_bd_intf_pins axi_interconnect/M08_AXI]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M_AXIS] [get_bd_intf_pins hdmi_in/M_AXIS]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins hdmi_in/S_AXIS]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins M_AXIS1] [get_bd_intf_pins hdmi_out/M_AXIS]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins S_AXIS1] [get_bd_intf_pins hdmi_out/S_AXIS]
  connect_bd_intf_net -intf_net S_AXI_CPU_IN_1 [get_bd_intf_pins axi_interconnect/M00_AXI] [get_bd_intf_pins hdmi_in/S_AXI_CPU_IN]
  connect_bd_intf_net -intf_net S_AXI_CPU_IN_2 [get_bd_intf_pins S_AXI_INTERCONNECT] [get_bd_intf_pins axi_register_slice/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins axi_register_slice/M_AXI] [get_bd_intf_pins axi_interconnect/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M01_AXI [get_bd_intf_pins axi_interconnect/M01_AXI] [get_bd_intf_pins axi_vdma/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_M02_AXI [get_bd_intf_pins axi_interconnect/M02_AXI] [get_bd_intf_pins hdmi_out/S_AXI_CPU_IN]
  connect_bd_intf_net -intf_net axi_interconnect_M03_AXI [get_bd_intf_pins axi_interconnect/M03_AXI] [get_bd_intf_pins hdmi_out/s_axi_control]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins axi_vdma/M_AXIS_MM2S] [get_bd_intf_pins hdmi_out/stream_in_64]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins M_AXI_MM2S] [get_bd_intf_pins axi_vdma/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_vdma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_rx_ss_DDC_OUT [get_bd_intf_pins RX_DDC_OUT] [get_bd_intf_pins hdmi_in/RX_DDC_OUT]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_DDC_OUT [get_bd_intf_pins TX_DDC_OUT] [get_bd_intf_pins hdmi_out/TX_DDC_OUT]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA0_OUT [get_bd_intf_pins hdmi_out/LINK_DATA0_OUT] [get_bd_intf_pins phy/vid_phy_tx_axi4s_ch0]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA1_OUT [get_bd_intf_pins hdmi_out/LINK_DATA1_OUT] [get_bd_intf_pins phy/vid_phy_tx_axi4s_ch1]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_LINK_DATA2_OUT [get_bd_intf_pins hdmi_out/LINK_DATA2_OUT] [get_bd_intf_pins phy/vid_phy_tx_axi4s_ch2]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch0 [get_bd_intf_pins hdmi_in/LINK_DATA0_IN] [get_bd_intf_pins phy/vid_phy_rx_axi4s_ch0]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch1 [get_bd_intf_pins hdmi_in/LINK_DATA1_IN] [get_bd_intf_pins phy/vid_phy_rx_axi4s_ch1]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_rx_axi4s_ch2 [get_bd_intf_pins hdmi_in/LINK_DATA2_IN] [get_bd_intf_pins phy/vid_phy_rx_axi4s_ch2]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_status_sb_rx [get_bd_intf_pins hdmi_in/SB_STATUS_IN] [get_bd_intf_pins phy/vid_phy_status_sb_rx]
  connect_bd_intf_net -intf_net intf_net_vid_phy_controller_vid_phy_status_sb_tx [get_bd_intf_pins hdmi_out/SB_STATUS_IN] [get_bd_intf_pins phy/vid_phy_status_sb_tx]
  connect_bd_intf_net -intf_net intf_net_zynq_us_ss_0_M00_AXI [get_bd_intf_pins vid_phy_axi4lite] [get_bd_intf_pins phy/vid_phy_axi4lite]
  connect_bd_intf_net -intf_net pixel_pack_0_stream_out_64 [get_bd_intf_pins axi_vdma/S_AXIS_S2MM] [get_bd_intf_pins hdmi_in/stream_out_64]
  connect_bd_intf_net -intf_net s_axi_control1_1 [get_bd_intf_pins axi_interconnect/M04_AXI] [get_bd_intf_pins hdmi_out/s_axi_control1]
  connect_bd_intf_net -intf_net s_axi_control1_2 [get_bd_intf_pins axi_interconnect/M06_AXI] [get_bd_intf_pins hdmi_in/s_axi_control1]
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_pins axi_interconnect/M05_AXI] [get_bd_intf_pins hdmi_in/s_axi_control]

  # Create port connections
  connect_bd_net -net axi_vdma_0_mm2s_introut [get_bd_pins mm2s_introut] [get_bd_pins axi_vdma/mm2s_introut]
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins axi_vdma/s2mm_introut]
  connect_bd_net -net ground_dout [get_bd_pins const_gnd/dout] [get_bd_pins hdmi_in/s_axis_audio_aclk] [get_bd_pins hdmi_out/s_axis_audio_aclk]
  connect_bd_net -net net_bdry_in_HDMI_RX_CLK_N_IN [get_bd_pins HDMI_RX_CLK_N_IN] [get_bd_pins phy/HDMI_RX_CLK_N_IN]
  connect_bd_net -net net_bdry_in_HDMI_RX_CLK_P_IN [get_bd_pins HDMI_RX_CLK_P_IN] [get_bd_pins phy/HDMI_RX_CLK_P_IN]
  connect_bd_net -net net_bdry_in_HDMI_RX_DAT_N_IN [get_bd_pins HDMI_RX_DAT_N_IN] [get_bd_pins phy/HDMI_RX_DAT_N_IN]
  connect_bd_net -net net_bdry_in_HDMI_RX_DAT_P_IN [get_bd_pins HDMI_RX_DAT_P_IN] [get_bd_pins phy/HDMI_RX_DAT_P_IN]
  connect_bd_net -net net_bdry_in_HDMI_SI5324_LOL_IN [get_bd_pins HDMI_SI5324_LOL_IN] [get_bd_pins phy/HDMI_SI5324_LOL_IN]
  connect_bd_net -net net_bdry_in_RX_DET_IN [get_bd_pins RX_DET_IN] [get_bd_pins hdmi_in/RX_DET_IN]
  connect_bd_net -net net_bdry_in_TX_HPD_IN [get_bd_pins TX_HPD_IN] [get_bd_pins hdmi_out/TX_HPD_IN]
  connect_bd_net -net net_bdry_in_TX_REFCLK_N_IN [get_bd_pins TX_REFCLK_N_IN] [get_bd_pins phy/TX_REFCLK_N_IN]
  connect_bd_net -net net_bdry_in_TX_REFCLK_P_IN [get_bd_pins TX_REFCLK_P_IN] [get_bd_pins phy/TX_REFCLK_P_IN]
  connect_bd_net -net net_v_hdmi_rx_ss_hpd [get_bd_pins RX_HPD_OUT] [get_bd_pins hdmi_in/RX_HPD_OUT]
  connect_bd_net -net net_v_hdmi_rx_ss_irq [get_bd_pins irq_hdmi_in] [get_bd_pins hdmi_in/irq]
  connect_bd_net -net net_v_hdmi_tx_ss_irq [get_bd_pins irq_hdmi_out] [get_bd_pins hdmi_out/irq1]
  connect_bd_net -net net_vcc_const_dout [get_bd_pins TX_EN_OUT] [get_bd_pins phy/TX_EN_OUT]
  connect_bd_net -net net_vid_phy_controller_irq [get_bd_pins irq_hdmi_phy] [get_bd_pins phy/irq2]
  connect_bd_net -net net_vid_phy_controller_phy_txn_out [get_bd_pins HDMI_TX_DAT_N_OUT] [get_bd_pins phy/HDMI_TX_DAT_N_OUT]
  connect_bd_net -net net_vid_phy_controller_phy_txp_out [get_bd_pins HDMI_TX_DAT_P_OUT] [get_bd_pins phy/HDMI_TX_DAT_P_OUT]
  connect_bd_net -net net_vid_phy_controller_rx_tmds_clk_n [get_bd_pins RX_REFCLK_N_OUT] [get_bd_pins phy/RX_REFCLK_N_OUT]
  connect_bd_net -net net_vid_phy_controller_rx_tmds_clk_p [get_bd_pins RX_REFCLK_P_OUT] [get_bd_pins phy/RX_REFCLK_P_OUT]
  connect_bd_net -net net_vid_phy_controller_rx_video_clk [get_bd_pins hdmi_in/video_clk] [get_bd_pins phy/rx_video_clk]
  connect_bd_net -net net_vid_phy_controller_rxoutclk [get_bd_pins hdmi_in/link_clk] [get_bd_pins phy/vid_phy_rx_axi4s_aclk]
  connect_bd_net -net net_vid_phy_controller_tx_tmds_clk_n [get_bd_pins HDMI_TX_CLK_N_OUT] [get_bd_pins phy/HDMI_TX_CLK_N_OUT]
  connect_bd_net -net net_vid_phy_controller_tx_tmds_clk_p [get_bd_pins HDMI_TX_CLK_P_OUT] [get_bd_pins phy/HDMI_TX_CLK_P_OUT]
  connect_bd_net -net net_vid_phy_controller_tx_video_clk [get_bd_pins hdmi_out/video_clk] [get_bd_pins phy/tx_video_clk]
  connect_bd_net -net net_vid_phy_controller_txoutclk [get_bd_pins hdmi_out/link_clk] [get_bd_pins phy/vid_phy_tx_axi4s_aclk]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins axi_interconnect/M03_ACLK] [get_bd_pins axi_interconnect/M04_ACLK] [get_bd_pins axi_interconnect/M05_ACLK] [get_bd_pins axi_interconnect/M06_ACLK] [get_bd_pins axi_interconnect/M07_ACLK] [get_bd_pins axi_interconnect/M08_ACLK] [get_bd_pins axi_vdma/m_axi_mm2s_aclk] [get_bd_pins axi_vdma/m_axi_s2mm_aclk] [get_bd_pins axi_vdma/m_axis_mm2s_aclk] [get_bd_pins axi_vdma/s_axis_s2mm_aclk] [get_bd_pins hdmi_in/aclk] [get_bd_pins hdmi_out/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axi_interconnect/M03_ARESETN] [get_bd_pins axi_interconnect/M04_ARESETN] [get_bd_pins axi_interconnect/M05_ARESETN] [get_bd_pins axi_interconnect/M06_ARESETN] [get_bd_pins axi_interconnect/M07_ARESETN] [get_bd_pins axi_interconnect/M08_ARESETN] [get_bd_pins hdmi_in/aresetn] [get_bd_pins hdmi_out/aresetn]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins clk_100MHz_aresetn] [get_bd_pins axi_interconnect/ARESETN] [get_bd_pins axi_interconnect/M00_ARESETN] [get_bd_pins axi_interconnect/M01_ARESETN] [get_bd_pins axi_interconnect/M02_ARESETN] [get_bd_pins axi_interconnect/S00_ARESETN] [get_bd_pins axi_vdma/axi_resetn] [get_bd_pins hdmi_in/clk_100MHz_aresetn] [get_bd_pins hdmi_out/clk_100MHz_aresetn] [get_bd_pins phy/clk_100MHz_aresetn] [get_bd_pins axi_register_slice/aresetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins clk_100MHz] [get_bd_pins axi_interconnect/ACLK] [get_bd_pins axi_interconnect/M00_ACLK] [get_bd_pins axi_interconnect/M01_ACLK] [get_bd_pins axi_interconnect/M02_ACLK] [get_bd_pins axi_interconnect/S00_ACLK] [get_bd_pins axi_vdma/s_axi_lite_aclk] [get_bd_pins hdmi_in/clk_100MHz] [get_bd_pins hdmi_out/clk_100MHz] [get_bd_pins phy/clk_100MHz] [get_bd_pins axi_register_slice/aclk]

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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 cam_gpio

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0


  # Create pins
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
   CONFIG.NUM_MI {8} \
 ] $axi_interconnect_1

  # Create instance: axi_vdma, and set properties
  set axi_vdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_include_mm2s_dre {0} \
   CONFIG.c_include_s2mm_dre {0} \
   CONFIG.c_m_axi_mm2s_data_width {64} \
   CONFIG.c_m_axi_s2mm_data_width {128} \
   CONFIG.c_m_axis_mm2s_tdata_width {32} \
   CONFIG.c_mm2s_genlock_mode {0} \
   CONFIG.c_mm2s_linebuffer_depth {512} \
   CONFIG.c_mm2s_max_burst_length {8} \
   CONFIG.c_num_fstores {4} \
   CONFIG.c_s2mm_genlock_mode {2} \
   CONFIG.c_s2mm_linebuffer_depth {4096} \
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

  # Create instance: cam_gpio, and set properties
  set cam_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 cam_gpio ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {1} \
 ] $cam_gpio

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
   CONFIG.C_GPIO_WIDTH {1} \
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
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins cam_gpio] [get_bd_intf_pins cam_gpio/GPIO]
  connect_bd_intf_net -intf_net S_AXI_INTERCONNECT_1 [get_bd_intf_pins S_AXI_INTERCONNECT] [get_bd_intf_pins axi_interconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M00_AXI [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_interconnect/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins axi_vdma/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins axi_interconnect_1/M01_AXI] [get_bd_intf_pins demosaic/s_axi_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_1_M02_AXI [get_bd_intf_pins axi_interconnect_1/M02_AXI] [get_bd_intf_pins gamma_lut/s_axi_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_1_M03_AXI [get_bd_intf_pins axi_interconnect_1/M03_AXI] [get_bd_intf_pins v_proc_sys/s_axi_ctrl]
  connect_bd_intf_net -intf_net axi_interconnect_1_M04_AXI [get_bd_intf_pins axi_interconnect_1/M04_AXI] [get_bd_intf_pins gpio_ip_reset/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M05_AXI [get_bd_intf_pins axi_interconnect_1/M05_AXI] [get_bd_intf_pins cam_gpio/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M06_AXI [get_bd_intf_pins axi_interconnect_1/M06_AXI] [get_bd_intf_pins mipi_csi2_rx_subsyst/csirxss_s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_1_M07_AXI [get_bd_intf_pins axi_interconnect_1/M07_AXI] [get_bd_intf_pins pixel_pack/s_axi_control]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_interconnect/S00_AXI] [get_bd_intf_pins axi_vdma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axis_channel_swap_M_AXIS [get_bd_intf_pins axis_channel_swap/M_AXIS] [get_bd_intf_pins axis_dwidth_48_24/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_24_48_M_AXIS [get_bd_intf_pins axis_dwidth_24_48/M_AXIS] [get_bd_intf_pins pixel_pack/stream_in_48]
  connect_bd_intf_net -intf_net axis_subset_converter_0_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins demosaic/s_axis_video]
  connect_bd_intf_net -intf_net dm0_m_axis_video [get_bd_intf_pins demosaic/m_axis_video] [get_bd_intf_pins gamma_lut/s_axis_video]
  connect_bd_intf_net -intf_net mipi_csi2_rx_subsyst_0_video_out [get_bd_intf_pins axis_subset_converter/S_AXIS] [get_bd_intf_pins mipi_csi2_rx_subsyst/video_out]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_pins mipi_phy_if_0] [get_bd_intf_pins mipi_csi2_rx_subsyst/mipi_phy_if]
  connect_bd_intf_net -intf_net pixel_pack_2_0_stream_out_64 [get_bd_intf_pins axi_vdma/S_AXIS_S2MM] [get_bd_intf_pins pixel_pack/stream_out_64]
  connect_bd_intf_net -intf_net v_proc_sys_m_axis [get_bd_intf_pins axis_channel_swap/S_AXIS] [get_bd_intf_pins v_proc_sys/m_axis]
  connect_bd_intf_net -intf_net vg0_m_axis_video [get_bd_intf_pins gamma_lut/m_axis_video] [get_bd_intf_pins v_proc_sys/s_axis]

  # Create port connections
  connect_bd_net -net axi_gpio_ip_reset_gpio_io_o [get_bd_pins axis_channel_swap/aresetn] [get_bd_pins axis_dwidth_24_48/aresetn] [get_bd_pins axis_dwidth_48_24/aresetn] [get_bd_pins demosaic/ap_rst_n] [get_bd_pins gamma_lut/ap_rst_n] [get_bd_pins gpio_ip_reset/gpio_io_o] [get_bd_pins pixel_pack/ap_rst_n] [get_bd_pins v_proc_sys/aresetn]
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins axi_vdma/s2mm_introut]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins dphy_clk_200M] [get_bd_pins mipi_csi2_rx_subsyst/dphy_clk_200M]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_csirxss_csi_irq [get_bd_pins csirxss_csi_irq] [get_bd_pins mipi_csi2_rx_subsyst/csirxss_csi_irq]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins axi_interconnect/ACLK] [get_bd_pins axi_interconnect/M00_ACLK] [get_bd_pins axi_interconnect/S00_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_1/M02_ACLK] [get_bd_pins axi_interconnect_1/M03_ACLK] [get_bd_pins axi_interconnect_1/M04_ACLK] [get_bd_pins axi_interconnect_1/M07_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_vdma/m_axi_s2mm_aclk] [get_bd_pins axi_vdma/s_axis_s2mm_aclk] [get_bd_pins axis_channel_swap/aclk] [get_bd_pins axis_dwidth_24_48/aclk] [get_bd_pins axis_dwidth_48_24/aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins demosaic/ap_clk] [get_bd_pins gamma_lut/ap_clk] [get_bd_pins gpio_ip_reset/s_axi_aclk] [get_bd_pins mipi_csi2_rx_subsyst/video_aclk] [get_bd_pins pixel_pack/ap_clk] [get_bd_pins v_proc_sys/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axi_interconnect/ARESETN] [get_bd_pins axi_interconnect/M00_ARESETN] [get_bd_pins axi_interconnect/S00_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_1/M02_ARESETN] [get_bd_pins axi_interconnect_1/M03_ARESETN] [get_bd_pins axi_interconnect_1/M04_ARESETN] [get_bd_pins axi_interconnect_1/M07_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins gpio_ip_reset/s_axi_aresetn] [get_bd_pins mipi_csi2_rx_subsyst/video_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins clk_100MHz_aresetn] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/M05_ARESETN] [get_bd_pins axi_interconnect_1/M06_ARESETN] [get_bd_pins axi_vdma/axi_resetn] [get_bd_pins cam_gpio/s_axi_aresetn] [get_bd_pins mipi_csi2_rx_subsyst/lite_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins clk_100MHz] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/M05_ACLK] [get_bd_pins axi_interconnect_1/M06_ACLK] [get_bd_pins axi_vdma/s_axi_lite_aclk] [get_bd_pins cam_gpio/s_axi_aclk] [get_bd_pins mipi_csi2_rx_subsyst/lite_aclk]

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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S13_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CTRL


  # Create pins
  create_bd_pin -dir I -type clk clk_300MHz
  create_bd_pin -dir I -type rst clk_300MHz_aresetn

  # Create instance: axis_data_fifo_join_0, and set properties
  set axis_data_fifo_join_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_join_0 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {8192} \
   CONFIG.FIFO_MEMORY_TYPE {ultra} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_data_fifo_join_0

  # Create instance: axis_data_fifo_join_1, and set properties
  set axis_data_fifo_join_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_join_1 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {16384} \
   CONFIG.FIFO_MEMORY_TYPE {ultra} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_data_fifo_join_1

  # Create instance: axis_data_fifo_tx_path, and set properties
  set axis_data_fifo_tx_path [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_tx_path ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {4096} \
   CONFIG.FIFO_MEMORY_TYPE {ultra} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.TDATA_NUM_BYTES {6} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_data_fifo_tx_path

  # Create instance: axis_downconv_join_0, and set properties
  set axis_downconv_join_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_downconv_join_0 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {0} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {3} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_downconv_join_0

  # Create instance: axis_downconv_join_1, and set properties
  set axis_downconv_join_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_downconv_join_1 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {0} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {3} \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_downconv_join_1

  # Create instance: axis_switch, and set properties
  set axis_switch [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch ]
  set_property -dict [ list \
   CONFIG.DECODER_REG {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.NUM_MI {16} \
   CONFIG.NUM_SI {16} \
   CONFIG.ROUTING_MODE {1} \
   CONFIG.TDATA_NUM_BYTES {3} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {1} \
 ] $axis_switch

  # Create instance: axis_upconv_join_0, and set properties
  set axis_upconv_join_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_upconv_join_0 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_upconv_join_0

  # Create instance: axis_upconv_join_1, and set properties
  set axis_upconv_join_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_upconv_join_1 ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_upconv_join_1

  # Create instance: axis_upconv_tx_path, and set properties
  set axis_upconv_tx_path [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_upconv_tx_path ]
  set_property -dict [ list \
   CONFIG.HAS_MI_TKEEP {1} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.M_TDATA_NUM_BYTES {6} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TUSER_BITS_PER_BYTE {1} \
 ] $axis_upconv_tx_path

  # Create instance: colorthresholding_accel, and set properties
  set colorthresholding_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:colorthresholding_accel:1.0 colorthresholding_accel ]

  # Create instance: dfx_decouplers
  create_hier_cell_dfx_decouplers $hier_obj dfx_decouplers

  # Create instance: filter2d_accel, and set properties
  set filter2d_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:filter2d_accel:1.0 filter2d_accel ]

  # Create instance: gray2rgb_accel, and set properties
  set gray2rgb_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:gray2rgb_accel:1.0 gray2rgb_accel ]

  # Create instance: lut_accel, and set properties
  set lut_accel [ create_bd_cell -type ip -vlnv xilinx.com:hls:LUT_accel:1.0 lut_accel ]

  # Create instance: pipeline_control, and set properties
  set pipeline_control [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 pipeline_control ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS_2 {0} \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO2_WIDTH {8} \
   CONFIG.C_GPIO_WIDTH {1} \
   CONFIG.C_IS_DUAL {1} \
 ] $pipeline_control

  # Create instance: pr_0
  create_hier_cell_pr_0 $hier_obj pr_0

  # Create instance: pr_1
  create_hier_cell_pr_1 $hier_obj pr_1

  # Create instance: pr_fork
  create_hier_cell_pr_fork $hier_obj pr_fork

  # Create instance: pr_join
  create_hier_cell_pr_join $hier_obj pr_join

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
   CONFIG.NUM_MI {7} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect

  # Create instance: axi_register_slice, and set properties
  set axi_register_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice ]
  set_property -dict [ list \
   CONFIG.REG_AR {7} \
   CONFIG.REG_AW {7} \
 ] $axi_register_slice

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M02_AXIS] [get_bd_intf_pins axis_switch/M02_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S02_AXIS] [get_bd_intf_pins axis_switch/S02_AXIS]
  connect_bd_intf_net -intf_net LUT_accel_stream_out [get_bd_intf_pins axis_switch/S03_AXIS] [get_bd_intf_pins lut_accel/stream_out]
  connect_bd_intf_net -intf_net S13_AXI_1 [get_bd_intf_pins S13_AXI] [get_bd_intf_pins dfx_decouplers/S13_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M07_AXI [get_bd_intf_pins S_AXI_CTRL] [get_bd_intf_pins axis_switch/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_M08_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_register_slice/S_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins axi_register_slice/M_AXI] [get_bd_intf_pins smartconnect/S00_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_join_0_M_AXIS [get_bd_intf_pins axis_data_fifo_join_0/M_AXIS] [get_bd_intf_pins axis_downconv_join_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_join_1_M_AXIS [get_bd_intf_pins axis_data_fifo_join_1/M_AXIS] [get_bd_intf_pins axis_downconv_join_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_tx_path_M_AXIS [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins axis_data_fifo_tx_path/M_AXIS]
  connect_bd_intf_net -intf_net axis_downconv_join_0_M_AXIS [get_bd_intf_pins axis_downconv_join_0/M_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_join_0]
  connect_bd_intf_net -intf_net axis_downconv_join_1_M_AXIS [get_bd_intf_pins axis_downconv_join_1/M_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_join_1]
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins axis_data_fifo_tx_path/S_AXIS] [get_bd_intf_pins axis_upconv_tx_path/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_1_M_AXIS [get_bd_intf_pins axis_data_fifo_join_0/S_AXIS] [get_bd_intf_pins axis_upconv_join_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_2_M_AXIS [get_bd_intf_pins axis_data_fifo_join_1/S_AXIS] [get_bd_intf_pins axis_upconv_join_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M00_AXIS [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_switch/M00_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M01_AXIS [get_bd_intf_pins axis_switch/M01_AXIS] [get_bd_intf_pins axis_upconv_tx_path/S_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M03_AXIS [get_bd_intf_pins axis_switch/M03_AXIS] [get_bd_intf_pins lut_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M04_AXIS [get_bd_intf_pins axis_switch/M04_AXIS] [get_bd_intf_pins rgb2gray_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M05_AXIS [get_bd_intf_pins axis_switch/M05_AXIS] [get_bd_intf_pins gray2rgb_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M06_AXIS [get_bd_intf_pins axis_switch/M06_AXIS] [get_bd_intf_pins rgb2hsv_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M07_AXIS [get_bd_intf_pins axis_switch/M07_AXIS] [get_bd_intf_pins colorthresholding_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M08_AXIS [get_bd_intf_pins axis_switch/M08_AXIS] [get_bd_intf_pins filter2d_accel/stream_in]
  connect_bd_intf_net -intf_net axis_switch_M09_AXIS [get_bd_intf_pins axis_switch/M09_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_0_0]
  connect_bd_intf_net -intf_net axis_switch_M10_AXIS [get_bd_intf_pins axis_switch/M10_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_0_1]
  connect_bd_intf_net -intf_net axis_switch_M11_AXIS [get_bd_intf_pins axis_switch/M11_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_1_0]
  connect_bd_intf_net -intf_net axis_switch_M12_AXIS [get_bd_intf_pins axis_switch/M12_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_1_1]
  connect_bd_intf_net -intf_net axis_switch_M13_AXIS [get_bd_intf_pins axis_switch/M13_AXIS] [get_bd_intf_pins dfx_decouplers/s_axis_dfx_pr_fork]
  connect_bd_intf_net -intf_net axis_switch_M14_AXIS [get_bd_intf_pins axis_switch/M14_AXIS] [get_bd_intf_pins axis_upconv_join_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_switch_M15_AXIS [get_bd_intf_pins axis_switch/M15_AXIS] [get_bd_intf_pins axis_upconv_join_1/S_AXIS]
  connect_bd_intf_net -intf_net colorthresholding_accel_stream_out [get_bd_intf_pins axis_switch/S07_AXIS] [get_bd_intf_pins colorthresholding_accel/stream_out]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_0_0 [get_bd_intf_pins axis_switch/S09_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_0_0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_0_1 [get_bd_intf_pins axis_switch/S10_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_0_1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_1_0 [get_bd_intf_pins axis_switch/S11_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_1_0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_1_1 [get_bd_intf_pins axis_switch/S12_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_1_1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_fork_0 [get_bd_intf_pins axis_switch/S13_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_fork_0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_fork_1 [get_bd_intf_pins axis_switch/S14_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_fork_1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_dfx_pr_join [get_bd_intf_pins axis_switch/S15_AXIS] [get_bd_intf_pins dfx_decouplers/m_axis_dfx_pr_join]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_0 [get_bd_intf_pins dfx_decouplers/m_axis_pr_0_0] [get_bd_intf_pins pr_0/stream_in1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_0_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_0_1] [get_bd_intf_pins pr_0/stream_in0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_1_0 [get_bd_intf_pins dfx_decouplers/m_axis_pr_1_0] [get_bd_intf_pins pr_1/stream_in0]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_1_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_1_1] [get_bd_intf_pins pr_1/stream_in1]
  connect_bd_intf_net -intf_net dfx_decouplers_m_axis_pr_fork [get_bd_intf_pins dfx_decouplers/m_axis_pr_fork] [get_bd_intf_pins pr_fork/stream_in0]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_0_0 [get_bd_intf_pins dfx_decouplers/s_axi_pr_0_0] [get_bd_intf_pins pr_0/s_axi_control1]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_0_1 [get_bd_intf_pins dfx_decouplers/s_axi_pr_0_1] [get_bd_intf_pins pr_0/s_axi_control0]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_1_0 [get_bd_intf_pins dfx_decouplers/s_axi_pr_1_0] [get_bd_intf_pins pr_1/s_axi_control0]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_1_1 [get_bd_intf_pins dfx_decouplers/s_axi_pr_1_1] [get_bd_intf_pins pr_1/s_axi_control1]
  connect_bd_intf_net -intf_net dfx_decouplers_s_axi_pr_fork [get_bd_intf_pins dfx_decouplers/s_axi_pr_fork] [get_bd_intf_pins pr_fork/s_axi_control]
  connect_bd_intf_net -intf_net dilate_accel_0_stream_out [get_bd_intf_pins dfx_decouplers/s_axis_pr_0_0] [get_bd_intf_pins pr_0/stream_out1]
  connect_bd_intf_net -intf_net erode_accel_0_stream_out [get_bd_intf_pins dfx_decouplers/s_axis_pr_0_1] [get_bd_intf_pins pr_0/stream_out0]
  connect_bd_intf_net -intf_net filter2d_accel_stream_out [get_bd_intf_pins axis_switch/S08_AXIS] [get_bd_intf_pins filter2d_accel/stream_out]
  connect_bd_intf_net -intf_net gray2rgb_accel_stream_out [get_bd_intf_pins axis_switch/S05_AXIS] [get_bd_intf_pins gray2rgb_accel/stream_out]
  connect_bd_intf_net -intf_net hdmi_in_M_AXIS [get_bd_intf_pins S00_AXIS] [get_bd_intf_pins axis_switch/S00_AXIS]
  connect_bd_intf_net -intf_net hdmi_out_M_AXIS [get_bd_intf_pins S01_AXIS] [get_bd_intf_pins axis_switch/S01_AXIS]
  connect_bd_intf_net -intf_net pr_1_stream_out0 [get_bd_intf_pins dfx_decouplers/s_axis_pr_1_0] [get_bd_intf_pins pr_1/stream_out0]
  connect_bd_intf_net -intf_net pr_1_stream_out1 [get_bd_intf_pins dfx_decouplers/s_axis_pr_1_1] [get_bd_intf_pins pr_1/stream_out1]
  connect_bd_intf_net -intf_net pr_fork_stream_out0 [get_bd_intf_pins dfx_decouplers/s_pr_fork_0] [get_bd_intf_pins pr_fork/stream_out0]
  connect_bd_intf_net -intf_net pr_fork_stream_out1 [get_bd_intf_pins dfx_decouplers/s_pr_fork_1] [get_bd_intf_pins pr_fork/stream_out1]
  connect_bd_intf_net -intf_net pr_join_stream_out0 [get_bd_intf_pins dfx_decouplers/s_axis_pr_join] [get_bd_intf_pins pr_join/stream_out0]
  connect_bd_intf_net -intf_net rgb2gray_accel_stream_out [get_bd_intf_pins axis_switch/S04_AXIS] [get_bd_intf_pins rgb2gray_accel/stream_out]
  connect_bd_intf_net -intf_net rgb2hsv_accel_stream_out [get_bd_intf_pins axis_switch/S06_AXIS] [get_bd_intf_pins rgb2hsv_accel/stream_out]
  connect_bd_intf_net -intf_net s_axi_control_1 [get_bd_intf_pins dfx_decouplers/s_axi_pr_join] [get_bd_intf_pins pr_join/s_axi_control]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins lut_accel/s_axi_control] [get_bd_intf_pins smartconnect/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins filter2d_accel/s_axi_control] [get_bd_intf_pins smartconnect/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins rgb2gray_accel/s_axi_control] [get_bd_intf_pins smartconnect/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins gray2rgb_accel/s_axi_control] [get_bd_intf_pins smartconnect/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins rgb2hsv_accel/s_axi_control] [get_bd_intf_pins smartconnect/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins colorthresholding_accel/s_axi_control] [get_bd_intf_pins smartconnect/M05_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M06_AXI [get_bd_intf_pins pipeline_control/S_AXI] [get_bd_intf_pins smartconnect/M06_AXI]
  connect_bd_intf_net -intf_net stream_in0_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_join_0] [get_bd_intf_pins pr_join/stream_in0]
  connect_bd_intf_net -intf_net stream_in1_1 [get_bd_intf_pins dfx_decouplers/m_axis_pr_join_1] [get_bd_intf_pins pr_join/stream_in1]

  # Create port connections
  connect_bd_net -net axi_control_gpio_io_o [get_bd_pins pipeline_control/gpio_io_o] [get_bd_pins ps_user_soft_reset/aux_reset_in]
  connect_bd_net -net dfx_decouplers_dfx_status [get_bd_pins dfx_decouplers/dfx_status] [get_bd_pins pipeline_control/gpio2_io_i]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins clk_300MHz] [get_bd_pins axis_data_fifo_join_0/s_axis_aclk] [get_bd_pins axis_data_fifo_join_1/s_axis_aclk] [get_bd_pins axis_data_fifo_tx_path/s_axis_aclk] [get_bd_pins axis_downconv_join_0/aclk] [get_bd_pins axis_downconv_join_1/aclk] [get_bd_pins axis_switch/aclk] [get_bd_pins axis_switch/s_axi_ctrl_aclk] [get_bd_pins axis_upconv_join_0/aclk] [get_bd_pins axis_upconv_join_1/aclk] [get_bd_pins axis_upconv_tx_path/aclk] [get_bd_pins colorthresholding_accel/ap_clk] [get_bd_pins dfx_decouplers/clk_300MHz] [get_bd_pins filter2d_accel/ap_clk] [get_bd_pins gray2rgb_accel/ap_clk] [get_bd_pins lut_accel/ap_clk] [get_bd_pins pipeline_control/s_axi_aclk] [get_bd_pins pr_0/clk_300MHz] [get_bd_pins pr_1/clk_300MHz] [get_bd_pins pr_fork/clk_300MHz] [get_bd_pins pr_join/clk_300MHz] [get_bd_pins ps_user_soft_reset/slowest_sync_clk] [get_bd_pins rgb2gray_accel/ap_clk] [get_bd_pins rgb2hsv_accel/ap_clk] [get_bd_pins smartconnect/aclk] [get_bd_pins axi_register_slice/aclk]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins clk_300MHz_aresetn] [get_bd_pins axis_switch/aresetn] [get_bd_pins axis_switch/s_axi_ctrl_aresetn] [get_bd_pins dfx_decouplers/clk_300MHz_aresetn] [get_bd_pins pipeline_control/s_axi_aresetn] [get_bd_pins ps_user_soft_reset/ext_reset_in] [get_bd_pins smartconnect/aresetn] [get_bd_pins axi_register_slice/aresetn]
  connect_bd_net -net net_zynq_us_ss_soft_reset [get_bd_pins axis_data_fifo_join_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_join_1/s_axis_aresetn] [get_bd_pins axis_data_fifo_tx_path/s_axis_aresetn] [get_bd_pins axis_downconv_join_0/aresetn] [get_bd_pins axis_downconv_join_1/aresetn] [get_bd_pins axis_upconv_join_0/aresetn] [get_bd_pins axis_upconv_join_1/aresetn] [get_bd_pins axis_upconv_tx_path/aresetn] [get_bd_pins colorthresholding_accel/ap_rst_n] [get_bd_pins dfx_decouplers/soft_rst_n] [get_bd_pins filter2d_accel/ap_rst_n] [get_bd_pins gray2rgb_accel/ap_rst_n] [get_bd_pins lut_accel/ap_rst_n] [get_bd_pins pr_0/clk_300MHz_aresetn] [get_bd_pins pr_1/clk_300MHz_aresetn] [get_bd_pins pr_fork/clk_300MHz_aresetn] [get_bd_pins pr_join/clk_300MHz_aresetn] [get_bd_pins ps_user_soft_reset/peripheral_aresetn] [get_bd_pins rgb2gray_accel/ap_rst_n] [get_bd_pins rgb2hsv_accel/ap_rst_n]
  connect_bd_net -net pipeline_control_gpio2_io_o [get_bd_pins dfx_decouplers/dfx_decouple] [get_bd_pins pipeline_control/gpio2_io_o]

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
  set HDMI_CTL_iic [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 HDMI_CTL_iic ]

  set RX_DDC_OUT [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 RX_DDC_OUT ]

  set TX_DDC_OUT [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 TX_DDC_OUT ]

  set cam_gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 cam_gpio ]

  set dip_switch_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 dip_switch_4bits ]

  set led_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_4bits ]

  set mipi_phy_if_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0 ]

  set push_button_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 push_button_4bits ]

  set rgbleds [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 rgbleds ]


  # Create ports
  set HDMI_RX_CLK_N_IN [ create_bd_port -dir I HDMI_RX_CLK_N_IN ]
  set HDMI_RX_CLK_P_IN [ create_bd_port -dir I HDMI_RX_CLK_P_IN ]
  set HDMI_RX_DAT_N_IN [ create_bd_port -dir I -from 2 -to 0 HDMI_RX_DAT_N_IN ]
  set HDMI_RX_DAT_P_IN [ create_bd_port -dir I -from 2 -to 0 HDMI_RX_DAT_P_IN ]
  set HDMI_SI5324_LOL_IN [ create_bd_port -dir I HDMI_SI5324_LOL_IN ]
  set HDMI_SI5324_RST_OUT [ create_bd_port -dir O -from 0 -to 0 HDMI_SI5324_RST_OUT ]
  set HDMI_TX_CLK_N_OUT [ create_bd_port -dir O HDMI_TX_CLK_N_OUT ]
  set HDMI_TX_CLK_P_OUT [ create_bd_port -dir O HDMI_TX_CLK_P_OUT ]
  set HDMI_TX_DAT_N_OUT [ create_bd_port -dir O -from 2 -to 0 HDMI_TX_DAT_N_OUT ]
  set HDMI_TX_DAT_P_OUT [ create_bd_port -dir O -from 2 -to 0 HDMI_TX_DAT_P_OUT ]
  set HDMI_TX_LS_OE [ create_bd_port -dir O -from 0 -to 0 HDMI_TX_LS_OE ]
  set RX_DET_IN [ create_bd_port -dir I RX_DET_IN ]
  set RX_HPD_OUT [ create_bd_port -dir O RX_HPD_OUT ]
  set RX_REFCLK_N_OUT [ create_bd_port -dir O RX_REFCLK_N_OUT ]
  set RX_REFCLK_P_OUT [ create_bd_port -dir O RX_REFCLK_P_OUT ]
  set TX_EN_OUT [ create_bd_port -dir O -from 0 -to 0 TX_EN_OUT ]
  set TX_HPD_IN [ create_bd_port -dir I TX_HPD_IN ]
  set TX_REFCLK_N_IN [ create_bd_port -dir I TX_REFCLK_N_IN ]
  set TX_REFCLK_P_IN [ create_bd_port -dir I TX_REFCLK_P_IN ]

  # Create instance: HDMI_CTL_axi_iic, and set properties
  set HDMI_CTL_axi_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 HDMI_CTL_axi_iic ]
  set_property -dict [ list \
   CONFIG.C_SCL_INERTIAL_DELAY {10} \
   CONFIG.C_SDA_INERTIAL_DELAY {10} \
   CONFIG.IIC_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $HDMI_CTL_axi_iic

  # Create instance: axi_intc, and set properties
  set axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc ]
  set_property -dict [ list \
   CONFIG.C_IRQ_CONNECTION {1} \
 ] $axi_intc

  # Create instance: xlconcat_int, and set properties
  set xlconcat_int [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_int ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {1} \
 ] $xlconcat_int

  # Create instance: axi_interconnect, and set properties
  set axi_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {14} \
 ] $axi_interconnect

  # Create instance: axi_mem_intercon, and set properties
  set axi_mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $axi_mem_intercon

  # Create instance: axi_mem_intercon_1, and set properties
  set axi_mem_intercon_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $axi_mem_intercon_1

  # Create instance: btns_gpio, and set properties
  set btns_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 btns_gpio ]
  set_property -dict [ list \
   CONFIG.C_INTERRUPT_PRESENT {1} \
   CONFIG.GPIO_BOARD_INTERFACE {push_button_4bits} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $btns_gpio

  # Create instance: composable
  create_hier_cell_composable [current_bd_instance .] composable

  # Create instance: leds_gpio, and set properties
  set leds_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 leds_gpio ]
  set_property -dict [ list \
   CONFIG.C_INTERRUPT_PRESENT {0} \
   CONFIG.GPIO_BOARD_INTERFACE {led_4bits} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $leds_gpio

  # Create instance: mipi
  create_hier_cell_mipi [current_bd_instance .] mipi

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

  # Create instance: ps_e_0, and set properties
  set ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 ps_e_0 ]
  set_property -dict [ list \
   CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS33} \
   CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
   CONFIG.PSU_DDR_RAM_HIGHADDR {0xFFFFFFFF} \
   CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
   CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
   CONFIG.PSU_DYNAMIC_DDR_CONFIG_EN {0} \
   CONFIG.PSU_MIO_0_DIRECTION {inout} \
   CONFIG.PSU_MIO_0_POLARITY {Default} \
   CONFIG.PSU_MIO_10_DIRECTION {inout} \
   CONFIG.PSU_MIO_10_POLARITY {Default} \
   CONFIG.PSU_MIO_11_DIRECTION {inout} \
   CONFIG.PSU_MIO_11_POLARITY {Default} \
   CONFIG.PSU_MIO_12_DIRECTION {inout} \
   CONFIG.PSU_MIO_12_POLARITY {Default} \
   CONFIG.PSU_MIO_13_DIRECTION {inout} \
   CONFIG.PSU_MIO_13_POLARITY {Default} \
   CONFIG.PSU_MIO_14_DIRECTION {inout} \
   CONFIG.PSU_MIO_14_POLARITY {Default} \
   CONFIG.PSU_MIO_15_DIRECTION {inout} \
   CONFIG.PSU_MIO_15_POLARITY {Default} \
   CONFIG.PSU_MIO_16_DIRECTION {inout} \
   CONFIG.PSU_MIO_16_POLARITY {Default} \
   CONFIG.PSU_MIO_17_DIRECTION {inout} \
   CONFIG.PSU_MIO_17_POLARITY {Default} \
   CONFIG.PSU_MIO_18_DIRECTION {inout} \
   CONFIG.PSU_MIO_18_POLARITY {Default} \
   CONFIG.PSU_MIO_19_DIRECTION {inout} \
   CONFIG.PSU_MIO_19_POLARITY {Default} \
   CONFIG.PSU_MIO_1_DIRECTION {inout} \
   CONFIG.PSU_MIO_1_POLARITY {Default} \
   CONFIG.PSU_MIO_20_DIRECTION {inout} \
   CONFIG.PSU_MIO_20_POLARITY {Default} \
   CONFIG.PSU_MIO_21_DIRECTION {inout} \
   CONFIG.PSU_MIO_21_POLARITY {Default} \
   CONFIG.PSU_MIO_22_DIRECTION {out} \
   CONFIG.PSU_MIO_22_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_22_POLARITY {Default} \
   CONFIG.PSU_MIO_23_DIRECTION {inout} \
   CONFIG.PSU_MIO_23_POLARITY {Default} \
   CONFIG.PSU_MIO_24_DIRECTION {in} \
   CONFIG.PSU_MIO_24_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_24_POLARITY {Default} \
   CONFIG.PSU_MIO_24_SLEW {fast} \
   CONFIG.PSU_MIO_25_POLARITY {Default} \
   CONFIG.PSU_MIO_26_DIRECTION {inout} \
   CONFIG.PSU_MIO_26_POLARITY {Default} \
   CONFIG.PSU_MIO_27_DIRECTION {out} \
   CONFIG.PSU_MIO_27_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_27_POLARITY {Default} \
   CONFIG.PSU_MIO_28_DIRECTION {in} \
   CONFIG.PSU_MIO_28_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_28_POLARITY {Default} \
   CONFIG.PSU_MIO_28_SLEW {fast} \
   CONFIG.PSU_MIO_29_DIRECTION {out} \
   CONFIG.PSU_MIO_29_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_29_POLARITY {Default} \
   CONFIG.PSU_MIO_2_DIRECTION {inout} \
   CONFIG.PSU_MIO_2_POLARITY {Default} \
   CONFIG.PSU_MIO_30_DIRECTION {in} \
   CONFIG.PSU_MIO_30_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_30_POLARITY {Default} \
   CONFIG.PSU_MIO_30_SLEW {fast} \
   CONFIG.PSU_MIO_31_DIRECTION {inout} \
   CONFIG.PSU_MIO_31_POLARITY {Default} \
   CONFIG.PSU_MIO_32_DIRECTION {inout} \
   CONFIG.PSU_MIO_32_POLARITY {Default} \
   CONFIG.PSU_MIO_33_DIRECTION {inout} \
   CONFIG.PSU_MIO_33_POLARITY {Default} \
   CONFIG.PSU_MIO_34_DIRECTION {in} \
   CONFIG.PSU_MIO_34_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_34_POLARITY {Default} \
   CONFIG.PSU_MIO_34_SLEW {fast} \
   CONFIG.PSU_MIO_35_DIRECTION {out} \
   CONFIG.PSU_MIO_35_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_35_POLARITY {Default} \
   CONFIG.PSU_MIO_36_DIRECTION {inout} \
   CONFIG.PSU_MIO_36_POLARITY {Default} \
   CONFIG.PSU_MIO_37_DIRECTION {inout} \
   CONFIG.PSU_MIO_37_POLARITY {Default} \
   CONFIG.PSU_MIO_38_DIRECTION {inout} \
   CONFIG.PSU_MIO_38_POLARITY {Default} \
   CONFIG.PSU_MIO_39_DIRECTION {inout} \
   CONFIG.PSU_MIO_39_POLARITY {Default} \
   CONFIG.PSU_MIO_3_DIRECTION {inout} \
   CONFIG.PSU_MIO_3_POLARITY {Default} \
   CONFIG.PSU_MIO_40_DIRECTION {inout} \
   CONFIG.PSU_MIO_40_POLARITY {Default} \
   CONFIG.PSU_MIO_41_DIRECTION {inout} \
   CONFIG.PSU_MIO_41_POLARITY {Default} \
   CONFIG.PSU_MIO_42_DIRECTION {inout} \
   CONFIG.PSU_MIO_42_POLARITY {Default} \
   CONFIG.PSU_MIO_43_DIRECTION {inout} \
   CONFIG.PSU_MIO_43_POLARITY {Default} \
   CONFIG.PSU_MIO_44_DIRECTION {inout} \
   CONFIG.PSU_MIO_44_POLARITY {Default} \
   CONFIG.PSU_MIO_45_DIRECTION {inout} \
   CONFIG.PSU_MIO_45_POLARITY {Default} \
   CONFIG.PSU_MIO_46_DIRECTION {inout} \
   CONFIG.PSU_MIO_46_POLARITY {Default} \
   CONFIG.PSU_MIO_47_DIRECTION {inout} \
   CONFIG.PSU_MIO_47_POLARITY {Default} \
   CONFIG.PSU_MIO_48_DIRECTION {inout} \
   CONFIG.PSU_MIO_48_POLARITY {Default} \
   CONFIG.PSU_MIO_49_DIRECTION {inout} \
   CONFIG.PSU_MIO_49_POLARITY {Default} \
   CONFIG.PSU_MIO_4_DIRECTION {inout} \
   CONFIG.PSU_MIO_4_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_4_POLARITY {Default} \
   CONFIG.PSU_MIO_50_DIRECTION {inout} \
   CONFIG.PSU_MIO_50_POLARITY {Default} \
   CONFIG.PSU_MIO_51_DIRECTION {out} \
   CONFIG.PSU_MIO_51_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_51_POLARITY {Default} \
   CONFIG.PSU_MIO_52_DIRECTION {in} \
   CONFIG.PSU_MIO_52_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_52_POLARITY {Default} \
   CONFIG.PSU_MIO_52_SLEW {fast} \
   CONFIG.PSU_MIO_53_DIRECTION {in} \
   CONFIG.PSU_MIO_53_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_53_POLARITY {Default} \
   CONFIG.PSU_MIO_53_SLEW {fast} \
   CONFIG.PSU_MIO_54_DIRECTION {inout} \
   CONFIG.PSU_MIO_54_POLARITY {Default} \
   CONFIG.PSU_MIO_55_DIRECTION {in} \
   CONFIG.PSU_MIO_55_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_55_POLARITY {Default} \
   CONFIG.PSU_MIO_55_SLEW {fast} \
   CONFIG.PSU_MIO_56_DIRECTION {inout} \
   CONFIG.PSU_MIO_56_POLARITY {Default} \
   CONFIG.PSU_MIO_57_DIRECTION {inout} \
   CONFIG.PSU_MIO_57_POLARITY {Default} \
   CONFIG.PSU_MIO_58_DIRECTION {out} \
   CONFIG.PSU_MIO_58_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_58_POLARITY {Default} \
   CONFIG.PSU_MIO_59_DIRECTION {inout} \
   CONFIG.PSU_MIO_59_POLARITY {Default} \
   CONFIG.PSU_MIO_5_DIRECTION {inout} \
   CONFIG.PSU_MIO_5_POLARITY {Default} \
   CONFIG.PSU_MIO_60_DIRECTION {inout} \
   CONFIG.PSU_MIO_60_POLARITY {Default} \
   CONFIG.PSU_MIO_61_DIRECTION {inout} \
   CONFIG.PSU_MIO_61_POLARITY {Default} \
   CONFIG.PSU_MIO_62_DIRECTION {inout} \
   CONFIG.PSU_MIO_62_POLARITY {Default} \
   CONFIG.PSU_MIO_63_DIRECTION {inout} \
   CONFIG.PSU_MIO_63_POLARITY {Default} \
   CONFIG.PSU_MIO_64_DIRECTION {in} \
   CONFIG.PSU_MIO_64_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_64_POLARITY {Default} \
   CONFIG.PSU_MIO_64_SLEW {fast} \
   CONFIG.PSU_MIO_65_DIRECTION {in} \
   CONFIG.PSU_MIO_65_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_65_POLARITY {Default} \
   CONFIG.PSU_MIO_65_SLEW {fast} \
   CONFIG.PSU_MIO_66_DIRECTION {inout} \
   CONFIG.PSU_MIO_66_POLARITY {Default} \
   CONFIG.PSU_MIO_67_DIRECTION {in} \
   CONFIG.PSU_MIO_67_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_67_POLARITY {Default} \
   CONFIG.PSU_MIO_67_SLEW {fast} \
   CONFIG.PSU_MIO_68_DIRECTION {inout} \
   CONFIG.PSU_MIO_68_POLARITY {Default} \
   CONFIG.PSU_MIO_69_DIRECTION {inout} \
   CONFIG.PSU_MIO_69_POLARITY {Default} \
   CONFIG.PSU_MIO_6_DIRECTION {inout} \
   CONFIG.PSU_MIO_6_POLARITY {Default} \
   CONFIG.PSU_MIO_70_DIRECTION {out} \
   CONFIG.PSU_MIO_70_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_70_POLARITY {Default} \
   CONFIG.PSU_MIO_71_DIRECTION {inout} \
   CONFIG.PSU_MIO_71_POLARITY {Default} \
   CONFIG.PSU_MIO_72_DIRECTION {inout} \
   CONFIG.PSU_MIO_72_POLARITY {Default} \
   CONFIG.PSU_MIO_73_DIRECTION {inout} \
   CONFIG.PSU_MIO_73_POLARITY {Default} \
   CONFIG.PSU_MIO_74_DIRECTION {inout} \
   CONFIG.PSU_MIO_74_POLARITY {Default} \
   CONFIG.PSU_MIO_75_DIRECTION {inout} \
   CONFIG.PSU_MIO_75_POLARITY {Default} \
   CONFIG.PSU_MIO_76_DIRECTION {inout} \
   CONFIG.PSU_MIO_76_POLARITY {Default} \
   CONFIG.PSU_MIO_77_DIRECTION {inout} \
   CONFIG.PSU_MIO_77_POLARITY {Default} \
   CONFIG.PSU_MIO_7_DIRECTION {inout} \
   CONFIG.PSU_MIO_7_POLARITY {Default} \
   CONFIG.PSU_MIO_8_DIRECTION {out} \
   CONFIG.PSU_MIO_8_INPUT_TYPE {cmos} \
   CONFIG.PSU_MIO_8_POLARITY {Default} \
   CONFIG.PSU_MIO_9_DIRECTION {in} \
   CONFIG.PSU_MIO_9_DRIVE_STRENGTH {12} \
   CONFIG.PSU_MIO_9_POLARITY {Default} \
   CONFIG.PSU_MIO_9_SLEW {fast} \
   CONFIG.PSU_MIO_TREE_PERIPHERALS {I2C 1#I2C 1#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#UART 1#UART 1#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#SD 0#SD 0#SD 0#SD 0#GPIO0 MIO#I2C 0#I2C 0#GPIO0 MIO#SD 0#SD 0#GPIO0 MIO#SD 0#USB0 Reset#GPIO1 MIO#DPAUX#DPAUX#DPAUX#DPAUX#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#UART 0#UART 0#GPIO1 MIO#GPIO1 MIO#SPI 0#GPIO1 MIO#GPIO1 MIO#SPI 0#SPI 0#SPI 0#GPIO1 MIO#GPIO1 MIO#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#GPIO2 MIO#GPIO2 MIO} \
   CONFIG.PSU_MIO_TREE_SIGNALS {scl_out#sda_out#gpio0[2]#gpio0[3]#gpio0[4]#gpio0[5]#gpio0[6]#gpio0[7]#txd#rxd#gpio0[10]#gpio0[11]#gpio0[12]#sdio0_data_out[0]#sdio0_data_out[1]#sdio0_data_out[2]#sdio0_data_out[3]#gpio0[17]#scl_out#sda_out#gpio0[20]#sdio0_cmd_out#sdio0_clk_out#gpio0[23]#sdio0_cd_n#reset#gpio1[26]#dp_aux_data_out#dp_hot_plug_detect#dp_aux_data_oe#dp_aux_data_in#gpio1[31]#gpio1[32]#gpio1[33]#rxd#txd#gpio1[36]#gpio1[37]#sclk_out#gpio1[39]#gpio1[40]#n_ss_out[0]#miso#mosi#gpio1[44]#gpio1[45]#sdio1_data_out[0]#sdio1_data_out[1]#sdio1_data_out[2]#sdio1_data_out[3]#sdio1_cmd_out#sdio1_clk_out#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#gpio2[76]#gpio2[77]} \
   CONFIG.PSU_SD0_INTERNAL_BUS_WIDTH {4} \
   CONFIG.PSU_SD1_INTERNAL_BUS_WIDTH {4} \
   CONFIG.PSU_USB3__DUAL_CLOCK_ENABLE {1} \
   CONFIG.PSU__ACT_DDR_FREQ_MHZ {1200.000000} \
   CONFIG.PSU__AFI0_COHERENCY {0} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1200.000000} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0 {1} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ {1200} \
   CONFIG.PSU__CRF_APB__ACPU_CTRL__SRCSEL {APLL} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FBDIV {72} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__APLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__APLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__APLL_TO_LPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {250.000000} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {250.000000} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {600.000000} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1200} \
   CONFIG.PSU__CRF_APB__DDR_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {600.000000} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__FREQMHZ {600} \
   CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__SRCSEL {APLL} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__FBDIV {72} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__DPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__DPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__DPLL_TO_LPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__ACT_FREQMHZ {25.000000} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR0 {20} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRF_APB__DP_AUDIO__FRAC_ENABLED {0} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__ACT_FREQMHZ {26.315790} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR0 {19} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__ACT_FREQMHZ {300.000000} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__SRCSEL {VPLL} \
   CONFIG.PSU__CRF_APB__DP_VIDEO__FRAC_ENABLED {0} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {600.000000} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__DIVISOR0 {2} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__FREQMHZ {600} \
   CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__ACT_FREQMHZ {500.000000} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__DIVISOR0 {1} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRF_APB__GPU_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRF_APB__SATA_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {400.000000} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__FREQMHZ {400} \
   CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {DPLL} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__FBDIV {90} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRF_APB__VPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRF_APB__VPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRF_APB__VPLL_TO_LPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {500.000000} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {50.000000} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR0 {30} \
   CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {500.000000} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__CPU_R5_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {250.000000} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1500.000000} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR0 {12} \
   CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__FBDIV {90} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRL_APB__IOPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRL_APB__IOPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRL_APB__IOPLL_TO_FPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {250.000000} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {500.000000} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__FREQMHZ {500} \
   CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.500000} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__DIVISOR0 {8} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__PCAP_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ {300.000000} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {300} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ {187.500000} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR0 {8} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__PL2_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__ACT_FREQMHZ {250.000000} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR0 {4} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__PL3_REF_CTRL__SRCSEL {RPLL} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR0 {5} \
   CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__DIV2 {1} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__FBDIV {90} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__FRACDATA {0.000000} \
   CONFIG.PSU__CRL_APB__RPLL_CTRL__SRCSEL {PSS_REF_CLK} \
   CONFIG.PSU__CRL_APB__RPLL_FRAC_CFG__ENABLED {0} \
   CONFIG.PSU__CRL_APB__RPLL_TO_FPD_CTRL__DIVISOR0 {3} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__ACT_FREQMHZ {187.500000} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR0 {8} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__ACT_FREQMHZ {187.500000} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR0 {8} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__FREQMHZ {200} \
   CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR0 {7} \
   CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__UART0_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR0 {15} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__FREQMHZ {100} \
   CONFIG.PSU__CRL_APB__UART1_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__ACT_FREQMHZ {250.000000} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__ACT_FREQMHZ {250.000000} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR0 {6} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR1 {1} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__FREQMHZ {250} \
   CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__ACT_FREQMHZ {20.000000} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR0 {25} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR1 {3} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__FREQMHZ {20} \
   CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__SRCSEL {IOPLL} \
   CONFIG.PSU__CRL_APB__USB3__ENABLE {1} \
   CONFIG.PSU__DDRC__ADDR_MIRROR {0} \
   CONFIG.PSU__DDRC__BANK_ADDR_COUNT {2} \
   CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
   CONFIG.PSU__DDRC__BRC_MAPPING {ROW_BANK_COL} \
   CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
   CONFIG.PSU__DDRC__CL {16} \
   CONFIG.PSU__DDRC__CLOCK_STOP_EN {0} \
   CONFIG.PSU__DDRC__COL_ADDR_COUNT {10} \
   CONFIG.PSU__DDRC__COMPONENTS {Components} \
   CONFIG.PSU__DDRC__CWL {16} \
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
   CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
   CONFIG.PSU__DDRC__SB_TARGET {16-16-16} \
   CONFIG.PSU__DDRC__SELF_REF_ABORT {0} \
   CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400R} \
   CONFIG.PSU__DDRC__STATIC_RD_MODE {0} \
   CONFIG.PSU__DDRC__TRAIN_DATA_EYE {1} \
   CONFIG.PSU__DDRC__TRAIN_READ_GATE {1} \
   CONFIG.PSU__DDRC__TRAIN_WRITE_LEVEL {1} \
   CONFIG.PSU__DDRC__T_FAW {30.0} \
   CONFIG.PSU__DDRC__T_RAS_MIN {32} \
   CONFIG.PSU__DDRC__T_RC {45.32} \
   CONFIG.PSU__DDRC__T_RCD {16} \
   CONFIG.PSU__DDRC__T_RP {16} \
   CONFIG.PSU__DDRC__VENDOR_PART {OTHERS} \
   CONFIG.PSU__DDRC__VREF {1} \
   CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {1} \
   CONFIG.PSU__DDR__INTERFACE__FREQMHZ {600.000} \
   CONFIG.PSU__DISPLAYPORT__LANE0__ENABLE {1} \
   CONFIG.PSU__DISPLAYPORT__LANE0__IO {GT Lane1} \
   CONFIG.PSU__DISPLAYPORT__LANE1__ENABLE {1} \
   CONFIG.PSU__DISPLAYPORT__LANE1__IO {GT Lane0} \
   CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__DLL__ISUSED {1} \
   CONFIG.PSU__DPAUX__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__DPAUX__PERIPHERAL__IO {MIO 27 .. 30} \
   CONFIG.PSU__DP__LANE_SEL {Dual Lower} \
   CONFIG.PSU__DP__REF_CLK_FREQ {27} \
   CONFIG.PSU__DP__REF_CLK_SEL {Ref Clk1} \
   CONFIG.PSU__FPD_SLCR__WDT1__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__FPD_SLCR__WDT1__FREQMHZ {100.000000} \
   CONFIG.PSU__FPD_SLCR__WDT_CLK_SEL__SELECT {APB} \
   CONFIG.PSU__FPGA_PL0_ENABLE {1} \
   CONFIG.PSU__FPGA_PL1_ENABLE {1} \
   CONFIG.PSU__FPGA_PL2_ENABLE {1} \
   CONFIG.PSU__FPGA_PL3_ENABLE {0} \
   CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
   CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO1_MIO__IO {MIO 26 .. 51} \
   CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO2_MIO__IO {MIO 52 .. 77} \
   CONFIG.PSU__GPIO2_MIO__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__GPIO_EMIO_WIDTH {8} \
   CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__GPIO_EMIO__PERIPHERAL__IO {<Select>} \
   CONFIG.PSU__GT__LINK_SPEED {HBR} \
   CONFIG.PSU__GT__PRE_EMPH_LVL_4 {0} \
   CONFIG.PSU__GT__VLT_SWNG_LVL_4 {0} \
   CONFIG.PSU__HIGH_ADDRESS__ENABLE {1} \
   CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 18 .. 19} \
   CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 0 .. 1} \
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
   CONFIG.PSU__IOU_SLCR__WDT0__ACT_FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__WDT0__FREQMHZ {100.000000} \
   CONFIG.PSU__IOU_SLCR__WDT_CLK_SEL__SELECT {APB} \
   CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
   CONFIG.PSU__MAXIGP1__DATA_WIDTH {128} \
   CONFIG.PSU__MAXIGP2__DATA_WIDTH {32} \
   CONFIG.PSU__OVERRIDE__BASIC_CLOCK {0} \
   CONFIG.PSU__PL_CLK0_BUF {TRUE} \
   CONFIG.PSU__PL_CLK1_BUF {TRUE} \
   CONFIG.PSU__PL_CLK2_BUF {TRUE} \
   CONFIG.PSU__PL_CLK3_BUF {FALSE} \
   CONFIG.PSU__PRESET_APPLIED {1} \
   CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;1|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;1|S_AXI_HP1_FPD:NA;1|S_AXI_HP0_FPD:NA;1|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;1|SATA1:NonSecure;0|SATA0:NonSecure;0|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;0|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;0|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;1|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1} \
   CONFIG.PSU__PROTECTION__SLAVES { \
     LPD;USB3_1_XHCI;FE300000;FE3FFFFF;1|LPD;USB3_1;FF9E0000;FF9EFFFF;1|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;1|LPD;USB3_0;FF9D0000;FF9DFFFF;1|LPD;UART1;FF010000;FF01FFFF;1|LPD;UART0;FF000000;FF00FFFF;1|LPD;TTC3;FF140000;FF14FFFF;1|LPD;TTC2;FF130000;FF13FFFF;1|LPD;TTC1;FF120000;FF12FFFF;1|LPD;TTC0;FF110000;FF11FFFF;1|FPD;SWDT1;FD4D0000;FD4DFFFF;1|LPD;SWDT0;FF150000;FF15FFFF;1|LPD;SPI1;FF050000;FF05FFFF;0|LPD;SPI0;FF040000;FF04FFFF;1|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;1|LPD;SD0;FF160000;FF16FFFF;1|FPD;SATA;FD0C0000;FD0CFFFF;0|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;0|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;1|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;0|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;0|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display Port;FD4A0000;FD4AFFFF;1|FPD;DPDMA;FD4C0000;FD4CFFFF;1|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;87FFFFFFF;1|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;1|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;0|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1 \
   } \
   CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333} \
   CONFIG.PSU__QSPI_COHERENCY {0} \
   CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {0} \
   CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__SATA__LANE0__ENABLE {0} \
   CONFIG.PSU__SATA__LANE1__ENABLE {0} \
   CONFIG.PSU__SATA__PERIPHERAL__ENABLE {0} \
   CONFIG.PSU__SAXIGP0__DATA_WIDTH {64} \
   CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP4__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP5__DATA_WIDTH {128} \
   CONFIG.PSU__SAXIGP6__DATA_WIDTH {128} \
   CONFIG.PSU__SD0_COHERENCY {0} \
   CONFIG.PSU__SD0_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__SD0__DATA_TRANSFER_MODE {4Bit} \
   CONFIG.PSU__SD0__GRP_CD__ENABLE {1} \
   CONFIG.PSU__SD0__GRP_CD__IO {MIO 24} \
   CONFIG.PSU__SD0__GRP_POW__ENABLE {0} \
   CONFIG.PSU__SD0__GRP_WP__ENABLE {0} \
   CONFIG.PSU__SD0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SD0__PERIPHERAL__IO {MIO 13 .. 16 21 22} \
   CONFIG.PSU__SD0__RESET__ENABLE {0} \
   CONFIG.PSU__SD0__SLOT_TYPE {SD 2.0} \
   CONFIG.PSU__SD1_COHERENCY {0} \
   CONFIG.PSU__SD1_ROUTE_THROUGH_FPD {0} \
   CONFIG.PSU__SD1__DATA_TRANSFER_MODE {4Bit} \
   CONFIG.PSU__SD1__GRP_CD__ENABLE {0} \
   CONFIG.PSU__SD1__GRP_POW__ENABLE {0} \
   CONFIG.PSU__SD1__GRP_WP__ENABLE {0} \
   CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 46 .. 51} \
   CONFIG.PSU__SD1__RESET__ENABLE {0} \
   CONFIG.PSU__SD1__SLOT_TYPE {SD 2.0} \
   CONFIG.PSU__SPI0__GRP_SS0__ENABLE {1} \
   CONFIG.PSU__SPI0__GRP_SS0__IO {MIO 41} \
   CONFIG.PSU__SPI0__GRP_SS1__ENABLE {0} \
   CONFIG.PSU__SPI0__GRP_SS2__ENABLE {0} \
   CONFIG.PSU__SPI0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__SPI0__PERIPHERAL__IO {MIO 38 .. 43} \
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
   CONFIG.PSU__UART0__BAUD_RATE {115200} \
   CONFIG.PSU__UART0__MODEM__ENABLE {0} \
   CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 34 .. 35} \
   CONFIG.PSU__UART1__BAUD_RATE {115200} \
   CONFIG.PSU__UART1__MODEM__ENABLE {1} \
   CONFIG.PSU__UART1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__UART1__PERIPHERAL__IO {MIO 8 .. 9} \
   CONFIG.PSU__USB0_COHERENCY {0} \
   CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__USB0__PERIPHERAL__IO {MIO 52 .. 63} \
   CONFIG.PSU__USB0__REF_CLK_FREQ {26} \
   CONFIG.PSU__USB0__REF_CLK_SEL {Ref Clk0} \
   CONFIG.PSU__USB0__RESET__ENABLE {1} \
   CONFIG.PSU__USB0__RESET__IO {MIO 25} \
   CONFIG.PSU__USB1_COHERENCY {0} \
   CONFIG.PSU__USB1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__USB1__PERIPHERAL__IO {MIO 64 .. 75} \
   CONFIG.PSU__USB1__REF_CLK_FREQ {26} \
   CONFIG.PSU__USB1__REF_CLK_SEL {Ref Clk0} \
   CONFIG.PSU__USB1__RESET__ENABLE {0} \
   CONFIG.PSU__USB2_0__EMIO__ENABLE {0} \
   CONFIG.PSU__USB2_1__EMIO__ENABLE {0} \
   CONFIG.PSU__USB3_0__EMIO__ENABLE {0} \
   CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__USB3_0__PERIPHERAL__IO {GT Lane2} \
   CONFIG.PSU__USB3_1__EMIO__ENABLE {0} \
   CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE {1} \
   CONFIG.PSU__USB3_1__PERIPHERAL__IO {GT Lane3} \
   CONFIG.PSU__USB__RESET__MODE {Shared MIO Pin} \
   CONFIG.PSU__USB__RESET__POLARITY {Active Low} \
   CONFIG.PSU__USE__IRQ0 {1} \
   CONFIG.PSU__USE__M_AXI_GP0 {0} \
   CONFIG.PSU__USE__M_AXI_GP1 {0} \
   CONFIG.PSU__USE__M_AXI_GP2 {1} \
   CONFIG.PSU__USE__S_AXI_GP0 {0} \
   CONFIG.PSU__USE__S_AXI_GP2 {1} \
   CONFIG.PSU__USE__S_AXI_GP3 {1} \
   CONFIG.PSU__USE__S_AXI_GP4 {1} \
   CONFIG.PSU__USE__S_AXI_GP5 {0} \
   CONFIG.PSU__USE__S_AXI_GP6 {0} \
   CONFIG.SUBPRESET1 {Custom} \
 ] $ps_e_0

  # Create instance: reset_control, and set properties
  set reset_control [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 reset_control ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {2} \
 ] $reset_control

  # Create instance: rgbleds, and set properties
  set rgbleds [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 rgbleds ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.GPIO_BOARD_INTERFACE {rgbleds} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rgbleds

  # Create instance: shutdown_HP0_FPD, and set properties
  set shutdown_HP0_FPD [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_axi_shutdown_manager:1.0 shutdown_HP0_FPD ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_DATA_WIDTH {128} \
 ] $shutdown_HP0_FPD

  # Create instance: shutdown_HP2_FPD, and set properties
  set shutdown_HP2_FPD [ create_bd_cell -type ip -vlnv xilinx.com:ip:dfx_axi_shutdown_manager:1.0 shutdown_HP2_FPD ]
  set_property -dict [ list \
   CONFIG.CTRL_INTERFACE_TYPE {1} \
   CONFIG.DP_AXI_DATA_WIDTH {128} \
 ] $shutdown_HP2_FPD

  # Create instance: switches_gpio, and set properties
  set switches_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 switches_gpio ]
  set_property -dict [ list \
   CONFIG.C_INTERRUPT_PRESENT {1} \
   CONFIG.GPIO_BOARD_INTERFACE {dip_switch_4bits} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $switches_gpio

  # Create instance: tx_en_out, and set properties
  set tx_en_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 tx_en_out ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {1} \
 ] $tx_en_out

  # Create instance: video
  create_hier_cell_video [current_bd_instance .] video

  # Create instance: xlconcat, and set properties
  set xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {9} \
 ] $xlconcat

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {2} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {2} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_1

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins composable/S00_AXI] [get_bd_intf_pins video/M08_AXI]
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_pins composable/M02_AXIS] [get_bd_intf_pins mipi/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_HDMI_IN_1 [get_bd_intf_pins composable/S00_AXIS] [get_bd_intf_pins video/M_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_HDMI_OUT_1 [get_bd_intf_pins composable/S01_AXIS] [get_bd_intf_pins video/M_AXIS1]
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins axi_interconnect/M12_AXI] [get_bd_intf_pins mipi/S_AXI_INTERCONNECT]
  connect_bd_intf_net -intf_net S_AXI_CTRL_1 [get_bd_intf_pins composable/S_AXI_CTRL] [get_bd_intf_pins video/M07_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports dip_switch_4bits] [get_bd_intf_pins switches_gpio/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO1 [get_bd_intf_ports led_4bits] [get_bd_intf_pins leds_gpio/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO2 [get_bd_intf_ports push_button_4bits] [get_bd_intf_pins btns_gpio/GPIO]
  connect_bd_intf_net -intf_net axi_interconnect_M02_AXI [get_bd_intf_pins HDMI_CTL_axi_iic/S_AXI] [get_bd_intf_pins axi_interconnect/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M03_AXI [get_bd_intf_pins axi_interconnect/M03_AXI] [get_bd_intf_pins reset_control/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M04_AXI [get_bd_intf_pins axi_intc/s_axi] [get_bd_intf_pins axi_interconnect/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M05_AXI [get_bd_intf_pins axi_interconnect/M05_AXI] [get_bd_intf_pins leds_gpio/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M06_AXI [get_bd_intf_pins axi_interconnect/M06_AXI] [get_bd_intf_pins tx_en_out/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M07_AXI [get_bd_intf_pins axi_interconnect/M07_AXI] [get_bd_intf_pins shutdown_HP2_FPD/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_M08_AXI [get_bd_intf_pins axi_interconnect/M08_AXI] [get_bd_intf_pins shutdown_HP0_FPD/S_AXI_CTRL]
  connect_bd_intf_net -intf_net axi_interconnect_M09_AXI [get_bd_intf_pins axi_interconnect/M09_AXI] [get_bd_intf_pins rgbleds/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M10_AXI [get_bd_intf_pins axi_interconnect/M10_AXI] [get_bd_intf_pins switches_gpio/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M11_AXI [get_bd_intf_pins axi_interconnect/M11_AXI] [get_bd_intf_pins btns_gpio/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_M13_AXI [get_bd_intf_pins axi_interconnect/M13_AXI] [get_bd_intf_pins composable/S13_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_1_M00_AXI [get_bd_intf_pins axi_mem_intercon_1/M00_AXI] [get_bd_intf_pins shutdown_HP2_FPD/S_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins axi_mem_intercon/M00_AXI] [get_bd_intf_pins shutdown_HP0_FPD/S_AXI]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins video/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_mem_intercon_1/S00_AXI] [get_bd_intf_pins video/M_AXI_S2MM]
  connect_bd_intf_net -intf_net composable_M_AXIS_HDMI_IN [get_bd_intf_pins composable/M00_AXIS] [get_bd_intf_pins video/S_AXIS]
  connect_bd_intf_net -intf_net composable_M_AXIS_HDMI_OUT [get_bd_intf_pins composable/M01_AXIS] [get_bd_intf_pins video/S_AXIS1]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_rx_ss_DDC_OUT [get_bd_intf_ports RX_DDC_OUT] [get_bd_intf_pins video/RX_DDC_OUT]
  connect_bd_intf_net -intf_net intf_net_v_hdmi_tx_ss_DDC_OUT [get_bd_intf_ports TX_DDC_OUT] [get_bd_intf_pins video/TX_DDC_OUT]
  connect_bd_intf_net -intf_net intf_net_zynq_us_M_AXI_HPM0_LPD [get_bd_intf_pins axi_interconnect/S00_AXI] [get_bd_intf_pins ps_e_0/M_AXI_HPM0_LPD]
  connect_bd_intf_net -intf_net intf_net_zynq_us_ss_0_IIC [get_bd_intf_ports HDMI_CTL_iic] [get_bd_intf_pins HDMI_CTL_axi_iic/IIC]
  connect_bd_intf_net -intf_net intf_net_zynq_us_ss_0_M00_AXI [get_bd_intf_pins axi_interconnect/M00_AXI] [get_bd_intf_pins video/vid_phy_axi4lite]
  connect_bd_intf_net -intf_net intf_net_zynq_us_ss_0_M01_AXI [get_bd_intf_pins axi_interconnect/M01_AXI] [get_bd_intf_pins video/S_AXI_INTERCONNECT]
  connect_bd_intf_net -intf_net mipi_M00_AXI [get_bd_intf_pins mipi/M_AXI_S2MM] [get_bd_intf_pins ps_e_0/S_AXI_HP1_FPD]
  connect_bd_intf_net -intf_net mipi_M_AXIS [get_bd_intf_pins composable/S02_AXIS] [get_bd_intf_pins mipi/M_AXIS]
  connect_bd_intf_net -intf_net mipi_cam_gpio [get_bd_intf_ports cam_gpio] [get_bd_intf_pins mipi/cam_gpio]
  connect_bd_intf_net -intf_net mipi_phy_if_0_0_1 [get_bd_intf_ports mipi_phy_if_0] [get_bd_intf_pins mipi/mipi_phy_if_0]
  connect_bd_intf_net -intf_net rgbleds_GPIO [get_bd_intf_ports rgbleds] [get_bd_intf_pins rgbleds/GPIO]
  connect_bd_intf_net -intf_net shutdown_HP0_M_AXI [get_bd_intf_pins ps_e_0/S_AXI_HP0_FPD] [get_bd_intf_pins shutdown_HP0_FPD/M_AXI]
  connect_bd_intf_net -intf_net shutdown_HP2_M_AXI [get_bd_intf_pins ps_e_0/S_AXI_HP2_FPD] [get_bd_intf_pins shutdown_HP2_FPD/M_AXI]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins axi_mem_intercon_1/ARESETN] [get_bd_pins proc_sys_reset_1/interconnect_aresetn]
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins reset_control/gpio_io_o] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net axi_intc_irq [get_bd_pins axi_intc/irq] [get_bd_pins xlconcat_int/In0]
  connect_bd_net -net xlconcat_int_dout [get_bd_pins xlconcat_int/dout] [get_bd_pins ps_e_0/pl_ps_irq0]
  connect_bd_net -net axi_vdma_0_mm2s_introut [get_bd_pins video/mm2s_introut] [get_bd_pins xlconcat/In4]
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins video/s2mm_introut] [get_bd_pins xlconcat/In3]
  connect_bd_net -net gpio_btns_ip2intc_irpt [get_bd_pins btns_gpio/ip2intc_irpt] [get_bd_pins xlconcat/In6]
  connect_bd_net -net gpio_sws_ip2intc_irpt [get_bd_pins switches_gpio/ip2intc_irpt] [get_bd_pins xlconcat/In5]
  connect_bd_net -net mipi_csirxss_csi_irq [get_bd_pins mipi/csirxss_csi_irq] [get_bd_pins xlconcat/In7]
  connect_bd_net -net mipi_s2mm_introut [get_bd_pins mipi/s2mm_introut] [get_bd_pins xlconcat/In8]
  connect_bd_net -net net_bdry_in_HDMI_RX_CLK_N_IN [get_bd_ports HDMI_RX_CLK_N_IN] [get_bd_pins video/HDMI_RX_CLK_N_IN]
  connect_bd_net -net net_bdry_in_HDMI_RX_CLK_P_IN [get_bd_ports HDMI_RX_CLK_P_IN] [get_bd_pins video/HDMI_RX_CLK_P_IN]
  connect_bd_net -net net_bdry_in_HDMI_RX_DAT_N_IN [get_bd_ports HDMI_RX_DAT_N_IN] [get_bd_pins video/HDMI_RX_DAT_N_IN]
  connect_bd_net -net net_bdry_in_HDMI_RX_DAT_P_IN [get_bd_ports HDMI_RX_DAT_P_IN] [get_bd_pins video/HDMI_RX_DAT_P_IN]
  connect_bd_net -net net_bdry_in_HDMI_SI5324_LOL_IN [get_bd_ports HDMI_SI5324_LOL_IN] [get_bd_pins video/HDMI_SI5324_LOL_IN]
  connect_bd_net -net net_bdry_in_RX_DET_IN [get_bd_ports RX_DET_IN] [get_bd_pins video/RX_DET_IN]
  connect_bd_net -net net_bdry_in_TX_HPD_IN [get_bd_ports TX_HPD_IN] [get_bd_pins video/TX_HPD_IN]
  connect_bd_net -net net_bdry_in_TX_REFCLK_N_IN [get_bd_ports TX_REFCLK_N_IN] [get_bd_pins video/TX_REFCLK_N_IN]
  connect_bd_net -net net_bdry_in_TX_REFCLK_P_IN [get_bd_ports TX_REFCLK_P_IN] [get_bd_pins video/TX_REFCLK_P_IN]
  connect_bd_net -net net_bdry_in_reset [get_bd_pins proc_sys_reset_0/aux_reset_in] [get_bd_pins proc_sys_reset_0/dcm_locked] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins proc_sys_reset_1/aux_reset_in] [get_bd_pins proc_sys_reset_1/dcm_locked] [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins ps_e_0/pl_resetn0]
  connect_bd_net -net net_rst_processor_1_100M_interconnect_aresetn [get_bd_pins axi_interconnect/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net net_v_hdmi_rx_ss_hpd [get_bd_ports RX_HPD_OUT] [get_bd_pins video/RX_HPD_OUT]
  connect_bd_net -net net_v_hdmi_rx_ss_irq [get_bd_pins video/irq_hdmi_in] [get_bd_pins xlconcat/In1]
  connect_bd_net -net net_v_hdmi_tx_ss_irq [get_bd_pins video/irq_hdmi_out] [get_bd_pins xlconcat/In2]
  connect_bd_net -net net_vcc_const_dout [get_bd_ports TX_EN_OUT] [get_bd_pins tx_en_out/gpio_io_o] [get_bd_pins video/TX_EN_OUT]
  connect_bd_net -net net_vid_phy_controller_irq [get_bd_pins video/irq_hdmi_phy] [get_bd_pins xlconcat/In0]
  connect_bd_net -net net_vid_phy_controller_phy_txn_out [get_bd_ports HDMI_TX_DAT_N_OUT] [get_bd_pins video/HDMI_TX_DAT_N_OUT]
  connect_bd_net -net net_vid_phy_controller_phy_txp_out [get_bd_ports HDMI_TX_DAT_P_OUT] [get_bd_pins video/HDMI_TX_DAT_P_OUT]
  connect_bd_net -net net_vid_phy_controller_rx_tmds_clk_n [get_bd_ports RX_REFCLK_N_OUT] [get_bd_pins video/RX_REFCLK_N_OUT]
  connect_bd_net -net net_vid_phy_controller_rx_tmds_clk_p [get_bd_ports RX_REFCLK_P_OUT] [get_bd_pins video/RX_REFCLK_P_OUT]
  connect_bd_net -net net_vid_phy_controller_tx_tmds_clk_n [get_bd_ports HDMI_TX_CLK_N_OUT] [get_bd_pins video/HDMI_TX_CLK_N_OUT]
  connect_bd_net -net net_vid_phy_controller_tx_tmds_clk_p [get_bd_ports HDMI_TX_CLK_P_OUT] [get_bd_pins video/HDMI_TX_CLK_P_OUT]
  connect_bd_net -net net_zynq_us_ss_0_clk_out2 [get_bd_pins axi_interconnect/M07_ACLK] [get_bd_pins axi_interconnect/M08_ACLK] [get_bd_pins axi_interconnect/M12_ACLK] [get_bd_pins axi_interconnect/M13_ACLK] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon_1/ACLK] [get_bd_pins axi_mem_intercon_1/M00_ACLK] [get_bd_pins axi_mem_intercon_1/S00_ACLK] [get_bd_pins composable/clk_300MHz] [get_bd_pins mipi/clk_300MHz] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins ps_e_0/pl_clk1] [get_bd_pins ps_e_0/saxihp0_fpd_aclk] [get_bd_pins ps_e_0/saxihp1_fpd_aclk] [get_bd_pins ps_e_0/saxihp2_fpd_aclk] [get_bd_pins shutdown_HP0_FPD/clk] [get_bd_pins shutdown_HP2_FPD/clk] [get_bd_pins video/clk_300MHz]
  connect_bd_net -net net_zynq_us_ss_0_dcm_locked [get_bd_pins axi_interconnect/M07_ARESETN] [get_bd_pins axi_interconnect/M08_ARESETN] [get_bd_pins axi_interconnect/M12_ARESETN] [get_bd_pins axi_interconnect/M13_ARESETN] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon_1/M00_ARESETN] [get_bd_pins axi_mem_intercon_1/S00_ARESETN] [get_bd_pins composable/clk_300MHz_aresetn] [get_bd_pins mipi/clk_300MHz_aresetn] [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins shutdown_HP0_FPD/resetn] [get_bd_pins shutdown_HP2_FPD/resetn] [get_bd_pins video/clk_300MHz_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_peripheral_aresetn [get_bd_pins HDMI_CTL_axi_iic/s_axi_aresetn] [get_bd_pins axi_intc/s_axi_aresetn] [get_bd_pins axi_interconnect/M00_ARESETN] [get_bd_pins axi_interconnect/M01_ARESETN] [get_bd_pins axi_interconnect/M02_ARESETN] [get_bd_pins axi_interconnect/M03_ARESETN] [get_bd_pins axi_interconnect/M04_ARESETN] [get_bd_pins axi_interconnect/M05_ARESETN] [get_bd_pins axi_interconnect/M06_ARESETN] [get_bd_pins axi_interconnect/M09_ARESETN] [get_bd_pins axi_interconnect/M10_ARESETN] [get_bd_pins axi_interconnect/M11_ARESETN] [get_bd_pins axi_interconnect/S00_ARESETN] [get_bd_pins btns_gpio/s_axi_aresetn] [get_bd_pins leds_gpio/s_axi_aresetn] [get_bd_pins mipi/clk_100MHz_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins reset_control/s_axi_aresetn] [get_bd_pins rgbleds/s_axi_aresetn] [get_bd_pins switches_gpio/s_axi_aresetn] [get_bd_pins tx_en_out/s_axi_aresetn] [get_bd_pins video/clk_100MHz_aresetn]
  connect_bd_net -net net_zynq_us_ss_0_s_axi_aclk [get_bd_pins HDMI_CTL_axi_iic/s_axi_aclk] [get_bd_pins axi_intc/s_axi_aclk] [get_bd_pins axi_interconnect/ACLK] [get_bd_pins axi_interconnect/M00_ACLK] [get_bd_pins axi_interconnect/M01_ACLK] [get_bd_pins axi_interconnect/M02_ACLK] [get_bd_pins axi_interconnect/M03_ACLK] [get_bd_pins axi_interconnect/M04_ACLK] [get_bd_pins axi_interconnect/M05_ACLK] [get_bd_pins axi_interconnect/M06_ACLK] [get_bd_pins axi_interconnect/M09_ACLK] [get_bd_pins axi_interconnect/M10_ACLK] [get_bd_pins axi_interconnect/M11_ACLK] [get_bd_pins axi_interconnect/S00_ACLK] [get_bd_pins btns_gpio/s_axi_aclk] [get_bd_pins leds_gpio/s_axi_aclk] [get_bd_pins mipi/clk_100MHz] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins ps_e_0/maxihpm0_lpd_aclk] [get_bd_pins ps_e_0/pl_clk0] [get_bd_pins reset_control/s_axi_aclk] [get_bd_pins rgbleds/s_axi_aclk] [get_bd_pins switches_gpio/s_axi_aclk] [get_bd_pins tx_en_out/s_axi_aclk] [get_bd_pins video/clk_100MHz]
  connect_bd_net -net ps_e_0_pl_clk2 [get_bd_pins mipi/dphy_clk_200M] [get_bd_pins ps_e_0/pl_clk2]
  connect_bd_net -net xlconcat_dout [get_bd_pins axi_intc/intr] [get_bd_pins xlconcat/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_ports HDMI_SI5324_RST_OUT] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_ports HDMI_TX_LS_OE] [get_bd_pins xlslice_1/Dout]

  # Create address segments
  assign_bd_address -offset 0x80041000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs HDMI_CTL_axi_iic/S_AXI/Reg] -force
  assign_bd_address -offset 0x80043000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x80130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/axi_vdma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80042000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/axi_vdma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x800B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/axis_switch/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x80011000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs btns_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/cam_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80010000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/hdmi_out/color_convert/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80050000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/hdmi_in/color_convert/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/colorthresholding_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80150000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/demosaic/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x80200000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/pr_0/dilate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80218000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/pr_1/dilate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/pr_fork/duplicate_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80208000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/pr_0/erode_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80210000 -range 0x00008000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/pr_1/erode_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x800C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/filter2d_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/hdmi_in/frontend/S_AXI_CPU_IN/Reg] -force
  assign_bd_address -offset 0x80020000 -range 0x00020000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/hdmi_out/frontend/S_AXI_CPU_IN/Reg] -force
  assign_bd_address -offset 0x80160000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/gamma_lut/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x80170000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/gpio_ip_reset/S_AXI/Reg] -force
  assign_bd_address -offset 0x800E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/gray2rgb_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80046000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs leds_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x800A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/lut_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80014000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/mipi_csi2_rx_subsyst/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x80190000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/pipeline_control/S_AXI/Reg] -force
  assign_bd_address -offset 0x80070000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/hdmi_in/pixel_pack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80180000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/pixel_pack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80080000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/hdmi_out/pixel_unpack/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80044000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs reset_control/S_AXI/Reg] -force
  assign_bd_address -offset 0x800F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/rgb2gray_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/rgb2hsv_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80012000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs rgbleds/S_AXI/Reg] -force
  assign_bd_address -offset 0x80090000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs shutdown_HP0_FPD/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x800D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs shutdown_HP2_FPD/S_AXI_CTRL/Reg] -force
  assign_bd_address -offset 0x80230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs composable/pr_join/subtract_accel/s_axi_control/Reg] -force
  assign_bd_address -offset 0x80040000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs switches_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80016000 -range 0x00001000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs tx_en_out/S_AXI/Reg] -force
  assign_bd_address -offset 0x80120000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs mipi/v_proc_sys/s_axi_ctrl/Reg] -force
  assign_bd_address -offset 0x80060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_e_0/Data] [get_bd_addr_segs video/phy/vid_phy_controller/vid_phy_axi4lite/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces mipi/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e_0/SAXIGP3/HP1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S] [get_bd_addr_segs ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e_0/SAXIGP4/HP2_DDR_LOW] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces mipi/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e_0/SAXIGP3/HP1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces mipi/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e_0/SAXIGP3/HP1_LPS_OCM]
  exclude_bd_addr_seg -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S] [get_bd_addr_segs ps_e_0/SAXIGP2/HP0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_MM2S] [get_bd_addr_segs ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0x000800000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e_0/SAXIGP4/HP2_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces video/axi_vdma/Data_S2MM] [get_bd_addr_segs ps_e_0/SAXIGP4/HP2_LPS_OCM]


  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx.com:xd:${overlay_name}:1.0} [get_files [current_bd_design].bd]
  set_property PFM.AXI_PORT {  M_AXI_HPM0_FPD {memport "M_AXI_GP"}  M_AXI_HPM0_LPD {memport "M_AXI_GP"}  S_AXI_HPC0_FPD {memport "S_AXI_HPC"}  S_AXI_HPC1_FPD {memport "S_AXI_HPC"}  S_AXI_HP0_FPD {memport "S_AXI_HP"}  S_AXI_HP1_FPD {memport "S_AXI_HP"}  S_AXI_HP2_FPD {memport "S_AXI_HP"}  S_AXI_HP3_FPD {memport "S_AXI_HP"}  
    S_AXI_LPD {memport "S_AXI_HP"}  } [get_bd_cells /ps_e_0]
  set_property PFM.CLOCK {  pl_clk0 {id "0" is_default "true"  proc_sys_reset "proc_sys_reset_0" status "fixed"}  pl_clk1 {id "1" is_default "false"  proc_sys_reset "proc_sys_reset_1" status "fixed"}  pl_clk2 {id "2" is_default "false"  proc_sys_reset "proc_sys_reset_2" status "fixed"}  pl_clk3 {id "3" is_default "false"  proc_sys_reset "proc_sys_reset_3" status "fixed"}  } [get_bd_cells /ps_e_0]
  set_property PFM.IRQ {In1 {} In2 {} In3 {} In4 {} In5 {} In6 {} In7 {}} [get_bd_cells /xlconcat_int]


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
set pr_0_dilate_erode "composable_pr_0_dilate_erode"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_0] $pr_0_dilate_erode
set new_pd [create_partition_def -name pr_0 -module $pr_0_dilate_erode]
create_reconfig_module -name $pr_0_dilate_erode -partition_def $new_pd -define_from $pr_0_dilate_erode
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd /composable/pr_0_temp]
replace_bd_cell  [get_bd_cells /composable/pr_0] $new_pdcell
delete_bd_objs  [get_bd_cells /composable/pr_0]
set_property name pr_0 $new_pdcell
## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_0_dilate_erode]
delete_bd_objs [get_bd_ports clk_300MHz]
create_bd_port -dir I -type clk -freq_hz 300000000 clk_300MHz
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins erode_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control0:s_axi_control1:stream_in0:stream_in1:stream_out0:stream_out1} [get_bd_ports /clk_300MHz]
assign_bd_address -target_address_space /s_axi_control0 -offset 0x00000000 -range 32K  [get_bd_addr_segs dilate_accel/s_axi_control/Reg] -force
assign_bd_address -target_address_space /s_axi_control1 -offset 0x00000000 -range 32K  [get_bd_addr_segs erode_accel/s_axi_control/Reg] -force

validate_bd_design
save_bd_design

# reconfigurable module
set pr_0_fast_fifo "composable_pr_0_fast_fifo"
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
  CONFIG.FIFO_MEMORY_TYPE {ultra} \
] [get_bd_cells axis_data_fifo_0]

connect_bd_intf_net [get_bd_intf_ports s_axi_control0] [get_bd_intf_pins fast_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins fast_accel/stream_in]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins fast_accel/ap_clk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins fast_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins fast_accel/stream_out]

connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]

assign_bd_address -offset 0x0000 -range 32K [get_bd_addr_segs {fast_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_0_filter2d_fifo "composable_pr_0_filter2d_fifo"
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
  CONFIG.FIFO_MEMORY_TYPE {ultra} \
] [get_bd_cells axis_data_fifo_1]

connect_bd_intf_net [get_bd_intf_ports s_axi_control0] [get_bd_intf_pins filter2d_accel/s_axi_control]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins filter2d_accel/ap_clk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins filter2d_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins filter2d_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins filter2d_accel/stream_out]

connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins axis_data_fifo_1/s_axis_aclk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn]

assign_bd_address -offset 0x0000 -range 32K [get_bd_addr_segs {filter2d_accel/s_axi_control/Reg}] 

validate_bd_design
save_bd_design


# PR 1 partition
set pr_1_dilate_erode "composable_pr_1_dilate_erode"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_1] $pr_1_dilate_erode
set new_pd [create_partition_def -name pr_1 -module $pr_1_dilate_erode]
create_reconfig_module -name $pr_1_dilate_erode -partition_def $new_pd -define_from $pr_1_dilate_erode
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd /composable/pr_1_temp]
replace_bd_cell  [get_bd_cells /composable/pr_1] $new_pdcell
delete_bd_objs  [get_bd_cells /composable/pr_1]
set_property name pr_1 $new_pdcell

## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_1_dilate_erode]
delete_bd_objs [get_bd_ports clk_300MHz]
create_bd_port -dir I -type clk -freq_hz 300000000 clk_300MHz
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins erode_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control0:s_axi_control1:stream_in0:stream_in1:stream_out0:stream_out1} [get_bd_ports /clk_300MHz]
assign_bd_address -target_address_space /s_axi_control0 -offset 0x00000000 -range 32K  [get_bd_addr_segs erode_accel/s_axi_control/Reg] -force
assign_bd_address -target_address_space /s_axi_control1 -offset 0x00000000 -range 32K  [get_bd_addr_segs dilate_accel/s_axi_control/Reg] -force

validate_bd_design 
save_bd_design

# reconfigurable module
set pr_1_cornerharris "composable_pr_1_cornerharris_fifo"
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
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins cornerHarris_accel/ap_clk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins cornerHarris_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins cornerHarris_accel/stream_out]

connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_ports stream_out1] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins axis_data_fifo_0/s_axis_aclk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]

assign_bd_address -offset 0x0000 -range 32K [get_bd_addr_segs {cornerHarris_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design


# pr_join partition
set pr_join_subtract "composable_pr_join_subtract"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_join] $pr_join_subtract
set new_pd [create_partition_def -name pr_join -module $pr_join_subtract]
create_reconfig_module -name $pr_join_subtract -partition_def $new_pd -define_from $pr_join_subtract
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd /composable/pr_join_temp]
replace_bd_cell  [get_bd_cells /composable/pr_join] $new_pdcell
delete_bd_objs  [get_bd_cells /composable/pr_join]
set_property name pr_join $new_pdcell
## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_join_subtract]
delete_bd_objs [get_bd_ports clk_300MHz]
create_bd_port -dir I -type clk -freq_hz 300000000 clk_300MHz
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins subtract_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control:stream_in0:stream_in1:stream_out} [get_bd_ports /clk_300MHz]

assign_bd_address -offset 0x00000000 -range 64K [get_bd_addr_segs {s_axi_control/*_Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_join_absdiff "composable_pr_join_absdiff"
create_bd_design -boundary_from [get_files $pr_join_subtract.bd] $pr_join_absdiff
create_reconfig_module -name $pr_join_absdiff -partition_def pr_join -define_from $pr_join_absdiff
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:absdiff_accel:1.0 absdiff_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins absdiff_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins absdiff_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins absdiff_accel/stream_in1]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins absdiff_accel/ap_clk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins absdiff_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins absdiff_accel/stream_out]

assign_bd_address -offset 0x0000 -range 64K [get_bd_addr_segs {absdiff_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_join_add "composable_pr_join_add"
create_bd_design -boundary_from [get_files $pr_join_subtract.bd] $pr_join_add
create_reconfig_module -name $pr_join_add -partition_def pr_join -define_from $pr_join_add
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:add_accel:1.0 add_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins add_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins add_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins add_accel/stream_in1]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins add_accel/ap_clk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins add_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins add_accel/stream_out]

assign_bd_address -offset 0x0000 -range 64K [get_bd_addr_segs {add_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_join_bitand "composable_pr_join_bitand"
create_bd_design -boundary_from [get_files $pr_join_subtract.bd] $pr_join_bitand
create_reconfig_module -name $pr_join_bitand -partition_def pr_join -define_from $pr_join_bitand
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:bitwise_and_accel:1.0 bitwise_and_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins bitwise_and_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins bitwise_and_accel/stream_in]
connect_bd_intf_net [get_bd_intf_ports stream_in1] [get_bd_intf_pins bitwise_and_accel/stream_in1]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins bitwise_and_accel/ap_clk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins bitwise_and_accel/ap_rst_n]
connect_bd_intf_net [get_bd_intf_ports stream_out0] [get_bd_intf_pins bitwise_and_accel/stream_out]

assign_bd_address -offset 0x0000 -range 64K [get_bd_addr_segs {bitwise_and_accel/s_axi_control/Reg}]
validate_bd_design
save_bd_design


# pr_fork partition
set pr_fork_duplicate "composable_pr_fork_duplicate"
current_bd_design [get_bd_designs ${design_name}]
validate_bd_design
set curdesign [current_bd_design]
create_bd_design -cell [get_bd_cells /composable/pr_fork] $pr_fork_duplicate
set new_pd [create_partition_def -name pr_fork -module $pr_fork_duplicate]
create_reconfig_module -name $pr_fork_duplicate -partition_def $new_pd -define_from $pr_fork_duplicate
current_bd_design $curdesign
set new_pdcell [create_bd_cell -type module -reference $new_pd /composable/pr_fork_temp]
replace_bd_cell  [get_bd_cells /composable/pr_fork] $new_pdcell
delete_bd_objs  [get_bd_cells /composable/pr_fork]
set_property name pr_fork $new_pdcell
## Convert regular clock pin to port "type clock" to preserve clock domain
current_bd_design [get_bd_designs $pr_fork_duplicate]
delete_bd_objs [get_bd_ports clk_300MHz]
create_bd_port -dir I -type clk -freq_hz 300000000 clk_300MHz
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins duplicate_accel/ap_clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control:stream_in0:stream_out0:stream_out1} [get_bd_ports /clk_300MHz]

assign_bd_address -offset 0x00000000 -range 64K [get_bd_addr_segs {s_axi_control/*_Reg}]
validate_bd_design
save_bd_design

# reconfigurable module
set pr_fork_rgb2xyz "composable_pr_fork_rgb2xyz"
create_bd_design -boundary_from [get_files $pr_fork_duplicate.bd] $pr_fork_rgb2xyz
create_reconfig_module -name $pr_fork_rgb2xyz -partition_def pr_fork -define_from $pr_fork_rgb2xyz
startgroup
create_bd_cell -type ip -vlnv xilinx.com:hls:rgb2xyz_accel:1.0 rgb2xyz_accel
endgroup

connect_bd_intf_net [get_bd_intf_ports s_axi_control] [get_bd_intf_pins rgb2xyz_accel/s_axi_control]
connect_bd_intf_net [get_bd_intf_ports stream_in0] [get_bd_intf_pins rgb2xyz_accel/stream_in]
connect_bd_net [get_bd_ports clk_300MHz] [get_bd_pins rgb2xyz_accel/ap_clk]
connect_bd_net [get_bd_ports clk_300MHz_aresetn] [get_bd_pins rgb2xyz_accel/ap_rst_n]
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
create_pr_configuration -name config_1 -partitions \
   [list \
      video_cp_i/composable/pr_0:${pr_0_dilate_erode} \
      video_cp_i/composable/pr_1:${pr_1_dilate_erode} \
      video_cp_i/composable/pr_fork:${pr_fork_duplicate} \
      video_cp_i/composable/pr_join:${pr_join_subtract}\
   ]

create_pr_configuration -name config_2 -partitions \
   [list \
      video_cp_i/composable/pr_0:${pr_0_fast_fifo} \
      video_cp_i/composable/pr_1:${pr_1_cornerharris} \
      video_cp_i/composable/pr_fork:${pr_fork_rgb2xyz} \
      video_cp_i/composable/pr_join:${pr_join_absdiff}\
   ]

create_pr_configuration -name config_3 -partitions \
   [list \
      video_cp_i/composable/pr_0:${pr_0_filter2d_fifo} \
      video_cp_i/composable/pr_join:${pr_join_add}\
   ] -greyboxes [list \
      video_cp_i/composable/pr_1 \
      video_cp_i/composable/pr_fork\
   ]

create_pr_configuration -name config_4 -partitions \
   [list \
      video_cp_i/composable/pr_join:${pr_join_bitand} \
   ] -greyboxes [list \
      video_cp_i/composable/pr_0 \
      video_cp_i/composable/pr_1 \
      video_cp_i/composable/pr_fork\
   ]

set_property PR_CONFIGURATION config_1 [get_runs impl_1]
create_run child_0_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2020} -strategy Performance_NetDelay_low -pr_config config_2
create_run child_1_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2020} -strategy Performance_NetDelay_low -pr_config config_3
create_run child_2_impl_1 -parent_run impl_1 -flow {Vivado Implementation 2020} -strategy Performance_NetDelay_low -pr_config config_4

# Change global implementation strategy
set_property strategy Performance_Explore [get_runs impl_1]
set_property report_strategy {UltraFast Design Methodology Reports} [get_runs impl_1]

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
launch_runs child_0_impl_1 -to_step write_bitstream -jobs 4
wait_on_run child_0_impl_1
launch_runs child_1_impl_1 child_2_impl_1 -to_step write_bitstream -jobs 4
wait_on_run child_1_impl_1
wait_on_run child_2_impl_1

# create bitstreams directory
set dest_dir "./overlay"
exec mkdir $dest_dir -p
set bithier "${design_name}_i_composable"

# cp hwh files
# pr_0 related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_0_dilate_erode}/hw_handoff/${pr_0_dilate_erode}.hwh ./${dest_dir}/${prj_name}_${pr_0_dilate_erode}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_0_fast_fifo}/hw_handoff/${pr_0_fast_fifo}.hwh ./${dest_dir}/${prj_name}_${pr_0_fast_fifo}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_0_filter2d_fifo}/hw_handoff/${pr_0_filter2d_fifo}.hwh ./${dest_dir}/${prj_name}_${pr_0_filter2d_fifo}_partial.hwh
# pr_1 related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_1_dilate_erode}/hw_handoff/${pr_1_dilate_erode}.hwh ./${dest_dir}/${prj_name}_${pr_1_dilate_erode}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_1_cornerharris}/hw_handoff/${pr_1_cornerharris}.hwh ./${dest_dir}/${prj_name}_${pr_1_cornerharris}_partial.hwh
# pr_join related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_subtract}/hw_handoff/${pr_join_subtract}.hwh ./${dest_dir}/${prj_name}_${pr_join_subtract}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_absdiff}/hw_handoff/${pr_join_absdiff}.hwh ./${dest_dir}/${prj_name}_${pr_join_absdiff}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_add}/hw_handoff/${pr_join_add}.hwh ./${dest_dir}/${prj_name}_${pr_join_add}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_join_bitand}/hw_handoff/${pr_join_bitand}.hwh ./${dest_dir}/${prj_name}_${pr_join_bitand}_partial.hwh
# pr_fork related
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_fork_duplicate}/hw_handoff/${pr_fork_duplicate}.hwh ./${dest_dir}/${prj_name}_${pr_fork_duplicate}_partial.hwh
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/${pr_fork_rgb2xyz}/hw_handoff/${pr_fork_rgb2xyz}.hwh ./${dest_dir}/${prj_name}_${pr_fork_rgb2xyz}_partial.hwh
# top-level
exec cp ./${prj_name}/${prj_name}.gen/sources_1/bd/$design_name/hw_handoff/$design_name.hwh ./${dest_dir}/${prj_name}.hwh

# copy bitstreams
# impl1 having full and partial bitstreams
exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_0_${pr_0_dilate_erode}_partial.bit ./${dest_dir}/${prj_name}_${pr_0_dilate_erode}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_join_${pr_join_subtract}_partial.bit ./${dest_dir}/${prj_name}_${pr_join_subtract}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_fork_${pr_fork_duplicate}_partial.bit ./${dest_dir}/${prj_name}_${pr_fork_duplicate}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/${bithier}_pr_1_${pr_1_dilate_erode}_partial.bit ./${dest_dir}/${prj_name}_${pr_1_dilate_erode}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/impl_1/video_cp_wrapper.bit ./${dest_dir}/${prj_name}.bit
# child_0_impl_1
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_0_${pr_0_fast_fifo}_partial.bit ./${dest_dir}/${prj_name}_${pr_0_fast_fifo}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_1_${pr_1_cornerharris}_partial.bit ./${dest_dir}/${prj_name}_${pr_1_cornerharris}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_join_${pr_join_absdiff}_partial.bit ./${dest_dir}/${prj_name}_${pr_join_absdiff}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_0_impl_1/${bithier}_pr_fork_${pr_fork_rgb2xyz}_partial.bit ./${dest_dir}/${prj_name}_${pr_fork_rgb2xyz}_partial.bit
# child_1_impl_1
exec cp ./${prj_name}/${prj_name}.runs/child_1_impl_1/${bithier}_pr_0_${pr_0_filter2d_fifo}_partial.bit ./${dest_dir}/${prj_name}_${pr_0_filter2d_fifo}_partial.bit
exec cp ./${prj_name}/${prj_name}.runs/child_1_impl_1/${bithier}_pr_join_${pr_join_add}_partial.bit ./${dest_dir}/${prj_name}_${pr_join_add}_partial.bit
# child_2_impl_1
exec cp ./${prj_name}/${prj_name}.runs/child_2_impl_1/${bithier}_pr_join_${pr_join_bitand}_partial.bit ./${dest_dir}/${prj_name}_${pr_join_bitand}_partial.bit

