# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import composable

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


_mem_items = ['axis_register_slice', 'axis_data_fifo',
              'fifo_generator', 'axis_dwidth_converter',
              'axis_subset_converter']


class DFXRegion:
    """Class that wraps attributes for IP objects on DFX regions"""

    def __init__(self, cpipe: composable.Composable, name: str):
        self._ol = cpipe._ol
        self._parent = cpipe._hier
        self._c_dict = cpipe._c_dict
        self.key = name

    def __getattr__(self, name: str):
        key = self.key + '/' + name
        if key in self._c_dict.keys():
            if not self._c_dict[key]['loaded']:
                return UnloadedIP(key)
            elif self._c_dict[key]['modtype'] in _mem_items:
                return BufferIP(key)
            else:
                return getattr(self._ol, self._parent + key)
        else:
            raise ValueError("IP \'{}\' does not exist in partial region "
                             "\'{}\'".format(name, self.key))


class StreamingIP:
    """Handles Streaming only IP"""

    def __init__(self, name: str):
        self._fullpath = name


class UnloadedIP:
    """Handles IP objects that are not yet loaded into the hardware

    This can be considered a virtual IP object
    """

    def __init__(self, path: str):
        self._fullpath = path


class BufferIP:
    """Handles IP objects that are of buffering type

    Expose fullpath attribute for buffering type IP such as:

        a) FIFOs

        b) Slice registers.
    """

    def __init__(self, path: str):
        self._fullpath = path
