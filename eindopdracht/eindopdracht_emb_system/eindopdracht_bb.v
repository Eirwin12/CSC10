
module eindopdracht (
	clk_clk,
	matrix_output_readdata,
	pio_buttons_export,
	pio_leds_export,
	pio_switches_export);	

	input		clk_clk;
	output	[31:0]	matrix_output_readdata;
	input	[3:0]	pio_buttons_export;
	output	[9:0]	pio_leds_export;
	input	[9:0]	pio_switches_export;
endmodule
