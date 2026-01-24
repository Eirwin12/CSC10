	component soc_system is
		port (
			clk_clk             : in  std_logic                    := 'X';             -- clk
			key_external_export : in  std_logic_vector(3 downto 0) := (others => 'X'); -- export
			matrix_external_r1  : out std_logic;                                       -- r1
			matrix_external_g1  : out std_logic;                                       -- g1
			matrix_external_b1  : out std_logic;                                       -- b1
			matrix_external_r2  : out std_logic;                                       -- r2
			matrix_external_g2  : out std_logic;                                       -- g2
			matrix_external_b2  : out std_logic;                                       -- b2
			matrix_external_a   : out std_logic;                                       -- a
			matrix_external_b   : out std_logic;                                       -- b
			matrix_external_c   : out std_logic;                                       -- c
			matrix_external_d   : out std_logic;                                       -- d
			matrix_external_clk : out std_logic;                                       -- clk
			matrix_external_lat : out std_logic;                                       -- lat
			matrix_external_oe  : out std_logic;                                       -- oe
			reset_reset_n       : in  std_logic                    := 'X'              -- reset_n
		);
	end component soc_system;

	u0 : component soc_system
		port map (
			clk_clk             => CONNECTED_TO_clk_clk,             --             clk.clk
			key_external_export => CONNECTED_TO_key_external_export, --    key_external.export
			matrix_external_r1  => CONNECTED_TO_matrix_external_r1,  -- matrix_external.r1
			matrix_external_g1  => CONNECTED_TO_matrix_external_g1,  --                .g1
			matrix_external_b1  => CONNECTED_TO_matrix_external_b1,  --                .b1
			matrix_external_r2  => CONNECTED_TO_matrix_external_r2,  --                .r2
			matrix_external_g2  => CONNECTED_TO_matrix_external_g2,  --                .g2
			matrix_external_b2  => CONNECTED_TO_matrix_external_b2,  --                .b2
			matrix_external_a   => CONNECTED_TO_matrix_external_a,   --                .a
			matrix_external_b   => CONNECTED_TO_matrix_external_b,   --                .b
			matrix_external_c   => CONNECTED_TO_matrix_external_c,   --                .c
			matrix_external_d   => CONNECTED_TO_matrix_external_d,   --                .d
			matrix_external_clk => CONNECTED_TO_matrix_external_clk, --                .clk
			matrix_external_lat => CONNECTED_TO_matrix_external_lat, --                .lat
			matrix_external_oe  => CONNECTED_TO_matrix_external_oe,  --                .oe
			reset_reset_n       => CONNECTED_TO_reset_reset_n        --           reset.reset_n
		);

