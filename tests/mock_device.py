# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import pynq
import struct

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


class MockDeviceBase(pynq.Device):
    def __init__(self, tag):
        super().__init__(tag)


class MockIPBase:
    def __init__(self, base_address, address_range):
        self.base = base_address
        self.range = address_range
        self.memory = dict()

    def write_register(self, address, data):
        self.memory[str(address)] = data

    def read_register(self, address):
        return self.memory.get(str(address))


class MockRegisterIP(MockIPBase):
    def read(self, address, length):
        assert length == 4
        return struct.pack('I', self.read_register(address))

    def write(self, address, data):
        assert len(data) == 4
        self.write_register(address, struct.unpack('I', data)[0])


class MockIPDevice(MockDeviceBase):
    def __init__(self, ip, tag):
        super().__init__(tag)
        self.capabilities = {'REGISTER_RW': True}
        self.ip = ip

    def read_registers(self, address, length=4):
        return self.ip.read(address + self.ip.base, length)

    def write_registers(self, address, data):
        return self.ip.write(address + self.ip.base, data)
