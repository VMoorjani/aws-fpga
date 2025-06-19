// hardware_test.sv

// This include provides the report_pass_fail_status task and other common test utilities.
`include "common_base_test.svh"

module hardware_test(input logic clk, SH_if sh_if);

    // Constants for register addresses
    localparam logic [63:0] ADDR_COUNTER_REG      = 64'h00;
    localparam logic [63:0] ADDR_RESET_VALUE_REG  = 64'h04;
    localparam logic [63:0] ADDR_CONTROL_REG      = 64'h08;

    // Constants for control register values
    localparam logic [31:0] CTRL_ENABLE = 32'h1;
    localparam logic [31:0] CTRL_RESET  = 32'h2;

    initial begin
        automatic logic [31:0] data;
        automatic logic pass = 1;

        $display("Starting test: hardware_test");

        // Test 1: Read the initial counter value, which should be the default from instantiation
        sh_if.ocl_rd(ADDR_COUNTER_REG, data);
        if (data !== 32'h12345678) begin
            $error("FAIL: Initial counter value was %h, expected 12345678", data);
            pass = 0;
        end else begin
            $display("PASS: Initial counter value is correct.");
        end

        // Test 2: Write and read the reset_value_reg
        sh_if.ocl_wr(ADDR_RESET_VALUE_REG, 32'hDEADBEEF);
        sh_if.ocl_rd(ADDR_RESET_VALUE_REG, data);
        if (data !== 32'hDEADBEEF) begin
            $error("FAIL: Reset value reg was %h, expected DEADBEEF", data);
            pass = 0;
        end else begin
             $display("PASS: Reset value register write/read successful.");
        end

        // Test 3: Apply software reset
        sh_if.ocl_wr(ADDR_CONTROL_REG, CTRL_RESET);
        // Give it a clock cycle to take effect
        #10ns;
        sh_if.ocl_rd(ADDR_COUNTER_REG, data);
         if (data !== 32'hDEADBEEF) begin
            $error("FAIL: Counter value after reset was %h, expected DEADBEEF", data);
            pass = 0;
        end else begin
             $display("PASS: Software reset works as expected.");
        end

        report_pass_fail_status(pass);
    end
endmodule