	component audio is
		port (
			reset_reset_n   : in  std_logic                    := 'X';             -- reset_n
			leds_export     : out std_logic_vector(9 downto 0);                    -- export
			switches_export : in  std_logic_vector(9 downto 0) := (others => 'X')  -- export
		);
	end component audio;

	u0 : component audio
		port map (
			reset_reset_n   => CONNECTED_TO_reset_reset_n,   --    reset.reset_n
			leds_export     => CONNECTED_TO_leds_export,     --     leds.export
			switches_export => CONNECTED_TO_switches_export  -- switches.export
		);

