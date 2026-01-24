# Opdracht

## Doelstelling

Ik wil modelsim gebruiken om een VHDL ontwerp te simuleren voor de DE1-SoC bord. Ik wil in modelsim een testbench maken die mijn VHDL code test en de resultaten visualiseert. en daarbij wil de 32x32 matrix testen met modelsim.

bord: DE1-SoC bord (Altera Cyclone V SoC 5CSEMA5F31C6N)



# vraag 

Kan je me stap voor stap uitleggen hoe ik modelsim kan gebruiken om mijn VHDL ontwerp te simuleren voor het DE1-SoC bord, inclusief het maken van een testbench en het testen van een 32x32 LED matrix?Natuurlijk! Hier is een stapsgewijze handleiding om ModelSim te gebruiken voor het simuleren van je VHDL ontwerp voor het DE1-SoC bord, inclusief het maken van een testbench en het testen van een 32x32 LED matrix.

# uitleg werking

First thing to notice is that there are 512 RGB LEDs in a 16x32 matrix. Like pretty much every matrix out there, you can't drive all 512 at once. One reason is that would require a lot of current, another reason is that it would be really expensive to have so many pins. Instead, the matrix is divided into 8 interleaved sections/strips. The first section is the 1st 'line' and the 9th 'line' (32 x 2 RGB LEDs = 64 RGB LEDs), the second is the 2nd and 10th line, etc until the last section which is the 8th and 16th line. You might be asking, why are the lines paired this way? wouldnt it be nicer to have the first section be the 1st and 2nd line, then 3rd and 4th, until the 15th and 16th? The reason they do it this way is so that the lines are interleaved and look better when refreshed, otherwise we'd see the stripes more clearly.

So, on the PCB are 12 LED driver chips. These are like 74HC595s but they have 16 outputs and they are constant current. 16 outputs * 12 chips = 192 LEDs that can be controlled at once, and 64 * 3 (R G and B) = 192. So now the design comes together: You have 192 outputs that can control one line at a time, with each of 192 R, G and B LEDs either on or off. The controller (say an FPGA or microcontroller) selects which section to currently draw (using A, B, and C address pins - 3 bits can have 8 values). Once the address is set, the controller clocks out 192 bits of data (24 bytes) and latches it. Then it increments the address and clocks out another 192 bits, etc until it gets to address #7, then it sets the address back to #0.



# pinnen## LED Matrix 32x32 - Eenvoudig gebruik met hardware scanning

- R1 = (PIN_AB17)_GPIO_1[0]
- G1 = (PIN_AA21)_GPIO_1[1]
- B1 = (PIN_AB21)_GPIO_1[2]
- R2 = (PIN_AD24)_GPIO_1[4]
- G2 = (PIN_AE23)_GPIO_1[5]
- B2 = (PIN_AE24)_GPIO_1[6]
- A  = (PIN_AF26)_GPIO_1[8]  // Row address bit 0
- B  = (PIN_AG25)_GPIO_1[9]  // Row address bit 1
- C  = (PIN_AG26)_GPIO_1[10] // Row address bit 2
- D  = (PIN_AH24)_GPIO_1[11] // Row address bit 3
- CLK= (PIN_AH27)_GPIO_1[12] // Shift clock
- LAT= (PIN_AJ27)_GPIO_1[13] // Latch
- OE = (PIN_AK29)_GPIO_1[14] // Output enable (active low)


# Keys pinnen

- KEY0 = AA14
- KEY1 = AA15
- KEY2 = W15
- KEY3 = Y16
