library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity framebuffer_tb is
end entity;

architecture testbench of rgb_framebuffer is
	component rgb_framebuffer is
		port (
			clock           : in  std_logic;
			reset           : in  std_logic;
		  
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
	signal clock_tb, reset_tb: std_logic;
	signal red_vector, blue_vector, green_vector: std_logic_vector(31 downto 0);
	signal address_tb: std_logic_vector(4 downto 0);
	signal write_tb, write_done_tb, collumn_filled_tb, change_row_tb, enable_matrix_tb: std_logic;
	signal matrix_r1_tb, matrix_g1_tb, matrix_b1_tb, matrix_r2_tb, matrix_G2_tb, matrix_B2_tb: std_logic;
	signal matrix_addr_a_tb, matrix_addr_b_tb, matrix_addr_c_tb, matrix_addr_d_tb, 
begin
	dut: rgb_framebuffer
	port map(
		clock => clock_tb,
		reset => reset_tb,
		  
		  red_vector_write => red_vector,
		  blue_vector_write => blue_vector,
		  green_vector_write => green_vector,
		  address => address_tb,
		  write => write_tb,
		  write_done => write_done_tb
		  collumn_filled => collumn_filled_tb,
		  change_row => change_row_tb,
		  enable_matrix => enable_matrix_tb,
		  -- RGB Matrix Output Conduit
		  matrix_r1 => matrix_r1_tb,
		  matrix_g1 => matrix_g1_tb,
		  matrix_b1 => matrix_b1_tb,
		  matrix_r2 => matrix_r2_tb,
		  matrix_g2 => matrix_g2_tb,
		  matrix_b2 => matrix_b2_tb,
		  matrix_addr_a => matrix_addr_a_tb,
		  matrix_addr_b => matrix_addr_b_tb, 
		  matrix_addr_c => matrix_addr_c_tb, 
		  matrix_addr_d => matrix_addr_d_tb
	);

	process
	begin

		report "Test completed.";
		std.env.stop;
	end process;
end architecture;