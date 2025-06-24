#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Vivado does not support svGetScopeFromName
#ifndef VIVADO_SIM
#include "svdpi.h"
#endif

#include "sh_dpi_tasks.h"

XDMA_DESC *h2c_desc_list_head;

// Register addresses
#define ADDR_COUNTER_REG      0x00
#define ADDR_RESET_VALUE_REG  0x04
#define ADDR_CONTROL_REG      0x08

// Control register bits
#define CONTROL_ENABLE_BIT    0
#define CONTROL_RESET_BIT     1

void test_main(uint32_t *exit_code) {
#ifndef VIVADO_SIM
  svScope scope;
#endif

  uint64_t cycle_count;
  uint64_t error_addr;

  uint8_t error_index;

  int timeout_count;

  int error_count;
  int fail;

  XDMA_DESC *h2c_desc;

  error_count = 0;
  fail = 0;

  // Vivado does not support svGetScopeFromName
#ifndef VIVADO_SIM
  scope = svGetScopeFromName("tb");
  svSetScope(scope);
#endif

  sv_pause(50);

  log_printf("=== HW/SW co-simulation test ===\n");

  if (error_count > 0) {
    fail = 1;
  }

  log_printf("Detected %3d errors during this test\n", error_count);

  if (fail != 0) {
    log_printf("*** TEST FAILED ***\n");
  } else {
    log_printf("*** TEST PASSED ***\n");
  }

  *exit_code = 0;
}