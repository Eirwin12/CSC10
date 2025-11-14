	component nois_system is
		port (
			clk_clk                                    : in  std_logic                    := 'X';             -- clk
			reset_reset_n                              : in  std_logic                    := 'X';             -- reset_n
			pio_in_segment_external_connection_export  : in  std_logic_vector(3 downto 0) := (others => 'X'); -- export
			pio_out_segment_external_connection_export : out std_logic_vector(6 downto 0)                     -- export
		);
	end component nois_system;

	u0 : component nois_system
		port map (
			clk_clk                                    => CONNECTED_TO_clk_clk,                                    --                                 clk.clk
			reset_reset_n                              => CONNECTED_TO_reset_reset_n,                              --                               reset.reset_n
			pio_in_segment_external_connection_export  => CONNECTED_TO_pio_in_segment_external_connection_export,  --  pio_in_segment_external_connection.export
			pio_out_segment_external_connection_export => CONNECTED_TO_pio_out_segment_external_connection_export  -- pio_out_segment_external_connection.export
		);

