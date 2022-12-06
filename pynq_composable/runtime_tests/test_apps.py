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
    app._cpipe._graph_debug = True
    app.start()
    time.sleep(5)
    status = app._video._video._started and app._video._video._running
    if status:
        app._cpipe.graph.attr(label=r'PASSED',
                              _attributes={"fontcolor": "green"})
    else:
        app._cpipe.graph.attr(label=r'FAILED',
                              _attributes={"fontcolor": "red"})

    name = f'app_{apps.index(obj)}_' + ('passed' if status else 'failed')
    app._cpipe.graph.render(format='png', outfile=f'result_tests/{name}.png')
    app.stop()
    assert status
