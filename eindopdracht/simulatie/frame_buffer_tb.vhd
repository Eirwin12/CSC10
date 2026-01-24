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
	signal clock_tb, reset_tb: std_logic:= '0';
	signal red_vector, blue_vector, green_vector: std_logic_vector(31 downto 0);
	signal address_tb: std_logic_vector(0 to 3);
	signal write_tb, write_done_tb, collumn_filled_tb, change_row_tb, enable_matrix_tb: std_logic;
	signal matrix_r1_tb, matrix_g1_tb, matrix_b1_tb, matrix_r2_tb, matrix_G2_tb, matrix_B2_tb: std_logic;
	signal matrix_addr_a_tb, matrix_addr_b_tb, matrix_addr_c_tb, matrix_addr_d_tb: std_logic;
	constant clock_cycle: time := 20 ns;
	signal matrix_address: std_logic_vector(3 downto 0);
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
	matrix_address <= (matrix_addr_a_tb, matrix_addr_b_tb, matrix_addr_c_tb, matrix_addr_d_tb);
	clock_tb <= clock_tb xor '1' after clock_cycle/2;
	process
	begin
		enable_matrix_tb <= '1';
		--enable the matrix en check de output. 
		for i in 0 to 30 loop
			wait for clock_cycle;
			assert matrix_r1_tb = '1' report "first red pixel in index " & to_string(i) & " isn't the correct value" severity error;
			assert matrix_g1_tb = '0' report "first green pixel in index " & to_string(i) & " isn't the correct value" severity error;
			assert matrix_b1_tb = '1' report "first blue pixel in index " & to_string(i) & " isn't the correct value" severity error;
			assert matrix_r2_tb = '1' report "second red pixel in index " & to_string(i) & " isn't the correct value" severity error;
			assert matrix_g2_tb = '0' report "second green pixel in index " & to_string(i) & " isn't the correct value" severity error;
			assert matrix_b2_tb = '1' report "second blue pixel in index " & to_string(i) & " isn't the correct value" severity error;

			assert matrix_address = 4x"0" report "address isn't 0 at start or changed to " & to_string(address) severity warning;
		end loop;
		wait for clock_cycle;
		assert matrix_r1_tb = '1' report "first red pixel in index " & to_string(i) & " isn't the correct value" severity error;
		assert matrix_g1_tb = '1' report "first green pixel in index " & to_string(i) & " isn't the correct value" severity error;
		assert matrix_b1_tb = '1' report "first blue pixel in index " & to_string(i) & " isn't the correct value" severity error;
		assert matrix_r2_tb = '1' report "second red pixel in index " & to_string(i) & " isn't the correct value" severity error;
		assert matrix_g2_tb = '1' report "second green pixel in index " & to_string(i) & " isn't the correct value" severity error;
		assert matrix_b2_tb = '1' report "second blue pixel in index " & to_string(i) & " isn't the correct value" severity error;
		assert collumn_filled = '1' report "collumn_filled isn't coming on time" severity error;
		
		--write a value to the 3rd vector
		write_tb <= '1';
		address_tb <= 5x"3";
		red_vector <= ('1', others => '0');
		blue_vector <= (2 => '1', others => '0');
		green_vector <= (others => '1');
		--while doing this, we are going to change the row
		change_row <= '1';
		wait for clock_cycle;
		assert write_done_tb = '1' report "write isn't done, while ;
		for i in 0 to 31 loop
			wait for clock_cycle;
			assert matrix_r1_tb = '1' report "first red pixel in index " & to_string(i) & " isn't the correct value" severity error;
			assert matrix_g1_tb = '0' report "first green pixel in index " & to_string(i) & " isn't the correct value" severity error;
			assert matrix_b1_tb = '1' report "first blue pixel in index " & to_string(i) & " isn't the correct value" severity error;

		end loop;
		for i in 0 to 31 loop
			wait for clock_cycle;
		end loop;
		report "Test completed.";
		std.env.stop;
	end process;
end architecture;