/*
 * second_filter.c
 *
 *  Created on: 19 dec. 2025
 *      Author: E. Li
 */

#include "better_filter.h"

const short int better_B[N +1] = {
	-24 , 0, 30 , 53 , 48 , 0, -79 , -143 , -127 ,
	0, 195 , 338 , 290 , 0, -419 , -711 , -602 , 0,
	877 , 1520 , 1344 , 0, -2377 , -5135 , -7341 , 24552 , -7341 ,
	-5135 , -2377 , 0, 1344 , 1520 , 877 , 0, -602 , -711 ,
	-419 , 0, 290 , 338 , 195 , 0, -127 , -143 , -79 ,
	0, 48 , 53 , 30 , 0, -24
};

short int secondFirFilter(short int sample)
{
	static short int buffer [N+1] = {0}; // buffer for input samples
	// read audio buffer
	// Add sample to buffer
	buffer [0] = sample ;
	// Apply filter calculation ( convolution )
	int output = 0;
	for ( size_t k = 0; k <= N; k ++)
	{
		output += buffer [k] * better_B[k ];
	}
	// Shift old samples to the back of the buffer
	for (size_t i = N; i >= 1; i --)
	{
		buffer [i] = buffer [i-1];
	}
	// write audio buffer
	return output;

}

