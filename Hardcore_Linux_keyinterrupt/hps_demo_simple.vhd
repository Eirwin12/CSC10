library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Eenvoudige top-level entity met ALLEEN FPGA pins
-- HPS I/O wordt automatisch behandeld door de HPS component
entity hps_demo_simple is
    port (
        -- Clock input
        CLOCK_50 : in  std_logic;
        
        -- KEY buttons (active low)
        KEY      : in  std_logic_vector(3 downto 0);
        
        -- LED outputs
        LEDR     : out std_logic_vector(3 downto 0)
    );
end entity hps_demo_simple;

architecture rtl of hps_demo_simple is
    
    -- Component declaration voor Platform Designer systeem
    -- LET OP: De HPS I/O signalen worden NIET verbonden in deze top-level!
    -- Die worden intern door de HPS component behandeld.
    component Hardcore_linux_interrupt is
        port (
            clk_clk         : in  std_logic;
            switches_export : in  std_logic_vector(3 downto 0);
            leds_export     : out std_logic_vector(3 downto 0);
            reset_reset_n   : in  std_logic
        );
    end component Hardcore_linux_interrupt;
    
    signal reset_n : std_logic := '1';  -- Active high (niet gebruikt, maar vereist)
    
begin

    -- Instantiate Platform Designer system
    u0 : component Hardcore_linux_interrupt
        port map (
            clk_clk         => CLOCK_50,
            switches_export => KEY,
            leds_export     => LEDR,
            reset_reset_n   => reset_n
        );

end architecture rtl;
