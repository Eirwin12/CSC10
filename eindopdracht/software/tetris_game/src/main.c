#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_timer_regs.h"
#include "sys/alt_irq.h"

#include "tetris_game.h"
#include "graphics.h"
#include "input.h"

// Global variabelen
static GameState game;
static volatile uint32_t system_tick = 0;
static volatile bool update_needed = false;

// Timer ISR
static void timer_isr(void* context) {
    // Clear interrupt
    IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_0_BASE, 0);
    
    system_tick++;
    
    // Update game elke 500ms (zwaartekracht)
    if (system_tick % 500 == 0) {
        update_needed = true;
    }
}

// Render functie
void render_game(const GameState* game) {
    // Clear screen
    clear_screen(COLOR_BLACK);
    
    // Draw board
    for (int y = 0; y < BOARD_HEIGHT; y++) {
        for (int x = 0; x < BOARD_WIDTH; x++) {
            if (game->board[y][x] != 0) {
                RGB color = {
                    .r = (game->board[y][x] >> 16) & 0xFF,
                    .g = (game->board[y][x] >> 8) & 0xFF,
                    .b = game->board[y][x] & 0xFF
                };
                draw_pixel(x, y, color);
            }
        }
    }
    
    // Draw current piece
    for (int py = 0; py < TETROMINO_SIZE; py++) {
        for (int px = 0; px < TETROMINO_SIZE; px++) {
            if (game->current_piece.shape[py][px]) {
                int screen_x = game->piece_x + px;
                int screen_y = game->piece_y + py;
                
                if (screen_x >= 0 && screen_x < BOARD_WIDTH &&
                    screen_y >= 0 && screen_y < BOARD_HEIGHT) {
                    RGB color = {
                        .r = (game->current_piece.color >> 16) & 0xFF,
                        .g = (game->current_piece.color >> 8) & 0xFF,
                        .b = game->current_piece.color & 0xFF
                    };
                    draw_pixel(screen_x, screen_y, color);
                }
            }
        }
    }
}

int main(void) {
    printf("Tetris Game Starting...\n");
    
    // Initialize subsystems
    graphics_init();
    input_init();
    game_init(&game);
    
    // Setup timer interrupt
    IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, 
        ALTERA_AVALON_TIMER_CONTROL_STOP_MSK);
    
    IOWR_ALTERA_AVALON_TIMER_PERIODL(TIMER_0_BASE, 
        TIMER_0_FREQ & 0xFFFF);
    IOWR_ALTERA_AVALON_TIMER_PERIODH(TIMER_0_BASE, 
        (TIMER_0_FREQ >> 16) & 0xFFFF);
    
    alt_ic_isr_register(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, 
                        TIMER_0_IRQ, 
                        timer_isr, 
                        NULL, 
                        NULL);
    
    IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE,
        ALTERA_AVALON_TIMER_CONTROL_ITO_MSK |
        ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |
        ALTERA_AVALON_TIMER_CONTROL_START_MSK);
    
    printf("Game initialized, starting main loop\n");
    
    // Main game loop
    static uint8_t last_buttons = 0xFF;
    
    while (!game.game_over) {
        // Read input
        uint8_t buttons = read_buttons();
        
        // Detect button press (edge detection, active low)
        uint8_t pressed = (~buttons) & (last_buttons);
        
        if (pressed & BUTTON_0) {
            // Left
            move_piece(&game, -1, 0);
            render_game(&game);
        }
        
        if (pressed & BUTTON_1) {
            // Right
            move_piece(&game, 1, 0);
            render_game(&game);
        }
        
        if (pressed & BUTTON_2) {
            // Rotate clockwise
            rotate_piece(&game, true);
            render_game(&game);
        }
        
        if (pressed & BUTTON_3) {
            // Rotate counter-clockwise
            rotate_piece(&game, false);
            render_game(&game);
        }
        
        last_buttons = buttons;
        
        // Gravity update
        if (update_needed) {
            update_needed = false;
            
            if (!move_piece(&game, 0, 1)) {
                // Piece landed
                lock_piece(&game);
                clear_lines(&game);
                spawn_new_piece(&game);
            }
            
            render_game(&game);
        }
        
        // Get color from switches
        RGB user_color = get_color_from_switches();
        game.current_piece.color = rgb_to_word(user_color);
        
        // Small delay
        for (volatile int i = 0; i < 10000; i++);
    }
    
    printf("Game Over!\n");
    
    // Game over screen
    draw_rect(0, 0, BOARD_WIDTH, BOARD_HEIGHT, COLOR_RED);
    
    return 0;
}
