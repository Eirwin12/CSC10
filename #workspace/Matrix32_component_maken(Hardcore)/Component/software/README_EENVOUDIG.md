# 🎯 EENVOUDIGE RGB LED MATRIX AANSTURING

## Architectuur: Wie doet wat?

### ✅ VHDL Hardware (Matrix32_LED.vhd) - **Doet het ZWARE WERK**

De FPGA hardware zorgt **automatisch** voor:

```
┌─────────────────────────────────────────────────────────┐
│  VHDL Hardware (in FPGA)                                │
│  ───────────────────────────                            │
│                                                          │
│  ✓ Framebuffer opslag (384 bytes)                      │
│  ✓ Matrix scanning (16 rijen multiplexing)             │
│  ✓ Row counter (automatisch 0→15 loop)                 │
│  ✓ Column shift register (32 pixels per rij)           │
│  ✓ Timing generatie:                                    │
│      • CLK pulsen (shift clock)                         │
│      • LAT pulse (latch data)                           │
│      • OE control (output enable)                       │
│  ✓ HUB75 protocol implementatie                         │
│  ✓ Real-time refresh (constant, >1kHz)                 │
│                                                          │
│  → GEEN CPU/SOFTWARE NODIG voor scanning!               │
│  → Hardware draait ALTIJD, ook zonder C code!          │
└─────────────────────────────────────────────────────────┘
```

**State Machine in VHDL:**
```vhdl
-- Hardware loopt automatisch door deze states:
IDLE → SHIFT_DATA → LATCH_DATA → DISPLAY → IDLE (repeat)
  ↓         ↓            ↓           ↓
 Clear   Shift 32    Latch to    Enable    Next row
 output  columns     outputs     LEDs      (row++)
```

### 📝 C Software - **Alleen pixels zetten**

Je C code hoeft alleen maar te zeggen: **"Zet pixel (x,y) op kleur RGB"**

```c
// DIT IS ALLES WAT JE HOEFT TE DOEN:

// 1. Initialisatie (één keer)
matrix32_init(MATRIX_BASE);
matrix32_enable(MATRIX_BASE, 1);  // Hardware start met scannen

// 2. Pixels aan/uit zetten (zo vaak je wilt)
matrix32_set_pixel(MATRIX_BASE, 10, 10, 1, 0, 0);  // Rood aan
matrix32_set_pixel(MATRIX_BASE, 10, 10, 0, 0, 0);  // Uit

// 3. Hele matrix vullen
matrix32_fill(MATRIX_BASE, MATRIX32_COLOR_RED);  // Alles rood

// KLAAR! Hardware toont het automatisch!
```

## 🔄 Hoe werkt het?

### Wat gebeurt er als je een pixel zet?

```
1. C Code:
   matrix32_set_pixel(base, 10, 10, 1, 0, 0);  // Rood pixel
                      ↓
2. Avalon Bus:
   Write naar framebuffer register (0x0C)
                      ↓
3. VHDL (Matrix32_LED_avalon.vhd):
   Schrijft byte naar framebuffer in FPGA
                      ↓
4. VHDL (Matrix32_LED.vhd):
   Hardware leest framebuffer tijdens scanning
   en zet automatisch de juiste LED aan!
                      ↓
5. HUB75 Protocol:
   R1/G1/B1/R2/G2/B2 signalen gaan naar LED matrix
   
→ PIXEL IS ZICHTBAAR! (binnen 1ms)
```

### Timing Diagram

```
Hardware scanning (automatisch, geen CPU nodig):

Row 0:  SHIFT 32 pixels → LATCH → DISPLAY (1ms)
Row 1:  SHIFT 32 pixels → LATCH → DISPLAY (1ms)
Row 2:  SHIFT 32 pixels → LATCH → DISPLAY (1ms)
...
Row 15: SHIFT 32 pixels → LATCH → DISPLAY (1ms)
└─→ Herhaal (constant refresh, ~60 Hz complete frame)

Tijdens SHIFT fase:
CLK:  ___╱‾╲___╱‾╲___╱‾╲___ (32 pulsen)
Data: RGB bits voor current row
LAT:  ________________╱‾╲___ (na 32 pulsen)
OE:   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾╲___╱ (enable na latch)
```

## 📊 Framebuffer Layout (in VHDL)

```
FPGA Memory (384 bytes):

Byte   0-127:  RED   channel (1024 bits = 32×32 pixels)
Byte 128-255:  GREEN channel (1024 bits = 32×32 pixels)  
Byte 256-383:  BLUE  channel (1024 bits = 32×32 pixels)

Elke byte = 8 pixels (1 bit per pixel)

Voorbeeld: Pixel (10, 10) in framebuffer:
  pixel_index = 10 * 32 + 10 = 330
  byte_addr   = 330 / 8 = 41
  bit_offset  = 330 % 8 = 2
  
  R waarde: framebuffer[41]   bit 2
  G waarde: framebuffer[169]  bit 2  (128+41)
  B waarde: framebuffer[297]  bit 2  (256+41)
```

## 🎮 C API - Minimaal en Eenvoudig

### Basis Functies

```c
// Initialisatie
void matrix32_init(uint32_t base_address);
void matrix32_enable(uint32_t base_address, uint8_t enable);

// Pixel control (MEEST GEBRUIKTE FUNCTIE!)
void matrix32_set_pixel(uint32_t base, uint8_t x, uint8_t y, 
                        uint8_t r, uint8_t g, uint8_t b);

// Convenience functies
void matrix32_clear(uint32_t base);              // Alles uit
void matrix32_fill(uint32_t base, uint8_t color); // Alles één kleur

// Voorgedefinieerde kleuren (in matrix32_led.h)
#define MATRIX32_COLOR_BLACK     0  // 000
#define MATRIX32_COLOR_RED       4  // 100
#define MATRIX32_COLOR_GREEN     2  // 010
#define MATRIX32_COLOR_BLUE      1  // 001
#define MATRIX32_COLOR_YELLOW    6  // 110
#define MATRIX32_COLOR_CYAN      3  // 011
#define MATRIX32_COLOR_MAGENTA   5  // 101
#define MATRIX32_COLOR_WHITE     7  // 111
```

### Voorbeeld Code

```c
#include "matrix32_led.h"

int main(void) {
    uint32_t matrix = MATRIX32_LED_0_BASE;
    
    // Stap 1: Init (hardware start met scannen)
    matrix32_init(matrix);
    matrix32_enable(matrix, 1);
    
    // Stap 2: Zet pixels aan/uit
    matrix32_set_pixel(matrix, 0, 0, 1, 0, 0);     // Rood links boven
    matrix32_set_pixel(matrix, 31, 0, 0, 1, 0);    // Groen rechts boven
    matrix32_set_pixel(matrix, 0, 31, 0, 0, 1);    // Blauw links onder
    matrix32_set_pixel(matrix, 31, 31, 1, 1, 1);   // Wit rechts onder
    
    // Stap 3: Hele matrix vullen
    matrix32_fill(matrix, MATRIX32_COLOR_YELLOW);
    
    // Hardware toont alles automatisch!
    while(1) { /* doe andere dingen */ }
}
```

## 🔧 Waarom is dit EENVOUDIG?

### ❌ WAT JE NIET HOEFT TE DOEN:

- ✗ Row scanning implementeren
- ✗ Timing berekenen voor CLK/LAT/OE
- ✗ Shift register aansturing
- ✗ HUB75 protocol implementeren
- ✗ Refresh loop schrijven
- ✗ Interrupts of timers instellen
- ✗ DMA configureren
- ✗ Frame rate managen

→ **VHDL doet dit allemaal in hardware!**

### ✅ WAT JE WEL DOET:

- ✓ `matrix32_set_pixel(x, y, r, g, b)` aanroepen
- ✓ Kleuren kiezen (0 of 1 per RGB channel)
- ✓ Optioneel: draw functies gebruiken (lijnen, rechthoeken)

→ **Simpel toch? Dat is het hele punt!**

## 📁 Bestanden Overzicht

```
Component/
├── hdl/
│   ├── Matrix32_LED.vhd          ← VHDL: Matrix scanning hardware
│   ├── Matrix32_LED_avalon.vhd   ← VHDL: Avalon bus wrapper
│   └── DE1_SoC_Matrix32_top.vhd  ← VHDL: Top-level (FPGA pins)
│
├── software/
│   ├── matrix32_led.h            ← C Header: API definitie
│   ├── matrix32_led.c            ← C Source: Eenvoudige wrappers
│   └── example_main.c            ← Voorbeeld: pixels aan/uit
│
└── matrix32_led_hw.tcl           ← Platform Designer component
```

## 🚀 Samenvatting

**Hardware (VHDL):**
- Doet alle matrix aansturing automatisch
- Scanning, timing, protocol = in FPGA
- Constant refresh zonder CPU

**Software (C):**
- Schrijft alleen pixel waarden
- Eenvoudige API: set_pixel(), fill(), clear()
- Hardware toont direct resultaat!

**Resultaat:**
- 🎯 Super eenvoudige C code
- ⚡ Snelle real-time updates
- 🔧 Geen complex timing gedoe
- ✅ Alles in hardware geregeld!

---

**Gemaakt voor CSC10 Project - DE1-SoC Platform**
