library IEEE;
use IEEE.std_logic_1164.all;

entity eindopdracht_Testris is
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
        GPIO_1 : inout std_logic_vector(35 downto 0)
    );
end entity eindopdracht_Testris;

architecture structure of eindopdracht_Testris is
    
    -- Platform Designer component (gegenereerd als "eindopdracht")
    component eindopdracht is
        port (
            clk_clk                                      : in  std_logic;
            pio_buttons_external_connection_export       : in  std_logic_vector(3 downto 0);
            pio_switches_external_connection_export      : in  std_logic_vector(9 downto 0);
            rgb_framebuffer_0_rgb_matrix_conduit_r1      : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_g1      : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_b1      : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_r2      : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_g2      : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_b2      : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_addr_a  : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_addr_b  : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_addr_c  : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_clk_out : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_lat     : out std_logic;
            rgb_framebuffer_0_rgb_matrix_conduit_oe_n    : out std_logic
        );
    end component;
    
begin
    
    -- Platform Designer System instantie (geen externe reset nodig, gebruikt intern reset)
    u0 : component eindopdracht
        port map (
            clk_clk                                      => CLOCK_50,
            pio_buttons_external_connection_export       => KEY,
            pio_switches_external_connection_export      => SW,
            rgb_framebuffer_0_rgb_matrix_conduit_r1      => GPIO_1(0),
            rgb_framebuffer_0_rgb_matrix_conduit_g1      => GPIO_1(1),
            rgb_framebuffer_0_rgb_matrix_conduit_b1      => GPIO_1(2),
            rgb_framebuffer_0_rgb_matrix_conduit_r2      => GPIO_1(3),
            rgb_framebuffer_0_rgb_matrix_conduit_g2      => GPIO_1(4),
            rgb_framebuffer_0_rgb_matrix_conduit_b2      => GPIO_1(5),
            rgb_framebuffer_0_rgb_matrix_conduit_addr_a  => GPIO_1(6),
            rgb_framebuffer_0_rgb_matrix_conduit_addr_b  => GPIO_1(7),
            rgb_framebuffer_0_rgb_matrix_conduit_addr_c  => GPIO_1(8),
            rgb_framebuffer_0_rgb_matrix_conduit_clk_out => GPIO_1(9),
            rgb_framebuffer_0_rgb_matrix_conduit_lat     => GPIO_1(10),
            rgb_framebuffer_0_rgb_matrix_conduit_oe_n    => GPIO_1(11)
        );
    
end architecture structure;
