#!/bin/bash
# usage: ./build_all_rm.sh cv_dfx_3_12k16kfifo_4_ag

#prj_dir=/group/zircon2/pongsto/projects/PYNQ_pipeline/homogeneous_3rp/implementation/project/$1 
#prj_dir=/group/zircon2/pongsto/projects/PYNQ_pipeline/homogeneous_3rp/implementation/project/21.2/PYNQ_Composable_Pipeline/boards/KV260/cv_dfx_3_pr
#prj_dir= ../../../project/cv_dfx_3_pr
prj_dir=$1
out_dir=$2

# list of source function for relocation. 
# Note composable_pr_1_dilate_erode is needed but it will be relocated from composable_pr_0_dilate_erode.
# Thus, it is not listed.
allRMs=( \
  composable_pr_0_dilate_erode_inst_0       \
  composable_pr_0_fast_fifo_inst_0          \
  composable_pr_0_filter2d_fifo_inst_0      \
  composable_pr_1_cornerharris_fifo_inst_0  \
  composable_pr_1_rgb2xyz_fifo_inst_0       \
  composable_pr_2_bitand_inst_0             \
  composable_pr_2_absdiff_inst_0            \
  composable_pr_2_subtract_inst_0           \
  composable_pr_2_add_inst_0                \
)


if [ -d "$out_dir" ]; then
    printf '%s\n' "Removing directory ($out_dir)"
    rm -rf "$out_dir"
fi    
mkdir $out_dir




pushd $out_dir > /dev/null
for rm in ${allRMs[@]}; do
  mkdir $rm
  pushd $rm > /dev/null
#  bsub vivado -mode batch -source ../implement_rm.tcl -tclargs $prj_dir $rm
  bsub -R 'select[type=X86_64 && osdistro=centos && osver=ws7]' -N -R 'rusage[mem=20000]' -o result.log -e result.log "vivado -mode batch -source ../../implement_rm.tcl -tclargs $prj_dir $rm"
#  vivado -source ../implement_rm.tcl -tclargs $prj_dir $rm
  popd      > /dev/null
done
popd      > /dev/null
