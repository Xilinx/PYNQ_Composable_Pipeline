# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from .mock_device import MockIP, MockCPipe
from pynq_composable import virtual
import pytest


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


def test_streaming_ip():
    name = "highpass_fir"
    ip = virtual.StreamingIP(name)
    assert ip._fullpath == name


def test_buffer_ip():
    name = "filter2d"
    ip = virtual.BufferIP(name)
    assert ip._fullpath == name


def test_dfx_region():
    cpipe = MockCPipe()
    dfx = virtual.DFXRegion(cpipe, "pr_0")
    assert dfx
    lut = dfx.lut_accel
    assert isinstance(lut, virtual.VirtualIP)
    name = "rgb2gray_accel"
    setattr(dfx._ol, "composablepr_0/" + name, name)
    rgb = dfx.rgb2gray_accel
    rgb2 = getattr(dfx, name)
    assert rgb == name
    assert rgb2 == name


def test_dfx_buffer_ip():
    cpipe = MockCPipe()
    dfx = virtual.DFXRegion(cpipe, "pr_0")
    fifo = dfx.fifo
    assert isinstance(fifo, virtual.BufferIP)


def test_invalid_ip():
    cpipe = MockCPipe()
    dfx = virtual.DFXRegion(cpipe, "pr_0")
    with pytest.raises(ValueError) as excinfo:
        dfx.rgb2gray
    assert str(excinfo.value) == "IP \'{}\' does not exist in partial "\
                                 "region \'{}\'".format("rgb2gray", "pr_0")


def test_virtual_loaded_ip():
    cpipe = MockCPipe("")
    name = "rgb2gray_accel"
    vip = virtual.VirtualIP(cpipe, "pr_0" + name)
    setattr(cpipe._ol, "pr_0" + name, MockIP(name))
    assert vip.rgb2gray_accel == name


def test_virtual_unloaded_ip():
    cpipe = MockCPipe("")
    name = "rgb2gray_accel"
    vip = virtual.VirtualIP(cpipe, "pr_0" + name)
    cpipe._c_dict["pr_0rgb2gray_accel"]["loaded"] = False
    setattr(cpipe._ol, "pr_0" + name, MockIP(name))
    with pytest.raises(AttributeError) as excinfo:
        vip.rgb2gray_accel
    assert str(excinfo.value) == "\'{}{}\' is not loaded, load IP before "\
                                 "using it".format("pr_0", name)
