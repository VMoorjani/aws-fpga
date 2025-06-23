// test_simple_register.c
// Place this in $CL_DIR/software/runtime/
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>

// Include the test APIs
#include "sh_dpi_tasks.h"

// Register addresses
#define ADDR_COUNTER_REG      0x00
#define ADDR_RESET_VALUE_REG  0x04
#define ADDR_CONTROL_REG      0x08

// Control register bits
#define CTRL_ENABLE_BIT       0x01
#define CTRL_RESET_BIT        0x02

void test_main() {
    uint32_t read_data;
    bool test_passed = true;
    
    log_printf("=== Starting C Co-simulation Test ===\n");
    
    // Test 1: Read initial counter value
    log_printf("\nTest 1: Reading initial counter value...\n");
    cl_peek(ADDR_COUNTER_REG, &read_data);
    log_printf("Counter value: 0x%08x\n", read_data);
    
    if (read_data != 0x12345678) {
        log_printf("ERROR: Expected 0x12345678, got 0x%08x\n", read_data);
        test_passed = false;
    } else {
        log_printf("PASS: Initial counter value correct\n");
    }
    
    // Test 2: Write reset value register
    log_printf("\nTest 2: Writing reset value register...\n");
    cl_poke(ADDR_RESET_VALUE_REG, 0xDEADBEEF);
    sv_pause(100); // 100us pause
    
    cl_peek(ADDR_COUNTER_REG, &read_data);
    if (read_data != 0xDEADBEEF) {
        log_printf("ERROR: Reset value register write failed\n");
        test_passed = false;
    } else {
        log_printf("PASS: Reset value register = 0x%08x\n", read_data);
    }
    
    // Test 3: Software reset
    log_printf("\nTest 3: Applying software reset...\n");
    cl_poke(ADDR_CONTROL_REG, CTRL_RESET_BIT);
    sv_pause(200);
    
    cl_peek(ADDR_COUNTER_REG, &read_data);
    if (read_data != 0xDEADBEEF) {
        log_printf("ERROR: Counter didn't reset to 0xDEADBEEF\n");
        test_passed = false;
    } else {
        log_printf("PASS: Counter reset to 0x%08x\n", read_data);
    }
    
    // Test 4: Enable counter
    log_printf("\nTest 4: Enabling counter...\n");
    uint32_t initial_count;
    uint32_t new_count;
    cl_peek(ADDR_COUNTER_REG, &initial_count);
    
    cl_poke(ADDR_CONTROL_REG, CTRL_ENABLE_BIT);
    sv_pause(1000); // Wait 1ms
    
    cl_peek(ADDR_COUNTER_REG, &new_count);
    log_printf("Counter: 0x%08x -> 0x%08x\n", initial_count, new_count);
    
    if (new_count <= initial_count) {
        log_printf("ERROR: Counter didn't increment\n");
        test_passed = false;
    } else {
        log_printf("PASS: Counter incremented by %d\n", new_count - initial_count);
    }
    
    // Test 5: Disable counter
    log_printf("\nTest 5: Disabling counter...\n");
    cl_poke(ADDR_CONTROL_REG, 0x00);
    sv_pause(100);

    uint32_t stopped_count;
    uint32_t final_count;

    cl_peek(ADDR_COUNTER_REG, &stopped_count);
    sv_pause(500);
    cl_peek(ADDR_COUNTER_REG, &final_count);
    
    if (stopped_count != final_count) {
        log_printf("ERROR: Counter still incrementing after disable\n");
        test_passed = false;
    } else {
        log_printf("PASS: Counter stopped at 0x%08x\n", stopped_count);
    }
    
    // Final result
    log_printf("\n=== Test %s ===\n", test_passed ? "PASSED" : "FAILED");