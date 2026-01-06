x# Custom RGB Framebuffer Component in Platform Designer

## Overzicht

Deze guide legt stap-voor-stap uit hoe je het custom `rgb_framebuffer` VHDL component toevoegt aan Platform Designer (Qsys) voor je Tetris project.

---

## Vereisten

- Quartus Prime geïnstalleerd
- `rgb_framebuffer.vhdl` bestand in je project directory
- Basis kennis van Platform Designer

---

## Stap 1: Voeg VHDL Bestand toe aan Project

1. Open je Quartus project
2. **Project → Add/Remove Files in Project**
3. Klik op **...** (browse)
4. Selecteer `rgb_framebuffer.vhdl`
5. Klik **OK**

**Verificatie:** Het bestand moet nu zichtbaar zijn in de **Files** tab van Project Navigator.

---

## Stap 2: Open Component Editor

1. Open Platform Designer: **Tools → Platform Designer**
2. In Platform Designer menu: **File → New Component...**
3. Of gebruik: **Tools → New Component...**

De **Component Editor** window opent.

---

## Stap 3: Component Type Configureren

### Tab: Component Type

Vul de volgende velden in:

| Veld | Waarde |
|------|--------|
| **Name** | `rgb_framebuffer` |
| **Display Name** | `RGB Framebuffer Controller` |
| **Version** | `1.0` |
| **Description** | `32x32 RGB LED Matrix Framebuffer Controller met Avalon-MM interface` |
| **Group** | `Custom Components` of laat leeg |

**Belangrijk:** De **Name** moet exact overeenkomen met de entity name in je VHDL!

---

## Stap 4: HDL Files Toevoegen

### Tab: Files

1. Klik op **Add File...**
2. Selecteer `rgb_framebuffer.vhdl`
3. **File Type:** Zorg dat het `VHDL` is (automatisch gedetecteerd)
4. **Top Level File:** Vink aan ✅
5. Klik **OK**

**Verificatie:** Je VHDL bestand staat nu in de lijst met een ✅ bij "Top-level".

---

## Stap 5: Analyze HDL Files

1. In de **Files** tab, klik op **Analyze Synthesis Files**
2. Wacht tot analyse compleet is (groen vinkje verschijnt)
3. **Belangrijk:** Als er errors zijn:
   - Check of alle library declaraties correct zijn
   - Verifieer dat `IEEE.numeric_std.all` aanwezig is
   - Check syntax errors in VHDL

**Output:** Je ziet nu alle ports uit je entity in de interface sectie.

---

## Stap 6: Signals & Interfaces Configureren

### Tab: Signals & Interfaces

Na analyse zie je automatisch alle ports. We gaan deze nu groeperen in interfaces.

#### 6.1 Clock Interface

1. Zoek de `clk` signal in de lijst
2. Rechtsklik op `clk` → **Add Interface...**
3. Configureer:
   - **Interface Type:** `Clock Input` (clock_sink)
   - **Interface Name:** `clock_sink`
   - **Signal Type:** `clk`
4. Klik **Finish**

#### 6.2 Reset Interface

1. Zoek de `reset` signal
2. Rechtsklik op `reset` → **Add Interface...**
3. Configureer:
   - **Interface Type:** `Reset Input` (reset_sink)
   - **Interface Name:** `reset_sink`
   - **Signal Type:** `reset`
   - **Reset Polarity:** **Active High** (omdat onze VHDL `reset = '1'` gebruikt)
   - **Associated Clock:** `clock_sink`
4. Klik **Finish**

**Let op:** Controleer je VHDL! Als je `reset_n` (active low) gebruikt, pas de polarity aan.

#### 6.3 Avalon-MM Slave Interface

1. Selecteer alle Avalon-MM signals:
   - `avs_address`
   - `avs_read`
   - `avs_write`
   - `avs_writedata`
   - `avs_readdata`
   - `avs_waitrequest`

2. Rechtsklik op een van de geselecteerde signals → **Add Interface...**
3. Configureer:
   - **Interface Type:** `Avalon Memory Mapped Slave` (avalon_slave)
   - **Interface Name:** `avalon_slave`
   - **Associated Clock:** `clock_sink`
   - **Associated Reset:** `reset_sink`

4. Map de signals:

| Signal Port | Signal Type |
|-------------|-------------|
| `avs_address` | `address` |
| `avs_read` | `read` |
| `avs_write` | `write` |
| `avs_writedata` | `writedata` |
| `avs_readdata` | `readdata` |
| `avs_waitrequest` | `waitrequest` |

5. Klik **Finish**

#### 6.4 Avalon-MM Slave Properties

1. Selecteer de **avalon_slave** interface in de lijst
2. Klik op **Avalon-MM Settings** (of dubbelklik op interface)
3. Configureer:

**Timing:**
- **Setup Time:** `0`
- **Read Wait Time:** `1`
- **Write Wait Time:** `0`
- **Hold Time:** `0`

**Address:**
- **Address Width:** `10` (voor 1024 adressen = 32×32 pixels)
- **Data Width:** `32` (32-bit RGB + padding)

**Transfer Types:**
- ✅ **Read**
- ✅ **Write**
- ❌ **Read Latency:** `0` (of `1` als je pipeline hebt)

**Address Alignment:**
- **Address Units:** `Symbols` (bytes)
- **Symbols Per Word:** `4` (32-bit = 4 bytes)

4. Klik **OK**

#### 6.5 RGB Matrix Conduit Interface (GPIO Output)

Nu maken we een conduit interface voor de RGB matrix pinnen die naar GPIO gaan.

1. Selecteer alle matrix output signals:
   - `matrix_r1`
   - `matrix_g1`
   - `matrix_b1`
   - `matrix_r2`
   - `matrix_g2`
   - `matrix_b2`
   - `matrix_addr_a`
   - `matrix_addr_b`
   - `matrix_addr_c`
   - `matrix_clk`
   - `matrix_lat`
   - `matrix_oe_n`

2. Rechtsklik → **Add Interface...**
3. Configureer:
   - **Interface Type:** `Conduit` (conduit_end)
   - **Interface Name:** `rgb_matrix_conduit`
   - **Associated Clock:** `clock_sink`
   - **Associated Reset:** `reset_sink`

4. Voor **elk** signal, stel de **Conduit Signal Type** in:

| Signal Port | Conduit Signal Type | Direction |
|-------------|---------------------|-----------|
| `matrix_r1` | `r1` | Output |
| `matrix_g1` | `g1` | Output |
| `matrix_b1` | `b1` | Output |
| `matrix_r2` | `r2` | Output |
| `matrix_g2` | `g2` | Output |
| `matrix_b2` | `b2` | Output |
| `matrix_addr_a` | `addr_a` | Output |
| `matrix_addr_b` | `addr_b` | Output |
| `matrix_addr_c` | `addr_c` | Output |
| `matrix_clk` | `clk_out` | Output |
| `matrix_lat` | `lat` | Output |
| `matrix_oe_n` | `oe_n` | Output |

5. Klik **Finish**

**Belangrijk:** De "Conduit Signal Type" namen (r1, g1, etc.) zijn wat je later ziet in je top-level VHDL!

---

## Stap 7: Interfaces Overzicht Controleren

Na alle configuratie heb je nu **4 interfaces**:

1. ✅ **clock_sink** (Clock Input)
   - `clk`

2. ✅ **reset_sink** (Reset Input)
   - `reset`

3. ✅ **avalon_slave** (Avalon-MM Slave)
   - `avs_address[9:0]`
   - `avs_read`
   - `avs_write`
   - `avs_writedata[31:0]`
   - `avs_readdata[31:0]`
   - `avs_waitrequest`

4. ✅ **rgb_matrix_conduit** (Conduit - GPIO)
   - `matrix_r1`, `matrix_g1`, `matrix_b1`
   - `matrix_r2`, `matrix_g2`, `matrix_b2`
   - `matrix_addr_a`, `matrix_addr_b`, `matrix_addr_c`
   - `matrix_clk`, `matrix_lat`, `matrix_oe_n`

---

## Stap 8: Parameters (Optioneel)

Je kunt generics/parameters toevoegen als je je VHDL flexibel wilt maken (bijv. verschillende resoluties).

Voor nu: **Skip deze stap** (geen parameters nodig).

---

## Stap 9: Component Opslaan

1. Klik op **Finish** (rechtsboven in Component Editor)
2. Kies een locatie om je component op te slaan:
   - Aanbevolen: `<project_dir>/ip/rgb_framebuffer/`
3. Component wordt opgeslagen als `rgb_framebuffer_hw.tcl`

**Belangrijk:** Onthoud deze directory! Je moet het toevoegen aan Platform Designer's IP search path.

---

## Stap 10: Component Toevoegen aan IP Catalog

### Methode 1: Via Search Paths (Aanbevolen)

1. In Platform Designer: **Tools → Options**
2. Tab: **IP Search Path**
3. Klik **+** (Add)
4. Browse naar de directory met je `rgb_framebuffer_hw.tcl`
   - Bijvoorbeeld: `C:/Users/mitch/Documents/GitHub/CSC10/eindopdracht/ip/rgb_framebuffer/`
5. Klik **OK**
6. **Tools → Refresh Library**

### Methode 2: Direct Toevoegen

1. In Platform Designer: **IP Catalog** (linker panel)
2. Rechtsklik in lege ruimte → **Refresh IP Catalog**
3. Je component zou nu moeten verschijnen onder:
   - **Project** (als het in project directory staat)
   - Of **Custom Components** (als je dat als group hebt ingesteld)

---

## Stap 11: Component Instantiëren in je Systeem

Nu kun je je custom component gebruiken!

1. In Platform Designer IP Catalog, zoek naar `rgb_framebuffer`
2. Dubbelklik of sleep het naar je systeem
3. Geef het een **Instance Name:** `rgb_framebuffer_0`
4. Klik **Finish**

---

## Stap 12: Verbindingen Maken

### Clock & Reset

| Connection | From | To |
|------------|------|-----|
| Clock | `clk_0.clk` | `rgb_framebuffer_0.clock_sink` |
| Reset | `clk_0.clk_reset` | `rgb_framebuffer_0.reset_sink` |

### Avalon-MM Interconnect

| Connection | From | To |
|------------|------|-----|
| Data Master | `nios2_gen2_0.data_master` | `rgb_framebuffer_0.avalon_slave` |

**Auto-assign Base Address:**
1. **System → Assign Base Addresses**
2. Controleer dat `rgb_framebuffer_0.avalon_slave` een uniek adres heeft (bijv. `0x00041000`)

### Conduit Export (naar Top-Level)

De `rgb_matrix_conduit` moet geëxporteerd worden naar je top-level VHDL:

1. Zoek `rgb_framebuffer_0` in je systeem
2. Onder **Export** kolom bij `rgb_matrix_conduit`, dubbelklik
3. Geef een export naam: `rgb_matrix_conduit`
4. Klik elders om te bevestigen

**Dit zorgt ervoor dat de pinnen beschikbaar zijn in je top-level entity!**

---

## Stap 13: System Genereren

1. **Generate → Generate HDL...**
2. **Simulation:** `None` (tenzij je simulatie wilt)
3. **Synthesis:** `VHDL` ✅
4. **Output Directory:** Laat default (meestal `<system_name>/synthesis/`)
5. Klik **Generate**

Wacht tot generatie compleet is (groene balk).

---

## Stap 14: Component in Top-Level VHDL Gebruiken

Na generatie krijg je een component declaratie. Gebruik deze in je top-level VHDL:

```vhdl
component nios_system is
    port (
        clk_clk                    : in  std_logic;
        reset_reset_n              : in  std_logic;
        
        -- Andere interfaces...
        
        -- RGB Matrix Conduit (geëxporteerd)
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
```

**Let op:** De port namen zijn `<export_name>_<signal_type>`.

---

## Troubleshooting

### Error: "Cannot find VHDL file"

**Oplossing:**
- Zorg dat `rgb_framebuffer.vhdl` in je Quartus project zit
- Verifieer het pad in Component Editor → Files tab

### Error: "Signal not assigned to interface"

**Oplossing:**
- Ga terug naar Component Editor
- Open je component: **Tools → Edit Component...**
- Controleer de Signals & Interfaces tab
- Zorg dat alle signals een interface hebben

### Error: "Address conflict"

**Oplossing:**
- **System → Assign Base Addresses**
- Verander base address van `rgb_framebuffer_0` handmatig

### Warning: "Reset polarity mismatch"

**Oplossing:**
- Check je VHDL: `reset = '1'` (active high) of `reset_n = '1'` (active low)
- Pas reset interface configuratie aan in Component Editor

### Component niet zichtbaar in IP Catalog

**Oplossing:**
1. **Tools → Options → IP Search Path**
2. Voeg de juiste directory toe
3. **Tools → Refresh IP Catalog**
4. Herstart Platform Designer indien nodig

### Synthesis errors na generatie

**Oplossing:**
- Controleer of alle library declaraties kloppen in VHDL
- Verifieer dat je `IEEE.numeric_std.all` gebruikt (niet `std_logic_arith`)
- Check for syntax errors met **Processing → Analyze Current File** in Quartus

---

## Verificatie Checklist

Na implementatie, controleer:

- ✅ Component verschijnt in IP Catalog
- ✅ Component kan toegevoegd worden aan systeem
- ✅ Clock/Reset zijn correct verbonden
- ✅ Avalon-MM slave heeft base address
- ✅ Conduit is geëxporteerd naar top-level
- ✅ System genereert zonder errors
- ✅ Top-level VHDL compileert zonder errors
- ✅ Pin assignments kloppen (GPIO1 pins)

---

## Volgende Stappen

1. ✅ Custom component gemaakt en toegevoegd
2. ⏭️ Voeg overige componenten toe (NIOS II, PIO's, Timer, etc.)
3. ⏭️ Maak alle verbindingen
4. ⏭️ Genereer systeem
5. ⏭️ Integreer in top-level VHDL (`eindopdracht_Testris.vhd`)
6. ⏭️ Compileer volledig project
7. ⏭️ Programmeer FPGA

---

## Extra: Component Updaten

Als je VHDL wijzigt:

1. Open Component Editor: **Tools → Edit Component...**
2. Selecteer je component uit de lijst
3. Tab **Files** → **Analyze Synthesis Files**
4. Controleer/update interfaces indien nodig
5. **Finish** om op te slaan
6. In Platform Designer: **Tools → Refresh Library**
7. **System → Upgrade IP Variants** (als je component al in systeem zit)

---

## Referenties

- [Intel Platform Designer User Guide](https://www.intel.com/content/www/us/en/docs/programmable/683364/current/introduction.html)
- [Creating Custom Components](https://www.intel.com/content/www/us/en/docs/programmable/683364/current/creating-a-custom-component.html)
- [Avalon Interface Specifications](https://www.intel.com/content/www/us/en/docs/programmable/683091/current/introduction-to-the-interface-specifications.html)

---

**Succes met je custom component!** 🎮✨

Voor verdere hulp, zie ook de hoofdguide: [PROJECT_SETUP_GUIDE.md](PROJECT_SETUP_GUIDE.md)
