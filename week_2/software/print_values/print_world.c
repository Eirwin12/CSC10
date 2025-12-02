#include "alt_types.h"
#include "sys/alt_irq.h"
#include "system.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "drivers/inc/altera_avalon_timer.h"
#include "drivers/inc/altera_avalon_jtag_uart.h"

volatile alt_32 count      = 0;     //count
volatile alt_8 flag      = 0; //flag for if count value has past or not

#define TIMER_STATUS 0x0

void timer_isr(void) {
    volatile int * timer_status = (int *)(TIMER_0_BASE + TIMER_STATUS);

    // Clear the timer interrupt by writing 0 to TO bit
    *timer_status = 0;

    // Increment counter
    count = (count + 1)% 0xFFFFFF;

    flag = 1;
}

int main(void) {
    /* Declare volatile pointers to I/O registers (volatile means that IO load
     * and store instructions will be used to access these pointer locations,
     * instead of regular memory loads and stores)
     */
    volatile int * interval_timer_ptr =
        (int *)TIMER_0_BASE;                    // interal timer base address

    /* set the interval timer period for scrolling the LED lights */
    int counter                 = 500000; // 1/(50 MHz) x (25000000) = 500 msec
    *(interval_timer_ptr + 0x2) = (counter & 0xFFFF);
    *(interval_timer_ptr + 0x3) = (counter >> 16) & 0xFFFF;

    /* start interval timer, enable its interrupts */
    alt_ic_isr_register(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_0_IRQ, timer_isr, NULL, NULL);
    *(interval_timer_ptr + 1) = 0x7; // STOP = 0, START = 1, CONT = 1, ITO = 1
//    result = alt_ic_irq_enable(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_0_IRQ);
//	alt_avalon_timer_sc_init(TIMER_0_BASE, TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_0_IRQ)
//    alt_vic_sw_interrupt_set(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_0_IRQ);

    NIOS2_WRITE_STATUS(1); // enable Nios II interrupts
	volatile int * lsb = (int *)REG32_AVALON_INTERFACE_V2_0_AVALON_SLAVE_0_BASE;
	volatile int * msb = (int *)REG32_AVALON_INTERFACE_V2_0_AVALON_SLAVE_1_BASE;

//	altera_avalon_jtag_uart_state jtag_state;
//	jtag_state.base = JTAG_UART_0_BASE;
//	altera_avalon_jtag_uart_init(jtag_state, JTAG_UART_0_IRQ_INTERRUPT_CONTROLLER_ID, JTAG_UART_0_IRQ);
	char input;
	printf("jtag uart testen");
    while (1)
    {
    	if (flag)
        {
        	flag = 0;
            *lsb = count & 0xFFFF;
            *msb = (count>>16) & 0xFF;
        }
    	input = getchar();
    	printf("getypt letter: ");
    	putchar(input);
    	printf("\n");
    }
}
