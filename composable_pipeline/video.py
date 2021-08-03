# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq.lib.video import VideoMode
from time import sleep
import cv2
from _thread import start_new_thread
import threading

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


"""Collection of classes to manage different video sources"""


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
