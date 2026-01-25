# Samenvatting


# Inhoudsopgave



# Inleiding

## Contextodpracht

## Aanpak

Voor de aanpak is er begonnen bij het definiëren van de pinnen die de verbinding tussen de matrix en FPGA mogelijk maakt. Daarna is er een modelsim project aangemaakt waarin de VHDL code wordt gesimuleerd om te controleren of de LED matrix correct wordt aangestuurd. Vervolgens is er in Platform Designer de eigen component aangemaakt die de registers bevat om de LED matrix aan te sturen. Vervolgens is er een top level design gemaakt waarin alle kopppelingen worden gemaakt om ervoor te zorgen dat de FPGA de LED matrix kan aansturen. Hierna is er een Nios II project aangemaakt om via de BSP de FPGA in c code aan te sturen. 

Voor de hardcore versie is er begonnen met het kopiëren van de softcore project files. Vervolgens is er in Platform Designer de HPS geconfigureerd om toegang te krijgen tot de registers van de matrix. Daarna is de top level design aangepast om de HPS te intergreren met wat in de softcore is aangemaakt. Vervolgens is alles geconfigureerd en gecompileerd en alles over gezet naar de micro sd kaart en is er begonnen aan het schrijven van de user space applicatie zoals bij de softcore versie. 



# Deelopdracht 1 (Hardware)

## Modelsim simulatie

Voor dat er begonnen werd met de hardware implementatie is er een Modelsim project aangemaakt om de VHDL code te simuleren. Dit om te controleren of de LED matrix correct wordt aangestuurd door de VHDL code. 

### Werking 32x32 RGB LED Matrix



## Hardware

## VHDL code

## Platform Designer

## Top level design

## Nios II software

# Deelodpracht 2 (Hardcore)

Na dat we de softcore implementatie hebben voltooid, gaan we nu de hardcore HPS (Hard Processor System) van de Cyclone V SoC FPGA gebruiken om de Matrix32 LED controller aan te sturen. Dit vereist het opzetten van een Linux-omgeving op de HPS en het ontwikkelen van een kernelmodule om te communiceren met de LED controller. Voordat we bgeonnen waren aan dit deel heb ik de werkende softcore project file gekopieerd om zo de benodigde bestanden te hebben voor de hardcore implementatie.

## Platform Designer Configuratie

Wat als eerst gedaan moest worden is de switches op de achterkant omzetten zodat de linux geboot kan worden. Vervolgens hebben in platform designer de HPS geconfigureerd met de preset "DE1-SoC bordje CSC10" die is meegeleverd bij Stap 1 bij week 3. Hierbij moest ik ook opletten dat de "device family" op Cyclone V SoC stond en de "Device" op "5CSEMA5F31C6".

Daarna is de HPS-to-FPGA Lightweight bridge toegevoeg en is de FPGA-to-HPS interupt aangezet. Het gene wat is gebleven is de Matrix 32 LED controller component die ik bij de softcore implementatie heb gemaakt en de pio_keys component die de knoppen op het bordje mogelijk maakt.

Vervolgens zijn alle stappen die in opdracht 3.9 tot 3.17 van de week opdrachten doorlopen om de HPS te configureren zodat die toegang heeft tot de registers van de LED controller. Hieronder een foto van de platform designer configuratie:
![Platform Designer HPS Configuratie](images/platform_designer_hps_config.png)

Hierna konden we in platform desginer alles laten genereren en konden we de "Instatiation Template" gebruiken om de top level design aan te passen.

## aanpasing top level design

Na dat alles is geconfigureerd in Platform Designer is de top level design aangepast om de HPS te integreren met de Matrix32 LED controller. 

## Hardcore Linux Setup

## User space 

## Kernel Module