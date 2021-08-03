# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import numpy as np
from pynq import DefaultIP, Overlay
from pynq.lib.video import *
from pynq.lib.video.clocks import *
import struct
import time


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


class HDMIVideo:
    """ HDMI class
    
    Handles HDMI input and output paths
    .start: configures hdmi_in and hdmi_out starts them and tie them together
    .stop: closes hdmi_in and hdmi_out

    """

    def __init__(self, ol: Overlay, source: str='HDMI') -> None:
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
            raise ValueError("Device {} only supports {} as input source "\
                .format(ol.device.name, vsources[0]))

        self._hdmi_out = ol.video.hdmi_out
        self._source = source
        self._started = None

        if ol.device.name == 'Pynq-ZU':
            # Deassert HDMI clock reset
            ol.reset_control.channel1[0].write(1)
            # Wait 200 ms for the clock to come out of reset
            time.sleep(0.2)

            ol.video.phy.vid_phy_controller.initialize()

            if self._source == 'HDMI':
                self._source_in = ol.video.hdmi_in
                self._source_in.frontend.set_phy(\
                    ol.video.phy.vid_phy_controller)
            else:
                self._source_in = ol.mipi


            self._hdmi_out.frontend.set_phy(ol.video.phy.vid_phy_controller)

            dp159 = DP159(ol.HDMI_CTL_axi_iic, 0x5C)
            si = SI_5324C(ol.HDMI_CTL_axi_iic, 0x68)
            self._hdmi_out.frontend.clocks = [dp159, si]
            if((ol.tx_en_out.read(0)) == 0):
                ol.tx_en_out.write(0, 1)
        else:
            self._source_in = ol.video.hdmi_in


    def start(self):
        """ Configure and start the HDMI

        """
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
        """ Stop the HDMI

        """
        if self._started:
            self._hdmi_out.close()
            self._source_in.close()
            self._started = False


def _float2int(value: float) -> int:
    """ Pack a single precision floating point into a 32-bit integer

    """
    return int.from_bytes(struct.pack('f', np.single(value)),'little')


class VitisVisionIP(DefaultIP):
    """Generic Driver for Vitis Vision IP cores"""
    
    bindto = [
        'xilinx.com:hls:dma2video_accel:1.0', 
        'xilinx.com:hls:video2dma_accel:1.0',
        'xilinx.com:hls:rgb2gray_accel:1.0', 
        'xilinx.com:hls:medianBlur_accel:1.0',
        'xilinx.com:hls:gray2rgb_accel:1.0', 
        'xilinx.com:hls:pyrUp_accel:1.0', 
        'xilinx.com:hls:subtract_accel:1.0', 
        'xilinx.com:hls:rgb2hsv_accel:1.0', 
        'xilinx.com:hls:rgb2xyz_accel:1.0',
        "xilinx.com:hls:absdiff_accel:1.0",
        "xilinx.com:hls:add_accel:1.0",
        "xilinx.com:hls:bitwise_and_accel:1.0",
        "xilinx.com:hls:bitwise_not_accel:1.0",
        "xilinx.com:hls:bitwise_or_accel:1.0",
        "xilinx.com:hls:bitwise_xor_accel:1.0",
    ]

    _rows_offset = 0x10
    _cols_offset = 0x18

    def __init__(self, description):
        super().__init__(description=description)
        if description['device'].name == 'Pynq-ZU':
            self._cols = 1920
            self._rows = 1280
        else:
            self._cols = 1280
            self._rows = 720
        
    def start(self):
        """ Populate the image resolution and start the IP
        """
        self.write(self._rows_offset, int(self._rows))
        self.write(self._cols_offset, int(self._cols))
        self.write(0x00, 0x81)

    def stop(self):
        """ Stop the IP
        """
        self.write(0x00, 0x0)


    @property
    def rows(self) -> int:
        """Image height"""
        return self._rows

    @rows.setter
    def rows(self, rows: int):
        if not isinstance(rows, int):
            raise ValueError("rows must an integer")
        elif rows < 0:
            raise ValueError("rows cannot be negative")

        self._rows = rows
        self.write(self._rows_offset, int(self._rows))

    @property
    def cols(self) -> int:
        """Image width"""
        return self._cols

    @cols.setter
    def cols(self, cols: int):
        if not isinstance(cols, int):
            raise ValueError("cols must an integer")
        elif cols < 0:
            raise ValueError("cols cannot be negative")

        self._cols = cols
        self.write(self._cols_offset, int(self._cols))


class Filter2d(VitisVisionIP):
    """Filter 2D Kernel"""
    bindto = ['xilinx.com:hls:filter2d_accel:1.0']
    
    _kernel_list = ['identity', 'edge_x', 'edge_y', 'edge', 'sharpen', 
                    'sobel_x', 'sobel_y', 'scharr_x', 'scharr_y',
                    'prewitt_x','prewitt_y','gaussian_blur', 'median_blur']

    _size = 3

    def __init__(self, description):
        super().__init__(description=description)
        self._kernel = np.zeros((self._size, self._size), dtype=np.int16)
        self._kernel[(self._size//2)+1][(self._size//2)+1] = 1
        self._quantize_error = 0
        self._shift  = 0

        self._kernel_type = self._kernel_list[0]
        self._sigma = 1.0

    def _gaussianBlur(self):
        """ Compute a Gaussian kernel of a given size and sigma.
        Implementation based on 
        """
        kernel = np.zeros((self._size, self._size), dtype=float)
        for u in range(kernel.shape[0]):
            for v in range(kernel.shape[1]):
                uc = u - (kernel.shape[0]-1)/2
                vc = v - (kernel.shape[1]-1)/2
                g = np.exp(-(np.power(uc,2)+np.power(vc,2))/\
                    (2*np.power(self._sigma,2)))
                kernel[u][v] = g
        
        return kernel / np.sum(kernel)
    
    def _medianBlur(self):
        kernel = np.ones((self._size, self._size), dtype=float)
        return kernel / np.sum(kernel)
    
    def _quantiseKernel(self, kernel, bit_width:int=16, max_shift:int=255):
        """ Quantise the floating point kernel into integer taking into account
        the maximum element in the kernel
        """
        max_value = np.max(kernel)
        scaling_max = (np.power(2,bit_width-1)) / max_value
        shift_up = int(np.floor(np.log2(scaling_max)))
        scale_factor = np.power(2, shift_up) - 1
        kernel_q = np.rint(kernel * scale_factor)
        self._quantize_error = (kernel * scale_factor) - kernel_q
        
        return kernel_q.astype(np.int16), shift_up
    
    @property
    def sigma(self):
        return self._sigma

    @sigma.setter
    def sigma(self, sigma):
        if not isinstance(sigma, (float, int)):
            raise ValueError("sigma must a number")

        self._sigma = float(sigma)

        if self._kernel_type in ['gaussian_blur']:
            self._kernel, self._shift = \
                self._quantiseKernel(self._gaussianBlur())
            self._populateKernel()

    @property
    def kernel_type(self):
        return self._kernel_type

    @kernel_type.setter
    def kernel_type(self, kernel_type):
        if kernel_type not in self._kernel_list:
            raise ValueError("Kernel type unknown")
        
        self._shift  = 0
        if kernel_type is 'identity':
            #self._kernel = np.array([[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[0,0,0],[0,1,0],[0,0,0]], dtype=np.int16)
        elif kernel_type is 'edge_x':
            #self._kernel = np.array([[0,0,0,0,0],[0,0,-1,0,0],[0,-1,4,-1,0],[0,0,-1,0,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[0,-1,0],[-1,4,-1],[0,-1,0]], dtype=np.int16)
        elif kernel_type is 'edge_y':
            #self._kernel = np.array([[0,0,0,0,0],[0,1,0,-1,0],[0,0,4,0,0],[0,-1,0,1,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[1,0,-1],[0,4,0],[-1,0,1]], dtype=np.int16)
        elif kernel_type is 'edge':
            #self._kernel = np.array([[0,0,0,0,0],[0,-1,-1,-1,0],[0,-1,8,-1,0],[0,-1,-1,-1,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[-1,-1,-1],[-1,8,-1],[-1,-1,-1]], dtype=np.int16)
        elif kernel_type is 'sobel_x':
            #self._kernel = np.array([[1,2,0,-2,-1],[4,8,0,-8,-4],[6,12,0,-12,-6],[4,8,0,-8,-4],[1,2,0,-2,-1]], dtype=np.int16)
            self._kernel = np.array([[1,0,-1],[2,0,-2],[1,0,-1]], dtype=np.int16)
        elif kernel_type is 'sobel_y':
            #self._kernel = np.array([[-1,-4,-6,-4,-1],[-2,-8,-12,-8,-2],[0,0,0,0,0],[2,8,12,8,2],[1,4,6,4,1]], dtype=np.int16)
            self._kernel = np.array([[1,2,1],[0,0,0],[-1,-2,-1]], dtype=np.int16)
        elif kernel_type is 'sharpen':
            #self._kernel = np.array([[0,0,0,0,0],[0,0,-1,0,0],[0,-1,5,-1,0],[0,0,-1,0,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[0,-1,0],[-1,5,-1],[0,-1,0]], dtype=np.int16)
        elif kernel_type is 'scharr_x':
            #self._kernel = np.array([[0,0,0,0,0],[0,3,0,-3,0],[0,10,0,-10,0],[0,3,0,-3,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[3,0,-3],[10,0,-10],[3,0,-3]], dtype=np.int16)
        elif kernel_type is 'scharr_y':
            #self._kernel = np.array([[0,0,0,0,0],[0,3,10,3,0],[0,0,0,0,0],[0,-3,-10,-3,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[3,10,3],[0,0,0],[-3,-10,-3]], dtype=np.int16)
        elif kernel_type is 'prewitt_x':
            #self._kernel = np.array([[0,0,0,0,0],[0,1,0,-1,0],[0,1,0,-1,0],[0,1,0,-1,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[1,0,-1],[1,0,-1],[1,0,-1]], dtype=np.int16)
        elif kernel_type is 'prewitt_y':
            #self._kernel = np.array([[0,0,0,0,0],[0,1,1,1,0],[0,0,0,0,0],[0,-1,-1,-1,0],[0,0,0,0,0]], dtype=np.int16)
            self._kernel = np.array([[1,1,1],[0,0,0],[-1,-1,-1]], dtype=np.int16)
        elif kernel_type is 'median_blur':
            self._kernel, self._shift = self._quantiseKernel(self._medianBlur())
            self._shift -= 1
        elif kernel_type is 'gaussian_blur':
            self._kernel, self._shift = self._quantiseKernel(self._gaussianBlur())

        self._kernel_type = kernel_type
        self._populateKernel()

    @property
    def kernel_list(self):
        return self._kernel_list
        
    def _populateKernel(self):
        kernel = self._kernel.reshape(self._kernel.shape[0]*\
            self._kernel.shape[1])
        aux = 0
        populate = False
        for i in range(len(kernel)):
            if i%2 == 0:
                aux = kernel[i]
            else:
                aux = ((np.uint32(kernel[i])<<16)  & 0xFFFF0000) + aux
                populate = True

            if populate or (i == len(kernel)-1):
                self.write(0x40+((i//2)*4), int(aux))
                aux = 0
                populate = False
        
        self.write(0x20, int(self._shift))
                
    def start(self):
        super().start()
        self._populateKernel()
    
    def status(self):
        control = self.read(0x00)
        return hex(control)

class DuplicateIP(VitisVisionIP):
    """DuplicateIP driver

    """
    
    bindto = ['xilinx.com:hls:duplicate_accel:1.0']

    _rows_offset = 0x1EC
    _cols_offset = 0x1F4


class GaussianBlur(VitisVisionIP):
    """GaussianBlur"""
    bindto = ['xilinx.com:hls:GaussianBlur_accel:1.0']

    def __init__(self, description):
        super().__init__(description=description)
        self.sigma = 1.0
        
    def start(self):
        super().start()
        if self.sigma < 0.27:
            aux = 0.27
        else:
            aux = self.sigma
        self.write(0x20, _float2int(aux))


class colorThreshold(VitisVisionIP):
    """Color Thresholding IP driver
    lower_thr and upper_thr are a numpy array, each row corresponds to a
    channel in the pixel.
    For RGB, row 0 is R, row 1 is G and row 2 is B
    For HSV, row 0 is H, row 1 is S and row 2 is V
    For XYZ, row 0 is X, row 1 is Y and row 2 is Z

    """
    bindto = ['xilinx.com:hls:colorthresholding_accel:1.0']

    def __init__(self, description):
        super().__init__(description=description)
        self._lower_thr = \
            np.array([[22,38,160],[150,150,150],[60,60,60]], dtype=np.uint8) 
        self._upper_thr = \
            np.array([[38,75,179],[255,255,255],[255,255,255]], dtype=np.uint8)
    
    def _populateThreshold(self):
        lower = self._lower_thr.reshape(self._lower_thr.shape[0]*\
            self._lower_thr.shape[1])
        upper = self._upper_thr.reshape(self._upper_thr.shape[0]*\
            self._upper_thr.shape[1])
        aux = 0
        for i in range(lower.shape[0]):
            shift = (i % 4) * 8
            aux = (np.uint32(lower[i]) << shift) + aux
            
            if ((i+1)%4)==0 or i==(len(lower)-1):
                self.write(0x20 + (i//4) * 4, int(aux))
                aux = 0
        aux = 0
        for i in range(upper.shape[0]):
            shift = (i % 4) * 8
            aux = (np.uint32(upper[i]) << shift) + aux
            
            if ((i+1)%4)==0 or i==(len(upper)-1):
                self.write(0x60 + (i//4) * 4, int(aux))
                aux = 0
                
    def start(self):
        super().start()
        self._populateThreshold()

    @property
    def lower_thr(self):
        """ Set and retrieve lower threshold configuration
        """        
        return self._lower_thr

    @lower_thr.setter
    def lower_thr(self, threshold):
        if not isinstance(threshold, np.ndarray):
            raise ValueError("lower_thr expects a numpy ndarray as input")
        elif threshold.shape != self._lower_thr.shape:
            raise ValueError("Shapes do not match, lower_thr expects a {} "
                "ndarray".format(self._lower_thr.shape))
        self._lower_thr = threshold
        self._populateThreshold()

    @property
    def upper_thr(self):
        """ Set and retrieve lower threshold configuration
        """        
        return self._upper_thr

    @upper_thr.setter
    def upper_thr(self, threshold):
        if not isinstance(threshold, np.ndarray):
            raise ValueError("upper_thr expects a numpy ndarray as input")
        elif threshold.shape != self._upper_thr.shape:
            raise ValueError("Shapes do not match, upper_thr expects a {} "
                "ndarray".format(self._upper_thr.shape))        
        self._upper_thr = threshold
        self._populateThreshold()

            
            
class inRange(VitisVisionIP):
    """inRange"""
    bindto = ['xilinx.com:hls:inRange_accel:1.0']

    def __init__(self, description):
        super().__init__(description=description)
        self.lower_thr = np.array([22,150,60], dtype=np.uint8) 
        self.upper_thr = np.array([38,255,255], dtype=np.uint8) 
    
    def populateThreshold(self):
        lower = self.lower_thr
        upper = self.upper_thr
        aux = 0
        for i in range(lower.shape[0]):
            shift = (i % 4) * 8
            aux = (np.uint32(lower[i]) << shift) + aux
            
            if ((i+1)%4)==0 or i==(len(lower)-1):
                self.write(0x20 + (i//4) * 4, int(aux))
                aux = 0
        aux = 0
        for i in range(upper.shape[0]):
            shift = (i % 4) * 8
            aux = (np.uint32(upper[i]) << shift) + aux
            
            if ((i+1)%4) == 0 or i==(len(upper)-1):
                self.write(0x30 + (i//4) * 4, int(aux))
                aux = 0
                
    def start(self):
        super().start()
        self.populateThreshold()
            
class Morphological(VitisVisionIP):
    """Erode and dilate"""
    bindto = [ 
        'xilinx.com:hls:dilate_accel:1.0', 
        'xilinx.com:hls:erode_accel:1.0'
    ]

    def __init__(self, description):
        super().__init__(description=description)
        self.kernel = np.ones((3,3), dtype=np.uint8)
    
    def populateKernel(self):
        kernel = self.kernel.reshape(self.kernel.shape[0]*self.kernel.shape[1])
        aux = 0
        for i in range(len(kernel)):
            shift = (i % 4) * 8
            aux = (kernel[i]<<shift) + aux

            if ((i+1)%4) == 0 or (i==len(kernel)-1):
                self.write(0x40+((i//4)*4), int(aux))
                aux = 0
                
    def start(self):
        super().start()
        self.populateKernel()

class Fast(VitisVisionIP):
    """Corner Detect, using Fast algorithm IP, python driver"""

    bindto = ['xilinx.com:hls:fast_accel:1.0']
    _max_threshold = (2**8) - 1

    def __init__(self, description):
        super().__init__(description=description)
        self._threshold = 20
    
    @property
    def threshold(self):
        return self._threshold

    @threshold.setter
    def threshold(self, threshold):
        if not isinstance(threshold, int):
            raise ValueError("threshold must be int")
        elif threshold > self._max_threshold:
            raise ValueError("threshold cannot be bigger than {}".\
                format(self._max_threshold))
        self._threshold = threshold
        self.write(0x20, int(self._threshold))

    def start(self):
        super().start()
        self.write(0x20, int(self._threshold))

def _convert_to_q0_16(v, maxval=(2**16)-1):
    vtmp = int(v*(2**16))
    return vtmp if vtmp <= maxval else maxval


class CornerHarris(VitisVisionIP):
    """Corner Detector, using Harris algorithm IP, python driver"""

    bindto = ['xilinx.com:hls:cornerHarris_accel:1.0']
    _max_threshold = (2**16) - 1

    def __init__(self, description):
        super().__init__(description=description)
        # set default threshold and k as per documentation
        self._threshold = 442
        self._k = _convert_to_q0_16(0.04)


    @property
    def threshold(self):
        return self._threshold

    @threshold.setter
    def threshold(self, threshold):
        if not isinstance(threshold, int):
            raise ValueError("threshold must be int")
        elif threshold > self._max_threshold:
            raise ValueError("threshold cannot be bigger than {}".\
                format(self._max_threshold))

        self._threshold = threshold
        self.write(0x20, int(self._threshold))

    @property
    def k(self):
        """ Harris detector parameter
        """
        return self._k

    @k.setter
    def k(self, k):
        if not isinstance(k, float):
            raise ValueError("k must be float")
        elif k > 1.0:
            raise ValueError("k must be between 0.0 and 1.0")

        self._k = _convert_to_q0_16(k)
        self.write(0x28, int(self._k))
    
    def start(self):
        super().start()
        self.write(0x20, int(self._threshold))
        self.write(0x28, int(self._k))


class PixelLut(VitisVisionIP):
    """Lut IP"""
    bindto = ['xilinx.com:hls:LUT_accel:1.0']

    _kernel_list = ['negative', 'original', 'binary_threshold', 'group_bin', 
                    'offset', 'threshold', 'random']

    def __init__(self, description):
        super().__init__(description=description)
        self.lut = np.empty((3, 256), dtype=np.uint8)
        self.step = 8
        self.offset = 32
        self._shape = self.lut.shape
        self.kernel_type = self._kernel_list[0]
        self._threshold = np.random.randint(0,255,(2, 3, 3), dtype=np.uint8)


    def _negative(self):
        for c in range(self._shape[0]):
            for e in range(self._shape[1]):
                self.lut[c][e] = 255-e

    def _original(self):
        for c in range(self._shape[0]):
            for e in range(self._shape[1]):
                self.lut[c][e] = e

    def _binary_threshold(self):
        for c in range(self._shape[0]):
            for e in range(self._shape[1]):
                if e < 128:
                    self.lut[c][e] = 0
                else:
                    self.lut[c][e] = 255

    def _group_bin(self, step=8):
        for c in range(self._shape[0]):
            for e in range(self._shape[1]):
                self.lut[c][e] = (e//self.step) * self.step

    def _offset(self):
        for c in range(self._shape[0]):
            for e in range(self._shape[1]):
                aux = (int(e) + self.offset) % 256
                self.lut[c][e] = np.uint8(aux)

    def _custom_threshold(self):
        """ Fill range between lower and upper threshold with 255 for
        each channel
        """

        lut = np.zeros(self.lut.shape, dtype=np.uint8)

        for c in range(lut.shape[0]):
            min_value = self._threshold[0][c]
            max_value = self._threshold[1][c]
            for idx, e in enumerate(min_value):
                for v in range(min_value[idx],max_value[idx]):
                    lut[2-c][v] = 255

        self.lut = lut


    @property
    def threshold(self):
        """ Set an retrieve threshold ndarray
        The first index indicates 
            0: lower threshold
            1: upper threshold
        The second index indicates the channel
        The third index indicates the value
        """
        return self._threshold

    @threshold.setter
    def threshold(self, matrix):
        if not isinstance(matrix, np.ndarray):
            raise ValueError("threshold expects a numpy ndarray as input")
        elif matrix.shape != self._threshold.shape:
            raise ValueError("Shapes do not match, threshold expects a {} "
                "ndarray".format(self._threshold.shape))    

        self._threshold = matrix
        self.kernel_type = 'threshold'

    @property
    def kernel_type(self):
        return self._kernel_type

    @property
    def kernel_list(self):
        return self._kernel_list

    @kernel_type.setter
    def kernel_type(self, kernel_type):
        if kernel_type not in self._kernel_list:
            raise ValueError("Kernel type unknown")

        if kernel_type == 'negative':
            self._negative()
        elif kernel_type == 'original':
            self._original()
        elif kernel_type == 'binary_threshold':
            self._binary_threshold()
        elif kernel_type == 'group_bin':
            self._group_bin()
        elif kernel_type == 'offset':
            self._offset()
        elif kernel_type == 'threshold':
            self._custom_threshold()
        elif kernel_type == 'random':
            self.lut = np.random.randint(0,255, self._shape, dtype=np.uint8)

        self._kernel_type = kernel_type
        self.populateLUT()


    def populateLUT(self):
        kernel = self.lut.reshape(self._shape[0]*self._shape[1])
        aux = 0
        for i in range(len(kernel)):
            shift = (i % 4) * 8
            aux = (kernel[i]<<shift) + aux

            if ((i+1)%4) == 0 or (i==len(kernel)-1):
                self.write(0x400+((i//4)*4), int(aux))
                aux = 0

    def start(self):
        super().start()
        self.populateLUT()
        

class MultiplyIP(VitisVisionIP):
    """Pixel-wise multiplication

    """
    
    bindto = [ 'xilinx.com:hls:multiply_accel:1.0']

    def __init__(self, description):
        super().__init__(description=description)
        self._scale = 1.0
    
    def start(self):
        super().start()
        self.write(0x20, _float2int(self.scale))

    @property
    def scale(self):
        """ Scale value
    
        Each pixel is multiplied by this scale value

        """
        return self._scale

    @scale.setter
    def scale(self, scale):
        if not isinstance(scale, (int, float)):
            raise ValueError("scale should be int or float")
        elif scale < 0:
            raise ValueError("scale cannot be negative")

        self._scale = float(scale)
        self.write(0x20, _float2int(self.scale))

