
module nois_system (
	clk_clk,
	left_3_hex_export,
	right_3_hex_export,
	reset_reset_n);	

	input		clk_clk;
	output	[20:0]	left_3_hex_export;
	output	[20:0]	right_3_hex_export;
	input		reset_reset_n;
endmodule
