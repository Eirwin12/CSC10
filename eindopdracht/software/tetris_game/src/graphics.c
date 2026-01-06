#include "graphics.h"
#include <string.h>

// Kleuren definitie
const RGB COLOR_BLACK   = {0, 0, 0};
const RGB COLOR_RED     = {255, 0, 0};
const RGB COLOR_GREEN   = {0, 255, 0};
const RGB COLOR_BLUE    = {0, 0, 255};
const RGB COLOR_YELLOW  = {255, 255, 0};
const RGB COLOR_CYAN    = {0, 255, 255};
const RGB COLOR_MAGENTA = {255, 0, 255};
const RGB COLOR_WHITE   = {255, 255, 255};

void graphics_init(void) {
    // Clear framebuffer
    clear_screen(COLOR_BLACK);
}

uint32_t rgb_to_word(RGB color) {
    return ((uint32_t)color.r << 16) | 
           ((uint32_t)color.g << 8) | 
           (uint32_t)color.b;
}

RGB word_to_rgb(uint32_t word) {
    RGB color;
    color.r = (word >> 16) & 0xFF;
    color.g = (word >> 8) & 0xFF;
    color.b = word & 0xFF;
    return color;
}

void draw_pixel(uint8_t x, uint8_t y, RGB color) {
    if (x >= 32 || y >= 32) return;
    
    uint32_t address = FRAMEBUFFER_BASE + ((y * 32 + x) * 4);
    uint32_t pixel_data = rgb_to_word(color);
    
    *(volatile uint32_t*)address = pixel_data;
}

void draw_rect(uint8_t x, uint8_t y, uint8_t width, uint8_t height, RGB color) {
    for (uint8_t dy = 0; dy < height; dy++) {
        for (uint8_t dx = 0; dx < width; dx++) {
            draw_pixel(x + dx, y + dy, color);
        }
    }
}

void clear_screen(RGB color) {
    draw_rect(0, 0, 32, 32, color);
}
