# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq_composable import DifferenceGaussians, CornerDetect, \
    ColorDetect, EdgeDetect, VSource, VSink
import pytest
import time


apps = [
    "DifferenceGaussians(pytest.overlay, VSource.OpenCV, VSink.DP)",
    "CornerDetect(pytest.overlay, VSource.OpenCV, VSink.DP)",
    "ColorDetect(pytest.overlay, VSource.OpenCV, VSink.DP)",
    "EdgeDetect(pytest.overlay, VSource.OpenCV, VSink.DP)"
]


@pytest.mark.skipif(not pytest.webcam, reason="Web Camera is not detected")
@pytest.mark.parametrize('obj', apps)
def test_diff_gaussians(obj):
    app = eval(obj)
    app.start()
    time.sleep(5)
    app.stop()
    assert True
