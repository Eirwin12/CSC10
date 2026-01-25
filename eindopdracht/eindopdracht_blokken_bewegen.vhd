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
	 signal output_matrix_buffer: std_logic_vector(31 downto 0);

    -- Platform Designer component (gegenereerd als "eindopdracht") 
    component eindopdracht is
        port (
            clk_clk                : in  std_logic                     := 'X';             -- clk
            pio_buttons_export     : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- export
            pio_switches_export    : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- export
            pio_leds_export        : out std_logic_vector(9 downto 0);                     -- export
            matrix_output_readdata : out std_logic_vector(31 downto 0)                     -- readdata
        );
    end component eindopdracht;
begin
    u0 : component eindopdracht
        port map (
            clk_clk                => CLOCK_50,                --           clk.clk
            pio_buttons_export     => KEY,     --   pio_buttons.export
            pio_switches_export    => SW,    --  pio_switches.export
            pio_leds_export        => LEDR,        --      pio_leds.export
            matrix_output_readdata => output_matrix_buffer  -- matrix_output.readdata
        );
		GPIO_1(0) <= output_matrix_buffer(0);
		GPIO_1(1) <= output_matrix_buffer(1);
		GPIO_1(2) <= output_matrix_buffer(2);
		GPIO_1(4) <= output_matrix_buffer(3);
		GPIO_1(5) <= output_matrix_buffer(4);
		GPIO_1(6) <= output_matrix_buffer(5);
		GPIO_1(8) <= output_matrix_buffer(6);
		GPIO_1(9) <= output_matrix_buffer(7);
		GPIO_1(10) <= output_matrix_buffer(8);
		GPIO_1(11) <= output_matrix_buffer(9);
		GPIO_1(12) <= output_matrix_buffer(10);
		GPIO_1(13) <= output_matrix_buffer(11);
		GPIO_1(14) <= output_matrix_buffer(12);

end architecture structure;