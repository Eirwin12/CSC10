
module nois_system (
	clk_clk,
	reset_reset_n,
	pio_in_segment_external_connection_export,
	pio_out_segment_external_connection_export);	

	input		clk_clk;
	input		reset_reset_n;
	input	[3:0]	pio_in_segment_external_connection_export;
	output	[6:0]	pio_out_segment_external_connection_export;
endmodule
