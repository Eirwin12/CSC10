	component eindopdracht is
		port (
			clk_clk                                 : in  std_logic                     := 'X';             -- clk
			pio_buttons_external_connection_export  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- export
			pio_switches_external_connection_export : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- export
			matrix_connection_readdata              : out std_logic_vector(31 downto 0)                     -- readdata
		);
	end component eindopdracht;

	u0 : component eindopdracht
		port map (
			clk_clk                                 => CONNECTED_TO_clk_clk,                                 --                              clk.clk
			pio_buttons_external_connection_export  => CONNECTED_TO_pio_buttons_external_connection_export,  --  pio_buttons_external_connection.export
			pio_switches_external_connection_export => CONNECTED_TO_pio_switches_external_connection_export, -- pio_switches_external_connection.export
			matrix_connection_readdata              => CONNECTED_TO_matrix_connection_readdata               --                matrix_connection.readdata
		);

