
module nois_system (
	clk_clk,
	hex3_hex0_external_connection_export,
	hex5_hex4_external_connection_export,
	reset_reset_n);	

	input		clk_clk;
	output	[31:0]	hex3_hex0_external_connection_export;
	output	[15:0]	hex5_hex4_external_connection_export;
	input		reset_reset_n;
endmodule
