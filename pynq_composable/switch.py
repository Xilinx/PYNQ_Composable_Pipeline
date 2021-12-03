# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq import DefaultIP
import numpy as np

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _mux_mi_gen(ports: int) -> tuple:
    """Generates index and address for AXI4-Stream Switch MI Mux Registers"""

    for i in range(ports):
        yield i, 0x40 + 4 * i


class StreamSwitch(DefaultIP):
    """AXI4-Stream Switch python driver

    This class provides the driver to control an AXI4-Stream Switch
    which uses the AXI4-Lite interfaces to specify the routing table.
    This routing mode requires that there is precisely only one path between
    producer and consumer. When attempting to map the same consumer interface
    to multiple producer interfaces, only the lowest consumer interface is
    able to access the consumer interface.
    Unused producer interfaces are automatically disabled by the logic
    provided in this driver
    """

    bindto = ['xilinx.com:ip:axis_switch:1.1']

    _control_reg = 0x0
    _pi_offset = 0x40
    _reg_update = 1 << 1

    def __init__(self, description: dict):
        super().__init__(description=description)
        self.max_slots = int(description['parameters']['C_NUM_MI_SLOTS'])
        self._pi = np.zeros(self.max_slots, dtype=np.int64)

    def default(self) -> None:
        """Generate default configuration

        Configures the AXI4-Stream Switch to connect
        producer[j] to consumer[j] for j = 0 to j = (max_slots-1)
        """

        for i in range(len(self._pi)):
            self._pi[i] = i
        self._populateRouting()

    def disable(self) -> None:
        """Disable all connections in the AXI4-Stream Switch"""

        for i in range(len(self._pi)):
            self._pi[i] = np.uint64(0x80000000)
        self._populateRouting()

    @property
    def pi(self):
        """ AXI4-Stream Switch configuration

        Configure the AXI4-Stream Switch given a numpy array
        Each element in the array controls a consumer interface selection.
        If more than one element in the array is set to the same consumer
        interface, then the lower producer interface wins.

        Parameters
        ----------
        conf_array : numpy array (dtype=np.int64)
            An array with the mapping of consumer to producer interfaces
            The index in the array is the producer interface and
            the value is the consumer interface slot
            The length of the array can vary from 1 to max slots
            Use negative values to indicate that a producer is disabled

            For instance, given this input [-1, 2, 1, 0]
                Consumer 2 will be routed to Producer 1
                Consumer 1 will be routed to Producer 2
                Consumer 0 will be routed to Producer 3
                Producer 0 is disabled
        """
        pi = np.zeros(self.max_slots, dtype=np.int64)
        for idx, offset in _mux_mi_gen(self.max_slots):
            pi[idx] = self.read(offset)
        return pi

    @pi.setter
    def pi(self, conf_array: np.dtype(np.int64)):
        length = len(conf_array)
        if conf_array.dtype is not np.dtype(np.int64):
            raise TypeError("Numpy array must be np.int64 dtype")
        elif length > self.max_slots:
            raise ValueError("Provided numpy array is bigger than "
                             "number of slots {}".format(self.max_slots))
        elif length < 1:
            raise ValueError("Input numpy array must be at least "
                             "one element long")

        for slot in range(len(conf_array)):
            if conf_array[slot] < 0:
                conf_array[slot] = np.uint64(0x80000000)

        if length != self.max_slots:
            new_slots = self.max_slots - length
            conf_array = np.append(conf_array,
                                   np.ones(new_slots, dtype=np.int32) *
                                   np.uint64(0x80000000))

        self._pi = conf_array
        self._populateRouting()

    def _populateRouting(self):
        """Writes the current configuration to the AXI4-Stream Switch

        First the Pi selector values are written to the corresponding
        register. Once the registers have been programmed, a commit
        register transfers the programmed values from the register interface
        into the switch, for a short period of time the AXI4-Stream Switch
        interfaces are held in reset.
        """

        for idx, offset in _mux_mi_gen(self.max_slots):
            self.write(offset, int(self._pi[idx]))
        self.write(self._control_reg, self._reg_update)
