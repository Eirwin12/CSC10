/**
 * @file matrix32_led.h
 * @brief Driver header voor 32x32 RGB LED Matrix Controller met Framebuffer
 * @author Mitch - CSC10 Project
 * @date 2026
 * 
 * EENVOUDIGE C API voor LED Matrix Control
 * =========================================
 * 
 * Deze header biedt een eenvoudige interface om RGB LEDs aan/uit te zetten.
 * 
 * VHDL HARDWARE (automatisch door FPGA):
 *   ✓ Matrix scanning (16 gemultiplexte rijen)
 *   ✓ HUB75 protocol timing (CLK, LAT, OE, RGB data)
 *   ✓ Framebuffer opslag in FPGA (384 bytes)
 *   ✓ Automatische refresh (1kHz+)
 * 
 * C SOFTWARE (wat jij doet):
 *   → matrix32_set_pixel(x, y, r, g, b)  - Zet één pixel aan/uit
 *   → matrix32_clear()                    - Alle pixels uit
 *   → matrix32_fill(color)                - Alle pixels één kleur
 *   → matrix32_draw_line/rect/etc.        - Teken vormen
 * 
 * GEBRUIK:
 *   uint32_t matrix_base = MATRIX32_LED_BASE;  // Van system.h
 *   matrix32_init(matrix_base);
 *   matrix32_set_mode(matrix_base, 0);         // 0=framebuffer mode
 *   matrix32_enable(matrix_base, 1);           // Enable
 *   matrix32_set_pixel(matrix_base, 10, 10, 1, 0, 0);  // Rood pixel op (10,10)
 *   // Hardware toont direct de pixel op de matrix!
 */

#ifndef MATRIX32_LED_H
#define MATRIX32_LED_H

#include <stdint.h>
#include <io.h>

// ============================================================================
// Register Offsets (relatief aan base address)
// ============================================================================
#define MATRIX32_CONTROL_REG_OFFSET    0x00  /**< Control register offset */
#define MATRIX32_PATTERN_REG_OFFSET    0x04  /**< Pattern register offset */
#define MATRIX32_FB_ADDR_REG_OFFSET    0x08  /**< Framebuffer address offset */
#define MATRIX32_FB_DATA_REG_OFFSET    0x0C  /**< Framebuffer data offset */
#define MATRIX32_STATUS_REG_OFFSET     0x10  /**< Status register offset (read-only) */

// ============================================================================
// Control Register Bit Masks
// ============================================================================
#define MATRIX32_CTRL_ENABLE_MASK      0x00000001  /**< Enable bit mask */
#define MATRIX32_CTRL_MODE_MASK        0x00000002  /**< Mode bit mask (0=FB, 1=pattern) */
#define MATRIX32_CTRL_MODE_FB          0           /**< Mode: Framebuffer */
#define MATRIX32_CTRL_MODE_PATTERN     1           /**< Mode: Test pattern */

// ============================================================================
// Matrix Dimensions
// ============================================================================
#define MATRIX32_WIDTH                 32   /**< Matrix width in pixels */
#define MATRIX32_HEIGHT                32   /**< Matrix height in pixels */
#define MATRIX32_FRAMEBUFFER_SIZE      384  /**< Framebuffer size in bytes */

// ============================================================================
// Pattern Register Values
// ============================================================================
typedef enum {
    MATRIX32_PATTERN_CHECKERBOARD = 0,  /**< Checkerboard pattern */
    MATRIX32_PATTERN_HORIZONTAL   = 1,  /**< Horizontal lines */
    MATRIX32_PATTERN_VERTICAL     = 2,  /**< Vertical lines */
    MATRIX32_PATTERN_ALL_ON       = 3,  /**< All LEDs on (white) */
    MATRIX32_PATTERN_RED_GRADIENT = 4,  /**< Red gradient */
    MATRIX32_PATTERN_CUSTOM_5     = 5,  /**< Reserved */
    MATRIX32_PATTERN_CUSTOM_6     = 6,  /**< Reserved */
    MATRIX32_PATTERN_ALL_OFF      = 7   /**< All LEDs off */
} matrix32_pattern_t;

// ============================================================================
// Color Definitions (1-bit per channel)
// ============================================================================
#define MATRIX32_COLOR_BLACK     0  /**< RGB: 000 */
#define MATRIX32_COLOR_BLUE      1  /**< RGB: 001 */
#define MATRIX32_COLOR_GREEN     2  /**< RGB: 010 */
#define MATRIX32_COLOR_CYAN      3  /**< RGB: 011 */
#define MATRIX32_COLOR_RED       4  /**< RGB: 100 */
#define MATRIX32_COLOR_MAGENTA   5  /**< RGB: 101 */
#define MATRIX32_COLOR_YELLOW    6  /**< RGB: 110 */
#define MATRIX32_COLOR_WHITE     7  /**< RGB: 111 */

// ============================================================================
// Register Access Macros
// ============================================================================

/**
 * @brief Write to a matrix register
 */
#define MATRIX32_WRITE_REG(base, offset, value) \
    IOWR_32DIRECT((base), (offset), (value))

/**
 * @brief Read from a matrix register
 */
#define MATRIX32_READ_REG(base, offset) \
    IORD_32DIRECT((base), (offset))

// ============================================================================
// Core API Functions
// ============================================================================

/**
 * @brief Initialiseer de LED matrix controller
 * 
 * @param base_address Base address van het matrix component
 */
void matrix32_init(uint32_t base_address);

/**
 * @brief Enable of disable de matrix
 * 
 * @param base_address Base address van het matrix component
 * @param enable 1 om te enablen, 0 om te disablen
 */
void matrix32_enable(uint32_t base_address, uint8_t enable);

/**
 * @brief Schakel tussen framebuffer en test pattern mode
 * 
 * @param base_address Base address van het matrix component
 * @param mode 0=framebuffer, 1=test pattern
 */
void matrix32_set_mode(uint32_t base_address, uint8_t mode);

/**
 * @brief Stel het test patroon in (alleen in pattern mode)
 * 
 * @param base_address Base address van het matrix component
 * @param pattern Patroon om weer te geven
 */
void matrix32_set_pattern(uint32_t base_address, matrix32_pattern_t pattern);

// ============================================================================
// Framebuffer API Functions
// ============================================================================

/**
 * @brief Clear hele framebuffer (alle pixels zwart)
 * 
 * @param base_address Base address van het matrix component
 */
void matrix32_clear(uint32_t base_address);

/**
 * @brief Fill hele framebuffer met één kleur
 * 
 * @param base_address Base address van het matrix component
 * @param color Kleur (0-7, zie MATRIX32_COLOR_* defines)
 */
void matrix32_fill(uint32_t base_address, uint8_t color);

/**
 * @brief Zet individuele pixel
 * 
 * @param base_address Base address van het matrix component
 * @param x X coordinaat (0-31)
 * @param y Y coordinaat (0-31)
 * @param r Rood (0 of 1)
 * @param g Groen (0 of 1)
 * @param b Blauw (0 of 1)
 */
void matrix32_set_pixel(uint32_t base_address, uint8_t x, uint8_t y, 
                        uint8_t r, uint8_t g, uint8_t b);

/**
 * @brief Zet pixel met kleur waarde
 * 
 * @param base_address Base address van het matrix component
 * @param x X coordinaat (0-31)
 * @param y Y coordinaat (0-31)
 * @param color Kleur (0-7, zie MATRIX32_COLOR_* defines)
 */
void matrix32_set_pixel_color(uint32_t base_address, uint8_t x, uint8_t y, uint8_t color);

/**
 * @brief Get pixel kleur
 * 
 * @param base_address Base address van het matrix component
 * @param x X coordinaat (0-31)
 * @param y Y coordinaat (0-31)
 * @return Kleur waarde (0-7)
 */
uint8_t matrix32_get_pixel(uint32_t base_address, uint8_t x, uint8_t y);

// ============================================================================
// Drawing Functions
// ============================================================================

/**
 * @brief Teken horizontale lijn
 * 
 * @param base_address Base address van het matrix component
 * @param x0 Start X
 * @param x1 Eind X
 * @param y Y coordinaat
 * @param color Kleur (0-7)
 */
void matrix32_draw_hline(uint32_t base_address, uint8_t x0, uint8_t x1, uint8_t y, uint8_t color);

/**
 * @brief Teken verticale lijn
 * 
 * @param base_address Base address van het matrix component
 * @param x X coordinaat
 * @param y0 Start Y
 * @param y1 Eind Y
 * @param color Kleur (0-7)
 */
void matrix32_draw_vline(uint32_t base_address, uint8_t x, uint8_t y0, uint8_t y1, uint8_t color);

/**
 * @brief Teken rechthoek (outline)
 * 
 * @param base_address Base address van het matrix component
 * @param x Top-left X
 * @param y Top-left Y
 * @param w Width
 * @param h Height
 * @param color Kleur (0-7)
 */
void matrix32_draw_rect(uint32_t base_address, uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint8_t color);

/**
 * @brief Fill rechthoek
 * 
 * @param base_address Base address van het matrix component
 * @param x Top-left X
 * @param y Top-left Y
 * @param w Width
 * @param h Height
 * @param color Kleur (0-7)
 */
void matrix32_fill_rect(uint32_t base_address, uint8_t x, uint8_t y, uint8_t w, uint8_t h, uint8_t color);

// ============================================================================
// Status & Debug Functions
// ============================================================================

/**
 * @brief Lees het status register
 * 
 * @param base_address Base address van het matrix component
 * @return Status register waarde
 */
uint32_t matrix32_get_status(uint32_t base_address);

/**
 * @brief Check of de matrix enabled is
 * 
 * @param base_address Base address van het matrix component
 * @return 1 als enabled, 0 als disabled
 */
uint8_t matrix32_is_enabled(uint32_t base_address);

/**
 * @brief Print matrix informatie naar console (debug)
 * 
 * @param base_address Base address van het matrix component
 */
void matrix32_print_info(uint32_t base_address);

// ============================================================================
// Low-Level Framebuffer Access (voor geavanceerd gebruik)
// ============================================================================

/**
 * @brief Schrijf 8 pixels direct naar framebuffer
 * 
 * Deze functie is low-level en wordt normaal intern gebruikt.
 * Voor normale gebruik, gebruik matrix32_set_pixel().
 * 
 * @param base_address Base address van het matrix component
 * @param byte_addr Byte address (0-383)
 * @param data 8 bits (8 pixels)
 */
void matrix32_write_fb_byte(uint32_t base_address, uint16_t byte_addr, uint8_t data);

#endif // MATRIX32_LED_H
