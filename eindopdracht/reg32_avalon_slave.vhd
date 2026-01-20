-- altera vhdl_input_version vhdl_2008
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg32_avalon_interface is
	port (
		clock, reset : in std_logic;
		read_0, read_1, read_2, read_3, read_4, read_5, read_6: in std_logic;
		write_0, write_1, write_2, write_3, write_4, write_5, write_6: in std_logic;
		chipselect_0, chipselect_1, chipselect_2, chipselect_3, chipselect_4, chipselect_5, chipselect_6: in std_logic;
		readdata_0, readdata_1, readdata_2, readdata_3, readdata_4, readdata_5, readdata_6: out std_logic_vector(31 downto 0);
		writedata_0, writedata_1, writedata_2, writedata_3, writedata_4, writedata_5, writedata_6: in  std_logic_vector(31 downto 0);
		byteenable_0, byteenable_1, byteenable_2, byteenable_3, byteenable_4, byteenable_5, byteenable_6: in  std_logic_vector( 3 downto 0);
		Q_export_matrix : out std_logic_vector(31 downto 0)
	);
end reg32_avalon_interface;

architecture rtl of reg32_avalon_interface is
	constant AMOUNT_REGISTERS: natural := 7;
	type logic_vector_vector is array(natural range<>) of std_logic_vector;
	type registers is array (0 to AMOUNT_REGISTERS-1) of std_logic_vector(31 downto 0);
	signal regs: registers;
	procedure read_write_reg(constant register_number: in integer;
								  signal read: in std_logic_vector;
								  signal write: in std_logic_vector;
								  signal writedata: in logic_vector_vector;
								  signal byteenable: in logic_vector_vector;
								  signal readdata: out logic_vector_vector;
								  signal reg: inout registers) is
	begin
		if read(register_number) then 
			readdata(register_number) <= reg(register_number);
		elsif write(register_number) then
			if byteenable(register_number)(0) then
				reg(register_number)(7 downto 0) <= writedata(register_number)(7 downto 0);
			end if;
			if byteenable(register_number)(1) then
				reg(register_number)(15 downto 8) <= writedata(register_number)(15 downto 8);
			end if;
			if byteenable(register_number)(2) then
				reg(register_number)(23 downto 16) <= writedata(register_number)(23 downto 16);
			end if;
			if byteenable(register_number)(3) then
				reg(register_number)(31 downto 24) <= writedata(register_number)(31 downto 24);
			end if;
		end if;
	end procedure;
	
	component matrix_top is
		port (
        clock, reset: in std_ulogic;
		  control_register	: inout std_logic_vector(31 downto 0);
		  red_vector_read		: in std_logic_vector(31 downto 0);
		  blue_vector_read	: in std_logic_vector(31 downto 0);
		  green_vector_read	: in std_logic_vector(31 downto 0);
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
	signal read: std_logic_vector(6 downto 0);
	signal write: std_logic_vector(6 downto 0);
	signal chipselect: std_logic_vector(6 downto 0);
	signal readdata: logic_vector_vector(6 downto 0)(31 downto 0);
	signal writedata: logic_vector_vector(6 downto 0)(31 downto 0);
	signal byteenable: logic_vector_vector(6 downto 0)(3 downto 0);
begin
	read <= (read_0, read_1, read_2, read_3, read_4, read_5, read_6);
	write <= (write_0, write_1, write_2, write_3, write_4, write_5, write_6);
	chipselect <= (chipselect_0, chipselect_1, chipselect_2, chipselect_3, chipselect_4, chipselect_5, chipselect_6);
	readdata <= (readdata_0, readdata_1, readdata_2, readdata_3, readdata_4, readdata_5, readdata_6);
	writedata <= (writedata_0, writedata_1, writedata_2, writedata_3, writedata_4, writedata_5, writedata_6);
	byteenable <= (byteenable_0, byteenable_1, byteenable_2, byteenable_3, byteenable_4, byteenable_5, byteenable_6);
	process(clock, reset)
	begin
		if reset then
			for i in 0 to AMOUNT_REGISTERS loop
				regs(i) <= (others => '0');
			end loop;
		elsif rising_edge(clock) then
			for i in chipselect'range loop
				if chipselect(i) then
					read_write_reg(i, read, write, writedata, readdata, byteenable, regs);
				end if;
			end loop;
		end if;
	end process;
	
	Q_export_matrix <= export_matrix;
	matrix: matrix_top 
	port map(
		clock => clock,
		reset => reset, 
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