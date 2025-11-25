
module embedded_system (
	clk_clk,
	reset_reset_n,
	to_hex_lsb_readdata,
	to_hex_msb_readdata);	

	input		clk_clk;
	input		reset_reset_n;
	output	[31:0]	to_hex_lsb_readdata;
	output	[31:0]	to_hex_msb_readdata;
endmodule
