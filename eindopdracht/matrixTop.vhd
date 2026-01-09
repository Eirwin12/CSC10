
entity matrix_top is
	port (
        clk, rst: in std_ulogic;
        input1, input2, ...: in std_ulogic;
        reset_buffer, output2, ...: out std_ulogic
    );
end matrix_top;

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
	
	
	entity fsm_display is
		port (
			  clk, rst: in std_ulogic;
			  input1, input2, ...: in std_ulogic;
			  reset_buffer, output2, ...: out std_ulogic
		);
	end fsm_display;
	
begin

end architecture;