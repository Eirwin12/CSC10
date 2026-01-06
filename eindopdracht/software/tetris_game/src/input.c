#include "input.h"
#include "altera_avalon_pio_regs.h"

void input_init(void) {
    // PIO wordt automatisch geïnitialiseerd door HAL
    // Buttons zijn active low inputs
    // Switches zijn normale inputs
}

uint8_t read_buttons(void) {
    return (uint8_t)IORD_ALTERA_AVALON_PIO_DATA(PIO_BUTTONS_BASE);
}

uint16_t read_switches(void) {
    return (uint16_t)IORD_ALTERA_AVALON_PIO_DATA(PIO_SWITCHES_BASE);
}

bool is_button_pressed(ButtonFunction btn) {
    uint8_t buttons = read_buttons();
    
    // Active low: pressed = 0
    switch(btn) {
        case BTN_LEFT:
            return !(buttons & BUTTON_0);
        case BTN_RIGHT:
            return !(buttons & BUTTON_1);
        case BTN_ROTATE_CW:
            return !(buttons & BUTTON_2);
        case BTN_ROTATE_CCW:
            return !(buttons & BUTTON_3);
        default:
            return false;
    }
}

RGB get_color_from_switches(void) {
    uint16_t sw = read_switches();
    
    // SW0-SW2: Blue (active low)
    // SW3-SW5: Green
    // SW6-SW8: Red
    
    uint8_t r_bits = (~sw >> 6) & 0x07;  // 0-7
    uint8_t g_bits = (~sw >> 3) & 0x07;
    uint8_t b_bits = (~sw) & 0x07;
    
    RGB color;
    
    // Map 0-7 to 1-255
    // 0 → 1 (zichtbaar maar dim)
    // 7 → 255 (volledig helder)
    color.r = (r_bits == 0) ? 1 : (r_bits * 36 + 3);
    color.g = (g_bits == 0) ? 1 : (g_bits * 36 + 3);
    color.b = (b_bits == 0) ? 1 : (b_bits * 36 + 3);
    
    return color;
}
