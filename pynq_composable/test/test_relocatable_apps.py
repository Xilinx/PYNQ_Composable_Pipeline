# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq_composable import Composable, VideoStream, VSource, VSink
import pytest
from pynq import Overlay
import time
import itertools


"""

1. Define list of partial bitstreams per app
2. Create permutation list
3. Download partial bitstreams
4. iterate over the pipeline to get the actual object
5. compose
6. start video
7. Wait for 5 secs
8.

"""

app_construct = [
    (['subtract', 'filter2d'],
     ['ps_video_in', 'filter2d_accel', 'duplicate_accel',
      [['pr/filter2d_accel'], [1]],
      'pr/subtract_accel', 'lut_accel', 'ps_video_out']),

    (['fast', 'add'], ['ps_video_in', 'duplicate_accel',
     [['rgb2gray_accel', 'pr/fast', 'gray2rgb_accel'], [1]],
     'pr/add_accel', 'ps_video_out']),

    (['cornerharris', 'add'], ['ps_video_in', 'duplicate_accel',
     [['rgb2gray_accel', 'pr/cornerHarris', 'gray2rgb_accel'], [1]],
     'pr/add_accel', 'ps_video_out']),
]


def generate_valid_permutations(dfx_ip: list, cpipe) -> list:
    """Given a set of functions on the DFX regions, generate all possible
    configurations that can support them
    """

    dfx_dict = cpipe.dfx_dict.copy()
    """Generate list of list with PR supporting corresponding function"""
    pr_regions_support = list()
    for i in dfx_ip:
        function_in_pr = list()
        for k, v in dfx_dict.items():
            if any(i in ele for ele in v['rm'].keys()):
                function_in_pr.append(k)
        pr_regions_support.append(function_in_pr)

    """Generate all possible permutations"""
    all_permute = list(itertools.product(*pr_regions_support))

    """Generate valid permute"""
    valid_permute = []
    for idx in range(len(all_permute)):
        duplicate = False
        for ii in range(len(all_permute[idx])):
            if all_permute[idx][ii] in all_permute[idx][ii+1:]:
                duplicate = True
                break
        if not duplicate:
            valid_permute.append(all_permute[idx])

    return valid_permute


def generate_valid_apps() -> list:
    ol = Overlay(pytest.overlay)
    cpipe = ol.composable

    list_apps = []
    for e in app_construct:
        valid_permutation = generate_valid_permutations(e[0], cpipe)
        for p in valid_permutation:
            list_dfx = []
            for idx in range(len(e[0])):
                list_dfx.append(p[idx] + '/' +  e[0][idx])
            list_apps.append([list_dfx, e[1]])

    return list_apps


valid_apps = generate_valid_apps()


@pytest.mark.parametrize('app', valid_apps)
def test_app(app, create_composable):
    #ol, cpipe = create_composable
    #video = VideoStream(ol, VSource.OpenCV, VSink.DP, '../mountains.mp4')
    #video.start()
    #time.sleep(5)
    #video.stop()
    print(app)
    assert True


"""
self._fi2d0 = self._cpipe.filter2d_accel
self._r2g = self._cpipe.rgb2gray_accel
self._g2r = self._cpipe.gray2rgb_accel
self._r2h = self._cpipe.rgb2hsv_accel
self._ct = self._cpipe.colorthresholding_accel
self._lut = self._cpipe.lut_accel
self._dup = self._cpipe.duplicate_accel
self._vii = self._cpipe.ps_video_in
self._vio = self._cpipe.ps_video_out
self._fi2d1 = self._cpipe.pr_0.filter2d_accel

"""