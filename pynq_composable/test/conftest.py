# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq import Overlay
import pytest


_overlay_file = "cv_dfx_3_pr.bit"


@pytest.fixture
def create_overlay():
    for i in range(5):
        try:
            ol = Overlay(_overlay_file)
        except OSError as e:
            if "Bitstream file" in str(e):
                pytest.exit(str(e))
            elif i != 4:
                continue
            raise OSError("Could not program the FPGA")

    yield ol
    ol.free()


@pytest.fixture
def create_composable(create_overlay):
    ol = create_overlay
    cpipe = ol.composable
    yield ol, cpipe


def parameter():
    ol = Overlay(_overlay_file)
    cpipe = ol.composable
    dfx_ip = list()
    for k, v in cpipe.c_dict.unloaded.items():
        element = {'ipname': k, 'modtype': v['modtype']}
        dfx_ip.append(element)
    return dfx_ip


def pytest_configure():
    pytest.dfx_ip = parameter()
    pytest.overlay = _overlay_file
