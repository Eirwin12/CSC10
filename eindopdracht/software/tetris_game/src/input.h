#ifndef INPUT_H
#define INPUT_H

#include <stdint.h>
#include <stdbool.h>
#include "system.h"
#include "graphics.h"

// Button mapping (active low)
#define BUTTON_0    0x01
#define BUTTON_1    0x02
#define BUTTON_2    0x04
#define BUTTON_3    0x08

// Button functions
typedef enum {
    BTN_LEFT,
    BTN_RIGHT,
    BTN_ROTATE_CW,
    BTN_ROTATE_CCW
} ButtonFunction;

// Functie prototypes
void input_init(void);
uint8_t read_buttons(void);
uint16_t read_switches(void);
bool is_button_pressed(ButtonFunction btn);
RGB get_color_from_switches(void);

#endif // INPUT_H
