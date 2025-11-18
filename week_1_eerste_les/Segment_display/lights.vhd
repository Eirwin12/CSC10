-- filepath: c:\Users\mitch\Documents\GitHub\CSC10\week_1_eerste_les\Segment_display\lights.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY lights IS
PORT (
    CLOCK_50 : IN STD_LOGIC;
    KEY      : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    HEX0     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    HEX1     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    HEX2     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    HEX3     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    HEX4     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    HEX5     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
);
END lights;

ARCHITECTURE lights_rtl OF lights IS
    COMPONENT nois_system 
        PORT (
            clk_clk                                    : IN  STD_LOGIC;
            reset_reset_n                              : IN  STD_LOGIC;
            hex3_hex0_external_connection_export       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); 
            hex5_hex4_external_connection_export       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)  
        );
    END COMPONENT;
    
    SIGNAL hex_combined : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL hex_extra    : STD_LOGIC_VECTOR(15 DOWNTO 0);
    
BEGIN
    NiosII : nois_system
    PORT MAP(
        clk_clk                              => CLOCK_50,
        reset_reset_n                        => KEY(0), 
        hex3_hex0_external_connection_export => hex_combined,
        hex5_hex4_external_connection_export => hex_extra
    );
    
    HEX0 <= hex_combined(6 DOWNTO 0);
    HEX1 <= hex_combined(14 DOWNTO 8);
    HEX2 <= hex_combined(22 DOWNTO 16);
    HEX3 <= hex_combined(30 DOWNTO 24);
    HEX4 <= hex_extra(6 DOWNTO 0);
    HEX5 <= hex_extra(14 DOWNTO 8);
    
END lights_rtl;