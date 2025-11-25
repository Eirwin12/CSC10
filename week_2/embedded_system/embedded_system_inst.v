	embedded_system u0 (
		.clk_clk             (<connected-to-clk_clk>),             //        clk.clk
		.reset_reset_n       (<connected-to-reset_reset_n>),       //      reset.reset_n
		.to_hex_lsb_readdata (<connected-to-to_hex_lsb_readdata>), // to_hex_lsb.readdata
		.to_hex_msb_readdata (<connected-to-to_hex_msb_readdata>)  // to_hex_msb.readdata
	);

