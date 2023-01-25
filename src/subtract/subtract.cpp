// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "hls_stream.h"
#include "common/xf_common.hpp"
#include "common/xf_infra.hpp"
#include "core/xf_arithm.hpp"

#define DATA_WIDTH 24
#define NPIX XF_NPPC1

/*  set the height and width  */
#define WIDTH 1920
#define HEIGHT 1080
#define INTYPE XF_8UC3

typedef ap_axiu<DATA_WIDTH,1,1,1> interface_t;
typedef hls::stream<interface_t> stream_t;

//https://docs.xilinx.com/r/en-US/Vitis_Libraries/vision/api-reference.html_2_83
void subtract_accel(stream_t& stream_in, 
                   stream_t& stream_in1, 
                   stream_t& stream_out, 
                   unsigned int rows,
                   unsigned int cols)
{
#pragma HLS INTERFACE axis register both port=stream_in
#pragma HLS INTERFACE axis register both port=stream_in1
#pragma HLS INTERFACE axis register both port=stream_out
#pragma HLS INTERFACE s_axilite port=rows offset=0x10
#pragma HLS INTERFACE s_axilite port=cols offset=0x18
#pragma HLS INTERFACE s_axilite port=return

    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_in0(rows, cols);
    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_in1(rows, cols);
    xf::cv::Mat<INTYPE, HEIGHT, WIDTH, NPIX> img_out(rows, cols);

#pragma HLS DATAFLOW

    // Convert stream in to xf::cv::Mat
    xf::cv::AXIvideo2xfMat<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(stream_in, img_in0);
    xf::cv::AXIvideo2xfMat<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(stream_in1, img_in1);

    // Run xfOpenCV kernel:
    xf::cv::subtract<XF_CONVERT_POLICY_SATURATE, INTYPE, HEIGHT, WIDTH, NPIX>(img_in0, img_in1, img_out);

    // Convert xf::cv::Mat to stream
    xf::cv::xfMat2AXIvideo<DATA_WIDTH, INTYPE, HEIGHT, WIDTH, NPIX>(img_out, stream_out);
}
