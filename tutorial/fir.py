# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import matplotlib.pyplot as plt
import numpy as np
from scipy import signal

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


class FIR:
    coef = []
    fs = 44100
    _type = ""
    
    def __init__(self):
        self.w, self.h = signal.freqz(self.coef, fs= self.fs)
        self.taps = len(self.coef)
        self.group_delay = (self.taps-1)//2

    def plot(self):
        plt.plot(self.w, 20 * np.log10(abs(self.h)), 'b');
        plt.ylabel('Amplitude [dB]');
        plt.xlabel('Frequency [Hz]');
        plt.title(self._type);

class LowPassFilter(FIR):
    _type = "Lowpass Filter"
    coef =[-133, -375, -356, -559, -643, -731, -731, -650, -458, -153, 263,
           772, 1348, 1949, 2532, 3048, 3453, 3712, 3800, 3712, 3453, 3048,
           2532, 1949, 1348, 772, 263, -153, -458, -650, -731, -731, -643,
           -559, -356, -375, -133]


class HighPassFilter(FIR):
    _type = "Highpass Filter"
    coef = [1136, -1197, -580, -33, 438, 658, 461, -116, -762, -1015, -565,
            480, 1532, 1774, 604, -1953, -5154, -7805, 23932, -7805, -5154,
            -1953, 604, 1774, 1532, 480, -565, -1015, -762, -116, 461, 658,
            438, -33, -580, -1197, 1136]


class BandPassFilter(FIR):
    _type = "Bandpass Filter"
    coef = [195, 42, -82, -129, -41, -6, -269, -705, -710, 234, 1758, 2526,
            1313, -1585, -4106, -3949, -708, 3427, 5298, 3427, -708, -3949,
            -4106, -1585, 1313, 2526, 1758, 234, -710, -705, -269, -6, -41,
            -129, -82, 42, 195]


class StopBandFilter(FIR):
    _type = "Stopband Filter"
    coef = [-1705, 2484, 232, -657, -484, 337, 1239, 1622, 1243, 449, 58, 737,
            2347, 3809, 3706, 1322, -2668, -6410, 24833, -6410, -2668, 1322,
            3706, 3809, 2347, 737, 58, 449, 1243, 1622, 1239, 337, -484, -657,
            232, 2484, -1705]

class Filters:
    """ Create Filter objects """

    def __init__(self):
        self.lp = LowPassFilter()
        self.hp = HighPassFilter()
        self.bp = BandPassFilter()
        self.sb = StopBandFilter()

    def plot(self):
        fig, axs = plt.subplots(2, 2, sharex=True, sharey=True, figsize=(15,9))
        axs[0, 0].plot(self.lp.w, 20 * np.log10(abs(self.lp.h)), 'b')
        axs[0, 0].set_title(self.lp._type, fontsize = 16)
        axs[0, 0].set_ylabel('Amplitude (dB)', fontsize = 14);
        axs[0, 1].plot(self.hp.w, 20 * np.log10(abs(self.hp.h)), 'b')
        axs[0, 1].set_title(self.hp._type, fontsize = 16)
        axs[0, 0].set_yticks(np.arange(0, 100, 10))
        axs[1, 0].plot(self.bp.w, 20 * np.log10(abs(self.bp.h)), 'b')
        axs[1, 0].set_title(self.bp._type, fontsize = 16)
        axs[1, 0].set_ylabel('Amplitude (dB)', fontsize = 14);
        axs[1, 0].set_xlabel('Frequency (Hz)', fontsize = 14);
        axs[1, 0].set_yticks(np.arange(0, 100, 10))
        axs[1, 0].set_xticks(np.arange(0, 22050, 2000))
        axs[1, 0].tick_params(axis='x', rotation=30)
        axs[1, 1].plot(self.sb.w, 20 * np.log10(abs(self.sb.h)), 'b')
        axs[1, 1].set_title(self.sb._type, fontsize = 16)
        axs[1, 1].set_xlabel('Frequency (Hz)', fontsize = 14);
        axs[1, 1].set_xticks(np.arange(0, 22050, 2000))
        axs[1, 1].tick_params(axis='x', rotation=30)
        plt.xlim([0, 22050])
        fig.tight_layout()
