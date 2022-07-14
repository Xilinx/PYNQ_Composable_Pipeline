# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np
from pynq import Overlay
from pynq_composable import Composable, StreamSwitch, VitisVisionIP, \
    CornerHarris
from pynq_composable.virtual import VirtualIP, BufferIP


def main():
    ol = Overlay("cv_dfx_3_pr.bit")
    cpipe = ol.composable

    """Test if dictionaries are created"""
    assert cpipe.c_dict
    assert cpipe.dfx_dict

    """Test if drivers have been assigned properly"""
    assert type(cpipe) == Composable
    assert type(ol.composable.axis_switch) == StreamSwitch
    assert type(ol.composable.rgb2gray_accel) == VitisVisionIP
    assert type(ol.composable.gray2rgb_accel) == VitisVisionIP
    assert type(cpipe.pr_0.axis_data_fifo_0) == VirtualIP
    assert type(cpipe.pr_1.cornerHarris_accel) == VirtualIP

    assert cpipe.current_pipeline is None
    assert cpipe.graph.body == []

    initial_conf = cpipe.axis_switch.mi
    assert initial_conf[0] == 0

    """Load some IP and verify if drivers have been assigned properly"""
    cpipe.load([cpipe.pr_0.axis_data_fifo_0, cpipe.pr_1.cornerHarris_accel,
                cpipe.pr_2.bitwise_and_accel])

    assert type(cpipe.pr_0.axis_data_fifo_0) == BufferIP
    assert type(cpipe.pr_1.cornerHarris_accel) == CornerHarris
    assert type(cpipe.pr_2.bitwise_and_accel) == VitisVisionIP

    pipeline = [cpipe.ps_video_in, cpipe.rgb2gray_accel, cpipe.lut_accel,
                cpipe.pr_1.cornerHarris_accel, cpipe.pr_0.axis_data_fifo_0,
                cpipe.gray2rgb_accel, cpipe.ps_video_out]
    cpipe.compose(pipeline)

    """Check if composed correctly"""
    assert cpipe.current_pipeline == pipeline
    assert cpipe.graph.body
    conf_0 = cpipe.axis_switch.mi
    assert not np.array_equal(initial_conf, conf_0)
    """Check a branched pipeline"""
    pipeline = [cpipe.ps_video_in, cpipe.duplicate_accel,
                [[cpipe.rgb2gray_accel, cpipe.pr_1.cornerHarris_accel],
                 [cpipe.lut_accel]], cpipe.pr_2.bitwise_and_accel,
                cpipe.pr_0.axis_data_fifo_0, cpipe.gray2rgb_accel,
                cpipe.ps_video_out]

    cpipe.compose(pipeline)
    """Check if composed correctly"""
    assert cpipe.current_pipeline == pipeline
    conf_1 = cpipe.axis_switch.mi
    assert not np.array_equal(conf_0, conf_1)


if __name__ == "__main__":
    main()
