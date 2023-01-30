# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import pytest


@pytest.mark.parametrize('ip', pytest.dfx_ip)
def test_mmap_write(ip, create_composable):
    ol, cpipe = create_composable
    ipname = ip['ipname']
    # Get base address of DFX Region
    base_ip = 'composable/' + ipname.split('/')[0]
    base_addr = ol.ip_dict[base_ip]['phys_addr']
    cpipe.load([ipname])
    print(f'Testing IP {ipname}: ')

    key = 'composable/' + ipname
    ip_attr = getattr(ol, key)
    addr = ol.ip_dict[key]['phys_addr']
    assert (base_addr & 0xFFFF0000) == (addr & 0xFFFF0000)
    status = ip_attr.read(0)
    ip_attr.write(0x10, 1280)
    ip_attr.write(0x18, 720)
    cols = ip_attr.read(0x10)
    rows = ip_attr.read(0x18)
    assert (4, 1280, 720) == (status, cols, rows)
