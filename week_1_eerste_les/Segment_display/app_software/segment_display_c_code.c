#include "address_map_nios2.h"
#include "globals.h" // defines global values
#include "nios2_ctrl_reg_macros.h"
#include <stdbool.h>

/* the global variables are written by interrupt service routines; we have to
 * declare
 * these as volatile to avoid the compiler caching their values in registers */
volatile int count      = 0;     //count
volatile bool flag      = false; //flag for if count value has past or not
#define hexOutput (volatile char*)  0x010; //adres of the output file

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
        (int *)TIMER_BASE;                    // interal timer base address
    volatile int * KEY_ptr = (int *)KEY_BASE; // pushbutton KEY address

    /* set the interval timer period for scrolling the LED lights */
    int counter                 = 50000; // 1/(50 MHz) x (2500000) = 50 msec
    *(interval_timer_ptr + 0x2) = (counter & 0xFFFF);
    *(interval_timer_ptr + 0x3) = (counter >> 16) & 0xFFFF;

    /* start interval timer, enable its interrupts */
    *(interval_timer_ptr + 1) = 0x7; // STOP = 0, START = 1, CONT = 1, ITO = 1

    *(KEY_ptr + 2) = 0x3; // enable interrupts for all pushbuttons

    /* set interrupt mask bits for levels 0 (interval timer) and level 1
     * (pushbuttons) */
    NIOS2_WRITE_IENABLE(0x3);

    NIOS2_WRITE_STATUS(1); // enable Nios II interrupts
	int hex_val;
    while (1)
    	if (flag)
        {
        	flag = false;
            *hexOutput = hex_to_7_seg(count);
        ; // main program simply idles
}