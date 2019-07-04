//======================================================================
//
// md5_core.v
// ----------
// The MD5 hash funxtion core.
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

module md5_core(
                input wire            clk,
                input wire            reset_n,

                input wire            next,
                output wire           ready,

                input wire [511 : 0]  block,
                output wire [127 : 0] digest
               );




  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam A0 = 32'h67452301;
  localparam B0 = 32'hefcdab89;
  localparam C0 = 32'h98badcfe;
  localparam D0 = 32'h10325476;

  localparam CTRL_IDLE = 2'h0;
  localparam CTRL_INIT = 2'h1;
  localparam CTRL_NEXT = 2'h2;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0] a_reg;
  reg [31 : 0] a_new;
  reg [31 : 0] b_reg;
  reg [31 : 0] b_new;
  reg [31 : 0] c_reg;
  reg [31 : 0] c_new;
  reg [31 : 0] d_reg;
  reg [31 : 0] d_new;
  reg          a_d_we;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [5 : 0]  round_ctr_reg;
  reg [5 : 0]  round_ctr_new;
  reg          round_ctr_inc;
  reg          round_ctr_rst;
  reg          round_ctr_we;

  reg [1 : 0]  md5_core_ctrl_reg;
  reg [1 : 0]  md5_core_ctrl_new;
  reg          md5_core_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire [31 : 0] k;
  reg           dp_init;
  reg           dp_update;


  //----------------------------------------------------------------
  // Function declarations.
  //----------------------------------------------------------------


  //----------------------------------------------------------------
  // Instantiations.
  //----------------------------------------------------------------
  md5_k_rom k_rom(.x(), .y(k));


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready = ready_reg;


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      if (!reset_n)
        begin
          a_reg             <= 32'h0;
          b_reg             <= 32'h0;
          c_reg             <= 32'h0;
          d_reg             <= 32'h0;
          ready_reg         <= 1'h1;
          round_ctr_reg     <= 6'h0;
          md5_core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (ready_we)
            ready_reg <= ready_new;

          if (a_d_we)
            begin
              a_reg <= a_new;
              b_reg <= b_new;
              c_reg <= c_new;
            end

          if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

          if (md5_core_ctrl_we)
            md5_core_ctrl_reg <= md5_core_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // md5_datapath
  //----------------------------------------------------------------
  always @*
    begin : md5_datapath
      reg [31 : 0] F;
      reg [31 : 0] G;
      reg [31 : 0] H;
      reg [31 : 0] I;

      a_new  = 32'h0;
      b_new  = 32'h0;
      c_new  = 32'h0;
      d_new  = 32'h0;
      a_d_we = 1'h0;


      F = (b_reg & c_reg) | (~b_reg & d_reg);
      G = (b_reg & d_reg) | (c_reg & ~d_reg);
      H = b_reg ^ c_reg ^ d_reg;
      I = c_reg ^ (b_reg | ~d_reg);


      if (dp_init)
        begin
          a_reg = A0;
          b_reg = B0;
          c_reg = C0;
          d_reg = D0;
        end

      if (dp_update)
        begin
        end
    end


  //----------------------------------------------------------------
  // round_ctr
  //----------------------------------------------------------------
  always @*
    begin : round_ctr
      round_ctr_new = 6'h0;
      round_ctr_we  = 1'h0;

      if (round_ctr_rst)
        begin
          round_ctr_new = 6'h0;
          round_ctr_we  = 1'h1;
        end

      if (round_ctr_inc)
        begin
          round_ctr_new = round_ctr_reg + 1'h1;
          round_ctr_we  = 1'h1;
        end
    end


  //----------------------------------------------------------------
  // md5_core_ctrl
  //----------------------------------------------------------------
  always @*
    begin : md5_core_ctrl
      ready_new         = 1'h0;
      ready_we          = 1'h0;
      round_ctr_inc     = 1'h0;
      round_ctr_rst     = 1'h0;
      dp_init           = 1'h0;
      dp_update         = 1'h0;
      md5_core_ctrl_new = CTRL_IDLE;
      md5_core_ctrl_we  = 1'h0;

      case (md5_core_ctrl_reg)
        CTRL_IDLE:
          begin
          end

        default:
          begin

          end
      endcase // case (md5_core_ctrl_reg)

    end // md5_core_ctrl
endmodule // md5_core

//======================================================================
// EOF md5_core.v
//======================================================================
