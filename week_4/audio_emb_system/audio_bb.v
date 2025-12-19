
module audio (
	leds_export,
	reset_reset_n,
	switches_export,
	audio_ADCDAT,
	audio_ADCLRCK,
	audio_BCLK,
	audio_DACDAT,
	audio_DACLRCK,
	audio_config_SDAT,
	audio_config_SCLK,
	clk_clk,
	audio_clk_clk);	

	output	[9:0]	leds_export;
	input		reset_reset_n;
	input	[9:0]	switches_export;
	input		audio_ADCDAT;
	input		audio_ADCLRCK;
	input		audio_BCLK;
	output		audio_DACDAT;
	input		audio_DACLRCK;
	inout		audio_config_SDAT;
	output		audio_config_SCLK;
	input		clk_clk;
	output		audio_clk_clk;
endmodule
