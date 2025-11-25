LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY bst_7_segment IS
	PORT ( CLOCK_50 : IN STD_LOGIC;
	KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	HEX0 : OUT STD_LOGIC_VECTOR(0 to 6);
	HEX1 : OUT STD_LOGIC_VECTOR(0 to 6);
	HEX2 : OUT STD_LOGIC_VECTOR(0 to 6);
	HEX3 : OUT STD_LOGIC_VECTOR(0 to 6);
	HEX4 : OUT STD_LOGIC_VECTOR(0 to 6);
	HEX5 : OUT STD_LOGIC_VECTOR(0 to 6));
	END bst_7_segment;

ARCHITECTURE Structure OF bst_7_segment IS
	SIGNAL to_HEX : STD_LOGIC_VECTOR(31 DOWNTO 0);
	COMPONENT embedded_system IS
	port (
		clk_clk             : in  std_logic                     := '0'; --        clk.clk
		reset_reset_n       : in  std_logic                     := '0'; --      reset.reset_n
		to_hex_lsb_readdata : out std_logic_vector(31 downto 0);        -- to_hex_lsb.readdata
		to_hex_msb_readdata : out std_logic_vector(31 downto 0)         -- to_hex_msb.readdata
	);
	END COMPONENT embedded_system;
BEGIN

	U0: embedded_system PORT MAP (
	clk_clk => CLOCK_50,
	reset_reset_n => KEY(0),
	to_hex_lsb_readdata(6 downto 0) =>   HEX0,
	to_hex_lsb_readdata(13 downto 7) =>  HEX1,
	to_hex_lsb_readdata(20 downto 14) => HEX2,
	to_hex_lsb_readdata(27 downto 21) => HEX3,
	to_hex_msb_readdata(6 downto 0) =>   HEX4,
	to_hex_msb_readdata(13 downto 7) =>  HEX5);
END Structure;