// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "hls_stream.h"
#include "common/xf_common.hpp"
#include "common/xf_utility.hpp"
#include "common/xf_infra.hpp"
#include "imgproc/xf_cvt_color.hpp"

#define DATA_WIDTH 24
#define NPIX XF_NPPC1

/*  set the height and width  */
#define WIDTH 1920
#define HEIGHT 1080


#define INTYPE XF_8UC3
#define TMPTYPE XF_8UC1

typedef xf::cv::ap_axiu<DATA_WIDTH,1,1,1> interface_t;
typedef hls::stream<interface_t> stream_t;

// https://xilinx.github.io/Vitis_Libraries/vision/2020.2/api-reference.html#rgb-to-gray
// https://xilinx.github.io/Vitis_Libraries/vision/2020.2/api-reference.html#gray-to-rgb
void rgb2gray_accel(stream_t& stream_in, 
                    stream_t& stream_out,
                    unsigned int rows,
                    unsigned int cols)
{
#pragma HLS INTERFACE axis register both port=stream_in
#pragma HLS INTERFACE axis register both port=stream_out
#pragma HLS INTERFACE s_axilite port=rows offset=0x10
#pragma HLS INTERFACE s_axilite port=cols offset=0x18
#pragma HLS INTERFACE s_axilite port=return

    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_in(rows, cols);
    xf::cv::Mat<TMPTYPE, HEIGHT, WIDTH, NPIX> img_gray(rows, cols);
    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_out(rows, cols);

#pragma HLS DATAFLOW

    // Convert stream in to xf::cv::Mat
    xf::cv::AXIvideo2xfMat<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(stream_in, img_in);

    // Convert original image to grayscale
    xf::cv::rgb2gray<INTYPE, TMPTYPE, HEIGHT, WIDTH, NPIX>(img_in, img_gray);

    // Convert grayscale image to rgb
    xf::cv::gray2rgb <TMPTYPE, INTYPE, HEIGHT, WIDTH, NPIX>(img_gray, img_out);

    // Convert xf::cv::Mat to stream
    xf::cv::xfMat2AXIvideo<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(img_out, stream_out);
}
