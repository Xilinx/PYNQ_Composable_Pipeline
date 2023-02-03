# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


import pytest
from pynq_composable import repr_dict

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"

_loaded = {
    'lut_accel': {'dfx': False, 'loaded': True},
    'rgb2gray_accel': {'dfx': False, 'loaded': True},
    'filter2d_accel': {'dfx': False, 'loaded': True},
    'pr_0/filter2d_accel': {'dfx': True, 'loaded': True}
}

_unloaded = {
    'pr_0/fast_accel': {'dfx': True, 'loaded': False},
    'pr_1/filter2d_accel': {'dfx': True, 'loaded': False}
}

_dfx = {
    'pr_0/filter2d_accel': {'dfx': True, 'loaded': True},
    'pr_0/fast_accel': {'dfx': True, 'loaded': False},
    'pr_1/filter2d_accel': {'dfx': True, 'loaded': False}
}

_default = {
    'ps_video_in': {'dfx': False, 'loaded': True, 'default': True},
    'ps_video_out': {'dfx': False, 'loaded': True, 'default': True}
}


@pytest.fixture
def reprdictionary():
    test_dict = dict(_loaded)
    test_dict.update(_unloaded)
    test_dict.update(_default)
    c_dict = repr_dict.ReprDictComposable(test_dict, rootname="composable")
    yield c_dict


def test_loaded(reprdictionary):
    test_dict = reprdictionary.loaded
    loaded_dict = dict(_loaded)
    loaded_dict.update(_default)
    assert test_dict == loaded_dict


def test_unloaded(reprdictionary):
    test_dict = reprdictionary.unloaded
    assert test_dict == _unloaded


def test_dfx(reprdictionary):
    test_dict = reprdictionary.dfx
    assert test_dict == _dfx


def test_default(reprdictionary):
    test_dict = reprdictionary.default
    assert test_dict == _default


def test_global(reprdictionary):
    c_dict = dict(_default)
    c_dict.update(_loaded)
    c_dict.update(_unloaded)
    assert reprdictionary == c_dict


def test_json_repr(reprdictionary):
    assert reprdictionary._repr_json_()
