#include <plat.h>
#include <8250_uart.h>
#include <stdint.h>

#define VIRT_UART_BAUDRATE      115200
#define VIRT_UART_SHIFTREG_ADDR 1843200

typedef struct {
    volatile uint32_t data;        /* 0x000 - channel 1 data */
    volatile uint32_t tri;         /* 0x004 - channel 1 tristate (0=output) */
    volatile uint32_t data2;       /* 0x008 - channel 2 data */
    volatile uint32_t tri2;        /* 0x00C - channel 2 tristate */
    uint8_t           reserved1[0x10C];
    volatile uint32_t gier;        /* 0x11C - global interrupt enable */
    volatile uint32_t ip_isr;      /* 0x120 - interrupt status */
    uint32_t          reserved2;
    volatile uint32_t ip_ier;      /* 0x128 - interrupt enable */
} xlnx_axi_gpio_t;

#define GPIO ((xlnx_axi_gpio_t *)(GPIO_BASE))

void uart_init(void)
{
    uart8250_init(PLAT_UART_ADDR, 50000000, 115200, 0, 4);
}

void plat_led_init(void)
{
    GPIO->tri = 0; /* channel 1: all pins as outputs (drives LEDs) */
}

void uart_putc(char c)
{
    uart8250_putc(c);
}

char uart_getchar(void)
{
    return uart8250_getc();
}

void uart_enable_rxirq(void)
{
    uart8250_enable_rx_int();
}

void uart_clear_rxirq(void)
{
    uart8250_interrupt_handler();
}

void plat_led_on(void)
{
    GPIO->data |= 0xff;
}

void plat_led_off(void)
{
    GPIO->data &= 0;
}
