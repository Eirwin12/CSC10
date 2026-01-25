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
#include "alt_types.h"


/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];
OS_STK    task3_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */

#define TASK1_PRIORITY      2
#define TASK2_PRIORITY      3
#define TASK3_PRIORITY      1

// Matrix dimensions
#define MATRIX32_WIDTH                 32
#define MATRIX32_HEIGHT                32
#define MATRIX32_FRAMEBUFFER_SIZE      384  // 32x32x3 bits / 8 = 384 bytes
static alt_u8 fb_cache[MATRIX32_FRAMEBUFFER_SIZE];

#define CONTROL_REG 0
#define ADDR_REG 2
#define DATA_REG 3
#define STATUS_REG 4

void matrix32_write_fb_byte(alt_u32 *base_address, alt_u16 byte_addr, alt_u8 data) {
	*(base_address+ADDR_REG) = byte_addr;
	*(base_address+DATA_REG) = data;
}

void matrix32_set_pixel(alt_u32 base_address, alt_u8 x, alt_u8 y,
                        alt_u8 r, alt_u8 g, alt_u8 b) {
    if (x >= MATRIX32_WIDTH || y >= MATRIX32_HEIGHT) {
        return;
    }

    alt_u16 pixel_index = y * MATRIX32_WIDTH + x;
    alt_u16 byte_addr = pixel_index / 8;
    alt_u8 bit_offset = pixel_index % 8;
    alt_u8 bit_mask = 1 << bit_offset;

    // R channel
    alt_u8 r_byte = fb_cache[byte_addr];
    if (r) {
        r_byte |= bit_mask;
    } else {
        r_byte &= ~bit_mask;
    }
    matrix32_write_fb_byte((alt_u32 *)base_address, byte_addr, r_byte);
    fb_cache[byte_addr] = r_byte;

    // G channel
    alt_u8 g_byte = fb_cache[128 + byte_addr];
    if (g) {
        g_byte |= bit_mask;
    } else {
        g_byte &= ~bit_mask;
    }
    matrix32_write_fb_byte((alt_u32 *)base_address, 128 + byte_addr, g_byte);
    fb_cache[128 + byte_addr] = g_byte;

    // B channel
    alt_u8 b_byte = fb_cache[256 + byte_addr];
    if (b) {
        b_byte |= bit_mask;
    } else {
        b_byte &= ~bit_mask;
    }
    matrix32_write_fb_byte((alt_u32 *)base_address, 256 + byte_addr, b_byte);
    fb_cache[256 + byte_addr] = b_byte;

}

bool links_button;
bool rechts_button;
bool boven_button;
bool onder_button;
//handle all the inputs
void input_handler(void* pdata)
{
	volatile int *button_base = (int *) PIO_BUTTONS_BASE;
	while(1)
	{
	int values = *button_base;
		links_button = values & 1;
		rechts_button = values & 1<<1;
		boven_button = values & 1<<2;
		onder_button = values & 1<<3;
		OSTimeDlyHMSM(0, 0, 0, 500);
	}
}

typedef enum kleuren {
	zwart = 0,
	rood = 0x1,
	groen = 0x2,
	blauw = 0x4,
	//secundaire kleuren (combi van 2 van de 3 kleuren
	magenta = 0x5,//rood + blauw
	geel = 0x3, //groen + blauw
	cyaan = 0x6, //groen + blauw
	wit = 0x7,
}kleuren_matrix_e;

kleuren_matrix_e figuurKleur = blauw;

//eerst testen of de matrix werkt of niet

void matrix_handler(void* pdata)
{
	alt_u8 rijLinks = 16;
	alt_u8 rijRechts = 17;
	alt_u8 collumnBoven = 16;
	alt_u8 collumnOnder = 17;
//	kleuren_matrix_e matrix_buf[32][32];
	matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnBoven, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
	matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnOnder, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
	matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnBoven, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
	matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnOnder, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
	while(1)
	{
		if(!links_button) {
			if(rijLinks > 0) {
				//pixel uit
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnBoven, 0, 0, 0);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnOnder, 0, 0, 0);
				//pixel aan
				rijLinks--;
				rijRechts--;
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnBoven, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnOnder, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
			}
		}
		else if(!rechts_button) {
			if(rijRechts <32){
			//pixel uit
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnBoven, 0, 0, 0);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnOnder, 0, 0, 0);
				//pixel aan
				rijLinks++;
				rijRechts++;
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnBoven, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnOnder, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
			}
		}
		if(!boven_button) {
			if(collumnBoven >0) {
				//pixel uit
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnOnder, 0, 0, 0);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnOnder, 0, 0, 0);
				//pixel aan
				collumnBoven--;
				collumnOnder--;
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnBoven, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnBoven, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
			}
		}
		else if (!onder_button){
			if(collumnOnder < 32) {
				//pixel uit
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnBoven, 0, 0, 0);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnBoven, 0, 0, 0);
				//pixel aan
				collumnBoven++;
				collumnOnder++;
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijLinks, collumnOnder, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
				matrix32_set_pixel(MATRIX_FRAMEBUFFER_AI_0_BASE, rijRechts, collumnOnder, figuurKleur & 0x1, figuurKleur & 0x2, figuurKleur & 0x4);
			}
		}
	    OSTimeDlyHMSM(0, 0, 1, 0);
	}
}

void kleur_handler(void* pdata)
{
	volatile int *switch_base = (int *) PIO_SWITCHES_BASE;
	volatile int *leds_base = (int *) PIO_LEDS_BASE;
	figuurKleur = zwart;
	while(1)
	{
		int values = *switch_base;
		if(values == zwart) {
			figuurKleur = wit;
			continue;
		}
		figuurKleur = values;
		*leds_base = *switch_base;
		OSTimeDlyHMSM(0, 0, 5, 0);
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
  OSTaskCreateExt(kleur_handler,
                  NULL,
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
