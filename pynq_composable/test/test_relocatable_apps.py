# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq_composable import VideoStream, VSource, VSink
import pytest
from pynq import Overlay
import time
import itertools


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

    (['dilate', 'dilate', 'bitand'], ['ps_video_in', 'duplicate_accel',
     [['rgb2gray_accel', 'colorthresholding_accel', 'pr/erode', 'pr/dilate',
     'pr/dilate', 'pr/erode'], [1]], 'pr/bitwise', 'ps_video_out']),

    (['add'], ['ps_video_in', 'duplicate_accel',
     [['rgb2gray_accel', 'filter2d_accel', 'colorthresholding_accel',
     'gray2rgb_accel'], [1]], 'pr/add_accel', 'ps_video_out']),
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

    """Generate all valid permute, not repeated DFX region"""
    valid_permute = []
    for i, v in enumerate(all_permute):
        duplicate = False
        for ii, _ in enumerate(v):
            if v[ii] in v[ii+1:]:
                duplicate = True
                break
        if not duplicate:
            valid_permute.append(v)

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
                list_dfx.append(p[idx] + '/' + e[0][idx])
            list_apps.append([list_dfx, e[1]])

    return list_apps


valid_apps = generate_valid_apps()


def get_ip_object_from_overlay(ip, cpipe):
    """Retrieve the actual IP driver object from the overlay"""

    if isinstance(ip, int) or ip == '':
        return ip
    elif 'pr' in ip:
        name = ip.split('/')[1]
        for k, v in cpipe.c_dict.loaded.items():
            if name in v['modtype'] and v['dfx'] and not v.get('used', False):
                v['used'] = True
                return getattr(cpipe, k)

    return getattr(cpipe, ip)


def convert_string_to_ip_object(app, cpipe) -> list:
    """From list of IP name to use and generate object list with driver"""
    obj = []
    for ip_name in app:
        if not isinstance(ip_name, list):
            ip_obj = get_ip_object_from_overlay(ip_name, cpipe)
            obj.append(ip_obj)
        else:
            branch = []
            for ip_list in ip_name:
                branch.append(convert_string_to_ip_object(ip_list, cpipe))
            obj.append(branch)
    return obj


def get_dfx_regions_to_download(dfx, cpipe) -> list:
    """Retrieve actual DFX region to download"""
    dfx_regions = []
    for ip in dfx:
        name = ip.replace('bitand', 'bitwise')
        for k, v in cpipe.c_dict.items():
            if name.lower() in k.lower() and v['dfx']:
                dfx_regions.append(k)
                break
    return dfx_regions


@pytest.mark.parametrize('app', valid_apps)
def test_app(app, create_composable):
    """ This test will compose the apps and start a video stream

    Each `app` contains the general name of dfx to download and pipeline
    """
    ol, cpipe = create_composable
    dfx_regions = get_dfx_regions_to_download(app[0], cpipe)
    cpipe.load(dfx_regions)
    app_obj = convert_string_to_ip_object(app[1], cpipe)
    cpipe.compose(app_obj)
    video = VideoStream(ol, VSource.OpenCV, VSink.DP, '../mountains.mp4')
    try:
        video.start()
        time.sleep(5)
        assert video._video._started and video._video._running
        video.stop()
    except pytest.PytestUnhandledThreadExceptionWarning:
        assert False, f"App {app} failed"
