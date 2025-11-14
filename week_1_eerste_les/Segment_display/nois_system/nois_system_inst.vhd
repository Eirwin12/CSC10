	component nois_system is
		port (
			clk_clk            : in  std_logic                     := 'X'; -- clk
			left_3_hex_export  : out std_logic_vector(20 downto 0);        -- export
			right_3_hex_export : out std_logic_vector(20 downto 0);        -- export
			reset_reset_n      : in  std_logic                     := 'X'  -- reset_n
		);
	end component nois_system;

	u0 : component nois_system
		port map (
			clk_clk            => CONNECTED_TO_clk_clk,            --         clk.clk
			left_3_hex_export  => CONNECTED_TO_left_3_hex_export,  --  left_3_hex.export
			right_3_hex_export => CONNECTED_TO_right_3_hex_export, -- right_3_hex.export
			reset_reset_n      => CONNECTED_TO_reset_reset_n       --       reset.reset_n
		);

