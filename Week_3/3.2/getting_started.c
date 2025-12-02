#include "address_map_arm.h"
/* This program demonstrates use of parallel ports in the Computer System
 *
 * It performs the following:
 *  1. displays a counter value on the 7-segment displays
 *  2. the counter increments regularly
*/

/* Function to convert hexadecimal digit to 7-segment display code */
int hex_to_7_seg(int hex_digit) {
    if (hex_digit == 0x0) return 0x3F;
    if (hex_digit == 0x1) return 0x06;
    if (hex_digit == 0x2) return 0x5B;
    if (hex_digit == 0x3) return 0x4F;
    if (hex_digit == 0x4) return 0x66;
    if (hex_digit == 0x5) return 0x6D;
    if (hex_digit == 0x6) return 0x7D;
    if (hex_digit == 0x7) return 0x07;
    if (hex_digit == 0x8) return 0x7F;
    if (hex_digit == 0x9) return 0x67;
    if (hex_digit == 0xA) return 0x77;
    if (hex_digit == 0xB) return 0x7C;
    if (hex_digit == 0xC) return 0x39;
    if (hex_digit == 0xD) return 0x5E;
    if (hex_digit == 0xE) return 0x79;
    if (hex_digit == 0xF) return 0x71;
    return 0x00;
}

int main(void) {
    /* Declare volatile pointers to I/O registers (volatile means that IO load
     * and store instructions will be used to access these pointer locations,
     * instead of regular memory loads and stores)
    */
    volatile int * HEX3_HEX0_ptr = (int *)HEX3_HEX0_BASE; // 7-segment displays HEX3-HEX0
    volatile int * HEX5_HEX4_ptr = (int *)HEX5_HEX4_BASE; // 7-segment displays HEX5-HEX4

    int counter = 0; // counter value
    volatile int
        delay_count; // volatile so the C compiler doesn't remove the loop
    int hex_display;

    while (1) {
        /* Convert counter to 7-segment display codes */
        hex_display = hex_to_7_seg(counter & 0xF) |
                      (hex_to_7_seg((counter >> 4) & 0xF) << 8) |
                      (hex_to_7_seg((counter >> 8) & 0xF) << 16) |
                      (hex_to_7_seg((counter >> 12) & 0xF) << 24);
        *(HEX3_HEX0_ptr) = hex_display;

        hex_display = hex_to_7_seg((counter >> 16) & 0xF) |
                      (hex_to_7_seg((counter >> 20) & 0xF) << 8);
        *(HEX5_HEX4_ptr) = hex_display;

        /* Increment counter */
        counter++;

        for (delay_count = 350000; delay_count != 0; --delay_count)
            ; // delay loop
    }
}
