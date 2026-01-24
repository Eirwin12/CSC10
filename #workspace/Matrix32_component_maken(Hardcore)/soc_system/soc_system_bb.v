
module soc_system (
	clk_clk,
	key_external_export,
	matrix_external_r1,
	matrix_external_g1,
	matrix_external_b1,
	matrix_external_r2,
	matrix_external_g2,
	matrix_external_b2,
	matrix_external_a,
	matrix_external_b,
	matrix_external_c,
	matrix_external_d,
	matrix_external_clk,
	matrix_external_lat,
	matrix_external_oe,
	reset_reset_n);	

	input		clk_clk;
	input	[3:0]	key_external_export;
	output		matrix_external_r1;
	output		matrix_external_g1;
	output		matrix_external_b1;
	output		matrix_external_r2;
	output		matrix_external_g2;
	output		matrix_external_b2;
	output		matrix_external_a;
	output		matrix_external_b;
	output		matrix_external_c;
	output		matrix_external_d;
	output		matrix_external_clk;
	output		matrix_external_lat;
	output		matrix_external_oe;
	input		reset_reset_n;
endmodule
