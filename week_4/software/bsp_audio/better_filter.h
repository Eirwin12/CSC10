/*
 * better_filter.h
 *
 *  Created on: 19 dec. 2025
 *      Author: E. Li
 */

#ifndef BETTER_FILTER_H_
#define BETTER_FILTER_H_

#include <altera_up_avalon_audio.h>
#include <altera_avalon_pio_regs.h>

# define N 50
// Q1.15 : 16 bits fixed point fraction length is 15 bits
const short int B[N +1] = {
	-24 , 0, 30 , 53 , 48 , 0, -79 , -143 , -127 ,
	0, 195 , 338 , 290 , 0, -419 , -711 , -602 , 0,
	877 , 1520 , 1344 , 0, -2377 , -5135 , -7341 , 24552 , -7341 ,
	-5135 , -2377 , 0, 1344 , 1520 , 877 , 0, -602 , -711 ,
	-419 , 0, 290 , 338 , 195 , 0, -127 , -143 , -79 ,
	0, 48 , 53 , 30 , 0, -24
};

short int secondFirFilter(short int sample);

#endif /* BETTER_FILTER_H_ */
