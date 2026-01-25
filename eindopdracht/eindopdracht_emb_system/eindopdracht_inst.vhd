	component eindopdracht is
		port (
			clk_clk             : in  std_logic                     := 'X';             -- clk
			pio_buttons_export  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- export
			pio_leds_export     : out std_logic_vector(9 downto 0);                     -- export
			pio_switches_export : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- export
			output_data         : out std_logic_vector(31 downto 0)                     -- data
		);
	end component eindopdracht;

	u0 : component eindopdracht
		port map (
			clk_clk             => CONNECTED_TO_clk_clk,             --          clk.clk
			pio_buttons_export  => CONNECTED_TO_pio_buttons_export,  --  pio_buttons.export
			pio_leds_export     => CONNECTED_TO_pio_leds_export,     --     pio_leds.export
			pio_switches_export => CONNECTED_TO_pio_switches_export, -- pio_switches.export
			output_data         => CONNECTED_TO_output_data          --       output.data
		);

