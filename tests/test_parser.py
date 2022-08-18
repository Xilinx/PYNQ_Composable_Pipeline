# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


import pytest
import hashlib
import pickle as pkl
from pynq_composable import parser

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


hwhfilename = "tests/files/cv_dfx_2pipes.hwh"
pklfile0 = "tests/files/cv_dfx_2pipes_pipeline0.pkl"
pklfile1 = "tests/files/cv_dfx_2pipes_pipeline1.pkl"


def _get_hwh_digest(filename):
    with open(filename, 'rb') as file:
        hwhdigest = hashlib.md5(file.read()).hexdigest()
    return hwhdigest


def _get_pickled_dict(filename):
    with open(filename, "rb") as file:
        return pkl.load(file)


_hwhdigest = _get_hwh_digest(hwhfilename)
_cached_digest0, _c_dict0, _dfx_dict0 = _get_pickled_dict(pklfile0)
_cached_digest1, _c_dict1, _dfx_dict1 = _get_pickled_dict(pklfile1)


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
    assert _hwhdigest == _cached_digest0


def test_switch1():
    switch = "pipeline1/axis_switch"
    hwhparser = parser.HWHComposable(hwhfilename, switch, False, True)
    assert _c_dict1 == hwhparser.c_dict
    assert _dfx_dict1 == hwhparser.dfx_dict
    assert _hwhdigest == _cached_digest1


def test_dfx():
    filename = "tests/files/cv_dfx_3_pr.hwh"
    pklfile_composable = "tests/files/cv_dfx_3_pr_composable.pkl"
    switch = "composable/axis_switch"
    _, c_dict, dfx_dict = _get_pickled_dict(pklfile_composable)
    hwhparser = parser.HWHComposable(filename, switch, False, True)

    from deepdiff import DeepDiff
    excludedRegex = [r"root\[\'.*'\]\['bitstream'\]"]
    diff = DeepDiff(c_dict, hwhparser.c_dict,
                    exclude_regex_paths=excludedRegex)
    assert not diff
    excludedRegex = [
        r"root\[\'.*'\]\['rm'\]\[\'.*'\]\[\'.*'\]\['bitstream'\]"
    ]
    diff = DeepDiff(dfx_dict, hwhparser.dfx_dict,
                    exclude_regex_paths=excludedRegex)

    assert not diff
