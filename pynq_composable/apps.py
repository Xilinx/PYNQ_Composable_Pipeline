# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq import Overlay
from pynq.lib.video import VideoMode
from .video import VideoStream, VSource, VSink
from .libs import xvF2d, xvLut
from ipywidgets import VBox, HBox, IntRangeSlider, FloatSlider, interact, \
    interactive_output, IntSlider, Dropdown
from IPython.display import display
import numpy as np
from threading import Timer
import glob
import os
import warnings

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


class PipelineApp:
    """ Base class to expose common pipeline methods

    This class wraps the common functionality for the different
    applications, these methods are:

        - start: configures and starts the pipeline
        - stop: stops the pipeline
        - play: exposes runtime configuration to the user
    """

    _dfx_ip = None

    def __init__(self, bitfile_name, source: VSource = VSource.HDMI,
                 sink: VSink = VSink.HDMI, file: int = 0,
                 videomode: VideoMode = None):
        """Return a PipelineApp object

        Parameters
        ----------
        bitfile_name : str
            Bitstream filename
        source : VSource (optional)
            Input video source. Default VSource.HDMI
        sink : VSink (optional)
            Output video sink. Default VSink.HDMI
        file: int, str (optional)
            OpenCV input stream. Default 0
            If this argument is \'int\' the source is a webcam
            If this argument is \'str\' the source is a file
        """
        dtbo = glob.glob(os.path.dirname(bitfile_name) + '/*.dtbo')
        if len(dtbo) > 1:
            warnings.warn("There are more than one dtbo, dtbo {} is being "
                          "used".format(dtbo[0]))
        elif not dtbo:
            dtbo = [None]

        self._ol = Overlay(bitfile_name, dtbo=dtbo[0])
        self._cpipe = self._ol.composable
        device = self._ol.device.name

        if source not in VSource:
            raise ValueError("source {} is not supported".format(source))
        elif (device == 'Pynq-Z2' and source == VSource.MIPI) or\
                (device == 'KV260' and source == VSource.HDMI):
            raise ValueError("Device {} does not support {} as input source "
                             .format(device, source.name))

        if sink not in VSink:
            raise ValueError("sink {} is not supported".format(sink))
        elif device == 'Pynq-Z2' and sink == VSink.DP:
            raise ValueError("Device {} does not support {} as output sink "
                             .format(device, sink.name))

        self._video = VideoStream(self._ol, source, sink, file, videomode)

        if source == VSource.HDMI:
            self._vii = self._cpipe.hdmi_source_in
            self._vio = self._cpipe.hdmi_source_out
        elif source == VSource.OpenCV and device != "KV260":
            self._vii = self._cpipe.hdmi_sink_in
            self._vio = self._cpipe.hdmi_sink_out
        elif source == VSource.OpenCV:
            self._vii = self._cpipe.ps_video_in
            self._vio = self._cpipe.ps_video_out
        elif source == VSource.MIPI:
            self._vii = self._cpipe.mipi_in
            self._vio = self._cpipe.mipi_out

        self._fi2d0 = self._cpipe.filter2d_accel
        self._r2g = self._cpipe.rgb2gray_accel
        self._g2r = self._cpipe.gray2rgb_accel
        self._r2h = self._cpipe.rgb2hsv_accel
        self._ct = self._cpipe.colorthresholding_accel
        self._lut = self._cpipe.lut_accel
        self._app_pipeline = [self._vii, self._vio]

    def stop(self):
        """ Stops the pipeline"""

        self._video.stop()
        self._ol.free()

    def _pipeline(self):
        """ Logic to configure pipeline

        Each child should extend this method to download partial
        bitstreams and compose the pipeline
        """

        pass

    def start(self):
        """ Starts the pipeline

        Start the HDMI, compose the pipeline and return the graph
        """

        if self._dfx_ip:
            self._cpipe.loadIP(self._dfx_ip)
        self._pipeline()
        self._cpipe.compose(self._app_pipeline)
        self._video.start()
        return self.graph

    def play(self):
        """ Exposes runtime configurations to the user

        Each child should implement its own version of play to expose
        runtime configurations to the users
        """

        pass

    @property
    def graph(self):
        """Return DAG"""

        return self._cpipe.graph


class DifferenceGaussians(PipelineApp):
    """ This class wraps the functionality to implement the Difference of
    Gaussian filter video pipeline application
    https://xilinx.github.io/Vitis_Libraries/vision/2020.2/overview.html#difference-gaussian-filter
    """

    _dfx_ip = [
        'pr_fork/duplicate_accel',
        'pr_join/subtract_accel',
        'pr_0/filter2d_accel'
    ]

    def _pipeline(self):
        """ Logic to configure pipeline

        Download partial bitstreams and configure pipeline
        """

        self._dup = self._cpipe.pr_fork.duplicate_accel
        self._sub = self._cpipe.pr_join.subtract_accel
        self._fi2d1 = self._cpipe.pr_0.filter2d_accel

        self.sigma0 = 0.5
        self._fi2d0.kernel_type = xvF2d.gaussian_blur
        self.sigma1 = 7
        self._fi2d1.kernel_type = xvF2d.gaussian_blur

        self._app_pipeline = [self._vii, self._fi2d0, self._dup,
                              [[self._fi2d1], [1]], self._sub, self._vio]

    def _play(self, sigma0, sigma1):
        self._fi2d0.sigma = sigma0
        self._fi2d1.sigma = sigma1

    def play(self):
        """ Exposes runtime configurations to the user
        Displays two sliders to change the sigma value of each Gaussian Filter
        """

        sigma0 = FloatSlider(min=0.1, max=10, value=0.5,
                             description='\u03C3\u2080')
        sigma1 = FloatSlider(min=0.1, max=10, value=7,
                             description='\u03C3\u2081')
        interact(self._play, sigma0=sigma0, sigma1=sigma1)


class CornerDetect(PipelineApp):
    """ This class wraps the functionality to implement the corner detection
    video pipeline application
    """

    _dfx_ip = [
        'pr_0/fast_accel',
        'pr_1/cornerHarris_accel',
        'pr_fork/duplicate_accel',
        'pr_join/add_accel'
    ]
    _algorithm = 'Fast'

    def _pipeline(self):
        """ Logic to configure pipeline

        Download partial bitstreams and configure pipeline
        """

        self._fast = self._cpipe.pr_0.fast_accel
        self._harr = self._cpipe.pr_1.cornerHarris_accel
        self._add = self._cpipe.pr_join.add_accel
        self._dup = self._cpipe.pr_fork.duplicate_accel

        self._app_pipeline = [self._vii, self._dup, [[self._r2g, self._fast,
                              self._g2r], [1]], self._add, self._vio]

    def _swap(self):
        if self._algorithm == 'Fast':
            self._cpipe.replace((self._fast, self._harr))
            self._algorithm = 'Harris'
            self._thr.max = 1024
            self._thr.value = 422
        else:
            self._cpipe.replace((self._harr, self._fast))
            self._algorithm = 'Fast'
            self._thr.max = 255
            self._thr.value = 20

    def _play(self, algorithm, threshold, k_harris):
        """ Logic for runtime updates"""

        if algorithm != self._algorithm:
            self._swap()
        elif algorithm == 'Fast':
            self._fast.threshold = threshold
            self._k_harris.disabled = True
        else:
            self._harr.threshold = threshold
            self._k_harris.disabled = False
            self._harr.k = k_harris

    def play(self):
        """ Exposes runtime configurations to the user

        Displays one drop down menu to select the Corner Detect Algorithm.
        It also displays two sliders to change the the threshold and K value
        for the algorithms.
        """
        self._thr = IntSlider(min=0, max=255, step=1, value=20)
        self._k_harris = FloatSlider(min=0, max=0.2, step=0.002, value=0.04,
                                     description='\u03BA')
        interact(self._play, algorithm=['Fast', 'Harris'],
                 threshold=self._thr, k_harris=self._k_harris)


class ColorDetect(PipelineApp):
    """ This class wraps the functionality to implement the color detect
    video pipeline application
    https://xilinx.github.io/Vitis_Libraries/vision/2020.2/overview.html#id9
    """

    _dfx_ip = [
        'pr_0/dilate_accel',
        'pr_1/dilate_accel',
        'pr_fork/duplicate_accel',
        'pr_join/bitwise_and_accel'
    ]
    _c_space = 'HSV'
    _output = 'Color Detect'
    _noise_reduction = 'Yes'

    def _pipeline(self):
        """ Logic to configure pipeline

        Download partial bitstreams and configure pipeline
        """

        self._er0 = self._cpipe.pr_0.erode_accel
        self._di0 = self._cpipe.pr_0.dilate_accel
        self._er1 = self._cpipe.pr_1.erode_accel
        self._di1 = self._cpipe.pr_1.dilate_accel
        self._band = self._cpipe.pr_join.bitwise_and_accel
        self._dup = self._cpipe.pr_fork.duplicate_accel

        self._app_pipeline = [self._vii, self._dup, [[self._r2h, self._ct,
                              self._er0, self._di0, self._di1, self._er1,
                              self._g2r], [1]], self._band, self._vio]

        self._app_pipeline1 = [self._vii, self._dup, [[self._ct,
                               self._er0, self._di0, self._di1, self._er1,
                               self._g2r], [1]], self._band, self._vio]

        self._app_pipelinennr = [self._vii, self._dup, [[self._r2h, self._ct,
                                 self._g2r], [1]], self._band, self._vio]

        self._app_pipeline1nnr = [self._vii, self._dup, [[self._ct, self._g2r],
                                  [1]], self._band, self._vio]

    def _play(self, h0, h1, h2, s0, s1, s2, v0, v1, v2, s, nr):
        lower_thr = np.empty((3, 3), dtype=np.uint8)
        upper_thr = np.empty((3, 3), dtype=np.uint8)

        lower_thr[0] = [h0[0], h1[0], h2[0]]
        upper_thr[0] = [h0[1], h1[1], h2[1]]

        lower_thr[1] = [s0[0], s1[0], s2[0]]
        upper_thr[1] = [s0[1], s1[1], s2[1]]

        lower_thr[2] = [v0[0], v1[0], v2[0]]
        upper_thr[2] = [v0[1], v1[1], v2[1]]

        self._ct.lower_thr = lower_thr
        self._ct.upper_thr = upper_thr

        if nr != self._noise_reduction:
            if nr == 'Yes':
                if self._c_space == 'RGB':
                    self._cpipe.compose(self._app_pipeline1)
                else:
                    self._cpipe.compose(self._app_pipeline)
            else:
                if self._c_space == 'RGB':
                    self._cpipe.compose(self._app_pipeline1nnr)
                else:
                    self._cpipe.compose(self._app_pipelinennr)

            self._noise_reduction = nr

        if s != self._c_space:
            if s == 'RGB':
                self._cpipe.compose(self._app_pipeline1)
            else:
                self._cpipe.compose(self._app_pipeline)
            self._c_space = s
            self._noise_r.value = 'Yes'

    _noise_r = Dropdown(options=['Yes', 'No'],
                        value='Yes', description='Noise Reduction')

    _h0 = IntRangeSlider(value=[22, 38], min=0, max=255,
                         description='h\u2080')
    _h1 = IntRangeSlider(value=[38, 75], min=0, max=255,
                         description='h\u2081')
    _h2 = IntRangeSlider(value=[160, 179], min=0, max=255,
                         description='h\u2082')

    _s0 = IntRangeSlider(value=[150, 255], min=0, max=255,
                         description='s\u2080')
    _s1 = IntRangeSlider(value=[150, 255], min=0, max=255,
                         description='s\u2081')
    _s2 = IntRangeSlider(value=[150, 255], min=0, max=255,
                         description='s\u2082')

    _v0 = IntRangeSlider(value=[60, 255], min=0, max=255,
                         description='v\u2080')
    _v1 = IntRangeSlider(value=[60, 255], min=0, max=255,
                         description='v\u2081')
    _v2 = IntRangeSlider(value=[60, 255], min=0, max=255,
                         description='v\u2082')

    _sliders = [_h0, _h1, _h2, _s0, _s1, _s2, _v0, _v1, _v2]

    def _control_sliders(self, disabled=True):
        for s in range(len(self._sliders)):
            self._sliders[s].disabled = disabled

    def play(self):
        """Exposes runtime configurations to the user

        Displays nine slides to change the thresholding range for three colors
        on the three channels
        """

        c_space = Dropdown(options=['HSV', 'RGB'], value='HSV',
                           description='Color Space')

        left_box = VBox([self._h0, self._h1, self._h2, c_space])
        middle_box = VBox([self._s0, self._s1, self._s2])
        right_box = VBox([self._v0, self._v1, self._v2, self._noise_r])

        out = \
            interactive_output(self._play,
                               {'h0': self._h0, 'h1': self._h1, 'h2': self._h2,
                                's0': self._s0, 's1': self._s1, 's2': self._s2,
                                'v0': self._v0, 'v1': self._v1, 'v2': self._v2,
                                's': c_space, 'nr': self._noise_r})

        ui = HBox([left_box, middle_box, right_box])
        display(ui, out)


class EdgeDetect(PipelineApp):
    """ Edge detect video pipeline application
    This class wraps the functionality to implement an edge detect
    video pipeline application
    """

    _dfx_ip = [
        'pr_fork/duplicate_accel',
        'pr_join/add_accel'
    ]

    _mask = 'Edges'

    def _pipeline(self):
        """Logic to configure pipeline"""

        self._di0 = self._cpipe.pr_0.dilate_accel
        self._di1 = self._cpipe.pr_1.dilate_accel
        self._add = self._cpipe.pr_join.add_accel
        self._dup = self._cpipe.pr_fork.duplicate_accel
        self._fi2d0.kernel_type = xvF2d.scharr_y

        self._app_pipeline = [self._vii, self._r2g, self._fi2d0, self._ct,
                              self._g2r, self._vio]
        self._app_pipeline1 = [self._vii, self._dup, [[self._r2g, self._fi2d0,
                               self._ct, self._g2r], [1]], self._add,
                               self._vio]

    def _play(self, thres, e, o):
        lower_thr = np.ones((3, 3), dtype=np.uint8) * np.uint8(thres)
        upper_thr = np.ones((3, 3), dtype=np.uint8) * 255
        self._ct.lower_thr = lower_thr
        self._ct.upper_thr = upper_thr
        self._fi2d0.kernel_type = e
        if o != self._mask:
            if o == 'Edges':
                self._cpipe.compose(self._app_pipeline)
            else:
                self._cpipe.compose(self._app_pipeline1)
            self._mask = o

    def play(self):
        """Exposes runtime configurations to the user

        Displays threshold slider to change the intensity threshold
        """
        edge = Dropdown(options=[xvF2d.edge_x, xvF2d.sobel_x, xvF2d.sobel_y,
                                 xvF2d.scharr_x, xvF2d.scharr_y,
                                 xvF2d.prewitt_y], value=xvF2d.scharr_y,
                        description='Kernel')
        output = Dropdown(options=['Edges', 'Edges on video'],
                          value='Edges', description='Output Video')
        threshold = IntSlider(value=100, min=1, max=255,
                              description='Threshold')

        out = interactive_output(self._play,
                                 {'thres': threshold, 'e': edge, 'o': output})
        ui = HBox([edge, threshold, output])
        display(ui, out)


class InterruptTimer(object):
    """ Threaded interrupt

    This class encapsulates a threaded interrupt that gets a function and
    executes it when the timer times out
    """

    def __init__(self, interval, function, *args, **kwargs):
        self._timer = None
        self.interval = interval
        self.function = function
        self.args = args
        self.kwargs = kwargs
        self.is_running = False

    def _run(self):
        self.is_running = False
        self.start()
        self.function(*self.args, **self.kwargs)

    def start(self):
        """ Start background task"""

        if not self.is_running:
            self._timer = Timer(self.interval, self._run)
            self._timer.start()
            self.is_running = True

    def stop(self):
        """ Stop background task"""

        if self.is_running:
            self._timer.cancel()
            self.is_running = False


class Filter2DApp(PipelineApp):
    """ This class wraps the functionality to implement the Filter2D IP in and
    expose kernel configurability through the buttons on the board
    """

    def __init__(self, bitfile_name, source: VSource = VSource.HDMI):
        """Return a Filter2DApp object

        Parameters
        ----------
        bitfile_name : str
            Bitstream filename
        source : str (optional)
            Input video source. Valid values ['HDMI', 'MIPI']
        """

        super().__init__(bitfile_name=bitfile_name, source=source)
        self._fi2d0.kernel_type = xvF2d.identity
        self._buttons = self._ol.btns_gpio.channel1
        self._leds = self._ol.leds_gpio.channel1
        self._timer = InterruptTimer(0.3, self._play)
        self._app_pipeline = [self._vii, self._fi2d0, self._vio]
        self._index = None

    def stop(self):
        """Stops the pipeline"""

        super().stop()
        self._timer.stop()

    def _play(self):
        buttons = int(self._buttons.read())
        index = buttons % len(xvF2d)
        if self._index != index:
            self._fi2d0.kernel_type = xvF2d(index)
            self._leds[0:4].write(index)
            self._index = index

    def play(self):
        """ Exposes runtime configurations to the user

        Enables user iteration by changing the on board buttons
        """

        self._timer.start()
        return "Use the buttons on the board to change the Filter2D "\
            "kernel type"


class LutApp(PipelineApp):
    """ This class wraps the functionality to implement the LUT IP and
    expose kernel configurability through the switches on the board
    """

    def __init__(self, bitfile_name, source: VSource = VSource.HDMI):
        """Return a LutApp object

        Parameters
        ----------
        bitfile_name : str
            Bitstream filename
        source : str (optional)
            Input video source. Valid values ['HDMI', 'MIPI']
        """

        super().__init__(bitfile_name=bitfile_name, source=source)
        self._lut.kernel_type = xvLut.negative
        self._switches = self._ol.switches_gpio.channel1
        self._leds = self._ol.leds_gpio.channel1
        self._timer = InterruptTimer(0.3, self._play)
        self._app_pipeline = [self._vii, self._lut, self._vio]
        self._index = None

    def stop(self):
        """Stops the pipeline"""

        super().stop()
        self._timer.stop()

    def _play(self):
        switches = int(self._switches.read())
        index = switches % len(xvLut)
        if self._index != index:
            self._lut.kernel_type = xvLut(index)
            self._leds[0:4].write(index)
            self._index = index

    def play(self):
        """ Exposes runtime configurations to the user

        Enables user iteration by changing the on board switches
        """

        self._timer.start()
        return "Use the switches on the board to change the LUT kernel type"
