// Hardware addresses from Platform Designer (nois_system.sopcinfo)
#define HEX3_HEX0_BASE    ((volatile unsigned int *) 0x2030)
#define HEX5_HEX4_BASE    ((volatile unsigned int *) 0x2020)
#define TIMER_BASE        ((volatile unsigned int *) 0x2000)

// Timer register offsets (in 32-bit words)
#define TIMER_STATUS      0
#define TIMER_CONTROL     1
#define TIMER_PERIODL     2
#define TIMER_PERIODH     3
#define TIMER_SNAPL       4
#define TIMER_SNAPH       5

volatile unsigned int counter = 0;


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
    *HEX3_HEX0_BASE = hex3_hex0;
    *HEX5_HEX4_BASE = hex5_hex4;
}

/**
 * timer_isr: Interrupt Service Routine for the timer
 * This is called by interrupt_handler in exception_handler.c
 */
void timer_isr(void) {
    volatile int * timer_status = (int *)(TIMER_BASE + TIMER_STATUS);
    
    // Clear the timer interrupt by writing 0 to TO bit
    *timer_status = 0;
    
    // Increment counter
    counter++;
    
    // Update displays (0 = decimal, 1 = hexadecimal)
    update_displays(counter, 0);
}

/**
 * init_timer: Initialize the interval timer with interrupts
 * Timer configured for 1ms interrupts (period already set in hardware to 49999)
 */
void init_timer(void) {
    volatile int * timer_control = (int *)(TIMER_BASE + TIMER_CONTROL);
    volatile int * timer_status = (int *)(TIMER_BASE + TIMER_STATUS);
    
    // Stop the timer first
    *timer_control = 0x8;  // STOP bit
    
    // Clear any pending interrupts
    *timer_status = 0;
    
    // Start timer with: START | CONT | ITO (enable interrupts)
    // Bit 0 (ITO) = 1: Interrupt enable
    // Bit 1 (CONT) = 1: Continuous mode
    // Bit 2 (START) = 1: Start the timer
    *timer_control = 0x7;  // 0b0111
}

/**
 * enable_nios2_interrupts: Enable interrupts in the Nios II processor
 */
void enable_nios2_interrupts(void) {
    int status;
    
    // Read the status register
    asm("rdctl %0, ctl0" : "=r" (status));
    
    // Set PIE bit (bit 0) to enable processor interrupts
    status |= 0x1;
    
    // Write back to status register
    asm("wrctl ctl0, %0" : : "r" (status));
    
    // Enable IRQ 1 (timer) in ienable register (ctl3)
    // IRQ 1 corresponds to bit 1
    asm("movi r2, 0x2");      // Load value 0x2 (bit 1 set)
    asm("wrctl ctl3, r2");    // Write to ienable register
}

/**
 * main: Main program
 */
int main(void) {
    // Initialize counter to 0
    counter = 0;
    
    // Display initial value
    update_displays(counter, 0);
    
    // Initialize the timer hardware
    init_timer();
    
    // Enable interrupts in Nios II processor
    enable_nios2_interrupts();
    
    // Main loop - counter updates automatically via interrupts
    while (1) {
        // The displays update automatically in the ISR every 1ms
        // You can add other code here if needed
    }
    
    return 0;
}
