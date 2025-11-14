-- Implements a simple Nios II system for the DE-series board.
-- Inputs: SW7-0 are parallel port inputs to the Nios II system
-- CLOCK_50 is the system clock
-- KEY0 is the active-low system reset
-- Outputs: LEDR7-0 are parallel port outputs from the Nios II system
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
ENTITY lights IS
PORT (
	CLOCK_50 : IN STD_LOGIC;
	HEX0: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX1: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX2: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX3: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX4: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX5: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	
);
END lights;
ARCHITECTURE lights_rtl OF lights IS
	COMPONENT nois_system
		PORT (
			clk_clk: IN STD_LOGIC;
			reset_reset_n : IN STD_LOGIC;
			left_3_hex_export  : out  std_logic_vector(20 downto 0); --  pio_in_segment_external_connection.export
			right_3_hex_export : out std_logic_vector(20 downto 0) 
				);
	END COMPONENT;
	signal hex5_3: std_logic_vector(20 downto 0);
	signal hex2_0: std_logic_vector(20 downto 0);
BEGIN
NiosII_HEX5_3 : nois_system
PORT MAP(
		clk_clk => CLOCK_50,
		reset_reset_n => '1',
		left_3_hex_export => hex5_3,
		right_3_hex_export => hex2_0
			);
		hex5 <= hex5_3(20 downto 14);
		hex4 <= hex5_3(13 downto 7);
		hex3 <= hex5_3(6 downto 0);
		hex2 <= hex2_0(20 downto 14);
		hex1 <= hex2_0(13 downto 7);
		hex0 <= hex2_0(6 downto 0);
END lights_rtl;