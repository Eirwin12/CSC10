# Opdracht

## Doelstelling

KEY0, KEY1, KEY2, KEY3 zijn de drukknoppen op de DE1-SoC bord. Het doel is om zodra een drukknop wordt ingedrukt, de corresponderende LED aan te zetten (LED0, LED1, LED2, LED3). Dus zodra KEY0 aan gaat dan gaat LED0 aan, zodra KEY1 aan gaat dan gaat LED1 aan, enzovoorts.

Dit wordt gerealiseerd door:
- Een Hard Processor System (HPS) te configureren in Platform Designer
- Het systeem via Linux te booten
- De schakeling aan te sturen via Linux
- Een simpele Linux kernel module te schrijven die de FPGA-schakeling kan aansturen en kan reageren op een interrupt afkomstig van de FPGA-schakeling

## Leerdoelen

Na deze opdracht kun je:

- Dual core ARM-Cortex A9 bare metal programmeren
- Een Hard Processor System (HPS) configureren binnen Platform Designer
- Een devicetree genereren voor jouw HPS-systeem om Linux te booten
- Een FPGA-schakeling aansturen vanuit Linux
- Een simpele Linux kernel module schrijven die de FPGA-schakeling kan aansturen en kan reageren op een interrupt afkomstig van de FPGA-schakeling
- Een character device installeren zodat je vanuit user space (zonder superuser rechten) de leds van het board via de FPGA kunt aansturen door naar een (virtueel) bestand te schrijven[^1]
- Een character device ontwikkelen en installeren zodat je vanuit user space de schakelaars van het board via de FPGA kunt inlezen door uit een (virtueel) bestand te lezen
- Een interrupt afkomstig van de schakelaars afhandelen in user space door het implementeren van een character device dat asynchrone I/O ondersteunt



bord: DE1-SoC bord (Altera Cyclone V SoC 5CSEMA5F31C6N)

