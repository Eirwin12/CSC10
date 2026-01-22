/*************************************************************************
* Copyright (c) 2004 Altera Corporation, San Jose, California, USA.      *
* All rights reserved. All use of this software and documentation is     *
* subject to the License Agreement located at the end of this file below.*
**************************************************************************
* Description:                                                           *
* The following is a simple hello world program running MicroC/OS-II.The * 
* purpose of the design is to be a very simple application that just     *
* demonstrates MicroC/OS-II running on NIOS II.The design doesn't account*
* for issues such as checking system call return codes. etc.             *
*                                                                        *
* Requirements:                                                          *
*   -Supported Example Hardware Platforms                                *
*     Standard                                                           *
*     Full Featured                                                      *
*     Low Cost                                                           *
*   -Supported Development Boards                                        *
*     Nios II Development Board, Stratix II Edition                      *
*     Nios Development Board, Stratix Professional Edition               *
*     Nios Development Board, Stratix Edition                            *
*     Nios Development Board, Cyclone Edition                            *
*   -System Library Settings                                             *
*     RTOS Type - MicroC/OS-II                                           *
*     Periodic System Timer                                              *
*   -Know Issues                                                         *
*     If this design is run on the ISS, terminal output will take several*
*     minutes per iteration.                                             *
**************************************************************************/


#include <stdio.h>
#include <stdbool.h>
#include "includes.h"
#include "system.h"

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */

#define TASK1_PRIORITY      1
#define TASK2_PRIORITY      2


bool links_button;
bool rechts_button;
bool boven_button;
bool onder_button;
bool startSysteem;
//handle all the inputs
void input_handler(void* pdata)
{
	volatile int *button_base = (int *) PIO_BUTTONS_BASE;
	volatile int *leds_base = (int *) PIO_LEDS_BASE;
	volatile int *switch_base = (int *) PIO_SWITCHES_BASE;
	int startReset, buttonValues;
	while(1)
	{
		startReset = *switch_base;
		if(!startSysteem)
		{
			//key wordt gebruikt voor starten en resetten
			if (startReset & 0x1) {
			startSysteem = true;
			volatile int* matrixRegister = (int *)LED_MATRIX_0_BASE;
			*matrixRegister = 1;//zet het fpga aan.
			}
		}
		else
		{
			if (startReset & (1<<1))
			{
				startSysteem = false;
				volatile int* matrixRegister = (int *)LED_MATRIX_0_BASE;
				*matrixRegister = 1<<1;//zet het fpga aan.
			}
			else
			{
				buttonValues = * button_base;
				links_button = buttonValues & 1;
				rechts_button = buttonValues & 1<<1;
				boven_button = buttonValues & 1<<2;
				onder_button = buttonValues & 1<<3;
			}
		}
		OSTimeDlyHMSM(0, 0, 1, 0);
	}
}

typedef enum kleuren {
	zwart = 0,
	rood = 0b001,
	groen = 0b010,
	blauw = 0b100,
	//secundaire kleuren (combi van 2 van de 3 kleuren
	magenta,//rood + blauw
	geel, //groen + blauw
	cyaan, //groen + blauw
	wit,
}kleuren_matrix_e;

//eerst testen of de matrix werkt of niet
/*
 * LED_MATRIX_0_BASE
 * register 1: control
 * register 2: red
 * register 3: green
 * register 4: blue
 */

typedef struct square{
	int lengte;
	kleuren_matrix_e kleur;
} vierkant_s;

#define START_INDEX_WIDTH 16
#define START_INDEX_HEIGHT 0

void matrix_handler(void* pdata)
{
	volatile int* matrixRegister = (int *)LED_MATRIX_0_BASE;
	*matrixRegister = 1;//zet het fpga aan.
	kleuren_matrix_e matrixBuf[32][32];
	for(int i=0; i<32; i++){
		for (j=0; i<32; j++){
			matrixBuf[i][j] = zwart;
		}
	}
	vierkant_s figuur = {2, blauw};
	int indexFiguur = START_INDEX;//dit is de linksboven index
	int indexFiguurHeight = START_INDEX_HEIGHT;//dit is de linksboven index
	matrixBuf[0][indexFiguur] = matrixBuf[1][indexFiguur] = blauw;
	matrixBuf[0][indexFiguur+1] = matrixBuf[1][indexFiguur+1] = blauw;

	*(matrixRegister+1) = 0x0;
	*(matrixRegister+2) = matrixBuf[0] & 0b100;
	*(matrixRegister+3) = 0x0;
	*matrixRegister = 0 | 0b100;
	//wacht tot dit doorgevoerd is
    OSTimeDlyHMSM(0, 0, 0, 10);

    //zet write weer even uit
	*matrixRegister = 0;
	*(matrixRegister+1) = 0x0;
	*(matrixRegister+2) = matrixBuf[1] & 0b100;
	*(matrixRegister+3) = 0x0;
	*matrixRegister = (1<<16)| 0b100;
    OSTimeDlyHMSM(0, 0, 0, 10);
    //zet write weer even uit
	*matrixRegister = 0;
	while(1)
	{
		if(links_button) {
			if(indexFiguur == 0) {
				//ignore input
				continue;
			}
			matrixBuf[indexFiguurHeight][indexFiguur+1] = matrixBuf[indexFiguurHeight+1][indexFiguur+1] = zwart;
			indexFiguur -=1;
		}
		else if(rechts_button) {
			if((indexFiguur + 1) == 31) {
				//tegen de rechter muur
				continue;
			}
			matrixBuf[indexFiguurHeight][indexFiguur] = matrixBuf[indexFiguurHeight+1][indexFiguur] = zwart;
			indexFiguur += 1;
		}
		if(boven_button) {
			if(indexFiguurHeight == 0) {
				continue;
			}
			matrixBuf[indexFiguurHeight+1][indexFiguur] = matrixBuf[indexFiguurHeight+1][indexFiguur+1] = zwart;
			indexFiguurHeight -=1;
		}
		else if(onder_button) {
			if((indexFiguurHeight + 1) == 31) {
				continue;
			}
			matrixBuf[indexFiguurHeight][indexFiguur] = matrixBuf[indexFiguurHeight][indexFiguur+1] = zwart;
			indexFiguurHeight += 1;
		}
		matrixBuf[indexFiguurHeight][indexFiguur] = matrixBuf[indexFiguurHeight+1][indexFiguur] = blauw;
		matrixBuf[indexFiguurHeight][indexFiguur+1] = matrixBuf[indexFiguurHeight+1][indexFiguur+1] = blauw;

		//update de matrix
		*(matrixRegister+1) = matrixBuf[indexFiguurHeight] & 0b001;
		*(matrixRegister+2) = matrixBuf[indexFiguurHeight] & 0b010;
		*(matrixRegister+3) = matrixBuf[indexFiguurHeight] & 0b100;
		*matrixRegister = (indexFiguurHeight<<16) | 0b100;
		//wacht tot dit doorgevoerd is
	    OSTimeDlyHMSM(0, 0, 0, 10);

	    //zet write weer even uit
		*matrixRegister = 0;
		*(matrixRegister+1) = matrixBuf[indexFiguurHeight+1] & 0b001;
		*(matrixRegister+2) = matrixBuf[indexFiguurHeight+1] & 0b010;
		*(matrixRegister+3) = matrixBuf[indexFiguurHeight+1] & 0b100;
		*matrixRegister = ((indexFiguurHeight+1)<<16)| 0b100;
	    OSTimeDlyHMSM(0, 0, 0, 10);
		*matrixRegister = 0;
		//updat de scherm elke 2 seconden
	    OSTimeDlyHMSM(0, 0, 2, 0);

	}
}
/* The main function creates two task and starts multi-tasking */
int main(void)
{

  printf("MicroC/OS-II Licensing Terms\n");
  printf("============================\n");
  printf("Micrium\'s uC/OS-II is a real-time operating system (RTOS) available in source code.\n");
  printf("This is not open-source software.\n");
  printf("This RTOS can be used free of charge only for non-commercial purposes and academic projects,\n");
  printf("any other use of the code is subject to the terms of an end-user license agreement\n");
  printf("for more information please see the license files included in the BSP project or contact Micrium.\n");
  printf("Anyone planning to use a Micrium RTOS in a commercial product must purchase a commercial license\n");
  printf("from the owner of the software, Silicon Laboratories Inc.\n");
  printf("Licensing information is available at:\n");
  printf("Phone: +1 954-217-2036\n");
  printf("Email: sales@micrium.com\n");
  printf("URL: www.micrium.com\n\n\n");  

  OSTaskCreateExt(input_handler,
                  NULL,
                  (void *)&task1_stk[TASK_STACKSIZE-1],
                  TASK1_PRIORITY,
                  TASK1_PRIORITY,
                  task1_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);
              
               
  OSTaskCreateExt(matrix_handler,
                  NULL,
                  (void *)&task2_stk[TASK_STACKSIZE-1],
                  TASK2_PRIORITY,
                  TASK2_PRIORITY,
                  task2_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);
  OSStart();
  return 0;
}

/******************************************************************************
*                                                                             *
* License Agreement                                                           *
*                                                                             *
* Copyright (c) 2004 Altera Corporation, San Jose, California, USA.           *
* All rights reserved.                                                        *
*                                                                             *
* Permission is hereby granted, free of charge, to any person obtaining a     *
* copy of this software and associated documentation files (the "Software"),  *
* to deal in the Software without restriction, including without limitation   *
* the rights to use, copy, modify, merge, publish, distribute, sublicense,    *
* and/or sell copies of the Software, and to permit persons to whom the       *
* Software is furnished to do so, subject to the following conditions:        *
*                                                                             *
* The above copyright notice and this permission notice shall be included in  *
* all copies or substantial portions of the Software.                         *
*                                                                             *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  *
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    *
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE *
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      *
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     *
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         *
* DEALINGS IN THE SOFTWARE.                                                   *
*                                                                             *
* This agreement shall be governed in all respects by the laws of the State   *
* of California and by the laws of the United States of America.              *
* Altera does not recommend, suggest or require that this reference design    *
* file be used in conjunction or combination with any other product.          *
******************************************************************************/
