# 32x32 RGB LED Matrix - Platform Designer Component met Framebuffer

## 📋 Overzicht

Deze directory bevat een **volledig framebuffer-gebaseerd** LED matrix controller component voor Quartus Platform Designer. Je kunt nu **individuele pixels** aansturen vanuit software!

**Belangrijkste features:**
- ✅ **384-byte framebuffer** voor volledige pixel controle
- ✅ **Dual-mode**: Framebuffer OF test patronen
- ✅ **Software API** met pixel/lijn/rechthoek functies
- ✅ **Hardware multiplexing** voor 32×32 matrix
- ✅ **Avalon Memory-Mapped** interface
- ✅ **ModelSim testbench** met framebuffer tests
- ✅ **DE1-SoC top level** kant-en-klaar

---

## 🚀 Wat is er veranderd?

### ⚡ Nieuw: Framebuffer Mode

Je kunt nu elke LED individueel aansturen:

```c
// Zet rode pixel op (10, 15)
matrix32_set_pixel(base, 10, 15, 1, 0, 0);

// Teken een lijn
matrix32_draw_hline(base, 0, 31, 16, MATRIX32_COLOR_CYAN);

// Vul rechthoek
matrix32_fill_rect(base, 5, 5, 10, 10, MATRIX32_COLOR_YELLOW);
```

### 📊 Framebuffer Organisatie

**Geheugen layout:**
- **384 bytes** totaal (32×32 pixels × 3 kleuren ÷ 8 bits/byte)
- **Bytes 0-127**: Alle R (rood) bits voor alle pixels
- **Bytes 128-255**: Alle G (groen) bits
- **Bytes 256-383**: Alle B (blauw) bits

**Pixel addressing:**
```
Pixel (x, y) → pixel_index = y * 32 + x
              → byte_addr = pixel_index / 8
              → bit_offset = pixel_index mod 8
```

---

## 📁 Directory Structuur

```
Component/
├── hdl/
│   ├── Matrix32_LED.vhd                    # Core controller MET framebuffer
│   ├── Matrix32_LED_avalon.vhd             # Avalon wrapper (5 registers)
│   ├── Matrix32_LED_framebuffer_tb.vhd     # Testbench voor simulatie
│   └── DE1_SoC_Matrix32_top.vhd            # Top level voor DE1-SoC
├── software/
│   ├── matrix32_led.h                      # Driver API header
│   ├── matrix32_led.c                      # Driver implementatie
│   └── example_main.c                      # Demo applicatie (7 demos!)
├── docs/
│   └── PIN_ASSIGNMENTS_DE1_SOC.txt         # Pin assignments
├── matrix32_led_hw.tcl                     # Platform Designer TCL
└── README.md                               # Deze file
```

---

## 🔧 Hardware: Register Map

| Offset | Naam     | Access | Beschrijving                              |
|--------|----------|--------|-------------------------------------------|
| 0x00   | CONTROL  | R/W    | [0]: Enable, [1]: Mode (0=FB, 1=Pattern) |
| 0x04   | PATTERN  | R/W    | [2:0]: Test pattern select (0-7)         |
| 0x08   | FB_ADDR  | R/W    | [11:0]: Framebuffer byte address         |
| 0x0C   | FB_DATA  | R/W    | [7:0]: Framebuffer data (triggers write) |
| 0x10   | STATUS   | R      | [0]: Enable, [1]: Mode, [4:2]: Pattern   |

**Framebuffer write procedure:**
1. Schrijf byte address naar `FB_ADDR` (0x08)
2. Schrijf data naar `FB_DATA` (0x0C) → **triggert automatisch write!**

---

## 💻 Software API

### Initialisatie

```c
#include "matrix32_led.h"

// Initialiseer
matrix32_init(MATRIX32_LED_0_BASE);

// Enable in framebuffer mode
matrix32_set_mode(MATRIX32_LED_0_BASE, MATRIX32_CTRL_MODE_FB);
matrix32_enable(MATRIX32_LED_0_BASE, 1);
```

### Pixel Drawing

```c
// Individuele pixel (x, y, r, g, b)
matrix32_set_pixel(base, 15, 15, 1, 0, 0);  // Rood

// Met kleur constant
matrix32_set_pixel_color(base, 10, 10, MATRIX32_COLOR_CYAN);
```

### Vormen Tekenen

```c
// Horizontale lijn
matrix32_draw_hline(base, 0, 31, 16, MATRIX32_COLOR_WHITE);

// Verticale lijn
matrix32_draw_vline(base, 16, 0, 31, MATRIX32_COLOR_GREEN);

// Rechthoek outline
matrix32_draw_rect(base, 5, 5, 20, 20, MATRIX32_COLOR_YELLOW);

// Gevulde rechthoek
matrix32_fill_rect(base, 8, 8, 10, 10, MATRIX32_COLOR_MAGENTA);
```

### Scherm Operations

```c
// Clear (alles zwart)
matrix32_clear(base);

// Vul met één kleur
matrix32_fill(base, MATRIX32_COLOR_RED);
```

### Kleuren

```c
#define MATRIX32_COLOR_BLACK     0  // 000
#define MATRIX32_COLOR_BLUE      1  // 001
#define MATRIX32_COLOR_GREEN     2  // 010
#define MATRIX32_COLOR_CYAN      3  // 011
#define MATRIX32_COLOR_RED       4  // 100
#define MATRIX32_COLOR_MAGENTA   5  // 101
#define MATRIX32_COLOR_YELLOW    6  // 110
#define MATRIX32_COLOR_WHITE     7  // 111
```

---

## 🧪 Simulatie met ModelSim

### Testbench Runnen

```tcl
# In ModelSim console:
cd Component/hdl
vcom -2008 Matrix32_LED.vhd
vcom -2008 Matrix32_LED_framebuffer_tb.vhd
vsim Matrix32_LED_framebuffer_tb

# Voeg signalen toe
add wave -group "Control" /Matrix32_LED_framebuffer_tb/clk
add wave -group "Control" /Matrix32_LED_framebuffer_tb/reset
add wave -group "Control" /Matrix32_LED_framebuffer_tb/mode

add wave -group "Framebuffer" /Matrix32_LED_framebuffer_tb/fb_write_enable
add wave -group "Framebuffer" /Matrix32_LED_framebuffer_tb/fb_write_addr
add wave -group "Framebuffer" /Matrix32_LED_framebuffer_tb/fb_write_data

add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/R1
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/G1
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/B1
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/R2
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/G2
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/B2
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/A
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/B
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/C
add wave -group "Matrix Output" /Matrix32_LED_framebuffer_tb/D

add wave -group "Control Signals" /Matrix32_LED_framebuffer_tb/CLK_out
add wave -group "Control Signals" /Matrix32_LED_framebuffer_tb/LAT
add wave -group "Control Signals" /Matrix32_LED_framebuffer_tb/OE

# Run
run 1 ms
```

### Tests in Testbench

1. ✅ **Clear framebuffer** - Alle pixels zwart
2. ✅ **Single pixels** - Individuele gekleurde pixels
3. ✅ **Horizontal line** - Cyan lijn
4. ✅ **Vertical line** - Magenta lijn
5. ✅ **Rectangle** - Wit kader
6. ✅ **Test patterns** - Hardware patronen vergelijking
7. ✅ **Mode switching** - Wissel tussen FB en pattern
8. ✅ **Byte-wide writes** - Performance test

---

## 📦 Platform Designer Setup

### Stap 1: Add Component

1. **Tools → IP Catalog**
2. **Add search path** → kies `Component/` directory
3. **Refresh** → component verschijnt
4. **Dubbel-klik** "32x32 RGB LED Matrix Controller"

### Stap 2: System Integration

```
Platform Designer System:
├── Clock Source (50 MHz)
├── Nios II Processor
├── On-chip Memory (voor code)
├── JTAG UART (voor printf)
├── Matrix32_LED_0 ← JE COMPONENT
│   ├── avalon_slave → verbind met Nios II data master
│   ├── clock → verbind met clk_0
│   ├── reset → verbind met clk_0_reset
│   └── led_matrix (conduit) → EXPORT naar top level
└── SDRAM Controller (optioneel)

Base Address Matrix: 0x00010000 (stel in bij "Base address")
```

### Stap 3: Generate & Build

1. **Generate HDL** → maakt `soc_system.vhd`
2. **Add top level** → gebruik `DE1_SoC_Matrix32_top.vhd`
3. **Add pin assignments** → kopieer `docs/PIN_ASSIGNMENTS_DE1_SOC.txt` naar .qsf
4. **Compile** → Quartus
5. **Program** → .sof naar FPGA

---

## 🎨 Voorbeeld Programma

Het voorbeeld (`software/example_main.c`) toont **7 demos**:

### Demo 1: Color Test
Doorloop alle 8 kleuren

### Demo 2: Smiley Face
Teken pixel art (ogen + mond)

### Demo 3: Shapes
Rechthoeken in verschillende kleuren

### Demo 4: Bouncing Pixel
Animatie van stuiterende pixel

### Demo 5: Gradient Patterns
Verticale en horizontale gradiënten

### Demo 6: Checkerboard
Schaakbord patroon in software

### Demo 7: Test Pattern Comparison
Vergelijk software FB met hardware patterns

---

## 🔌 Hardware Aansluiting

Gebruik **GPIO_0** pins op DE1-SoC:

| Matrix Pin | Signal | GPIO_0 Pin | FPGA Pin |
|------------|--------|------------|----------|
| 1          | R1     | GPIO_0[0]  | AC18     |
| 3          | G1     | GPIO_0[1]  | Y17      |
| 5          | B1     | GPIO_0[2]  | AD17     |
| 7          | R2     | GPIO_0[3]  | Y18      |
| 9          | G2     | GPIO_0[4]  | AK16     |
| 11         | B2     | GPIO_0[5]  | AK18     |
| 13         | A      | GPIO_0[6]  | AK19     |
| 14         | B      | GPIO_0[7]  | AJ19     |
| 15         | C      | GPIO_0[8]  | AJ17     |
| 16         | D      | GPIO_0[9]  | AJ16     |
| 17         | CLK    | GPIO_0[10] | AH18     |
| 18         | LAT    | GPIO_0[11] | AH17     |
| 19         | OE     | GPIO_0[12] | AG16     |

**⚠️ BELANGRIJK:**
- Matrix heeft **externe 5V/2-4A** voeding nodig!
- Verbind **GND** van matrix met DE1-SoC GND
- Check **pin 1 orientatie** op connector!

---

## 🛠️ Development Workflow

### 1. Simuleer in ModelSim
```bash
# Test framebuffer werking
vsim Matrix32_LED_framebuffer_tb
run 1 ms
```

### 2. Bouw Hardware
```bash
# Quartus compilatie
quartus_sh --flow compile <project_name>
```

### 3. Ontwikkel Software
```c
// In Nios II Software Build Tools
#include "matrix32_led.h"

int main() {
    matrix32_init(MATRIX32_LED_0_BASE);
    matrix32_set_mode(MATRIX32_LED_0_BASE, 0);  // Framebuffer
    matrix32_enable(MATRIX32_LED_0_BASE, 1);
    
    // Teken iets!
    matrix32_fill_rect(MATRIX32_LED_0_BASE, 10, 10, 12, 12, MATRIX32_COLOR_CYAN);
    
    while(1) { /* loop */ }
}
```

### 4. Download & Test
```bash
nios2-download -g matrix_app.elf
nios2-terminal
```

---

## 📊 Performance & Geheugen

### Framebuffer Geheugen
- **384 bytes** on-chip BRAM
- **Dual-port**: simultaneous read/write
- **1 clock cycle** write latency

### Refresh Rate
- **16 rows** multiplexed
- **32 CLK_out** cycles per row
- **~3 kHz** refresh rate (flicker-free!)

### Software Performance
```c
// Single pixel: ~60 clock cycles
matrix32_set_pixel(base, x, y, r, g, b);

// Full screen clear: ~8000 clock cycles (160 µs @ 50 MHz)
matrix32_clear(base);

// Draw line (32 pixels): ~2000 clock cycles
matrix32_draw_hline(base, 0, 31, y, color);
```

---

## 🐛 Troubleshooting

### "Component niet zichtbaar in IP Catalog"
- ✅ Check search path: `Tools → Options → IP Search Paths`
- ✅ Refresh: `View → Refresh System`
- ✅ Verifieer dat `matrix32_led_hw.tcl` in Component/ staat

### "Pixels worden niet weergegeven"
- ✅ Check mode: `matrix32_set_mode(base, 0)` voor framebuffer
- ✅ Check enable: `matrix32_enable(base, 1)`
- ✅ Verifieer base address in `system.h`
- ✅ Test met `matrix32_fill(base, MATRIX32_COLOR_WHITE)` voor all-on

### "Matrix blijft zwart op hardware"
- ✅ Externe 5V voeding aangesloten?
- ✅ Common ground (GND) verbonden?
- ✅ Pin assignments correct in .qsf?
- ✅ Pin 1 orientatie correct?

### "Compilation errors"
- ✅ VHDL-2008: gebruik `vcom -2008`
- ✅ Check dat alle bestanden in hdl/ staan
- ✅ Verifieer component port names in TCL

---

## 📚 Verdere Documentatie

- **../QUARTUS_PLATFORM_DESIGNER_GUIDE.md** - Platform Designer tutorial
- **../MODELSIM_HANDLEIDING.md** - Simulatie guide
- **docs/PIN_ASSIGNMENTS_DE1_SOC.txt** - Complete pin lijst

---

## 🎯 Volgende Stappen

1. **Simuleer** de testbench om framebuffer werking te verifiëren
2. **Integreer** in Platform Designer volgens README stappen
3. **Compileer** en program FPGA met top level
4. **Run** example_main.c om 7 demos te zien
5. **Ontwikkel** je eigen grafische applicatie!

---

## ✨ Features Samenvatting

✅ **384-byte framebuffer** met pixel-level controle  
✅ **Software API** met 15+ functies  
✅ **Dual-mode** (framebuffer / test patterns)  
✅ **Avalon Memory-Mapped** interface  
✅ **ModelSim testbench** met 8 tests  
✅ **DE1-SoC top level** kant-en-klaar  
✅ **Complete pin assignments**  
✅ **7-demo voorbeeld programma**  
✅ **HUB75 protocol** compliant  
✅ **3 kHz refresh** rate  

---

**Veel succes met je LED Matrix project! 🎨🚀**

*Vragen? Check de testbench of example code voor voorbeelden!*
