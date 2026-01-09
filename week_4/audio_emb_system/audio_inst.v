	audio u0 (
		.leds_export       (<connected-to-leds_export>),       //         leds.export
		.reset_reset_n     (<connected-to-reset_reset_n>),     //        reset.reset_n
		.switches_export   (<connected-to-switches_export>),   //     switches.export
		.audio_ADCDAT      (<connected-to-audio_ADCDAT>),      //        audio.ADCDAT
		.audio_ADCLRCK     (<connected-to-audio_ADCLRCK>),     //             .ADCLRCK
		.audio_BCLK        (<connected-to-audio_BCLK>),        //             .BCLK
		.audio_DACDAT      (<connected-to-audio_DACDAT>),      //             .DACDAT
		.audio_DACLRCK     (<connected-to-audio_DACLRCK>),     //             .DACLRCK
		.audio_config_SDAT (<connected-to-audio_config_SDAT>), // audio_config.SDAT
		.audio_config_SCLK (<connected-to-audio_config_SCLK>), //             .SCLK
		.clk_clk           (<connected-to-clk_clk>),           //          clk.clk
		.audio_clk_clk     (<connected-to-audio_clk_clk>)      //    audio_clk.clk
	);

