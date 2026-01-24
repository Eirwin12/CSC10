# Matrix32_LED Testbench - Complete Uitleg 📊

## 🎯 Hoofddoel van de Testbench

De testbench voor de Matrix32_LED component heeft drie belangrijke taken:
1. **Genereert stimulus** (input signalen) voor het ontwerp
2. **Observeert output** signalen (RGB data, control signalen)
3. **Valideert** dat de LED matrix controller correct werkt

Deze testbench simuleert een 32x32 RGB LED matrix controller en test of alle functionaliteit correct werkt volgens het multiplexing principe.

---

## 📦 1. Declaratie Sectie (Regels 1-41)

### Libraries
```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  -- Voor std_logic types
use IEEE.NUMERIC_STD.ALL;      -- Voor unsigned/signed berekeningen
```

**Waarom deze libraries?**
- `STD_LOGIC_1164`: Definieert std_logic type ('0', '1', 'Z', 'X', etc.)
- `NUMERIC_STD`: Nodig voor unsigned/signed arithmetiek (counters, addressing)

### Component Declaration
```vhdl
component Matrix32_LED is
    Port (
        clk, reset      : in  std_logic;
        R1, G1, B1      : out std_logic;  -- RGB voor upper half (rijen 1-16)
        R2, G2, B2      : out std_logic;  -- RGB voor lower half (rijen 17-32)
        A, B, C, D      : out std_logic;  -- 4-bit row address (0-15)
        CLK_out         : out std_logic;  -- Shift clock naar LED drivers
        LAT             : out std_logic;  -- Latch pulse
        OE              : out std_logic;  -- Output Enable
        test_pattern    : in  std_logic_vector(2 downto 0)  -- Patroon keuze
    );
end component;
```

**Wat dit doet:** 
Definieert de interface van het te testen component (Unit Under Test - UUT). Dit is nodig zodat de testbench weet welke signalen er beschikbaar zijn.

### Testbench Signalen
```vhdl
-- Input signalen (testbench stuurt deze aan)
signal clk          : std_logic := '0';   -- Clock input (50 MHz)
signal reset        : std_logic := '0';   -- Reset (active high)
signal test_pattern : std_logic_vector(2 downto 0) := "000";  -- Patroon selectie

-- Output signalen (testbench observeert deze)
signal R1, G1, B1, R2, G2, B2 : std_logic;  -- RGB data
signal A, B, C, D             : std_logic;   -- Row address
signal CLK_out, LAT, OE       : std_logic;   -- Control signalen
```

**Belangrijk:**
- Input signalen worden geïnitialiseerd (`:= '0'`)
- Output signalen worden NIET geïnitialiseerd (die komen van het UUT)

**Constanten:**
```vhdl
constant clk_period : time := 20 ns;  -- 50 MHz: 1/50MHz = 20ns
signal sim_done : boolean := false;    -- Stop flag voor clock generator
```

**Berekening clock periode:**
```
Frequentie = 50 MHz
Periode = 1 / 50,000,000 Hz = 0.00000002 seconden = 20 nanoseconden
```

---

## ⚙️ 2. UUT Instantiatie (Regels 43-62)

```vhdl
UUT: Matrix32_LED
    port map (
        clk          => clk,          -- Verbind testbench signaal clk
        reset        => reset,        -- naar component poort clk
        R1           => R1,
        G1           => G1,
        B1           => B1,
        R2           => R2,
        G2           => G2,
        B2           => B2,
        A            => A,
        B            => B,
        C            => C,
        D            => D,
        CLK_out      => CLK_out,
        LAT          => LAT,
        OE           => OE,
        test_pattern => test_pattern
    );
```

**Wat dit doet:**
- Maakt een instantie van het Matrix32_LED component
- Verbindt alle poorten met testbench signalen
- Dit is het "Device Under Test" (DUT) of "Unit Under Test" (UUT)

**Port Mapping:**
```
Component Poort  <=>  Testbench Signaal
─────────────────────────────────────────
clk              <=>  clk
reset            <=>  reset
R1               <=>  R1
...etc
```

---

## 🕐 3. Clock Generator (Regels 64-72)

```vhdl
clk_process: process
begin
    while not sim_done loop        -- Blijf draaien tot sim_done = true
        clk <= '0';                -- Clock laag
        wait for clk_period/2;     -- 10ns wachten
        clk <= '1';                -- Clock hoog
        wait for clk_period/2;     -- 10ns wachten
    end loop;                      -- Herhaal (50 MHz clock)
    wait;                          -- Stop (wacht voor altijd)
end process;
```

**Wat dit doet:**
- Genereert een continue 50 MHz clock signaal
- Periode: 20ns (10ns laag + 10ns hoog)
- Stopt automatisch wanneer `sim_done` true wordt
- Dit simuleert de 50 MHz crystal oscillator op het DE1-SoC bord

**Timing diagram:**
```
clk:  ___┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_
         │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
         └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘
      ◄─20ns─►◄─20ns─►◄─20ns─►◄─20ns─►
      
      10ns   10ns
       low   high
```

**Waarom een while loop?**
- Continue clock generatie
- Kan gestopt worden (met `sim_done`)
- Zonder loop zou proces na 1 cyclus stoppen

---

## 🧪 4. Stimulus Process - De Eigenlijke Tests (Regels 74-129)

Dit is het hart van de testbench - het voert 8 verschillende tests uit om alle functionaliteit te verifiëren.

### Test 1: Reset Functionaliteit (Regels 79-84)

```vhdl
report "Test 1: Reset functionaliteit" severity note;
reset <= '1';      -- Activeer reset
wait for 100 ns;   -- Houd reset 100ns actief (5 clock cycles)
reset <= '0';      -- Deactiveer reset
wait for 200 ns;   -- Wacht op stabilisatie (10 clock cycles)
```

**Doel:** Verifieer dat het systeem correct reset

**Wat er moet gebeuren:**
- ✅ Alle counters gaan naar 0
- ✅ State machine gaat naar IDLE state
- ✅ Outputs gaan naar default waarden
- ✅ `row_counter` = 0
- ✅ `col_counter` = 0
- ✅ `OE` = '1' (output disabled)

**Verificatie:**
Kijk in waveform dat na reset:
- `A, B, C, D` = "0000"
- State = IDLE

---

### Test 2: Checkerboard Patroon (Regels 86-89)

```vhdl
report "Test 2: Checkerboard patroon (patroon 000)" severity note;
test_pattern <= "000";
wait for 100 us;  -- 100 microseconden = 100,000 ns = 5000 clock cycles
```

**Wat gebeurt er:**
- `test_pattern = "000"` activeert checkerboard logica
- Component genereert alternerende rode en groene pixels

**Verwacht patroon:**
```
In het component (Matrix32_LED.vhd):
when "000" =>  -- Checkerboard
    R1 <= '1' when (to_integer(row_counter) + to_integer(col_counter)) mod 2 = 0 else '0';
    G1 <= '0';
    B1 <= '0';
    R2 <= '0';
    G2 <= '1' when (to_integer(row_counter) + to_integer(col_counter)) mod 2 = 0 else '0';
    B2 <= '0';
```

**Visueel resultaat op matrix:**
```
        Col: 0 1 2 3 4 5 6 7 8 9 ...
Row  0:      R . R . R . R . R . ...  (Upper half)
Row  1:      . R . R . R . R . R ...
Row  2:      R . R . R . R . R . ...
...
Row 16:      G . G . G . G . G . ...  (Lower half)
Row 17:      . G . G . G . G . G ...

R = Rood (R1='1')
G = Groen (G2='1')
. = Uit
```

**Waarom 100us?**
- Genoeg tijd voor meerdere complete refresh cycli
- 1 complete scan (16 rijen) duurt ~16 × 1000 clocks = 16,000 clocks = 320us
- Dus 100us = ongeveer 5-6 rijen

---

### Test 3: Horizontal Lines (Regels 91-94)

```vhdl
report "Test 3: Horizontal lines patroon (patroon 001)" severity note;
test_pattern <= "001";
wait for 100 us;
```

**Component logica:**
```vhdl
when "001" =>  -- Horizontal lines
    R1 <= '1';  -- Alle pixels in upper half rood
    G1 <= '0';
    B1 <= '0';
    R2 <= '0';
    G2 <= '0';
    B2 <= '1';  -- Alle pixels in lower half blauw
```

**Verwacht patroon:**
- Upper half (rijen 1-16): Constant R1 = '1' → ROOD
- Lower half (rijen 17-32): Constant B2 = '1' → BLAUW
- Onafhankelijk van kolom nummer

**Visueel resultaat:**
```
┌─────────────────────┐
│  RRRRRRRRRRRRRRRR   │ ← Rijen 1-16 (upper)
│  RRRRRRRRRRRRRRRR   │
│  RRRRRRRRRRRRRRRR   │
├─────────────────────┤
│  BBBBBBBBBBBBBBBB   │ ← Rijen 17-32 (lower)
│  BBBBBBBBBBBBBBBB   │
│  BBBBBBBBBBBBBBBB   │
└─────────────────────┘
```

---

### Test 4: Vertical Lines (Regels 96-99)

```vhdl
report "Test 4: Vertical lines patroon (patroon 010)" severity note;
test_pattern <= "010";
wait for 100 us;
```

**Component logica:**
```vhdl
when "010" =>  -- Vertical lines
    R1 <= '1' when col_counter(0) = '0' else '0';
    G1 <= '1' when col_counter(0) = '0' else '0';
    B1 <= '1' when col_counter(0) = '0' else '0';
    R2 <= '1' when col_counter(0) = '1' else '0';
    G2 <= '1' when col_counter(0) = '1' else '0';
    B2 <= '1' when col_counter(0) = '1' else '0';
```

**Uitleg:**
- `col_counter(0)` is de LSB (least significant bit) van kolom nummer
- Even kolommen (0,2,4,6...): LSB = '0' → Upper RGB = wit
- Oneven kolommen (1,3,5,7...): LSB = '1' → Lower RGB = wit

**Visueel resultaat:**
```
     Col: 0 1 2 3 4 5 6 7 8 9 10 11 ...
Upper:    W . W . W . W . W . W  .  ...
Lower:    . W . W . W . W . W .  W  ...

W = Wit (RGB='111')
. = Uit
```

**Interessant detail:**
- Alternerende verticale strepen
- Upper en lower zijn geïnterleaved (elkaar aanvullend)

---

### Test 5: Alle LEDs Aan / Wit (Regels 101-104)

```vhdl
report "Test 5: Alle LEDs aan - wit (patroon 011)" severity note;
test_pattern <= "011";
wait for 100 us;
```

**Component logica:**
```vhdl
when "011" =>  -- Alle LEDs aan (wit)
    R1 <= '1';
    G1 <= '1';
    B1 <= '1';
    R2 <= '1';
    G2 <= '1';
    B2 <= '1';
```

**Verwacht:**
- Alle 512 LEDs branden (32×32 = 1024 RGB positions, maar interleaved)
- Maximum brightness test
- Hoogste power consumption scenario

**Test doel:**
- ✅ Verifieer dat alle pixels aangestuurd kunnen worden
- ✅ Check of er geen dead pixels zijn
- ✅ Maximum load test voor drivers

**Visueel:**
```
┌─────────────────────┐
│ WWWWWWWWWWWWWWWWWWW │ Heel scherm wit
│ WWWWWWWWWWWWWWWWWWW │
│ WWWWWWWWWWWWWWWWWWW │
│ WWWWWWWWWWWWWWWWWWW │
└─────────────────────┘
```

---

### Test 6: Rood Gradient (Regels 106-109)

```vhdl
report "Test 6: Rood gradient (patroon 100)" severity note;
test_pattern <= "100";
wait for 100 us;
```

**Component logica:**
```vhdl
when "100" =>  -- Rood gradient
    R1 <= '1' when col_counter < 16 else '0';
    G1 <= '0';
    B1 <= '0';
    R2 <= '1' when col_counter >= 16 else '0';
    G2 <= '0';
    B2 <= '0';
```

**Uitleg:**
- Linker helft (kolom 0-15): R1 = '1' (rood in upper)
- Rechter helft (kolom 16-31): R2 = '1' (rood in lower)
- Creëert horizontale overgang in het midden

**Visueel resultaat:**
```
     Col: 0  1  2 ... 14 15 | 16 17 18 ... 30 31
Row  0:   R  R  R  R  R  R  | .  .  .  .  .  .   (Upper)
Row  1:   R  R  R  R  R  R  | .  .  .  .  .  .
...
Row 16:   .  .  .  .  .  .  | R  R  R  R  R  R   (Lower)
Row 17:   .  .  .  .  .  .  | R  R  R  R  R  R

           ← Left half →        ← Right half →
```

**Doel:**
- Test column addressing
- Verifieer dat col_counter correct incrementeert
- Visuele gradient voor debugging

---

### Test 7: Alle LEDs Uit (Regels 111-114)

```vhdl
report "Test 7: Alle LEDs uit (patroon 111)" severity note;
test_pattern <= "111";
wait for 100 us;
```

**Component logica:**
```vhdl
when others =>  -- Default: alles uit
    R1 <= '0';
    G1 <= '0';
    B1 <= '0';
    R2 <= '0';
    G2 <= '0';
    B2 <= '0';
```

**Verwacht:**
- Alle RGB outputs = '0'
- Matrix is volledig donker
- Minimum power test

**Test doel:**
- ✅ Verifieer dat matrix correct kan uitschakelen
- ✅ Check dat `OE` signaal nog steeds werkt
- ✅ Baseline voor noise/leakage detectie

---

### Test 8: Row Scanning Verificatie (Regels 116-119)

```vhdl
report "Test 8: Verifieer row scanning" severity note;
test_pattern <= "001";  -- Horizontal lines (duidelijk patroon)
wait for 200 us;        -- Extra lange tijd
```

**Doel:**
- Verifieer dat row address (A,B,C,D) correct telt van 0 tot 15
- Check dat alle 16 rijen worden gescand
- Verifieer cyclische herhaling (15 → 0)

**Wat te observeren:**
1. **Address progression:**
   ```
   A,B,C,D: 0000 → 0001 → 0010 → 0011 → ... → 1110 → 1111 → 0000
            (0)    (1)    (2)    (3)          (14)   (15)   (0)
   ```

2. **Timing:**
   ```
   Per rij: ~32 CLK pulsen + LAT + OE enable + display tijd
   Totaal per rij: ~1000-2000 clock cycles
   16 rijen: ~16,000-32,000 cycles = 320-640 us @ 50MHz
   ```

3. **Console output:**
   ```
   # CLK pulse - Row: 0 | ...
   # LATCH: Data voor row 0 gelatched
   # OUTPUT ENABLED voor row 0
   # CLK pulse - Row: 1 | ...
   # LATCH: Data voor row 1 gelatched
   ...
   # CLK pulse - Row: 15 | ...
   # LATCH: Data voor row 15 gelatched
   # OUTPUT ENABLED voor row 15
   # CLK pulse - Row: 0 | ...  ← Terug naar 0!
   ```

**Waarom 200us?**
- Lang genoeg voor meerdere complete scans
- Verificatie dat scanning niet stopt
- Check voor stuck states

---

### Simulatie Afsluiten (Regels 121-124)

```vhdl
report "=== Simulatie succesvol afgerond ===" severity note;
sim_done <= true;  -- Stopt de clock generator
wait;              -- Blijf wachten (simulatie eindigt)
```

**Wat gebeurt er:**
1. Print afsluitbericht in console
2. `sim_done` wordt `true`
3. Clock generator ziet `sim_done = true`
4. Clock generator stopt (exit while loop)
5. Beide processen wachten voor altijd (`wait;`)
6. ModelSim detecteert dat alle processen vastzitten → simulatie stopt

**Zonder `sim_done`:**
- Clock zou voor altijd blijven draaien
- Simulatie zou nooit stoppen
- Zou oneindige .wlf file genereren

---

## 📡 5. Monitor Process - Live Debugging (Regels 131-153)

Dit is een geavanceerd debug mechanisme dat real-time feedback geeft tijdens simulatie:

```vhdl
monitor_proc: process(CLK_out, LAT, OE)
    variable row_addr : unsigned(3 downto 0);
begin
    -- Bereken 4-bit row address uit individuele bits
    row_addr := D & C & B & A;
    ...
end process;
```

### A. CLK_out Monitoring

```vhdl
if rising_edge(CLK_out) then
    report "CLK pulse - Row: " & integer'image(to_integer(row_addr)) & 
           " | R1=" & std_logic'image(R1) & 
           " G1=" & std_logic'image(G1) & 
           " B1=" & std_logic'image(B1) &
           " | R2=" & std_logic'image(R2) & 
           " G2=" & std_logic'image(G2) & 
           " B2=" & std_logic'image(B2)
           severity note;
end if;
```

**Wat dit doet:**
- Triggert op **elke rising edge** van CLK_out
- Print huidige row nummer (0-15)
- Print alle 6 RGB data bits
- Gebeurt 32× per rij (voor 32 kolommen)

**Voorbeeld console output:**
```
# CLK pulse - Row: 0 | R1='1' G1='0' B1='0' | R2='0' G2='1' B2='0'
# CLK pulse - Row: 0 | R1='0' G1='0' B1='0' | R2='1' G2='1' B2='0'
# CLK pulse - Row: 0 | R1='1' G1='0' B1='0' | R2='0' G2='1' B2='0'
... (32 keer voor kolom 0-31)
# CLK pulse - Row: 1 | R1='1' G1='0' B1='0' | R2='0' G2='1' B2='0'
```

**Waarom nuttig?**
- ✅ Zie exact welke data per kolom wordt verzonden
- ✅ Verifieer dat data klopt met verwacht patroon
- ✅ Detecteer glitches of verkeerde data
- ✅ Debug timing issues

**Concatenatie uitleg:**
```vhdl
row_addr := D & C & B & A;

Voorbeeld:
D = '1', C = '0', B = '1', A = '0'
row_addr = "1010" = 10 (decimal)
```

### B. LAT Monitoring

```vhdl
if rising_edge(LAT) then
    report "LATCH: Data voor row " & integer'image(to_integer(row_addr)) & 
           " gelatched" severity note;
end if;
```

**Wat dit doet:**
- Detecteert wanneer data wordt "gelatched" naar de LED drivers
- Gebeurt **1× per rij** (na 32 CLK pulsen)
- Bevestigt dat data correct is overgedragen

**Voorbeeld output:**
```
# CLK pulse - Row: 0 | ...  ← 32x
# LATCH: Data voor row 0 gelatched  ← 1x
# CLK pulse - Row: 1 | ...
# LATCH: Data voor row 1 gelatched
```

**Fysieke betekenis:**
In echte hardware triggert LAT signaal de 74HC595-achtige shift registers om:
1. Data van shift register naar output register te kopiëren
2. Outputs te bevriezen terwijl nieuwe data binnenkomt
3. Voorkomen van "tearing" (half oude/half nieuwe data)

### C. OE (Output Enable) Monitoring

```vhdl
if falling_edge(OE) then
    report "OUTPUT ENABLED voor row " & integer'image(to_integer(row_addr)) 
           severity note;
end if;
```

**Wat dit doet:**
- Detecteert wanneer output wordt geactiveerd
- **Falling edge** want OE is **active-low**
  - OE = '1' → Output disabled (drivers high-Z)
  - OE = '0' → Output enabled (LEDs kunnen branden)
- Gebeurt **1× per rij** (na LAT)

**Timing sequentie:**
```
1. Data shift in (32 CLK pulsen)    ← RGB data changes
2. LAT goes high (latch data)        ← Data frozen in output register
3. OE goes low (enable output)       ← LEDs turn on
4. Display for ~1000 clocks          ← Persistence of vision
5. OE goes high (disable output)     ← LEDs turn off
6. Repeat for next row
```

**Console output:**
```
# CLK pulse - Row: 0 | ...           ← Col 0
# CLK pulse - Row: 0 | ...           ← Col 1
... (30 more)
# CLK pulse - Row: 0 | ...           ← Col 31
# LATCH: Data voor row 0 gelatched   ← Data ready
# OUTPUT ENABLED voor row 0          ← LEDs ON!
```

---

## 🔄 Typische Simulatie Flow - Complete Cyclus

Laten we één complete rij-cyclus doorlopen in detail:

### Fase 1: IDLE State (Start)

**State Machine:**
```
current_state = IDLE
row_counter = 0 (ABCD = 0000)
col_counter = 0
```

**Signalen:**
```
OE = '1'   (LEDs uit)
LAT = '0'  (data niet gelatched)
CLK_out = '0'
```

**Wat gebeurt er:**
- Component bereidt zich voor om data te shiften
- State machine gaat naar SHIFT_DATA

---

### Fase 2: SHIFT_DATA State (32 Clock Cycles)

**Voor elke kolom (0-31):**

```vhdl
CLK_out togglet:
    
Cycle 1 (Col 0):
    CLK_out: 0→1 (rising edge)
        - Monitor print: "CLK pulse - Row: 0 | R1='1' G1='0' B1='0' | R2='0' G2='1' B2='0'"
        - Data voor kolom 0 klaarstaat
    CLK_out: 1→0 (falling edge)
        - col_counter += 1
        
Cycle 2 (Col 1):
    CLK_out: 0→1 (rising edge)
        - Monitor print: "CLK pulse - Row: 0 | R1='0' G1='0' B1='0' | R2='1' G2='1' B2='0'"
        - Data voor kolom 1 klaarstaat
    CLK_out: 1→0 (falling edge)
        - col_counter += 1

... (herhaal 30 keer meer)

Cycle 32 (Col 31):
    CLK_out: 0→1 (rising edge)
        - Monitor print: "CLK pulse - Row: 0 | ..."
        - Data voor kolom 31 (laatste)
    CLK_out: 1→0 (falling edge)
        - col_counter = 32
        - current_state → LATCH_DATA
```

**Waveform:**
```
CLK_out: _┌─┐_┌─┐_┌─┐_┌─┐_ ... _┌─┐_  (32 pulsen)
          │ │ │ │ │ │ │ │     │ │
          └─┘ └─┘ └─┘ └─┘     └─┘
          
R1:      ──█──────█──────█─ ... ──█──  (data voor elke kolom)
G1:      ────────────────── ... ─────
B1:      ────────────────── ... ─────
R2:      ────────────────── ... ─────
G2:      ────█──────█───── ... ──█──
B2:      ────────────────── ... ─────

          ↑     ↑     ↑           ↑
        Col0  Col1  Col2        Col31
```

---

### Fase 3: LATCH_DATA State

```vhdl
current_state = LATCH_DATA
LAT goes high:

LAT: _______┌─────────┐_______
            │         │
            └─────────┘
            ↑
            Monitor: "LATCH: Data voor row 0 gelatched"
```

**Wat gebeurt er:**
- LAT signaal gaat hoog (rising edge)
- Monitor proces detecteert dit en print bericht
- In echte hardware: data wordt gekopieerd van shift register naar output register
- 192 bits data (32 cols × 6 colors) nu "vastgevroren"
- State machine → DISPLAY

**Duur:** Minimaal 1 clock cycle

---

### Fase 4: DISPLAY State

```vhdl
current_state = DISPLAY
LAT goes low:
LAT: ─────────┐         ┌───────
              │         │
              └─────────┘

OE goes low (enable):
OE: ──────────┐_________________
              │
              └─────────────────
              ↑
              Monitor: "OUTPUT ENABLED voor row 0"

refresh_counter counts:
0 → 1 → 2 → 3 → ... → 999 → 1000

When refresh_counter = 1000:
    - row_counter += 1 (0→1)
    - current_state → IDLE (start next row)
```

**Wat gebeurt er:**
1. LAT gaat terug laag
2. OE gaat laag (falling edge) → LEDs gaan AAN
3. Monitor detecteert falling edge OE
4. Display tijd: ~1000 clock cycles = 20us @ 50MHz
5. Na 1000 cycles: volgende rij

**Waveform complete cyclus:**
```
State:    IDLE  SHIFT_DATA (32 CLK)  LATCH  DISPLAY (1000 cycles)
          ────┬──────────────────────┬──────┬─────────────────────
              │    CLK pulsen        │ LAT  │   OE enabled
              
CLK_out:  ____┌─┐_┌─┐_┌─┐_..._┌─┐___________________________
              │ │ │ │ │ │   │ │
              └─┘ └─┘ └─┘   └─┘

LAT:      __________________________┌─────┐_______________
                                    │     │
                                    └─────┘

OE:       ──────────────────────────────────┐___________┐──
                                            │           │
                                            └───────────┘
                                            ← LEDs ON →
                                            
ABCD:     0000 (throughout this row)

RGB:      Data Data Data ... Data   Fixed    Fixed
          col0 col1 col2    col31   (latched) (displaying)
```

---

### Fase 5: Increment & Repeat

```vhdl
After DISPLAY:
    row_counter: 0 → 1
    ABCD: 0000 → 0001
    current_state → IDLE
    
Then repeat Phases 1-4 for row 1
Then row 2
...
Then row 15

After row 15:
    row_counter: 15 → 0  (wraps around)
    ABCD: 1111 → 0000
    Cycle starts over!
```

**Complete scan timing:**
```
1 row = 32 CLK cycles + 1 LAT cycle + 1000 display cycles
      ≈ 1033 cycles @ 50MHz
      = 1033 × 20ns
      = 20,660 ns
      = 20.66 us

16 rows = 16 × 20.66 us
        = 330.56 us
        ≈ 3000 Hz refresh rate
```

**Waarom dit belangrijk is:**
- 3000 Hz >> 60 Hz (human flicker fusion threshold)
- Zorgt voor stabiel beeld zonder flikkering
- Elke LED brandt 1/16e van de tijd (duty cycle = 6.25%)

---

## 📊 Wat Kun Je Observeren in Waveforms?

### 1. Clock Relaties & Hierarchy

```
Hoofdclock (50 MHz):
clk:      ┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_
          │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
          └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘
          
CLK_out (gedivide, alleen tijdens SHIFT_DATA):
          __┌─┐___┌─┐___┌─┐___┌─┐___┌─┐___________
            │ │   │ │   │ │   │ │   │ │
            └─┘   └─┘   └─┘   └─┘   └─┘
            ↑     ↑     ↑     ↑     ↑
          Col0  Col1  Col2  Col3  Col4

LAT (1 pulse per rij):
          ____________________________________┌─┐_____
                                              │ │
                                              └─┘

OE (enable tijdens display):
          ──────────────────────────────────────┐____┐
                                                │    │
                                                └────┘
```

**Relaties:**
- CLK_out frequentie << clk frequentie
- LAT komt na laatste CLK_out puls
- OE activeert na LAT

---

### 2. Row Address Progression

```
Tijd →

ABCD:  0000 ────────── 0001 ────────── 0010 ────────── 0011 ──
       (0)   20us      (1)   20us      (2)   20us      (3)

       ──────── ... ────────── 1110 ────────── 1111 ────────── 0000 ──
                                (14)   20us      (15)   20us      (0)
                                                                  ↑
                                                              Wraps!
```

**Wat te verifiëren:**
- ✅ Counter telt sequentieel (geen sprongen)
- ✅ Geen stuck values
- ✅ Correct wrap-around (15→0)
- ✅ Timing tussen increments consistent

---

### 3. RGB Data Patterns

#### Checkerboard (pattern="000")

```
Tijd →  (Row 0, showing first 8 columns)

Col:      0   1   2   3   4   5   6   7
R1:     ──█───────█───────█───────█─────
G1:     ────────────────────────────────
B1:     ────────────────────────────────
R2:     ────────────────────────────────
G2:     ──█───────█───────────█───────█─
B2:     ────────────────────────────────

CLK:    _┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐
         │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
         └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘
```

**Patroon:** Alternerende R1 en G2

---

#### All White (pattern="011")

```
Col:      0   1   2   3   4   5   6   7
R1:     ──█───█───█───█───█───█───█───█─
G1:     ──█───█───█───█───█───█───█───█─
B1:     ──█───█───█───█───█───█───█───█─
R2:     ──█───█───█───█───█───█───█───█─
G2:     ──█───█───█───█───█───█───█───█─
B2:     ──█───█───█───█───█───█───█───█─

CLK:    _┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐
         │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
         └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘
```

**Patroon:** Alle RGB lijnen constant '1'

---

#### Vertical Lines (pattern="010")

```
Col:      0   1   2   3   4   5   6   7
R1:     ──█───────█───────█───────█─────  Even cols: upper RGB
G1:     ──█───────█───────█───────█─────
B1:     ──█───────█───────█───────█─────
R2:     ──────█───────█───────█───────█─  Odd cols: lower RGB
G2:     ──────█───────█───────█───────█─
B2:     ──────█───────█───────█───────█─

CLK:    _┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐
         │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
         └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘
```

**Patroon:** Upper en lower alterneren per kolom

---

### 4. State Machine Transitions

```
State:   IDLE  SHIFT_DATA (32 cycles)  LATCH  DISPLAY (1000)  IDLE
         ────┬──────────────────────────┬─────┬──────────────┬────
             │                          │     │              │
             └─ Start shifting          │     │              └─ Next row
                                        │     │
                                        │     └─ Enable output
                                        │
                                        └─ Lock data

Observeer in waveforms:
UUT/current_state signal toont deze transities
```

---

## ✅ Verificatie Checklist

Gebruik deze checklist bij het analyseren van de simulatie:

### Hardware Functionaliteit

#### Timing Verificatie
- [ ] Clock loopt continu met 50 MHz (20ns periode)
- [ ] CLK_out frequentie is lager dan clk
- [ ] CLK_out stopt tussen rijen (tijdens LATCH/DISPLAY)
- [ ] LAT puls komt precies na 32ste CLK_out puls
- [ ] OE falling edge komt na LAT rising edge
- [ ] Display tijd is consistent (~1000 cycles)

#### Reset Verificatie
- [ ] Reset zet alle counters naar 0
- [ ] State machine gaat naar IDLE
- [ ] OE gaat naar '1' (disabled)
- [ ] Row counter = 0 (ABCD = 0000)
- [ ] Col counter = 0

#### Row Multiplexing
- [ ] Address lines (A,B,C,D) tellen van 0 tot 15
- [ ] Elke rij wordt in volgorde aangestuurd
- [ ] Na rij 15 gaat het terug naar rij 0 (cyclisch)
- [ ] Geen duplicate rijen
- [ ] Geen gemiste rijen
- [ ] Timing tussen rijen consistent

#### Data Clocking
- [ ] CLK_out genereert exact 32 pulsen per rij
- [ ] RGB data wijzigt synchroon met CLK_out rising edges
- [ ] Data is stabiel tijdens CLK_out high
- [ ] Geen glitches op RGB lijnen
- [ ] Data hold time correct (data blijft na CLK falling)

#### Latch Timing
- [ ] LAT puls komt na laatste CLK_out puls
- [ ] LAT is minimaal 1 klok periode hoog
- [ ] LAT rising edge correct getimed
- [ ] OE gaat pas laag na LAT terug laag is
- [ ] Geen overlap tussen CLK_out en LAT

---

### Data Pattern Verificatie

#### Test 2: Checkerboard
- [ ] R1 alterneert per kolom
- [ ] G2 alterneert per kolom
- [ ] R1 en G2 zijn complementair
- [ ] Andere RGB lijnen zijn '0'
- [ ] Patroon consistent over meerdere rijen

#### Test 3: Horizontal Lines
- [ ] R1 constant '1' voor alle kolommen
- [ ] B2 constant '1' voor alle kolommen
- [ ] Andere RGB lijnen zijn '0'
- [ ] Geen variatie per kolom

#### Test 4: Vertical Lines
- [ ] Even kolommen: R1,G1,B1 = '1'
- [ ] Oneven kolommen: R2,G2,B2 = '1'
- [ ] Alternerend patroon correct
- [ ] col_counter(0) correct gebruikt

#### Test 5: All White
- [ ] R1,G1,B1,R2,G2,B2 allemaal '1'
- [ ] Constant voor alle kolommen
- [ ] Geen '0' waarden zichtbaar

#### Test 6: Red Gradient
- [ ] Kolom 0-15: R1 = '1'
- [ ] Kolom 16-31: R2 = '1'
- [ ] Overgang bij kolom 16 correct
- [ ] Andere kleuren '0'

#### Test 7: All Off
- [ ] Alle RGB lijnen '0'
- [ ] Constant voor alle kolommen
- [ ] OE toggle nog steeds zichtbaar

---

### Console Output Verificatie

#### CLK Pulse Messages
- [ ] "CLK pulse - Row: X" incrementeert correct
- [ ] RGB waarden matchen waveform
- [ ] 32 berichten per rij
- [ ] Row nummer constant tijdens 32 pulsen

#### LATCH Messages
- [ ] "LATCH: Data voor row X" na elke 32 CLK pulsen
- [ ] Row nummer klopt
- [ ] 1 bericht per rij
- [ ] Timing klopt met waveform

#### OUTPUT ENABLED Messages
- [ ] "OUTPUT ENABLED voor row X" na elke LATCH
- [ ] Row nummer klopt
- [ ] 1 bericht per rij
- [ ] Komt na LATCH bericht

---

### State Machine Verificatie

- [ ] State sequence: IDLE → SHIFT_DATA → LATCH_DATA → DISPLAY
- [ ] Geen onverwachte states
- [ ] Geen stuck states
- [ ] Transities gebeuren op juiste momenten:
  - [ ] IDLE → SHIFT_DATA: onmiddellijk
  - [ ] SHIFT_DATA → LATCH_DATA: na col_counter = 32
  - [ ] LATCH_DATA → DISPLAY: na LAT pulse
  - [ ] DISPLAY → IDLE: na refresh_counter = 1000

---

### Performance Metrics

Bereken en verifieer:

#### Timing Berekeningen
```
1 rij tijd = (32 CLK + 1 LAT + 1000 DISPLAY) × 20ns
           = 1033 × 20ns
           = 20,660 ns
           = 20.66 μs

16 rijen tijd = 16 × 20.66 μs
              = 330.56 μs
              = 0.33 ms

Refresh rate = 1 / 0.33ms
             = 3030 Hz
```

- [ ] 1 rij tijd ≈ 20 μs
- [ ] 16 rijen tijd ≈ 330 μs
- [ ] Refresh rate ≈ 3000 Hz
- [ ] Duty cycle per LED ≈ 6.25% (1/16)

---

## 🐛 Debug Tips & Troubleshooting

### Problem 1: Geen Console Output

**Symptomen:**
- Waveforms zijn OK
- Maar geen "CLK pulse" of "LATCH" berichten

**Mogelijke oorzaken:**
1. Monitor process sensitivity list verkeerd
2. Report statements syntax errors
3. ModelSim transcript window niet zichtbaar

**Oplossing:**
```vhdl
-- Check sensitivity list:
process(CLK_out, LAT, OE)  -- Moet alle signalen bevatten waar je op triggert

-- Check report syntax:
report "Message" severity note;  -- Niet vergeten: severity note/warning/error
```

**In ModelSim:**
- Kijk in **Transcript** window (onderaan)
- Als niet zichtbaar: `View → Transcript`

---

### Problem 2: CLK_out Stopt Niet

**Symptomen:**
- CLK_out blijft togglen tijdens DISPLAY state
- 32 pulsen limiet wordt niet nageleefd

**Debug stappen:**
1. Check `col_counter` in waveform
2. Verifieer dat `col_counter` reset na rij
3. Check state transitions

**In waveform:**
```
Add signals:
- /matrix32_led_tb/UUT/col_counter
- /matrix32_led_tb/UUT/current_state
- /matrix32_led_tb/UUT/CLK_out

Look for:
- col_counter should reset to 0 after reaching 31
- State should go from SHIFT_DATA to LATCH_DATA
```

---

### Problem 3: Row Address Niet Correct

**Symptomen:**
- ABCD telt niet sequentieel
- Rijen worden overgeslagen
- Counter stuck op bepaalde waarde

**Debug:**
```tcl
# In ModelSim wave window, voeg toe:
add wave /matrix32_led_tb/UUT/row_counter
add wave /matrix32_led_tb/A
add wave /matrix32_led_tb/B
add wave /matrix32_led_tb/C
add wave /matrix32_led_tb/D

# Check dat:
# A = row_counter(0)
# B = row_counter(1)
# C = row_counter(2)
# D = row_counter(3)
```

**Common bug:**
```vhdl
-- FOUT:
A <= std_logic_vector(row_counter);  -- Type mismatch!

-- CORRECT:
A <= row_counter(0);
B <= row_counter(1);
C <= row_counter(2);
D <= row_counter(3);
```

---

### Problem 4: RGB Data Niet Zichtbaar

**Symptomen:**
- R1,G1,B1,R2,G2,B2 allemaal '0' of 'X'
- Geen data variatie

**Debug stappen:**

1. **Check test_pattern input:**
```tcl
# Voeg toe aan wave:
add wave /matrix32_led_tb/test_pattern

# Verifieer dat het wijzigt (000, 001, 010, etc.)
```

2. **Check case statement in component:**
```vhdl
-- In Matrix32_LED.vhd, check:
case test_pattern is
    when "000" => ...
    when "001" => ...
    -- etc
end case;
```

3. **Check data assignment:**
```tcl
# Zoom in op SHIFT_DATA state
# R1 should change per column for most patterns
```

---

### Problem 5: Simulatie Stopt Niet

**Symptomen:**
- `run -all` draait eeuwig
- Moet handmatig stoppen (Ctrl+C)

**Oorzaak:**
`sim_done` wordt nooit `true`

**Oplossing:**
```vhdl
-- Check in stimulus process:
-- Laatste regel moet zijn:
sim_done <= true;
wait;
```

**Emergency stop:**
```tcl
# In ModelSim:
stop
quit -sim
```

---

### Problem 6: Timing Violations

**Symptomen:**
- Setup/hold time warnings
- Metastability warnings
- "X" waarden in waveform

**Check:**
```vhdl
-- In testbench, check clock period:
constant clk_period : time := 20 ns;  -- Moet 20ns zijn voor 50MHz

-- Check wait statements:
wait for clk_period/2;  -- Moet exact half zijn
```

---

### Problem 7: Monitor Process Crash

**Symptomen:**
```
** Error: (vcom-1136) Unknown identifier "row_addr"
```

**Oorzaak:**
Variabele buiten process of verkeerde scope

**Correct formaat:**
```vhdl
monitor_proc: process(CLK_out, LAT, OE)
    variable row_addr : unsigned(3 downto 0);  -- Binnen process!
begin
    row_addr := D & C & B & A;  -- := voor variabele
    
    if rising_edge(CLK_out) then
        report "Row: " & integer'image(to_integer(row_addr));
    end if;
end process;
```

**LET OP:**
- Variabele: `:=` (direct assignment)
- Signaal: `<=` (scheduled assignment)

---

## 🎓 Belangrijke VHDL Concepten

### 1. Wait Statements

```vhdl
wait;                    -- Wacht voor altijd (stopt proces)
wait for 100 ns;         -- Wacht 100 nanoseconden
wait for clk_period;     -- Wacht 1 clock periode
wait until clk = '1';    -- Wacht tot conditie waar is
wait on clk;             -- Wacht tot signaal wijzigt
```

**Gebruik in testbench:**
```vhdl
-- Timing control:
wait for 100 us;

-- Synchronisatie:
wait until rising_edge(clk);

-- Einde simulatie:
sim_done <= true;
wait;  -- Stop voor altijd
```

---

### 2. Report Statements

```vhdl
report "Bericht" severity note;      -- Informatie (groen)
report "Waarschuwing" severity warning;  -- Waarschuwing (geel)
report "Fout!" severity error;       -- Error (rood, gaat door)
report "Fataal!" severity failure;   -- Failure (rood, stopt sim)
```

**String concatenatie:**
```vhdl
report "Counter = " & integer'image(counter_value);
report "Signal = " & std_logic'image(signal_value);
report "Vector = " & to_string(vector_value);  -- VHDL-2008
```

**Voorbeeld:**
```vhdl
if row_counter > 15 then
    report "ERROR: Row counter out of bounds!" severity error;
end if;
```

---

### 3. Process Sensitivity List

```vhdl
-- Concurrent process (altijd actief):
process(CLK_out, LAT, OE)  -- Triggert bij wijziging van deze signalen
begin
    if rising_edge(CLK_out) then
        -- Code here
    end if;
end process;

-- Sequential process (voor testbench):
process
begin
    wait for 100 ns;
    signal <= '1';
    wait for 100 ns;
    signal <= '0';
end process;
```

**Verschil:**
- **Met sensitivity list**: Event-driven (triggert bij signaal wijziging)
- **Zonder sensitivity list**: Tijd-driven (met wait statements)

---

### 4. Signal vs Variable

```vhdl
-- Signal (voor hardware):
signal counter : integer := 0;
counter <= counter + 1;  -- Scheduled assignment (na delta delay)

-- Variable (voor berekeningen):
variable temp : integer := 0;
temp := temp + 1;        -- Immediate assignment
```

**In testbench monitor:**
```vhdl
process(A, B, C, D)
    variable row_addr : unsigned(3 downto 0);
begin
    row_addr := D & C & B & A;  -- Onmiddellijke waarde
    -- Gebruik row_addr direct
end process;
```

---

### 5. Concurrent vs Sequential

**Concurrent (parallel):**
```vhdl
-- Deze statements runnen allemaal tegelijk:
UUT: entity work.component port map(...);
monitor_proc: process(...) ...;
clk_proc: process ...;
stim_proc: process ...;
```

**Sequential (binnen process):**
```vhdl
process
begin
    reset <= '1';       -- Stap 1
    wait for 100 ns;    -- Stap 2
    reset <= '0';       -- Stap 3
    wait for 100 ns;    -- Stap 4
end process;
```

---

### 6. Type Conversions

```vhdl
-- std_logic → integer:
integer_val := to_integer(unsigned(std_logic_signal));

-- integer → string:
string_val := integer'image(integer_val);

-- std_logic → string:
string_val := std_logic'image(std_logic_signal);  -- '0' of '1'

-- Concatenatie:
combined := D & C & B & A;  -- 4 std_logic → 4-bit vector
```

**In monitor proces:**
```vhdl
variable row_addr : unsigned(3 downto 0);
row_addr := D & C & B & A;  -- Concateneer 4 bits
report "Row: " & integer'image(to_integer(row_addr));
```

---

## 📚 Referentie: Test Pattern Overzicht

| Pattern | Binair | Naam             | Verwacht Gedrag                          |
|---------|--------|------------------|------------------------------------------|
| 0       | 000    | Checkerboard     | R1 en G2 alterneren per (row+col) mod 2 |
| 1       | 001    | Horizontal       | R1='1' upper, B2='1' lower               |
| 2       | 010    | Vertical         | RGB1 even cols, RGB2 odd cols            |
| 3       | 011    | All White        | Alle RGB lijnen '1'                      |
| 4       | 100    | Red Gradient     | R1 col<16, R2 col>=16                    |
| 5       | 101    | (undefined)      | Default: alles uit                       |
| 6       | 110    | (undefined)      | Default: alles uit                       |
| 7       | 111    | All Off          | Alle RGB lijnen '0'                      |

---

## 📊 Simulatie Statistieken

### Typical Resource Usage

```
Simulation time: ~1 ms
Wall clock time: ~10-30 seconden (afhankelijk van PC)
Memory usage: ~50-100 MB
Waveform size: ~5-10 MB

Events generated:
- Clock edges: ~50,000 (1ms / 20ns)
- CLK_out edges: ~8,000 (32 × 16 × 8 tests)
- LAT pulses: ~4,000
- OE toggles: ~4,000
- State changes: ~16,000
- Report statements: ~200,000+

Total signals tracked: ~30
```

---

## ✨ Samenvatting

### De Testbench in 1 Minuut

Deze testbench:

1. **Genereert een 50 MHz clock** die het hele systeem aandrijft
2. **Instantieert het Matrix32_LED component** als UUT
3. **Voert 8 tests uit** met verschillende patronen:
   - Reset test
   - 6 display patronen (checkerboard, lines, etc.)
   - Row scanning verificatie
4. **Monitor proces** print real-time debug info:
   - Elke CLK puls met RGB data
   - Elke LATCH event
   - Elke OUTPUT ENABLE event
5. **Stopt automatisch** na alle tests

### Wat Je Leert

Door deze testbench te analyseren leer je:

✅ Hoe LED matrix multiplexing werkt  
✅ Clock domain management (50MHz → variable CLK_out)  
✅ State machine timing en verificatie  
✅ VHDL testbench technieken (stimulus, monitoring, assertions)  
✅ Waveform analyse en timing verificatie  
✅ Debug strategieën voor complexe digitale systemen  

### Volgende Stappen

Na succesvolle simulatie:

1. **Analyseer waveforms** - Check alle timing requirements
2. **Lees console output** - Verifieer data patronen
3. **Experimenteer** - Wijzig test_pattern tijden, voeg tests toe
4. **Hardware test** - Program FPGA en test met echte matrix
5. **Optimalisatie** - PWM toevoegen, brightness control, etc.

---

**🎉 Veel succes met je simulatie!**

---

## 📎 Appendix: Handige ModelSim Commando's

### Compile & Run
```tcl
# Compileren
vcom -2008 -work work Matrix32_LED.vhd
vcom -2008 -work work Matrix32_LED_tb.vhd

# Simuleren
vsim -voptargs=+acc work.matrix32_led_tb

# Signalen toevoegen
add wave /matrix32_led_tb/UUT/*

# Runnen
run -all

# Zoom
wave zoom full
```

### Wave Viewer Commands
```tcl
# Zoom
wave zoom full
wave zoom range 0 100us

# Cursor
wave cursor time 1000ns

# Signaal radix wijzigen
radix signal /path/signal unsigned

# Dividers toevoegen
add wave -divider "Section Name"
```

### Debug Commands
```tcl
# Print signaal waarde
examine /matrix32_led_tb/clk

# Breakpoint (advanced)
bp /matrix32_led_tb/UUT/current_state LATCH_DATA

# Step through
step
```

---

**Einde Testbench Uitleg** 📘
