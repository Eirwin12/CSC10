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
	constant AMOUNT_REGISTERS: natural := 6;
	
	type registers is array (0 to AMOUNT_REGISTERS) of std_logic_vector(31 downto 0);
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
	
	component matrix_top is
		port (
		  -- Clock en Reset (Platform Designer interface names)
		  clock           	: in  std_logic;
		  reset           	: in  std_logic;
		  control_register	: in std_ulogic_vector(31 downto 0);
		  red_vector_read		: out std_logic_vector(31 downto 0);
		  blue_vector_read	: out std_logic_vector(31 downto 0);
		  green_vector_read	: out std_logic_vector(31 downto 0);
		  
		  red_vector_write	: in std_logic_vector(31 downto 0);
		  blue_vector_write	: in std_logic_vector(31 downto 0);
		  green_vector_write	: in std_logic_vector(31 downto 0);
		  
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
		  matrix_addr_d : out std_logic;
		  matrix_clk    : out std_logic;
		  matrix_lat    : out std_logic;
		  matrix_oe_n   : out std_logic
		);
	end component;
	
	signal reset_s : std_logic;
	signal export_matrix: std_logic_vector(12 downto 0);
begin
	reset_s => not(resetn);--1 is reset, 0 is geen reset. 
	process(clock, reset_s)
	begin
		if reset_s then
			for i in 0 to AMOUNT_REGISTERS loop
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
			if chipselect_6 then
				read_write_reg(writedata, 6, read, write, byteenable, readdata, regs);
			end if;
		end if;
	end process;
	
	--register 3 is voor data lezen of versturen. zie het als de controle register
	--1 bit voor lezen/schrijven
	--4 bits voor welke rij geschreven/gelezen wordt
	--1 bit voor start
	--1 bit (software) reset
	
	--bit 16 tot 19 voor de rij definiëren
	--bit1 is start
	--bit2 reset
	--bit3 is lezen/schrijven
	
	--afspreken 0 t/m 2 zijn voor schrijven
	--afspreken 4 t/m 6 is voor lezen. 
	
	Q_export_r_0 <= export_matrix(0);
	matrix: matrix_top 
	port map(
		clock => clock,
		reset => reset, 
		control_register => reg(3),
		red_vector_read => reg(0),
		blue_vector_read  => reg(1),
		green_vector_read => reg(2),
		red_vector_write   => reg(4),
		blue_vector_write  => reg(5),
		green_vector_write => reg(6),

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
		matrix_oe_n => export_matrix(12),
		--outputs
		--hoe doen we dit?
		);
end architecture rtl;