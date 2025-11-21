LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY bst_7_segment IS
	PORT ( CLOCK_50 : IN STD_LOGIC;
	KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	HEX0 : OUT STD_LOGIC_VECTOR(6 downto 0);
	HEX1 : OUT STD_LOGIC_VECTOR(6 downto 0);
	HEX2 : OUT STD_LOGIC_VECTOR(6 downto 0);
	HEX3 : OUT STD_LOGIC_VECTOR(6 downto 0));
	END bst_7_segment;

ARCHITECTURE Structure OF bst_7_segment IS
	COMPONENT embedded_system IS
	PORT ( 
		clk_clk             : in  std_logic                     := '0'; --        clk.clk
		reset_reset_n       : in  std_logic                     := '0'; --      reset.reset_n
		to_display_1_readdata : out std_logic_vector(55 downto 0);        -- to_display.readdata
		to_hex_readdata     : out std_logic_vector(31 downto 0));         --     to_hex.readdata
	END COMPONENT embedded_system;
BEGIN

	U0: embedded_system PORT MAP (
	clk_clk => CLOCK_50,
	reset_reset_n => KEY(0),
	to_hex_readdata => open,
	to_display_1_readdata(6 downto 0) => hex0,
	to_display_1_readdata(13 downto 7) => hex1,
	to_display_1_readdata(20 downto 14) => hex2,
	to_display_1_readdata(27 downto 21) => hex3,
	to_display_1_readdata(55 downto 28) => open);

END Structure;