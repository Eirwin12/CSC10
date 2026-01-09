-- altera vhdl_input_version vhdl_2008
library IEEE;
use IEEE.std_logic_1164.all;

entity reg32_avalon_interface is
	port (
		clock, resetn : in std_logic;
		read, write : in std_logic;
		chipselect_0, chipselect_1, chipselect_2, chipselect_3, chipselect_4, chipselect_5: in std_logic;
		readdata     : out std_logic_vector(31 downto 0);
		writedata    : in  std_logic_vector(31 downto 0);
		byteenable   : in  std_logic_vector( 3 downto 0);
		Q_export_r_0 : out std_logic_vector(31 downto 0);
		Q_export_g_0 : out std_logic_vector(31 downto 0);
		Q_export_b_0 : out std_logic_vector(31 downto 0);
		Q_export_r_1 : out std_logic_vector(31 downto 0);
		Q_export_g_1 : out std_logic_vector(31 downto 0);
		Q_export_b_1 : out std_logic_vector(31 downto 0)
	);
end reg32_avalon_interface;

architecture rtl of reg32_avalon_interface is
	type registers is array (0 to 5) of std_logic_vector(31 downto 0);
	signal regs: registers;
	procedure read_write_reg(signal writedata: in std_logic_vector(31 downto 0);
								  signal register_number: in unsigned(4 downto 0);
								  signal read: in std_logic;
								  signal write: in std_logic;
								  signal byteenable: in std_logic_vector (3 downto 0);
								  signal readdata: out std_logic_vector(31 downto 0);
								  signal reg: out registers) is
	begin
		if read then 
			readdata <= reg(register_number);
		elsif write then
			--hoe werkt het met de regs ook alweer?
			if byteenable(0) then
				reg(register_number)(7 downto 0) <= writedata(7 downto 0);
			end if;
			if byteenable(1) then
				reg(register_number)(15 downto 8) <= writedata(15 downto 8);
			end if;
			if byteenable(2) then
				reg(register_number)(23 downto 16) <= writedata(23 downto 16);
			end if;
			if byteenable(3) then
				reg(register_number)(31 downto 24) <= writedata(31 downto 24);
			end if;
		end if;
	end procedure;
	
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
	signal reset : std_logic;
begin
	reset => not(resetn);--1 is reset, 0 is geen reset. 
	process(clock, resetn)
	begin
		if not resetn then
			for i in 0 to 5 loop
				regs(i) <= (others => '0');
			end loop;
		elsif rising_edge(clock) then
			if chipselect_0 then
				read_write_reg(writedata, 0, read, write, byteenable, readdata, regs);
			end if;
			if chipselect_1 then
				read_write_reg(writedata, 1, read, write, byteenable, readdata, regs);
			end if;
			if chipselect_2 then
				read_write_reg(writedata, 2, read, write, byteenable, readdata, regs);
			end if;
			if chipselect_3 then
				read_write_reg(writedata, 3, read, write, byteenable, readdata, regs);
			end if;
			if chipselect_4 then
				read_write_reg(writedata, 4, read, write, byteenable, readdata, regs);
			end if;
			if chipselect_5 then
				read_write_reg(writedata, 5, read, write, byteenable, readdata, regs);
			end if;
		end if;
	end process;
	Q_export_r_0 <= regs(0);
	Q_export_g_0 <= regs(1);
	Q_export_b_0 <= regs(2);
	Q_export_r_1 <= regs(3);
	Q_export_g_1 <= regs(4);
	Q_export_b_1 <= regs(5);
	matrix: rgb_framebuffer 
	port map(
		clock => clock,
		reset => reset, 
		red_vector_0   => v,
		blue_vector_0  => v,
		grean_vector_0 => v,
		red_vector_1   => v,
		blue_vector_1  => v,
		green_vector_1 => v,
		--outputs
		--hoe doen we dit?
		);
end architecture rtl;