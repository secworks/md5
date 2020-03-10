//======================================================================
//
// md5.v
// ------
// Top level wrapper for the MD5 hash function core.
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

module md5(
           input wire           clk,
           input wire           reset_n,

           input wire           cs,
           input wire           we,

           input wire  [7 : 0]  address,
           input wire  [31 : 0] write_data,
           output wire [31 : 0] read_data
          );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_NAME0       = 8'h00;
  localparam ADDR_NAME1       = 8'h01;
  localparam ADDR_VERSION     = 8'h02;

  localparam ADDR_CTRL        = 8'h08;
  localparam CTRL_INIT_BIT    = 0;
  localparam CTRL_NEXT_BIT    = 1;

  localparam ADDR_STATUS      = 8'h09;
  localparam STATUS_READY_BIT = 0;

  localparam ADDR_BLOCK0      = 8'h20;
  localparam ADDR_BLOCK15     = 8'h2f;

  localparam ADDR_DIGEST0     = 8'h40;
  localparam ADDR_DIGEST3     = 8'h43;

  localparam CORE_NAME0       = 32'h6d643520; // "md5 "
  localparam CORE_NAME1       = 32'h68617368; // "hash"
  localparam CORE_VERSION     = 32'h302e3130; // "0.10"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg          init_reg;
  reg          init_new;

  reg          next_reg;
  reg          next_new;

  reg [31 : 0] block_reg [0 : 15];
  reg          block_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]   tmp_read_data;

  wire           core_ready;
  wire [511 : 0] core_block;
  wire [127 : 0] core_digest;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data   = tmp_read_data;

  assign core_block  = {block_reg[0], block_reg[1], block_reg[2], block_reg[3],
                        block_reg[4], block_reg[5], block_reg[6], block_reg[7],
                        block_reg[8], block_reg[9], block_reg[10], block_reg[11],
                        block_reg[12], block_reg[13], block_reg[14], block_reg[15]};


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  md5_core core(
                 .clk(clk),
                 .reset_n(reset_n),

                 .init(init_reg),
                 .next(next_reg),
                 .ready(core_ready),

                 .block(core_block),
                 .digest(core_digest)
                );


  //----------------------------------------------------------------
  // reg_update
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < 16 ; i = i + 1)
            block_reg[i] <= 32'h0;

          init_reg   <= 1'h0;
          next_reg   <= 1'h0;
        end
      else
        begin
          init_reg <= init_new;
          next_reg <= next_new;

          if (block_we)
            block_reg[address[3 : 0]] <= write_data;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      init_new      = 1'h0;
      next_new      = 1'h0;
      block_we      = 1'h0;
      tmp_read_data = 32'h0;

      if (cs)
        begin
          if (we)
            begin
              if (core_ready)
                begin
                  if (address == ADDR_CTRL)
                    begin
                      init_new = write_data[CTRL_INIT_BIT];
                      next_new = write_data[CTRL_NEXT_BIT];
                    end

                  if ((address >= ADDR_BLOCK0) && (address <= ADDR_BLOCK15))
                    block_we = 1'h1;
                end
            end
          else
            begin
              case (address)
                ADDR_NAME0:   tmp_read_data = CORE_NAME0;
                ADDR_NAME1:   tmp_read_data = CORE_NAME1;
                ADDR_VERSION: tmp_read_data = CORE_VERSION;
                ADDR_STATUS:  tmp_read_data = {31'h0, core_ready};

                default:
                  begin
                  end
              endcase // case (address)

              if ((address >= ADDR_DIGEST0) && (address <= ADDR_DIGEST3))
                tmp_read_data = core_digest[(3 - (address - ADDR_DIGEST0)) * 32 +: 32];
            end
        end
    end // addr_decoder
endmodule // md5

//======================================================================
// EOF md5.v
//======================================================================
