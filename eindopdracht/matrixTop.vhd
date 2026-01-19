
entity matrix_top is
	port (
        clk, rst: in std_ulogic;
		  red_vector_0		: in std_logic_vector(31 downto 0);
		  blue_vector_0	: in std_logic_vector(31 downto 0);
		  green_vector_0	: in std_logic_vector(31 downto 0);
		  
		  red_vector_1		: in std_logic_vector(31 downto 0);
		  blue_vector_1	: in std_logic_vector(31 downto 0);
		  green_vector_1	: in std_logic_vector(31 downto 0);
		  
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
		  matrix_clk    : out std_logic;
		  matrix_lat    : out std_logic;
		  matrix_oe_n   : out std_logic
		);
    );
end;

architecture imp of matrix_top is
	component rgb_framebuffer is
		port (
		  -- Clock en Reset (Platform Designer interface names)
		  clock           : in  std_logic;
		  reset           : in  std_logic;
		  red_vector_0		: in std_logic_vector(31 downto 0);
		  blue_vector_0	: in std_logic_vector(31 downto 0);
		  green_vector_0	: in std_logic_vector(31 downto 0);
		  
		  red_vector_1		: in std_logic_vector(31 downto 0);
		  blue_vector_1	: in std_logic_vector(31 downto 0);
		  green_vector_1	: in std_logic_vector(31 downto 0);
		  
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
		  matrix_clk    : out std_logic;
		  matrix_lat    : out std_logic;
		  matrix_oe_n   : out std_logic
		);
	end component;
	
	component fsm_display is
		port (
			  clk, rst: in std_ulogic;
			  start_button, timer_repeated: in std_ulogic;
			  --matrix outputs
			  reset_matrix, enable_matrix, enable_change, enable_latch: out std_ulogic;
			  --external unit outputs. 
			  reset_clk, reset_counter, enable_counter: out std_ulogic;
		 );
	end component;
	
	component clock_divider is
		generic(
			divisor: natural--deling om van 50MHz naar 1Hz
		);
		port(
			input_clock: in std_ulogic;
			reset: in std_ulogic;
			output_clock: out std_ulogic
		);
	end component;
	
	--houdt bij machten van 2, was wat AI had gedaan, maar kan in principe welke waarde dat gewild wordt
	constant brightness: unsigned := 32;
	component counter is
		generic (max_count: natural);
		port(
			klok, reset, enable: in std_ulogic;
			count: out std_ulogic_vector(7 downto 0);
			count_done: out std_ulogic
		);
	end component;
	--tijdelijke signalen. hoort in de entity declaratie
	signal start: std_ulogic;
	
	signal repeated_count: std_ulogic;
	
	signal reset_matrix_s, enable_matrix_s, enable_change_s, enable_latch_s: out std_ulogic;
	signal reset_clock_s, reset_counter_s, enable_counter_s: std_ulogic;

begin

	matrix_com: rgb_framebuffer
	port map (
	
	);
	fsm: fsm_display
	port map (
		clk => clk,
		rst => rst,
		start_button => start,
		timer_repeated => repeated_count,
		
		reset_matrix => reset_matrix_s,
		enable_matrix => enable_matrix_s,
		enable_change => enable_change_s,
		enable_latch => enable_latch_s,
		reset_clk => reset_clock_s,
		reset_counter => reset_counter_s,
		enable_counter => enable_counter_s
	);
	
	 matrix_clock: clock_divider
	 generic map (
		divisor => 25)
	 port map (
		input_clock => clk,
		reset => reset_clock_s,
		output_clock =>matrix_clk
	 );
	 brightness_control: counter
	 generic map (max_count => brightness)
	 port map (
		klok => clk, 
		reset => reset_clock_s, 
		enable => enable_counter_s,
		count => open,
		count_done => repeated_count
	);
end architecture;