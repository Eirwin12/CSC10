/*
 * key_control_test.c - Interactieve besturing van 2x2 blok op Matrix32 LED
 * 
 * Bestuur een 2x2 blauw blok op de Matrix32 LED met de DE1-SoC hardware knoppen:
 * - KEY0: Blok naar beneden verplaatsen
 * - KEY1: Blok naar boven verplaatsen
 * - KEY2: Blok naar rechts verplaatsen
 * - KEY3: Blok naar links verplaatsen
 * 
 * Compileren: arm-linux-gnueabihf-gcc -o key_control_test key_control_test.c
 * Uitvoeren op DE1-SoC: sudo ./key_control_test
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

/* Hardware adressen */
#define HPS_LW_BRIDGE_BASE  0xFF200000
#define MATRIX32_OFFSET     0x00000060
#define KEY_OFFSET          0x00000080
#define MATRIX32_BASE       (HPS_LW_BRIDGE_BASE + MATRIX32_OFFSET)
#define KEY_BASE            (HPS_LW_BRIDGE_BASE + KEY_OFFSET)
#define MATRIX32_SPAN       0x20
#define KEY_SPAN            0x10

#define PAGE_SIZE           4096
#define PAGE_MASK           (PAGE_SIZE - 1)

/* Matrix32 LED Controller registers */

#define REG_CONTROL    0x00  // Control register (enable, reset, update)
#define REG_PATTERN    0x04  // Pattern select register (hardware patronen)
#define REG_FB_ADDR    0x08  // Framebuffer address register (byte selectie 0-383)
#define REG_FB_DATA    0x0C  // Framebuffer data register (8-bit data schrijven)

/* Control register bits - functionaliteit van CTRL register */
#define CTRL_ENABLE    (1 << 0)  // Bit 0: LED controller inschakelen
#define CTRL_RESET     (1 << 1)  // Bit 1: Framebuffer resetten naar 0
#define CTRL_UPDATE    (1 << 2)  // Bit 2: Framebuffer naar LED matrix kopiëren

/* Pattern modes - hardware test patronen (niet gebruikt in framebuffer mode) */
#define PATTERN_OFF    0  // Patroon uit: gebruik framebuffer mode

/* KEY buttons - Register offsets */

#define KEY_DATA       0x00  // DATA register: huidige staat van knoppen (actief laag)
#define KEY_EDGECAP    0x0C  // EDGECAP register: welke knoppen zijn ingedrukt (edge detection)

/* KEY button masks - bit posities voor elke knop */
#define KEY0_MASK      (1 << 0)  // Bit 0: KEY0 (beneden)
#define KEY1_MASK      (1 << 1)  // Bit 1: KEY1 (boven)
#define KEY2_MASK      (1 << 2)  // Bit 2: KEY2 (rechts)
#define KEY3_MASK      (1 << 3)  // Bit 3: KEY3 (links)

/* Globale pointers naar gemapte hardware registers */
volatile uint32_t *matrix32_regs = NULL;
volatile uint32_t *key_regs = NULL;

/* Software framebuffer (384 bytes: 128 RED + 128 GREEN + 128 BLUE) */
static uint8_t framebuffer[384];

/* Matrix32 functies */


/* Schrijf een waarde naar een Matrix32 register */
void write_matrix_reg(uint32_t offset, uint32_t value) {
    matrix32_regs[offset / 4] = value;  // Delen door 4 omdat pointer uint32_t is
}

/* Lees een waarde uit een Matrix32 register */
uint32_t read_matrix_reg(uint32_t offset) {
    return matrix32_regs[offset / 4];
}

/* Schakel de Matrix32 LED controller in */
void matrix32_enable(void) {
    write_matrix_reg(REG_CONTROL, CTRL_ENABLE);
}

/* Reset de Matrix32 controller en wis framebuffer */
void matrix32_reset(void) {
    write_matrix_reg(REG_CONTROL, CTRL_RESET);  // Hardware reset activeren
    usleep(10000);  // Wacht 10ms voor reset voltooiing
    write_matrix_reg(REG_CONTROL, 0);  // Reset deactiveren
}

/* Selecteer een hardware test patroon (PATTERN_OFF = framebuffer mode) */
void matrix32_set_pattern(uint32_t pattern) {
    write_matrix_reg(REG_PATTERN, pattern);
    write_matrix_reg(REG_CONTROL, CTRL_ENABLE | CTRL_UPDATE);
}

/* Zet een pixel op (x,y) met RGB kleur - gebruikt read-modify-write voor bit-packed framebuffer */
void matrix32_set_pixel(uint8_t x, uint8_t y, uint8_t r, uint8_t g, uint8_t b) {
    if (x >= 32 || y >= 32) return;
    
    uint16_t pixel_index = y * 32 + x;
    uint8_t byte_addr = pixel_index / 8;
    uint8_t bit_offset = pixel_index % 8;
    uint8_t bit_mask = 1 << bit_offset;
    
    // Update framebuffer en schrijf naar hardware
    if (r) framebuffer[byte_addr] |= bit_mask;
    else   framebuffer[byte_addr] &= ~bit_mask;
    write_matrix_reg(REG_FB_ADDR, byte_addr);
    write_matrix_reg(REG_FB_DATA, framebuffer[byte_addr]);
    
    if (g) framebuffer[128 + byte_addr] |= bit_mask;
    else   framebuffer[128 + byte_addr] &= ~bit_mask;
    write_matrix_reg(REG_FB_ADDR, 128 + byte_addr);
    write_matrix_reg(REG_FB_DATA, framebuffer[128 + byte_addr]);
    
    if (b) framebuffer[256 + byte_addr] |= bit_mask;
    else   framebuffer[256 + byte_addr] &= ~bit_mask;
    write_matrix_reg(REG_FB_ADDR, 256 + byte_addr);
    write_matrix_reg(REG_FB_DATA, framebuffer[256 + byte_addr]);
}

/* Teken een 2x2 blok met linkerbovenhoek op (x,y) */
void matrix32_set_block_2x2(uint8_t x, uint8_t y, uint8_t r, uint8_t g, uint8_t b) {
    for (int dy = 0; dy < 2; dy++) {
        for (int dx = 0; dx < 2; dx++) {
            matrix32_set_pixel(x + dx, y + dy, r, g, b);
        }
    }
}

void matrix32_update(void) {
    uint32_t ctrl = read_matrix_reg(REG_CONTROL);
    write_matrix_reg(REG_CONTROL, ctrl | CTRL_UPDATE);
}

void matrix32_clear_all(void) {
    for (int i = 0; i < 384; i++) {
        framebuffer[i] = 0;
    }
    for (int i = 0; i < 384; i++) {
        write_matrix_reg(REG_FB_ADDR, i);
        write_matrix_reg(REG_FB_DATA, 0);
    }
    matrix32_update();
}

/* KEY functies */

/* Schrijf een waarde naar een KEY register */
void write_key_reg(uint32_t offset, uint32_t value) {
    key_regs[offset / 4] = value;  // Delen door 4 omdat pointer uint32_t is
}

/* Lees een waarde uit een KEY register */
uint32_t read_key_reg(uint32_t offset) {
    return key_regs[offset / 4];
}

/* Lees welke knoppen zijn ingedrukt (edge capture)
 * Retourneert bitmask van ingedrukte knoppen (KEY0_MASK, KEY1_MASK, etc.)
 * 
 * Werking:
 *   - EDGECAP register vangt knopdrukkingen op (edge detection)
 *   - Eenmaal gelezen wordt register automatisch gewist
 *   - Voorkomt dat dezelfde druk meerdere keren wordt gedetecteerd
 */
uint32_t read_key_press(void) {
    // Lees edge capture register (welke knoppen zijn ingedrukt)
    uint32_t edge = read_key_reg(KEY_EDGECAP);
    
    // Wis edge capture door dezelfde waarde terug te schrijven
    if (edge != 0) {
        write_key_reg(KEY_EDGECAP, edge);
    }
    
    return edge;  // Bitmask van ingedrukte knoppen
}

int main(int argc, char **argv) {
    int fd;
    void *virtual_base;
    off_t page_aligned_addr;
    size_t page_offset;
    
    printf("=================================================\n");
    printf("Matrix32 LED - Interactieve KEY Besturing\n");
    printf("=================================================\n\n");
    printf("Besturing:\n");
    printf("  KEY0: Blok naar BENEDEN\n");
    printf("  KEY1: Blok naar BOVEN\n");
    printf("  KEY2: Blok naar RECHTS\n");
    printf("  KEY3: Blok naar LINKS\n");
    printf("  Ctrl+C: Afsluiten\n\n");
    
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("Fout bij openen /dev/mem");
        printf("Tip: Draai met sudo!\n");
        return 1;
    }
    
    // Map Matrix32 registers

    page_aligned_addr = MATRIX32_BASE & ~PAGE_MASK;
    page_offset = MATRIX32_BASE & PAGE_MASK;
    
    virtual_base = mmap(NULL, 
                       MATRIX32_SPAN + page_offset, 
                       PROT_READ | PROT_WRITE, 
                       MAP_SHARED, 
                       fd, 
                       page_aligned_addr);
    
    if (virtual_base == MAP_FAILED) {
        perror("Failed to mmap Matrix32");
        close(fd);
        return 1;
    }
    
    matrix32_regs = (volatile uint32_t *)((char *)virtual_base + page_offset);
    printf("Matrix32 mapped at physical 0x%08X\n", MATRIX32_BASE);
    
    /* Map KEY registers */
    page_aligned_addr = KEY_BASE & ~PAGE_MASK;
    page_offset = KEY_BASE & PAGE_MASK;
    
    void *key_virtual_base = mmap(NULL, 
                                   KEY_SPAN + page_offset, 
                                   PROT_READ | PROT_WRITE, 
                                   MAP_SHARED, 
                                   fd, 
                                   page_aligned_addr);
    
    if (key_virtual_base == MAP_FAILED) {
        perror("Failed to mmap KEY");
        munmap(virtual_base, MATRIX32_SPAN + (MATRIX32_BASE & PAGE_MASK));
        close(fd);
        return 1;
    }
    
    key_regs = (volatile uint32_t *)((char *)key_virtual_base + page_offset);
    printf("KEY mapped at physical 0x%08X\n", KEY_BASE);
    
    // Debug: lees KEY register waarden
    printf("\nDEBUG: Initial KEY register values:\n");
    printf("  KEY_DATA:    0x%08X\n", read_key_reg(KEY_DATA));
    printf("  KEY_EDGECAP: 0x%08X\n\n", read_key_reg(KEY_EDGECAP));
    
    /* Initialize Matrix32 */
    matrix32_reset();
    matrix32_set_pattern(PATTERN_OFF); // Framebuffer mode
    matrix32_enable();
    matrix32_clear_all();
    
    /* Clear any pending KEY edge captures */
    write_key_reg(KEY_EDGECAP, 0x0F);
    
    /* Block position (start in center) - top-left corner of 2x2 block */
    int block_x = 15;
    int block_y = 15;
    
    /* Block color (blue) */
    uint8_t color_r = 0;
    uint8_t color_g = 0;
    uint8_t color_b = 1;
    
    printf("Starting interactive control (2x2 blue block)...\n");
    printf("Initial position: (%d, %d)\n\n", block_x, block_y);
    
    // Draw initial 2x2 block
    matrix32_set_block_2x2(block_x, block_y, color_r, color_g, color_b);
    matrix32_update();
    
    /* Main control loop */
    int loop_count = 0;
    while (1) {
        // Debug: print KEY status elke seconde
        if (loop_count % 100 == 0) {
            uint32_t key_data = read_key_reg(KEY_DATA);
            uint32_t key_edge = read_key_reg(KEY_EDGECAP);
            printf("DEBUG [%d]: KEY_DATA=0x%08X  KEY_EDGECAP=0x%08X\n", 
                   loop_count/100, key_data, key_edge);
        }
        loop_count++;
        
        // Check for key presses
        uint32_t keys = read_key_press();
        
        if (keys != 0) {
            printf("DEBUG: Key press detected! keys=0x%08X ", keys);
            printf("(KEY0=%d KEY1=%d KEY2=%d KEY3=%d)\n",
                   (keys & KEY0_MASK) ? 1 : 0,
                   (keys & KEY1_MASK) ? 1 : 0,
                   (keys & KEY2_MASK) ? 1 : 0,
                   (keys & KEY3_MASK) ? 1 : 0);
            
            // Update position based on key press FIRST
            if (keys & KEY0_MASK) {
                // KEY0: Down (max 30 omdat 2x2 blok tot y+1 gaat)
                block_y++;
                if (block_y > 30) block_y = 30;
                printf("KEY0: Moving DOWN  -> Position (%2d, %2d)\n", block_x, block_y);
            }
            
            if (keys & KEY1_MASK) {
                // KEY1: Up
                block_y--;
                if (block_y < 0) block_y = 0;
                printf("KEY1: Moving UP    -> Position (%2d, %2d)\n", block_x, block_y);
            }
            
            if (keys & KEY2_MASK) {
                // KEY2: Right (max 30 omdat 2x2 blok tot x+1 gaat)
                block_x++;
                if (block_x > 30) block_x = 30;
                printf("KEY2: Moving RIGHT -> Position (%2d, %2d)\n", block_x, block_y);
            }
            
            if (keys & KEY3_MASK) {
                // KEY3: Left
                block_x--;
                if (block_x < 0) block_x = 0;
                printf("KEY3: Moving LEFT  -> Position (%2d, %2d)\n", block_x, block_y);
            }
            
            // Clear entire display first
            matrix32_clear_all();
            
            // Draw 2x2 block at new position
            matrix32_set_block_2x2(block_x, block_y, color_r, color_g, color_b);
            matrix32_update();
        }
        
        // Small delay to prevent excessive CPU usage
        usleep(10000); // 10ms
    }
    
    /* Cleanup (unreachable, but good practice) */
    matrix32_clear_all();
    munmap(virtual_base, MATRIX32_SPAN + (MATRIX32_BASE & PAGE_MASK));
    munmap(key_virtual_base, KEY_SPAN + (KEY_BASE & PAGE_MASK));
    close(fd);
    
    return 0;
}
