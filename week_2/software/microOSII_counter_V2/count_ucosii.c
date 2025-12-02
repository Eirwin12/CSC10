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
#include "includes.h"
#include "altera_avalon_jtag_uart.h"
/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];
OS_STK    task3_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */

#define TASK1_PRIORITY      1
#define TASK2_PRIORITY      2
#define TASK3_PRIORITY		3

//a enum to keep track of all states
typedef enum {
	lopen,
	stilstaan,
} TOESTAND_EN;

//deze task zal de counter verhogen van de 4 rechter 7 seg display
void countTask1(void* pdata)
{
	TOESTAND_EN *toestand = (TOESTAND_EN*)pdata;
	INT16U count = 0;
	volatile int * lsb = (int *)REG32_AVALON_INTERFACE_V2_0_AVALON_SLAVE_0_BASE;
	while(1)
	{
		if(*toestand == lopen)
		{
			*lsb = count & 0xFFFF;
			OSTimeDlyHMSM(0, 0, 0, 1);
			count = (count + 1)% 0xFFFF;
		}
		else
		{
			OSTimeDlyHMSM(0, 0, 0, 10);
		}
	}
}
//deze task zal de counter verhogen van de 2 linker 7 seg display
void countTask2(void* pdata)
{
	TOESTAND_EN *toestand = (TOESTAND_EN*)pdata;
	INT16U count = 0;
	volatile int * msb = (int *)REG32_AVALON_INTERFACE_V2_0_AVALON_SLAVE_1_BASE;
	while(1)
	{
		if(*toestand == lopen)
		{
			*msb = count & 0xFF;
			OSTimeDlyHMSM(0, 0, 1, 0);
			count = (count + 1)% 0xFF;
		}
		else
		{
			OSTimeDlyHMSM(0, 0, 1, 0);
		}
	}
}

typedef struct {
	TOESTAND_EN *toestand;
	altera_avalon_jtag_uart_state uartTag;
}uartData;

void UARTTask(void* pdata)
{
	uartData *data = (uartData*)pdata;
	char input;
	while(1)
	{
		input = getchar();
		if(input == '\r' || (input == '\n'))
		{
			continue;
		}
		if(*data->toestand == stilstaan && input == '1')
		{
			*data->toestand = lopen;
		}
		else if(*data->toestand == lopen && input == '0')
		{
			*data->toestand = stilstaan;
		}
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

  TOESTAND_EN toestand = stilstaan;
  OSTaskCreateExt(countTask1,
		  	  	  &toestand,
                  (void *)&task1_stk[TASK_STACKSIZE-1],
                  TASK1_PRIORITY,
                  TASK1_PRIORITY,
                  task1_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);
              
  OSTaskCreateExt(countTask2,
		  	  	  &toestand,
                  (void *)&task2_stk[TASK_STACKSIZE-1],
                  TASK2_PRIORITY,
                  TASK2_PRIORITY,
                  task2_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);

  altera_avalon_jtag_uart_state uartTag = {JTAG_UART_0_BASE};
  uartData taskData = {&toestand, uartTag};
  OSTaskCreateExt(UARTTask,
		  	  	  &taskData,
                  (void *)&task3_stk[TASK_STACKSIZE-1],
                  TASK3_PRIORITY,
                  TASK3_PRIORITY,
                  task3_stk,
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
