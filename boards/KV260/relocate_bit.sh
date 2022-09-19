#!/bin/bash

# ussage relocate_bit.sh 1
# where the PR number is where the bit fiels are implemented in
dir=$1
s=$2


# copy bit file built at a given PR
for i in `find ./relocatable_modules -name "*\.bit"`
do
  SRCNAME="$(basename $i .bit)"
  cp $i ./${dir}/${SRCNAME}.bit
done 


pushd $dir > /dev/null


# change the name to be the one it is implemented in
for i in `find . -maxdepth 1 -name "*\.bit"`
do
#  echo $i
  SRCNAME="$(basename $i .bit)"
  DSTNAME=$SRCNAME
#  echo "src $SRCNAME"


  for j in {0..2}
  do
    DSTNAME=$(echo "$DSTNAME" | sed "s/composable_pr_$j/composable_pr_$s/")
  done

#  echo "dst $DSTNAME"
  if [ "$SRCNAME" != "$DSTNAME" ]; then
    mv $SRCNAME.bit $DSTNAME.bit
  fi
done


# relocate bitstream to every pr
for i in `find . -maxdepth 1 -name "*\.bit"`
do
#  echo $i
  SRCNAME="$(basename $i .bit)"

  for j in {0..2}
  do
    if [ "$j" != "$s" ]; then
      DSTNAME=$(echo "$SRCNAME" | sed "s/composable_pr_$s/composable_pr_$j/")
      FROM=$SRCNAME
      TO=$DSTNAME
      OFFSET=$((s-j))
#      echo "$s - $j $OFFSET"
      echo ""
      echo ""
#      echo "relocate from PR $s to PR $j (offset $OFFSET)"
      /group/zircon2/pongsto/bin/intellij/idea-IC-221.5080.210/jbr/bin/java -javaagent:/group/zircon2/pongsto/bin/intellij/idea-IC-221.5080.210/lib/idea_rt.jar=46489:/group/zircon2/pongsto/bin/intellij/idea-IC-221.5080.210/bin -Dfile.encoding=UTF-8 -classpath /group/zircon2/pongsto/RW_dev/RapidWright/out/production/RapidWright:/group/zircon2/pongsto/RW_dev/RapidWright/jars/qtjambi-linux64-gcc-4.5.2_01.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-platform-engine-1.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/objenesis-3.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/json-20160810.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jgrapht-core-1.3.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/reflectasm-1.11.9.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-jupiter-engine-5.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/protobuf-java-3.11.4.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-platform-commons-1.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/kryo-5.2.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/annotations-20.1.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/runtime-0.1.13.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/qtjambi-4.5.2_01.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/commons-io-2.11.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-jupiter-api-5.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jeromq-0.5.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/commons-cli-1.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jzlib-1.1.3.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jupyter-kernel-jsr223-1.0.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/opentest4j-1.2.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/minlog-1.3.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-jupiter-params-5.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/apiguardian-api-1.1.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jheaps-0.9.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jython-standalone-2.7.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jnacl-1.0.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jopt-simple-5.0.4.jar:/group/zircon2/pongsto/RW_dev/RapidWright/out/production/RapidWrightXDEF \
        com.xilinx.rapidwright.util.RelocateBitstreamByRow -fr ${FROM}.bit -to ${TO}.bit $OFFSET -series US+
    fi
  done

done


popd > /dev/null

