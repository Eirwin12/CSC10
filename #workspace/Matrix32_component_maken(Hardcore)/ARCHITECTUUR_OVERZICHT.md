# 🏗️ Matrix32 LED Controller - Architectuur Overzicht

## 🎯 Design Filosofie: VHDL doet het werk, C is eenvoudig

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  C SOFTWARE (Nios II / HPS)                                     │
│  ──────────────────────────                                     │
│                                                                  │
│  matrix32_set_pixel(10, 10, 1, 0, 0);  ← Een regel code!       │
│         │                                                        │
│         └─→ Avalon Bus Write                                    │
│                    │                                             │
└────────────────────┼─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  VHDL HARDWARE (FPGA)                                           │
│  ────────────────────                                           │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │ Matrix32_LED_avalon.vhd (Avalon Wrapper)        │          │
│  │  • Registers (CONTROL, PATTERN, FB_ADDR/DATA)   │          │
│  │  • Avalon bus interface                          │          │
│  │  • Write trigger naar framebuffer                │          │
│  └──────────────────┬───────────────────────────────┘          │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────────────────┐          │
│  │ Matrix32_LED.vhd (Core Controller)               │          │
│  │                                                   │          │
│  │  ┌─────────────────────────────────────┐        │          │
│  │  │ FRAMEBUFFER (384 bytes)             │        │          │
│  │  │  • R channel: 0-127                 │        │          │
│  │  │  • G channel: 128-255               │        │          │
│  │  │  • B channel: 256-383               │        │          │
│  │  └─────────────────┬───────────────────┘        │          │
│  │                    │                              │          │
│  │  ┌─────────────────▼───────────────────┐        │          │
│  │  │ STATE MACHINE                        │        │          │
│  │  │  IDLE → SHIFT_DATA →                │        │          │
│  │  │  LATCH_DATA → DISPLAY → (loop)      │        │          │
│  │  └─────────────────┬───────────────────┘        │          │
│  │                    │                              │          │
│  │  ┌─────────────────▼───────────────────┐        │          │
│  │  │ ROW SCANNING                         │        │          │
│  │  │  • Row counter: 0→15 (automatisch)  │        │          │
│  │  │  • Column counter: 0→31             │        │          │
│  │  │  • Refresh > 1kHz                   │        │          │
│  │  └─────────────────┬───────────────────┘        │          │
│  │                    │                              │          │
│  │  ┌─────────────────▼───────────────────┐        │          │
│  │  │ HUB75 PROTOCOL TIMING                │        │          │
│  │  │  • CLK pulses (32x per rij)         │        │          │
│  │  │  • LAT pulse (na 32 pixels)         │        │          │
│  │  │  • OE control (PWM/brightness)      │        │          │
│  │  └─────────────────┬───────────────────┘        │          │
│  └────────────────────┼──────────────────────────────┘          │
│                       │                                          │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        ▼
          ┌──────────────────────────┐
          │  GPIO_1 (DE1-SoC Board)  │
          │  R1 G1 B1 R2 G2 B2       │
          │  A B C D CLK LAT OE      │
          └────────────┬─────────────┘
                       │
                       ▼
          ┌──────────────────────────┐
          │   32x32 RGB LED Matrix   │
          │   (HUB75 Interface)      │
          └──────────────────────────┘
```

## 🔄 Data Flow: Van C Code naar LED

### Stap 1: C Code (Software)
```c
matrix32_set_pixel(base, 10, 10, 1, 0, 0);  // Rood pixel op (10,10)
```

### Stap 2: Framebuffer Berekening (C functie)
```c
pixel_index = 10 * 32 + 10 = 330
byte_addr   = 330 / 8 = 41
bit_offset  = 330 % 8 = 2
bit_mask    = 1 << 2 = 0b00000100
```

### Stap 3: Avalon Bus Writes (3x voor RGB)
```
Write 1: FB_ADDR = 41    FB_DATA = 0b00000100  (R channel)
Write 2: FB_ADDR = 169   FB_DATA = 0b00000000  (G channel)
Write 3: FB_ADDR = 297   FB_DATA = 0b00000000  (B channel)
```

### Stap 4: VHDL Framebuffer Update
```vhdl
-- In Matrix32_LED.vhd:
if fb_write_enable = '1' then
    framebuffer(to_integer(unsigned(fb_write_addr))) <= fb_write_data;
end if;
```

### Stap 5: Hardware Scanning (Automatisch, Constant)
```vhdl
-- State machine loopt constant:
for each row in 0..15:
    for each column in 0..31:
        shift_out RGB data from framebuffer
    latch data
    enable output
    display for 1ms
    next row
```

### Stap 6: HUB75 Output Timing
```
Row 10 scanning:
  CLK:  ___╱‾╲___╱‾╲___╱‾╲___ (32 pulsen)
  R1:   ───────╱‾╲─────────── (pixel 10 data)
  LAT:  ___________________╱‾╲
  OE:   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾╲___╱
  
  → LED op positie (10,10) gaat AAN!
```

## 📊 Component Interface Overzicht

### Avalon Memory-Mapped Registers

| Offset | Register  | Bits | Read/Write | Beschrijving |
|--------|-----------|------|------------|--------------|
| 0x00   | CONTROL   | [0]  | R/W        | Enable bit (1=aan) |
|        |           | [1]  | R/W        | Mode (0=FB, 1=pattern) |
| 0x04   | PATTERN   | [2:0]| R/W        | Test pattern select |
| 0x08   | FB_ADDR   | [11:0]| R/W       | Framebuffer write address |
| 0x0C   | FB_DATA   | [7:0]| R/W        | Framebuffer write data (trigger) |
| 0x10   | STATUS    | [31:0]| R         | Component status |

### HUB75 Matrix Signals (naar GPIO)

| Signal | Dir | Beschrijving |
|--------|-----|--------------|
| R1, G1, B1 | Out | RGB data voor upper half (rij 0-15) |
| R2, G2, B2 | Out | RGB data voor lower half (rij 16-31) |
| A, B, C, D | Out | 4-bit row address (0-15) |
| CLK | Out | Shift clock (32 pulsen per rij) |
| LAT | Out | Latch pulse (na 32 pixels) |
| OE  | Out | Output Enable (active low, PWM) |

## ⏱️ Timing Specificaties

### Frame Timing
```
Complete frame = 16 rijen × 1ms = 16ms
Refresh rate   = 1000ms / 16ms ≈ 62.5 Hz
```

### Per Row Timing (bij 50 MHz klok)
```
SHIFT_DATA:   32 columns × 2 clocks = 64 clocks = 1.28 μs
LATCH_DATA:   1 clock                = 20 ns
DISPLAY:      1000 refresh counts    ≈ 1 ms
───────────────────────────────────────────────────
Total per row:                       ≈ 1 ms
```

### Shift Clock Frequency
```
CLK_out toggle elke clock cycle tijdens SHIFT_DATA
Frequency = 50 MHz / 2 = 25 MHz (maar met pauzes)
```

## 🎨 Framebuffer Memory Map

```
FPGA Block RAM (384 bytes × 8 bits = 3072 bits)

┌────────────────────────────────────────┐
│ RED CHANNEL (128 bytes)                │  Addresses 0-127
│ ─────────────────────────              │
│ Byte 0:   Pixels (0,0) t/m (0,7)      │  Rij 0, eerste 8 pixels
│ Byte 1:   Pixels (0,8) t/m (0,15)     │  Rij 0, volgende 8 pixels
│ Byte 2:   Pixels (0,16) t/m (0,23)    │  Rij 0, volgende 8 pixels
│ Byte 3:   Pixels (0,24) t/m (0,31)    │  Rij 0, laatste 8 pixels
│ Byte 4:   Pixels (1,0) t/m (1,7)      │  Rij 1, eerste 8 pixels
│ ...                                     │
│ Byte 127: Pixels (31,24) t/m (31,31)  │  Laatste rij, laatste 8
├────────────────────────────────────────┤
│ GREEN CHANNEL (128 bytes)              │  Addresses 128-255
│ ─────────────────────────              │
│ (zelfde layout als RED)                │
├────────────────────────────────────────┤
│ BLUE CHANNEL (128 bytes)               │  Addresses 256-383
│ ─────────────────────────────          │
│ (zelfde layout als RED)                │
└────────────────────────────────────────┘

Pixel (x, y) mapping:
  pixel_index = y × 32 + x
  byte_addr   = pixel_index / 8
  bit_offset  = pixel_index % 8
  
  R: framebuffer[byte_addr]       bit [bit_offset]
  G: framebuffer[128 + byte_addr] bit [bit_offset]
  B: framebuffer[256 + byte_addr] bit [bit_offset]
```

## 🔌 Platform Designer Integration

### Component Files
```
matrix32_led_hw.tcl          ← Platform Designer TCL script
  ├─ Instantiates: Matrix32_LED_avalon.vhd (top-level)
  │   └─ Instantiates: Matrix32_LED.vhd (core)
  │
  ├─ Exports: led_matrix conduit
  │   └─ Signals: R1,G1,B1,R2,G2,B2,A,B,C,D,CLK,LAT,OE
  │
  └─ Provides: Avalon MM Slave (5 registers)
```

### System Integration
```
Platform Designer:
  ┌─────────────────────────────────────┐
  │ Nios II Processor                   │
  └──────────────┬──────────────────────┘
                 │ (Avalon Bus)
  ┌──────────────▼──────────────────────┐
  │ Matrix32_LED Component              │
  │ Base Address: 0x00010000 (example)  │
  └──────────────┬──────────────────────┘
                 │ (Conduit)
                 ▼
            [GPIO_0 pins]
                 │
                 ▼
          [LED Matrix HUB75]
```

## 📈 Performance Karakteristieken

### CPU Load
- **0%** - Hardware doet alle scanning
- CPU schrijft alleen bij pixel updates
- Typisch: enkele writes per frame

### Latency
- Write naar framebuffer: **1 clock cycle** (20ns @ 50MHz)
- Pixel visible op matrix: **< 1ms** (volgende row scan)
- Frame update compleet: **< 16ms** (volledige refresh)

### Throughput
- Max write rate: **50 MHz** (Avalon bus snelheid)
- Praktisch: **~1000 pixel updates/sec** (meer dan genoeg!)
- Geen DMA nodig: direct writes naar FPGA memory

## ✅ Voordelen van deze Architectuur

### 🎯 Eenvoudige Software
- Geen complex timing code
- Geen interrupt handlers
- Geen DMA configuratie
- Simpele API: `set_pixel(x, y, rgb)`

### ⚡ Snelle Hardware
- Constant refresh (geen CPU cycles)
- Deterministische timing
- Real-time updates
- Lage latency

### 🔧 Flexibel
- Software kan andere taken doen
- Hardware draait onafhankelijk
- Test patterns in hardware
- Framebuffer én pattern mode

### 💪 Robuust
- Geen missed frames
- Geen flickering
- Correcte HUB75 timing
- Hardware is altijd consistent

---

**Dit is waarom VHDL het zware werk doet en C eenvoudig blijft!** 🚀
