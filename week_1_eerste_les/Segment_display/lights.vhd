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
			pio_in_segment_external_connection_export  : in  std_logic_vector(3 downto 0) := (others => '0'); --  pio_in_segment_external_connection.export
			pio_out_segment_external_connection_export : out std_logic_vector(6 downto 0) 
				);
	END COMPONENT;
BEGIN
NiosII_HEX0 : nois_system
PORT MAP(
		clk_clk => CLOCK_50,
		reset_reset_n => '1',
		pio_in_segment_external_connection_export => OPEN,
		pio_out_segment_external_connection_export => HEX0
			);
			
NiosII_HEX1 : nois_system
PORT MAP(
		clk_clk => CLOCK_50,
		reset_reset_n => '1',
		pio_in_segment_external_connection_export => OPEN,
		pio_out_segment_external_connection_export => HEX1
			);
NiosII_HEX2 : nois_system
PORT MAP(
		clk_clk => CLOCK_50,
		reset_reset_n => '1',
		pio_in_segment_external_connection_export => OPEN,
		pio_out_segment_external_connection_export => HEX2
			);
NiosII_HEX3 : nois_system
PORT MAP(
		clk_clk => CLOCK_50,
		reset_reset_n => '1',
		pio_in_segment_external_connection_export => OPEN,
		pio_out_segment_external_connection_export => HEX3
			);
			
NiosII_HEX4 : nois_system
PORT MAP(
		clk_clk => CLOCK_50,
		reset_reset_n => '1',
		pio_in_segment_external_connection_export => OPEN,
		pio_out_segment_external_connection_export => HEX4
			);
			
NiosII_HEX5 : nois_system
PORT MAP(
		clk_clk => CLOCK_50,
		reset_reset_n => '1',
		pio_in_segment_external_connection_export => OPEN,
		pio_out_segment_external_connection_export => HEX5
			);
END lights_rtl;