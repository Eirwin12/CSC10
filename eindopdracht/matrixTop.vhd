
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
			  input1, input2, ...: in std_ulogic;
			  reset_buffer, reset_clk, freeze_matrix:  out std_ulogic
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
	
	signal reset_buf, reset_clock: std_ulogic;

begin

	matrix_com: rgb_framebuffer
	port map (
	
	);
	fsm: fsm_display
	port map (
	
		reset_buffer => reset_buf,,
		reset_clk => reset clock,
	);
	
	 matrix_clk: clock_divider
	 generic map (
		divisor => 25)
	 port map (
		input_clock => clock,
		reset => reset_clock,
		output_clock =>matrix_clk
	 );
end architecture;