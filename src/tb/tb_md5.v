//======================================================================
//
// tb_md5.v
// --------
// Testbench for the md5 top level wrapper
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

module tb_md5();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

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


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;
  reg          tb_monitor;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_we;
  reg [7 : 0]   tb_address;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;

  reg [31 : 0] read_data;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  md5 dut(
           .clk(tb_clk),
           .reset_n(tb_reset_n),

           .cs(tb_cs),
           .we(tb_we),

           .address(tb_address),
           .write_data(tb_write_data),
           .read_data(tb_read_data)
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
      $display("");
      $display("Core inputs and outputs:");
      $display("inputt: 0x%01x, next: 0x%01x, ready: 0x%01x",
               dut.core.init, dut.core.next, dut.core.ready);
      $display("block:  0x%064x", dut.core.block);
      $display("digest: 0x%016x", dut.core.digest);
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

      tb_clk        = 1'h0;
      tb_reset_n    = 1'h1;
      tb_cs         = 1'h0;
      tb_we         = 1'h0;
      tb_address    = 8'h0;
      tb_write_data = 32'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [11 : 0] address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("*** Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      tb_address = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(2 * CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [11 : 0]  address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;

      if (DEBUG)
        begin
          $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag to be set in dut.
  //----------------------------------------------------------------
  task wait_ready;
    begin : wready
      read_word(ADDR_STATUS);
      while (read_data == 0)
        read_word(ADDR_STATUS);
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // tc1()
  // Empty string "" test case.
  //----------------------------------------------------------------
  task tc1;
    begin : tc1
      reg [127 : 0] digest;

      tc_ctr = tc_ctr + 1;

      tb_monitor = 0;

      $display("");
      $display("*** TC1 - Empty string '' test case started.");

      // Perform init.
      $display("*** TC1 - starting init.");
      write_word(ADDR_CTRL, 32'h1);
      wait_ready();
      $display("*** TC1 - Init completed.");


      $display("*** TC1 - Writing block and performing hash.");
      write_word(ADDR_BLOCK0 + 0,  32'h00000080);
      write_word(ADDR_BLOCK0 + 1,  32'h0);
      write_word(ADDR_BLOCK0 + 2,  32'h0);
      write_word(ADDR_BLOCK0 + 3,  32'h0);
      write_word(ADDR_BLOCK0 + 4,  32'h0);
      write_word(ADDR_BLOCK0 + 5,  32'h0);
      write_word(ADDR_BLOCK0 + 6,  32'h0);
      write_word(ADDR_BLOCK0 + 7,  32'h0);
      write_word(ADDR_BLOCK0 + 8,  32'h0);
      write_word(ADDR_BLOCK0 + 9,  32'h0);
      write_word(ADDR_BLOCK0 + 10, 32'h0);
      write_word(ADDR_BLOCK0 + 11, 32'h0);
      write_word(ADDR_BLOCK0 + 12, 32'h0);
      write_word(ADDR_BLOCK0 + 13, 32'h0);
      write_word(ADDR_BLOCK0 + 14, 32'h0);
      write_word(ADDR_BLOCK0 + 15, 32'h0);

      write_word(ADDR_CTRL, 32'h2);
      wait_ready();
      $display("*** TC1 - Hash completed.");

      // Reading out the result.
      read_word(ADDR_DIGEST0 + 0);
      digest[127 : 96] = read_data;
      read_word(ADDR_DIGEST0 + 1);
      digest[95 : 64] = read_data;
      read_word(ADDR_DIGEST0 + 2);
      digest[63 : 32] = read_data;
      read_word(ADDR_DIGEST0 + 3);
      digest[31 : 0] = read_data;

      tb_monitor = 0;

      if (digest == 128'hd41d8cd98f00b204e9800998ecf8427e)
        begin
          $display("*** TC1 - Correct digest received.");
        end
      else
        begin
          $display("*** TC1 - Incorrect digest received. Expected 0x128'hd41d8cd98f00b204e9800998ecf8427e, got 0x%016x", digest);
          error_ctr = error_ctr + 1;
        end
      $display("");
    end
  endtask // tc1


  //----------------------------------------------------------------
  // tc2()
  // Single char "a" testcase.
  //----------------------------------------------------------------
  task tc2;
    begin : tc2
      reg [127 : 0] digest;

      tc_ctr = tc_ctr + 1;

      tb_monitor = 0;

      $display("");
      $display("*** TC2 - Single char 'a' string test case started.");

      // Perform init.
      $display("*** TC2 - Starting init.");
      write_word(ADDR_CTRL, 32'h1);
      wait_ready();
      $display("*** TC2 - Init completed.");


      $display("*** TC2 - Writing block and performing hash.");
      write_word(ADDR_BLOCK0 + 0,  32'h00008061);
      write_word(ADDR_BLOCK0 + 1,  32'h0);
      write_word(ADDR_BLOCK0 + 2,  32'h0);
      write_word(ADDR_BLOCK0 + 3,  32'h0);
      write_word(ADDR_BLOCK0 + 4,  32'h0);
      write_word(ADDR_BLOCK0 + 5,  32'h0);
      write_word(ADDR_BLOCK0 + 6,  32'h0);
      write_word(ADDR_BLOCK0 + 7,  32'h0);
      write_word(ADDR_BLOCK0 + 8,  32'h0);
      write_word(ADDR_BLOCK0 + 9,  32'h0);
      write_word(ADDR_BLOCK0 + 10, 32'h0);
      write_word(ADDR_BLOCK0 + 11, 32'h0);
      write_word(ADDR_BLOCK0 + 12, 32'h0);
      write_word(ADDR_BLOCK0 + 13, 32'h0);
      write_word(ADDR_BLOCK0 + 14, 32'h00000008);
      write_word(ADDR_BLOCK0 + 15, 32'h0);

      write_word(ADDR_CTRL, 32'h2);
      wait_ready();
      $display("*** TC2 - Hash completed.");

      // Reading out the result.
      read_word(ADDR_DIGEST0 + 0);
      digest[127 : 96] = read_data;
      read_word(ADDR_DIGEST0 + 1);
      digest[95 : 64] = read_data;
      read_word(ADDR_DIGEST0 + 2);
      digest[63 : 32] = read_data;
      read_word(ADDR_DIGEST0 + 3);
      digest[31 : 0] = read_data;

      tb_monitor = 0;

      if (digest == 128'h0cc175b9c0f1b6a831c399e269772661)
        begin
          $display("*** TC2 - Correct digest received.");
        end
      else
        begin
          $display("*** TC2 - Incorrect digest received. Expected 0x128'h0cc175b9c0f1b6a831c399e269772661, got 0x%016x", digest);
          error_ctr = error_ctr + 1;
        end
      $display("");
    end
  endtask // tc2


  //----------------------------------------------------------------
  // tc3()
  // "The quick brown fox jumps over the lazy dog" testcase.
  //----------------------------------------------------------------
  task tc3;
    begin : tc3
      reg [127 : 0] digest;

      tc_ctr = tc_ctr + 1;

      tb_monitor = 0;

      $display("");
      $display("*** TC3 - 'The quick brown fox jumps over the lazy dog' string test case.");

      // Perform init.
      $display("*** TC3 - Starting init.");
      write_word(ADDR_CTRL, 32'h1);
      wait_ready();
      $display("*** TC3 - Init completed.");


      $display("*** TC3 - Writing block and performing hash.");
      write_word(ADDR_BLOCK0 + 0,  32'h20656854);
      write_word(ADDR_BLOCK0 + 1,  32'h63697571);
      write_word(ADDR_BLOCK0 + 2,  32'h7262206b);
      write_word(ADDR_BLOCK0 + 3,  32'h206e776f);
      write_word(ADDR_BLOCK0 + 4,  32'h20786f66);
      write_word(ADDR_BLOCK0 + 5,  32'h706d756a);
      write_word(ADDR_BLOCK0 + 6,  32'h766f2073);
      write_word(ADDR_BLOCK0 + 7,  32'h74207265);
      write_word(ADDR_BLOCK0 + 8,  32'h6c206568);
      write_word(ADDR_BLOCK0 + 9,  32'h20797a61);
      write_word(ADDR_BLOCK0 + 10, 32'h80676f64);
      write_word(ADDR_BLOCK0 + 11, 32'h0);
      write_word(ADDR_BLOCK0 + 12, 32'h0);
      write_word(ADDR_BLOCK0 + 13, 32'h0);
      write_word(ADDR_BLOCK0 + 14, 32'h00000158);
      write_word(ADDR_BLOCK0 + 15, 32'h0);

      write_word(ADDR_CTRL, 32'h2);
      wait_ready();
      $display("*** TC3 - Hash completed.");

      // Reading out the result.
      read_word(ADDR_DIGEST0 + 0);
      digest[127 : 96] = read_data;
      read_word(ADDR_DIGEST0 + 1);
      digest[95 : 64] = read_data;
      read_word(ADDR_DIGEST0 + 2);
      digest[63 : 32] = read_data;
      read_word(ADDR_DIGEST0 + 3);
      digest[31 : 0] = read_data;

      tb_monitor = 0;

      if (digest == 128'h9e107d9d372bb6826bd81d3542a419d6)
        begin
          $display("*** TC3 - Correct digest received.");
        end
      else
        begin
          $display("*** TC3 - Incorrect digest received. Expected 0x128'h9e107d9d372bb6826bd81d3542a419d6, got 0x%016x", digest);
          error_ctr = error_ctr + 1;
        end
      $display("");
    end
  endtask // tc3


  //----------------------------------------------------------------
  // tc4()
  // Dual block input representing the string:
  // "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  //----------------------------------------------------------------
  task tc4;
    begin : tc4
      reg [127 : 0] digest;

      tc_ctr = tc_ctr + 1;

      tb_monitor = 0;

      $display("");
      $display("*** TC4 - 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' string spanning two blocks test case.");

      // Perform init.
      $display("*** TC4 - Starting init.");
      write_word(ADDR_CTRL, 32'h1);
      wait_ready();
      $display("*** TC4 - Init completed.");


      $display("*** TC4 - Writing first block and performing hash.");
      write_word(ADDR_BLOCK0 + 0,  32'h61616161);
      write_word(ADDR_BLOCK0 + 1,  32'h61616161);
      write_word(ADDR_BLOCK0 + 2,  32'h61616161);
      write_word(ADDR_BLOCK0 + 3,  32'h61616161);
      write_word(ADDR_BLOCK0 + 4,  32'h61616161);
      write_word(ADDR_BLOCK0 + 5,  32'h61616161);
      write_word(ADDR_BLOCK0 + 6,  32'h61616161);
      write_word(ADDR_BLOCK0 + 7,  32'h61616161);
      write_word(ADDR_BLOCK0 + 8,  32'h61616161);
      write_word(ADDR_BLOCK0 + 9,  32'h61616161);
      write_word(ADDR_BLOCK0 + 10, 32'h61616161);
      write_word(ADDR_BLOCK0 + 11, 32'h61616161);
      write_word(ADDR_BLOCK0 + 12, 32'h61616161);
      write_word(ADDR_BLOCK0 + 13, 32'h61616161);
      write_word(ADDR_BLOCK0 + 14, 32'h61616161);
      write_word(ADDR_BLOCK0 + 15, 32'h61616161);

      write_word(ADDR_CTRL, 32'h2);
      wait_ready();
      $display("*** TC4 - First hash completed.");


      $display("*** TC4 - Writing second block and performing hash.");
      write_word(ADDR_BLOCK0 + 0,  32'h00806161);
      write_word(ADDR_BLOCK0 + 1,  32'h00000000);
      write_word(ADDR_BLOCK0 + 2,  32'h00000000);
      write_word(ADDR_BLOCK0 + 3,  32'h00000000);
      write_word(ADDR_BLOCK0 + 4,  32'h00000000);
      write_word(ADDR_BLOCK0 + 5,  32'h00000000);
      write_word(ADDR_BLOCK0 + 6,  32'h00000000);
      write_word(ADDR_BLOCK0 + 7,  32'h00000000);
      write_word(ADDR_BLOCK0 + 8,  32'h00000000);
      write_word(ADDR_BLOCK0 + 9,  32'h00000000);
      write_word(ADDR_BLOCK0 + 10, 32'h00000000);
      write_word(ADDR_BLOCK0 + 11, 32'h00000000);
      write_word(ADDR_BLOCK0 + 12, 32'h00000000);
      write_word(ADDR_BLOCK0 + 13, 32'h00000000);
      write_word(ADDR_BLOCK0 + 14, 32'h00000210);
      write_word(ADDR_BLOCK0 + 15, 32'h00000000);

      write_word(ADDR_CTRL, 32'h2);
      wait_ready();
      $display("*** TC4 - Second hash completed.");

      // Reading out the result.
      read_word(ADDR_DIGEST0 + 0);
      digest[127 : 96] = read_data;
      read_word(ADDR_DIGEST0 + 1);
      digest[95 : 64] = read_data;
      read_word(ADDR_DIGEST0 + 2);
      digest[63 : 32] = read_data;
      read_word(ADDR_DIGEST0 + 3);
      digest[31 : 0] = read_data;

      tb_monitor = 0;

      if (digest == 128'hdef5d97e01e1219fb2fc8da6c4d6ba2f)
        begin
          $display("*** TC4 - Correct digest received.");
        end
      else
        begin
          $display("*** TC4 - Incorrect digest received. Expected 0x128'hdef5d97e01e1219fb2fc8da6c4d6ba2f, got 0x%016x", digest);
          error_ctr = error_ctr + 1;
        end
      $display("");
    end
  endtask // tc4


  //----------------------------------------------------------------
  // md5_test
  //----------------------------------------------------------------
  initial
    begin : md5_test
      $display("   -= Testbench for md5 started =-");
      $display("     ============================");
      $display("");

      init_sim();
      reset_dut();

      tc1();
      tc2();
      tc3();
      tc4();

      display_test_result();
      $display("");
      $display("*** md5 simulation done. ***");
      $finish;
    end // md5_test
endmodule // tb_md5

//======================================================================
// EOF tb_md5.v
//======================================================================
