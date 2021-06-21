#   Copyright (c) 2021, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from pynq.lib.video import *
from time import sleep
import cv2
from _thread import *
import threading 


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


"""Collection of classes to manage different video sources"""


# Threaded
class Webcam:
    """Wrapper for a webcam video pipeline"""
    
    def __init__(self, filename: int=0, mode=VideoMode(1280,720,24,30)):
        """ Returns a Webcam object
        
        Parameters
        ----------
        filename : int
            webcam filename, by default this is 0

        mode : VideoMode
            webcam configuration
        """
        self._dev = filename
        self._videoIn = None
        self.mode = mode
        self._width = mode.width
        self._height = mode.height
        self._thread = threading.Lock()
        self._running = None
    
    def _configure(self):
        self._videoIn = cv2.VideoCapture(self._dev)
        self._videoIn.set(cv2.CAP_PROP_FRAME_WIDTH, self.mode.width);
        self._videoIn.set(cv2.CAP_PROP_FRAME_HEIGHT, self.mode.height);
        self._videoIn.set(cv2.CAP_PROP_FPS, self.mode.fps)
    
    def start(self):
        """Start webcam by configuring it"""

        self._configure()

    def stop(self):
        """Stop the pipeline"""

        if self._videoIn:
            self._running = False
            while self._thread.locked():
                sleep(0.05)
            self._videoIn.release()
            self._videoIn = None

    def pause(self):
        """Pause tie"""

        if not self._videoIn:
            raise SystemError("The Webcam is not started")

        if self._running:
            self._running = False

    def close(self):
        """Uninitialise the drivers, stopping the pipeline beforehand"""

        self.stop()
        
    def readframe(self):
        """Read an image from the webcam"""

        ret, frame = self._videoIn.read()
        return frame
    
    def tie(self, output):
        """Mirror the webcam input to an output channel

        Parameters
        ----------
        output : HDMIOut
            The output to mirror on to
        """
        if not self._videoIn:
            raise SystemError("The Webcam is not started")
        self._output = output
        self._outframe = self._output.newframe()
        self._thread.acquire()
        self._running = True
        try:
            start_new_thread(self._tie, ())
        except:
            import traceback
            print (traceback.format_exc())
        
    def _tie(self):
        """Threaded method to implement tie"""

        while self._running:
            self._outframe[:] = self.readframe()
            self._output.writeframe(self._outframe)
        self._thread.release()

