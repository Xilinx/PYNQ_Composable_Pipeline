# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


from .composable import Composable
from .switch import StreamSwitch
from .apps import PipelineApp
from .apps import DifferenceGaussians
from .apps import CornerDetect
from .apps import ColorDetect
from .apps import Filter2DApp
from .apps import LutApp
from .apps import EdgeDetect
from .video import VideoStream
from .video import VSource
from .video import VSink
from .libs import *


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"
__version__ = '1.1.0'
