# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq_composable import DifferenceGaussians, CornerDetect, \
    ColorDetect, EdgeDetect, VSource, VSink
import pytest
import time


def test_diff_gaussians():
    app = DifferenceGaussians(pytest.overlay, VSource.OpenCV, VSink.DP)
    app.start()
    time.sleep(5)
    app.stop()
    assert True


def test_corner():
    app = CornerDetect(pytest.overlay, VSource.OpenCV, VSink.DP)
    app.start()
    time.sleep(5)
    app.stop()
    assert True


def test_color():
    app = ColorDetect(pytest.overlay, VSource.OpenCV, VSink.DP)
    app.start()
    time.sleep(5)
    app.stop()
    assert True


def test_edge():
    app = EdgeDetect(pytest.overlay, VSource.OpenCV, VSink.DP)
    app.start()
    time.sleep(5)
    app.stop()
    assert True
