//======================================================================
//
// tb_md5_core.v
// --------------
// Testbench for the md5 hash function core.
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

`default_nettype none

module tb_md5_core();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;
  reg          tb_monitor;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_init;
  reg           tb_next;
  wire          tb_ready;
  reg [511 : 0]  tb_block;
  wire [127 : 0] tb_digest;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  md5_core dut(
                .clk(tb_clk),
                .reset_n(tb_reset_n),

                .init(tb_init),
                .next(tb_next),

                .block(tb_block),
                .digest(tb_digest),
                .ready(tb_ready)
               );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;
      #(CLK_PERIOD);
      if (tb_monitor)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("State of DUT");
      $display("------------");
      $display("Cycle: %08d", cycle_ctr);
      $display("Inputs and outputs:");
      $display("init   = 0x%01x, next = 0x%01x", dut.init, dut.next);
      $display("block  = 0x%0128x", dut.block);
      $display("ready  = 0x%01x", dut.ready);
      $display("digest = 0x%032x", dut.digest);
      $display("");
      $display("Internal states:");
      $display("init_state = 0x%01x, update_state = 0x%01x, init_round = 0x%01x, update_round = 0x%01x",
               dut.init_state, dut.update_state, dut.init_round, dut.update_round);
      $display("h0_reg: 0x%08x, h1_reg: 0x%08x, h2_reg: 0x%08x, h3: 0x%08x, h_we: 0x%01x",
               dut.h0_reg, dut.h1_reg, dut.h2_reg, dut.h3_reg, dut.h_we);
      $display("a_reg:  0x%08x, b_reg:  0x%08x, c_reg:  0x%08x, d_reg: 0x%08x",
               dut.a_reg, dut.b_reg, dut.c_reg, dut.d_reg);
      $display("f:      0x%08x, g:      0x%08x, k:      0x%08x, w:     0x%08x",
               dut.md5_dp.f, dut.md5_dp.g, dut.md5_dp.k, dut.md5_dp.w);
      $display("tmp_b0: 0x%08x, lr:     0x%08x, tmp_b2: 0x%08x", dut.md5_dp.tmp_b0, dut.md5_dp.lr, dut.md5_dp.tmp_b2);
      $display("a_new:  0x%08x, b_new:  0x%08x, c_new:  0x%08x, d_new: 0x%08x",
               dut.a_new, dut.b_new, dut.c_new, dut.d_new);
      $display("md5_core_ctrl_reg = 0x%02x, md5_core_ctrl_new = 0x%02x, round_ctr_reg = 0x%03x",
               dut.md5_core_ctrl_reg, dut.md5_core_ctrl_new, dut.round_ctr_reg);
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag in the dut to be set.
  //
  // Note: It is the callers responsibility to call the function
  // when the dut is actively processing and will in fact at some
  // point set the flag.
  //----------------------------------------------------------------
  task wait_ready;
    begin
      while (!tb_ready)
        begin
          #(CLK_PERIOD);
          if (DUMP_WAIT)
            begin
              dump_dut_state();
            end
        end
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr  = 0;
      error_ctr  = 0;
      tc_ctr     = 0;
      tb_monitor = 0;

      tb_clk     = 1'h0;
      tb_reset_n = 1'h1;
      tb_init    = 1'h0;
      tb_next    = 1'h0;
      tb_block   = 512'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // tc1()
  // Single, block input representing the empty string "".
  //----------------------------------------------------------------
  task tc1;
    begin
      $display("*** TC1 - Single empty string input started.");
      tc_ctr = tc_ctr + 1;
      tb_monitor = 0;

      $display("-- Asserting init.");
      tb_init = 1'h1;
      #(2 * CLK_PERIOD);
      tb_init = 1'h0;

      #(2 * CLK_PERIOD);

      $display("-- Asserting next.");
      tb_block = {32'h00000080, 32'h0, 32'h0, 32'h0,
                  32'h0,        32'h0, 32'h0, 32'h0,
                  32'h0,        32'h0, 32'h0, 32'h0,
                  32'h0,        32'h0, 32'h0, 32'h0};
      tb_next = 1'h1;
      #(2 * CLK_PERIOD);
      tb_next = 1'h0;
      wait_ready();
      #(2 * CLK_PERIOD);

      if (tb_digest == 128'hd41d8cd98f00b204e9800998ecf8427e)
        $display("** Correct result for TC1.");
      else
        begin
          $display("** Incorrect result for TC1. Expected 0xd41d8cd98f00b204e9800998ecf8427e, Got 0x%032x", tb_digest);
          error_ctr = error_ctr + 1;
        end
      $display("*** TC1 completed.");
      $display("");

      tb_monitor = 0;
    end
  endtask // tc1


  //----------------------------------------------------------------
  // tc2()
  // Single, block input representing the string: "a".
  //----------------------------------------------------------------
  task tc2;
    begin
      $display("*** TC2 - Single byte string 'a' input started.");
      tc_ctr = tc_ctr + 1;
      tb_monitor = 0;

      $display("-- Asserting init.");
      tb_init = 1'h1;
      #(2 * CLK_PERIOD);
      tb_init = 1'h0;

      #(2 * CLK_PERIOD);

      $display("-- Asserting next.");
      tb_block = {32'h00008061, 32'h0, 32'h0,        32'h0,
                  32'h0,        32'h0, 32'h0,        32'h0,
                  32'h0,        32'h0, 32'h0,        32'h0,
                  32'h0,        32'h0, 32'h00000008, 32'h0};
      tb_next = 1'h1;
      #(2 * CLK_PERIOD);
      tb_next = 1'h0;
      wait_ready();
      #(2 * CLK_PERIOD);

      if (tb_digest == 128'h0cc175b9c0f1b6a831c399e269772661)
        $display("** Correct result for TC2.");
      else
        begin
          $display("** Incorrect result for TC2. Expected 0x0cc175b9c0f1b6a831c399e269772661, Got 0x%032x", tb_digest);
          error_ctr = error_ctr + 1;
        end
      $display("*** TC2 completed.");
      $display("");

      tb_monitor = 0;
    end
  endtask // tc2


  //----------------------------------------------------------------
  // tc3()
  // Single, block input representing the string:
  // "The quick brown fox jumps over the lazy dog".
  //----------------------------------------------------------------
  task tc3;
    begin
      $display("*** TC3 - 'The quick brown fox jumps over the lazy dog' string input started.");
      tc_ctr = tc_ctr + 1;
      tb_monitor = 0;

      $display("-- Asserting init.");
      tb_init = 1'h1;
      #(2 * CLK_PERIOD);
      tb_init = 1'h0;

      #(2 * CLK_PERIOD);

      $display("-- Asserting next.");

      tb_block = {32'h20656854, 32'h63697571, 32'h7262206b, 32'h206e776f,
                  32'h20786f66, 32'h706d756a, 32'h766f2073, 32'h74207265,
                  32'h6c206568, 32'h20797a61, 32'h80676f64, 32'h00000000,
                  32'h00000000, 32'h00000000, 32'h00000158, 32'h00000000};
      tb_next = 1'h1;
      #(2 * CLK_PERIOD);
      tb_next = 1'h0;
      wait_ready();
      #(2 * CLK_PERIOD);

      if (tb_digest == 128'h9e107d9d372bb6826bd81d3542a419d6)
        $display("** Correct result for TC3.");
      else
        begin
          $display("** Incorrect result for TC3. Expected 0x9e107d9d372bb6826bd81d3542a419d6, Got 0x%032x", tb_digest);
          error_ctr = error_ctr + 1;
        end
      $display("*** TC3 completed.");
      $display("");

      tb_monitor = 0;
    end
  endtask // tc3


  //----------------------------------------------------------------
  // tc4()
  // Dual block input representing the string:
  // "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  //----------------------------------------------------------------
  task tc4;
    begin
      $display("*** TC4 - 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' string input started.");
      tc_ctr = tc_ctr + 1;
      tb_monitor = 0;

      $display("-- Asserting init.");
      tb_init = 1'h1;
      #(2 * CLK_PERIOD);
      tb_init = 1'h0;

      #(2 * CLK_PERIOD);

      $display("-- Asserting next for first block.");
      tb_block = {32'h61616161, 32'h61616161, 32'h61616161, 32'h61616161,
                  32'h61616161, 32'h61616161, 32'h61616161, 32'h61616161,
                  32'h61616161, 32'h61616161, 32'h61616161, 32'h61616161,
                  32'h61616161, 32'h61616161, 32'h61616161, 32'h61616161};
      tb_next = 1'h1;
      #(2 * CLK_PERIOD);
      tb_next = 1'h0;
      wait_ready();
      $display("-- Processing of first block completed.");
      #(2 * CLK_PERIOD);


      $display("-- Asserting next for second block.");
      tb_block = {32'h00806161, 32'h00000000, 32'h00000000, 32'h00000000,
                  32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
                  32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
                  32'h00000000, 32'h00000000, 32'h00000210, 32'h00000000};
      tb_next = 1'h1;
      #(2 * CLK_PERIOD);
      tb_next = 1'h0;
      wait_ready();
      $display("-- Processing of second block completed.");
      #(2 * CLK_PERIOD);

      if (tb_digest == 128'hdef5d97e01e1219fb2fc8da6c4d6ba2f)
        $display("** Correct result for TC4.");
      else
        begin
          $display("** Incorrect result for TC4. Expected 0xdef5d97e01e1219fb2fc8da6c4d6ba2f, Got 0x%032x", tb_digest);
          error_ctr = error_ctr + 1;
        end
      $display("*** TC4 completed.");
      $display("");

      tb_monitor = 0;
    end
  endtask // tc4


  //----------------------------------------------------------------
  // md5_core_test
  //
  // Test vectors from:
  //----------------------------------------------------------------
  initial
    begin : md5_core_test
      $display("   -= Testbench for md5 core started =-");
      $display("     =================================");
      $display("");

      init_sim();
      reset_dut();

      tc1();
      tc2();
      tc3();
      tc4();

      display_test_result();
      $display("");
      $display("*** md5 core simulation done. ***");
      $finish;
    end // md5_core_test
endmodule // tb_md5_core

//======================================================================
// EOF tb_md5_core.v
//======================================================================
