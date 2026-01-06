#ifndef GRAPHICS_H
#define GRAPHICS_H

#include <stdint.h>
#include "system.h"

// Framebuffer base address (vanuit Platform Designer)
#define FRAMEBUFFER_BASE RGB_FRAMEBUFFER_0_BASE

// RGB kleur structuur
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} RGB;

// Functie prototypes
void graphics_init(void);
void draw_pixel(uint8_t x, uint8_t y, RGB color);
void draw_rect(uint8_t x, uint8_t y, uint8_t width, uint8_t height, RGB color);
void clear_screen(RGB color);
uint32_t rgb_to_word(RGB color);
RGB word_to_rgb(uint32_t word);

// Handige kleuren
extern const RGB COLOR_BLACK;
extern const RGB COLOR_RED;
extern const RGB COLOR_GREEN;
extern const RGB COLOR_BLUE;
extern const RGB COLOR_YELLOW;
extern const RGB COLOR_CYAN;
extern const RGB COLOR_MAGENTA;
extern const RGB COLOR_WHITE;

#endif // GRAPHICS_H
