# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq_composable import DifferenceGaussians, CornerDetect, \
    ColorDetect, EdgeDetect, VSource, VSink
import pytest
import time


apps = [
    "DifferenceGaussians(pytest.overlay, VSource.OpenCV, sink, file=file)",
    "CornerDetect(pytest.overlay, VSource.OpenCV, sink, file=file)",
    "ColorDetect(pytest.overlay, VSource.OpenCV, sink, file=file)",
    "EdgeDetect(pytest.overlay, VSource.OpenCV, sink, file=file)"
]


@pytest.mark.skipif(not pytest.webcam and not pytest.videofile,
                    reason='Web Camera or Video file not found')
@pytest.mark.parametrize('obj', apps)
def test_apps(obj):
    file = '../mountains.mp4' if pytest.videofile else 0
    sink = VSink.DP if pytest.board == 'KV260' else VSink.HDMI
    app = eval(obj)
    app._cpipe._graph_debug = True
    app.start()
    time.sleep(5)
    status = app._video._video._started and app._video._video._running
    label = 'FAILED\n'
    color = 'red'
    if status:
        label = 'PASSED\n'
        color = 'green'
    label = label + pytest.overlay

    app._cpipe.graph.attr(label=label, _attributes={'fontcolor': color})
    name = ('passed' if status else 'failed') + f'/app_{apps.index(obj)}'
    app._cpipe.graph.render(format='png', outfile=f'result_tests/{name}.png')
    app.stop()
    assert status
