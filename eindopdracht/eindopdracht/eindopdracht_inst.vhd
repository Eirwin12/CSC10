	component eindopdracht is
		port (
			clk_clk                                      : in  std_logic                    := 'X';             -- clk
			pio_buttons_external_connection_export       : in  std_logic_vector(3 downto 0) := (others => 'X'); -- export
			pio_switches_external_connection_export      : in  std_logic_vector(9 downto 0) := (others => 'X'); -- export
			rgb_framebuffer_0_rgb_matrix_conduit_r1      : out std_logic;                                       -- r1
			rgb_framebuffer_0_rgb_matrix_conduit_g1      : out std_logic;                                       -- g1
			rgb_framebuffer_0_rgb_matrix_conduit_b1      : out std_logic;                                       -- b1
			rgb_framebuffer_0_rgb_matrix_conduit_r2      : out std_logic;                                       -- r2
			rgb_framebuffer_0_rgb_matrix_conduit_g2      : out std_logic;                                       -- g2
			rgb_framebuffer_0_rgb_matrix_conduit_b2      : out std_logic;                                       -- b2
			rgb_framebuffer_0_rgb_matrix_conduit_addr_a  : out std_logic;                                       -- addr_a
			rgb_framebuffer_0_rgb_matrix_conduit_addr_b  : out std_logic;                                       -- addr_b
			rgb_framebuffer_0_rgb_matrix_conduit_addr_c  : out std_logic;                                       -- addr_c
			rgb_framebuffer_0_rgb_matrix_conduit_clk_out : out std_logic;                                       -- clk_out
			rgb_framebuffer_0_rgb_matrix_conduit_lat     : out std_logic;                                       -- lat
			rgb_framebuffer_0_rgb_matrix_conduit_oe_n    : out std_logic                                        -- oe_n
		);
	end component eindopdracht;

	u0 : component eindopdracht
		port map (
			clk_clk                                      => CONNECTED_TO_clk_clk,                                      --                                  clk.clk
			pio_buttons_external_connection_export       => CONNECTED_TO_pio_buttons_external_connection_export,       --      pio_buttons_external_connection.export
			pio_switches_external_connection_export      => CONNECTED_TO_pio_switches_external_connection_export,      --     pio_switches_external_connection.export
			rgb_framebuffer_0_rgb_matrix_conduit_r1      => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_r1,      -- rgb_framebuffer_0_rgb_matrix_conduit.r1
			rgb_framebuffer_0_rgb_matrix_conduit_g1      => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_g1,      --                                     .g1
			rgb_framebuffer_0_rgb_matrix_conduit_b1      => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_b1,      --                                     .b1
			rgb_framebuffer_0_rgb_matrix_conduit_r2      => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_r2,      --                                     .r2
			rgb_framebuffer_0_rgb_matrix_conduit_g2      => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_g2,      --                                     .g2
			rgb_framebuffer_0_rgb_matrix_conduit_b2      => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_b2,      --                                     .b2
			rgb_framebuffer_0_rgb_matrix_conduit_addr_a  => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_addr_a,  --                                     .addr_a
			rgb_framebuffer_0_rgb_matrix_conduit_addr_b  => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_addr_b,  --                                     .addr_b
			rgb_framebuffer_0_rgb_matrix_conduit_addr_c  => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_addr_c,  --                                     .addr_c
			rgb_framebuffer_0_rgb_matrix_conduit_clk_out => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_clk_out, --                                     .clk_out
			rgb_framebuffer_0_rgb_matrix_conduit_lat     => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_lat,     --                                     .lat
			rgb_framebuffer_0_rgb_matrix_conduit_oe_n    => CONNECTED_TO_rgb_framebuffer_0_rgb_matrix_conduit_oe_n     --                                     .oe_n
		);

