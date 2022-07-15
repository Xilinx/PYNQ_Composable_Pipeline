# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np
from pynq import Overlay
from pynq.lib.video import VideoMode
from pynq_composable import Composable, StreamSwitch, VitisVisionIP, \
    CornerHarris
from pynq_composable.virtual import VirtualIP, BufferIP
import pytest


@pytest.fixture
def create_overlay():
    for i in range(5):
        try:
            ol = Overlay("cv_dfx_3_pr.bit")
        except OSError:
            if i != 4:
                continue
            raise OSError("Could not program the FPGA")
    yield ol
    ol.free()


@pytest.fixture
def create_composable(create_overlay):
    ol = create_overlay
    cpipe = ol.composable
    yield ol, cpipe


def test_overlay_type(create_overlay):
    ol = create_overlay
    assert type(ol) == Overlay


def test_overlay_ip_dict(create_overlay):
    ol = create_overlay
    assert ol.ip_dict


def test_composable_overlay_dict(create_composable):
    """Test if dictionaries are not empty"""
    _, cpipe = create_composable
    assert cpipe.c_dict
    assert cpipe.dfx_dict


def test_switch_default_config(create_composable):
    """Test if dictionaries are not empty"""
    _, cpipe = create_composable
    assert cpipe.axis_switch.mi[0] == 0


def test_composable_drivers(create_composable):
    """Test if drivers have been assigned properly"""
    ol, cpipe = create_composable
    assert type(cpipe) == Composable
    assert type(ol.composable.axis_switch) == StreamSwitch
    assert type(ol.composable.rgb2gray_accel) == VitisVisionIP
    assert type(ol.composable.gray2rgb_accel) == VitisVisionIP
    assert type(cpipe.pr_0.axis_data_fifo_0) == VirtualIP
    assert type(cpipe.pr_1.cornerHarris_accel) == VirtualIP


def load_ip(cpipe: Composable) -> None:
    cpipe.load([cpipe.pr_0.axis_data_fifo_0, cpipe.pr_1.cornerHarris_accel,
                cpipe.pr_2.bitwise_and_accel])


@pytest.mark.dependency()
def test_load_dfx_ip(create_composable):
    """Load some IP and verify if drivers have been assigned properly"""
    ol, cpipe = create_composable
    load_ip(cpipe)
    assert type(cpipe.pr_0.axis_data_fifo_0) == BufferIP
    assert type(cpipe.pr_1.cornerHarris_accel) == CornerHarris
    assert type(cpipe.pr_2.bitwise_and_accel) == VitisVisionIP


@pytest.mark.dependency(depends=["test_load_dfx_ip"])
def test_pipeline_0(create_composable):
    ol, cpipe = create_composable
    load_ip(cpipe)
    pipeline = [cpipe.ps_video_in, cpipe.rgb2gray_accel, cpipe.lut_accel,
                cpipe.pr_1.cornerHarris_accel, cpipe.pr_0.axis_data_fifo_0,
                cpipe.gray2rgb_accel, cpipe.ps_video_out]
    cpipe.compose(pipeline)
    assert cpipe.current_pipeline == pipeline
    assert cpipe.graph.body


@pytest.mark.dependency(depends=["test_load_dfx_ip"])
def test_pipeline_1(create_composable):
    ol, cpipe = create_composable
    load_ip(cpipe)
    pipeline = [cpipe.ps_video_in, cpipe.duplicate_accel,
                [[cpipe.rgb2gray_accel, cpipe.pr_1.cornerHarris_accel],
                 [cpipe.lut_accel]], cpipe.pr_2.bitwise_and_accel,
                cpipe.pr_0.axis_data_fifo_0, cpipe.gray2rgb_accel,
                cpipe.ps_video_out]

    cpipe.compose(pipeline)
    """Check if composed correctly"""
    assert cpipe.current_pipeline == pipeline
