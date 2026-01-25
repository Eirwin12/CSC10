-- ============================================================================
-- DE1-SoC Top Level voor Matrix32 LED Controller met Platform Designer
-- Cyclone V 5CSEMA5F31C6N
-- ============================================================================
-- Dit bestand integreert:
--   - Nios II systeem (gegenereerd door Platform Designer)
--   - 32x32 RGB LED Matrix controller via GPIO_1
--   - Clock, reset, en LEDs voor debug
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity eindopdracht_blokken_bewegen is
    Port (
        -- ==================================================================
        -- Clock Input
        -- ==================================================================
        CLOCK_50   : in    std_logic;  -- 50 MHz systeem clock
        
        -- ==================================================================
        -- Buttons and Switches
        -- ==================================================================
        KEY        : in    std_logic_vector(3 downto 0);   -- Push buttons (active low)
        SW         : in    std_logic_vector(9 downto 0);   -- Slide switches
        
        LEDR       : out   std_logic_vector(9 downto 0);   -- Red LEDs
        
        -- ==================================================================
        -- GPIO Header 1 - LED Matrix Connection
        -- ==================================================================
        GPIO_1     : inout std_logic_vector(14 downto 0)   -- GPIO_1[14:0] voor LED matrix
    );
end entity;

architecture Behavioral of eindopdracht_blokken_bewegen is
    

    component eindopdracht is
        port (
            clk_clk             : in  std_logic                     := 'X';             -- clk
            output_data         : out std_logic_vector(31 downto 0);                    -- data
            pio_buttons_export  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- export
            pio_leds_export     : out std_logic_vector(9 downto 0);                     -- export
            pio_switches_export : in  std_logic_vector(9 downto 0)  := (others => 'X')  -- export
        );
    end component eindopdracht;

	 signal output: std_logic_vector(31 downto 0);
    
begin

    u0 : component eindopdracht
        port map (
            clk_clk             => CLOCK_50,             --          clk.clk
            output_data         => output,     --   matrix_out.data
            pio_buttons_export  => KEY,  --  pio_buttons.export
            pio_leds_export     => ledr,     --     pio_leds.export
            pio_switches_export => SW  -- pio_switches.export
        );
    --pinnen 3 en 7 worden niet gebruikt, zodat het aansluiten met matrix makkelijker gaat. 
	 gpio_1(0) <= output(0);
	 gpio_1(1) <= output(1);
	 gpio_1(2) <= output(2);
	 gpio_1(4) <= output(3);
	 gpio_1(5) <= output(4);
	 gpio_1(6) <= output(5);
	 gpio_1(8) <= output(6);
	 gpio_1(9) <= output(7);
	 gpio_1(10) <= output(8);
	 gpio_1(11) <= output(9);
	 gpio_1(12) <= output(10);
	 gpio_1(13) <= output(11);
	 gpio_1(14) <= output(12);

end Behavioral;
