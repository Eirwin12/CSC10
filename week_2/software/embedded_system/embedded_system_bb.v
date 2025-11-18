
module embedded_system (
	clk_clk,
	reset_reset_n,
	to_7seg_readdata,
	to_hex_readdata);	

	input		clk_clk;
	input		reset_reset_n;
	output	[6:0]	to_7seg_readdata;
	output	[31:0]	to_hex_readdata;
endmodule
