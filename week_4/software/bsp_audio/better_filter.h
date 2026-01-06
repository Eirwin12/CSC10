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
extern const short int better_B[N +1];

short int secondFirFilter(short int sample);

#endif /* BETTER_FILTER_H_ */
