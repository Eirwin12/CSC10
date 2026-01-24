# ModelSim Handleiding voor 32x32 LED Matrix Simulatie
## DE1-SoC Bord (Altera Cyclone V SoC 5CSEMA5F31C6N)

---

## 📋 Overzicht
Deze handleiding leidt je door het complete proces van VHDL simulatie met ModelSim voor een 32x32 RGB LED matrix controller. De matrix werkt volgens het multiplexing principe met 8 interleaved secties.

---

## 🎯 Stap 1: Project Voorbereiding

### Benodigde bestanden:
- ✅ `Matrix32_LED.vhd` - Hoofdcomponent voor LED matrix
- ✅ `Matrix32_LED_tb.vhd` - Testbench
- ✅ `modelsim.ini` - ModelSim configuratie (al aanwezig)

### Werkingsprincipe LED Matrix:
```
16x32 RGB Matrix = 512 LEDs
├── 8 Interleaved secties (multiplexed)
│   ├── Sectie 0: Rij 1 + Rij 9  (A=000)
│   ├── Sectie 1: Rij 2 + Rij 10 (A=001)
│   ├── Sectie 2: Rij 3 + Rij 11 (A=010)
│   ├── ...
│   └── Sectie 7: Rij 8 + Rij 16 (A=111)
│
├── 12 LED driver chips (192 outputs totaal)
│   └── 192 = 64 LEDs × 3 kleuren (R,G,B)
│
└── Control signalen:
    ├── A, B, C: 3-bit row address (selecteert sectie 0-7)
    ├── R1,G1,B1: RGB data upper half (rij 1-8)
    ├── R2,G2,B2: RGB data lower half (rij 9-16)
    ├── CLK: Shift clock (192 pulsen per rij)
    ├── LAT: Latch signal (data vastzetten)
    └── OE: Output Enable (actief laag)
```

---

## 🚀 Stap 2: ModelSim Starten

### Via Command Prompt/PowerShell:
```powershell
# Navigeer naar je project directory
cd "C:\Users\mitch\Documents\GitHub\CSC10\#workspace\Matrix32_component_maken"

# Start ModelSim
vsim
```

### Via GUI:
1. Start ModelSim-Altera vanuit Windows menu
2. Navigeer naar je project folder via `File > Change Directory`

---

## 📦 Stap 3: Nieuwe Library Aanmaken

In de ModelSim **Transcript** venster:

```tcl
# Maak een nieuwe work library
vlib work

# Map de work library
vmap work work

# Verifieer de library
vdir
```

**Verwachte output:**
```
# Compiling work.matrix32_led...
# Compiling work.matrix32_led_tb...
```

---

## ⚙️ Stap 4: VHDL Bestanden Compileren

### Methode A: Via Transcript (Aanbevolen)

```tcl
# Compileer de hoofdcomponent
vcom -2008 -work work Matrix32_LED.vhd

# Compileer de testbench
vcom -2008 -work work Matrix32_LED_tb.vhd
```

### Methode B: Via GUI
1. Klik op `Compile > Compile...`
2. Selecteer `Matrix32_LED.vhd`
3. Klik **Compile**
4. Herhaal voor `Matrix32_LED_tb.vhd`

### Compilatie Succesvol? ✅
Je zou dit moeten zien:
```
# Model Technology ModelSim ALTERA vcom 10.5b Compiler 2016.10 Oct  5 2016
# -- Loading package STANDARD
# -- Loading package NUMERIC_STD
# -- Compiling entity matrix32_led
# -- Compiling architecture behavioral of matrix32_led
```

### Fouten? ⚠️
- **Syntax errors**: Controleer haakjes, puntkomma's, end statements
- **Library errors**: Zorg dat `IEEE.STD_LOGIC_1164.ALL` en `IEEE.NUMERIC_STD.ALL` geïncludeerd zijn
- **Path errors**: Gebruik absolute paths of zorg dat je in de juiste directory bent

---

## 🎬 Stap 5: Simulatie Opstarten

```tcl
# Start simulatie met testbench als top-level entity
vsim -voptargs=+acc work.matrix32_led_tb

# Of met GUI optimalisatie:
vsim -voptargs=+acc work.matrix32_led_tb -gui
```

### Alternatief via GUI:
1. Ga naar `Simulate > Start Simulation...`
2. Vouw de **work** library uit in de tree
3. Selecteer `matrix32_led_tb`
4. Klik **OK**

---

## 📊 Stap 6: Signalen Toevoegen aan Wave Viewer

### Alle signalen automatisch toevoegen:
```tcl
# Voeg alle signalen van de testbench toe
add wave -divider "Testbench Control"
add wave /matrix32_led_tb/clk
add wave /matrix32_led_tb/reset
add wave /matrix32_led_tb/test_pattern

# Voeg signalen van het UUT (design onder test) toe
add wave -divider "LED Matrix Control"
add wave /matrix32_led_tb/UUT/A
add wave /matrix32_led_tb/UUT/B
add wave /matrix32_led_tb/UUT/C
add wave /matrix32_led_tb/UUT/CLK_out
add wave /matrix32_led_tb/UUT/LAT
add wave /matrix32_led_tb/UUT/OE

add wave -divider "RGB Data Upper"
add wave /matrix32_led_tb/UUT/R1
add wave /matrix32_led_tb/UUT/G1
add wave /matrix32_led_tb/UUT/B1

add wave -divider "RGB Data Lower"
add wave /matrix32_led_tb/UUT/R2
add wave /matrix32_led_tb/UUT/G2
add wave /matrix32_led_tb/UUT/B2

add wave -divider "Internal State"
add wave /matrix32_led_tb/UUT/current_state
add wave /matrix32_led_tb/UUT/row_counter
add wave /matrix32_led_tb/UUT/col_counter
```

### Via GUI:
1. Ga naar het **Objects** venster
2. Selecteer signalen (Ctrl+Click voor meerdere)
3. Rechtermuisklik > **Add to Wave**
4. Of sleep signalen naar Wave venster

---

## ▶️ Stap 7: Simulatie Uitvoeren

### Volledige simulatie:
```tcl
# Run tot einde simulatie (sim_done = true)
run -all
```

### Gefaseerd runnen (voor analyse):
```tcl
# Run specifieke tijd
run 100 us

# Continue voor nog meer tijd
run 200 us

# Of run tot specifiek event
run 1 ms
```

### Simulatie controle commando's:
```tcl
# Restart simulatie
restart -f

# Stop simulatie
stop

# Continue na stop
run 100 us
```

---

## 🔍 Stap 8: Waveform Analyse

### Zoom en navigatie:
- **Zoom Full**: Druk `F` of klik ![zoom full icon]
- **Zoom In**: Druk `I` of gebruik muiswiel
- **Zoom Out**: Druk `O`
- **Zoom Range**: Sleep met middelmuisknop

### Cursors gebruiken:
```tcl
# Plaats cursor op specifieke tijd
cursor add -time 1000ns

# Meet tijd tussen twee events
# 1. Klik op eerste event (cursor verschijnt)
# 2. Shift+Click op tweede event
# 3. Delta tijd wordt getoond in status bar
```

### Wat te controleren in waveforms:

#### ✅ Test 1: Reset functionaliteit
- Controleer dat alle signalen op default waarde staan na reset
- `OE` moet hoog zijn (output disabled)
- `row_counter` moet 0 zijn

#### ✅ Test 2: Row Scanning
Zoom in op enkele complete refresh cycli:
```
Verwacht patroon:
├── A = "000" (Rij 1 + 9)
│   ├── 32 CLK pulsen (shift data)
│   ├── LAT = '1' (latch pulse)
│   └── OE = '0' (display actief)
├── A = "001" (Rij 2 + 10)
│   └── ... (herhaal)
├── ...
└── A = "111" (Rij 8 + 16)
    └── Terug naar "000"
```

#### ✅ Test 3: Data Patronen
Voor **Checkerboard** patroon (`test_pattern = "000"`):
- R1 en G2 moeten alterneren per kolom
- Verifieer dat data synchroon loopt met CLK_out

Voor **Horizontal lines** (`test_pattern = "001"`):
- R1 moet constant '1' zijn voor alle kolommen in een rij
- B2 moet constant '1' zijn voor alle kolommen

#### ✅ Test 4: Timing
Controleer deze kritieke timings:
1. **Setup time**: Data moet stabiel zijn vóór CLK_out rising edge
2. **Latch pulse**: LAT moet minimaal 1 klok cyclus hoog blijven
3. **OE timing**: OE mag pas laag na LAT weer laag is

---

## 📈 Stap 9: Advanced Analyse

### Console output bekijken:
Het **Transcript** venster toont real-time debug berichten:
```
# Test 1: Reset functionaliteit
# CLK pulse - Row: 0 | R1='1' G1='0' B1='0' | R2='0' G2='1' B2='0'
# LATCH: Data voor row 0 gelatched
# OUTPUT ENABLED voor row 0
```

### Waveform meten:
```tcl
# Meet frequentie van CLK_out
wave cursor add -name cursor1 -time 1000ns
wave cursor add -name cursor2 -time 2000ns

# Of gebruik GUI measurement tools:
# Rechtermuisklik in wave > Cursors > New
```

### Signaal waarden bekijken:
1. Hover over signaal in Wave viewer
2. Of bekijk in **Objects** venster rechtsonder
3. Voor bus signalen (A, B, C): Kies display format:
   - Rechtermuisklik > Radix > Unsigned/Binary/Hexadecimal

---

## 💾 Stap 10: Resultaten Opslaan

### Waveform opslaan:
```tcl
# Sla huidige wave configuratie op
write format wave -window .main_pane.wave.interior.cs.body.pw.wf wave.do

# Later inladen:
do wave.do
```

### Screenshot maken:
1. Ga naar `File > Print` > `Print to File`
2. Kies **Postscript** of **PDF** format
3. Of gebruik Windows Snipping Tool voor specifieke delen

### Simulatie log exporteren:
```tcl
# Redirect transcript output naar bestand
transcript file simulation_log.txt

# Terug naar console:
transcript file ""
```

---

## 🐛 Stap 11: Debugging Tips

### Veelvoorkomende problemen:

#### Probleem: "No objects found"
**Oplossing:**
```tcl
# Hercompileer met debug info
vcom -2008 -work work +acc Matrix32_LED.vhd
vsim -voptargs=+acc work.matrix32_led_tb
```

#### Probleem: Waveforms zijn "flat" (geen transities)
**Oplossing:**
- Check of `run -all` uitgevoerd is
- Controleer of clock genereert (zie clk signaal)
- Verifieer dat reset goed werkt

#### Probleem: Simulatie blijft hangen
**Oplossing:**
```tcl
# Stop forcefully
stop

# Of restart volledig
restart -force
quit -sim
```

#### Probleem: "Compilation failed"
**Controle checklist:**
- [ ] IEEE libraries correct geïncludeerd?
- [ ] Alle `end process;` statements aanwezig?
- [ ] Component declaratie matcht entity definitie?
- [ ] VHDL-2008 syntax gebruikt met `-2008` flag?

---

## 📝 Stap 12: TCL Script voor Automatisering

Maak een script `run_sim.tcl` voor snelle simulatie:

```tcl
# run_sim.tcl - Automatische simulatie script

# Cleanup oude compilatie
if {[file exists work]} {
    vdel -all -lib work
}

# Maak library
vlib work
vmap work work

# Compileer bestanden
vcom -2008 -work work Matrix32_LED.vhd
vcom -2008 -work work Matrix32_LED_tb.vhd

# Start simulatie
vsim -voptargs=+acc work.matrix32_led_tb

# Voeg signalen toe
add wave -divider "Testbench Control"
add wave /matrix32_led_tb/clk
add wave /matrix32_led_tb/reset
add wave /matrix32_led_tb/test_pattern

add wave -divider "LED Matrix Control"
add wave /matrix32_led_tb/UUT/A
add wave /matrix32_led_tb/UUT/CLK_out
add wave /matrix32_led_tb/UUT/LAT
add wave /matrix32_led_tb/UUT/OE

add wave -divider "RGB Data Upper"
add wave /matrix32_led_tb/UUT/R1
add wave /matrix32_led_tb/UUT/G1
add wave /matrix32_led_tb/UUT/B1

add wave -divider "RGB Data Lower"
add wave /matrix32_led_tb/UUT/R2
add wave /matrix32_led_tb/UUT/G2
add wave /matrix32_led_tb/UUT/B2

add wave -divider "Internal State"
add wave /matrix32_led_tb/UUT/current_state
add wave /matrix32_led_tb/UUT/row_counter
add wave /matrix32_led_tb/UUT/col_counter

# Configure wave display
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -timelineunits us

# Run simulatie
run -all

# Zoom full
wave zoom full

# Print succes bericht
echo "========================================="
echo "Simulatie compleet!"
echo "Analyseer de waveforms in het Wave venster"
echo "========================================="
```

### Script uitvoeren:
```tcl
# In ModelSim Transcript:
do run_sim.tcl
```

---

## 🎓 Stap 13: Verificatie Checklist

Na het runnen van de simulatie, verifieer het volgende:

### ✅ Basis Functionaliteit
- [ ] Clock loopt continu met 50 MHz (20ns periode)
- [ ] Reset zet alle signalen naar default
- [ ] State machine doorloopt alle states: IDLE → SHIFT_DATA → LATCH_DATA → DISPLAY

### ✅ Row Multiplexing
- [ ] Address lines (A, B, C) tellen van 0 tot 7
- [ ] Elke rij wordt in volgorde aangestuurd
- [ ] Na rij 7 gaat het terug naar rij 0 (cyclisch)

### ✅ Data Clocking
- [ ] CLK_out genereert 32 pulsen per rij (voor 32 kolommen)
- [ ] RGB data (R1,G1,B1,R2,G2,B2) wijzigt synchroon met CLK_out
- [ ] Data is stabiel tijdens CLK_out high

### ✅ Latch Timing
- [ ] LAT puls komt na laatste CLK_out puls
- [ ] LAT is minimaal 1 klok periode hoog
- [ ] OE gaat pas laag (enabled) na LAT terug laag is

### ✅ Test Patronen
- [ ] Checkerboard toont alternerende pixels
- [ ] Horizontal lines: rij 1-8 rood, rij 9-16 blauw
- [ ] Vertical lines: kolommen alterneren
- [ ] Alle LEDs wit: R1=G1=B1=R2=G2=B2='1'

---

## 🔧 Extra Tips voor DE1-SoC

### Klok instellingen:
De DE1-SoC heeft een 50 MHz crystal oscillator:
```vhdl
-- Voor echte hardware, gebruik clock divider voor lagere refresh rate
-- Voor simulatie: gebruik hogere clk_divider waarde voor snellere waveforms
```

### Pin Assignment (voor later Quartus synthese):
```tcl
# Voorbeeld pin assignments voor DE1-SoC
set_location_assignment PIN_AF14 -to clk       # 50 MHz clock
set_location_assignment PIN_AA14 -to reset     # KEY[0]

# LED Matrix pins (pas aan aan je specifieke hardware)
set_location_assignment PIN_XX -to R1
set_location_assignment PIN_XX -to G1
# ... etc
```

---

## 📚 Volgende Stappen

Na succesvolle simulatie:

1. **Quartus Synthese**
   - Import de `Matrix32_LED.vhd` in Quartus
   - Maak pin assignments voor DE1-SoC
   - Compileer en genereer `.sof` bestand

2. **Hardware Testing**
   - Program FPGA via USB Blaster
   - Test met echte LED matrix
   - Debug met SignalTap (FPGA logic analyzer)

3. **Optimalisatie**
   - Voeg PWM toe voor brightness control
   - Implementeer frame buffer voor complexe patronen
   - Voeg communicatie interface toe (UART/SPI)

---

## 📞 Referenties

- **ModelSim User Manual**: [Intel FPGA Documentation]
- **VHDL-2008 Standard**: IEEE 1076-2008
- **DE1-SoC User Manual**: Terasic website
- **LED Matrix Datasheet**: Adafruit 32x32 RGB LED Matrix

---

## ✨ Samenvatting van Belangrijke Commando's

```tcl
# Setup
vlib work
vmap work work

# Compileren
vcom -2008 -work work Matrix32_LED.vhd
vcom -2008 -work work Matrix32_LED_tb.vhd

# Simuleren
vsim -voptargs=+acc work.matrix32_led_tb

# Signalen toevoegen
add wave -divider "Control"
add wave /matrix32_led_tb/UUT/*

# Runnen
run -all

# Cleanup
quit -sim
```

---

**Veel succes met je simulatie! 🚀**

Als je vragen hebt of tegen problemen aanloopt, check de console output voor error messages en debug info.
