# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq_composable.virtual import _mem_items
import pytest


@pytest.mark.parametrize('ip', pytest.dfx_ip)
def test_mmap_write(ip, create_composable):
    ol, cpipe = create_composable
    ipname, modtype = ip['ipname'], ip['modtype']
    # Get base address of DFX Region
    base_ip = 'composable/' + ipname.split('/')[0]
    base_addr = ol.ip_dict[base_ip]['phys_addr']
    cpipe.load([ipname])
    if modtype not in _mem_items:
        key = 'composable/' + ipname
        ip_attr = getattr(ol, key)
        addr = ol.ip_dict[key]['phys_addr']
        assert (base_addr & 0xFFFF0000) == (addr & 0xFFFF0000)
        value = ip_attr.read(0)
        print("{}: {}".format(key, value))
        assert value == 4
        ip_attr.write(0x10, 1280)
        ip_attr.write(0x18, 720)
        assert 1280 == ip_attr.read(0x10)
        assert 720 == ip_attr.read(0x18)
        print("Writing and reading OK")
    else:
        assert True
