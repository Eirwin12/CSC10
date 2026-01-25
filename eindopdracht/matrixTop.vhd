library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matrix_top is
   Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        R1, G1, B1      : out std_logic;
        R2, G2, B2      : out std_logic;
        A, B, C, D      : out std_logic;
        CLK_out         : out std_logic;
        LAT             : out std_logic;
        OE              : out std_logic;
        fb_write_enable : in  std_logic;
        fb_write_addr   : in  std_logic_vector(11 downto 0);
        fb_write_data   : in  std_logic_vector(7 downto 0);
        mode            : in  std_logic;
        test_pattern    : in  std_logic_vector(2 downto 0)
        );
end entity;

architecture imp of matrix_top is
	component rgb_framebuffer is
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            R1, G1, B1      : out std_logic;
            R2, G2, B2      : out std_logic;
            A, B, C, D      : out std_logic;
            fb_write_enable : in  std_logic;
            fb_write_addr   : in  std_logic_vector(11 downto 0);
            fb_write_data   : in  std_logic_vector(7 downto 0);
            mode            : in  std_logic;
            test_pattern    : in  std_logic_vector(2 downto 0)
        );
	end component;
	
	component fsm_display is
		port (
			  clk, rst: in std_ulogic;
			  start_button, collumn_filled, write, write_done: in std_ulogic;
			  --matrix outputs
			  reset_matrix, enable_matrix, enable_latch, row_change, write_matrix: out std_ulogic
		 );
	end component;
	
	--houdt bij machten van 2, was wat AI had gedaan, maar kan in principe welke waarde dat gewild wordt
	constant brightness: natural := 32;
	component nibble_count is
		generic (max_count: natural);
		port(
			klok, reset, enable: in std_ulogic;
			count: out std_ulogic_vector(7 downto 0);
			count_done: out std_ulogic
		);
	end component;
	
	signal reset_matrix_s, enable_matrix_s, enable_latch_s, collumn_filled_s, row_changed, write_done_s, write_matrix_s: std_ulogic := '0';
	signal reset: std_ulogic;
	
	constant CONTROL_START_BIT: natural := 0;
	constant CONTROL_RESET_BIT: natural := 1;
	constant CONTROL_WRITE_BIT: natural := 2;
	
	constant ADDRESS_UPPER_BOUND: natural := 20;
	constant ADDRESS_LOWER_BOUND: natural := 16;
begin
	reset <= rst or control_register(CONTROL_RESET_BIT);
	matrix_com: rgb_framebuffer
        port map (
            clk             => clk,
            reset           => reset,
            R1              => R1,
            G1              => G1,
            B1              => B1,
            R2              => R2,
            G2              => G2,
            B2              => B2,
            A               => A,
            B               => B,
            C               => C,
            D               => D,
            fb_write_enable => fb_write_enable,
            fb_write_addr   => reg_fb_addr(11 downto 0),
            fb_write_data   => reg_fb_data(7 downto 0),
            mode            => mode,
            test_pattern    => test_pattern_int
        );
	
	fsm: fsm_display
	port map (
		clk => clk,
		rst => reset,
		start_button => '1',
		collumn_filled => collumn_filled_s,
		write => control_register(CONTROL_WRITE_BIT),
		write_done => write_done_s,
		
		write_matrix => write_matrix_s,
		reset_matrix => reset_matrix_s,
		enable_matrix => enable_matrix_s,
		enable_latch => enable_latch_s,
		row_change => row_changed
	);

	OE <= not enable_matrix_s;--its active low
	LAT <= enable_latch_s;
	CLK_out <= clk;
	status_register <= (0 => enable_matrix_s, 1 => write_done_s, others => '0');
end architecture;