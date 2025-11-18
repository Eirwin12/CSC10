#include "address_map_nios2.h"
#include "globals.h" // defines global values
#include "nios2_ctrl_reg_macros.h"

/* the global variables are written by interrupt service routines; we have to
 * declare
 * these as volatile to avoid the compiler caching their values in registers */
volatile int counter_int      = 0; // pattern for shifting
volatile int flag         = 0; // pattern for shifting

#define LEFT_HEX_ADDR       0x2060
#define RIGHT_HEX_ADDR	    0x2070
#define TIMER_ADDR			0x2020
/*******************************************************************************
 * This program demonstrates use of interrupts. It
 * first starts the interval timer with 50 msec timeouts, and then enables
 * Nios II interrupts from the interval timer and pushbutton KEYs
 *
 * The interrupt service routine for the interval timer displays a pattern on
 * the LED lights, and shifts this pattern either left or right. The shifting
 * direction is reversed when KEY[1] is pressed
********************************************************************************/

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

int main(void) {
    /* Declare volatile pointers to I/O registers (volatile means that IO load
     * and store instructions will be used to access these pointer locations,
     * instead of regular memory loads and stores)
     */
    volatile int * interval_timer_ptr =
        (int *)TIMER_ADDR;                    // interal timer base address
    volatile int * left_hex_ptr = (int *)LEFT_HEX_ADDR;
    volatile int * right_hex_ptr = (int *)RIGHT_HEX_ADDR;

    /* set the interval timer period for scrolling the LED lights */
    int counter                 = 2500000; // 1/(50 MHz) x (2500000) = 50 msec
    *(interval_timer_ptr + 0x2) = (counter & 0xFFFF);
    *(interval_timer_ptr + 0x3) = (counter >> 16) & 0xFFFF;

    /* start interval timer, enable its interrupts */
    *(interval_timer_ptr + 1) = 0x7; // STOP = 0, START = 1, CONT = 1, ITO = 1

    /* set interrupt mask bits for levels 0 (interval timer) and level 1
     * (pushbuttons) */
    NIOS2_WRITE_IENABLE(0x3);

    NIOS2_WRITE_STATUS(1); // enable Nios II interrupts

    while (1)
    {
    	if (flag == 1)
        {
        	flag = 0;
            int output;
            output = hex_to_7_seg(counter_int & 0xf) + (hex_to_7_seg((counter_int>>4) & 0xf)<<7) + (hex_to_7_seg((counter_int>>8) &0xf)<<14);
            *right_hex_ptr = output;
            output = hex_to_7_seg((counter_int>>12) &0xf) + (hex_to_7_seg((counter_int>>16) &0xf)<<7) + (hex_to_7_seg((counter_int>>20) &0xf)<<14);
            *left_hex_ptr = output;
        }
    }
}
