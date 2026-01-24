library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Matrix32_LED_tb is
end Matrix32_LED_tb;

architecture Behavioral of Matrix32_LED_tb is
    -- Component declaratie
    component Matrix32_LED is
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            R1, G1, B1      : out std_logic;
            R2, G2, B2      : out std_logic;
            A, B, C, D      : out std_logic;
            CLK_out         : out std_logic;
            LAT             : out std_logic;
            OE              : out std_logic;
            fb_write_enable : in  std_logic;
            fb_write_addr   : in  std_logic_vector(11 downto 0);
            fb_write_data   : in  std_logic_vector(7 downto 0);
            mode            : in  std_logic;
            test_pattern    : in  std_logic_vector(2 downto 0)
        );
    end component;
    
    -- Testbench signalen
    signal clk             : std_logic := '0';
    signal reset           : std_logic := '0';
    signal R1, G1, B1      : std_logic;
    signal R2, G2, B2      : std_logic;
    signal A, B, C, D      : std_logic;
    signal CLK_out         : std_logic;
    signal LAT             : std_logic;
    signal OE              : std_logic;
    signal fb_write_enable : std_logic := '0';
    signal fb_write_addr   : std_logic_vector(11 downto 0) := (others => '0');
    signal fb_write_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal mode            : std_logic := '1';  -- Start in test pattern mode
    signal test_pattern    : std_logic_vector(2 downto 0) := "000";
    
    -- Clock periode (50 MHz voor DE1-SoC)
    constant clk_period : time := 20 ns;
    
    -- Simulatie controle
    signal sim_done : boolean := false;
    
begin
    -- Unit Under Test (UUT) instantiëren
    UUT: Matrix32_LED
        port map (
            clk             => clk,
            reset           => reset,
            R1              => R1,
            G1              => G1,
            B1              => B1,
            R2              => R2,
            G2              => G2,
            B2              => B2,
            A               => A,
            B               => B,
            C               => C,
            D               => D,
            CLK_out         => CLK_out,
            LAT             => LAT,
            OE              => OE,
            fb_write_enable => fb_write_enable,
            fb_write_addr   => fb_write_addr,
            fb_write_data   => fb_write_data,
            mode            => mode,
            test_pattern    => test_pattern
        );
    
    -- Clock proces
    clk_process: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;
    
    -- Stimulus proces
    stim_proc: process
    begin
        -- Wacht op stabilisatie
        report "=== Start van simulatie ===" severity note;
        
        -- Test 1: Reset
        report "Test 1: Reset functionaliteit" severity note;
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 200 ns;
        
        -- ====================================================================
        -- TEST PATTERN MODE TESTS (mode = '1')
        -- ====================================================================
        mode <= '1';  -- Test pattern mode
        report "=== PATTERN MODE TESTS ===" severity note;
        
        -- Test 2: Checkerboard patroon
        report "Test 2: Checkerboard patroon (patroon 000)" severity note;
        test_pattern <= "000";
        wait for 100 us;  -- Wacht lang genoeg om meerdere refresh cycli te zien
        
        -- Test 3: Horizontal lines
        report "Test 3: Horizontal lines patroon (patroon 001)" severity note;
        test_pattern <= "001";
        wait for 100 us;
        
        -- Test 4: Vertical lines
        report "Test 4: Vertical lines patroon (patroon 010)" severity note;
        test_pattern <= "010";
        wait for 100 us;
        
        -- Test 5: Alle LEDs aan (wit)
        report "Test 5: Alle LEDs aan - wit (patroon 011)" severity note;
        test_pattern <= "011";
        wait for 100 us;
        
        -- Test 6: Rood gradient
        report "Test 6: Rood gradient (patroon 100)" severity note;
        test_pattern <= "100";
        wait for 100 us;
        
        -- Test 7: Alle LEDs uit
        report "Test 7: Alle LEDs uit (patroon 111)" severity note;
        test_pattern <= "111";
        wait for 100 us;
        
        -- ====================================================================
        -- FRAMEBUFFER MODE TESTS (mode = '0')
        -- ====================================================================
        mode <= '0';  -- Framebuffer mode
        report "=== FRAMEBUFFER MODE TESTS ===" severity note;
        
        -- Test 8: Write enkele pixels naar framebuffer (RED channel)
        report "Test 8: Framebuffer write - enkele RED pixels" severity note;
        fb_write_enable <= '1';
        fb_write_addr <= x"000";  -- Byte 0 (eerste 8 RED pixels)
        fb_write_data <= "10101010";  -- Alternerende pixels
        wait for clk_period;
        fb_write_enable <= '0';
        wait for 50 us;  -- Laat matrix refreshen
        
        -- Test 9: Write naar GREEN channel
        report "Test 9: Framebuffer write - GREEN pixels" severity note;
        fb_write_enable <= '1';
        fb_write_addr <= x"080";  -- Byte 128 (GREEN channel start)
        fb_write_data <= "11001100";  -- Patroon
        wait for clk_period;
        fb_write_enable <= '0';
        wait for 50 us;
        
        -- Test 10: Write naar BLUE channel
        report "Test 10: Framebuffer write - BLUE pixels" severity note;
        fb_write_enable <= '1';
        fb_write_addr <= x"100";  -- Byte 256 (BLUE channel start)
        fb_write_data <= "11110000";  -- Patroon
        wait for clk_period;
        fb_write_enable <= '0';
        wait for 50 us;
        
        -- Test 11: Fill eerste row met wit (RGB alle aan)
        report "Test 11: Fill eerste row met wit" severity note;
        for i in 0 to 3 loop  -- 4 bytes per row (32 pixels / 8)
            -- R channel
            fb_write_enable <= '1';
            fb_write_addr <= std_logic_vector(to_unsigned(i, 12));
            fb_write_data <= x"FF";
            wait for clk_period;
            
            -- G channel
            fb_write_addr <= std_logic_vector(to_unsigned(128 + i, 12));
            fb_write_data <= x"FF";
            wait for clk_period;
            
            -- B channel
            fb_write_addr <= std_logic_vector(to_unsigned(256 + i, 12));
            fb_write_data <= x"FF";
            wait for clk_period;
            fb_write_enable <= '0';
        end loop;
        wait for 100 us;  -- Laat volledige refresh zien
        
        -- Einde simulatie
        report "=== Simulatie succesvol afgerond ===" severity note;
        sim_done <= true;
        wait;
    end process;
    
    -- Monitor proces voor debugging
    monitor_proc: process(CLK_out, LAT, OE)
        variable row_addr : unsigned(3 downto 0);
    begin
        -- Bereken 4-bit row address uit individuele bits
        row_addr := D & C & B & A;
        
        if rising_edge(CLK_out) then
            report "CLK pulse - Row: " & integer'image(to_integer(row_addr)) & 
                   " | R1=" & std_logic'image(R1) & 
                   " G1=" & std_logic'image(G1) & 
                   " B1=" & std_logic'image(B1) &
                   " | R2=" & std_logic'image(R2) & 
                   " G2=" & std_logic'image(G2) & 
                   " B2=" & std_logic'image(B2)
                   severity note;
        end if;
        
        if rising_edge(LAT) then
            report "LATCH: Data voor row " & integer'image(to_integer(row_addr)) & " gelatched" severity note;
        end if;
        
        if falling_edge(OE) then
            report "OUTPUT ENABLED voor row " & integer'image(to_integer(row_addr)) severity note;
        end if;
    end process;

end Behavioral;
