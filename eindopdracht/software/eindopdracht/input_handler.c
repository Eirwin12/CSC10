/*
 * input_handler.c
 *
 *  Created on: 21 jan. 2026
 *      Author: E. Li
 */

#include "system.h"


bool links_button;
bool rechts_button;
bool boven_button;
bool onder_button;

void input_handler(void* pdata)
{
	*(int *) PIO_LEDS_BASE = *(int *) PIO_BUTTONS_BASE;
	int values = *(int*) PIO_BUTTONS_BASE;
	links_button = values & 0x01;
	rechts_button = values & 0x02;
	boven_button = values & 0x04;
	onder_button = values & 0x08;
}
