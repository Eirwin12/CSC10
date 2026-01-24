# KEY/LED Linux Kernel Driver - Gebruikshandleiding

## Overzicht

Deze driver implementeert een character device voor de DE1-SoC KEY/LED interface met volledige interrupt support en asynchrone I/O.

## Hardware Vereisten

- **Platform Designer configuratie:**
  - LED PIO: 4-bit output @ offset 0x00000000
  - KEY PIO: 4-bit input @ offset 0x00000010
  - Edge capture enabled op KEY PIO
  - Interrupt verbonden met f2h_irq_p0[0] (IRQ 72)

## Bestanden

- `key_led_driver.c` - Linux kernel module
- `Makefile` - Build configuratie
- `test_key_led.c` - Simpel blocking read test
- `test_async_key.c` - Asynchrone I/O test (SIGIO)
- `test_poll.c` - Non-blocking poll() test

## Compileren

### Op DE1-SoC (native):
```bash
make
```

### Cross-compilatie (vanaf development PC):
```bash
# Pas Makefile aan:
# - Zet ARCH = arm
# - Zet CROSS_COMPILE = arm-linux-gnueabihf-
# - Zet KDIR naar je kernel source directory

make
```

### Test programma's compileren:
```bash
make test
```

## Installeren en Gebruiken

### 1. Kopieer bestanden naar DE1-SoC
```bash
scp key_led_driver.ko test_* root@192.168.1.10:/root/
```

### 2. Load kernel module
```bash
sudo insmod key_led_driver.ko
```

### 3. Controleer of module geladen is
```bash
lsmod | grep key_led
dmesg | tail
```

Je zou moeten zien:
```
KEY_LED: Driver loaded successfully (Major: xxx, IRQ: 72)
KEY_LED: Device node: /dev/key_led
```

### 4. Controleer device node
```bash
ls -l /dev/key_led
```

Indien niet aanwezig, maak handmatig aan:
```bash
sudo mknod /dev/key_led c <major_number> 0
sudo chmod 666 /dev/key_led
```

### 5. Run test programma's

#### Test 1: Blocking Read
```bash
sudo ./test_key_led
```
- Druk op KEY0-KEY3 op het board
- Corresponderende LED gaat aan
- Programma print welke key ingedrukt is

#### Test 2: Asynchrone I/O (SIGIO)
```bash
sudo ./test_async_key
```
- Draait in background
- Reageert onmiddellijk op key presses
- Print events asynchroon

#### Test 3: Poll Test
```bash
sudo ./test_poll
```
- Non-blocking I/O met poll()
- Timeout van 1 seconde

## Handmatig LED Control

```bash
# Zet LED0 aan (0x01 = 0b0001)
echo "1" | sudo tee /dev/key_led

# Zet LED0 en LED2 aan (0x05 = 0b0101)
echo "5" | sudo tee /dev/key_led

# Zet alle LEDs aan (0x0F = 0b1111)
echo "15" | sudo tee /dev/key_led

# Alle LEDs uit
echo "0" | sudo tee /dev/key_led
```

## Device Interface

### Read Operatie
- **Blocking read**: Wacht op key interrupt
- Returns 1 byte met key status (bit 0-3 voor KEY0-KEY3)
- Voorbeeld: `0x01` = KEY0 pressed

### Write Operatie
- Schrijf 1 byte naar LEDs
- Accepteert decimal of hex (0x...)
- Alleen bits 0-3 worden gebruikt
- Voorbeeld: `echo "0x0A" > /dev/key_led` zet LED1 en LED3 aan

### Poll/Select Support
- Device ondersteunt `poll()`, `select()`, `epoll()`
- Returns `POLLIN` wanneer key event beschikbaar is

### Async I/O (SIGIO)
- Ondersteunt `fcntl(fd, F_SETFL, FASYNC)`
- Stuurt `SIGIO` signaal bij key interrupt

## Debugging

### Bekijk kernel logs:
```bash
dmesg | tail -20
# of
tail -f /var/log/kern.log
```

### Check interrupt counts:
```bash
cat /proc/interrupts | grep key_led
```

### Module info:
```bash
modinfo key_led_driver.ko
```

## Module verwijderen

```bash
sudo rmmod key_led_driver
```

## Troubleshooting

### Device node bestaat niet
```bash
# Haal major number op uit dmesg
major=$(dmesg | grep "KEY_LED: Driver loaded" | grep -oP 'Major: \K\d+')
sudo mknod /dev/key_led c $major 0
sudo chmod 666 /dev/key_led
```

### IRQ werkt niet
- Controleer Platform Designer: interrupt moet verbonden zijn
- Check IRQ number in code (standaard 72 voor f2h_irq_p0[0])
- Kijk in `/proc/interrupts`

### Permission denied
```bash
sudo chmod 666 /dev/key_led
# of run programma's met sudo
```

### Module laadt niet
- Check kernel versie: `uname -r`
- Module moet gecompileerd zijn voor juiste kernel versie
- Check `dmesg` voor error messages

## Hardware Addresses

De driver gebruikt deze adressen:
- **LW Bridge Base**: 0xFF200000
- **LED PIO**: 0xFF200000 (LW_BASE + 0x00)
- **KEY PIO**: 0xFF200010 (LW_BASE + 0x10)
- **IRQ**: 72 (f2h_irq_p0[0])

**Let op:** Als je in Platform Designer andere offsets gebruikt, pas deze aan in `key_led_driver.c`:
```c
#define LED_PIO_OFFSET      0x00000000  // Pas aan
#define KEY_PIO_OFFSET      0x00000010  // Pas aan
#define KEY_IRQ_NUMBER      72          // Pas aan
```

## Belangrijke Functionaliteit

### Automatische LED Control via Interrupts
- Wanneer KEY wordt ingedrukt, genereert FPGA interrupt
- Kernel interrupt handler leest welke key(s) ingedrukt zijn
- Handler zet automatisch corresponderende LED(s) aan
- Geen user space interventie nodig!

### Character Device
- `/dev/key_led` is normale file
- Kan gelezen/geschreven worden zonder root (met juiste permissions)
- Integreert naadloos in Linux ecosystem

### Edge Capture
- FPGA PIO edge capture register slaat key presses op
- Voorkomt gemiste events
- Wordt gecleared na elke read

## Verder Ontwikkelen

### Debouncing toevoegen
Keys kunnen "bouncen" - meerdere interrupts per press:
```c
// In interrupt handler, voeg delay/timer toe
static unsigned long last_interrupt_time = 0;
unsigned long current_time = jiffies;

if (current_time - last_interrupt_time > HZ/10) {  // 100ms debounce
    // Process interrupt
    last_interrupt_time = current_time;
}
```

### Meerdere readers
Implementeer buffer voor meerdere key events:
```c
#define BUFFER_SIZE 16
static unsigned char key_buffer[BUFFER_SIZE];
static int buffer_head = 0;
static int buffer_tail = 0;
```

### ioctl() toevoegen
Voor configuratie (enable/disable interrupts, etc):
```c
static long device_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
    // Implementeer custom commands
}
```

## Licentie

GPL v2 - vrij te gebruiken en modificeren voor educatieve doeleinden.
