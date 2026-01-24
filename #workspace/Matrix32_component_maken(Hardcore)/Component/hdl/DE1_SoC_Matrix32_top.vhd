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

entity DE1_SoC_Matrix32_top is
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
        
        -- ==================================================================
        -- LEDs (debug)
        -- ==================================================================
        LEDR       : out   std_logic_vector(9 downto 0);   -- Red LEDs
        
        -- ==================================================================
        -- GPIO Header 1 - LED Matrix Connection
        -- ==================================================================
        GPIO_1     : inout std_logic_vector(14 downto 0)   -- GPIO_1[14:0] voor LED matrix
    );
end DE1_SoC_Matrix32_top;

architecture Behavioral of DE1_SoC_Matrix32_top is
    
    -- ========================================================================
    -- Component Declarations
    -- ========================================================================
    
    -- Platform Designer systeem (gegenereerd uit soc_system.qsys)
    component soc_system is
        port (
            clk_clk             : in  std_logic;
            reset_reset_n       : in  std_logic;
            
            -- KEY buttons input (exported van pio_key)
            key_external_export : in  std_logic_vector(3 downto 0);
            
            -- Matrix LED Conduit (exported van matrix32_led_0)
            matrix_external_r1  : out std_logic;
            matrix_external_g1  : out std_logic;
            matrix_external_b1  : out std_logic;
            matrix_external_r2  : out std_logic;
            matrix_external_g2  : out std_logic;
            matrix_external_b2  : out std_logic;
            matrix_external_a   : out std_logic;
            matrix_external_b   : out std_logic;
            matrix_external_c   : out std_logic;
            matrix_external_d   : out std_logic;
            matrix_external_clk : out std_logic;
            matrix_external_lat : out std_logic;
            matrix_external_oe  : out std_logic
        );
    end component;
    
    -- ========================================================================
    -- Internal Signals
    -- ========================================================================
    signal reset_n : std_logic;
    
begin
    
    -- ========================================================================
    -- Reset Logic
    -- KEY(0) is active-low reset button
    -- ========================================================================
    reset_n <= KEY(0);
    
    -- ========================================================================
    -- Platform Designer System Instantiation
    -- ========================================================================
    u0: soc_system
        port map (
            -- Clock and reset
            clk_clk             => CLOCK_50,
            reset_reset_n       => reset_n,
            
            -- KEY buttons (active low)
            key_external_export => KEY,
            
            -- Matrix LED signals → Direct naar GPIO_1 pins
            matrix_external_r1  => GPIO_1(0),   -- R1  (PIN_AB17)
            matrix_external_g1  => GPIO_1(1),   -- G1  (PIN_AA21)
            matrix_external_b1  => GPIO_1(2),   -- B1  (PIN_AB21)
            matrix_external_r2  => GPIO_1(4),   -- R2  (PIN_AD24)
            matrix_external_g2  => GPIO_1(5),   -- G2  (PIN_AE23)
            matrix_external_b2  => GPIO_1(6),   -- B2  (PIN_AE24)
            matrix_external_a   => GPIO_1(8),   -- A   (PIN_AF26)
            matrix_external_b   => GPIO_1(9),   -- B   (PIN_AG25)
            matrix_external_c   => GPIO_1(10),  -- C   (PIN_AG26)
            matrix_external_d   => GPIO_1(11),  -- D   (PIN_AH24)
            matrix_external_clk => GPIO_1(12),  -- CLK (PIN_AH27)
            matrix_external_lat => GPIO_1(13),  -- LAT (PIN_AJ27)
            matrix_external_oe  => GPIO_1(14)   -- OE  (PIN_AK29)
        );
    
    -- ========================================================================
    -- Ongebruikte GPIO pins: niet toegewezen (blijven als input)
    -- GPIO_1[3] en GPIO_1[7] worden niet gebruikt
    -- ========================================================================
    
    -- ========================================================================
    -- Debug LEDs: echo switches
    -- ========================================================================
    LEDR <= SW;

end Behavioral;
