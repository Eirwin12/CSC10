/*
 * filter.h
 *
 *  Created on: 19 dec. 2025
 *      Author: E. Li
 */

#ifndef FILTER_H_
#define FILTER_H_

#include <altera_up_avalon_audio.h>
#include <altera_avalon_pio_regs.h>

#define N 8

const short int B[N+1] = {
		0, -528 , -2817 , -6383 , 24580 , -6383 , -2817 , -528 , 0
};
short int FIRFilter(short int sample);
#endif /* FILTER_H_ */
