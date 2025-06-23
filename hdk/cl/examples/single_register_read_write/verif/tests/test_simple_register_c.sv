`include "common_base_test.svh"

module test_simple_register_c;
    import tb_type_defines_pkg::*;
    import "DPI-C" context function void test_main(output int exit_code);

    initial begin
        int ec;
        tb.power_up();
        test_main(ec);
        tb.power_down();
        $display("C-test exit code = %0d", ec);
        $finish;
    end
endmodule
