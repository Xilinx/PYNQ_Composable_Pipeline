# Copyright (C) 2021 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause

.PHONY:all 

DIRECTORIES  = $(shell ls ../../../../src)
HLS_PROJECTS = $(addsuffix  .vhlsprj, $(DIRECTORIES))

all: $(HLS_PROJECTS)

DEVICE ?= zynq
PERIOD ?= 6.4
FPGAPART ?= xc7z020clg400-1
DEVICE_MACRO := _ZYNQ_
VITIS_LIB_INCLUDE = $(shell readlink -f ../../../../Vitis_Libraries/vision/L1/include/)


ifeq ($(DEVICE),zynq-us)
	FPGAPART = xczu5eg-sfvc784-1-e
	PERIOD = 3.3
	DEVICE_MACRO = _ZYNQ_US_
endif

%.vhlsprj:
	vitis_hls -f script_hls.tcl -tclargs $(subst .vhlsprj,,$@) $(FPGAPART) $(PERIOD) $(VITIS_LIB_INCLUDE) $(DEVICE_MACRO)

clean:
	rm -rf *.log *.jou *.str

distclean: clean
	rm -rf *.vhlsprj
