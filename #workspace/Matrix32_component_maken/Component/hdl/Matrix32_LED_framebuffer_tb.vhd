-- ============================================================================
-- Testbench voor Matrix32_LED met Framebuffer Support
-- Test zowel framebuffer mode als test pattern mode
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity Matrix32_LED_framebuffer_tb is
end Matrix32_LED_framebuffer_tb;

architecture Behavioral of Matrix32_LED_framebuffer_tb is
    -- Component declaration
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
    
    -- Clock and reset
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal sim_done    : boolean := false;
    
    -- LED matrix signals
    signal R1, G1, B1  : std_logic;
    signal R2, G2, B2  : std_logic;
    signal A, B, C, D  : std_logic;
    signal CLK_out     : std_logic;
    signal LAT         : std_logic;
    signal OE          : std_logic;
    
    -- Framebuffer interface
    signal fb_write_enable : std_logic := '0';
    signal fb_write_addr   : std_logic_vector(11 downto 0) := (others => '0');
    signal fb_write_data   : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Mode control
    signal mode          : std_logic := '0';  -- 0=framebuffer, 1=test pattern
    signal test_pattern  : std_logic_vector(2 downto 0) := "000";
    
    -- Clock period
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz
    
begin
    -- ========================================================================
    -- DUT instantiation
    -- ========================================================================
    dut: Matrix32_LED
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
    
    -- ========================================================================
    -- Clock generation
    -- ========================================================================
    clk_process: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;
    
    -- ========================================================================
    -- Stimulus process
    -- ========================================================================
    stimulus: process
        -- Helper: Write pixel to framebuffer (x, y, r, g, b)
        procedure write_pixel(
            constant x : in integer range 0 to 31;
            constant y : in integer range 0 to 31;
            constant r : in std_logic;
            constant g : in std_logic;
            constant b : in std_logic
        ) is
            variable pixel_index : integer;
            variable byte_addr   : integer;
            variable bit_offset  : integer;
            variable bit_mask    : std_logic_vector(7 downto 0);
        begin
            pixel_index := y * 32 + x;
            byte_addr := pixel_index / 8;
            bit_offset := pixel_index mod 8;
            
            -- Create bit mask
            bit_mask := (others => '0');
            bit_mask(bit_offset) := '1';
            
            -- Write R channel
            if r = '1' then
                fb_write_addr <= std_logic_vector(to_unsigned(byte_addr, 12));
                fb_write_data <= bit_mask;
                fb_write_enable <= '1';
                wait for CLK_PERIOD;
                fb_write_enable <= '0';
                wait for CLK_PERIOD;
            end if;
            
            -- Write G channel
            if g = '1' then
                fb_write_addr <= std_logic_vector(to_unsigned(128 + byte_addr, 12));
                fb_write_data <= bit_mask;
                fb_write_enable <= '1';
                wait for CLK_PERIOD;
                fb_write_enable <= '0';
                wait for CLK_PERIOD;
            end if;
            
            -- Write B channel
            if b = '1' then
                fb_write_addr <= std_logic_vector(to_unsigned(256 + byte_addr, 12));
                fb_write_data <= bit_mask;
                fb_write_enable <= '1';
                wait for CLK_PERIOD;
                fb_write_enable <= '0';
                wait for CLK_PERIOD;
            end if;
        end procedure;
        
        -- Helper: Clear framebuffer
        procedure clear_framebuffer is
        begin
            report "Clearing framebuffer...";
            for addr in 0 to 383 loop
                fb_write_addr <= std_logic_vector(to_unsigned(addr, 12));
                fb_write_data <= x"00";
                fb_write_enable <= '1';
                wait for CLK_PERIOD;
                fb_write_enable <= '0';
                wait for CLK_PERIOD;
            end loop;
        end procedure;
        
    begin
        report "========================================";
        report "  Matrix32 LED Framebuffer Testbench";
        report "========================================";
        report "";
        
        -- Reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;
        
        -- ====================================================================
        -- TEST 1: Framebuffer mode - Clear all
        -- ====================================================================
        report ">>> TEST 1: Clear Framebuffer <<<";
        mode <= '0';  -- Framebuffer mode
        clear_framebuffer;
        wait for 50 us;
        
        -- ====================================================================
        -- TEST 2: Framebuffer mode - Single pixels
        -- ====================================================================
        report ">>> TEST 2: Single Pixels <<<";
        
        -- Red pixel top-left (0, 0)
        report "  Writing RED pixel at (0, 0)";
        write_pixel(0, 0, '1', '0', '0');
        
        -- Green pixel top-right (31, 0)
        report "  Writing GREEN pixel at (31, 0)";
        write_pixel(31, 0, '0', '1', '0');
        
        -- Blue pixel bottom-left (0, 31)
        report "  Writing BLUE pixel at (0, 31)";
        write_pixel(0, 31, '0', '0', '1');
        
        -- White pixel bottom-right (31, 31)
        report "  Writing WHITE pixel at (31, 31)";
        write_pixel(31, 31, '1', '1', '1');
        
        -- Center yellow pixel (16, 16)
        report "  Writing YELLOW pixel at (16, 16)";
        write_pixel(16, 16, '1', '1', '0');
        
        wait for 100 us;
        
        -- ====================================================================
        -- TEST 3: Framebuffer mode - Horizontal line
        -- ====================================================================
        report ">>> TEST 3: Horizontal Line (row 15, cyan) <<<";
        clear_framebuffer;
        
        for x in 0 to 31 loop
            write_pixel(x, 15, '0', '1', '1');  -- Cyan
        end loop;
        
        wait for 100 us;
        
        -- ====================================================================
        -- TEST 4: Framebuffer mode - Vertical line
        -- ====================================================================
        report ">>> TEST 4: Vertical Line (col 15, magenta) <<<";
        clear_framebuffer;
        
        for y in 0 to 31 loop
            write_pixel(15, y, '1', '0', '1');  -- Magenta
        end loop;
        
        wait for 100 us;
        
        -- ====================================================================
        -- TEST 5: Framebuffer mode - Rectangle
        -- ====================================================================
        report ">>> TEST 5: Rectangle outline (white) <<<";
        clear_framebuffer;
        
        -- Top and bottom edges
        for x in 8 to 23 loop
            write_pixel(x, 8, '1', '1', '1');
            write_pixel(x, 23, '1', '1', '1');
        end loop;
        
        -- Left and right edges
        for y in 8 to 23 loop
            write_pixel(8, y, '1', '1', '1');
            write_pixel(23, y, '1', '1', '1');
        end loop;
        
        wait for 100 us;
        
        -- ====================================================================
        -- TEST 6: Test Pattern Mode - Compare with framebuffer
        -- ====================================================================
        report ">>> TEST 6: Test Pattern Mode <<<";
        mode <= '1';  -- Switch to test pattern mode
        
        report "  Pattern 0: Checkerboard";
        test_pattern <= "000";
        wait for 100 us;
        
        report "  Pattern 1: Horizontal lines";
        test_pattern <= "001";
        wait for 100 us;
        
        report "  Pattern 2: Vertical lines";
        test_pattern <= "010";
        wait for 100 us;
        
        report "  Pattern 3: All ON (white)";
        test_pattern <= "011";
        wait for 100 us;
        
        report "  Pattern 4: Red gradient";
        test_pattern <= "100";
        wait for 100 us;
        
        -- ====================================================================
        -- TEST 7: Mode switching during operation
        -- ====================================================================
        report ">>> TEST 7: Mode Switching <<<";
        
        -- Back to framebuffer with custom pattern
        mode <= '0';
        clear_framebuffer;
        
        -- Write diagonal line
        for i in 0 to 31 loop
            write_pixel(i, i, '1', '0', '0');  -- Red diagonal
        end loop;
        
        wait for 50 us;
        
        -- Switch to pattern mode
        mode <= '1';
        test_pattern <= "011";  -- All white
        wait for 50 us;
        
        -- Back to framebuffer (diagonal should still be there)
        mode <= '0';
        wait for 50 us;
        
        -- ====================================================================
        -- TEST 8: Byte-wide writes (faster framebuffer filling)
        -- ====================================================================
        report ">>> TEST 8: Byte-wide Write Performance <<<";
        clear_framebuffer;
        
        -- Fill first row with alternating pattern (0xAA = 10101010)
        for byte_addr in 0 to 3 loop  -- First 4 bytes = 32 pixels
            fb_write_addr <= std_logic_vector(to_unsigned(byte_addr, 12));
            fb_write_data <= x"AA";
            fb_write_enable <= '1';
            wait for CLK_PERIOD;
            fb_write_enable <= '0';
            wait for CLK_PERIOD;
        end loop;
        
        wait for 50 us;
        
        -- ====================================================================
        -- Finish
        -- ====================================================================
        report "";
        report "========================================";
        report "  All tests completed successfully!";
        report "========================================";
        
        wait for 100 us;
        sim_done <= true;
        wait;
    end process;
    
    -- ========================================================================
    -- Monitor process - Display RGB values when signals change
    -- ========================================================================
    monitor_proc: process(CLK_out, LAT, OE)
        variable row_addr : unsigned(3 downto 0);
    begin
        row_addr := D & C & B & A;
        
        if rising_edge(CLK_out) then
            report "CLK pulse - Row: " & integer'image(to_integer(row_addr)) & 
                   " | R1=" & std_logic'image(R1) & 
                   " G1=" & std_logic'image(G1) & 
                   " B1=" & std_logic'image(B1) & 
                   " | R2=" & std_logic'image(R2) & 
                   " G2=" & std_logic'image(G2) & 
                   " B2=" & std_logic'image(B2);
        end if;
        
        if rising_edge(LAT) then
            report ">>> LAT: Latching row " & integer'image(to_integer(row_addr));
        end if;
        
        if falling_edge(OE) then
            report ">>> OE: Display enabled for row " & integer'image(to_integer(row_addr));
        end if;
    end process;

end Behavioral;
