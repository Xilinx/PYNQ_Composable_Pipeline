# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import asyncio
import cv2
from enum import Enum, auto
import json
import os
from pynq import Overlay
from pynq.lib.video import DrmDriver, VideoMode, PIXEL_RGB
from pynq.lib.video.clocks import *
from pynq.ps import CPU_ARCH, ZU_ARCH, ZYNQ_ARCH
from time import sleep
import threading
from typing import Union


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


"""Collection of classes to manage different video sources"""


class VSource(Enum):
    """Suported input video sources"""

    OpenCV = auto()
    HDMI = auto()
    MIPI = auto()


class VSink(Enum):
    """Suported output video sinks"""

    HDMI = auto()
    DP = auto()


class _DisplayPort(DrmDriver):
    """Subclass of DisplayPort that works in a thread"""

    def __init__(self):
        """Create a new driver instance bound to card0 which
        should always be the hardened DisplayPort
        """

        super().__init__('/dev/dri/card0')

    def writeframe(self, frame):
        """Write a frame to the display.

        Raises an exception if the operation fails and blocks until a
        page-flip if there is already a frame scheduled to be displayed.

        Parameters
        ----------
        frame : pynq.ContiguousArray
            Frame to write - must have been created by `newframe`
        """

        ret = self._videolib.pynqvideo_frame_write(
            self._device, frame.pointer)
        if ret == -1:
            self._loop.run_until_complete(
                asyncio.ensure_future(self.writeframe_async(frame)))
        elif ret > 0:
            raise OSError(ret, "Can't write frame")
        else:
            # Frame should no longer be disposed
            frame.pointer = None


class PLPLVideo:
    """PLPLVideo class

    Handles video streams that start in the PL and end in the PL
    """

    def __init__(self, ol: Overlay, source: VSource = VSource.HDMI) -> None:
        """Return a PLVideo object to handle the video path

        Parameters
        ----------
        ol : pynq.Overlay
            Overlay object
        source : str (optional)
            Input video source. Valid values [VSource.HDMI, VSource.MIPI]
        """

        VSourceources = [VSource.HDMI, VSource.MIPI]
        if source not in VSourceources:
            raise ValueError("{} is not supported".format(source))
        elif ol.device.name != 'Pynq-ZU' and source != VSource.HDMI:
            raise ValueError("Device {} only supports {} as input source "
                             .format(ol.device.name, VSource.HDMI.name))

        self._hdmi_out = ol.video.hdmi_out
        self._source = source
        self._started = None

        if ol.device.name == 'Pynq-ZU':
            # Deassert HDMI clock reset
            ol.hdmi_tx_control.channel2[0].write(1)
            # Wait 200 ms for the clock to come out of reset
            sleep(0.2)

            ol.video.phy.vid_phy_controller.initialize()

            if self._source == VSource.HDMI:
                self._source_in = ol.video.hdmi_in
                self._source_in.frontend.set_phy(
                    ol.video.phy.vid_phy_controller)
            else:
                self._source_in = ol.mipi

            self._hdmi_out.frontend.set_phy(ol.video.phy.vid_phy_controller)

            dp159 = DP159(ol.HDMI_CTL_axi_iic, 0x5C)
            si = SI_5324C(ol.HDMI_CTL_axi_iic, 0x68)
            self._hdmi_out.frontend.clocks = [dp159, si]
            if (ol.hdmi_tx_control.read(0)) == 0:
                ol.hdmi_tx_control.write(0, 1)
        else:
            self._source_in = ol.video.hdmi_in

    def start(self):
        """Configure and start the Video source

        Configures hdmi_in or mipi and hdmi_out. Then starts the source and
        sink, and finally tie them together
        """

        if not self._started:
            if self._source == VSource.HDMI:
                self._source_in.configure()
            else:
                self._source_in.configure(VideoMode(1280, 720, 24, 60))

            self._hdmi_out.configure(self._source_in.mode)

            self._source_in.start()
            self._hdmi_out.start()

            self._source_in.tie(self._hdmi_out)
            self._started = True

    def stop(self):
        """Closes source and sink"""

        if self._started:
            self._hdmi_out.close()
            self._source_in.close()
            self._started = False

    @property
    def modein(self):
        """Return input video source mode"""

        return self._source_in.mode

    @property
    def modeout(self):
        """Return output video sink mode"""

        return self._hdmi_out.mode


class PLDPVideo:
    """Wrapper for PL Video stream sources that sink on DisplayPort

    """

    def __init__(self, ol: Overlay, source: VSource = VSource.HDMI) -> None:
        """Return a PLDP object to handle the video path

        Parameters
        ----------
        ol : pynq.Overlay
            Overlay object
        source : str (optional)
            Input video source. Valid values [VSource.HDMI, VSource.MIPI]
        """

        VSourceources = [VSource.HDMI, VSource.MIPI]
        if source not in VSourceources:
            raise ValueError("{} is not supported".format(source))

        if CPU_ARCH != ZU_ARCH:
            raise RuntimeError("Device {} does not support DisplayPort"
                               .format(ol.device.name))

        self._source = source
        self._started = None
        self._pause = None
        self._dp = _DisplayPort()
        self._running = None

        if self._source == VSource.HDMI:
            self._source_in = ol.video.hdmi_in
            self._source_in.frontend.set_phy(ol.video.phy.vid_phy_controller)
        else:
            self._source_in = ol.mipi

    def start(self):
        """Configure and start the HDMI"""
        if not self._started:
            if self._source == VSource.HDMI:
                self._source_in.configure()
                videomode = self._source_in.mode
            else:
                videomode = VideoMode(1280, 720, 24, 60)
                self._source_in.configure(videomode)

            self._dp.configure(videomode, PIXEL_RGB)
            self._source_in.start()

            self._started = True
            sleep(0.2)
            self._tie()
        elif self._pause:
            self._tie()
            self._pause = None

    def stop(self):
        """Stop the HDMI"""
        if self._started:
            self._running = False
            while self._thread.is_alive():
                sleep(0.05)
            self._source_in.close()
            self._dp.stop()
            self._started = False
            self._pause = False

    def _tie(self):
        """Mirror the video stream input to an output channel"""

        self._thread = threading.Thread(target=self._tievdma, daemon=True)
        self._running = True

        try:
            self._thread.start()
        except Exception:
            import traceback
            print(traceback.format_exc())
            raise ValueError("error starting new thread")

    def _tievdma(self):
        """Threaded method to implement tie"""
        while self._running:
            try:
                dpframe = self._dp.newframe()
                dpframe[:] = self._source_in.readframe()
                self._dp.writeframe(dpframe)
                sleep(0.07)
            except Exception as e:
                print('An exception occurred: {}'.format(e))
                import traceback
                import logging
                logging.error(traceback.format_exc())
                self._running = False

    @property
    def modein(self):
        """Return input video source mode"""
        return self._source_in.mode

    @property
    def modeout(self):
        """Return output video sink mode"""

        return self._dp.mode


class OpenCVPLVideo:
    """Wrapper for a OpenCV video stream pipeline that sinks on PL"""

    def __init__(self, ol: Overlay, filename: Union[int, str],
                 mode=VideoMode(1280, 720, 24, 60)):
        """ Returns a OpenCVPL object

        Parameters
        ----------
        filename : [int, str]
            video filename

        mode : VideoMode
            video configuration
        """

        if not isinstance(filename, str) and not isinstance(filename, int):
            raise ValueError("filename ({}) is not an string or integer"
                             .format(filename))

        if isinstance(filename, str) and not os.path.exists(filename):
            raise RuntimeError("File {} does not exists".format(filename))

        self._file = filename
        self._hdmi_out = ol.video.hdmi_out
        self._videoIn = None
        self.mode = mode
        self._running = None
        self._started = None

        if ol.device.name == 'Pynq-ZU':
            # Deassert HDMI clock reset
            ol.hdmi_tx_control.channel2[0].write(1)
            # Wait 200 ms for the clock to come out of reset
            sleep(0.2)

            ol.video.phy.vid_phy_controller.initialize()

            self._hdmi_out.frontend.set_phy(ol.video.phy.vid_phy_controller)

            dp159 = DP159(ol.HDMI_CTL_axi_iic, 0x5C)
            si = SI_5324C(ol.HDMI_CTL_axi_iic, 0x68)
            self._hdmi_out.frontend.clocks = [dp159, si]
            if (ol.hdmi_tx_control.read(0)) == 0:
                ol.hdmi_tx_control.write(0, 1)

    def _configure(self):
        """Add cv2.CAP_V4L2 to make sure V4L2 libraries are used"""
        if isinstance(self._file, int):
            self._file += cv2.CAP_V4L2
        self._videoIn = cv2.VideoCapture(self._file)
        if not self._videoIn:
            raise RuntimeError("OpenCV can't open {}".format(self._file))
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

        f_reso = (int(self._videoIn.get(cv2.CAP_PROP_FRAME_WIDTH)),
                  int(self._videoIn.get(cv2.CAP_PROP_FRAME_HEIGHT)))
        v_reso = (self.mode.width, self.mode.height)

        if f_reso != v_reso:
            raise RuntimeError("Source {} and sink {} resolution do not match"
                               .format(f_reso, v_reso))

    def start(self):
        """Start video stream by configuring it"""
        if not self._started:
            self._configure()
            self._hdmi_out.configure(self.mode)
            self._hdmi_out.start()
            self._tie()
            self._started = True
        elif not self._running:
            self._tie()

    def stop(self):
        """Stop the video stream"""

        if self._videoIn and self._started:
            self._running = False
            while self._thread.is_alive():
                sleep(0.05)
            self._videoIn.release()
            self._hdmi_out.stop()
            self._videoIn = None
            self._started = False

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

        for _ in range(5):
            ret, frame = self._videoIn.read()
            if not ret:
                self._configure()
            else:
                return frame
        raise RuntimeError("OpenCV can't rewind {}".format(self._file))

    def _tie(self):
        """Mirror the video stream input to an output channel"""

        if not self._videoIn:
            raise SystemError("The stream is not started")

        self._outframe = self._hdmi_out.newframe()
        self._thread = threading.Thread(target=self._tievdma, daemon=True)
        self._running = True
        try:
            self._thread.start()
        except Exception:
            import traceback
            print(traceback.format_exc())

    def _tievdma(self):
        """Threaded method to implement tie"""

        while self._running:
            self._outframe[:] = self.readframe()
            self._hdmi_out.writeframe(self._outframe)


class OpenCVDPVideo(OpenCVPLVideo):
    """Wrapper for a webcam/file video pipeline streamed to DisplayPort"""

    def __init__(self, ol: Overlay, filename: Union[int, str],
                 mode=VideoMode(1280, 720, 24, 60)):
        """ Returns a OpenCVDP object

        Parameters
        ----------
        filename : [int, str]
            video filename
        mode : VideoMode
            webcam configuration
        vdma : pynq.lib.video.dma.AxiVDMA
            Xilinx VideoDMA IP core
        """

        if not isinstance(filename, str) and not isinstance(filename, int):
            raise ValueError("filename ({}) is not an string or integer"
                             .format(filename))

        if isinstance(filename, str) and not os.path.exists(filename):
            raise RuntimeError("File {} does not exists".format(filename))

        self._file = filename
        self.vdma = ol.video.axi_vdma
        self.mode = mode
        self._dp = _DisplayPort()
        if self.vdma:
            self.vdma.writechannel.mode = self.mode
            self.vdma.readchannel.mode = self.mode

        self._running = None
        self._started = None

    def start(self):
        """Configure and start the video stream from/to PS"""

        self._configure()
        if not self._started:
            self._dp.configure(self.mode, PIXEL_RGB)
            self.vdma.writechannel.start()
            self.vdma.readchannel.start()
            self._started = True
            self._tie()

    def stop(self):
        """Stop video stream"""

        if self._started:
            self._running = False
            while self._thread.is_alive():
                sleep(0.05)
            self.vdma.writechannel.stop()
            self.vdma.readchannel.stop()
            self._dp.stop()
            self._started = False

    def _tie(self):
        """Mirror the video stream input to an output channel"""

        if not self._videoIn:
            raise SystemError("The stream is not started")

        self._thread = threading.Thread(target=self._tievdma, daemon=True)
        self._running = True

        try:
            self._thread.start()
        except Exception:
            import traceback
            print(traceback.format_exc())
            raise ValueError("error starting new thread")

    def _tievdma(self):
        """Threaded method to implement tie"""

        while self._running:
            try:
                fpgaframe = self.vdma.writechannel.newframe()
                fpgaframe[:] = self.readframe()
                self.vdma.writechannel.writeframe(fpgaframe)
                dpframe = self._dp.newframe()
                dpframe[:] = self.vdma.readchannel.readframe()
                self._dp.writeframe(dpframe)
            except RuntimeError:
                raise RuntimeError("Can't start thread")


class VideoStream:
    """VideoStream class

    Handles DisplayPort output paths
    .start: configures hdmi_in and hdmi_out starts them and tie them together
    .stop: closes hdmi_in and hdmi_out

    """
    _fres = "/tmp/resolution.json"

    def __init__(self, ol: Overlay, source: VSource = VSource.HDMI,
                 sink: VSink = VSink.HDMI, file: int = 0,
                 mode: VideoMode = None):
        """Return a HDMIVideo object to handle the video path

        Parameters
        ----------
        ol : pynq.Overlay
            Overlay object
        source : str (optional)
            Input video source. Valid values [VSource.HDMI, VSource.MIPI]
        """

        if not mode:
            if CPU_ARCH == ZYNQ_ARCH or source == VSource.MIPI \
                    or (source == VSource.OpenCV and isinstance(file, int)):
                mode = VideoMode(1280, 720, 24, 60)
            else:
                mode = VideoMode(1920, 1080, 24, 60)

        if (source == VSource.HDMI or source == VSource.MIPI) and \
                sink == VSink.HDMI:
            self._video = PLPLVideo(ol=ol, source=source)
        elif (source == VSource.HDMI or source == VSource.MIPI) and \
                sink == VSink.DP:
            self._video = PLDPVideo(ol, source)
        elif source == VSource.OpenCV and sink == VSink.HDMI:
            self._video = OpenCVPLVideo(ol, file, mode)
        elif source == VSource.OpenCV and sink == VSink.DP:
            self._video = OpenCVDPVideo(ol=ol, filename=file, mode=mode)

        reso = {"width": mode.width, "height": mode.height, "fps": mode.fps}
        with open(self._fres, "w", encoding="utf-8") as f:
            json.dump(reso, f)

    def start(self):
        """Start the video stream"""
        self._video.start()

    def stop(self):
        """Stop the video stream"""

        if os.path.exists(self._fres):
            os.remove(self._fres)
        self._video.stop()

    def pause(self):
        """Pause the stream"""
        if hasattr(self._video, "pause"):
            self._video.pause()

    @property
    def mode(self):
        """Return mode"""
        return self._video.mode
