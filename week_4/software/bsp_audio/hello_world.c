#include <altera_up_avalon_audio.h>
#include <altera_up_avalon_audio_and_video_config.h>
#include <altera_avalon_performance_counter.h>
#include <altera_avalon_pio_regs.h>
#include <sys/alt_stdio.h>
#include <alt_types.h>
#include <stdlib.h>
#include <system.h>

#define TEST_BETTER_FILTER
#ifndef TEST_BETTER_FILTER
#include "hamming_filter.h"
#else
#include "better_filter.h"
#endif

int main(void) {
	PERF_RESET(AUDIO_0_BASE);
    alt_up_audio_dev *audio_dev = alt_up_audio_open_dev("/dev/audio_0");
    if (audio_dev == NULL) {
        alt_printf("Error: could not open audio device\n");
        return -1;
    } else
        alt_printf("Opened audio device\n");
    const int run_time_in_seconds = 30;
    const int run_time_in_samples = run_time_in_seconds * 48000;
    int sample_count = 0;

    alt_up_av_config_dev* audio_video_config = alt_up_av_config_open_dev("audio_config_0")
    if (audio_dev == NULL) {
        alt_printf("Error: could not open audio config device\n");
        return -1;
    } else
        alt_printf("Opened audio config\n");
    alt_u8 samplingControl = 0b0011 <<2;
    //register addres can be found in the codec datasheet
    //should be shifted 1 bit right (7 bit value and first bit isn't counted)
    alt_u8 addresSamplingControl = 0x10>>1;

    while(alt_up_av_config_read_ready(audio_video_config) == 0);
    if(alt_up_av_config_write_audio_cfg_register(audio_video_config, AUDIO_CONFIG_0_BASE+8, addresSamplingControl) != 0) {
    	alt_printf("Error: couldn't write address to config");
    	return -1;
    }
    while(alt_up_av_config_read_ready(audio_video_config) == 0);
    if(alt_up_av_config_write_audio_cfg_register(audio_video_config, AUDIO_CONFIG_0_BASE+12, samplingControl) != 0) {
    	alt_printf("Error: couldn't write data to config");
    	return -1;
    }
    *(int *)(AUDIO_CONFIG_0_BASE+12) = samplingControl;

    //start performance counter
    //before beginning, reset counter
    PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
	PERF_START_MEASURING(PERFORMANCE_COUNTER_0_BASE);

    do {
        int fifospace_right = alt_up_audio_read_fifo_avail(audio_dev, ALT_UP_AUDIO_RIGHT);
        if (fifospace_right > 0) { // check if data is
        	sample_count++;//available

        	PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, 1);
        	// read audio buffer
        	unsigned int r_buf = alt_up_audio_read_fifo_head(audio_dev, ALT_UP_AUDIO_RIGHT);
        	PERF_END(PERFORMANCE_COUNTER_0_BASE, 1);

            IOWR_ALTERA_AVALON_PIO_DATA(PIO_LEDS_BASE, abs((short)r_buf)>>5); // light up the leds
            // write audio buffer
            int output = secondFirFilter(r_buf);
        	alt_up_audio_write_fifo_head(audio_dev ,(( output>>14)+1)>>1 , ALT_UP_AUDIO_RIGHT );
        }
        int fifospace_left = alt_up_audio_read_fifo_avail(audio_dev, ALT_UP_AUDIO_LEFT);
        if (fifospace_left > 0) { // check if data is available
        	unsigned int l_buf = alt_up_audio_read_fifo_head(audio_dev, ALT_UP_AUDIO_LEFT);
        	PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, 2);
    	    alt_up_audio_write_fifo_head(audio_dev, l_buf, ALT_UP_AUDIO_LEFT);
        	PERF_END(PERFORMANCE_COUNTER_0_BASE, 2);
		}
    } while (sample_count < run_time_in_samples);

    PERF_STOP_MEASURING(PERFORMANCE_COUNTER_0_BASE);
    perf_print_formatted_report(AUDIO_0_BASE, 50000000, 2, "right", "left");
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_LEDS_BASE, 0); // switch off the leds
}
