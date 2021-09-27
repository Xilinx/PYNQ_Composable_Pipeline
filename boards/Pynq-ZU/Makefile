# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

overlay_name := cv_dfx_4_pr

all: vision_ip pynq_hls project
	@echo
	@tput setaf 2 ; echo "Built $(overlay_name) successfully!"; tput sgr0;
	@echo

vision_ip:
	make -C ip/vitis_vision/ DEVICE=zynq-us -j4

pynq_hls:
	make -C ../ip/boards/ZCU104/base/ hls_ip

project:
	vivado -mode batch -source $(overlay_name).tcl -notrace
	cp default_paths.json overlay/$(overlay_name)_paths.json

clean:
	rm -rf *.jou *.log NA *.str .Xil/

distclean: clean
	rm -rf $(overlay_name) *.zip

zip:
	@echo "board = $$(basename "$(PWD)")" > overlay/version.txt
	@echo "git_id = $$(git log --format="%H" -n 1)" >> overlay/version.txt
	@echo "date  = $$(date +'%d %B %Y')" >> overlay/version.txt
	@echo "version = $$(grep "version" ../../pynq_composable/__init__.py | cut -d" " -f3 | tr -d \'\")" >> overlay/version.txt
	@echo "---- md5sum                       Files ----" >> overlay/version.txt
	@echo "$$(md5sum $$(ls overlay/*bit overlay/*hwh))" >> overlay/version.txt
	cp LICENSE overlay/LICENSE.txt
	zip -r overlay.zip overlay/