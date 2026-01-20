library IEEE;
use IEEE.std_logic_1164.all;

entity eindopdracht_blokken_bewegen is
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
end entity eindopdracht_blokken_bewegen;

architecture structure of eindopdracht_blokken_bewegen is

    -- Platform Designer component (gegenereerd als "eindopdracht") 
    component eindopdracht is
        port (
            clk_clk                                 : in  std_logic                     := 'X';             -- clk
            pio_buttons_external_connection_export  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- export
            pio_switches_external_connection_export : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- export
            matrix_connection_readdata              : out std_logic_vector(31 downto 0)                     -- readdata
        );
    end component eindopdracht;
	 signal output_matrix_buffer: std_ulogic_vector( 31 downto 0);
begin

    u0 : component eindopdracht
        port map (
            clk_clk                                 => ClOCK_50,                                 --                              clk.clk
            pio_buttons_external_connection_export  => KEY,  --  pio_buttons_external_connection.export
            pio_switches_external_connection_export => SW, -- pio_switches_external_connection.export
            matrix_connection_readdata              => output_matrix_buffer               --                matrix_connection.readdata
        );
	 GPIO_1(12 downto 0) <= output_matrix_buffer(12 downto 0);

end architecture structure;