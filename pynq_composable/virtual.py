# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


_mem_items = ['axis_register_slice', 'axis_data_fifo',
              'fifo_generator', 'axis_dwidth_converter',
              'axis_subset_converter']


class DFXRegion:
    """Class that wraps attributes to handle IP objects within DFX regions"""

    def __init__(self, cpipe, name: str):
        self._cpipe = cpipe
        self._ol = cpipe._ol
        self._parent = cpipe._hier
        self._c_dict = cpipe._c_dict
        self.key = name

    def __getattr__(self, name: str):
        key = self.key + '/' + name
        if key in self._c_dict.keys():
            if not self._c_dict[key]['loaded']:
                return VirtualIP(self._cpipe, key)
            elif self._c_dict[key]['modtype'] in _mem_items:
                return BufferIP(key)
            elif (ipname := self._parent + key) in self._ol.ip_dict.keys():
                return getattr(self._ol, ipname)
            return StreamingIP(ipname)
        else:
            raise ValueError("IP \'{}\' does not exist in partial region "
                             "\'{}\'".format(name, self.key))


class VirtualIP:
    """Handles MMIO IP objects that are within a DFX region

    This can be considered a virtual IP object when it is not loaded
    """

    def __init__(self, cpipe, path: str):
        self._cpipe = cpipe
        self._c_dict = cpipe._c_dict
        self._parent = cpipe._hier
        self._fullpath = path

    @property
    def is_loaded(self):
        return self._c_dict[self._fullpath]['loaded']

    def __getattr__(self, name: str):
        if self.is_loaded:
            attr = getattr(self._cpipe._ol, self._parent + self._fullpath)
            return getattr(attr, name)
        else:
            raise AttributeError("\'{}\' is not loaded, load IP before "
                                 "using it".format(self._fullpath))


class StreamingIP:
    """Handles Streaming only IP"""

    def __init__(self, name: str):
        self._fullpath = name


class BufferIP:
    """Handles IP objects that are of buffering type

    Expose fullpath attribute for buffering type IP such as:

        a) FIFOs

        b) Slice registers.
    """

    def __init__(self, path: str):
        self._fullpath = path
