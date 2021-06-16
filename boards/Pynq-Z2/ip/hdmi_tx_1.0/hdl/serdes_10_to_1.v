//////////////////////////////////////////////////////////////////////////////////
// Module: serdes_10_to_1
// Author: Tinghui Wang
//
// Copyright @ 2017 RealDigital.org
//
// Description:
//   10-to-1 serdes serializer for 7-series FPGA. data is transmitted LSB first.
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
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module serdes_10_to_1 (
    input clk_x5,
    input reset,
    input clk,
    input [9:0] datain,
    output iob_data_out
);

wire slave_shift_out1;
wire slave_shift_out2;

OSERDESE2 # (
    .DATA_WIDTH(10),
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .TRISTATE_WIDTH(1),
    .SERDES_MODE("MASTER")
) oserdes_m (
    .OQ(iob_data_out),
    .OFB(),
    .TQ(),
    .TFB(),
    .SHIFTOUT1(),
    .SHIFTOUT2(),
    .CLK(clk_x5),
    .CLKDIV(clk),
    .D8(datain[7]),
    .D7(datain[6]),
    .D6(datain[5]),
    .D5(datain[4]),
    .D4(datain[3]),
    .D3(datain[2]),
    .D2(datain[1]),
    .D1(datain[0]),
    .TCE(1'b0),
    .OCE(1'b1),
    .TBYTEIN(1'b0),
    .TBYTEOUT(),
    .RST(reset),
    .SHIFTIN1(slave_shift_out1),
    .SHIFTIN2(slave_shift_out2),
    .T4(1'b0),
    .T3(1'b0),
    .T2(1'b0),
    .T1(1'b0)
);

OSERDESE2 # (
    .DATA_WIDTH(10),
    .DATA_RATE_OQ("DDR"),
    .DATA_RATE_TQ("SDR"),
    .TRISTATE_WIDTH(1),
    .SERDES_MODE("SLAVE")
) oserdes_s (
    .OQ(),
    .OFB(),
    .TQ(),
    .TFB(),
    .SHIFTOUT1(slave_shift_out1),
    .SHIFTOUT2(slave_shift_out2),
    .CLK(clk_x5),
    .CLKDIV(clk),
    .D8(1'b0),
    .D7(1'b0),
    .D6(1'b0),
    .D5(1'b0),
    .D4(datain[9]),
    .D3(datain[8]),
    .D2(1'b0),
    .D1(1'b0),
    .TCE(1'b0),
    .OCE(1'b1),
    .TBYTEIN(1'b0),
    .TBYTEOUT(),
    .RST(reset),
    .SHIFTIN1(1'b0),
    .SHIFTIN2(1'b0),
    .T4(1'b0),
    .T3(1'b0),
    .T2(1'b0),
    .T1(1'b0)
);

endmodule
