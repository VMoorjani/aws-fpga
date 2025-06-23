// test_simple_register_c.sv
// Place this in $CL_DIR/verif/tests/
`include "common_base_test.svh"

module test_simple_register_c();
    import tb_type_defines_pkg::*;
    
    // Import C function
    import "DPI-C" function void test_main();
    
    initial begin
        // Power up the testbench
        tb.power_up();
        
        // Wait for system to stabilize
        #500ns;
        
        // Call C test function
        test_main();
        
        // Allow some time for any pending operations
        #1000ns;
        
        // Power down
        tb.power_down();
        
        $finish;
    end
endmodule