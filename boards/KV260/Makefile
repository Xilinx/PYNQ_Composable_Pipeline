# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

overlay_name := cv_dfx_3_pr

all: submodule vision_ip pynq_hls project dtbo version
	@echo
	@tput setaf 2 ; echo "Built $(overlay_name) successfully!"; tput sgr0;
	@echo

submodule:
	cd ../../ && git submodule init && git submodule update

vision_ip:
	make -C ../Pynq-ZU/ip/vitis_vision/ DEVICE=zynq-us -j4

pynq_hls:
	make -C ../ip/boards/ZCU104/base/ hls_ip

project:
	vivado -mode batch -source $(overlay_name).tcl -notrace

shell:
	/group/zircon2/pongsto/bin/intellij/idea-IC-221.5080.210/jbr/bin/java -javaagent:/group/zircon2/pongsto/bin/intellij/idea-IC-221.5080.210/lib/idea_rt.jar=38397:/group/zircon2/pongsto/bin/intellij/idea-IC-221.5080.210/bin -Dfile.encoding=UTF-8 -classpath /group/zircon2/pongsto/RW_dev/RapidWright/out/production/RapidWright:/group/zircon2/pongsto/RW_dev/RapidWright/jars/qtjambi-linux64-gcc-4.5.2_01.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-platform-engine-1.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/objenesis-3.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/json-20160810.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jgrapht-core-1.3.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/reflectasm-1.11.9.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-jupiter-engine-5.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/protobuf-java-3.11.4.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-platform-commons-1.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/kryo-5.2.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/annotations-20.1.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/runtime-0.1.13.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/qtjambi-4.5.2_01.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/commons-io-2.11.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-jupiter-api-5.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jeromq-0.5.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/commons-cli-1.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jzlib-1.1.3.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jupyter-kernel-jsr223-1.0.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/opentest4j-1.2.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/minlog-1.3.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/junit-jupiter-params-5.7.1.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/apiguardian-api-1.1.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jheaps-0.9.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jython-standalone-2.7.2.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jnacl-1.0.0.jar:/group/zircon2/pongsto/RW_dev/RapidWright/jars/jopt-simple-5.0.4.jar:/group/zircon2/pongsto/RW_dev/RapidWright/out/production/RapidWrightXDEF com.xilinx.rapidwright.applications.HardwareContractMaker -in $(overlay_name)/$(overlay_name).runs/impl_1/video_cp_wrapper_routed.dcp -fromCell hw_contract_pr1 INT_X0Y60 -to hw_contract_pr0 INT_X0Y120 -to hw_contract_pr2 INT_X0Y0 -out hwctdirect_pr1.dcp
	vivado -mode batch -source build_shell_with_hwct.tcl -tclargs $(overlay_name)

build_all_rm:
	build_all_rm.sh $(overlay_name) relocatable_modules
build_package:	
	build_package.sh $(overlay_name) $(overlay_name)_reloc

dtbo:
	make -C dts/
	cp dts/mipi.dtbo overlay/$(overlay_name).dtbo

clean:
	rm -rf *.jou *.log NA *.str .Xil/

distclean: clean
	rm -rf $(overlay_name) *.zip
	rm *.dcp
	rm *.bit
	rm -rf relocatable_modules

version:
	cp default_paths.json overlay/$(overlay_name)_paths.json
	@echo "board = $$(basename "$(PWD)")" > overlay/version.txt
	@echo "git_id = $$(git log --format="%H" -n 1)" >> overlay/version.txt
	@echo "date  = $$(date +'%d %B %Y')" >> overlay/version.txt
	@echo "version = $$(grep "version" ../../pynq_composable/__init__.py | cut -d" " -f3 | tr -d \'\")" >> overlay/version.txt
	@echo "---- md5sum                       Files ----" >> overlay/version.txt
	@echo "$$(md5sum $$(ls overlay/*bit overlay/*hwh))" >> overlay/version.txt

zip: version
	$(eval ver := $(shell grep "version" ../../pynq_composable/__init__.py | cut -d" " -f3 | tr -d \'\" | tr . _))
	cp LICENSE overlay/LICENSE.txt
	zip -r composable-video-pipeline-KV260-v$(ver).zip overlay/

dict:
	python3 ../../pynq_composable/parser.py --hwh overlay/$(overlay_name).hwh
