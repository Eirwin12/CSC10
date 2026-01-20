-- altera vhdl_input_version vhdl_2008
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg32_avalon_interface is
	port (
		clock, reset : in std_logic;
		read, write, chipselect : in std_logic;
		readdata : out std_logic_vector(31 downto 0);
		writedata : in std_logic_vector(31 downto 0);
		byteenable : in std_logic_vector(3 downto 0);
		address    : in std_logic_vector(3 downto 0);
		Q_export : out std_logic_vector(31 downto 0)
	);
end reg32_avalon_interface;

architecture rtl of reg32_avalon_interface is
	constant AMOUNT_REGISTERS: natural := 7;
	constant LAST_REGISTER_INDEX: natural := AMOUNT_REGISTERS-1;
	type registers is array (0 to AMOUNT_REGISTERS-1) of std_logic_vector(31 downto 0);
	signal regs: registers;
	
	component matrix_top is
		port (
			  clk, rst: in std_ulogic;
			  control_register	: inout std_logic_vector(31 downto 0);
			  red_vector_read		: out std_logic_vector(31 downto 0);
			  blue_vector_read	: out std_logic_vector(31 downto 0);
			  green_vector_read	: out std_logic_vector(31 downto 0);
			  
			  red_vector_write	: in std_logic_vector(31 downto 0);
			  blue_vector_write	: in std_logic_vector(31 downto 0);
			  green_vector_write	: in std_logic_vector(31 downto 0);
			  
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
	end component;
	
	signal export_matrix: std_logic_vector(31 downto 0);
begin
	process(clock, reset)
		variable address_value: integer range 0 to 7;
	begin
		if reset then
			for i in 0 to LAST_REGISTER_INDEX loop
				regs(i) <= (others => '0');
			end loop;
		elsif rising_edge(clock) then
			if chipselect then
				address_value := to_integer(unsigned(address));
				if read then
					readdata <= regs(0);
				elsif write then
					if byteenable(0) then
						regs(address_value)(7 downto 0) <= writedata(7 downto 0);
					end if;
					if byteenable(1) then
						regs(address_value)(15 downto 8) <= writedata(15 downto 8);
					end if;
					if byteenable(2) then
						regs(address_value)(23 downto 16) <= writedata(23 downto 16);
					end if;
					if byteenable(3) then
						regs(address_value)(31 downto 24) <= writedata(31 downto 24);
					end if;
				end if;
			end if;
		end if;
	end process;
	
	Q_export <= export_matrix;
	matrix: matrix_top 
	port map(
		clk => clock,
		rst => reset, 
		control_register => regs(3),
		red_vector_read => regs(0),
		blue_vector_read  => regs(1),
		green_vector_read => regs(2),
		red_vector_write   => regs(4),
		blue_vector_write  => regs(5),
		green_vector_write => regs(6),

		matrix_r1 => export_matrix(0),
		matrix_g1 => export_matrix(1),
		matrix_b1 => export_matrix(2),
		matrix_r2 => export_matrix(3),
		matrix_g2 => export_matrix(4),
		matrix_b2 => export_matrix(5),
		matrix_addr_a => export_matrix(6),
		matrix_addr_b => export_matrix(7),
		matrix_addr_c => export_matrix(8),
		matrix_addr_d => export_matrix(9),
		matrix_clk => export_matrix(10),
		matrix_lat => export_matrix(11),
		matrix_oe  => export_matrix(12)
		);
end architecture rtl;