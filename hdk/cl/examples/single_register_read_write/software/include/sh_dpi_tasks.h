#ifndef SH_DPI_TASKS
#define SH_DPI_TASKS

#include <stdarg.h>
#include <stdio.h>

#include "svdpi.h"

extern void sv_printf(char *msg);
extern void sv_map_host_memory(uint8_t *memory);

extern void cl_peek(uint64_t addr, uint32_t *data);
extern void cl_poke(uint64_t addr, uint32_t  data);
extern void sv_int_ack(uint32_t int_num);
extern void sv_pause(uint32_t x);

void test_main(uint32_t *exit_code);

// Function declarations only - implementations are in sh_dpi_tasks.c
void host_memory_putc(uint64_t addr, uint8_t data);
uint8_t host_memory_getc(uint64_t addr);
void cosim_printf(const char *format, ...);  // Note: this is cosim_printf, not log_printf
void int_handler(uint32_t int_num);

// Add this inline function to handle scope properly
static inline void log_printf(const char *format, ...)
{
  static char sv_msg_buffer[256];
  va_list args;

  va_start(args, format);
  vsprintf(sv_msg_buffer, format, args);

#ifdef VIVADO_SIM
  /* XSIM: ensure a legal scope before any DPI call.  Try the current scope first,
   * fall back to the test-bench top-level ("tb") if current is NULL. */
  svScope cur = svGetScope();
  if (cur == NULL)
      cur = svGetScopeFromName("tb");
  if (cur != NULL)
      svSetScope(cur);
#endif

  sv_printf(sv_msg_buffer);
  va_end(args);
}

#define LOW_32b(a)  ((uint32_t)((uint64_t)(a) & 0xffffffff))
#define HIGH_32b(a) ((uint32_t)(((uint64_t)(a)) >> 32L))

#endif
