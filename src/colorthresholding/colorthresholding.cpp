// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "hls_stream.h"
#include "common/xf_common.hpp"
#include "common/xf_infra.hpp"
#include "imgproc/xf_colorthresholding.hpp"

#define DATA_WIDTH 24
#define NPIX XF_NPPC1

/*  set the height and width  */
#define WIDTH 1920
#define HEIGHT 1080
#define INTYPE XF_8UC3
#define OUTTYPE XF_8UC1
#define MAXCOLORS 3

typedef xf::cv::ap_axiu<DATA_WIDTH,1,1,1> interface_t;
typedef hls::stream<interface_t> stream_t;

//https://xilinx.github.io/Vitis_Libraries/vision/2020.2/api-reference.html#color-thresholding
void colorthresholding_accel(stream_t& stream_in, 
                             stream_t& stream_out, 
                             unsigned char lower_threshold[MAXCOLORS*3],
                             unsigned char upper_threshold[MAXCOLORS*3],
                             unsigned int rows,
                             unsigned int cols)
{
#pragma HLS INTERFACE axis register both port=stream_in
#pragma HLS INTERFACE axis register both port=stream_out
#pragma HLS INTERFACE s_axilite port=lower_threshold offset=0x20
#pragma HLS INTERFACE s_axilite port=upper_threshold offset=0x60
#pragma HLS INTERFACE s_axilite port=rows offset=0x10
#pragma HLS INTERFACE s_axilite port=cols offset=0x18
#pragma HLS INTERFACE s_axilite port=return

    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_in(rows, cols);
    xf::cv::Mat<OUTTYPE, HEIGHT, WIDTH, NPIX> img_out(rows, cols);

#pragma HLS DATAFLOW

    // Convert stream in to xf::cv::Mat
    xf::cv::AXIvideo2xfMat<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(stream_in, img_in);

    // Run xfOpenCV kernel:
    xf::cv::colorthresholding<INTYPE, OUTTYPE, MAXCOLORS, HEIGHT, WIDTH, NPIX>(img_in, img_out, lower_threshold, upper_threshold);

    // Convert xf::cv::Mat to stream
    xf::cv::xfMat2AXIvideo<DATA_WIDTH, OUTTYPE, HEIGHT, WIDTH, NPIX>(img_out, stream_out);
}
