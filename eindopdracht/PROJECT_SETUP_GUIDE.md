# Tetris Project Setup Guide - DE1-SoC FPGA

## Projectoverzicht

Dit project implementeert een Tetris-spel op de DE1-SoC FPGA (Altera Cyclone V 5CSEMA5F31C6N) met een 32x32 RGB LED Matrix via GPIO1 (JP2).

---

## Hardware Specificaties

### FPGA Board
- **Board**: DE1-SoC Development Board
- **FPGA**: Altera Cyclone V 5CSEMA5F31C6N
- **HPS**: ARM Cortex-A9 dual-core processor

### RGB LED Matrix
- **Type**: 32x32 RGB LED Matrix Panel
- **Pitch**: 4mm
- **Verbinding**: GPIO1 (JP2) op DE1-SoC
- **Kloksnelheid**: 50MHz aanbevolen
- **Architectuur**: 8 strips van 2 rijen (16 RGB LEDs per strip)

### Inputs
- **KEY0-KEY3**: Beweging (links, rechts, omhoog/neer of rotatie)
- **SW0-SW8**: Kleurinstelling (3 switches per kleurkanaal RGB)
- **SW9**: Reserve/niet gebruikt

---

## GPIO1 (JP2) Pin Mapping

### RGB Matrix Interface Pinnen - Connector Layout (32x32 / 64x32 Panels - Variant A)

```
┌─────────────────────────────────────┐
│  32x32 RGB LED Matrix Connector     │
├─────────────────┬───────────────────┤
│  Left Side      │    Right Side     │
├─────────────────┼───────────────────┤
│  R1  ● ○        │        ○ ●  G1    │
│  B1  ● ○        │        ○ ●  GND   │
│  R2  ● ○        │        ○ ●  G2    │
│  B2  ● ○        │        ○ ●  GND   │
│  A   ● ○        │        ○ ●  B     │
│  C   ● ○        │        ○ ●  D     │
│  CLK ● ○        │        ○ ●  LAT   │
│  OE  ● ○        │        ○ ●  GND   │
└─────────────────┴───────────────────┘
```

**Let op**: D-pin niet gebruikt voor 32x32 panels (wel voor 64x32 panels).

### Pin Mapping Tabel

| Connector Pin | Signaal | GPIO Pin | FPGA Pin | Beschrijving |
|---------------|---------|----------|----------|--------------|
| **Links 1**   | **R1**  | GPIO_1[0] | PIN_V12 | Rood data voor upper half (rijen 0-7) |
| Rechts 1      | G1      | GPIO_1[1] | PIN_AF7 | Groen data voor upper half (rijen 0-7) |
| **Links 2**   | **B1**  | GPIO_1[2] | PIN_W12 | Blauw data voor upper half (rijen 0-7) |
| Rechts 2      | GND     | -         | -       | Ground |
| **Links 3**   | **R2**  | GPIO_1[3] | PIN_AF8 | Rood data voor lower half (rijen 8-15) |
| Rechts 3      | G2      | GPIO_1[4] | PIN_Y8  | Groen data voor lower half (rijen 8-15) |
| **Links 4**   | **B2**  | GPIO_1[5] | PIN_AB4 | Blauw data voor lower half (rijen 8-15) |
| Rechts 4      | GND     | -         | -       | Ground |
| **Links 5**   | **A**   | GPIO_1[6] | PIN_W8  | Row address bit 0 (0-7 selectie) |
| Rechts 5      | B       | GPIO_1[7] | PIN_Y4  | Row address bit 1 (0-7 selectie) |
| **Links 6**   | **C**   | GPIO_1[8] | PIN_Y5  | Row address bit 2 (0-7 selectie) |
| Rechts 6      | D       | -         | -       | Row address bit 3 (niet gebruikt) |
| **Links 7**   | **CLK** | GPIO_1[9] | PIN_U11 | Shift register clock (~1MHz) |
| Rechts 7      | LAT     | GPIO_1[10] | PIN_T8 | Latch/strobe signal |
| **Links 8**   | **OE**  | GPIO_1[11] | PIN_T12 | Output enable (active low) |
| Rechts 8      | GND     | -         | -       | Ground |

**Let op**: Controleer altijd de voltage levels (3.3V voor DE1-SoC GPIO).

---

## Quartus Platform Designer Setup

### Stap 1: Nieuw Platform Designer Project

1. Open Quartus Prime
2. Tools → Platform Designer (Qsys)
3. Maak nieuw systeem aan

### Stap 2: Basis Componenten Toevoegen

#### 2.1 Clock Source
```
Component: Clock Source
Instance Name: clk_0
Clock Rate: 50 MHz
```

#### 2.2 NIOS II Processor
```
Component: Nios II Processor
Instance Name: nios2_gen2_0
Type: Nios II/e (economy) of Nios II/f (fast)
Reset Vector: onchip_memory.s1
Exception Vector: onchip_memory.s1
```

**Aanbevolen instellingen:**
- Multiply: DSP block
- Hardware divide: Ja
- Instruction cache: 4 KB (optioneel)
- Data cache: 2 KB (optioneel)

#### 2.3 On-Chip Memory
```
Component: On-Chip Memory (RAM or ROM)
Instance Name: onchip_memory
Type: RAM
Total Memory Size: 256 KB (262144 bytes)
Data Width: 32 bits
```

#### 2.4 JTAG UART
```
Component: JTAG UART
Instance Name: jtag_uart_0
Write FIFO: 64
Read FIFO: 64
```

#### 2.5 System ID Peripheral
```
Component: System ID Peripheral
Instance Name: sysid_qsys
ID: (automatisch gegenereerd)
```

#### 2.6 Timer (voor periodieke interrupts)
```
Component: Interval Timer
Instance Name: timer_0
Timeout Period: 1 ms (1000 µs)
Hardware Options:
  - Writable period: Nee
  - Readable snapshot: Ja
  - Start/Stop control bits: Ja
```

### Stap 3: Custom PIO Components

#### 3.1 PIO voor LED Matrix (RGB Framebuffer Interface)
```
Component: Avalon-MM PIO (Custom - gebruik custom VHDL component)
Instance Name: rgb_framebuffer_0
Type: Custom VHDL component
```

**Avalon-MM Slave Interface:**
- Base Address: (automatisch toewijzen)
- Address Width: 10 bits (1024 woorden = 32x32 pixels, elk 1 woord voor RGB)
- Data Width: 32 bits
- Read/Write: Beide

**Conduit Signals naar VHDL:**
```
rgb_matrix_conduit:
  - r1, g1, b1 (upper half RGB)
  - r2, g2, b2 (lower half RGB)
  - addr_a, addr_b, addr_c (row selection)
  - clk_out (shift clock)
  - lat (latch)
  - oe_n (output enable, active low)
```

#### 3.2 PIO voor Buttons (KEY0-KEY3)
```
Component: PIO (Parallel I/O)
Instance Name: pio_buttons
Direction: Input
Width: 4 bits
Edge Capture: Ja (voor interrupt-driven input)
IRQ: Ja (optioneel)
```

**Reset value**: 0xF (active low buttons)

#### 3.3 PIO voor Switches (SW0-SW9)
```
Component: PIO (Parallel I/O)
Instance Name: pio_switches
Direction: Input
Width: 10 bits
Edge Capture: Nee
```

**Reset value**: 0x0

#### 3.4 PIO voor LEDs (optioneel, voor debugging)
```
Component: PIO (Parallel I/O)
Instance Name: pio_leds
Direction: Output
Width: 10 bits
Reset value: 0x0
```

### Stap 4: Verbindingen Maken in Platform Designer

#### Clock en Reset Verbindingen
| Component | Clock Input | Reset Input |
|-----------|-------------|-------------|
| nios2_gen2_0 | clk_0.clk | clk_0.clk_reset |
| onchip_memory | clk_0.clk | clk_0.clk_reset |
| jtag_uart_0 | clk_0.clk | clk_0.clk_reset |
| timer_0 | clk_0.clk | clk_0.clk_reset |
| sysid_qsys | clk_0.clk | clk_0.clk_reset |
| rgb_framebuffer_0 | clk_0.clk | clk_0.clk_reset |
| pio_buttons | clk_0.clk | clk_0.clk_reset |
| pio_switches | clk_0.clk | clk_0.clk_reset |
| pio_leds | clk_0.clk | clk_0.clk_reset |

#### Avalon Memory Mapped (MM) Verbindingen

**NIOS II Data Master → Slaves:**
- nios2_gen2_0.data_master → onchip_memory.s1
- nios2_gen2_0.data_master → jtag_uart_0.avalon_jtag_slave
- nios2_gen2_0.data_master → timer_0.s1
- nios2_gen2_0.data_master → sysid_qsys.control_slave
- nios2_gen2_0.data_master → rgb_framebuffer_0.avalon_slave
- nios2_gen2_0.data_master → pio_buttons.s1
- nios2_gen2_0.data_master → pio_switches.s1
- nios2_gen2_0.data_master → pio_leds.s1

**NIOS II Instruction Master → Slaves:**
- nios2_gen2_0.instruction_master → onchip_memory.s1

#### Interrupt Verbindingen (IRQ)
| Master | IRQ # | Slave |
|--------|-------|-------|
| nios2_gen2_0.irq | 0 | jtag_uart_0.irq |
| nios2_gen2_0.irq | 1 | timer_0.irq |
| nios2_gen2_0.irq | 2 | pio_buttons.irq (optioneel) |

### Stap 5: Base Addresses Toewijzen

Platform Designer wijst automatisch adressen toe, maar controleer deze:

| Component | Base Address | Size |
|-----------|--------------|------|
| onchip_memory.s1 | 0x00000000 | 256 KB |
| rgb_framebuffer_0.avalon_slave | 0x00041000 | 4 KB |
| pio_buttons.s1 | 0x00042000 | 16 bytes |
| pio_switches.s1 | 0x00042010 | 16 bytes |
| pio_leds.s1 | 0x00042020 | 16 bytes |
| timer_0.s1 | 0x00042040 | 32 bytes |
| jtag_uart_0.avalon_jtag_slave | 0x00042060 | 8 bytes |
| sysid_qsys.control_slave | 0x00042068 | 8 bytes |

### Stap 6: Genereren en Integreren

1. **System → Assign Base Addresses** (controleer conflicten)
2. **Generate → Generate HDL** (kies VHDL als output)
3. **Finish** en sluit Platform Designer

---

## VHDL Component: RGB Framebuffer

### Bestand: `rgb_framebuffer.vhdl`

Dit component moet:
1. Avalon-MM slave interface implementeren voor NIOS II communicatie
2. Dual-port RAM bevatten voor 32x32 RGB pixels (elk 24-bit of 32-bit)
3. RGB matrix scanning logic implementeren
4. Multiplexing van 8 rij-paren uitvoeren

### Component Interface

```vhdl
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rgb_framebuffer is
    port (
        -- Clock en Reset
        clk           : in  std_logic;
        reset         : in  std_logic;
        
        -- Avalon-MM Slave Interface
        avs_address   : in  std_logic_vector(9 downto 0);  -- 1024 adressen (32x32)
        avs_read      : in  std_logic;
        avs_write     : in  std_logic;
        avs_writedata : in  std_logic_vector(31 downto 0); -- RGB888 + padding
        avs_readdata  : out std_logic_vector(31 downto 0);
        avs_waitrequest : out std_logic;
        
        -- RGB Matrix Output Conduit
        matrix_r1     : out std_logic;
        matrix_g1     : out std_logic;
        matrix_b1     : out std_logic;
        matrix_r2     : out std_logic;
        matrix_g2     : out std_logic;
        matrix_b2     : out std_logic;
        matrix_addr_a : out std_logic;
        matrix_addr_b : out std_logic;
        matrix_addr_c : out std_logic;
        matrix_clk    : out std_logic;
        matrix_lat    : out std_logic;
        matrix_oe_n   : out std_logic
    );
end entity rgb_framebuffer;
```

### Framebuffer Geheugen Structuur

**Pixel Formaat (32-bit woord):**
```
Bits 31-24: Reserved (0x00)
Bits 23-16: Red (0-255)
Bits 15-8:  Green (0-255)
Bits 7-0:   Blue (0-255)
```

**Adres Mapping:**
```
Address = Y * 32 + X
waarbij X = 0..31 (kolom), Y = 0..31 (rij)
```

### Implementatie Details

#### 1. Dual-Port RAM (Framebuffer)
```vhdl
type ram_type is array (0 to 1023) of std_logic_vector(31 downto 0);
signal framebuffer : ram_type := (others => (others => '0'));
```

#### 2. Matrix Scanning Logic

De matrix wordt gescand met ~500 Hz refresh rate:
- 8 rij-paren (row 0+16, 1+17, ..., 7+23)
- 32 kolommen per rij-paar
- Per frame: 8 * 32 = 256 klok cycli

**Scan FSM States:**
1. **SHIFT**: Clock out 32 pixels (2 rijen) via shift registers
2. **LATCH**: Latch data in LED drivers
3. **DISPLAY**: Enable output (OE low), wacht voor helderheid
4. **NEXT_ROW**: Verhoog rij-adres

#### 3. PWM voor Helderheid (optioneel)

Voor 8-bit kleurdiepte implementeer bit angle modulation of BCM:
- Elke kleur bit wordt afzonderlijk getoond
- Bit 7 (MSB): 128/255 tijd
- Bit 6: 64/255 tijd
- ...
- Bit 0 (LSB): 1/255 tijd

### Template Code Structuur

```vhdl
architecture rtl of rgb_framebuffer is
    -- Framebuffer RAM
    type ram_type is array (0 to 1023) of std_logic_vector(31 downto 0);
    signal framebuffer : ram_type := (others => (others => '0'));
    
    -- Scanning signals
    signal row_addr : unsigned(2 downto 0) := (others => '0');
    signal col_count : unsigned(4 downto 0) := (others => '0');
    
    -- Matrix clock divider (50MHz → 25MHz bijvoorbeeld)
    signal clk_div : std_logic := '0';
    signal clk_counter : unsigned(1 downto 0) := (others => '0');
    
    -- FSM
    type state_type is (SHIFT, LATCH, DISPLAY, NEXT_ROW);
    signal state : state_type := SHIFT;
    
    -- Pixel data shiften
    signal shift_pixel1 : std_logic_vector(23 downto 0);
    signal shift_pixel2 : std_logic_vector(23 downto 0);
    
begin
    -- Avalon-MM Interface: Read/Write naar framebuffer
    process(clk, reset)
    begin
        if reset = '1' then
            framebuffer <= (others => (others => '0'));
            avs_readdata <= (others => '0');
        elsif rising_edge(clk) then
            avs_waitrequest <= '0';
            
            if avs_write = '1' then
                framebuffer(to_integer(unsigned(avs_address))) <= avs_writedata;
            end if;
            
            if avs_read = '1' then
                avs_readdata <= framebuffer(to_integer(unsigned(avs_address)));
            end if;
        end if;
    end process;
    
    -- Matrix Scanning FSM
    process(clk, reset)
    begin
        if reset = '1' then
            state <= SHIFT;
            row_addr <= (others => '0');
            col_count <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when SHIFT =>
                    -- Clock out pixels naar shift registers
                    -- ... implementatie ...
                    
                when LATCH =>
                    -- Latch data
                    -- ... implementatie ...
                    
                when DISPLAY =>
                    -- Enable output
                    -- ... implementatie ...
                    
                when NEXT_ROW =>
                    -- Volgende rij
                    -- ... implementatie ...
            end case;
        end if;
    end process;
    
    -- Output assignments
    matrix_addr_a <= std_logic(row_addr(0));
    matrix_addr_b <= std_logic(row_addr(1));
    matrix_addr_c <= std_logic(row_addr(2));
    
    -- ... verdere implementatie ...
    
end architecture rtl;
```

---

## Top-Level VHDL Integratie

### Bestand: `eindopdracht_Testris.vhd` (top level)

```vhdl
library IEEE;
use IEEE.std_logic_1164.all;

entity eindopdracht_Testris is
    port (
        -- Clock
        CLOCK_50 : in std_logic;
        
        -- Keys (active low)
        KEY : in std_logic_vector(3 downto 0);
        
        -- Switches
        SW : in std_logic_vector(9 downto 0);
        
        -- LEDs (voor debugging)
        LEDR : out std_logic_vector(9 downto 0);
        
        -- GPIO1 (JP2) voor RGB Matrix
        GPIO_1 : inout std_logic_vector(35 downto 0)
    );
end entity eindopdracht_Testris;

architecture structure of eindopdracht_Testris is
    
    -- Platform Designer component
    component nios_system is
        port (
            clk_clk                    : in  std_logic;
            reset_reset_n              : in  std_logic;
            pio_buttons_export         : in  std_logic_vector(3 downto 0);
            pio_switches_export        : in  std_logic_vector(9 downto 0);
            pio_leds_export            : out std_logic_vector(9 downto 0);
            rgb_matrix_conduit_r1      : out std_logic;
            rgb_matrix_conduit_g1      : out std_logic;
            rgb_matrix_conduit_b1      : out std_logic;
            rgb_matrix_conduit_r2      : out std_logic;
            rgb_matrix_conduit_g2      : out std_logic;
            rgb_matrix_conduit_b2      : out std_logic;
            rgb_matrix_conduit_addr_a  : out std_logic;
            rgb_matrix_conduit_addr_b  : out std_logic;
            rgb_matrix_conduit_addr_c  : out std_logic;
            rgb_matrix_conduit_clk     : out std_logic;
            rgb_matrix_conduit_lat     : out std_logic;
            rgb_matrix_conduit_oe_n    : out std_logic
        );
    end component;
    
    signal reset_n : std_logic;
    
begin
    
    -- Reset: active low
    reset_n <= KEY(0);  -- Gebruik KEY0 als reset, of maak aparte reset logic
    
    -- NIOS System instantie
    u0 : component nios_system
        port map (
            clk_clk                    => CLOCK_50,
            reset_reset_n              => reset_n,
            pio_buttons_export         => KEY,
            pio_switches_export        => SW,
            pio_leds_export            => LEDR,
            rgb_matrix_conduit_r1      => GPIO_1(0),
            rgb_matrix_conduit_g1      => GPIO_1(1),
            rgb_matrix_conduit_b1      => GPIO_1(2),
            rgb_matrix_conduit_r2      => GPIO_1(3),
            rgb_matrix_conduit_g2      => GPIO_1(4),
            rgb_matrix_conduit_b2      => GPIO_1(5),
            rgb_matrix_conduit_addr_a  => GPIO_1(6),
            rgb_matrix_conduit_addr_b  => GPIO_1(7),
            rgb_matrix_conduit_addr_c  => GPIO_1(8),
            rgb_matrix_conduit_clk     => GPIO_1(9),
            rgb_matrix_conduit_lat     => GPIO_1(10),
            rgb_matrix_conduit_oe_n    => GPIO_1(11)
        );
    
end architecture structure;
```

---

## Software (C/C++) Structuur

### Project Opzet

1. **Nios II Software Build Tools for Eclipse** gebruiken
2. Maak een nieuw "Nios II Application and BSP from Template"
3. Kies "Hello World" als basis template

### Bestandsstructuur

```
software/
├── tetris_app/
│   ├── main.c
│   ├── tetris_game.c
│   ├── tetris_game.h
│   ├── graphics.c
│   ├── graphics.h
│   ├── input.c
│   └── input.h
└── tetris_app_bsp/
    └── (automatisch gegenereerd)
```

### Header Guards en Includes

#### `tetris_game.h`
```c
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
```

#### `graphics.h`
```c
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
```

#### `input.h`
```c
#ifndef INPUT_H
#define INPUT_H

#include <stdint.h>
#include <stdbool.h>
#include "system.h"

// Button mapping (active low)
#define BUTTON_0    0x01
#define BUTTON_1    0x02
#define BUTTON_2    0x04
#define BUTTON_3    0x08

// Button functions
typedef enum {
    BTN_LEFT,
    BTN_RIGHT,
    BTN_ROTATE_CW,
    BTN_ROTATE_CCW
} ButtonFunction;

// Functie prototypes
void input_init(void);
uint8_t read_buttons(void);
uint16_t read_switches(void);
bool is_button_pressed(ButtonFunction btn);
RGB get_color_from_switches(void);

#endif // INPUT_H
```

### Implementatie: `main.c`

```c
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
```

### Implementatie: `graphics.c`

```c
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
```

### Implementatie: `input.c`

```c
#include "input.h"
#include "altera_avalon_pio_regs.h"

void input_init(void) {
    // PIO wordt automatisch geïnitialiseerd door HAL
    // Buttons zijn active low inputs
    // Switches zijn normale inputs
}

uint8_t read_buttons(void) {
    return (uint8_t)IORD_ALTERA_AVALON_PIO_DATA(PIO_BUTTONS_BASE);
}

uint16_t read_switches(void) {
    return (uint16_t)IORD_ALTERA_AVALON_PIO_DATA(PIO_SWITCHES_BASE);
}

bool is_button_pressed(ButtonFunction btn) {
    uint8_t buttons = read_buttons();
    
    // Active low: pressed = 0
    switch(btn) {
        case BTN_LEFT:
            return !(buttons & BUTTON_0);
        case BTN_RIGHT:
            return !(buttons & BUTTON_1);
        case BTN_ROTATE_CW:
            return !(buttons & BUTTON_2);
        case BTN_ROTATE_CCW:
            return !(buttons & BUTTON_3);
        default:
            return false;
    }
}

RGB get_color_from_switches(void) {
    uint16_t sw = read_switches();
    
    // SW0-SW2: Blue (active low)
    // SW3-SW5: Green
    // SW6-SW8: Red
    
    uint8_t r_bits = (~sw >> 6) & 0x07;  // 0-7
    uint8_t g_bits = (~sw >> 3) & 0x07;
    uint8_t b_bits = (~sw) & 0x07;
    
    RGB color;
    
    // Map 0-7 to 1-255
    // 0 → 1 (zichtbaar maar dim)
    // 7 → 255 (volledig helder)
    color.r = (r_bits == 0) ? 1 : (r_bits * 36 + 3);
    color.g = (g_bits == 0) ? 1 : (g_bits * 36 + 3);
    color.b = (b_bits == 0) ? 1 : (b_bits * 36 + 3);
    
    return color;
}
```

### Implementatie: `tetris_game.c`

```c
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
```

---

## BSP (Board Support Package) Instellingen

1. **Maak BSP aan**: Right-click project → Nios II → BSP Editor
2. **Settings**:
   - `hal.enable_c_plus_plus`: false (tenzij C++ nodig is)
   - `hal.enable_small_c_library`: true (voor kleinere code)
   - `hal.enable_reduced_device_drivers`: false
   - `hal.sys_clk_timer`: timer_0
   - `hal.timestamp_timer`: timer_0

3. **Drivers controleren**:
   - altera_avalon_pio
   - altera_avalon_timer
   - altera_avalon_jtag_uart

---

## Compilatie en Programmeren

### FPGA Programmeren

1. **Compileer VHDL design**:
   - Processing → Start Compilation
   - Controleer geen errors

2. **Program FPGA**:
   - Tools → Programmer
   - Add File → selecteer `.sof` file
   - Start programming

### Software Compileren

1. **Build project**:
   - Right-click → Build Project
   - Controleer geen errors

2. **Run on target**:
   - Right-click → Run As → Nios II Hardware
   - Via JTAG UART zie je printf output

---

## Testing en Debugging

### Stap 1: Test RGB Matrix Verbinding

1. Upload simpel test programma dat alle pixels rood maakt
2. Controleer of matrix oplicht
3. Test verschillende kleuren

### Stap 2: Test Input

1. Print button states via JTAG UART
2. Test switches en controleer waarden
3. Implementeer LED feedback

### Stap 3: Test Game Logic

1. Test collision detection
2. Test line clearing
3. Test rotation

### Stap 4: Performance Tuning

1. Check refresh rate (moet >500 Hz zijn)
2. Optimaliseer VHDL timing indien nodig
3. Gebruik SignalTap voor debugging

---

## RTOS vs Linux Vergelijking

### FreeRTOS Optie

**Voordelen:**
- Deterministische timing
- Lage latency
- Kleine footprint (~10KB)
- Real-time response voor inputs
- Geschikt voor deze applicatie

**Nadelen:**
- Meer low-level programmeren
- Minder standaard libraries
- Complexere debugging

### Linux Optie

**Voordelen:**
- Rijke ecosystem (stdlib, etc.)
- Makkelijker development
- Betere debugging tools
- Network stack (voor toekomstige features)

**Nadelen:**
- Hogere latency (niet hard real-time)
- Groter geheugen vereist
- Boot tijd
- Overkill voor deze applicatie

### Aanbeveling

Voor dit project: **Bare-metal HAL** (geen OS) of **FreeRTOS**
- Eenvoudig genoeg voor bare-metal
- FreeRTOS als je tasks wilt scheiden
- Linux is te complex voor deze use case

---

## Toevoegingen Implementatie

### Kleur Selectie via Switches

Al geïmplementeerd in `input.c` → `get_color_from_switches()`

Mapping:
- SW0-SW2: Blauw (3 bits = 0-7 → 1-255)
- SW3-SW5: Groen
- SW6-SW8: Rood

### Gravity (Zwaartekracht)

In `main.c` al geïmplementeerd via timer interrupt:
- Elke 500ms valt het piece 1 blok naar beneden
- Pas de interval aan voor snellere/langzamere val

### Muziek (optioneel)

Voor Aux-audio output:
1. Voeg I2S of Audio Core toe in Platform Designer
2. Gebruik Wolfson WM8731 codec op DE1-SoC
3. Implementeer software audio generator in C
4. Play Tetris theme (Korobeiniki)

**Dit vereist:**
- Audio IP Core configuratie
- I2C configuratie voor codec
- PCM audio buffer generatie

---

## Troubleshooting

### RGB Matrix toont niets
- Controleer GPIO pin mapping
- Verify 3.3V/5V levels (gebruik level shifter indien nodig)
- Check ground verbinding
- Verify clock signaal met oscilloscoop

### NIOS II compile errors
- Regenerate BSP
- Check System.h includes
- Verify base addresses in Platform Designer

### Game lag
- Verhoog refresh rate in VHDL
- Optimaliseer draw functie
- Check timer interrupt frequentie

### Buttons reageren niet
- Controleer active low logic
- Debouncing toevoegen in software
- Test met LED feedback

---

## Next Steps

1. ✅ Setup Platform Designer met alle components
2. ✅ Schrijf RGB Framebuffer VHDL component
3. ✅ Integreer in top-level VHDL
4. ✅ Compileer en program FPGA
5. ✅ Setup NIOS II software project
6. ✅ Implementeer graphics en input libraries
7. ✅ Implementeer basic Tetris game logic
8. ✅ Test en debug
9. ⬜ Optimaliseer performance
10. ⬜ Voeg extra features toe (muziek, etc.)

---

## Referenties

- [DE1-SoC User Manual](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=165&No=836&PartNo=4)
- [Adafruit RGB Matrix Guide](https://learn.adafruit.com/32x16-32x32-rgb-led-matrix)
- [Nios II Software Developer Handbook](https://www.intel.com/content/www/us/en/docs/programmable/683525/current/introduction.html)
- [Quartus Platform Designer Documentation](https://www.intel.com/content/www/us/en/docs/programmable/683364/current/introduction.html)

---

**Succes met je project!** 🎮✨
