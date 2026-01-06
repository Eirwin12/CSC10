#ifndef TETRIS_GAME_H
#define TETRIS_GAME_H

#include <stdint.h>
#include <stdbool.h>

// Tetris constanten
#define BOARD_WIDTH     32
#define BOARD_HEIGHT    32
#define TETROMINO_SIZE  4

// Tetromino types
typedef enum {
    TETROMINO_I,
    TETROMINO_O,
    TETROMINO_T,
    TETROMINO_S,
    TETROMINO_Z,
    TETROMINO_J,
    TETROMINO_L,
    TETROMINO_COUNT
} TetrominoType;

// Tetromino definitie
typedef struct {
    uint8_t shape[TETROMINO_SIZE][TETROMINO_SIZE];
    uint8_t width;
    uint8_t height;
    uint32_t color;
} Tetromino;

// Game state
typedef struct {
    uint8_t board[BOARD_HEIGHT][BOARD_WIDTH];
    Tetromino current_piece;
    int piece_x;
    int piece_y;
    TetrominoType current_type;
    bool game_over;
} GameState;

// Functie prototypes
void game_init(GameState* game);
void game_update(GameState* game);
bool move_piece(GameState* game, int dx, int dy);
void rotate_piece(GameState* game, bool clockwise);
void lock_piece(GameState* game);
void clear_lines(GameState* game);
void spawn_new_piece(GameState* game);
bool check_collision(GameState* game, int x, int y, const Tetromino* piece);

#endif // TETRIS_GAME_H
