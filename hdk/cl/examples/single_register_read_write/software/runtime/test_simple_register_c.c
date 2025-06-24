#ifdef SV_TEST
#include "fpga_pci_sv.h"
#else
#include <fpga_mgmt.h>
#include <fpga_pci.h>
#endif

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <unistd.h>

// Include the local test APIs
#include "sh_dpi_tasks.h"

// Register addresses
#define ADDR_COUNTER_REG      0x00
#define ADDR_RESET_VALUE_REG  0x04
#define ADDR_CONTROL_REG      0x08

// Control register bits
#define CONTROL_ENABLE_BIT    0
#define CONTROL_RESET_BIT     1

void test_main(uint32_t *exit_code) {
    uint32_t rdata;
    
    log_printf("Starting Simple Register Test\n");
    
    // Test 1: Read initial counter value
    log_printf("Test 1: Reading initial counter value...\n");
    cl_peek(ADDR_COUNTER_REG, &rdata);
    log_printf("Initial counter value: 0x%08x\n", rdata);
    
    // Test 2: Read reset value register
    log_printf("Test 2: Reading reset value register...\n");
    cl_peek(ADDR_RESET_VALUE_REG, &rdata);
    log_printf("Reset value: 0x%08x\n", rdata);
    
    // Test 3: Write a new reset value
    log_printf("Test 3: Writing new reset value (0x12345678)...\n");
    cl_poke(ADDR_RESET_VALUE_REG, 0x12345678);
    cl_peek(ADDR_RESET_VALUE_REG, &rdata);
    log_printf("New reset value: 0x%08x\n", rdata);
    
    // Test 4: Test reset functionality
    log_printf("Test 4: Testing reset functionality...\n");
    cl_poke(ADDR_CONTROL_REG, (1 << CONTROL_RESET_BIT));  // Assert reset
    cl_peek(ADDR_COUNTER_REG, &rdata);
    log_printf("Counter after reset: 0x%08x\n", rdata);
    
    // Test 5: Enable counter and check if it increments
    log_printf("Test 5: Enabling counter...\n");
    cl_poke(ADDR_CONTROL_REG, (1 << CONTROL_ENABLE_BIT));  // Enable counter
    
    // Wait a few cycles and read counter multiple times
    for (int i = 0; i < 5; i++) {
        sv_pause(10);  // Wait 10 cycles
        cl_peek(ADDR_COUNTER_REG, &rdata);
        log_printf("Counter value (iteration %d): 0x%08x\n", i, rdata);
    }
    
    // Test 6: Disable counter
    log_printf("Test 6: Disabling counter...\n");
    cl_poke(ADDR_CONTROL_REG, 0x00);  // Disable counter
    cl_peek(ADDR_COUNTER_REG, &rdata);
    uint32_t stopped_value = rdata;
    log_printf("Counter value when stopped: 0x%08x\n", stopped_value);
    
    // Wait and verify counter doesn't increment when disabled
    sv_pause(20);
    cl_peek(ADDR_COUNTER_REG, &rdata);
    log_printf("Counter value after wait (should be same): 0x%08x\n", rdata);
    
    if (rdata == stopped_value) {
        log_printf("PASS: Counter correctly stopped when disabled\n");
    } else {
        log_printf("FAIL: Counter continued counting when disabled\n");
        *exit_code = 1;
        return;
    }
    
    log_printf("Simple Register Test completed successfully!\n");
    *exit_code = 0;
}