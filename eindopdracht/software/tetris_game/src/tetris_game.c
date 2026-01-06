#include "tetris_game.h"
#include <stdlib.h>
#include <string.h>

// Tetromino shapes (4x4 grid)
static const uint8_t tetromino_shapes[TETROMINO_COUNT][4][4] = {
    // I
    {
        {0, 0, 0, 0},
        {1, 1, 1, 1},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    // O
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0}
    },
    // T
    {
        {0, 0, 0, 0},
        {0, 1, 0, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0}
    },
    // S
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {1, 1, 0, 0},
        {0, 0, 0, 0}
    },
    // Z
    {
        {0, 0, 0, 0},
        {1, 1, 0, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0}
    },
    // J
    {
        {0, 0, 0, 0},
        {1, 0, 0, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0}
    },
    // L
    {
        {0, 0, 0, 0},
        {0, 0, 1, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0}
    }
};

// Tetromino kleuren (standaard)
static const uint32_t tetromino_colors[TETROMINO_COUNT] = {
    0x00FFFF,  // I - Cyan
    0xFFFF00,  // O - Yellow
    0xFF00FF,  // T - Magenta
    0x00FF00,  // S - Green
    0xFF0000,  // Z - Red
    0x0000FF,  // J - Blue
    0xFF8800   // L - Orange
};

void game_init(GameState* game) {
    memset(game, 0, sizeof(GameState));
    game->game_over = false;
    spawn_new_piece(game);
}

void spawn_new_piece(GameState* game) {
    // Random tetromino
    TetrominoType type = rand() % TETROMINO_COUNT;
    
    game->current_type = type;
    memcpy(game->current_piece.shape, 
           tetromino_shapes[type], 
           sizeof(game->current_piece.shape));
    
    game->current_piece.width = TETROMINO_SIZE;
    game->current_piece.height = TETROMINO_SIZE;
    game->current_piece.color = tetromino_colors[type];
    
    // Start positie boven aan, midden
    game->piece_x = (BOARD_WIDTH - TETROMINO_SIZE) / 2;
    game->piece_y = 0;
    
    // Check of game over is
    if (check_collision(game, game->piece_x, game->piece_y, &game->current_piece)) {
        game->game_over = true;
    }
}

bool check_collision(GameState* game, int x, int y, const Tetromino* piece) {
    for (int py = 0; py < TETROMINO_SIZE; py++) {
        for (int px = 0; px < TETROMINO_SIZE; px++) {
            if (piece->shape[py][px]) {
                int board_x = x + px;
                int board_y = y + py;
                
                // Check bounds
                if (board_x < 0 || board_x >= BOARD_WIDTH ||
                    board_y < 0 || board_y >= BOARD_HEIGHT) {
                    return true;
                }
                
                // Check collision met geplaatste blokken
                if (game->board[board_y][board_x] != 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

bool move_piece(GameState* game, int dx, int dy) {
    int new_x = game->piece_x + dx;
    int new_y = game->piece_y + dy;
    
    if (!check_collision(game, new_x, new_y, &game->current_piece)) {
        game->piece_x = new_x;
        game->piece_y = new_y;
        return true;
    }
    return false;
}

void rotate_piece(GameState* game, bool clockwise) {
    Tetromino rotated = game->current_piece;
    
    // Rotate shape matrix
    for (int y = 0; y < TETROMINO_SIZE; y++) {
        for (int x = 0; x < TETROMINO_SIZE; x++) {
            if (clockwise) {
                rotated.shape[x][TETROMINO_SIZE - 1 - y] = 
                    game->current_piece.shape[y][x];
            } else {
                rotated.shape[TETROMINO_SIZE - 1 - x][y] = 
                    game->current_piece.shape[y][x];
            }
        }
    }
    
    // Check of rotatie mogelijk is
    if (!check_collision(game, game->piece_x, game->piece_y, &rotated)) {
        game->current_piece = rotated;
    }
}

void lock_piece(GameState* game) {
    for (int py = 0; py < TETROMINO_SIZE; py++) {
        for (int px = 0; px < TETROMINO_SIZE; px++) {
            if (game->current_piece.shape[py][px]) {
                int board_x = game->piece_x + px;
                int board_y = game->piece_y + py;
                
                if (board_x >= 0 && board_x < BOARD_WIDTH &&
                    board_y >= 0 && board_y < BOARD_HEIGHT) {
                    game->board[board_y][board_x] = game->current_piece.color;
                }
            }
        }
    }
}

void clear_lines(GameState* game) {
    for (int y = BOARD_HEIGHT - 1; y >= 0; y--) {
        bool line_full = true;
        
        for (int x = 0; x < BOARD_WIDTH; x++) {
            if (game->board[y][x] == 0) {
                line_full = false;
                break;
            }
        }
        
        if (line_full) {
            // Shift alle rijen boven deze naar beneden
            for (int shift_y = y; shift_y > 0; shift_y--) {
                memcpy(game->board[shift_y], 
                       game->board[shift_y - 1], 
                       BOARD_WIDTH);
            }
            
            // Clear top rij
            memset(game->board[0], 0, BOARD_WIDTH);
            
            // Check deze rij opnieuw
            y++;
        }
    }
}

void game_update(GameState* game) {
    // Dit wordt aangeroepen door de timer interrupt
    if (!move_piece(game, 0, 1)) {
        lock_piece(game);
        clear_lines(game);
        spawn_new_piece(game);
    }
}
