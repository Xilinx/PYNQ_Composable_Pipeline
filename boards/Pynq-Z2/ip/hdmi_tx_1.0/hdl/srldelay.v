//////////////////////////////////////////////////////////////////////////////////
// Module: srldelay
// Author: Tinghui Wang
//
// Copyright @ 2017 RealDigital.org
//
// Description:
//   Delay Line Using SRL16 - maximum 16 taps of delay.
//
// Note:
//   Part of the codes used in this module originated from XAPP460 by Bob Feng.
//
// History:
//   11/12/17: Created
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

module srldelay # (
  parameter WIDTH = 1,       //data width
  parameter TAPS  = 4'b1111  //delay taps
)(
  input  wire                 clk,
  input  wire [(WIDTH - 1):0] data_i,
  output wire [(WIDTH - 1):0] data_o
);

  wire [3:0] dlytaps = TAPS;

  genvar i;
  generate
    for (i=0; i < WIDTH; i = i + 1) begin : srl
      SRL16E # (
        .INIT(16'h0)
      ) srl16_i  (
        .Q   (data_o[i]),
        .A0  (dlytaps[0]),
        .A1  (dlytaps[1]),
        .A2  (dlytaps[2]),
        .A3  (dlytaps[3]),
        .CE  (1'b1),
        .CLK (clk),
        .D   (data_i[i])
      );
    end
  endgenerate

endmodule
