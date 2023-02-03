# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import pytest
import os


os.makedirs(os.path.dirname('result_tests/passed/'), exist_ok=True)
os.makedirs(os.path.dirname('result_tests/failed/'), exist_ok=True)


@pytest.mark.parametrize('ip', pytest.dfx_ip)
def test_mmap_write(ip, create_composable):
    ol, cpipe = create_composable
    ipname = ip['ipname']
    # Get base address of DFX Region
    base_ip = 'composable/' + ipname.split('/')[0]
    base_addr = ol.ip_dict[base_ip]['phys_addr']
    cpipe.load([ipname])
    key = 'composable/' + ipname
    ip_attr = getattr(ol, key)
    addr = ol.ip_dict[key]['phys_addr']
    assert (base_addr & 0xFFFF0000) == (addr & 0xFFFF0000)
    control = ip_attr.read(0)
    ip_attr.write(0x10, 1280)
    ip_attr.write(0x18, 720)
    cols = ip_attr.read(0x10)
    rows = ip_attr.read(0x18)
    status = (4, 1280, 720) == (control, cols, rows)
    name = ipname.replace('/', '_')
    filename = ('passed' if status else 'failed') + f'/{name}.txt'
    with open(f'result_tests/{filename}', 'w') as file:
        file.write(f'Base IP: {base_ip}\n')
        file.write(f'Base Address: {hex(addr)}\n')
        file.write(f'Partial bitstream address: {hex(base_addr)}\n')
        file.write(f'Control: {control} in hex {hex(control)}\n')
        file.write(f'Cols   : {cols} in hex {hex(cols)}\n')
        file.write(f'Rows   : {rows} in hex {hex(rows)}\n')
    assert status
