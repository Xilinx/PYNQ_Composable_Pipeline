// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "hls_stream.h"
#include "common/xf_common.hpp"
#include "common/xf_infra.hpp"
#include "features/xf_fast.hpp"

#define DATA_WIDTH 24
#define NPIX XF_NPPC1

/*  set the height and width  */
#define WIDTH 1920
#define HEIGHT 1080
#define INTYPE XF_8UC1
#define NMS 1
#define MAXCORNERS 1024

typedef ap_axiu<DATA_WIDTH,1,1,1> interface_t;
typedef hls::stream<interface_t> stream_t;


//https://xilinx.github.io/Vitis_Libraries/vision/2020.2/api-reference.html#fast-corner-detection
void fast_accel(stream_t& stream_in,
                     stream_t& stream_out, 
                     unsigned char threshold,
                     unsigned int rows,
                     unsigned int cols)
{
#pragma HLS INTERFACE axis register both port=stream_in
#pragma HLS INTERFACE axis register both port=stream_out
#pragma HLS INTERFACE s_axilite port=threshold offset=0x20
#pragma HLS INTERFACE s_axilite port=rows offset=0x10
#pragma HLS INTERFACE s_axilite port=cols offset=0x18
#pragma HLS INTERFACE s_axilite port=return

    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_in(rows, cols);
    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_out(rows, cols);

#pragma HLS DATAFLOW

    // Convert stream in to xf::cv::Mat
    xf::cv::AXIvideo2xfMat<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(stream_in, img_in);

    // Run xfOpenCV kernel:
    xf::cv::fast<NMS, INTYPE, HEIGHT, WIDTH, NPIX>(img_in, img_out, threshold);

    // Convert xf::cv::Mat to stream
    xf::cv::xfMat2AXIvideo<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(img_out, stream_out);
}
