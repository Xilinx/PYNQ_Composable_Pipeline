# assign cells connecting to rp to pblock_rp_intf
# Assumptions:
# 1) there are companion pblocks, pblock_s_intf
# 2) all the cells in hw_contract_rp${i} are assigned to pblock_s_intf_pr${i} before calling these, ie., in xdc. 

proc get_cells_connect_to_rp {rp_id} {
  ;# filter clock out or get get 660 cells for an RP. Leave the filter to make it clear.
  set rp_intf_nets [get_nets video_cp_i/composable/dfx_decouplers/hw_contract/hw_contract_pr${rp_id}/dfx_decoupler/rp_* -filter {TYPE!="GLOBAL_CLOCK"}]
  
  set intf_cells [list]
  
  foreach n $rp_intf_nets {
    ;# need -leaf to get the 
    foreach p [get_pins -leaf -of $n] {
      set c [get_cells -of $p]
      if {[regexp {dfx_decouplers} $c]} {
        lappend intf_cells $c  
      }
    }
  }
  puts "Found [llength $intf_cells] interface cell to RP_${rp_id}"
  return $intf_cells
}

add_cells_to_pblock pblock_rp_intf_pr0 [get_cells_connect_to_rp 0]
add_cells_to_pblock pblock_rp_intf_pr1 [get_cells_connect_to_rp 1]
add_cells_to_pblock pblock_rp_intf_pr2 [get_cells_connect_to_rp 2]


############################# To make sure these clocks use the same clock track number #######################################
#place_cell [get_cells "video_cp_i/composable/clk_buf_rp0/U0/USE_BUFG.GEN_BUFG[0].BUFG_U"]  BUFGCE_X0Y60
#place_cell [get_cells "video_cp_i/composable/clk_buf_rp1/U0/USE_BUFG.GEN_BUFG[0].BUFG_U"]  BUFGCE_X0Y36
#place_cell [get_cells "video_cp_i/composable/clk_buf_rp2/U0/USE_BUFG.GEN_BUFG[0].BUFG_U"]  BUFGCE_X0Y12


