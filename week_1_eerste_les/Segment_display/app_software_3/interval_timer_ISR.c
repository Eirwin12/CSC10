#include "address_map_nios2.h"
#include "globals.h" // defines global values

extern volatile int counter_int, flag;
/*******************************************************************************
 * Interval timer interrupt service routine
 *
 * Shifts a PATTERN being displayed on the LED lights. The shift direction
 * is determined by the external variable key_dir.
 ******************************************************************************/
 
 #define MAX_COUNT (0xffffff)
 #define TIMER_ADDR 0x2020
 
void interval_timer_ISR() {
    volatile int * interval_timer_ptr = (int *)TIMER_ADDR;

    *(interval_timer_ptr) = 0; // clear the interrupt

    /* rotate the pattern shown on the LEDG lights */
    counter_int = (counter_int+1) % MAX_COUNT;
    flag = 1;
    return;
}

