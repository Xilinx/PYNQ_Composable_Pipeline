# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


from .mock_device import MockIPDevice, MockRegisterIP
import numpy as np
import pynq
from pynq_composable import switch
import pytest

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"

desc = {"parameters":
        {"C_BASEADDR": "0x0", "C_HIGHADDR": "0xFFFF", "NUM_MI": 8},
        "phys_addr": 0x0, "addr_range": 0xFFFF}

test_data = [(np.arange(desc["parameters"]["NUM_MI"], dtype=np.int64),
              {'64': 0, '68': 1, '72': 2, '76': 3, '80': 4, '84': 5, '88': 6,
               '92': 7, '0': 2}),
             (np.arange(5, dtype=np.int64),
              {'64': 0, '68': 1, '72': 2, '76': 3, '80': 4, '84': 1 << 31,
               '88': 1 << 31, '92': 1 << 31, '0': 2}),
             (np.ones(desc["parameters"]["NUM_MI"], dtype=np.int64)*-1,
              {'64': 1 << 31, '68': 1 << 31, '72': 1 << 31, '76': 1 << 31,
               '80': 1 << 31, '84': 1 << 31, '88': 1 << 31, '92': 1 << 31,
               '0': 2}),
             (np.array([7, 3, 4, 2, 1, 0, 5, 6], dtype=np.int64),
              {'64': 7, '68': 3, '72': 4, '76': 2, '80': 1, '84': 0, '88': 5,
               '92': 6, '0': 2}),
             {'64': 0, '68': 1, '72': 2, '76': 3, '80': 4, '84': 5, '88': 6,
              '92': 7, '0': 2},
             {'64': 1 << 31, '68': 1 << 31, '72': 1 << 31, '76': 1 << 31,
              '80': 1 << 31, '84': 1 << 31, '88': 1 << 31, '92': 1 << 31,
              '0': 2}]


@pytest.fixture
def registerip():
    ip = MockRegisterIP(desc["phys_addr"], desc["addr_range"])
    yield ip


@pytest.fixture
def ipdevice(registerip):
    device = MockIPDevice(registerip, "ipdevice")
    pynq.Device.active_device = device
    yield device
    pynq.Device.active_device = None


def test_wrong_type(ipdevice):
    sw = switch.StreamSwitch(desc)
    with pytest.raises(TypeError) as excinfo:
        sw.mi = np.ones(5, dtype=np.int32)
    assert str(excinfo.value) == "Numpy array must be np.int64 dtype"


def test_too_long(ipdevice):
    sw = switch.StreamSwitch(desc)
    with pytest.raises(ValueError) as excinfo:
        sw.mi = np.ones(20, dtype=np.int64)
    assert str(excinfo.value) == "Provided numpy array is bigger than number "\
        "of slots {}".format(desc["parameters"]["NUM_MI"])


def test_too_short(ipdevice):
    sw = switch.StreamSwitch(desc)
    with pytest.raises(ValueError) as excinfo:
        sw.mi = np.ones(0, dtype=np.int64)
    assert str(excinfo.value) == "Input numpy array must be at least one "\
        "element long"


def test_data0(ipdevice):
    sw = switch.StreamSwitch(desc)
    sw.mi = test_data[0][0]
    assert ipdevice.ip.memory == test_data[0][1]


def test_data_smaller_array(ipdevice):
    sw = switch.StreamSwitch(desc)
    sw.mi = test_data[1][0]
    assert ipdevice.ip.memory == test_data[1][1]


def test_data_disable0(ipdevice):
    sw = switch.StreamSwitch(desc)
    sw.mi = test_data[2][0]
    assert ipdevice.ip.memory == test_data[2][1]


def test_data_disable1(ipdevice):
    sw = switch.StreamSwitch(desc)
    sw.mi = test_data[3][0]
    assert ipdevice.ip.memory == test_data[3][1]


def test_data_default(ipdevice):
    sw = switch.StreamSwitch(desc)
    sw.default()
    assert ipdevice.ip.memory == test_data[4]


def test_data_all_disabled(ipdevice):
    sw = switch.StreamSwitch(desc)
    sw.disable()
    assert ipdevice.ip.memory == test_data[5]


def test_data_return(ipdevice):
    sw = switch.StreamSwitch(desc)
    tvector = np.arange(desc["parameters"]["NUM_MI"], dtype=np.int64)
    sw.mi = tvector
    assert np.array_equal(sw.mi, tvector)
