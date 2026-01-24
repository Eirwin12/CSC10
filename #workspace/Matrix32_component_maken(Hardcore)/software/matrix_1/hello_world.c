/**
 * @file matrix32_demo.c
 * @brief Complete demo voor 32x32 RGB LED Matrix Controller
 * @author Mitch - CSC10 Project
 * @date 2026
 *
 * ============================================================================
 * ARCHITECTUUR OVERZICHT
 * ============================================================================
 *
 * VHDL HARDWARE (Matrix32_LED.vhd + Matrix32_LED_avalon.vhd):
 *   ✓ Automatische matrix scanning (16 gemultiplexte rijen)
 *   ✓ HUB75 protocol timing (CLK, LAT, OE signalen)
 *   ✓ Framebuffer opslag (384 bytes in FPGA)
 *   ✓ Real-time refresh (>1kHz refresh rate)
 *   ✓ Test pattern generator (5 hardware patronen)
 *
 * AVALON INTERFACE (5 registers):
 *   Register 0x00 (CONTROL): Enable bit [0], Mode bit [1]
 *   Register 0x04 (PATTERN): Test pattern selectie [2:0]
 *   Register 0x08 (FB_ADDR): Framebuffer address [8:0]
 *   Register 0x0C (FB_DATA): Framebuffer data [7:0] (write triggers update)
 *   Register 0x10 (STATUS):  Read-only status bits
 *
 * C SOFTWARE (deze file):
 *   → Simpele API om pixels aan/uit te zetten
 *   → Draw functies (lijnen, rechthoeken)
 *   → Demo programma's
 *
 * GEBRUIK:
 *   1. Compileer in Nios II SBT: nios2-app-generate-makefile
 *   2. make
 *   3. Upload via JTAG: nios2-download -g matrix32_demo.elf
 *   4. Run: nios2-terminal
 *
 * ============================================================================
 */

#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <io.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

// ============================================================================
// Hardware Configuratie
// ============================================================================

// Matrix component base address (uit system.h na Platform Designer)
#ifndef MATRIX32_LED_0_BASE
    #define MATRIX32_LED_0_BASE 0x00010000  // Pas aan naar jouw system.h waarde!
#endif

// KEY buttons PIO base address (uit system.h)
#ifndef PIO_KEY_BASE
    #define PIO_KEY_BASE 0x00020000  // Pas aan naar jouw system.h waarde!
#endif

#define MATRIX_BASE MATRIX32_LED_0_BASE
#define KEY_BASE PIO_KEY_BASE

// ============================================================================
// Register Offsets en Bit Masks
// ============================================================================

// Register offsets
#define MATRIX32_CONTROL_REG_OFFSET    0x00
#define MATRIX32_PATTERN_REG_OFFSET    0x04
#define MATRIX32_FB_ADDR_REG_OFFSET    0x08
#define MATRIX32_FB_DATA_REG_OFFSET    0x0C
#define MATRIX32_STATUS_REG_OFFSET     0x10

// Control register bits
#define MATRIX32_CTRL_ENABLE_MASK      0x00000001
#define MATRIX32_CTRL_MODE_MASK        0x00000002
#define MATRIX32_CTRL_MODE_FB          0
#define MATRIX32_CTRL_MODE_PATTERN     1

// Matrix dimensions
#define MATRIX32_WIDTH                 32
#define MATRIX32_HEIGHT                32
#define MATRIX32_FRAMEBUFFER_SIZE      384  // 32x32x3 bits / 8 = 384 bytes

// Kleuren (3-bit RGB)
#define COLOR_BLACK     0  // 000
#define COLOR_BLUE      1  // 001
#define COLOR_GREEN     2  // 010
#define COLOR_CYAN      3  // 011
#define COLOR_RED       4  // 100
#define COLOR_MAGENTA   5  // 101
#define COLOR_YELLOW    6  // 110
#define COLOR_WHITE     7  // 111

// Test patterns
typedef enum {
    PATTERN_CHECKERBOARD = 0,
    PATTERN_HORIZONTAL   = 1,
    PATTERN_VERTICAL     = 2,
    PATTERN_ALL_ON       = 3,
    PATTERN_RED_GRADIENT = 4,
    PATTERN_ALL_OFF      = 7
} matrix32_pattern_t;

// ============================================================================
// Register Access Macros
// ============================================================================

#define MATRIX32_WRITE_REG(base, offset, value) \
    IOWR_32DIRECT((base), (offset), (value))

#define MATRIX32_READ_REG(base, offset) \
    IORD_32DIRECT((base), (offset))

// ============================================================================
// Global Variables
// ============================================================================

static uint8_t fb_cache[MATRIX32_FRAMEBUFFER_SIZE];
static uint8_t cache_valid = 0;

// ============================================================================
// Low-Level Hardware Functions
// ============================================================================

void matrix32_write_fb_byte(uint32_t base_address, uint16_t byte_addr, uint8_t data) {
    MATRIX32_WRITE_REG(base_address, MATRIX32_FB_ADDR_REG_OFFSET, (uint32_t)byte_addr);
    MATRIX32_WRITE_REG(base_address, MATRIX32_FB_DATA_REG_OFFSET, (uint32_t)data);
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
        ctrl_reg |= MATRIX32_CTRL_MODE_MASK;
    } else {
        ctrl_reg &= ~MATRIX32_CTRL_MODE_MASK;
    }

    MATRIX32_WRITE_REG(base_address, MATRIX32_CONTROL_REG_OFFSET, ctrl_reg);
}

void matrix32_set_pattern(uint32_t base_address, matrix32_pattern_t pattern) {
    uint32_t pattern_reg = (uint32_t)pattern & 0x7;
    MATRIX32_WRITE_REG(base_address, MATRIX32_PATTERN_REG_OFFSET, pattern_reg);
}

uint32_t matrix32_get_status(uint32_t base_address) {
    return MATRIX32_READ_REG(base_address, MATRIX32_STATUS_REG_OFFSET);
}

// ============================================================================
// Framebuffer Functions
// ============================================================================

void matrix32_clear(uint32_t base_address) {
    for (uint16_t addr = 0; addr < MATRIX32_FRAMEBUFFER_SIZE; addr++) {
        matrix32_write_fb_byte(base_address, addr, 0x00);
        fb_cache[addr] = 0x00;
    }
    cache_valid = 1;
}

void matrix32_init(uint32_t base_address) {
    memset(fb_cache, 0, MATRIX32_FRAMEBUFFER_SIZE);
    cache_valid = 0;

    MATRIX32_WRITE_REG(base_address, MATRIX32_CONTROL_REG_OFFSET, 0x00000000);
    MATRIX32_WRITE_REG(base_address, MATRIX32_PATTERN_REG_OFFSET, 0x00000000);

    matrix32_clear(base_address);
}

void matrix32_fill(uint32_t base_address, uint8_t color) {
    uint8_t r = (color & 0x04) ? 1 : 0;
    uint8_t g = (color & 0x02) ? 1 : 0;
    uint8_t b = (color & 0x01) ? 1 : 0;

    uint8_t r_byte = r ? 0xFF : 0x00;
    uint8_t g_byte = g ? 0xFF : 0x00;
    uint8_t b_byte = b ? 0xFF : 0x00;

    // R channel (bytes 0-127)
    for (uint16_t addr = 0; addr < 128; addr++) {
        matrix32_write_fb_byte(base_address, addr, r_byte);
        fb_cache[addr] = r_byte;
    }

    // G channel (bytes 128-255)
    for (uint16_t addr = 128; addr < 256; addr++) {
        matrix32_write_fb_byte(base_address, addr, g_byte);
        fb_cache[addr] = g_byte;
    }

    // B channel (bytes 256-383)
    for (uint16_t addr = 256; addr < 384; addr++) {
        matrix32_write_fb_byte(base_address, addr, b_byte);
        fb_cache[addr] = b_byte;
    }

    cache_valid = 1;
}

void matrix32_set_pixel(uint32_t base_address, uint8_t x, uint8_t y,
                        uint8_t r, uint8_t g, uint8_t b) {
    if (x >= MATRIX32_WIDTH || y >= MATRIX32_HEIGHT) {
        return;
    }

    uint16_t pixel_index = y * MATRIX32_WIDTH + x;
    uint16_t byte_addr = pixel_index / 8;
    uint8_t bit_offset = pixel_index % 8;
    uint8_t bit_mask = 1 << bit_offset;

    // R channel
    uint8_t r_byte = fb_cache[byte_addr];
    if (r) {
        r_byte |= bit_mask;
    } else {
        r_byte &= ~bit_mask;
    }
    matrix32_write_fb_byte(base_address, byte_addr, r_byte);
    fb_cache[byte_addr] = r_byte;

    // G channel
    uint8_t g_byte = fb_cache[128 + byte_addr];
    if (g) {
        g_byte |= bit_mask;
    } else {
        g_byte &= ~bit_mask;
    }
    matrix32_write_fb_byte(base_address, 128 + byte_addr, g_byte);
    fb_cache[128 + byte_addr] = g_byte;

    // B channel
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
    if (x >= MATRIX32_WIDTH || y >= MATRIX32_HEIGHT) {
        return 0;
    }

    uint16_t pixel_index = y * MATRIX32_WIDTH + x;
    uint16_t byte_addr = pixel_index / 8;
    uint8_t bit_offset = pixel_index % 8;
    uint8_t bit_mask = 1 << bit_offset;

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
    matrix32_draw_hline(base_address, x, x + w - 1, y, color);
    matrix32_draw_hline(base_address, x, x + w - 1, y + h - 1, color);
    matrix32_draw_vline(base_address, x, y, y + h - 1, color);
    matrix32_draw_vline(base_address, x + w - 1, y, y + h - 1, color);
}

void matrix32_fill_rect(uint32_t base_address, uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint8_t color) {
    for (uint8_t dy = 0; dy < h && (y + dy) < MATRIX32_HEIGHT; dy++) {
        matrix32_draw_hline(base_address, x, x + w - 1, y + dy, color);
    }
}

// ============================================================================
// Debug Functions
// ============================================================================

void matrix32_print_info(uint32_t base_address) {
    uint32_t control = MATRIX32_READ_REG(base_address, MATRIX32_CONTROL_REG_OFFSET);
    uint32_t pattern = MATRIX32_READ_REG(base_address, MATRIX32_PATTERN_REG_OFFSET);
    uint32_t status = matrix32_get_status(base_address);

    printf("\n=== Matrix32 LED Status ===\n");
    printf("Base Address: 0x%08X\n", (unsigned int)base_address);
    printf("\nRegisters:\n");
    printf("  CONTROL (0x00): 0x%08X\n", (unsigned int)control);
    printf("  PATTERN (0x04): 0x%08X\n", (unsigned int)pattern);
    printf("  STATUS  (0x10): 0x%08X\n", (unsigned int)status);
    printf("\nDecoded Status:\n");
    printf("  Enabled: %s\n", (status & 0x01) ? "YES" : "NO");
    printf("  Mode: %s\n", (status & 0x02) ? "PATTERN" : "FRAMEBUFFER");
    printf("  Pattern: %u\n", (unsigned int)((status >> 2) & 0x07));
    printf("  Cache Valid: %s\n", cache_valid ? "YES" : "NO");
    printf("===========================\n\n");
}

// ============================================================================
// Demo Functions
// ============================================================================

void demo_single_pixel(void) {
    printf(">>> Demo 1: Enkele pixel aan/uit <<<\n");
    matrix32_clear(MATRIX_BASE);

    printf("  Rode pixel aan op (16, 16)\n");
    matrix32_set_pixel(MATRIX_BASE, 16, 16, 1, 0, 0);
    usleep(2000000);

    printf("  Pixel uit\n");
    matrix32_set_pixel(MATRIX_BASE, 16, 16, 0, 0, 0);
    usleep(1000000);
}

void demo_rgb_colors(void) {
    printf("\n>>> Demo 2: RGB kleuren <<<\n");
    matrix32_clear(MATRIX_BASE);

    printf("  Rode pixel (5, 5)\n");
    matrix32_set_pixel(MATRIX_BASE, 5, 5, 1, 0, 0);

    printf("  Groene pixel (15, 5)\n");
    matrix32_set_pixel(MATRIX_BASE, 15, 5, 0, 1, 0);

    printf("  Blauwe pixel (25, 5)\n");
    matrix32_set_pixel(MATRIX_BASE, 25, 5, 0, 0, 1);

    printf("  Witte pixel (15, 15)\n");
    matrix32_set_pixel(MATRIX_BASE, 15, 15, 1, 1, 1);

    usleep(3000000);
}

void demo_fill_colors(void) {
    printf("\n>>> Demo 3: Vul hele matrix <<<\n");

    const char* color_names[] = {"Zwart", "Blauw", "Groen", "Cyaan",
                                  "Rood", "Magenta", "Geel", "Wit"};

    for (uint8_t color = 1; color < 8; color++) {
        printf("  %s (kleur %u)\n", color_names[color], (unsigned int)color);
        matrix32_fill(MATRIX_BASE, color);
        usleep(1000000);
    }

    printf("  Vierkant in midden (geel)\n");
    matrix32_fill_rect(MATRIX_BASE, 12, 12, 8, 8, COLOR_YELLOW);
    usleep(2000000);
}

void demo_bouncing_pixel(void) {
    printf("\n>>> Demo 4: Bouncing Pixel <<<\n");
    matrix32_clear(MATRIX_BASE);

    int8_t x = 0, y = 0;
    int8_t dx = 1, dy = 1;
    uint8_t color_idx = COLOR_RED;

    for (int i = 0; i < 200; i++) {
        matrix32_set_pixel_color(MATRIX_BASE, x, y, COLOR_BLACK);

        x += dx;
        y += dy;

        if (x <= 0 || x >= 31) {
            dx = -dx;
            color_idx = (color_idx % 7) + 1;
        }
        if (y <= 0 || y >= 31) {
            dy = -dy;
            color_idx = (color_idx % 7) + 1;
        }

        matrix32_set_pixel_color(MATRIX_BASE, x, y, color_idx);
        usleep(50000);
    }
}

void demo_gradients(void) {
    printf("\n>>> Demo 5: Gradient Patterns <<<\n");

    printf("  Verticale gradient (rood-groen)\n");
    for (uint8_t y = 0; y < 32; y++) {
        uint8_t color = (y < 16) ? COLOR_RED : COLOR_GREEN;
        matrix32_draw_hline(MATRIX_BASE, 0, 31, y, color);
    }
    usleep(2000000);

    printf("  Horizontale gradient (blauw-geel)\n");
    for (uint8_t x = 0; x < 32; x++) {
        uint8_t color = (x < 16) ? COLOR_BLUE : COLOR_YELLOW;
        matrix32_draw_vline(MATRIX_BASE, x, 0, 31, color);
    }
    usleep(2000000);
}

void demo_checkerboard(void) {
    printf("\n>>> Demo 6: Checkerboard <<<\n");

    for (uint8_t y = 0; y < 32; y++) {
        for (uint8_t x = 0; x < 32; x++) {
            uint8_t color = ((x + y) % 2 == 0) ? COLOR_WHITE : COLOR_BLACK;
            matrix32_set_pixel_color(MATRIX_BASE, x, y, color);
        }
    }
    usleep(2000000);
}

void demo_test_patterns(void) {
    printf("\n>>> Demo 7: Hardware Test Patterns <<<\n");
    printf("  Switching to hardware test patterns...\n");

    matrix32_set_mode(MATRIX_BASE, MATRIX32_CTRL_MODE_PATTERN);

    const char* pattern_names[] = {
        "Checkerboard", "Horizontal", "Vertical", "All On", "Red Gradient"
    };

    for (uint8_t pattern = 0; pattern < 5; pattern++) {
        printf("  Pattern %u: %s\n", (unsigned int)pattern, pattern_names[pattern]);
        matrix32_set_pattern(MATRIX_BASE, (matrix32_pattern_t)pattern);
        usleep(2000000);
    }

    printf("  Switching back to framebuffer mode...\n");
    matrix32_set_mode(MATRIX_BASE, MATRIX32_CTRL_MODE_FB);
}

// ============================================================================
// Main Function
// ============================================================================

int main(void) {
    printf("\n========================================\n");
    printf(" 32x32 RGB LED MATRIX DEMO\n");
    printf(" DE1-SoC + Platform Designer\n");
    printf("========================================\n\n");

    printf("Initializing matrix hardware...\n");
    matrix32_init(MATRIX_BASE);
    matrix32_set_mode(MATRIX_BASE, MATRIX32_CTRL_MODE_FB);
    matrix32_enable(MATRIX_BASE, 1);
    printf("Matrix ready! Hardware is scanning...\n\n");

    matrix32_print_info(MATRIX_BASE);

    while (1) {
        demo_single_pixel();
        demo_rgb_colors();
        demo_fill_colors();
        demo_bouncing_pixel();
        demo_gradients();
        demo_checkerboard();
        demo_test_patterns();

        matrix32_print_info(MATRIX_BASE);

        printf("\n========================================\n");
        printf("  Demo cycle complete! Repeating...\n");
        printf("========================================\n\n");

        usleep(2000000);
    }

    return 0;
}
