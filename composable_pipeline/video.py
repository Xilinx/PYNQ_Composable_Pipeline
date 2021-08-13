# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import pynq
from pynq import Overlay
from pynq.lib.video import VideoMode
from pynq.lib.video.clocks import DP159, SI_5324C
from time import sleep
import cv2
from _thread import start_new_thread
import threading


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


"""Collection of classes to manage different video sources"""


class HDMIVideo:
    """HDMI class

    Handles HDMI input and output paths
    .start: configures hdmi_in and hdmi_out starts them and tie them together
    .stop: closes hdmi_in and hdmi_out

    """

    def __init__(self, ol: Overlay, source: str = 'HDMI') -> None:
        """Return a HDMIVideo object to handle the video path

        Parameters
        ----------
        ol : pynq.Overlay
            Overlay object
        source : str (optional)
            Input video source. Valid values ['HDMI', 'MIPI']
        """

        vsources = ['HDMI', 'MIPI']
        if source not in vsources:
            raise ValueError("{} is not supported".format(source))
        elif ol.device.name != 'Pynq-ZU' and source != 'HDMI':
            raise ValueError(
                "Device {} only supports {} as input source ".format(
                    ol.device.name, vsources[0]
                )
            )

        self._hdmi_out = ol.video.hdmi_out
        self._source = source
        self._started = None

        if ol.device.name == 'Pynq-ZU':
            # Deassert HDMI clock reset
            ol.reset_control.channel1[0].write(1)
            # Wait 200 ms for the clock to come out of reset
            sleep(0.2)

            ol.video.phy.vid_phy_controller.initialize()

            if self._source == 'HDMI':
                self._source_in = ol.video.hdmi_in
                self._source_in.frontend.set_phy(
                    ol.video.phy.vid_phy_controller)
            else:
                self._source_in = ol.mipi

            self._hdmi_out.frontend.set_phy(ol.video.phy.vid_phy_controller)

            dp159 = DP159(ol.HDMI_CTL_axi_iic, 0x5C)
            si = SI_5324C(ol.HDMI_CTL_axi_iic, 0x68)
            self._hdmi_out.frontend.clocks = [dp159, si]
            if (ol.tx_en_out.read(0)) == 0:
                ol.tx_en_out.write(0, 1)
        else:
            self._source_in = ol.video.hdmi_in

    def start(self):
        """Configure and start the HDMI"""
        if not self._started:
            if self._source == 'HDMI':
                self._source_in.configure()
            else:
                self._source_in.configure(VideoMode(1280, 720, 24))

            self._hdmi_out.configure(self._source_in.mode)

            self._source_in.start()
            self._hdmi_out.start()

            self._source_in.tie(self._hdmi_out)
            self._started = True

    def stop(self):
        """Stop the HDMI"""
        if self._started:
            self._hdmi_out.close()
            self._source_in.close()
            self._started = False


class VideoFile:
    """Wrapper for a video stream pipeline"""

    def __init__(self, filename: str, mode=VideoMode(1280, 720, 24, 30)):
        """ Returns a VideoFile object

        Parameters
        ----------
        filename : int
            video filename

        mode : VideoMode
            video configuration
        """

        if not isinstance(filename, str):
            raise ValueError("filename ({}) is not an string".format(filename))

        self._file = filename
        self._videoIn = None
        self.mode = mode
        self._thread = threading.Lock()
        self._running = None

    def _configure(self):
        self._videoIn = cv2.VideoCapture(self._file)
        self._videoIn.set(cv2.CAP_PROP_FRAME_WIDTH, self.mode.width)
        self._videoIn.set(cv2.CAP_PROP_FRAME_HEIGHT, self.mode.height)
        fourcc = int(self._videoIn.get(cv2.CAP_PROP_FOURCC))
        mode = \
            fourcc.to_bytes((fourcc.bit_length() + 7) // 8, 'little').decode()
        if isinstance(self._file, int):
            if mode != 'MJPG':
                self._videoIn.set(cv2.CAP_PROP_FOURCC,
                                  cv2.VideoWriter_fourcc('M', 'J', 'P', 'G'))
        self._videoIn.set(cv2.CAP_PROP_FPS, self.mode.fps)

    def start(self):
        """Start video stream by configuring it"""

        self._configure()

    def stop(self):
        """Stop the video stream"""

        if self._videoIn:
            self._running = False
            while self._thread.locked():
                sleep(0.05)
            self._videoIn.release()
            self._videoIn = None

    def pause(self):
        """Pause tie"""

        if not self._videoIn:
            raise SystemError("The stream is not started")

        if self._running:
            self._running = False

    def close(self):
        """Uninitialise the drivers, stopping the pipeline beforehand"""

        self.stop()

    def readframe(self):
        """Read an image from the video stream"""

        ret, frame = self._videoIn.read()
        if not ret:
            print('Rewind')
            self._configure()
            return self.readframe()
        return frame

    def tie(self, output):
        """Mirror the video stream input to an output channel

        Parameters
        ----------
        output : HDMIOut
            The output to mirror on to
        """

        if not self._videoIn:
            raise SystemError("The stream is not started")
        self._output = output
        self._outframe = self._output.newframe()
        self._thread.acquire()
        self._running = True
        try:
            start_new_thread(self._tie, ())
        except Exception:
            import traceback
            print(traceback.format_exc())

    def _tie(self):
        """Threaded method to implement tie"""

        while self._running:
            self._outframe[:] = self.readframe()
            self._output.writeframe(self._outframe)
        self._thread.release()


class Webcam(VideoFile):
    """Wrapper for a webcam video pipeline"""

    def __init__(self, filename: int = 0, mode=VideoMode(1280, 720, 24, 30)):
        """ Returns a Webcam object

        Parameters
        ----------
        filename : int
            webcam filename, by default this is 0
        mode : VideoMode
            webcam configuration
        """

        if not isinstance(filename, int):
            raise ValueError("filename ({}) is not an integer"
                             .format(filename))

        self._file = filename
        self._videoIn = None
        self.mode = mode
        self._thread = threading.Lock()
        self._running = None


class FileDisplayPort(VideoFile):
    """Wrapper for a webcam video pipeline streamed to DisplayPort"""

    def __init__(self, filename: str, mode=VideoMode(1280, 720, 24, 30),
                 vdma: pynq.lib.video.dma.AxiVDMA = None):
        """ Returns a FileDisplayPort object

        Parameters
        ----------
        filename : int
            video filename
        mode : VideoMode
            webcam configuration
        vdma : pynq.lib.video.dma.AxiVDMA
            Xilinx VideoDMA IP core
        """
        super().__init__(filename=filename, mode=mode)

        self.vdma = vdma
        self.mode = mode
        if self.vdma:
            self.vdma.writechannel.mode = self.mode
            self.vdma.readchannel.mode = self.mode

        self._thread = threading.Lock()
        self._running = None

    def start(self):
        """Start video stream by configuring it"""

        self._configure()
        if self.vdma:
            self.vdma.writechannel.start()
            self.vdma.readchannel.start()

    def stop(self):
        """Pause tie"""

        super().stop()
        if self.vdma:
            self.vdma.writechannel.stop()
            self.vdma.readchannel.stop()

    def tie(self, dp: pynq.lib.video.DisplayPort):
        """Mirror the video stream input to an output channel

        Parameters
        ----------
        dp : pynq.lib.video.DisplayPort
            DisplayPort object
        """

        if not self._videoIn:
            raise SystemError("The stream is not started")
        self._dp = dp

        self._thread.acquire()
        self._running = True
        if self.vdma:
            tie = self._tievdma
        else:
            tie = self._tienovdma
        try:
            start_new_thread(tie, ())
        except Exception:
            import traceback
            print(traceback.format_exc())

    def _tievdma(self):
        """Threaded method to implement tie"""

        while self._running:
            fpgaframe = self.vdma.writechannel.newframe()
            fpgaframe[:] = self.readframe()
            self.vdma.writechannel.writeframe(fpgaframe)
            dpframe = self._dp.newframe()
            dpframe[:] = self.vdma.readchannel.readframe()
            self._dp.writeframe(dpframe)

        self._thread.release()

    def _tienovdma(self):
        """Threaded method to implement tie"""

        while self._running:
            dpframe = self._dp.newframe()
            dpframe[:] = self.readframe()
            self._dp.writeframe(dpframe)
        self._thread.release()


class WebcamDisplayPort(FileDisplayPort):
    """Wrapper for a webcam video pipeline streamed to DisplayPort"""

    def __init__(self, filename: int = 0, mode=VideoMode(1280, 720, 24, 30),
                 vdma: pynq.lib.video.dma.AxiVDMA = None):
        """ Returns a WebcamDisplayPort object

        Parameters
        ----------
        filename : int
            webcam filename, by default this is 0
        mode : VideoMode
            webcam configuration
        vdma : pynq.lib.video.dma.AxiVDMA
            Xilinx VideoDMA IP core
        """
        if not isinstance(filename, int):
            raise ValueError("filename \'{}\' is not an integer"
                             .format(filename))

        self._file = filename
        self._videoIn = None
        self.vdma = vdma
        self.mode = mode
        if self.vdma:
            self.vdma.writechannel.mode = self.mode
            self.vdma.readchannel.mode = self.mode

        self._thread = threading.Lock()
        self._running = None
