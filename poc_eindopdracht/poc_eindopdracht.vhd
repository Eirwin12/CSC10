library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity poc_eindopdracht is
    port (
        -- Clock
        CLOCK_50 : in std_logic;
        
        -- Keys (active low)
        KEY : in std_logic_vector(3 downto 0);
        
        -- Switches
        SW : in std_logic_vector(9 downto 0);
        
        -- LEDs (voor debugging)
        LEDR : out std_logic_vector(9 downto 0);
        
        -- GPIO1 (JP2) voor RGB Matrix
        GPIO_1 : inout std_logic_vector(34 downto 0)
    );
end;

architecture imp of poc_eindopdracht is
	
	component top is
		port (
        clk, rst: in std_ulogic;
		  control_register	: inout std_logic_vector(31 downto 0);
		  switches: in std_logic_vector(2 downto 0);
		  
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
	component clock_divider is
		generic(
			divisor: natural := 50e6--deling om van 50MHz naar 1Hz
		);
		port(
			input_clock: in std_ulogic;
			reset: in std_ulogic;
			output_clock: out std_ulogic
		);
	end component;
	signal matrix_clk: std_ulogic;
	signal matrix_addr: std_ulogic_vector(3 downto 0);
begin
	matrix_com: top
	port map(
		clk => matrix_clk,
		rst => KEY(0), 
		control_register => 32x"1",
		switches => SW(2 downto 0),

		matrix_r1 => GPIO_1(0),
		matrix_g1 => GPIO_1(1),
		matrix_b1 => GPIO_1(2),
		matrix_r2 => GPIO_1(3),
		matrix_g2 => GPIO_1(4),
		matrix_b2 => GPIO_1(5),
		matrix_addr_a => matrix_addr(0),
		matrix_addr_b => matrix_addr(1),
		matrix_addr_c => matrix_addr(2),
		matrix_addr_d => matrix_addr(3),
		matrix_clk => GPIO_1(10),
		matrix_lat => GPIO_1(11),
		matrix_oe  => GPIO_1(12)
	);
		
	klok: clock_divider
	generic map (
		divisor => 50)
	port map (
		input_clock => clock_50,
		reset => key(0),
		output_clock => matrix_clk
	);
	process(matrix_clk)
	begin
		if rising_edge(matrix_clk) then
			LEDR(2 downto 0) <= SW(2 downto 0);
			LEDR(6 downto 3) <= std_logic_vector(matrix_addr);
		end if;
	end process;
	
		GPIO_1(6) <= matrix_addr(1);
		GPIO_1(7) <= matrix_addr(1);
		GPIO_1(8) <= SW(5);
		GPIO_1(9) <= SW(6);
end architecture;