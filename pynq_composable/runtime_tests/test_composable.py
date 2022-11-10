# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np
import os
from pynq import Overlay
from pynq.lib.video import VideoMode
from pynq_composable import Composable, StreamSwitch, VitisVisionIP, \
    CornerHarris
from pynq_composable.virtual import VirtualIP, BufferIP
from pynq_composable.libs import XvLut, _cols, _rows
import pytest
import shutil
import time


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
def test_parser(tmp_path):
    dir = tmp_path / "hwh"
    shutil.copytree("../overlay/", dir)
    for item in os.listdir(str(dir)):
        if item.endswith(".pkl"):
            os.remove(os.path.join(str(dir), item))

    ol = Overlay(os.path.join(str(dir), "cv_dfx_3_pr.bit"))
    cpipe = ol.composable
    pklfile = "../overlay/cv_dfx_3_pr_composable.pkl"
    if os.path.isfile(pklfile):
        import pickle as pkl
        from deepdiff import DeepDiff
        with open(pklfile, "rb") as file:
            _, c_dict, dfx_dict = pkl.load(file)

        excludedRegex = [r"root\[\'.*'\]\['bitstream'\]"]
        diff = DeepDiff(cpipe._c_dict, c_dict,
                        exclude_regex_paths=excludedRegex)
        if 'dictionary_item_added' in diff.keys():
            del[diff['dictionary_item_added']]
        if 'dictionary_item_removed' in diff.keys():
            del[diff['dictionary_item_removed']]

        assert not diff
        excludedRegex = [
            r"root\[\'.*'\]\['rm'\]\[\'.*'\]\[\'.*'\]\['bitstream'\]"
        ]
        diff = DeepDiff(cpipe._dfx_dict, dfx_dict,
                        exclude_regex_paths=excludedRegex)
        assert not diff

    else:
        assert cpipe.c_dict
        assert cpipe.dfx_dict


@pytest.mark.dependency()
def test_load_dfx_ip(create_composable):
    """Load some IP and verify if drivers have been assigned properly"""
    ol, cpipe = create_composable
    load_ip(cpipe)
    assert type(cpipe.pr_0.axis_data_fifo_0) == BufferIP
    assert type(cpipe.pr_1.cornerHarris_accel) == CornerHarris
    assert type(cpipe.pr_2.bitwise_and_accel) == VitisVisionIP


@pytest.mark.dependency(depends=["test_parser", "test_load_dfx_ip"])
def test_pipeline_0(create_composable):
    ol, cpipe = create_composable
    load_ip(cpipe)
    pipeline = [cpipe.ps_video_in, cpipe.rgb2gray_accel, cpipe.lut_accel,
                cpipe.pr_1.cornerHarris_accel, cpipe.pr_0.axis_data_fifo_0,
                cpipe.gray2rgb_accel, cpipe.ps_video_out]
    cpipe.compose(pipeline)
    assert cpipe.current_pipeline == pipeline
    assert cpipe.graph.body


@pytest.mark.dependency(depends=["test_parser", "test_load_dfx_ip"])
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


@pytest.mark.timeout(60)
@pytest.mark.dependency(depends=["test_parser", "test_load_dfx_ip"])
def test_data_movement_fifo(create_composable):
    ol, cpipe = create_composable
    load_ip(cpipe)
    pipeline = [cpipe.ps_video_in, cpipe.pr_0.axis_data_fifo_0,
                cpipe.pr_1.axis_data_fifo_0, cpipe.ps_video_out]
    cpipe.compose(pipeline)
    """Check if composed correctly"""
    assert cpipe.current_pipeline == pipeline

    mode = VideoMode(_cols, _rows, 24)
    writechannel = ol.video.axi_vdma.writechannel
    readchannel = ol.video.axi_vdma.readchannel
    writechannel.mode = readchannel.mode = mode
    writechannel.start()
    readchannel.start()

    frame = writechannel.newframe()
    res = np.empty(shape=frame.shape, dtype=np.uint8)
    frame[:] = np.random.randint(0, 255, size=frame.shape, dtype=np.uint8)
    writechannel.writeframe(frame)
    time.sleep(1)
    res[:] = readchannel.readframe()

    writechannel.stop()
    readchannel.stop()
    assert np.array_equal(frame, res)


@pytest.mark.timeout(60)
@pytest.mark.dependency(depends=["test_parser"])
def test_data_movement_lut_negative(create_composable):
    ol, cpipe = create_composable
    cpipe.lut_accel.kernel_type = XvLut.negative
    pipeline = [cpipe.ps_video_in, cpipe.lut_accel, cpipe.ps_video_out]
    cpipe.compose(pipeline)
    """Check if composed correctly"""
    assert cpipe.current_pipeline == pipeline

    mode = VideoMode(_cols, _rows, 24)
    writechannel = ol.video.axi_vdma.writechannel
    readchannel = ol.video.axi_vdma.readchannel
    writechannel.mode = readchannel.mode = mode
    writechannel.start()
    readchannel.start()

    frame = writechannel.newframe()
    golden = np.empty(shape=frame.shape, dtype=np.uint8)
    for c in range(frame.shape[1]):
        value = c % 255
        frame[:, c, :] = value
        golden[:, c, :] = 255 - value
    writechannel.writeframe(frame)
    time.sleep(1)
    res = readchannel.readframe()
    writechannel.stop()
    readchannel.stop()
    assert np.array_equal(golden, res)
