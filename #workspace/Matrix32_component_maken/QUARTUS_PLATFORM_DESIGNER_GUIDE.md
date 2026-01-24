# Platform Designer Component Guide - 32x32 LED Matrix
## Voor DE1-SoC Bord (Altera Cyclone V SoC 5CSEMA5F31C6N)

---

## 📋 Overzicht

Deze handleiding leidt je door het complete proces om je 32x32 LED Matrix VHDL component te integreren in Quartus Prime met Platform Designer (voorheen Qsys), zodat je het kunt aansturen vanuit een Nios II processor of HPS (Hard Processor System).

### 🎯 **Architectuur Filosofie**

**VHDL doet het ZWARE WERK automatisch:**
- ✅ Matrix scanning (16 gemultiplexte rijen)
- ✅ HUB75 protocol timing (CLK, LAT, OE)
- ✅ Framebuffer opslag (384 bytes in FPGA)
- ✅ Real-time refresh (constant >1kHz)

**C code is SUPER EENVOUDIG:**
- 📝 `matrix32_set_pixel(x, y, r, g, b)` - één regel!
- 📝 `matrix32_fill(color)` - hele matrix vullen
- 📝 Hardware toont direct resultaat

Zie [ARCHITECTUUR_OVERZICHT.md](ARCHITECTUUR_OVERZICHT.md) voor complete technische details.

---

## 🎯 Projectstructuur

### Wat gaan we maken?
```
DE1-SoC Project
├── FPGA Fabric
│   ├── Nios II Processor (of HPS bridge)
│   ├── Avalon Memory-Mapped Bus
│   └── Matrix32_LED Component (ons custom component)
│       ├── Avalon Slave Interface (5 registers)
│       │   ├── CONTROL (enable, mode)
│       │   ├── PATTERN (test patronen)
│       │   ├── FB_ADDR (framebuffer adres)
│       │   ├── FB_DATA (framebuffer data schrijven)
│       │   └── STATUS (read-only status)
│       ├── Framebuffer (384 bytes in FPGA)
│       ├── Scanning Hardware (automatisch!)
│       └── Conduit naar externe LED matrix pins
└── Hardware Pins
    └── GPIO_1 pins naar 32x32 LED Matrix (HUB75)
```

---

## 📁 STAP 1: Project Organisatie

### 1.1 Directory Structuur Aanmaken

Maak de volgende mappenstructuur aan:

```
Matrix32_component_maken/
├── Component/                    # Platform Designer component
│   ├── hdl/
│   │   ├── Matrix32_LED.vhd              # Core (scanning hardware)
│   │   ├── Matrix32_LED_avalon.vhd       # Avalon wrapper
│   │   ├── DE1_SoC_Matrix32_top.vhd      # Top-level voor FPGA
│   │   └── Matrix32_LED_framebuffer_tb.vhd # Testbench
│   ├── software/
│   │   ├── matrix32_led.h                # Driver header
│   │   ├── matrix32_led.c                # Driver implementatie
│   │   ├── example_main.c                # Voorbeeldcode
│   │   └── README_EENVOUDIG.md           # Software guide
│   ├── docs/
│   │   └── PIN_ASSIGNMENTS_DE1_SOC.txt   # Pin mapping
│   └── matrix32_led_hw.tcl               # Platform Designer TCL
├── quartus/                              # Quartus project (jouw)
│   ├── DE1_SoC_Matrix.qpf
│   ├── DE1_SoC_Matrix.qsf
│   └── soc_system/                       # Platform Designer output
├── Matrix32_LED.vhd                      # Root versie (voor testbench)
├── Matrix32_LED_tb.vhd                   # ModelSim testbench
├── ARCHITECTUUR_OVERZICHT.md             # Technische architectuur
└── QUARTUS_PLATFORM_DESIGNER_GUIDE.md    # Deze guide
```

### 1.2 Bestanden Kopiëren

```powershell
# Gebruik de bestaande Component directory structuur
# Alles staat al op de juiste plek in Component/

# Optioneel: Maak een Quartus project directory
New-Item -ItemType Directory -Path "quartus" -Force

# Controleer of alle bestanden aanwezig zijn
Test-Path "Component\hdl\Matrix32_LED.vhd"
Test-Path "Component\hdl\Matrix32_LED_avalon.vhd"
Test-Path "Component\matrix32_led_hw.tcl"
Test-Path "Component\software\matrix32_led.h"
Test-Path "Component\software\matrix32_led.c"
```

---

## 🔧 STAP 2: VHDL Component Aanpassen voor Avalon Interface

### 2.1 Avalon Memory-Mapped Slave Interface Toevoegen

Maak een wrapper: `hdl/Matrix32_LED_avalon.vhd`

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Matrix32_LED_avalon is
    Port (
        -- Avalon Clock and Reset Interface
        csi_clk             : in  std_logic;
        rsi_reset_n         : in  std_logic;
        
        -- Avalon Memory-Mapped Slave Interface
        avs_s0_address      : in  std_logic_vector(1 downto 0);  -- 4 registers
        avs_s0_write        : in  std_logic;
        avs_s0_writedata    : in  std_logic_vector(31 downto 0);
        avs_s0_read         : in  std_logic;
        avs_s0_readdata     : out std_logic_vector(31 downto 0);
        avs_s0_chipselect   : in  std_logic;
        
        -- Conduit to External LED Matrix (exported to top level)
        coe_matrix_R1       : out std_logic;
        coe_matrix_G1       : out std_logic;
        coe_matrix_B1       : out std_logic;
        coe_matrix_R2       : out std_logic;
        coe_matrix_G2       : out std_logic;
        coe_matrix_B2       : out std_logic;
        coe_matrix_A        : out std_logic;
        coe_matrix_B        : out std_logic;
        coe_matrix_C        : out std_logic;
        coe_matrix_D        : out std_logic;
        coe_matrix_CLK      : out std_logic;
        coe_matrix_LAT      : out std_logic;
        coe_matrix_OE       : out std_logic
    );
end Matrix32_LED_avalon;

architecture Behavioral of Matrix32_LED_avalon is
    
    -- Component declaration
    component Matrix32_LED is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            R1, G1, B1   : out std_logic;
            R2, G2, B2   : out std_logic;
            A, B, C, D   : out std_logic;
            CLK_out      : out std_logic;
            LAT          : out std_logic;
            OE           : out std_logic;
            test_pattern : in  std_logic_vector(2 downto 0)
        );
    end component;
    
    -- Internal registers (Avalon slave registers)
    signal reg_control      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_pattern      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_brightness   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_status       : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Internal signals
    signal reset_internal   : std_logic;
    signal enable           : std_logic;
    signal test_pattern_int : std_logic_vector(2 downto 0);
    
begin
    
    -- Convert Avalon reset (active low) to internal reset (active high)
    reset_internal <= not rsi_reset_n;
    
    -- Extract control signals from registers
    enable           <= reg_control(0);
    test_pattern_int <= reg_pattern(2 downto 0);
    
    -- Instantiate the Matrix32_LED core
    matrix_core : Matrix32_LED
        port map (
            clk          => csi_clk,
            reset        => reset_internal,
            R1           => coe_matrix_R1,
            G1           => coe_matrix_G1,
            B1           => coe_matrix_B1,
            R2           => coe_matrix_R2,
            G2           => coe_matrix_G2,
            B2           => coe_matrix_B2,
            A            => coe_matrix_A,
            B            => coe_matrix_B,
            C            => coe_matrix_C,
            D            => coe_matrix_D,
            CLK_out      => coe_matrix_CLK,
            LAT          => coe_matrix_LAT,
            OE           => coe_matrix_OE,
            test_pattern => test_pattern_int
        );
    
    -- Avalon Slave Write Process
    process(csi_clk, rsi_reset_n)
    begin
        if rsi_reset_n = '0' then
            reg_control    <= (others => '0');
            reg_pattern    <= (others => '0');
            reg_brightness <= x"000000FF";  -- Default brightness
            
        elsif rising_edge(csi_clk) then
            if avs_s0_chipselect = '1' and avs_s0_write = '1' then
                case avs_s0_address is
                    when "00" =>  -- Address 0x0: Control Register
                        reg_control <= avs_s0_writedata;
                    when "01" =>  -- Address 0x4: Pattern Register
                        reg_pattern <= avs_s0_writedata;
                    when "10" =>  -- Address 0x8: Brightness Register
                        reg_brightness <= avs_s0_writedata;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;
    
    -- Avalon Slave Read Process
    process(csi_clk)
    begin
        if rising_edge(csi_clk) then
            avs_s0_readdata <= (others => '0');  -- Default
            
            if avs_s0_chipselect = '1' and avs_s0_read = '1' then
                case avs_s0_address is
                    when "00" =>  -- Address 0x0: Control Register
                        avs_s0_readdata <= reg_control;
                    when "01" =>  -- Address 0x4: Pattern Register
                        avs_s0_readdata <= reg_pattern;
                    when "10" =>  -- Address 0x8: Brightness Register
                        avs_s0_readdata <= reg_brightness;
                    when "11" =>  -- Address 0xC: Status Register
                        avs_s0_readdata <= reg_status;
                    when others =>
                        avs_s0_readdata <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    -- Status register (read-only, shows component state)
    reg_status(0) <= enable;
    reg_status(3 downto 1) <= test_pattern_int;
    reg_status(31 downto 4) <= (others => '0');

end Behavioral;
```

**Register Map:**| Access | Description
--------|------------|--------|--------------------------------------------------
0x00    | CONTROL    | R/W    | [0]: Enable (1=run, 0=stop)
        |            |        | [1]: Mode (0=framebuffer, 1=test pattern)
0x04    | PATTERN    | R/W    | [2:0]: Test pattern select (0-7)
0x08    | FB_ADDR    | R/W    | [11:0]: Framebuffer write address (0-383)
0x0C    | FB_DATA    | R/W    | [7:0]: Framebuffer write data (8 pixels)
        |            |        | Writing triggers framebuffer update!
0x10    | STATUS     | R      | [0]: Enable, [1]: Mode, [4:2]: Pattern
```

**Framebuffer Layout (384 bytes in FPGA):**
```
Bytes   0-127:  RED   channel (32×32 pixels = 1024 bits)
Bytes 128-255:  GREEN channel (32×32 pixels = 1024 bits)
Bytes 256-383:  BLUE  channel (32×32 pixels = 1024 bits)

Elk byte = 8 pixels (1 bit per pixel per kleur)
0x08    | BRIGHTNESS        | R/W    | [7:0]: Brightness (0-255)
0x0C    | STATUS            | R      | [0]: Running, [3:1]: Current pattern
```

---

## 📜 STAP 3: Platform Designer Component Definitie (TCL)

### 3.1 Maak Component Definitie Bestand

**Gebruik het bestaande bestand:** `Component/matrix32_led_hw.tcl`

Dit bestand is al compleet en bevat:
- Module properties (naam, versie, auteur)
- File sets (VHDL bestanden)
- Avalon Clock interface
- Avalon Reset interface  
- Avalon Memory-Mapped Slave (5 registers, 3-bit address)
- Conduit interface (13 LED matrix signalen)

**Belangrijke eigenschappen in de TCL:**

```tcl
# Avalon Slave: 5 registers (3-bit address = 8 words max)
add_interface_port avalon_slave avs_s0_address address Input 3
add_interface_port avalon_slave avs_s0_writedata writedata Input 32
add_interface_port avalon_slave avs_s0_readdata readdata Output 32

# Conduit: Alle HUB75 signalen
add_interface_port led_matrix coe_matrix_R1 R1 Output 1
add_interface_port led_matrix coe_matrix_G1 G1 Output 1
# ... (totaal 13 signalen)
```

Het bestand staat al in `Component/matrix32_led_hw.tcl` en hoeft niet aangepast!

---

## 🏗️ STAP 4: Quartus Project Setup

### 4.1 Nieuw Quartus Project Aanmaken

1. **Start Quartus Prime**
   ```
   Menu: File → New Project Wizard
   ```

2. **Project Naam & Locatie**
   - Directory: `Matrix32_Platform_Designer/quartus/`
   - Project name: `DE1_SoC_Matrix`
   - Top-level entity: `DE1_SoC_Matrix_top`

3. **Add Files**
   - Skip (we voegen later toe via Platform Designer)

4. **Device Selection**
   - Family: `Cyclone V`
   - Device: `5CSEMA5F31C6`
   - Dit is de chip op het DE1-SoC bord

5. **EDA Tool Settings**
   - Simulation: ModelSim-Altera
   - Format: VHDL

6. **Finish**

### 4.2 IP Catalog Toevoegen

1. **Ga naar Tools → IP Catalog**

2. **Voeg custom IP toe:**
   ```
   IP Catalog → IP Search Locations (rechter muisknop)
   → Add...
   → Selecteer: [jouw_project]\Component\
   ```

3. **Refresh IP Catalog**
   - Je zou nu "32x32 RGB LED Matrix Controller" moeten zien onder "CSC10 Custom Components"

---

## 🎨 STAP 5: Platform Designer System Maken

### 5.1 Platform Designer Openen

1. **Start Platform Designer**
   ```
   Menu: Tools → Platform Designer
   ```

2. **Sla op als:**
   - `quartus/soc_system.qsys`

### 5.2 System Componenten Toevoegen

#### A. Clock Source
```
IP Catalog → Library → Basic Functions → Clocks → Clock Source
→ Dubbel-klik om toe te voegen
```
- **Naam**: `clk_0`
- **Clock frequency**: `50.0 MHz` (DE1-SoC heeft 50 MHz oscillator)

#### B. Nios II Processor (Optioneel - voor software control)
```
IP Catalog → Processors → Nios II → Nios II Processor
```
- **Naam**: `nios2_gen2_0`
- **Type**: Nios II/e (Economy) of Nios II/f (Fast)
- **Reset vector**: `onchip_memory.s1`
- **Exception vector**: `onchip_memory.s1`

#### C. On-Chip Memory (voor Nios II code)
```
IP Catalog → Basic Functions → On-Chip Memory → On-Chip Memory (RAM or ROM)
```
- **Naam**: `onchip_memory`
- **Type**: RAM
- **Total memory size**: `65536 bytes` (64 KB)
- **Data width**: `32 bits`

#### D. JTAG UART (voor debugging)
```
IP Catalog → Interface Protocols → Serial → JTAG UART
```
- **Naam**: `jtag_uart_0`
- Default settings OK

#### E. System ID Peripheral
```
IP Catalog → Basic Functions → Peripherals → System ID Peripheral
```
- **Naam**: `sysid_qsys_0`
- Default settings OK

#### F. PIO (Parallel I/O) voor KEY Buttons

**Stap-voor-stap: PIO Component Toevoegen**

1. **Zoek PIO in IP Catalog**
   ```
   IP Catalog → Basic Functions → Peripherals → PIO (Parallel I/O)
   ```
   - **Dubbel-klik** om toe te voegen

2. **Configuratie venster**
   ```
   ┌─────────────────────────────────────────────┐
   │ Add PIO (Parallel I/O)                      │
   ├─────────────────────────────────────────────┤
   │ Name: pio_key                               │
   │                                             │
   │ Parameters:                                 │
   │   Width: 4                  (4 KEY buttons)│
   │   Direction: Input only                     │
   │   ☑ Synchronously capture                   │
   │   ☐ Set bit-clearing for edge capture reg   │
   │   ☑ Generate IRQ (Edge Capture Interrupt)   │
   │   ☐ Edge type: RISING edge                  │
   │   ☑ Edge type: FALLING edge (active-low!)   │
   │                                             │
   │ [ Finish ]  [ Cancel ]                      │
   └─────────────────────────────────────────────┘
   ```

3. **Belangrijke instellingen:**
   - **Name**: `pio_key`
   - **Width**: `4` (KEY0, KEY1, KEY2, KEY3)
   - **Direction**: `Input only`
   - **Synchronously capture**: ✓ (voor stabiele input)
   - **Generate IRQ**: ✓ (optioneel - voor interrupt op button press)
   - **Edge type**: `FALLING` (DE1-SoC buttons zijn active-low!)

4. **Component features:**
   - 4-bit input port voor KEY[3:0]
   - Edge capture register (detecteert button press)
   - Interrupt capability (optioneel gebruik in software)
   - Debouncing moet in software (of externe hardware)

#### G. LED Matrix Component (Ons custom IP!)

**OPTIE 1: Handmatig nieuw component aanmaken in Platform Designer**

Je kunt zelf een nieuw component aanmaken zonder de TCL file te gebruiken:

**Stap-voor-stap: Nieuw component maken**

1. **Open Platform Designer** (als nog niet open)

2. **Ga naar: File → New Component...**
   ```
   Dit opent de "Component Editor" window
   ```

3. **Component Type tab - Basisinformatie invullen:**
   ```
   ┌─────────────────────────────────────────────┐
   │ Component Editor - Component Type           │
   ├─────────────────────────────────────────────┤
   │ Name: matrix32_led                          │
   │ Display name: 32x32 RGB LED Matrix          │
   │ Version: 1.0                                │
   │ Description: 32x32 RGB LED Matrix Controller│
   │              with Framebuffer               │
   │                                             │
   │ Group: CSC10 Custom Components              │
   │                                             │
   │ [ Next > ]                                  │
   └─────────────────────────────────────────────┘
   ```

4. **Files tab - VHDL bestanden toevoegen:**
   
   a. **Klik op "Add File..."**
   
   b. **Browse naar:** `Component\hdl\Matrix32_LED_avalon.vhd`
      - ☑ **Copy file to component directory**: UNCHECKED (we willen origineel gebruiken)
      - **File type**: VHDL
      - ☑ **This file defines the top-level module**: CHECKED
      
   c. **Klik "Add File..." opnieuw**
   
   d. **Browse naar:** `Component\hdl\Matrix32_LED.vhd`
      - ☑ **Copy file to component directory**: UNCHECKED
      - **File type**: VHDL
      - ☐ **This file defines the top-level module**: UNCHECKED (alleen avalon file is top!)

5. **Signals & Interfaces tab - Interfaces toevoegen:**

   **5a. Clock Interface toevoegen:**
   ```
   Klik: Add Interface → Clock Input
   
   Interface Properties:
   - Name: clock
   - Type: clock (end)
   - Associated Clock: (none)
   - Associated Reset: reset
   
   Signals:
   - Klik "Add Signal"
   - Signal name: clk
   - Direction: Input
   - Width: 1
   - HDL signal name: csi_clk
   ```

   **5b. Reset Interface toevoegen:**
   ```
   Klik: Add Interface → Reset Input
   
   Interface Properties:
   - Name: reset
   - Type: reset (end)
   - Associated Clock: clock
   
   Signals:
   - Klik "Add Signal"
   - Signal name: reset_n
   - Direction: Input
   - Width: 1
   - HDL signal name: rsi_reset_n
   - Signal Type: reset_n (active low)
   ```

   **5c. Avalon Memory-Mapped Slave Interface:**
   ```
   Klik: Add Interface → Avalon Memory Mapped Slave
   
   Interface Properties:
   - Name: avalon_slave
   - Type: avalon (end)
   - Associated Clock: clock
   - Associated Reset: reset
   
   Timing:
   - Read Wait States: 0
   - Write Wait States: 0
   - Setup Time: 0
   - Hold Time: 0
   
   Address Alignment:
   - Address Units: Words (32-bit)
   - Address Width: 3 bits (= 8 words = 32 bytes)
   - Data Width: 32 bits
   
   Signals - Klik "Add Signal" voor elk:
   
   Signal 1:
   - Signal name: address
   - Direction: Input
   - Width: 3
   - HDL signal name: avs_s0_address
   - Signal Type: address
   
   Signal 2:
   - Signal name: write
   - Direction: Input
   - Width: 1
   - HDL signal name: avs_s0_write
   - Signal Type: write
   
   Signal 3:
   - Signal name: writedata
   - Direction: Input
   - Width: 32
   - HDL signal name: avs_s0_writedata
   - Signal Type: writedata
   
   Signal 4:
   - Signal name: read
   - Direction: Input
   - Width: 1
   - HDL signal name: avs_s0_read
   - Signal Type: read
   
   Signal 5:
   - Signal name: readdata
   - Direction: Output
   - Width: 32
   - HDL signal name: avs_s0_readdata
   - Signal Type: readdata
   
   Signal 6:
   - Signal name: chipselect
   - Direction: Input
   - Width: 1
   - HDL signal name: avs_s0_chipselect
   - Signal Type: chipselect
   ```

   **5d. Conduit Interface (LED Matrix pins):**
   ```
   Klik: Add Interface → Conduit
   
   Interface Properties:
   - Name: led_matrix
   - Type: conduit (end)
   - Associated Clock: (none)
   - Associated Reset: (none)
   
   Signals - Klik "Add Signal" 13 keer voor elke LED pin:
   
   ⚠️ BELANGRIJK: Elk signaal moet een UNIEKE role hebben!
   Signal Type/Role moet de NAAM van het signaal zijn, NIET "export"!
   
   Signal 1:
   - Signal name: R1
   - HDL signal name: coe_matrix_R1
   - Direction: Output
   - Width: 1
   - Signal Type/Role: R1          ← BELANGRIJK: unieke naam!
   
   Signal 2:
   - Signal name: G1
   - HDL signal name: coe_matrix_G1
   - Direction: Output
   - Width: 1
   - Signal Type/Role: G1          ← BELANGRIJK: unieke naam!
   
   Signal 3:
   - Signal name: B1
   - HDL signal name: coe_matrix_B1
   - Direction: Output
   - Width: 1
   - Signal Type/Role: B1          ← BELANGRIJK: unieke naam!
   
   Signal 4:
   - Signal name: R2
   - HDL signal name: coe_matrix_R2
   - Direction: Output
   - Width: 1
   - Signal Type/Role: R2          ← BELANGRIJK: unieke naam!
   
   Signal 5:
   - Signal name: G2
   - HDL signal name: coe_matrix_G2
   - Direction: Output
   - Width: 1
   - Signal Type/Role: G2          ← BELANGRIJK: unieke naam!
   
   Signal 6:
   - Signal name: B2
   - HDL signal name: coe_matrix_B2
   - Direction: Output
   - Width: 1
   - Signal Type/Role: B2          ← BELANGRIJK: unieke naam!
   
   Signal 7:
   - Signal name: A
   - HDL signal name: coe_matrix_A
   - Direction: Output
   - Width: 1
   - Signal Type/Role: A           ← BELANGRIJK: unieke naam!
   
   Signal 8:
   - Signal name: B
   - HDL signal name: coe_matrix_B
   - Direction: Output
   - Width: 1
   - Signal Type/Role: B           ← BELANGRIJK: unieke naam!
   
   Signal 9:
   - Signal name: C
   - HDL signal name: coe_matrix_C
   - Direction: Output
   - Width: 1
   - Signal Type/Role: C           ← BELANGRIJK: unieke naam!
   
   Signal 10:
   - Signal name: D
   - HDL signal name: coe_matrix_D
   - Direction: Output
   - Width: 1
   - Signal Type/Role: D           ← BELANGRIJK: unieke naam!
   
   Signal 11:
   - Signal name: CLK
   - HDL signal name: coe_matrix_CLK
   - Direction: Output
   - Width: 1
   - Signal Type/Role: CLK         ← BELANGRIJK: unieke naam!
   
   Signal 12:
   - Signal name: LAT
   - HDL signal name: coe_matrix_LAT
   - Direction: Output
   - Width: 1
   - Signal Type/Role: LAT         ← BELANGRIJK: unieke naam!
   
   Signal 13:
   - Signal name: OE
   - HDL signal name: coe_matrix_OE
   - Direction: Output
   - Width: 1
   - Signal Type/Role: OE          ← BELANGRIJK: unieke naam!
   
   ⚠️ FOUT die je NIET moet maken:
   - Signal Type/Role: export      ← FOUT! Niet allemaal "export"!
   - Elk signaal moet zijn eigen unieke role naam hebben (R1, G1, B1, etc.)
   ```

6. **Parameters tab:**
   - Laat leeg (geen parameters nodig)

7. **Software Files tab:**
   - Optioneel: Voeg `Component\software\matrix32_led.h` en `.c` toe als driver files
   - Dit is niet verplicht, maar handig voor later

8. **Finish:**
   ```
   Klik: File → Save Component
   → Save in: Component\ directory
   → Component is nu opgeslagen en klaar voor gebruik!
   ```

9. **Component toevoegen aan systeem:**
   ```
   In Platform Designer main window:
   → IP Catalog
   → Vouw uit: Library → CSC10 Custom Components
   → Dubbel-klik: "32x32 RGB LED Matrix"
   → Component verschijnt als "matrix32_led_0" in System Contents
   ```

---

**OPTIE 2: Gebruik bestaande TCL file (sneller)**

**Stap-voor-stap: Custom Component Toevoegen**

1. **Open IP Catalog in Platform Designer**
   - Klik op het **IP Catalog** tabblad (rechts in Platform Designer venster)
   - Of: Menu → **IP Catalog**

2. **Zoek jouw custom component**
   - Vouw de categorieën uit in de boom structuur
   - Navigeer naar: **Library → CSC10 Custom Components**
   - Je zou moeten zien: **"32x32 RGB LED Matrix Controller"**
   
   **TIP:** Als je het component niet ziet:
   - Controleer of je de Component/ directory hebt toegevoegd in Stap 4.2
   - Klik op **Refresh** (icoon rechtsboven in IP Catalog)
   - Herstart Platform Designer indien nodig

3. **Component toevoegen aan systeem**
   - **Dubbel-klik** op "32x32 RGB LED Matrix Controller"
   - Of: Rechter muisknop → **Add...**
   
4. **Component configuratie venster opent**
   ```
   ┌─────────────────────────────────────────────┐
   │ Add 32x32 RGB LED Matrix Controller         │
   ├─────────────────────────────────────────────┤
   │ Name: matrix32_led_0                        │
   │                                             │
   │ Parameters:                                 │
   │   (Geen parameters - alles is hard-coded)  │
   │                                             │
   │ [ Finish ]  [ Cancel ]                      │
   └─────────────────────────────────────────────┘
   ```
   
   - **Name**: Laat staan als `matrix32_led_0` (of wijzig naar jouw voorkeur)
   - **Parameters**: Dit component heeft geen configureerbare parameters
   - Klik **Finish**

5. **Component verschijnt in System Contents**
   - Je ziet nu `matrix32_led_0` in de lijst met componenten
   - Het component heeft:
     - **clock** interface (moet verbonden worden met clk_0)
     - **reset** interface (moet verbonden worden met clk_0)
     - **avalon_slave** interface (voor Nios II verbinding)
     - **led_matrix** conduit (voor externe LED matrix pins)

6. **Verifieer component eigenschappen**
   - Klik op `matrix32_led_0` in de System Contents lijst
   - Kijk rechtsonder in het **Component Details** panel:
     - **Address span**: 32 bytes (8 words × 4 bytes)
     - **Data width**: 32 bits
     - **Interfaces**: Clock, Reset, Avalon Slave, Conduit

**Component Features:**
- Framebuffer: 384 bytes in FPGA Block RAM
- Automatische matrix scanning (16 rijen gemultiplexed)
- 5 registers (CONTROL, PATTERN, FB_ADDR, FB_DATA, STATUS)
- HUB75 protocol timing volledig in hardware

---

### ⚠️ TROUBLESHOOTING: Component verschijnt niet of heeft verkeerde interfaces

**Als je het component NIET ziet in System Contents, of als de interfaces niet kloppen:**

#### STAP 1: Verifieer dat TCL en VHDL files bestaan

Open PowerShell in je workspace directory:

```powershell
# Controleer of bestanden bestaan
Test-Path "Component\matrix32_led_hw.tcl"          # Moet True zijn
Test-Path "Component\hdl\Matrix32_LED.vhd"         # Moet True zijn  
Test-Path "Component\hdl\Matrix32_LED_avalon.vhd"  # Moet True zijn

# Check TCL file naam in de file zelf
Get-Content "Component\matrix32_led_hw.tcl" | Select-String "set_module_property NAME"
# Output MOET zijn: set_module_property NAME matrix32_led
```

#### STAP 2: Verifieer IP Catalog configuratie in Quartus

1. **Ga naar Tools → IP Catalog** (in hoofdvenster Quartus, NIET Platform Designer!)
2. **Rechter muisknop op "IP Catalog" → IP Search Locations...**
3. **Controleer lijst:**
   - Is het pad naar `Component\` directory aanwezig?
   - Volledige pad moet zijn: `C:\Users\mitch\Documents\GitHub\CSC10\#workspace\Matrix32_component_maken\Component`
   
4. **Als het pad NIET in lijst staat of verkeerd is:**
   ```
   → Click "Add..."
   → Browse naar: C:\Users\mitch\Documents\GitHub\CSC10\#workspace\Matrix32_component_maken\Component
   → OK
   → OK
   ```

5. **Refresh IP Catalog:**
   - Klik op refresh icoon (🔄) rechtsboven
   - Of: Sluit en heropen Tools → IP Catalog

#### STAP 3: Check of component verschijnt in IP Catalog

In Quartus IP Catalog (Tools → IP Catalog):

```
Vouw uit: Library
  → CSC10 Custom Components
    → Moet zien: "32x32 RGB LED Matrix Controller"
```

**Als je het NIET ziet:**
- Check Messages window (View → Utility Windows → Messages)
- Filter op "IP" of "TCL"
- Zoek naar error messages over de TCL file

#### STAP 4: Handmatig TCL file laden in Platform Designer

1. **Open Platform Designer** (Tools → Platform Designer)
2. **Ga naar: Tools → TCL Scripts...**
3. **Browse naar:** `Component\matrix32_led_hw.tcl`
4. **Click "Run"**
5. **Check Console output onderaan:**
   - Geen errors? → Component is geladen
   - Errors? → Read de error message zorgvuldig

**Veelvoorkomende errors:**
- `"entity matrix32_led not found"` → Check of VHDL files in `Component\hdl\` staan
- `"invalid command name"` → TCL syntax error in matrix32_led_hw.tcl
- `"file not found"` → Pad naar VHDL files klopt niet in TCL

#### STAP 5: Verifieer Entity naam in VHDL

Open: `Component\hdl\Matrix32_LED_avalon.vhd`

**De eerste 15 regels MOETEN zijn:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity matrix32_led is  -- <-- LET OP: Naam moet EXACT "matrix32_led" zijn!
    Port (
        -- Avalon Clock and Reset Interface
        csi_clk             : in  std_logic;
        rsi_reset_n         : in  std_logic;
        
        -- Avalon Memory-Mapped Slave Interface  
        avs_s0_address      : in  std_logic_vector(2 downto 0);
        avs_s0_write        : in  std_logic;
```

**⚠️ KRITIEK:** 
- Entity naam MOET `matrix32_led` zijn (zonder `_avalon`!)
- Port namen MOETEN beginnen met: `csi_`, `rsi_`, `avs_`, `coe_`
- Dit zijn Avalon naming conventions!

#### STAP 6: Check TCL file syntax

Open: `Component\matrix32_led_hw.tcl`

**Belangrijke regels om te checken:**

```tcl
# Regel ~5 - Module naam
set_module_property NAME matrix32_led  # Moet EXACT matchen met entity naam!

# Regel ~35 - HDL files (moeten relatief pad hebben)
add_fileset_file Matrix32_LED_avalon.vhd VHDL PATH hdl/Matrix32_LED_avalon.vhd TOP_LEVEL_FILE
add_fileset_file Matrix32_LED.vhd VHDL PATH hdl/Matrix32_LED.vhd

# Regel ~50 - Avalon slave interface naam
add_interface avalon_slave avalon end  # Naam moet avalon_slave zijn

# Regel ~95 - Conduit interface naam  
add_interface led_matrix conduit end   # Naam moet led_matrix zijn
```

#### STAP 7: Fresh restart

Als alles faalt:

1. **Sluit Platform Designer** (File → Exit)
2. **Sluit Quartus completely**
3. **Herstart Quartus**
4. **Tools → IP Catalog → Refresh** (🔄 icoon)
5. **Zoek component in IP Catalog** (moet nu verschijnen)
6. **Open Platform Designer opnieuw**
7. **IP Catalog → CSC10 Custom Components → Dubbel-klik component**

#### STAP 8: Verificatie - Component succesvol toegevoegd

**Als het werkt, zie je dit in Platform Designer System Contents:**

```
System Contents lijst:
✅ matrix32_led_0
   Interfaces:
   - clock         (type: clock)       → Verbind met clk_0
   - reset         (type: reset)       → Verbind met clk_0  
   - avalon_slave  (type: avalon)      → Nios II master verbindt hiermee
   - led_matrix    (type: conduit)     → Export naar top-level (zie stap 5.4)
```

**Klik op `matrix32_led_0` en check rechtsonder in Component Details:**
- **Module**: matrix32_led
- **Version**: 1.0
- **Description**: 32x32 RGB LED Matrix Controller with Framebuffer
- **Address span**: 32 bytes
- **Data width**: 32 bits

**Als dit allemaal klopt → Ga verder met Stap 5.3 (Connections maken)**

**Als het NOG STEEDS niet werkt:**
- Pak de error message uit Platform Designer Console
- Check of de VHDL files geen syntax errors hebben
- Open Matrix32_LED_avalon.vhd in Quartus en check voor compile errors

---

**⚠️ TROUBLESHOOTING: Component verschijnt niet of heeft verkeerde interfaces**

Als je het component niet ziet, of als het niet de verwachte interfaces heeft:

**STAP 1: Verifieer TCL file**
```powershell
# Controleer of TCL file bestaat
Test-Path "Component\matrix32_led_hw.tcl"
# Moet True teruggeven

# Open de file en check de naam
Get-Content "Component\matrix32_led_hw.tcl" | Select-String "set_module_property NAME"
# Moet tonen: set_module_property NAME matrix32_led
```

**STAP 2: Verifieer VHDL files**
```powershell
# Check of VHDL bestanden bestaan
Test-Path "Component\hdl\Matrix32_LED.vhd"
Test-Path "Component\hdl\Matrix32_LED_avalon.vhd"
# Beide moeten True zijn
```

**STAP 3: Verifieer IP Catalog configuratie**
1. **In Quartus: Tools → IP Catalog**
2. **Klik rechts op "IP Catalog" → IP Search Locations...**
3. **Controleer of de Component/ directory in de lijst staat**
   - Pad moet zijn: `C:\Users\mitch\Documents\GitHub\CSC10\#workspace\Matrix32_component_maken\Component`
   - Of het volledige pad naar jouw Component/ directory
4. **Als het pad niet klopt:**
   - Remove het verkeerde pad
   - Add... → Browse naar correcte Component/ directory
   - OK

**STAP 4: Refresh IP Catalog**
1. **In Platform Designer: Klik op het refresh icoon** (🔄 rechtsboven in IP Catalog)
2. **Of: Sluit Platform Designer en open opnieuw**
3. **Check Messages tab onderaan** voor errors

**STAP 5: Controleer TCL errors**

Open `Component\matrix32_led_hw.tcl` en verifieer deze regels:

```tcl
# Regel ~5: Module naam MOET matrix32_led zijn (zonder _hw)
set_module_property NAME matrix32_led

# Regel ~50: Avalon slave MOET avalon_slave heten
add_interface avalon_slave avalon end

# Regel ~95: Conduit MOET led_matrix heten
add_interface led_matrix conduit end
set_interface_property led_matrix EXPORT_OF ""
```

**STAP 6: Entity naam in VHDL**

Open `Component\hdl\Matrix32_LED_avalon.vhd` en check:

```vhdl
-- Regel 1-10: Entity naam MOET exact matrix32_led zijn
entity matrix32_led is
    Port (
        -- Avalon interfaces met EXACTE namen:
        csi_clk             : in  std_logic;
        rsi_reset_n         : in  std_logic;
        avs_s0_address      : in  std_logic_vector(2 downto 0);
        -- ...
        coe_matrix_R1       : out std_logic;
        -- ...
    );
end matrix32_led;
```

**⚠️ LET OP:** Entity naam in VHDL MOET EXACT overeenkomen met TCL!
- TCL: `set_module_property NAME matrix32_led`
- VHDL: `entity matrix32_led is`

**STAP 7: Als component nog steeds niet verschijnt**

1. **Check Quartus Messages window** (View → Utility Windows → Messages)
   - Filter op "IP Catalog" of "TCL"
   - Zoek naar error messages

2. **Handmatig TCL uitvoeren in Platform Designer:**
   ```
   Platform Designer → Tools → TCL Scripts...
   → Browse naar Component\matrix32_led_hw.tcl
   → Run
   ```
   - Check Console output voor errors

3. **Verifieer file permissions**
   ```powershell
   # Check of files read-only zijn
   Get-ChildItem -Path "Component\hdl\*.vhd" | Select-Object Name, IsReadOnly
   Get-ChildItem -Path "Component\*.tcl" | Select-Object Name, IsReadOnly
   ```

**STAP 8: Fresh start**

Als alles faalt:
1. Sluit Platform Designer
2. Sluit Quartus
3. Herstart Quartus
4. Tools → IP Catalog → Refresh
5. Tools → Platform Designer
6. Probeer component opnieuw toe te voegen

**Na succesvolle toevoeging zie je:**
- Component: `matrix32_led_0` in System Contents lijst
- Interfaces:
  - ✅ clock (type: clock, moet naar clk_0)
  - ✅ reset (type: reset, moet naar clk_0)
  - ✅ avalon_slave (type: avalon, Nios II master verbindt hier)
  - ✅ led_matrix (type: conduit, exporteer naar top-level)

**Na toevoegen: Connecties maken (zie Stap 5.3)**

### 5.3 Connections Maken

**⚠️ EERST VERIFIËREN:** Controleer of alle componenten correct zijn toegevoegd:

```
System Contents moet bevatten:
✅ clk_0 (Clock Source)
✅ nios2_gen2_0 (Nios II Processor)  
✅ onchip_memory (On-Chip Memory)
✅ jtag_uart_0 (JTAG UART)
✅ sysid_qsys_0 (System ID)
✅ pio_key (PIO - Parallel I/O)
✅ matrix32_led_0 (32x32 LED Matrix Controller)
```

Als `matrix32_led_0` NIET in de lijst staat, ga terug naar Stap 5.2G en volg de troubleshooting stappen!

Verbind alle componenten via de **Connection Column**:

| Component          | Clock   | Reset     | Master             | Slave              | IRQ |
|--------------------|---------|-----------|--------------------|--------------------|-----|
| clk_0              | -       | -         | -                  | -                  | -   |
| clk_0              | -       | -         | -                  | -                  |
| nios2_gen2_0       | clk_0   | clk_0     | data_master        | -                  |
| onchip_memory      | clk_0   | clk_0     | -                  | s1                 |
| jtag_uart_0        | clk_0   | clk_0     | -                  | avalon_jtag_slave  |
| sysid_qsys_0       | clk_0   | clk_0     | -                  | control_slave      |
| matrix32_led_0     | clk_0   | clk_0     | -                  | avalon_slave       |

**Handmatig verbinden:**
1. Klik in intersectie van `nios2_gen2_0.data_master` en `onchip_memory.s1` → Vinkje
2. Herhaal voor alle slaves
3. Verbind alle clocks naar `clk_0.clk`
4. Verbind alle resets naar `clk_0.clk_reset`

### 5.4 Conduit Exporteren

**Stap-voor-stap: Signalen Exporteren naar Top-Level**

#### LED Matrix Conduit

1. **Zoek matrix32_led_0 in System Contents**
   - Scroll naar de rij met `matrix32_led_0`

2. **Exporteer de Conduit interface**
   - Zoek de kolom **"Export"** (helemaal rechts in de tabel)
   - Zoek de rij waar `matrix32_led_0` en kolom `led_matrix` elkaar kruisen
   - Dubbelklik in deze cel, of klik op de dropdown
   - Selecteer: **"led_matrix_external"** (of type een eigen naam)
   - De cel krijgt een groene achtergrond met de export naam

3. **Verifieer export**
   - Onderaan het System Contents venster zie je nu:
     ```
     Exported Conduits:
     - led_matrix_external (13 signals)
       R1, G1, B1, R2, G2, B2, A, B, C, D, CLK, LAT, OE
     ```

#### PIO KEY Conduit

1. **Zoek pio_key in System Contents**
   - Scroll naar de rij met `pio_key`

2. **Exporteer de external_connection**
   - Zoek de kolom **"Export"**
   - Zoek de rij waar `pio_key` en kolom `external_connection` elkaar kruisen
   - Dubbelklik in deze cel
   - Selecteer: **"key_external"**
   - De cel krijgt een groene achtergrond

3. **Verifieer export**
   ```
   Exported Conduits:
   - key_external (4 signals)
     KEY[3:0]
   ```

**Wat doet dit?**
- De signalen worden nu zichtbaar in de top-level VHDL
- LED matrix: 13 signalen → GPIO_1 pins
- KEY buttons: 4 signalen → KEY input pins
- Platform Designer genereert de component port map automatisch

**Voorbeeld gegenereerde ports:**
```vhdl
-- In soc_system.vhd (gegenereerd door Platform Designer)
component soc_system is
  port (
    -- ... andere ports ...
    led_matrix_external_R1  : out std_logic;
    led_matrix_external_G1  : out std_logic;
    -- ... (13 LED signalen totaal)
    
    key_external_export     : in std_logic_vector(3 downto 0);
    -- ...
  );
end component;
```

### 5.5 Address Map Controleren

1. Ga naar **System → Assign Base Addresses**
2. Verifieer dat alle components adressen hebben:
   ```
   onchip_memory:    0x00000000 - 0x0000FFFF (64 KB)
   jtag_uart_0:      0x00010000 - 0x00010007
   sysid_qsys_0:     0x00010008 - 0x0001000F
   pio_key:          0x00010010 - 0x0001001F (16 bytes)
   matrix32_led_0:   0x00010020 - 0x0001003F (5 registers × 4 bytes)
   ```

**Belangrijk:** Noteer de base addresses! Je hebt ze nodig in C code:
- `PIO_KEY_BASE` → 0x00010010
- `MATRIX32_LED_0_BASE` → 0x00010020

### 5.6 Genereren

1. **Klik: Generate → Generate HDL...**
2. **Settings:**
   - Synthesis: VHDL (of Verilog)
   - Simulation: VHDL
   - Create HDL design files: ✓
   - Create block symbol file: ✓
3. **Generate**

Dit maakt `soc_system` module in `quartus/soc_system/` directory.

---

## 📌 STAP 6: Top-Level Design & Pin Assignment

### 6.1 Top-Level VHDL Maken

Maak: `quartus/DE1_SoC_Matrix_top.vhd`

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DE1_SoC_Matrix_top is
    Port (
        -- Clock inputs
        CLOCK_50        : in  std_logic;  -- 50 MHz oscillator
        CLOCK2_50       : in  std_logic;
        CLOCK3_50       : in  std_logic;
        CLOCK4_50       : in  std_logic;
        
        -- Pushbuttons (KEY0-3, active low)
        KEY             : in  std_logic_vector(3 downto 0);
        
        -- Switches (SW0-9)
        SW              : in  std_logic_vector(9 downto 0);
        
        -- LEDs (LEDR0-9)
        LEDR            : out std_logic_vector(9 downto 0);
        
        -- 7-segment displays (optional, not used for matrix)
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
        
        -- GPIO_1 - LED Matrix Connection (Pin Header JP7)
        GPIO_1          : out std_logic_vector(35 downto 0)
        
        -- HPS (Hard Processor System) pins - optioneel
        -- HPS_DDR3_ADDR, HPS_DDR3_DQ, etc. (zie DE1-SoC manual)
    );
end DE1_SoC_Matrix_top;

architecture Behavioral of DE1_SoC_Matrix_top is
    
    -- Component declaration for Platform Designer system
    component soc_system is
        port (
            clk_clk                            : in  std_logic;
            reset_reset_n                      : in  std_logic;
            
            -- KEY buttons input
            key_external_export                : in  std_logic_vector(3 downto 0);
            
            -- LED Matrix outputs
            led_matrix_external_R1             : out std_logic;
            led_matrix_external_G1             : out std_logic;
            led_matrix_external_B1             : out std_logic;
            led_matrix_external_R2             : out std_logic;
            led_matrix_external_G2             : out std_logic;
            led_matrix_external_B2             : out std_logic;
            led_matrix_external_A              : out std_logic;
            led_matrix_external_B              : out std_logic;
            led_matrix_external_C              : out std_logic;
            led_matrix_external_D              : out std_logic;
            led_matrix_external_CLK            : out std_logic;
            led_matrix_external_LAT            : out std_logic;
            led_matrix_external_OE             : out std_logic
        );
    end component;
    
    -- Internal signals
    signal reset_n : std_logic;
    
begin
    
    -- Reset logic: KEY0 is active-low reset button
    reset_n <= KEY(0);
    
    -- Debug LEDs: Show switches state
    LEDR <= SW;
    
    -- Turn off 7-segment displays
    HEX0 <= (others => '1');
    HEX1 <= (others => '1');
    HEX2 <= (others => '1');
    HEX3 <= (others => '1');
    HEX4 <= (others => '1');
    HEX5 <= (others => '1');
    
    -- Instantiate Platform Designer system
    u0 : component soc_system
        port map (
            clk_clk                       => CLOCK_50,
            reset_reset_n                 => reset_n,
            
            -- KEY buttons (active low) - verbind met DE1-SoC buttons
            key_external_export           => KEY,
            
            -- LED Matrix signals mapped to GPIO_1
            led_matrix_external_R1        => GPIO_1(0),   -- PIN_AB17
            led_matrix_external_G1        => GPIO_1(1),   -- PIN_AA21
            led_matrix_external_B1        => GPIO_1(2),   -- PIN_AB21
            led_matrix_external_R2        => GPIO_1(4),   -- PIN_AD24
            led_matrix_external_G2        => GPIO_1(5),   -- PIN_AE23
            led_matrix_external_B2        => GPIO_1(6),   -- PIN_AE24
            led_matrix_external_A         => GPIO_1(8),   -- PIN_AF26
            led_matrix_external_B         => GPIO_1(9),   -- PIN_AG25
            led_matrix_external_C         => GPIO_1(10),  -- PIN_AG26
            led_matrix_external_D         => GPIO_1(11),  -- PIN_AH24
            led_matrix_external_CLK       => GPIO_1(12),  -- PIN_AH27
            led_matrix_external_LAT       => GPIO_1(13),  -- PIN_AJ27
            led_matrix_external_OE        => GPIO_1(14)   -- PIN_AK29
        );

end Behavioral;
```

### 6.2 Pin Assignment Bestand

Maak: `quartus/DE1_SoC_Matrix.qsf` (toevoegen aan bestaand .qsf)

```tcl
# DE1-SoC Pin Assignments voor 32x32 LED Matrix

# Clock 50 MHz
set_location_assignment PIN_AF14 -to CLOCK_50

# Push buttons KEY0-KEY3 (active low)
# Deze pinnen zijn correct voor DE1-SoC
set_location_assignment PIN_AA14 -to KEY[0]  # KEY0
set_location_assignment PIN_AA15 -to KEY[1]  # KEY1
set_location_assignment PIN_W15  -to KEY[2]  # KEY2
set_location_assignment PIN_Y16  -to KEY[3]  # KEY3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[3]

# Switches SW0-SW9
set_location_assignment PIN_AB12 -to SW[0]
set_location_assignment PIN_AC12 -to SW[1]
set_location_assignment PIN_AF9  -to SW[2]
set_location_assignment PIN_AF10 -to SW[3]
set_location_assignment PIN_AD11 -to SW[4]
set_location_assignment PIN_AD12 -to SW[5]
set_location_assignment PIN_AE11 -to SW[6]
set_location_assignment PIN_AC9  -to SW[7]
set_location_assignment PIN_AD10 -to SW[8]
set_location_assignment PIN_AE12 -to SW[9]

# LEDs LEDR0-LEDR9
set_location_assignment PIN_V16 -to LEDR[0]
set_location_assignment PIN_W16 -to LEDR[1]
set_location_assignment PIN_V17 -to LEDR[2]
set_location_assignment PIN_V18 -to LEDR[3]
set_location_assignment PIN_W17 -to LEDR[4]
set_location_assignment PIN_W19 -to LEDR[5]
set_location_assignment PIN_Y19 -to LEDR[6]
set_location_assignment PIN_W20 -to LEDR[7]
set_location_assignment PIN_W21 -to LEDR[8]
set_location_assignment PIN_Y21 -to LEDR[9]

# GPIO_1 Pin Header (JP7) - LED Matrix Connections
# Custom pin selection

set_location_assignment PIN_AB17 -to GPIO_1[0]   # R1
set_location_assignment PIN_AA21 -to GPIO_1[1]   # G1
set_location_assignment PIN_AB21 -to GPIO_1[2]   # B1
set_location_assignment PIN_AD24 -to GPIO_1[4]   # R2
set_location_assignment PIN_AE23 -to GPIO_1[5]   # G2
set_location_assignment PIN_AE24 -to GPIO_1[6]   # B2
set_location_assignment PIN_AF26 -to GPIO_1[8]   # A
set_location_assignment PIN_AG25 -to GPIO_1[9]   # B
set_location_assignment PIN_AG26 -to GPIO_1[10]  # C
set_location_assignment PIN_AH24 -to GPIO_1[11]  # D
set_location_assignment PIN_AH27 -to GPIO_1[12]  # CLK
set_location_assignment PIN_AJ27 -to GPIO_1[13]  # LAT
set_location_assignment PIN_AK29 -to GPIO_1[14]  # OE

# I/O Standards
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[*]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[*]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[*]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to GPIO_1[*]

# Current strength for high-speed signals
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to GPIO_1[12]  # CLK
set_instance_assignment -name CURRENT_STRENGTH_NEW 4MA -to GPIO_1[*]
```

### 6.3 Pin Mapping Diagram

```
DE1-SoC GPIO_1 (JP7) ←→ LED Matrix Connector

Matrix Pin   | Signal | GPIO_1 Pin | FPGA Pin
-------------|--------|------------|----------
1            | R1     | GPIO_1[0]  | AB17
2            | GND    | GND        | GND
3            | G1     | GPIO_1[1]  | AA21
4            | GND    | GND        | GND
5            | B1     | GPIO_1[2]  | AB21
6            | GND    | GND        | GND
7            | R2     | GPIO_1[4]  | AD24
8            | GND    | GND        | GND
9            | G2     | GPIO_1[5]  | AE23
10           | GND    | GND        | GND
11           | B2     | GPIO_1[6]  | AE24
12           | GND    | GND        | GND
13           | A      | GPIO_1[8]  | AF26
14           | B      | GPIO_1[9]  | AG25
15           | C      | GPIO_1[10] | AG26
16           | D      | GPIO_1[11] | AH24
17           | CLK    | GPIO_1[12] | AH27
18           | LAT    | GPIO_1[13] | AJ27
19           | OE     | GPIO_1[14] | AK29
20           | GND    | GND        | GND
```

---

## ⚙️ STAP 7: Compilatie & Timing Constraints

### 7.1 Timing Constraints (SDC File)

Maak: `quartus/DE1_SoC_Matrix.sdc`

```tcl
# Timing Constraints voor DE1-SoC Matrix Project

# Create base clock constraint (50 MHz input)
create_clock -name CLOCK_50 -period 20.000ns [get_ports {CLOCK_50}]

# Derive PLL clocks (if any PLLs in Platform Designer)
derive_pll_clocks

# Automatically calculate clock uncertainty
derive_clock_uncertainty

# False paths for asynchronous inputs
set_false_path -from [get_ports {KEY[*]}] -to *
set_false_path -from [get_ports {SW[*]}] -to *

# Output delays for LED matrix (conservative timing)
set_output_delay -clock CLOCK_50 -max 5.0 [get_ports {GPIO_1[*]}]
set_output_delay -clock CLOCK_50 -min 0.0 [get_ports {GPIO_1[*]}]

# Multicycle path for LED data (data stable for multiple clocks)
set_multicycle_path -setup -to [get_ports {GPIO_1[0]}] 2  # R1
set_multicycle_path -setup -to [get_ports {GPIO_1[1]}] 2  # G1
set_multicycle_path -setup -to [get_ports {GPIO_1[2]}] 2  # B1
set_multicycle_path -setup -to [get_ports {GPIO_1[4]}] 2  # R2
set_multicycle_path -setup -to [get_ports {GPIO_1[5]}] 2  # G2
set_multicycle_path -setup -to [get_ports {GPIO_1[6]}] 2  # B2
```

### 7.2 Project Compileren

**In Quartus:**

1. **Processing → Start Compilation** (of Ctrl+L)

2. **Wacht op compilatie** (kan 5-15 minuten duren)

3. **Check voor errors:**
   - Kijk in Messages window
   - Controleer Timing Analyzer: **Tools → Timing Analyzer**

4. **Verifieer resource usage:**
   ```
   Compilation Report → Resource Section:
   - Logic Elements: ~1000-2000 (op ~85K beschikbaar)
   - Registers: ~500
   - Memory bits: 65536 (voor on-chip RAM)
   ```
**Gebruik het bestaande bestand:** `Component/software/matrix32_led.h`

Dit bestand bevat al:

```c
// Register offsets
#define MATRIX32_CONTROL_REG_OFFSET    0x00
#define MATRIX32_PATTERN_REG_OFFSET    0x04
#define MATRIX32_FB_ADDR_REG_OFFSET    0x08
#define MATRIX32_FB_DATA_REG_OFFSET    0x0C
#define MATRIX32_STATUS_REG_OFFSET     0x10

// Kleur definities (1-bit per channel)
#define MATRIX32_COLOR_BLACK     0  // RGB: 000
#define MATRIX32_COLOR_BLUE      1  // RGB: 001
#define MATRIX32_COLOR_GREEN     2  // RGB: 010
#define MATRIX32_COLOR_CYAN      3  // RGB: 011
#define MATRIX32_COLOR_RED       4  // RGB: 100
#define MATRIX32_COLOR_MAGENTA   5  // RGB: 101
#define MATRIX32_COLOR_YELLOW    6  // RGB: 110
#define MATRIX32_COLOR_WHITE     7  // RGB: 111

// API functies
void matrix32_init(uint32_t base_address);
void matrix32_enable(uint32_t base_address, uint8_t enable);
void matrix32_set_mode(uint32_t base_address, uint8_t mode);
void matrix32_set_pixel(uint32_t base, uint8_t x, uint8_t y, 
                        uint8_t r, uint8_t g, uint8_t b);
void matrix32_fill(uint32_t base_address, uint8_t color);
void matrix32_clear(uint32_t base_address);
// ... en meer draw functies
```

Zie het complete bestand in `Component/software/matrix32_led.hid matrix_init(void);
void matrix_enable(uint8_t enable);
void matrix_set_pattern(matrix_pattern_t pattern);
void matrix_set_brightness(uint8_t brightness);
uint32_t matrix_get_status(void);

#endif // MATRIX_DRIVER_H
```

**Gebruik het bestaande bestand:** `Component/software/matrix32_led.c`

**Belangrijkste functies:**

```c
// Initialisatie (één keer bij opstarten)
void matrix32_init(uint32_t base_address) {
    // Clear framebuffer, disable, set defaults
}

// Enable/disable hardware
void matrix32_enable(uint32_t base_address, uint8_t enable) {
    // Set enable bit in CONTROL register
}

// Zet één pixel (MEEST GEBRUIKTE FUNCTIE!)
void matrix32_set_pixel(uint32_t base, uint8_t x, uint8_t y, 
                        uint8_t r, uint8_t g, uint8_t b) {
    // Bereken pixel index en byte address
    // Schrijf naar framebuffer via FB_ADDR en FB_DATA registers
    // Hardware toont automatisch!
}

// Hele matrix vullen met één kleur
void matrix32_fill(uint32_t base_address, uint8_t color) {
    // Schrijf alle 384 bytes met kleur
}

// Alle pixels uit
void matrix32_clear(uint32_t base_address) {
    // Schrijf zeros naar alle 384 bytes
}
```

**Architectuur:**
- C code schrijft alleen pixel waarden
- VHDL hardware doet automatisch: scanning, timing, refresh
- Geen DMA, geen interrupts nodig!
**Gebruik het bestaande voorbeeld:** `Component/software/example_main.c`

**Eenvoudig voorbeeld:**

```c
#include <stdio.h>
#include <unistd.h>
#include "system.h"
#include "matrix32_led.h"

// Base address uit Platform Designer (vervang met jouw waarde!)
#define MATRIX_BASE MATRIX32_LED_0_BASE  // of 0x00010010

int main(void) {
    printf("=== RGB LED Matrix Demo ===\n");
    
    // 1. Initialisatie (hardware start met scannen)
    matrix32_init(MATRIX_BASE);
    matrix32_set_mode(MATRIX_BASE, 0);  // 0 = Framebuffer mode
    matrix32_enable(MATRIX_BASE, 1);    // Enable
    
    while (1) {
        // 2. Zet enkele pixels aan
        printf("Rode pixel op (10, 10)\n");
        matrix32_set_pixel(MATRIX_BASE, 10, 10, 1, 0, 0);  // Rood
        usleep(1000000);  // 1 seconde
        
        printf("Groene pixel op (15, 15)\n");
        matrix32_set_pixel(MATRIX_BASE, 15, 15, 0, 1, 0);  // Groen
        usleep(1000000);
        
        // 3. Hele matrix vullen
        printf("Hele matrix BLAUW\n");
        matrix32_fill(MATRIX_BASE, MATRIX32_COLOR_BLUE);
        usleep(2000000);
        
        printf("Hele matrix GEEL\n");
        matrix32_fill(MATRIX_BASE, MATRIX32_COLOR_YELLOW);
        usleep(2000000);
        
        // 4. Alles uit
        printf("Alle pixels uit\n");
        matrix32_clear(MATRIX_BASE);
        usleep(1000000);
        
        // Hardware toont alles automatisch!
        // Geen extra timing code nodig!
    }
    
    return 0;
}
```

**Zo simpel is het!** De VHDL hardware zorgt voor alle scanning en timing.

Zie `Component/software/example_main.c` voor meer voorbeelden.     // Read status
        uint32_t status = matrix_get_status();
        printf("Status register: 0x%08X\n", status);
    }
    
    return 0;
}
```

---

## 🧪 STAP 9: Software Compileren (Nios II)

### 9.1 Nios II Software Build Tools (Eclipse)

1. **Start Nios II Software Build Tools**
   ```
   Start Menu → Intel FPGA → Nios II Software Build Tools for Eclipse
   ```

2. **Maak BSP (Board Support Package)**
   ```
   File → New → Nios II Board Support Package
   - SOPC Information File: quartus/soc_system.sopcinfo
   - BSP Target Directory: software/matrix_bsp
   ```

3. **Maak Applicatie Project**
   ```
   File → New → Nios II Application
   - Project name: matrix_test
   - Location: software/matrix_test
   - Select: Use existing BSP
   - BSP: matrix_bsp
   ```

4. **Voeg source files toe**
   - Kopieer `main.c`, `matrix_driver.c`, `matrix_driver.h` naar `matrix_test/` directory
   - Refresh project in Eclipse

5. **Build Project**
   ```
   Project → Build Project (of Ctrl+B)
   ```

---

## 🚀 STAP 10: FPGA Programmeren & Testen

### 10.1 Hardware Programmeren

1. **Sluit DE1-SoC aan via USB Blaster**

2. **Open Quartus Programmer**
   ```
   Tools → Programmer
   ```

3. **Add SOF File**
   - Click **Add File**
   - Select: `quartus/output_files/DE1_SoC_Matrix.sof`
   - Check: **Program/Configure**

4. **Program Device**
   - Click **Start**
   - Wacht tot "100% (Successful)" verschijnt

### 10.2 LED Matrix Hardware Aansluiten

**Verbinding schema:**

```
DE1-SoC GPIO_1 (JP7)  ←→  LED Matrix Input Connector
                          (16-pin IDC connector)

Let op polariteit! Pin 1 heeft meestal een pijl of indicator
```

**Voeding:**
- LED Matrix heeft externe 5V power nodig (2-4A)
- Verbind GND van power supply met GND van DE1-SoC (common ground!)

### 10.3 Software Laden

1. **Open Nios II Console**
   ```
   Nios II → Nios II Command Shell
   ```

2. **Download & Run**
   ```bash
   cd software/matrix_test
   nios2-download -g matrix_test.elf
   nios2-terminal
   ```

3. **Observeer Output**
   ```
   === 32x32 LED Matrix Test ===
   Matrix initialized
   Matrix enabled
   
   --- Pattern Test Cycle ---
   Pattern: Checkerboard
   ...
   ```

### 10.4 Debugging via JTAG UART

Als er problemen zijn, check:

```c
// In main.c, voeg debug output toe:
printf("Control reg: 0x%08X\n", IORD_32DIRECT(MATRIX32_CONTROL_REG, 0));
printf("Pattern reg: 0x%08X\n", IORD_32DIRECT(MATRIX32_PATTERN_REG, 0));
```

---

## 🔍 STAP 11: Verificatie & Troubleshooting

### 11.1 Checklist Verificatie

**Hardware:**
- [ ] FPGA succesvol geprogrammeerd (no errors in Programmer)
- [ ] LED matrix heeft externe 5V voeding
- [ ] Alle 16 draden correct verbonden (check pin 1 orientatie!)
- [ ] Common ground tussen power supply, matrix, en FPGA

**Software:**
- [ ] BSP gegenereerd zonder errors (2-4A!)
- [ ] Alle 16 draden correct verbonden (check pin 1 orientatie!)
- [ ] Common ground tussen power supply, matrix, en FPGA

**Software:**
- [ ] BSP gegenereerd zonder errors
- [ ] Application compileert zonder warnings
- [ ] Base address klopt (check system.h: `MATRIX32_LED_0_BASE`)
- [ ] JTAG UART toont console output
- [ ] Status register leesbaar via software

**Signalen:**
- [ ] CLK signaal zichtbaar op oscilloscoop (~MHz range)
- [ ] LAT puls komt periodiek (elke 32 CLK pulsen)
- [ ] OE toggle (enable/disable output)
- [ ] RGB data wijzigt per pixel/patroon

**Framebuffer:**
- [ ] Pixel writes komen aan (check via SignalTap)
- [ ] FB_ADDR increment werkt
- [ ] FB_DATA trigger zorgt voor write
- [ ] Framebuffer data zichtbaar in hardware
- Check USB Blaster driver (Device Manager)
- Probeer andere USB poort
- Check power op DE1-SoC (beide power switches ON)

#### Probleem 2: Matrix blijft zwart
**Diagnose:**
``` (LED aan achterkant?)
3. Verifieer CLK togglet met oscilloscoop
4. Test eerst met test pattern mode (mode=1, pattern=3 = all on)
5. Check framebuffer mode: schrijf 0xFF naar alle adressen
```

**Debug met C code:**
```c
// Test framebuffer direct
for (uint16_t addr = 0; addr < 384; addr++) {
    matrix32_write_fb_byte(MATRIX_BASE, addr, 0xFF);
}
// Alle pixels zouden WIT moeten zijnix
3. Verifieer CLK togglet met oscilloscoop
4. Test met patroon "ALL_ON" (3)
```

#### Probleem 3: Software crash/hang
**Debug:**
```bash
# Check memory map
nios2-elf-objdump -h matrix_test.elf

# Run met GDB debugger
nios2-gdb-server &
nios2-elf-gdb matrix_test.elf
(gdb) target remote :2342
(gdb) load
(gdb) break main
(gdb) continue
```

#### Probleem 4: Timing violations
**Fix in SDC:**
```tcl
# Relax constraints als niet kritisch
set_output_delay -clock CLOCK_50 -max 10.0 [get_ports {GPIO_1[*]}]

# Of gebruik slower I/O standard
set_instance_assignment -name IO_STANDARD "2.5-V" -to GPIO_1[*]
```

---, R2, G2, B2
   - matrix32_led_0|matrix_core|CLK_out
   - matrix32_led_0|matrix_core|LAT
   - matrix32_led_0|matrix_core|OE
   - matrix32_led_0|matrix_core|current_state
   - matrix32_led_0|matrix_core|row_counter
   - matrix32_led_0|matrix_core|col_counter
   - matrix32_led_0|matrix_core|framebuffer[0..10]  # Eerste bytes
   - matrix32_led_0|reg_fb_addr
   - matrix32_led_0|reg_fb_data
   - matrix32_led_0|fb_write_trigg

Voor hardware debugging:

1. **Tools → SignalTap II Logic Analyzer**

2. **Add Signals:**
   ```
   - matrix32_led_0|matrix_core|R1, G1, B1
   - matrix32_led_0|matrix_core|CLK_out
   - matrix32_led_0|matrix_core|LAT
   - matrix32_led_0|matrix_core|current_state
   - matrix32_led_0|matrix_core|row_counter
   ```

3. **Trigger Setup:**
   -Huidige Features:

✅ **Al geïmplementeerd:**
- Frame Buffer Memory (384 bytes in FPGA)
- Automatische matrix scanning
- HUB75 protocol timing
- Dual mode (framebuffer + test patterns)
- C API voor pixel control

### Mogelijke Uitbreidingen:

1. **PWM voor Helderheid per Pixel**
   - Multi-bit per pixel (bijv. 4-bit = 16 niveaus)
   - Gamma correctie
   - BCM (Binary Code Modulation) voor smooth gradients

2. **DMA Controller**
   - Automatisch frame data van DDR3 naar matrix
   - Double buffering (ping-pong buffers)
   - Elimineer CPU overhead

3. **Video Streaming**
   - Input van HDMI/Camera
   - Real-time downscaling naar 32×32
   -Project Documentatie:
- **[ARCHITECTUUR_OVERZICHT.md](ARCHITECTUUR_OVERZICHT.md)** - Complete technische architectuur
- **[Component/software/README_EENVOUDIG.md](Component/software/README_EENVOUDIG.md)** - Software API guide
- **[MODELSIM_HANDLEIDING.md](MODELSIM_HANDLEIDING.md)** - Simulatie guide
- **[Component/docs/PIN_ASSIGNMENTS_DE1_SOC.txt](Component/docs/PIN_ASSIGNMENTS_DE1_SOC.txt)** - Pin mapping

### Altera/Intel Documentatie:
- **Cyclone V Device Handbook**: cv_51001.pdf
- **Avalon Interface Specifications**: mnl_avalon_spec.pdf
- **Platform Designer User Guide**: ug_platform_designer.pdf
- **Nios II Software Developer's Handbook**: n2sw_nii5v2gen2.pdf

### DE1-SoC Specifiek:
- **DE1-SoC User Manual**: DE1_SoC_User_manual.pdf (Terasic website)
- **DE1-SoC Getting Started Guide**: DE1-SoC_Getting_Started_Guide.pdf
- **DE1-SoC Schematic**: DE1-SoC_schematic.pdf

### LED Matrix:
- **Adafruit RGB Matrix Guide**: https://learn.adafruit.com/32x16-32x32-rgb-led-matrix
- **HUB75 Protocol**: https://www.sparkfun.com/sparkfun-rgb-led-matrix-panel-hookup-guide
- **LED Matrix Drive(AL KLAAR!)                       │
│    ✓ Matrix32_LED.vhd (core met framebuffer)       │
│    ✓ Matrix32_LED_avalon.vhd (Avalon wrapper)      │
│    ✓ matrix32_led_hw.tcl (Platform Designer)       │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 2. Quartus Project Setup                            │
│    - Device: 5CSEMA5F31C6                           │
│    - Add Component/ dir to IP catalog               │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 3. Platform Designer System                         │
│    - Add Nios II, Memory, UART                      │
│    - Add Matrix32_LED component (IP catalog)        │
│    - Connect via Avalon bus                         │
│    - Export LED conduit                             │
│    - Generate HDL                                   │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 4. Top-Level Integration                            │
│    - Use Component/hdl/DE1_SoC_Matrix32_top.vhd    │
│    - Instantiate soc_system                         │
│    - Map GPIO_1 pins (use PIN_ASSIGNMENTS.txt)      │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 5. Pin Assignment & Constraints                     │
│    - .qsf file (pin locations)                      │
│    - .sdc file (timing)                             │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 6. Compile & Synthesize                             │
│    - Quartus compilation                            │
│    - Generate .sof file                             │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 7. Software Development                             │
│    - BSP generation                                 │
│    - Use Component/software/matrix32_led.h/.c       │
│    - Test met example_main.c                        │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 8. Program & Test                                   │
│    - Download .sof to FPGA                          │
│    - Run software via JTAG                          │
│    - Observe LED matrix - pixels direct zichtbaar!  │
└─────────────────────────────────────────────────────┘
```

### 🎯 Belangrijkste Verschillen vs Oude Workflow:

**✅ Wat nu MAKKELIJKER is:**
- Component files zijn al compleet (hdl/, software/)
- Framebuffer = in VHDL, niet in software
- C API is super simpel: `set_pixel(x, y, rgb)` done!
- Hardware doet scanning automatisch (geen CPU cycles!)

**📝 Wat je zelf doet:**
1. Quartus project maken
2. IP catalog setup (Component/ directory toevoegen)
3. Platform Designer systeem bouwen
4. Top-level integratie
5. Compilererst test pattern mode (simpel, geen framebuffer)
   - Dan framebuffer mode met enkele pixels
   - Gebruik SignalTap voor hardware debug
   - Print debug info via JTAG UART

2. **Framebuffer debugging**
   ```c
   // Check of writes aankomen
   for (int i = 0; i < 10; i++) {
       matrix32_write_fb_byte(base, i, 0xFF);
       printf("Wrote 0xFF to addr %d\n", i);
   }
   // Eerste 80 pixels (10 bytes) zouden wit moeten zijn
   ```

3. **Version control**
   - Git voor source code (Component/ directory is al goed georganiseerd!)
   - Tag elke werkende versie
   - Document wijzigingen in Quartus settings

4. **Backup maken**
   - Quartus settings (.qsf, .sdc)
   - Platform Designer (.qsys)
   - Working .sof files
   - BSP directory

5. **Timing closure**
   - Altijd check Timing Analyzer na compilatie
   - Fix alle timing violations
   - Test op verschillende FPGA boards (kan verschillen!)

### Learning Resources:

- **Project Docs**: Start met ARCHITECTUUR_OVERZICHT.md
- **Software Guide**: Component/software/README_EENVOUDIG.md│    - Generate HDL                                   │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 5. Top-Level Integration                            │
│    - DE1_SoC_Matrix_top.vhd                         │
│    - Instantiate soc_system                         │
│    - Map GPIO_0 pins                                │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 6. Pin Assignment & Constraints                     │
│    - .qsf file (pin locations)                      │
│    - .sdc file (timing)                             │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 7. Compile & Synthesize                             │
│    - Quartus compilation                            │
│    - Generate .sof file                             │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 8. Software Development                             │
│    - BSP generation                                 │
│    - C driver (matrix_driver.c)                     │
│    - Test application                               │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│ 9. Program & Test                                   │
│    - Download .sof to FPGA                          │
│    - Run software via JTAG                          │
│    - Observe LED matrix                             │
└─────────────────────────────────────────────────────┘
```

---

## 🎓 Tips voor Succesvol Gebruik

### Best Practices:

1. **Incrementeel testen**
   - Test elk component apart (eerst LED blink, dan matrix)
   - Gebruik SignalTap voor hardware debug
   - Print debug info via JTAG UART

2. **Version control**
   - Git voor source code
   - Tag elke werkende versie
   - Document wijzigingen

3. **Backup maken**
   - Quartus settings (.qsf, .sdc)
   - Platform Designer (.qsys)
   - Working .sof files

4. **Timing closure**
   - Altijd check Timing Analyzer na compilatie
   - Fix alle timing violations
   - Test op verschillende FPGA boards (kan verschillen!)

### Learning Resources:

- **Intel FPGA Training**: https://www.intel.com/content/www/us/en/programmable/support/training/overview.html
- **Nios II Tutorials**: Embedded in Software Build Tools
- **DE1-SoC Labs**: Terasic provides example projects

---

**Succes met je 32x32 LED Matrix project! 🎉**

Als je problemen tegenkomt, check:
1. Console output (JTAG UART)
2. SignalTap waveforms
3. Quartus Messages window
4. Timing Analyzer reports

Veel plezier met Platform Designer! 🚀
