	component nois_system is
		port (
			clk_clk                              : in  std_logic                     := 'X'; -- clk
			hex3_hex0_external_connection_export : out std_logic_vector(31 downto 0);        -- export
			hex5_hex4_external_connection_export : out std_logic_vector(15 downto 0);        -- export
			reset_reset_n                        : in  std_logic                     := 'X'  -- reset_n
		);
	end component nois_system;

	u0 : component nois_system
		port map (
			clk_clk                              => CONNECTED_TO_clk_clk,                              --                           clk.clk
			hex3_hex0_external_connection_export => CONNECTED_TO_hex3_hex0_external_connection_export, -- hex3_hex0_external_connection.export
			hex5_hex4_external_connection_export => CONNECTED_TO_hex5_hex4_external_connection_export, -- hex5_hex4_external_connection.export
			reset_reset_n                        => CONNECTED_TO_reset_reset_n                         --                         reset.reset_n
		);

