// ============================================================================
// Amazon FPGA Hardware Development Kit
//
// Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.
// ============================================================================


// This test initiates dma and pcim traffic in parallel.
`include "common_base_test.svh"

module hardware_test();

   import tb_type_defines_pkg::*;

    localparam logic [63:0] ADDR_COUNTER_REG = 64'h00;
    localparam logic [63:0] ADDR_RESET_VALUE_REG = 64'h04;
    localparam logic [63:0] ADDR_CONTROL_REG = 64'h08;
    localparam logic [31:0] CTRL_ENABLE = 32'h1;
    localparam logic [31:0] CTRL_RESET = 32'h2;
    localparam logic [31:0] CTRL_BOTH = 32'h3;

   initial begin
        logic [31:0] data;
        logic pass = 1;

        logic [31:0] initial_count;
        logic [31:0] disabled_count;
        
        $display("*****Starting hardware_test: %t*****", $time);
        tb.power_up();
        #500ns;
        
        tb.peek_ocl(.addr(ADDR_COUNTER_REG), .data(data));
    
        if (data !== 32'h12345678) begin
            $error("Fail: Initial counter value was 0x%08h, should have been 0x12345678", data);
            pass = 0;
        end
    
        tb.poke_ocl(.addr(ADDR_RESET_VALUE_REG), .data(32'hDEADBEEF));
        #100ns;
        
        tb.peek_ocl(.addr(ADDR_RESET_VALUE_REG), .data(data));

        if (data !== 32'hDEADBEEF) begin
            $error("Fail: Reset value register was 0x%08h, should have been 0xDEADBEEF", data);
            pass = 0;
        end

        tb.poke_ocl(.addr(ADDR_CONTROL_REG), .data(CTRL_RESET));
        #200ns;
        
        tb.peek_ocl(.addr(ADDR_COUNTER_REG), .data(data));

        if (data !== 32'hDEADBEEF) begin
            $error("Fail: Counter value after reset was 0x%08h, should have been 0xDEADBEEF", data);
            pass = 0;
        end
        
        tb.peek_ocl(.addr(ADDR_CONTROL_REG), .data(data));
        if (data !== 32'h0) begin
            $error("Fail: Control register should be 0x0 after reset, but is 0x%08h", data);
            pass = 0;
        end
        

        tb.peek_ocl(.addr(ADDR_COUNTER_REG), .data(data));
        initial_count = data;
        tb.poke_ocl(.addr(ADDR_CONTROL_REG), .data(CTRL_ENABLE));
        #1000ns;
        tb.peek_ocl(.addr(ADDR_COUNTER_REG), .data(data));
        
        if (data <= initial_count) begin
            $error("Fail: Counter did not increment. Initial: 0x%08h, Current: 0x%08h", initial_count, data);
            pass = 0;
        end
        

        tb.poke_ocl(.addr(ADDR_CONTROL_REG), .data(32'h0));
        #100ns;

        tb.peek_ocl(.addr(ADDR_COUNTER_REG), .data(data));
        disabled_count = data;
        #1000ns;
        tb.peek_ocl(.addr(ADDR_COUNTER_REG), .data(data));
        
        if (data !== disabled_count) begin
            $error("Fail: Counter changed while disabled. was: 0x%08h, now: 0x%08h", disabled_count, data);
            pass = 0;
        end
        
        tb.poke_ocl(.addr(ADDR_COUNTER_REG), .data(32'hCAFEBABE));
        #100ns;
        
        tb.peek_ocl(.addr(ADDR_COUNTER_REG), .data(data));
        
        if (data !== 32'hCAFEBABE) begin
            $error("Fail: Direct write to counter failed. wwas: 0x%08h, should have been: 0xCAFEBABE", data);
            pass = 0;
        end
        
        if (pass) begin
            $display("Worked");
        end 

        report_pass_fail_status(pass);
        tb.power_down();
        $finish;
    end // initial begin

endmodule // hardware_test
