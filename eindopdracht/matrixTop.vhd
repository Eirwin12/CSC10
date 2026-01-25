library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matrix_top is
	port (
        clk, rst: in std_ulogic;
		  control_register	: in std_logic_vector(31 downto 0);
		  red_vector_write	: in std_logic_vector(31 downto 0);
		  blue_vector_write	: in std_logic_vector(31 downto 0);
		  green_vector_write	: in std_logic_vector(31 downto 0);
		  status_register    : out std_logic_vector(31 downto 0);
		  
		  matrix_r1     : out std_logic;
		  matrix_g1     : out std_logic;
		  matrix_b1     : out std_logic;
		  matrix_r2     : out std_logic;
		  matrix_g2     : out std_logic;
		  matrix_b2     : out std_logic;
		  matrix_addr_a : out std_logic;
		  matrix_addr_b : out std_logic;
		  matrix_addr_c : out std_logic;
		  matrix_addr_d : out std_logic;
		  matrix_clk    : out std_logic;
		  matrix_lat    : out std_logic;
		  matrix_oe     : out std_logic
		);
end;

architecture imp of matrix_top is
	component rgb_framebuffer is
		port (
			clock, reset      : in  std_logic;	  
			red_vector_write	: in std_logic_vector(31 downto 0);
			blue_vector_write	: in std_logic_vector(31 downto 0);
			green_vector_write	: in std_logic_vector(31 downto 0);
			address			: in std_logic_vector(4 downto 0);
		   write           : in std_logic;
		   write_done      : out std_logic;
			collumn_filled  : out std_ulogic;
			change_row      : in std_ulogic;
			enable_matrix   : in std_ulogic;
			-- RGB Matrix Output Conduit
			matrix_r1     : out std_logic;
			matrix_g1     : out std_logic;
			matrix_b1     : out std_logic;
			matrix_r2     : out std_logic;
			matrix_g2     : out std_logic;
			matrix_b2     : out std_logic;
			matrix_addr_a : out std_logic;
			matrix_addr_b : out std_logic;
			matrix_addr_c : out std_logic;
			matrix_addr_d : out std_logic
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
	reset <= rst and control_register(CONTROL_RESET_BIT);
	matrix_com: rgb_framebuffer
	port map(
		clock => clk,
		reset => reset_matrix_s,
	  red_vector_write => red_vector_write,
	  blue_vector_write => blue_vector_write,
	  green_vector_write => green_vector_write,
	  address => control_register(ADDRESS_UPPER_BOUND downto ADDRESS_LOWER_BOUND),
	  write => control_register(CONTROL_WRITE_BIT),
	  write_done => write_done_s,
	  collumn_filled => collumn_filled_s,
	  change_row => row_changed,
	  enable_matrix => enable_matrix_s,
	  
		matrix_r1 => matrix_r1,
		matrix_g1 => matrix_g1,
		matrix_b1 => matrix_b1,
		matrix_r2 => matrix_r2,
		matrix_g2 => matrix_g2,
		matrix_b2 => matrix_b2,
		matrix_addr_a => matrix_addr_a,
		matrix_addr_b => matrix_addr_b,
		matrix_addr_c => matrix_addr_c,
		matrix_addr_d => matrix_addr_d
	);
	
	fsm: fsm_display
	port map (
		clk => clk,
		rst => reset,
		start_button => control_register(CONTROL_START_BIT),
		collumn_filled => collumn_filled_s,
		write => control_register(CONTROL_WRITE_BIT),
		write_done => write_done_s,
		
		write_matrix => write_matrix_s,
		reset_matrix => reset_matrix_s,
		enable_matrix => enable_matrix_s,
		enable_latch => enable_latch_s,
		row_change => row_changed
	);

	matrix_oe <= not enable_matrix_s;--its active low
	matrix_lat <= enable_latch_s;
	matrix_clk <= clk;
	status_register <= (0 => enable_matrix_s, 1 => write_done_s, others => '0');
end architecture;