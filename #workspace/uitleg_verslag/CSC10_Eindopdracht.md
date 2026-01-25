# CSC10 Eindopdracht

## Samenvatting

Dit verslag beschrijft de implementatie van een 32x32 RGB LED-matrix die wordt aangestuurd door een FPGA op een DE1-SoC bordje. De opdracht is opgesplitst in twee delen: de eerste deelopdracht richt zich op het aansturen van de matrix met een Nios II softcore-processor, terwijl de tweede deelopdracht gebruikmaakt van de hard processor (HPS) van de Cyclone V SoC FPGA om de matrix aan te sturen onder een Linux-omgeving.

## Inhoudsopgave

## Inleiding

### Contextopdracht

### Aanpak

Voor de aanpak is begonnen met het definiëren van de pinnen die de verbinding tussen de matrix en de FPGA mogelijk maken. Daarna is een ModelSim-project aangemaakt waarin de VHDL-code wordt gesimuleerd om te controleren of de LED-matrix correct wordt aangestuurd. Vervolgens is in Platform Designer een eigen component aangemaakt die de registers bevat om de LED-matrix aan te sturen. Daarna is een top-leveldesign gemaakt waarin alle koppelingen worden aangebracht, zodat de FPGA de LED-matrix kan aansturen. Hierna is een Nios II-project aangemaakt om via de BSP de FPGA in C-code aan te sturen.

Voor de hardcoreversie is begonnen met het kopiëren van de softcore-projectbestanden. Vervolgens is in Platform Designer de HPS geconfigureerd om toegang te krijgen tot de registers van de matrix. Daarna is het top-leveldesign aangepast om de HPS te integreren met wat in de softcore-implementatie is aangemaakt. Vervolgens is alles geconfigureerd en gecompileerd, is alles overgezet naar de microSD-kaart en is begonnen met het schrijven van de userspace-applicatie, zoals bij de softcoreversie.

## Deelopdracht 1 (Hardware)

### ModelSim-simulatie

Voordat er werd begonnen met de hardware-implementatie is een ModelSim-project aangemaakt om de VHDL-code te simuleren. Dit is gedaan om te controleren of de LED-matrix correct wordt aangestuurd door de VHDL-code. De testbench bestaat uit het genereren van een kloksignaal en het instellen van de reset. Daarna wordt er een eenvoudige patroon gegenereerd dat over de matrix wordt weergegeven. Hieronder is een screenshot te zien van de simulatie in ModelSim:
![ModelSim-simulatie](images/modelsim_simulatie.png)

#### Werking 32x32 RGB LED-matrix

De PCB bevat 12 LED-driverchips. Je kunt ze zien als shiftregisters zoals een 74HC595, alleen hebben ze 16 uitgangen en sturen ze met constante stroom. Samen leveren ze 12 x 16 = 192 uitgangen. Dat is handig, want één scanstap van de matrix gebruikt precies 192 signalen: 64 pixels tegelijk, elk met R, G en B (64 x 3 = 192).

Met de adreslijnen A, B en C kiest de controller welke van de 8 secties op dat moment actief is. Zodra die selectie is gemaakt, wordt 192 bits (24 bytes) aan beelddata uitgeklokt en met de latch vastgezet. Daarna gaat de controller door naar de volgende sectie, tot alle 8 secties zijn geweest, en begint de cyclus opnieuw bij sectie 0.

### Hardware

### VHDL-code

### Platform Designer

### Top-leveldesign

### Nios II-software

## Deelopdracht 2 (Hardcore)

Nadat we de softcore-implementatie hebben voltooid, gaan we de hardcore HPS (Hard Processor System) van de Cyclone V SoC FPGA gebruiken om de 32x32 LED-matrix aan te sturen. Dit vereist het opzetten van een Linux-omgeving op de HPS. Voordat we begonnen aan dit deel is het werkende softcore-projectbestand gekopieerd, zodat de benodigde bestanden beschikbaar waren voor de hardcore-implementatie. In principe hoeft dan alleen de processor te worden vervangen: van de Nios naar de hard processor.

### Platform Designer-configuratie

Wat als eerste gedaan moest worden, is het omzetten van de schakelaars op de achterkant, zodat Linux kan booten. Vervolgens hebben we in Platform Designer de HPS geconfigureerd met de preset "DE1-SoC bordje CSC10", die is meegeleverd bij stap 1 van week 3. Hierbij moest ik er ook op letten dat de "device family" op Cyclone V SoC stond en de "Device" op "5CSEMA5F31C6".

Daarna is de HPS-to-FPGA Lightweight Bridge toegevoegd en is de FPGA-to-HPS interrupt aangezet. Hetgeen is gebleven is de Matrix32 LED-controllercomponent die bij de softcore-implementatie is aangemaakt, en de pio_keys-component die de knoppen op het bord mogelijk maakt.

Vervolgens zijn alle stappen uit opdracht 3.9 tot en met 3.17 van de weekopdrachten doorlopen om de HPS zo te configureren dat deze toegang heeft tot de registers van de LED-controller. Hieronder staat een afbeelding van de Platform Designer-configuratie:
![Platform Designer HPS-configuratie](images/platform_designer_hps_config.png)

Hierna konden we in Platform Designer alles laten genereren en konden we de "Instantiation Template" gebruiken om het top-level design aan te passen.

### Hardcore Linux-setup

Vervolgens moest de Linux-omgeving op de HPS worden opgezet. Dit is gedaan door de stappen uit week 3 te volgen, waarbij de juiste rbf bestand en device tree blobs (DTB) wordt gebruikt om de FPGA te configureren bij het opstarten van Linux.

## Conclusie

De resultaten van zowel de softcore- als de hardcore-implementatie zijn grotendeels succesvol. In beide gevallen is de 32x32 RGB LED-matrix correct aangestuurd en worden de gewenste patronen weergegeven. Alleen KEY0 werkte niet, omdat deze in de configuratie was gekoppeld aan de reset.

De softcore-implementatie vormde een goede basis om de werking van de matrix te doorgronden. Uiteindelijk is het doel bereikt: een functionerende 32x32 RGB LED-matrix die kan worden aangestuurd via zowel een Nios II-processor als de HPS van de Cyclone V SoC FPGA.

In de zipmap is een video toegevoegd waarin zowel de softcore- als de hardcore-implementatie in actie te zien is.
