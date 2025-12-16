
module audio (
	reset_reset_n,
	leds_export,
	switches_export);	

	input		reset_reset_n;
	output	[9:0]	leds_export;
	input	[9:0]	switches_export;
endmodule
