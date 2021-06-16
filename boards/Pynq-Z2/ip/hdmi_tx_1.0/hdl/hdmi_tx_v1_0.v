//////////////////////////////////////////////////////////////////////////////////
// Module: hdmi_tx_v1_0
// Author: Tinghui Wang
//
// Copyright @ 2017-2019 RealDigital.org
//
// Description:
//   HDMI/DVI encoder module for Xilinx 7-series FPGA.
//
// Note:
//   Part of the codes used in this module originated from XAPP460 by Bob Feng.
//
// History:
//   11/12/17: Created
//   02/01/19: Update to utilize vid_io bus interface in Vivado.
//   02/05/19: Update to synchronize rst_i signal to pix_clk.
//   02/06/19: Added asynchronous reset to rst_i signal.
//
// License: BSD 3-Clause
//
// Redistribution and use in source and binary forms, with or without 
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this 
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, 
//    this list of conditions and the following disclaimer in the documentation 
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors 
//    may be used to endorse or promote products derived from this software 
//    without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Xilinx Disclaimer From XAPP460:
//   LIMITED WARRANTY AND DISCLAMER. These designs are provided to you "as is". 
//   Xilinx and its licensors makeand you receive no warranties or conditions, 
//   express, implied, statutory or otherwise, and Xilinx specifically disclaims 
//   any implied warranties of merchantability, non-infringement,or fitness for a 
//   particular purpose. Xilinx does notwarrant that the functions contained in 
//   these designs will meet your requirements, or that the operation of these 
//   designs will be uninterrupted or error free, or that defects in the Designs
//   will be corrected. Furthermore, Xilinx does not warrantor make any 
//   representations regarding use or the results ofthe use of the designs in 
//   terms of correctness, accuracy, reliability, or otherwise.
//
//   LIMITATION OF LIABILITY. In no event will Xilinx or its licensors be liable 
//   for any loss of data, lost profits,cost or procurement of substitute goods or 
//   services, or for any special, incidental, consequential, or indirect damages
//   arising from the use or operation of the designs or accompanying 
//   documentation, however caused and on anytheory of liability. This limitation 
//   will apply even if Xilinx has been advised of the possibility of such damage. 
//   This limitation shall apply not-withstanding the failure of the essential 
//   purpose of any limited remedies herein.
//
//   Copyright  2004 Xilinx, Inc.
//   All rights reserved
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1ps

module hdmi_tx_v1_0 # (
  parameter MODE = "DVI",	// Encoder Mode: HDMI or DVI
  parameter C_DATA_WIDTH = 32,  // Data width of bus with RGB
  parameter C_RED_WIDTH = 8,	// Width of Red Channel
  parameter C_GREEN_WIDTH = 8,  // Width of Green Channel
  parameter C_BLUE_WIDTH = 8	// Width of Blue Channel
)(
    // clock and control signals
    input pix_clk,              // Pixel Clock
    input pix_clkx5,            // Pixel Clock x5 - used for TMDS serializer
    input pix_clk_locked,       // Pixel Locked signal
    input rst,                  // reset
    // fit to XSVI standard port
    input [C_DATA_WIDTH-1:0] pix_data,  // Width of RGB data bus
    input hsync,                        // Hsync Data
    input vsync,                        // Vsync Data
    input vde,                          // Video Data enable
    // audio part
    input [3:0]   aux0_din,             // Audio/Auxilary Data
    input [3:0]   aux1_din,             // Audio/Auxilary Data
    input [3:0]   aux2_din,             // Audio/Auxilary Data
    input         ade,                  // Audio/Auxilary Data Enable
    // hdmi output ports
    output TMDS_CLK_P,          // HDMI/DVI Differential Clock
    output TMDS_CLK_N,          // HDMI/DVI Differential Clock
    output  [2:0] TMDS_DATA_P,  // HDMI/DVI Differential Data Channel
    output  [2:0] TMDS_DATA_N   // HDMI/DVI Differential Data Channel
);

// Reset
wire rst_i, rst_in;
reg rst_q1, rst_q2;
assign rst_in = rst | ~pix_clk_locked;
assign rst_i = rst_q2;

// Generate synchronous reset signal
always @ (posedge pix_clk or posedge rst_in) begin
  if (rst_in) begin
    rst_q1 <= 1'b1;
    rst_q2 <= 1'b1;
  end else begin
    rst_q1 <=#1 rst_in;
    rst_q2 <=#1 rst_q1;
  end
end

// Padding/Truncating RGB to 24-bit color depth
wire    [7:0]   blue_din;         // Blue data in
wire    [7:0]   green_din;        // Green data in
wire    [7:0]   red_din;          // Red data in

// RBG Breakout
wire [C_RED_WIDTH-1:0] red;        // Red Channel Video Data
wire [C_GREEN_WIDTH-1:0] green;    // Green Channel Video Data
wire [C_BLUE_WIDTH-1:0] blue;      // Blue Channel Video Data
assign red = pix_data[C_RED_WIDTH+C_GREEN_WIDTH+C_BLUE_WIDTH-1:C_GREEN_WIDTH+C_BLUE_WIDTH];
assign green = pix_data[C_GREEN_WIDTH+C_BLUE_WIDTH-1:C_BLUE_WIDTH];
assign blue = pix_data[C_BLUE_WIDTH-1:0];


generate
if (C_RED_WIDTH >= 8)
    assign red_din = red[C_RED_WIDTH-1 : C_RED_WIDTH-8];
else
    assign red_din = {red, {(8-C_RED_WIDTH) {1'b0}}};
endgenerate

generate
if (C_GREEN_WIDTH >= 8)
    assign green_din = green[C_GREEN_WIDTH-1 : C_GREEN_WIDTH-8];
else
    assign green_din = {green, {(8-C_GREEN_WIDTH) {1'b0}}};
endgenerate

generate
if (C_BLUE_WIDTH >= 8)
    assign blue_din = blue[C_BLUE_WIDTH-1 : C_BLUE_WIDTH-8];
else
    assign blue_din = {blue, {(8-C_BLUE_WIDTH) {1'b0}}};
endgenerate


wire    [9:0]   tmds_red;
wire    [9:0]   tmds_green;
wire    [9:0]   tmds_blue;

localparam DILNDPREAM = 4'b1010;
localparam VIDEOPREAM = 4'b1000;
localparam NULLCONTRL = 4'b0000;

// Prepare CTRL0, CTRL1 signal for Red and Green Channel
// Blue channel encodes hsync and vsync
wire ctl0, ctl1, ctl2, ctl3;

generate
if (MODE == "HDMI") begin
    reg  hdmi_ctl0, hdmi_ctl1, hdmi_ctl2, hdmi_ctl3;
    always @ (posedge pix_clk) begin
        if(vde)
            {hdmi_ctl0, hdmi_ctl1, hdmi_ctl2, hdmi_ctl3} <=#1 VIDEOPREAM;
        else if(ade)
            {hdmi_ctl0, hdmi_ctl1, hdmi_ctl2, hdmi_ctl3} <=#1 DILNDPREAM;
        else
            {hdmi_ctl0, hdmi_ctl1, hdmi_ctl2, hdmi_ctl3} <=#1 NULLCONTRL;
    end
    assign ctl0 = hdmi_ctl0;
    assign ctl1 = hdmi_ctl1;
    assign ctl2 = hdmi_ctl2;
    assign ctl3 = hdmi_ctl3;
end
else
begin
    assign ctl0 = 1'b0;
    assign ctl1 = 1'b0;
    assign ctl2 = 1'b0;
    assign ctl3 = 1'b0;
end
endgenerate

wire [7:0] blue_dly, green_dly, red_dly;
wire [3:0] aux0_dly, aux1_dly, aux2_dly;
wire       hsync_dly, vsync_dly, vde_dly, ade_dly;

// Local Delays to data and audio signal. A delay of 10 clock cycle is needed to insert preamble
// and guardband according to HDMI specification 1.3. In DVI mode, there is no such requirement,
// so a delay of 1 clock would be more than enough.
localparam SRL_DELAY = (MODE == "HDMI") ? 4'b1010 : 4'b0001;

srldelay # (
    .WIDTH(40),
    .TAPS(SRL_DELAY)
) srldly_0 (
    .data_i({blue_din, green_din, red_din, aux0_din, aux1_din, aux2_din, hsync, vsync, vde, ade}),
    .data_o({blue_dly, green_dly, red_dly, aux0_dly, aux1_dly, aux2_dly, hsync_dly, vsync_dly, vde_dly, ade_dly}),
    .clk(pix_clk)
);

// Data Channel Encoders
encode # (
  .CHANNEL("BLUE"),
  .MODE(MODE)
)encb (
    .clkin  (pix_clk),
    .rstin  (rst_i),
    .vdin   (blue_dly),
    .adin   (aux0_dly),
    .c0     (hsync_dly),
    .c1     (vsync_dly),
    .vde    (vde_dly),
    .ade    (ade_dly),
    .dout   (tmds_blue)) ;

encode # (
  .CHANNEL("GREEN"),
  .MODE(MODE)
) encg (
    .clkin  (pix_clk),
    .rstin  (rst_i),
    .vdin   (green_dly),
    .adin   (aux1_dly),
    .c0     (ctl0),
    .c1     (ctl1),
    .vde    (vde_dly),
    .ade    (ade_dly),
    .dout   (tmds_green)) ;

encode # (
  .CHANNEL("RED"),
  .MODE(MODE)
) encr (
    .clkin  (pix_clk),
    .rstin  (rst_i),
    .vdin   (red_dly),
    .adin   (aux2_dly),
    .c0     (ctl2),
    .c1     (ctl3),
    .vde    (vde_dly),
    .ade    (ade_dly),
    .dout   (tmds_red)) ;

wire [9:0] tmdsclkint;
assign tmdsclkint = 10'b1111100000;

wire [2:0] TMDSINT;
wire tmdsclk;

// Channel 10-to-1 serializer
serdes_10_to_1 serial_b(
    .clk_x5(pix_clkx5),
    .reset(rst_i),
    .clk(pix_clk),
    .datain(tmds_blue),
    .iob_data_out(TMDSINT[0]));

serdes_10_to_1 serial_g(
    .clk_x5(pix_clkx5),
    .reset(rst_i),
    .clk(pix_clk),
    .datain(tmds_green),
    .iob_data_out(TMDSINT[1]));

serdes_10_to_1 serial_r(
    .clk_x5(pix_clkx5),
    .reset(rst_i),
    .clk(pix_clk),
    .datain(tmds_red),
    .iob_data_out(TMDSINT[2]));

serdes_10_to_1 serial_clk(
    .clk_x5(pix_clkx5),
    .reset(rst_i),
    .clk(pix_clk),
    .datain(tmdsclkint),
    .iob_data_out(tmdsclk));

// Output Differential Buffer
OBUFDS #(
    .IOSTANDARD("TMDS_33")
)
OBUFDS_B(
    .O(TMDS_DATA_P[0]),
    .OB(TMDS_DATA_N[0]),
    .I(TMDSINT[0]));

OBUFDS #(
    .IOSTANDARD("TMDS_33")
)
OBUFDS_G(
    .O(TMDS_DATA_P[1]),
    .OB(TMDS_DATA_N[1]),
    .I(TMDSINT[1]));
OBUFDS #(
    .IOSTANDARD("TMDS_33")
)
OBUFDS_R(
    .O(TMDS_DATA_P[2]),
    .OB(TMDS_DATA_N[2]),
    .I(TMDSINT[2]));

OBUFDS #(
    .IOSTANDARD("TMDS_33")
)
OBUFDS_CLK(
    .O(TMDS_CLK_P),
    .OB(TMDS_CLK_N),
    .I(tmdsclk));

endmodule
