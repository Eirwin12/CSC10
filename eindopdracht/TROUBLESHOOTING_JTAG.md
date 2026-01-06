# NIOS II JTAG Connection Troubleshooting

## Fout: "Unable to validate connection settings"

Deze fout treedt op wanneer Eclipse geen verbinding kan maken met de FPGA.

---

## Stap 1: Controleer Hardware Verbinding

### Checklist:
- [ ] USB Blaster kabel aangesloten op DE1-SoC (JP1 - USB Blaster II connector)
- [ ] USB kabel naar PC aangesloten
- [ ] DE1-SoC board aangezet (power schakelaar aan)
- [ ] Groene LED bij USB Blaster connector brandt

---

## Stap 2: Programmeer FPGA met .sof File

**BELANGRIJK**: De FPGA moet eerst geprogrammeerd zijn voordat software kan worden geüpload!

### In Quartus Prime:

1. Open Quartus Prime
2. Open project: `eindopdracht_Testris.qpf`
3. **Als compilatie nog niet compleet is:**
   - Processing → Start Compilation
   - Wacht tot "Full Compilation was successful"
4. **Programmeer FPGA:**
   - Tools → Programmer
   - Klik "Hardware Setup..."
   - Selecteer "USB-Blaster [USB-0]" (of [USB-1])
   - Klik "Close"
   - Zorg dat `eindopdracht_Testris.sof` in lijst staat
   - Vink "Program/Configure" aan
   - Klik **"Start"**
   - Wacht op "100% (Successful)"

### Verificatie:
- LEDs op DE1-SoC board zouden moeten reageren
- JTAG UART is nu actief

---

## Stap 3: Test JTAG Verbinding

### In NIOS II Command Shell (niet Eclipse!):

```bash
# Open: Nios II Command Shell (Start Menu → Intel FPGA → Nios II Command Shell)

# Test 1: Detecteer JTAG hardware
jtagconfig

# Verwachte output:
# 1) USB-Blaster [USB-0]
#   02E660DD   5CSEMA5(.|ES)/5CSXFC6D6

# Test 2: Scan JTAG chain
jtagd

# Test 3: Check NIOS II systeem
nios2-terminal

# Als dit werkt, zie je: "nios2-terminal: connected to hardware target using JTAG UART"
# Druk Ctrl+C om te stoppen
```

---

## Stap 4: Check USB Blaster Driver (Windows)

### Verificatie:
1. Open "Device Manager" (Apparaatbeheer)
2. Kijk onder "Universal Serial Bus controllers"
3. Zoek naar "Altera USB-Blaster" of "Intel USB-Blaster"

### Als driver niet gevonden:
1. Download "Quartus Prime Programmer and Tools" standalone
2. Of: Installeer driver handmatig:
   - Ga naar: `C:\intelFPGA_lite\18.1\quartus\drivers\usb-blaster`
   - Device Manager → Update Driver → Browse → Selecteer deze folder

---

## Stap 5: BSP Configuratie Check

### In Eclipse:

1. Right-click op `hello_world_bsp` project
2. **Nios II → BSP Editor...**
3. Check deze instellingen:
   - **Main** tab:
     - `hal.sys_clk_timer` = `timer_0`
     - `hal.timestamp_timer` = `timer_0`
     - `hal.stdin` = `jtag_uart_0`
     - `hal.stdout` = `jtag_uart_0`
   - **Linker Script** tab:
     - `.text` = `onchip_memory.s1`
     - `.rodata` = `onchip_memory.s1`
     - `.rwdata` = `onchip_memory.s1`
     - `.bss` = `onchip_memory.s1`
     - `.heap` = `onchip_memory.s1`
     - `.stack` = `onchip_memory.s1`
4. Klik **"Generate"**
5. Klik **"Exit"**
6. Right-click op `hello_world` → **Build Project**

---

## Stap 6: System ID Verificatie

### Probleem:
Als je de Platform Designer wijzigt en opnieuw compileert, krijgt de hardware een nieuwe System ID. De oude BSP heeft nog de oude ID.

### Oplossing:

```bash
# In Nios II Command Shell:

cd C:\Users\mitch\Documents\GitHub\CSC10\eindopdracht\software\hello_world_bsp

# Regenerate BSP met huidige hardware
nios2-bsp-generate-files --bsp-dir . --settings settings.bsp
```

### Of in Eclipse:
1. Right-click `hello_world_bsp`
2. **Nios II → Generate BSP**

---

## Stap 7: Run Configuration Check

### In Eclipse:

1. Run → **Run Configurations...**
2. Selecteer je "Hello_world" configuratie (of maak nieuwe aan)
3. **Target Connection** tab:
   - System ID: `0x????????` (auto-detect)
   - Processor: `nios2_gen2_0` (moet matchen met Platform Designer)
   - Terminal: `jtag_uart_0`
   - Enable "Ignore mismatched system ID"
4. **Project** tab:
   - Project name: `hello_world`
   - ELF file: `hello_world.elf`
5. Klik **"Apply"**

---

## Stap 8: Volledige Reset Procedure

Als alles nog niet werkt:

```bash
# In Nios II Command Shell:

# Stop alle JTAG servers
jtagconfig --stop

# Herstart JTAG daemon
jtagconfig --start

# Test opnieuw
jtagconfig
```

### In Eclipse:
1. Close Eclipse
2. Herstart Eclipse
3. Clean all projects: Project → Clean → Clean all
4. Build all: Project → Build All
5. Programmeer FPGA opnieuw met .sof
6. Run → Run (probeer opnieuw)

---

## Common Issues & Solutions

### Issue 1: "No JTAG hardware available"
**Oplossing**: 
- Check USB kabel
- Herstart board
- Installeer/update USB-Blaster driver

### Issue 2: "System ID mismatch"
**Oplossing**:
- Regenerate BSP (zie Stap 6)
- Of: Enable "Ignore mismatched system ID" in Run Configuration

### Issue 3: "Cannot download ELF to target"
**Oplossing**:
- FPGA niet geprogrammeerd → Programmeer met .sof
- Verkeerd processor name → Check Platform Designer (nios2_gen2_0)

### Issue 4: "No response from target"
**Oplossing**:
- FPGA mogelijk vastgelopen → Power cycle board (uit/aan)
- Programmeer FPGA opnieuw

---

## Debug Output Via JTAG UART

### Terminal openen:

**Optie A - Eclipse Console:**
- Run → Run → (applicatie start)
- Output verschijnt automatisch in "Nios II IDE Console"

**Optie B - Standalone Terminal:**
```bash
# In Nios II Command Shell:
nios2-terminal

# Hou dit venster open tijdens debugging
```

---

## Verification Checklist

Controleer deze punten voordat je "Run" klikt:

- [ ] Quartus compilatie succesvol (Full Compilation was successful)
- [ ] FPGA geprogrammeerd met .sof file (via Programmer)
- [ ] `jtagconfig` toont USB-Blaster en FPGA
- [ ] BSP gegenereerd (geen errors in Eclipse)
- [ ] Project gebuild zonder errors (hello_world.elf bestaat)
- [ ] Run Configuration ingesteld met juiste processor naam
- [ ] JTAG UART console zichtbaar in Eclipse

---

## Quick Test Flow

1. **Quartus**: Compile → Program FPGA (.sof)
2. **Command Shell**: `jtagconfig` (test JTAG)
3. **Eclipse**: Build project
4. **Eclipse**: Run → Run
5. **Check Console**: "Hello from Nios II!" verschijnt

Als dit lukt, is je setup correct! ✅
