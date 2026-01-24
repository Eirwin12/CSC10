/**
 * @file example_main.c
 * @brief EENVOUDIG Voorbeeld: RGB LEDs aan/uit zetten
 * @author Mitch - CSC10 Project
 * @date 2026
 * 
 * ============================================================================
 * BELANGRIJK: VHDL doet het zware werk!
 * ============================================================================
 * Deze C code is SUPER SIMPEL omdat de VHDL hardware alles automatisch doet:
 *   ✓ Matrix scanning (hardware loop door alle rijen)
 *   ✓ Timing generatie (CLK, LAT, OE pulsen)
 *   ✓ Framebuffer opslag (384 bytes in FPGA memory)
 *   ✓ Real-time refresh (constant ververst, geen CPU nodig!)
 * 
 * Jij hoeft alleen maar te zeggen: "Zet pixel (x,y) op kleur RGB"
 * De hardware zorgt dat het direct zichtbaar wordt!
 * ============================================================================
 */

#include <stdio.h>
#include <unistd.h>
#include "system.h"
#include "matrix32_led.h"

// Base address van de matrix component (uit system.h na Platform Designer)
#ifndef MATRIX32_LED_0_BASE
    #define MATRIX32_LED_0_BASE 0x00010000  // Pas aan naar jouw system.h waarde!
#endif

#define MATRIX_BASE MATRIX32_LED_0_BASE

int main(void) {
    printf("\n========================================\n");
    printf(" EENVOUDIGE RGB LED MATRIX DEMO\n");
    printf(" VHDL doet matrix scanning\n");
    printf(" C code zet alleen pixels aan/uit\n");
    printf("========================================\n\n");
    
    // ========================================================================
    // STAP 1: Initialisatie (één keer bij opstarten)
    // ========================================================================
    printf("Initializing matrix...\n");
    matrix32_init(MATRIX_BASE);                           // Clear framebuffer
    matrix32_set_mode(MATRIX_BASE, 0);                    // 0 = Framebuffer mode
    matrix32_enable(MATRIX_BASE, 1);                      // Enable hardware
    printf("Matrix ready! Hardware is nu aan het scannen...\n\n");
    
    while (1) {
        // ====================================================================
        // DEMO 1: Eenvoudig - één pixel aan/uit
        // ====================================================================
        printf(">>> Demo 1: Enkele pixel aan/uit <<<\n");
        matrix32_clear(MATRIX_BASE);  // Alles uit
        
        // Zet één rode pixel aan (midden van matrix)
        printf("  Rood pixel aan op (16, 16)\n");
        matrix32_set_pixel(MATRIX_BASE, 16, 16, 1, 0, 0);  // R=1, G=0, B=0
        usleep(2000000);  // 2 seconden wachten
        
        // Zet uit
        printf("  Pixel uit\n");
        matrix32_set_pixel(MATRIX_BASE, 16, 16, 0, 0, 0);  // R=0, G=0, B=0
        usleep(1000000);
        
        // ====================================================================
        // DEMO 2: Meerdere pixels - verschillende kleuren
        // ====================================================================
        printf("\n>>> Demo 2: RGB kleuren <<<\n");
        matrix32_clear(MATRIX_BASE);
        
        // Rood pixel
        printf("  Rode pixel (5, 5)\n");
        matrix32_set_pixel(MATRIX_BASE, 5, 5, 1, 0, 0);
        
        // Groene pixel
        printf("  Groene pixel (15, 5)\n");
        matrix32_set_pixel(MATRIX_BASE, 15, 5, 0, 1, 0);
        
        // Blauwe pixel
        printf("  Blauwe pixel (25, 5)\n");
        matrix32_set_pixel(MATRIX_BASE, 25, 5, 0, 0, 1);
        
        // Wit pixel (alle kleuren aan)
        printf("  Witte pixel (15, 15)\n");
        matrix32_set_pixel(MATRIX_BASE, 15, 15, 1, 1, 1);
        
        usleep(3000000);  // 3 seconden
        
        // ====================================================================
        // DEMO 3: Hele matrix vullen met één kleur
        // ====================================================================
        printf("\n>>> Demo 3: Vul hele matrix <<<\n");
        
        const char* color_names[] = {"Zwart", "Blauw", "Groen", "Cyaan", 
                                      "Rood", "Magenta", "Geel", "Wit"};
        
        for (uint8_t color = 1; color < 8; color++) {  // Skip black
            printf("  %s (kleur %d)\n", color_names[color], color);
            matrix32_fill(MATRIX_BASE, color);  // Vul hele matrix
            usleep(1000000);  // 1 seconde per kleur
        }
        usleep(1000000);
        
        // Filled square in center
        matrix32_fill_rect(MATRIX_BASE, 12, 12, 8, 8, MATRIX32_COLOR_YELLOW);
        usleep(2000000);
        
        // ================================================================
        // Demo 4: Animatie - Bouncing pixel
        // ================================================================
        printf("\n>>> Demo 4: Bouncing Pixel <<<\n");
        matrix32_clear(MATRIX_BASE);
        
        int8_t x = 0, y = 0;
        int8_t dx = 1, dy = 1;
        uint8_t color_idx = 1;
        
        for (int i = 0; i < 200; i++) {
            // Clear old position
            matrix32_set_pixel_color(MATRIX_BASE, x, y, MATRIX32_COLOR_BLACK);
            
            // Update position
            x += dx;
            y += dy;
            
            // Bounce off walls
            if (x <= 0 || x >= 31) {
                dx = -dx;
                color_idx = (color_idx % 7) + 1;  // Change color
            }
            if (y <= 0 || y >= 31) {
                dy = -dy;
                color_idx = (color_idx % 7) + 1;
            }
            
            // Draw new position
            matrix32_set_pixel_color(MATRIX_BASE, x, y, color_idx);
            
            usleep(50000);  // 50ms
        }
        
        // ================================================================
        // Demo 5: Gradient patterns
        // ================================================================
        printf("\n>>> Demo 5: Gradient Patterns <<<\n");
        
        // Vertical gradient (red-green)
        for (uint8_t y = 0; y < 32; y++) {
            uint8_t color = (y < 16) ? MATRIX32_COLOR_RED : MATRIX32_COLOR_GREEN;
            matrix32_draw_hline(MATRIX_BASE, 0, 31, y, color);
        }
        usleep(2000000);
        
        // Horizontal gradient (blue-yellow)
        for (uint8_t x = 0; x < 32; x++) {
            uint8_t color = (x < 16) ? MATRIX32_COLOR_BLUE : MATRIX32_COLOR_YELLOW;
            matrix32_draw_vline(MATRIX_BASE, x, 0, 31, color);
        }
        usleep(2000000);
        
        // ================================================================
        // Demo 6: Checkerboard patroon
        // ================================================================
        printf("\n>>> Demo 6: Checkerboard <<<\n");
        
        for (uint8_t y = 0; y < 32; y++) {
            for (uint8_t x = 0; x < 32; x++) {
                uint8_t color = ((x + y) % 2 == 0) ? MATRIX32_COLOR_WHITE : MATRIX32_COLOR_BLACK;
                matrix32_set_pixel_color(MATRIX_BASE, x, y, color);
            }
        }
        usleep(2000000);
        
        // ================================================================
        // Demo 7: Test pattern mode vergelijking
        // ================================================================
        printf("\n>>> Demo 7: Test Pattern Mode <<<\n");
        printf("  Switching to hardware test patterns...\n");
        
        matrix32_set_mode(MATRIX_BASE, MATRIX32_CTRL_MODE_PATTERN);
        
        for (uint8_t pattern = 0; pattern < 5; pattern++) {
            printf("  Pattern %d\n", pattern);
            matrix32_set_pattern(MATRIX_BASE, (matrix32_pattern_t)pattern);
            usleep(2000000);
        }
        
        // Back to framebuffer mode
        printf("  Switching back to framebuffer mode...\n");
        matrix32_set_mode(MATRIX_BASE, MATRIX32_CTRL_MODE_FB);
        
        // ================================================================
        // Status Info
        // ================================================================
        printf("\n");
        matrix32_print_info(MATRIX_BASE);
        
        printf("\n========================================\n");
        printf("  Demo cycle complete! Repeating...\n");
        printf("========================================\n\n");
        
        usleep(2000000);
    }
    
    return 0;
}
