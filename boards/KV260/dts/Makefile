# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

DTB = mipi

all:
	dtc -I dts -O dtb -o $(DTB).dtbo $(DTB).dtsi

clean:
	rm -rf $(DTB).dtbo