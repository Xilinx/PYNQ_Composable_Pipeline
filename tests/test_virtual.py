# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq_composable import virtual

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


def test_streaming_ip():
    name = 'highpass_fir'
    ip = virtual.StreamingIP(name)
    assert ip._fullpath == name


def test_buffer_ip():
    name = 'filter2d'
    ip = virtual.BufferIP(name)
    assert ip._fullpath == name
