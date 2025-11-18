#include <system.h>
#include <altera_avalon_pio_regs.h>
#include <alt_types.h>
#include <altera_avalon_timer_regs.h>
#include <altera_avalon_timer.h>
#include <stdio.h>
#include <stdlib.h>
#include "sys/alt_irq.h"
#include <stdint.h>

volatile uint32_t counter = 0;


int hex_to_7_seg(int hex_digit) {
    if (hex_digit == 0x0) return 0x40;
    if (hex_digit == 0x1) return 0x79;
    if (hex_digit == 0x2) return 0x24;
    if (hex_digit == 0x3) return 0x30;
    if (hex_digit == 0x4) return 0x19;
    if (hex_digit == 0x5) return 0x12;
    if (hex_digit == 0x6) return 0x02;
    if (hex_digit == 0x7) return 0x78;
    if (hex_digit == 0x8) return 0x00;
    if (hex_digit == 0x9) return 0x10;
    if (hex_digit == 0xA) return 0x08;
    if (hex_digit == 0xB) return 0x03;
    if (hex_digit == 0xC) return 0x46;
    if (hex_digit == 0xD) return 0x21;
    if (hex_digit == 0xE) return 0x06;
    if (hex_digit == 0xF) return 0x0E;
    return 0x7F;
}


void update_displays(unsigned int value, int use_hex) {
    int digit0, digit1, digit2, digit3, digit4, digit5;
    unsigned int hex3_hex0 = 0;
    unsigned int hex5_hex4 = 0;
    
    if (use_hex) {
        // Hexadecimal display
        digit0 = (value >> 0) & 0xF;
        digit1 = (value >> 4) & 0xF;
        digit2 = (value >> 8) & 0xF;
        digit3 = (value >> 12) & 0xF;
        digit4 = (value >> 16) & 0xF;
        digit5 = (value >> 20) & 0xF;
    } else {
        // Decimal display
        digit0 = value % 10;
        value /= 10;
        digit1 = value % 10;
        value /= 10;
        digit2 = value % 10;
        value /= 10;
        digit3 = value % 10;
        value /= 10;
        digit4 = value % 10;
        value /= 10;
        digit5 = value % 10;
    }
    
    // Pack 4 displays (HEX0-HEX3) into one 32-bit value
    hex3_hex0 = (hex_to_7_seg(digit3) << 24) | 
                (hex_to_7_seg(digit2) << 16) | 
                (hex_to_7_seg(digit1) << 8)  | 
                 hex_to_7_seg(digit0);
    
    // Pack 2 displays (HEX4-HEX5) into one 32-bit value
    hex5_hex4 = (hex_to_7_seg(digit5) << 8) | 
                 hex_to_7_seg(digit4);
    
    // Write to the hardware registers
    IOWR_ALTERA_AVALON_PIO_DATA(HEX_DISPLAY_HEX3_HEX0_BASE, hex3_hex0);
    IOWR_ALTERA_AVALON_PIO_DATA(HEX_DISPLAY_HEX5_HEX4_BASE, hex5_hex4);
}

/**
 * timer_isr: Interrupt Service Routine for the timer
 * This is called by interrupt_handler in exception_handler.c
 */
static void timer_isr(void* context) {
    // Clear pending interrupt and update the counter
    IOWR_ALTERA_AVALON_TIMER_STATUS(INTERVAL_TIMER_SEGMENT_BASE, 0);
    counter++;
    update_displays(counter, 0);
}

/*
 * We gebruiken nu de BSP helper alt_avalon_timer_sc_init i.p.v. een eigen
 * init_timer functie. Deze configureert de interval timer en registreert
 * eerst een standaard ISR; daarna overriden we die met onze eigen ISR voor
 * het bijwerken van de 7-segment displays.
 */


/**
 * main: Main program
 */
int main(void) {
    // Initialize counter to 0
    counter = 0;
    
    // Display initial value
    update_displays(counter, 0);
    // Initialise de hardware timer via BSP helper (base, ic_id, irq, freq)
    alt_avalon_timer_sc_init((void*)INTERVAL_TIMER_SEGMENT_BASE,
                             INTERVAL_TIMER_SEGMENT_IRQ_INTERRUPT_CONTROLLER_ID,
                             INTERVAL_TIMER_SEGMENT_IRQ,
                             ALT_CPU_FREQ);

    // Override standaard ISR met onze eigen (display update)
    alt_irq_register(INTERVAL_TIMER_SEGMENT_IRQ, NULL, timer_isr);
    // CPU interrupts inschakelen
    alt_irq_cpu_enable_interrupts();
    
    
    // Main loop - counter updates automatically via interrupts
    while (1) {
        // The displays update automatically in the ISR every 1ms
        // You can add other code here if needed
    }
    
    return 0;
}
