//======================================================================
//
// md5_k_rom.v
// -------------
// Rom of K constants for the MD5 hash function core.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2019, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module md5_k_rom(input wire [5 : 0] x, output wire [31 : 0] y);

  //----------------------------------------------------------------
  // Registers and wires.
  //----------------------------------------------------------------
  reg [31 : 0] tmp_y;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign y = tmp_y;


  //----------------------------------------------------------------
  // k_rom
  //----------------------------------------------------------------
  always @*
    begin: k_rom
      case(x)
        6'h00: tmp_y = 32'hd76aa478;
        6'h01: tmp_y = 32'he8c7b756;
        6'h02: tmp_y = 32'h242070db;
        6'h03: tmp_y = 32'hc1bdceee;
        6'h04: tmp_y = 32'hf57c0faf;
        6'h05: tmp_y = 32'h4787c62a;
        6'h06: tmp_y = 32'ha8304613;
        6'h07: tmp_y = 32'hfd469501;
        6'h08: tmp_y = 32'h698098d8;
        6'h09: tmp_y = 32'h8b44f7af;
        6'h0a: tmp_y = 32'hffff5bb1;
        6'h0b: tmp_y = 32'h895cd7be;
        6'h0c: tmp_y = 32'h6b901122;
        6'h0d: tmp_y = 32'hfd987193;
        6'h0e: tmp_y = 32'ha679438e;
        6'h0f: tmp_y = 32'h49b40821;
        6'h10: tmp_y = 32'hf61e2562;
        6'h11: tmp_y = 32'hc040b340;
        6'h12: tmp_y = 32'h265e5a51;
        6'h13: tmp_y = 32'he9b6c7aa;
        6'h14: tmp_y = 32'hd62f105d;
        6'h15: tmp_y = 32'h02441453;
        6'h16: tmp_y = 32'hd8a1e681;
        6'h17: tmp_y = 32'he7d3fbc8;
        6'h18: tmp_y = 32'h21e1cde6;
        6'h19: tmp_y = 32'hc33707d6;
        6'h1a: tmp_y = 32'hf4d50d87;
        6'h1b: tmp_y = 32'h455a14ed;
        6'h1c: tmp_y = 32'ha9e3e905;
        6'h1d: tmp_y = 32'hfcefa3f8;
        6'h1e: tmp_y = 32'h676f02d9;
        6'h1f: tmp_y = 32'h8d2a4c8a;
        6'h20: tmp_y = 32'hfffa3942;
        6'h21: tmp_y = 32'h8771f681;
        6'h22: tmp_y = 32'h6d9d6122;
        6'h23: tmp_y = 32'hfde5380c;
        6'h24: tmp_y = 32'ha4beea44;
        6'h25: tmp_y = 32'h4bdecfa9;
        6'h26: tmp_y = 32'hf6bb4b60;
        6'h27: tmp_y = 32'hbebfbc70;
        6'h28: tmp_y = 32'h289b7ec6;
        6'h29: tmp_y = 32'heaa127fa;
        6'h2a: tmp_y = 32'hd4ef3085;
        6'h2b: tmp_y = 32'h04881d05;
        6'h2c: tmp_y = 32'hd9d4d039;
        6'h2d: tmp_y = 32'he6db99e5;
        6'h2e: tmp_y = 32'h1fa27cf8;
        6'h2f: tmp_y = 32'hc4ac5665;
        6'h30: tmp_y = 32'hf4292244;
        6'h31: tmp_y = 32'h432aff97;
        6'h32: tmp_y = 32'hab9423a7;
        6'h33: tmp_y = 32'hfc93a039;
        6'h34: tmp_y = 32'h655b59c3;
        6'h35: tmp_y = 32'h8f0ccc92;
        6'h36: tmp_y = 32'hffeff47d;
        6'h37: tmp_y = 32'h85845dd1;
        6'h38: tmp_y = 32'h6fa87e4f;
        6'h39: tmp_y = 32'hfe2ce6e0;
        6'h3a: tmp_y = 32'ha3014314;
        6'h3b: tmp_y = 32'h4e0811a1;
        6'h3c: tmp_y = 32'hf7537e82;
        6'h3d: tmp_y = 32'hbd3af235;
        6'h3e: tmp_y = 32'h2ad7d2bb;
        6'h3f: tmp_y = 32'heb86d391;
      endcase // case (x)
    end // k_rom
endmodule // md5_k_rom

//======================================================================
// EOF md5_k_rom.v
//======================================================================
