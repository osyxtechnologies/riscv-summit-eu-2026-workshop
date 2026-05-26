#ifndef PLAT_H
#define PLAT_H

#ifndef PLAT_MEM_BASE
#define PLAT_MEM_BASE 0x88200000
#endif
#define PLAT_MEM_SIZE 0x01000000

#define PLAT_TIMER_FREQ (25000000ull) /* 25 MHz */

/* Defaults: UART1 at 0x10002000, APLIC source 8 (milestone 02 baremetal).
 * Override via -DPLAT_UART_ADDR/-DUART_IRQ_ID for milestone 00 UART0 use. */
#ifndef PLAT_UART_ADDR
#define PLAT_UART_ADDR (0x10002000)
#endif
#ifndef UART_IRQ_ID
#define UART_IRQ_ID    (8)
#endif

#define PLAT_APLIC_CTL_BASE_ADDR  (0xd000000)
#define PLAT_APLIC_MAX_INTERRUPTS (64)
#define PLAT_IMSIC_IF_BASE_ADDR   (0x28000000)
#define PLAT_IMSIC_MAX_INTERRUPTS (255)

#define CPU_EXT_SSTC 1

/* IPC shmem interrupt injected by Bao on peer notification. */
#define SHMEM_IRQ_ID (3)

/* Xilinx AXI GPIO base address (channel 1 drives the LEDs). */
#define GPIO_BASE (0x40000000UL)

#ifndef __ASSEMBLER__
void plat_led_init(void);
void plat_led_on(void);
void plat_led_off(void);
#endif

#endif
