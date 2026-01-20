
module eindopdracht (
	clk_clk,
	pio_buttons_external_connection_export,
	pio_switches_external_connection_export,
	matrix_connection_readdata);	

	input		clk_clk;
	input	[3:0]	pio_buttons_external_connection_export;
	input	[9:0]	pio_switches_external_connection_export;
	output	[31:0]	matrix_connection_readdata;
endmodule
