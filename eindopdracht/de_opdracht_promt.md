# Hoofdopdracht

De 32x32 RGB led scherm is gekocht vanuit Kiwi Electronics. Deze scherm en de knoppen op de FPGA worden gebruikt om voor geprogrammeerde blokken.

Op de FPGA wordt de aansturing van de scherm en ontvangst van de knoppen geregeld. De NIOS-koppeling krijgt als inputs van de FPGA de knoppen (hoog/laag) en verstuurt een figuur van wat verstuurt moet worden. In de register naar de scherm wordt 3 bytes voor rood, groen en blauw.

Voor het dataverwerking wordt een vergelijking gemaakt tussen Linux en RTOS. De verschillende voordelen en nadelen van elk implementatie wordt bekeken en een besluit gemaakt welke beter is.

## Voorbeeld

Een blauwe vierkant kan met 4 keys (Key0 t/m key3) omhoog, omlaag, links en rechts bewogen worden. De ingedrukte knop wordt via de NIOS-koppeling gestuurd naar een RTOS of Linux. In de RTOS/Linux wordt de volgende plaats van de blokje bepaald en doorgestuurd naar de FPGA. De FPGA ontvangt wat op het beeldscherm moet komen en zend het ook daadwerkelijk uit naar het scherm toe.

## Toevoegingen

### Kleuren

Er zijn nog 10 switches aanwezig op de FPGA. 9 van de switches worden gebruikt om de kleur van de figuur aan te passen. Elke drie switches geven een waarde voor rood, groen of blauw waarbij 0 (alle switches hoog, wegens active low) een waarde stuurt van 1 (om nog zichtbaar te maken op het scherm) en bij 3 een waarde van 255 (felste voor het kleur).

### Basis Tetris

Wanneer alles werkt en tijd over is, wordt extra software in de RTOS/Linux gestopt om een (heel simpel) Tetris spel te maken. I.p.v. een voor gedefinieerde figuren worden 7 standaard figuren met de juiste kleuren random gekozen. Deze figuren worden bestuurd door de eerder benoemde key's: 2 knoppen voor links en rechts en 2 knoppen voor de twee rotaties (met de klok mee en tegen de klok in). Wanneer één of meerdere lijnen vol zitten, worden de volle lijnen weggehaald. De spel is verloren wanneer een figuur de top bereikt.

Ten slotte moet de zwaartekracht geïmplementeerd worden. Als gebruiker kan je dan niet meer op of neer bewegen, maar het figuur zakt langzaam naar de bodem.

### Muziek

Er is een Aux-poort aanwezig op de FPGA. Wanneer tijd over is EN de vorige toevoeging voltooid is, is het ook leuk als het de bekende deuntje van Tetris af kan spelen. De audio wordt volledig gedaan in de software (Linux of RTOS) en verstuurd naar de Aux-kabel. Oortjes of speaker (al dan niet met een versterker ervoor) kan dan gebruikt worden om de deuntje te horen.

## Afbakening

Er wordt verwacht dat alleen 1 knop tegelijk ingedrukt zal worden. 2 knoppen tegelijk resulteert dus niet in een diagonale beweging.

Voor de toevoegingen wordt de punten berekening buiten beschouwing gelaten. Dit is iets te complex om toe te voegen voor al een vrij moeilijk opdracht.

In hetzelfde gedachte worden T-spins ook niet geïmplementeerd. Dit detecteren is nog te doen, maar het berust op de zogenaamde Super Rotation System (SRS) en dat is veel meer dan wat nu gedaan zal worden.

Bij Tetris zijn er verschillende levels waarbij de zwaartekracht anders is (vaak zwaarder waardoor het sneller valt). Dit is ook iets te veel voor dit project: er wordt maar 1 vaste zwaartekracht aangehouden (en dus 1 valsnelheid).

## Werking RGB Matrix

De RGB-ledjes in de matrix kunnen niet allemaal tegelijkertijd aangestuurd worden en dit zou veel stroom vereisten. De matrix is verdeeld in 8 afwisselende secties/strips dus je kan maar twee strips (23x2 RGB-leds = 64 RGB leds)tegelijkertijd aansturen. Op de printplaat van de matrix zitten 12 LED-driverchips die 16 output pins heeft om een constante stroom als output te geven. 16 output * 12 chips = 192 LED's die tegelijk aangestuurd kunnen worden. De FGPA selecteert welk gedeelte momenteel getekend moet worden. Dit wordt gedaan doormiddel van A, B en C adres pinnen – 3 bits kunnen 8 waarden hebben. Zodra het adres is ingesteld klokt de FGPA 192 bits aan data uit en slaat deze op. Vervolgens verhoogt hij het adres en klokt hij opnieuw 192 bits uit totdat adres 7 bereikt is Dan zet hij het adres terug naar 0. Wat betreft de snelheid die de matrix aan kan is 50MHz volgens adafruit een goede snelheid om de matrix aan te sturen.

## Links

- [32x32 RGB LED Matrix Paneel - 4mm pitch | Kiwi Electronics](https://www.kiwi-electronics.com/nl/32x32-rgb-led-matrix-paneel-4mm-pitch-2836?search=led%20matrix)
- [Connecting with Jumper Wires | RGB LED Matrix Basics | Adafruit Learning System](https://learn.adafruit.com/32x16-32x32-rgb-led-matrix/connecting-with-jumper-wires)
