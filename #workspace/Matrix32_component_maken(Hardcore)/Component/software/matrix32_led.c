/**
 * @file matrix32_led.c
 * @brief Driver implementatie voor 32x32 RGB LED Matrix Controller met Framebuffer
 * @author Mitch - CSC10 Project
 * @date 2026
 * 
 * ARCHITECTUUR:
 * =============
 * Deze driver biedt een EENVOUDIGE C API om pixels aan/uit te zetten.
 * 
 * VHDL (Matrix32_LED.vhd) doet het ZWARE WERK:
 *   - Automatische row scanning (16 gemultiplexte rijen)
 *   - Shift register aansturing (HUB75 protocol)
 *   - Timing generatie (CLK, LAT, OE signalen)
 *   - Framebuffer opslag (384 bytes in FPGA)
 *   - Real-time refresh (constant 1kHz+ refresh rate)
 * 
 * C CODE (deze file) doet alleen:
 *   - Pixel waarden schrijven naar framebuffer via Avalon bus
 *   - Eenvoudige draw functies (lijnen, rechthoeken, tekst)
 *   - Mode selectie (framebuffer vs test patterns)
 * 
 * De FPGA hardware zorgt ervoor dat zodra je een pixel schrijft,
 * deze automatisch op de matrix verschijnt zonder verdere actie!
 */

#include "matrix32_led.h"
#include <stdio.h>
#include <string.h>

// ============================================================================
// Internal Helper: Framebuffer cache (optioneel, voor snellere read-modify-write)
// ============================================================================
static uint8_t fb_cache[MATRIX32_FRAMEBUFFER_SIZE];
static uint8_t cache_valid = 0;

// ============================================================================
// Core API Functions
// ============================================================================

void matrix32_init(uint32_t base_address) {
    // Clear framebuffer cache
    memset(fb_cache, 0, MATRIX32_FRAMEBUFFER_SIZE);
    cache_valid = 0;
    
    // Disable matrix
    MATRIX32_WRITE_REG(base_address, MATRIX32_CONTROL_REG_OFFSET, 0x00000000);
    
    // Set mode to framebuffer
    MATRIX32_WRITE_REG(base_address, MATRIX32_PATTERN_REG_OFFSET, 0x00000000);
    
    // Clear framebuffer in hardware
    matrix32_clear(base_address);
}

void matrix32_enable(uint32_t base_address, uint8_t enable) {
    uint32_t ctrl_reg = MATRIX32_READ_REG(base_address, MATRIX32_CONTROL_REG_OFFSET);
    
    if (enable) {
        ctrl_reg |= MATRIX32_CTRL_ENABLE_MASK;
    } else {
        ctrl_reg &= ~MATRIX32_CTRL_ENABLE_MASK;
    }
    
    MATRIX32_WRITE_REG(base_address, MATRIX32_CONTROL_REG_OFFSET, ctrl_reg);
}

void matrix32_set_mode(uint32_t base_address, uint8_t mode) {
    uint32_t ctrl_reg = MATRIX32_READ_REG(base_address, MATRIX32_CONTROL_REG_OFFSET);
    
    if (mode) {
        ctrl_reg |= MATRIX32_CTRL_MODE_MASK;  // Pattern mode
    } else {
        ctrl_reg &= ~MATRIX32_CTRL_MODE_MASK; // Framebuffer mode
    }
    
    MATRIX32_WRITE_REG(base_address, MATRIX32_CONTROL_REG_OFFSET, ctrl_reg);
}

void matrix32_set_pattern(uint32_t base_address, matrix32_pattern_t pattern) {
    uint32_t pattern_reg = (uint32_t)pattern & 0x7;
    MATRIX32_WRITE_REG(base_address, MATRIX32_PATTERN_REG_OFFSET, pattern_reg);
}

// ============================================================================
// Framebuffer API Functions
// ============================================================================

void matrix32_clear(uint32_t base_address) {
    // Write zeros to all 384 bytes
    for (uint16_t addr = 0; addr < MATRIX32_FRAMEBUFFER_SIZE; addr++) {
        matrix32_write_fb_byte(base_address, addr, 0x00);
    }
    
    // Update cache
    memset(fb_cache, 0, MATRIX32_FRAMEBUFFER_SIZE);
    cache_valid = 1;
}

void matrix32_fill(uint32_t base_address, uint8_t color) {
    uint8_t r = (color & 0x04) ? 1 : 0;
    uint8_t g = (color & 0x02) ? 1 : 0;
    uint8_t b = (color & 0x01) ? 1 : 0;
    
    uint8_t r_byte = r ? 0xFF : 0x00;
    uint8_t g_byte = g ? 0xFF : 0x00;
    uint8_t b_byte = b ? 0xFF : 0x00;
    
    // Write R channel (bytes 0-127)
    for (uint16_t addr = 0; addr < 128; addr++) {
        matrix32_write_fb_byte(base_address, addr, r_byte);
        fb_cache[addr] = r_byte;
    }
    
    // Write G channel (bytes 128-255)
    for (uint16_t addr = 128; addr < 256; addr++) {
        matrix32_write_fb_byte(base_address, addr, g_byte);
        fb_cache[addr] = g_byte;
    }
    
    // Write B channel (bytes 256-383)
    for (uint16_t addr = 256; addr < 384; addr++) {
        matrix32_write_fb_byte(base_address, addr, b_byte);
        fb_cache[addr] = b_byte;
    }
    
    cache_valid = 1;
}

void matrix32_set_pixel(uint32_t base_address, uint8_t x, uint8_t y, 
                        uint8_t r, uint8_t g, uint8_t b) {
    // ========================================================================
    // EENVOUDIGE PIXEL SET FUNCTIE
    // De C code schrijft alleen pixel waarden naar de framebuffer.
    // De VHDL hardware zorgt automatisch voor:
    //   - Matrix scanning en multiplexing
    //   - Timing generatie (CLK, LAT, OE)
    //   - Real-time refresh van de matrix
    // ========================================================================
    
    // Bounds check
    if (x >= MATRIX32_WIDTH || y >= MATRIX32_HEIGHT) {
        return;
    }
    
    // Calculate pixel index
    uint16_t pixel_index = y * MATRIX32_WIDTH + x;
    uint16_t byte_addr = pixel_index / 8;
    uint8_t bit_offset = pixel_index % 8;
    uint8_t bit_mask = 1 << bit_offset;
    
    // Update R channel (bytes 0-127)
    // Hardware leest deze waarde en zet direct de LED aan/uit
    uint8_t r_byte = fb_cache[byte_addr];
    if (r) {
        r_byte |= bit_mask;   // Zet bit aan
    } else {
        r_byte &= ~bit_mask;  // Zet bit uit
    }
    matrix32_write_fb_byte(base_address, byte_addr, r_byte);
    fb_cache[byte_addr] = r_byte;
    
    // Update G channel (bytes 128-255)
    uint8_t g_byte = fb_cache[128 + byte_addr];
    if (g) {
        g_byte |= bit_mask;
    } else {
        g_byte &= ~bit_mask;
    }
    matrix32_write_fb_byte(base_address, 128 + byte_addr, g_byte);
    fb_cache[128 + byte_addr] = g_byte;
    
    // Update B channel (bytes 256-383)
    uint8_t b_byte = fb_cache[256 + byte_addr];
    if (b) {
        b_byte |= bit_mask;
    } else {
        b_byte &= ~bit_mask;
    }
    matrix32_write_fb_byte(base_address, 256 + byte_addr, b_byte);
    fb_cache[256 + byte_addr] = b_byte;
    
    cache_valid = 1;
}

void matrix32_set_pixel_color(uint32_t base_address, uint8_t x, uint8_t y, uint8_t color) {
    uint8_t r = (color & 0x04) ? 1 : 0;
    uint8_t g = (color & 0x02) ? 1 : 0;
    uint8_t b = (color & 0x01) ? 1 : 0;
    
    matrix32_set_pixel(base_address, x, y, r, g, b);
}

uint8_t matrix32_get_pixel(uint32_t base_address, uint8_t x, uint8_t y) {
    // Bounds check
    if (x >= MATRIX32_WIDTH || y >= MATRIX32_HEIGHT) {
        return 0;
    }
    
    // Calculate pixel index
    uint16_t pixel_index = y * MATRIX32_WIDTH + x;
    uint16_t byte_addr = pixel_index / 8;
    uint8_t bit_offset = pixel_index % 8;
    uint8_t bit_mask = 1 << bit_offset;
    
    // Read RGB from cache
    uint8_t r = (fb_cache[byte_addr] & bit_mask) ? 1 : 0;
    uint8_t g = (fb_cache[128 + byte_addr] & bit_mask) ? 1 : 0;
    uint8_t b = (fb_cache[256 + byte_addr] & bit_mask) ? 1 : 0;
    
    return (r << 2) | (g << 1) | b;
}

// ============================================================================
// Drawing Functions
// ============================================================================

void matrix32_draw_hline(uint32_t base_address, uint8_t x0, uint8_t x1, uint8_t y, uint8_t color) {
    if (x1 < x0) {
        uint8_t temp = x0;
        x0 = x1;
        x1 = temp;
    }
    
    for (uint8_t x = x0; x <= x1 && x < MATRIX32_WIDTH; x++) {
        matrix32_set_pixel_color(base_address, x, y, color);
    }
}

void matrix32_draw_vline(uint32_t base_address, uint8_t x, uint8_t y0, uint8_t y1, uint8_t color) {
    if (y1 < y0) {
        uint8_t temp = y0;
        y0 = y1;
        y1 = temp;
    }
    
    for (uint8_t y = y0; y <= y1 && y < MATRIX32_HEIGHT; y++) {
        matrix32_set_pixel_color(base_address, x, y, color);
    }
}

void matrix32_draw_rect(uint32_t base_address, uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint8_t color) {
    // Top edge
    matrix32_draw_hline(base_address, x, x + w - 1, y, color);
    
    // Bottom edge
    matrix32_draw_hline(base_address, x, x + w - 1, y + h - 1, color);
    
    // Left edge
    matrix32_draw_vline(base_address, x, y, y + h - 1, color);
    
    // Right edge
    matrix32_draw_vline(base_address, x + w - 1, y, y + h - 1, color);
}

void matrix32_fill_rect(uint32_t base_address, uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint8_t color) {
    for (uint8_t dy = 0; dy < h && (y + dy) < MATRIX32_HEIGHT; dy++) {
        matrix32_draw_hline(base_address, x, x + w - 1, y + dy, color);
    }
}

// ============================================================================
// Status & Debug Functions
// ============================================================================

uint32_t matrix32_get_status(uint32_t base_address) {
    return MATRIX32_READ_REG(base_address, MATRIX32_STATUS_REG_OFFSET);
}

uint8_t matrix32_is_enabled(uint32_t base_address) {
    uint32_t status = matrix32_get_status(base_address);
    return (status & 0x01) ? 1 : 0;
}

void matrix32_print_info(uint32_t base_address) {
    uint32_t control = MATRIX32_READ_REG(base_address, MATRIX32_CONTROL_REG_OFFSET);
    uint32_t pattern = MATRIX32_READ_REG(base_address, MATRIX32_PATTERN_REG_OFFSET);
    uint32_t status = matrix32_get_status(base_address);
    
    printf("=== Matrix32 LED Status ===\n");
    printf("Base Address: 0x%08X\n", base_address);
    printf("\n");
    printf("Registers:\n");
    printf("  CONTROL (0x00): 0x%08X\n", control);
    printf("  PATTERN (0x04): 0x%08X\n", pattern);
    printf("  STATUS  (0x10): 0x%08X\n", status);
    printf("\n");
    printf("Decoded Status:\n");
    printf("  Enabled: %s\n", (status & 0x01) ? "YES" : "NO");
    printf("  Mode: %s\n", (status & 0x02) ? "PATTERN" : "FRAMEBUFFER");
    printf("  Pattern: %d\n", (status >> 2) & 0x07);
    printf("  Cache Valid: %s\n", cache_valid ? "YES" : "NO");
    printf("===========================\n");
}

// ============================================================================
// Low-Level Framebuffer Access
// ============================================================================

void matrix32_write_fb_byte(uint32_t base_address, uint16_t byte_addr, uint8_t data) {
    // Set address
    MATRIX32_WRITE_REG(base_address, MATRIX32_FB_ADDR_REG_OFFSET, (uint32_t)byte_addr);
    
    // Write data (triggers framebuffer write)
    MATRIX32_WRITE_REG(base_address, MATRIX32_FB_DATA_REG_OFFSET, (uint32_t)data);
}
