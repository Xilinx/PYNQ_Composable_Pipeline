# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"

import pytest
import hashlib
import pickle as pkl
from composable_pipeline import parser

hwhfilename = "cv_dfx_2pipes.hwh"
pklfile0 = "cv_dfx_2pipes_pipeline0.pkl"
pklfile1 = "cv_dfx_2pipes_pipeline1.pkl"

with open(pklfile0, "rb") as file:
    _cached_digest0, _c_dict0, _dfx_dict0 = pkl.load(file)
    
with open(pklfile1, "rb") as file:
    _cached_digest1, _c_dict1, _dfx_dict1 = pkl.load(file)

with open(hwhfilename, 'rb') as file:
    hwhdigest = hashlib.md5(file.read()).hexdigest()

def test_file():
    filename = 'nofile.hwh'
    with pytest.raises(FileNotFoundError) as fileinfo:
        parser.HWHComposable(filename, 'noswitch', False)
    assert str(fileinfo.value) == \
        "[Errno 2] No such file or directory: 'nofile.hwh'"


def test_bad_switch():
    switch = "badswitch"
    with pytest.raises(AttributeError) as attrinfo:
        parser.HWHComposable(hwhfilename, switch, False)
    assert str(attrinfo.value) == \
        "AXI4-Switch {} does not exist in the hwh file".format(switch)


def test_switch0():
    switch = "pipeline0/axis_switch"
    hwhparser = parser.HWHComposable(hwhfilename, switch, False)
    assert _c_dict0 == hwhparser.c_dict
    assert _dfx_dict0 == hwhparser.dfx_dict
    assert hwhdigest == _cached_digest0


def test_switch1():
    switch = "pipeline1/axis_switch"
    hwhparser = parser.HWHComposable(hwhfilename, switch, False)
    assert _c_dict1 == hwhparser.c_dict
    assert _dfx_dict1 == hwhparser.dfx_dict
    assert hwhdigest == _cached_digest1
