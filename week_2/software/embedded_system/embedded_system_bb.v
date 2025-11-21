
module embedded_system (
	clk_clk,
	reset_reset_n,
	to_hex_readdata,
	to_display_1_readdata);	

	input		clk_clk;
	input		reset_reset_n;
	output	[31:0]	to_hex_readdata;
	output	[55:0]	to_display_1_readdata;
endmodule
