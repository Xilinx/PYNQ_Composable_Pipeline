#!/bin/bash

#PRJ_NAME=cv_dfx_3_12k16kfifo_4_ag
PRJ_NAME=$1
PKG_NAME=$2
#HWH_DIR=../rm/overlay_3
#HWH_DIR=/group/zircon2/pongsto/projects/PYNQ_pipeline/homogeneous_3rp/implementation/project/21.2/PYNQ_Composable_Pipeline/boards/KV260/overlay
HWH_DIR=./overlay
#SHELL=../shell1/$PRJ_NAME.bit
SHELL=./full_shell.bit

if [ -d "$PKG_NAME" ]; then rm -Rf $PKG_NAME; fi
mkdir $PKG_NAME


relocate_bit.sh $PKG_NAME 1


echo "Copy the shell bit file $SHELL"
cp $SHELL ./$PKG_NAME/${PRJ_NAME}.bit
echo "Copy hwh file from directory $HWH_DIR"
cp $HWH_DIR/*.hwh ./$PKG_NAME
#echo "Copy bit files"            
#for i in `find . -maxdepth 1 -name "*\.bit"`
#do
#  SRCNAME="$(basename $i .bit)"
##  echo $SRCNAME $i
#  cp $i ./$PKG_NAME/${PRJ_NAME}_${SRCNAME}.bit
##  cp $i ./$PKG_NAME/${SRCNAME}.bit
#done


# copy and change hwh so that each function is in PR0,PR1,PR2
echo "Copy hwh file of a function to every PR"
pushd $PKG_NAME > /dev/null
for i in `find . -maxdepth 1 -name "*\.hwh"`
do
  SRCNAME=$i

  if [[ "$i" =~ _pr_([0-9]) ]]; then  
    s=${BASH_REMATCH[1]}
#    echo $i $s
    echo "  Process from $s , $i"
    for j in {0..2}
    do
    if [ "$s" != "$j" ]; then
#      echo "do $j"
      echo "    Copy to PR $j"
      DSTNAME=$(echo "$SRCNAME" | sed "s/composable_pr_$s/composable_pr_$j/")
      cp $SRCNAME $DSTNAME
      sed -i "s/composable_pr_${s}_/composable_pr_${j}_/"  $DSTNAME
    fi
    done
  else
    echo "skip $i"
  fi
done
popd > /dev/null


