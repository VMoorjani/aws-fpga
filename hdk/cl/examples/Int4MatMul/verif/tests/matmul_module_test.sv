`timescale 1ns/1ps

`include "common_base_test.svh"

module matmul_module_test();

   import tb_type_defines_pkg::*;

   localparam logic [15:0] ADDR_CTL     = 16'h0000;       // Control / status register
   localparam logic [15:0] ADDR_A_BASE  = 16'h0004;       // Matrix A starts at 0x04
   localparam logic [15:0] ADDR_B_BASE  = 16'h0104;       // Matrix B starts at 0x104
   localparam logic [15:0] ADDR_C_BASE  = 16'h0204;       // Matrix C starts at 0x204

   localparam int M = 8;
   localparam int N = 8;
   localparam int K = 8;

   logic       pass;
   logic [31:0] data;


   function automatic logic [15:0] calc_addr(input logic [15:0] base,
                                            input int            idx);
      calc_addr = base + (idx << 2); // Words
   endfunction


   initial begin : test_body
      int r, c;
      int timeout;
      pass = 1;
      $display("*****Starting matmul_module_test: %t*****", $time);

      tb.power_up();
      #500ns;

      for (r = 0; r < M; r++) begin
         for (c = 0; c < K; c++) begin
            tb.poke_ocl(.addr(calc_addr(ADDR_A_BASE, r*K + c)),
                        .data({24'h0, r[7:0]}));
         end
      end

      for (r = 0; r < K; r++) begin
         for (c = 0; c < N; c++) begin
            tb.poke_ocl(.addr(calc_addr(ADDR_B_BASE, r*N + c)),
                        .data({24'h0, c[7:0]}));
         end
      end

      tb.poke_ocl(.addr(ADDR_CTL), .data(32'h0000_0001));

      timeout = 0;

      do begin
         #100ns;
         tb.peek_ocl(.addr(ADDR_CTL), .data(data));
         timeout++;
         if (timeout > 1000) begin
            $error("Timeout waiting for matmul to assert busy");
            pass = 0;
            break;
         end
      end while (data[2] !== 1'b1);

      timeout = 0;
      do begin
         #100ns;
         tb.peek_ocl(.addr(ADDR_CTL), .data(data));
         timeout++;
         if (timeout > 5000) begin
            $error("Timeout waiting for matmul to finish");
            pass = 0;
            break;
         end
      end while (data[2] !== 1'b0);

      for (r = 0; r < M; r++) begin
         for (c = 0; c < N; c++) begin
            logic [15:0] exp_val = r * c * K;
            tb.peek_ocl(.addr(calc_addr(ADDR_C_BASE, r*N + c)), .data(data));
            if (data[15:0] !== exp_val) begin
               $error("Mismatch at C[%0d][%0d] : got 0x%0h, expected 0x%0h", r, c, data[15:0], exp_val);
               pass = 0;
            end
         end
      end

      report_pass_fail_status(pass);
      tb.power_down();
      $finish;
   end // initial begin

endmodule // matmul_module_test 