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
def test_apps(obj):
    app = eval(obj)
    app.start()
    name = f'app_{apps.index(obj)}'
    app._cpipe.graph.render(format='png', outfile=f'result_tests/{name}.png')
    time.sleep(5)
    status = app._video._video._started and app._video._video._running
    with open(f'result_tests/{name}.txt', 'w') as f:
        f.write(f'pipeline: {str(obj)}\n')
        f.write(f'Pass status: {status}\n')
        f.write(f'Pipeline graph: {name}.png\n')
    app.stop()
    assert status
