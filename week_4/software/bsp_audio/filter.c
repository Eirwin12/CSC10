/*
 * filter.c
 *
 *  Created on: 19 dec. 2025
 *      Author: E. Li
 */
#include "filter.h"

short int FIRFilter(short int sample)
{
	static short int buffer [N+1] = {0}; // buffer for input samples
	// read audio buffer
	// Add sample to buffer
	buffer [0] = sample ;
	// Apply filter calculation ( convolution )
	int output = 0;
	for ( size_t k = 0; k <= N; k ++)
	{
		output += buffer [k] * B[k ];
	}
	// Shift old samples to the back of the buffer
	for (size_t i = N; i >= 1; i --)
	{
		buffer [i] = buffer [i -1];
	}
	// write audio buffer
	return output;

}
