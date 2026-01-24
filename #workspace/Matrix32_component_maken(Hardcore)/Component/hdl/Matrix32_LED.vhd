-- ============================================================================
-- Matrix32_LED.vhd - 32x32 RGB LED Matrix Controller
-- VHDL Hardware Core - Doet ALLE matrix aansturing automatisch
-- ============================================================================
-- Dit VHDL bestand implementeert de COMPLETE matrix aansturing in hardware.
-- De C software hoeft alleen maar pixel waarden te schrijven naar de 
-- framebuffer, en deze hardware zorgt automatisch voor:
--
--   ✓ Matrix scanning (16 gemultiplexte rijen)
--   ✓ Column data shifting (32 pixels per rij)
--   ✓ HUB75 protocol timing (CLK, LAT, OE signalen)
--   ✓ Framebuffer opslag (384 bytes in FPGA)
--   ✓ Real-time refresh (constant, >1kHz)
--
-- HARDWARE STATE MACHINE:
--   IDLE → SHIFT_DATA → LATCH_DATA → DISPLAY → (volgende rij) → IDLE
--    ↓          ↓            ↓           ↓
--   Setup   Shift 32     Latch data  Enable LEDs
--   rij     columns      to outputs   (PWM tijd)
--
-- GEEN CPU NODIG VOOR SCANNING! Hardware loopt constant door alle rijen.
-- C code schrijft alleen pixel waarden, hardware toont ze automatisch.
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Matrix32_LED is
    Port (
        -- Clock en reset
        clk         : in  std_logic;
        reset       : in  std_logic;
        
        -- LED matrix control signalen
        R1, G1, B1  : out std_logic;  -- RGB data voor upper half (lijn 1-16)
        R2, G2, B2  : out std_logic;  -- RGB data voor lower half (lijn 17-32)
        A, B, C, D  : out std_logic;  -- Row address (4 bits = 16 rijen)
        CLK_out     : out std_logic;  -- Shift clock voor LED drivers
        LAT         : out std_logic;  -- Latch signal
        OE          : out std_logic;  -- Output Enable (active low)
        
        -- Framebuffer interface
        fb_write_enable : in  std_logic;
        fb_write_addr   : in  std_logic_vector(11 downto 0);  -- 4096 adressen (max 384 bytes)
        fb_write_data   : in  std_logic_vector(7 downto 0);   -- 8 pixels per write
        
        -- Mode select: 0=framebuffer, 1=test pattern
        mode            : in  std_logic;
        test_pattern    : in  std_logic_vector(2 downto 0)
    );
end Matrix32_LED;

architecture Behavioral of Matrix32_LED is
    -- Constants
    constant MATRIX_WIDTH  : integer := 32;
    constant MATRIX_HEIGHT : integer := 32;
    constant NUM_ROWS      : integer := 16;  -- Aantal multiplexed rijen (32/2)
    
    -- Framebuffer: 3072 bits (32x32 pixels × 3 colors)
    -- Georganiseerd als 384 bytes × 8 bits
    -- Layout: R bits [0-127], G bits [128-255], B bits [256-383]
    type framebuffer_type is array (0 to 383) of std_logic_vector(7 downto 0);
    signal framebuffer : framebuffer_type := (others => (others => '0'));
    
    -- Internal signals
    signal row_counter     : unsigned(3 downto 0) := (others => '0');
    signal col_counter     : unsigned(5 downto 0) := (others => '0');
    signal refresh_counter : unsigned(15 downto 0) := (others => '0');
    
    -- State machine
    type state_type is (IDLE, SHIFT_DATA, LATCH_DATA, DISPLAY);
    signal current_state : state_type := IDLE;
    
    -- Clock divider voor display refresh
    signal clk_divider : unsigned(7 downto 0) := (others => '0');
    signal refresh_clk : std_logic := '0';
    
    -- Internal clock signal (output ports kunnen niet gelezen worden)
    signal clk_out_internal : std_logic := '0';
    
    -- Pixel data van framebuffer
    signal pixel_r1, pixel_g1, pixel_b1 : std_logic;
    signal pixel_r2, pixel_g2, pixel_b2 : std_logic;
    
begin
    -- ========================================================================
    -- Framebuffer Write Process
    -- ========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if fb_write_enable = '1' then
                -- Write 8 pixels (bits) naar framebuffer
                if unsigned(fb_write_addr) < 384 then
                    framebuffer(to_integer(unsigned(fb_write_addr))) <= fb_write_data;
                end if;
            end if;
        end if;
    end process;
    
    -- ========================================================================
    -- Output Port Assignments
    -- ========================================================================
    -- Assign internal clock signal naar output port
    CLK_out <= clk_out_internal;
    
    -- ========================================================================
    -- Framebuffer Read Process - haal pixel data op voor huidige positie
    -- ========================================================================
    process(row_counter, col_counter, framebuffer)
        variable pixel_index : integer range 0 to 1023;
        variable byte_addr   : integer range 0 to 127;
        variable bit_offset  : integer range 0 to 7;
    begin
        -- Bereken pixel index voor upper half: row * 32 + col
        pixel_index := to_integer(row_counter) * 32 + to_integer(col_counter);
        
        -- Bereken byte address en bit offset
        byte_addr := pixel_index / 8;
        bit_offset := pixel_index mod 8;
        
        -- R1: bytes 0-127 (alle R pixels upper half)
        if byte_addr < 128 then
            pixel_r1 <= framebuffer(byte_addr)(bit_offset);
        else
            pixel_r1 <= '0';
        end if;
        
        -- G1: bytes 128-255
        if byte_addr < 128 then
            pixel_g1 <= framebuffer(128 + byte_addr)(bit_offset);
        else
            pixel_g1 <= '0';
        end if;
        
        -- B1: bytes 256-383
        if byte_addr < 128 then
            pixel_b1 <= framebuffer(256 + byte_addr)(bit_offset);
        else
            pixel_b1 <= '0';
        end if;
        
        -- R2, G2, B2: zelfde pixel maar voor lower half (row + 16)
        pixel_index := (to_integer(row_counter) + 16) * 32 + to_integer(col_counter);
        byte_addr := pixel_index / 8;
        bit_offset := pixel_index mod 8;
        
        if byte_addr < 128 then
            pixel_r2 <= framebuffer(byte_addr)(bit_offset);
            pixel_g2 <= framebuffer(128 + byte_addr)(bit_offset);
            pixel_b2 <= framebuffer(256 + byte_addr)(bit_offset);
        else
            pixel_r2 <= '0';
            pixel_g2 <= '0';
            pixel_b2 <= '0';
        end if;
    end process;
    
    -- ========================================================================
    -- Clock divider proces (verlaag klok voor zichtbare simulatie)
    -- ========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            clk_divider <= clk_divider + 1;
            if clk_divider = 0 then
                refresh_clk <= not refresh_clk;
            end if;
        end if;
    end process;
    
    -- ========================================================================
    -- Hoofdproces voor matrix aansturen
    -- ========================================================================
    process(clk, reset)
    begin
        if reset = '1' then
            row_counter <= (others => '0');
            col_counter <= (others => '0');
            current_state <= IDLE;
            LAT <= '0';
            OE <= '1';  -- Output disabled
            clk_out_internal <= '0';
            
        elsif rising_edge(clk) then
            case current_state is
                when IDLE =>
                    OE <= '1';  -- Disable output tijdens data load
                    LAT <= '0';
                    col_counter <= (others => '0');
                    current_state <= SHIFT_DATA;
                    
                when SHIFT_DATA =>
                    -- Shift data uit voor huidige kolom en rij
                    clk_out_internal <= not clk_out_internal;  -- Toggle clock
                    
                    if clk_out_internal = '1' then  -- Op dalende flank, volgende kolom
                        if col_counter < MATRIX_WIDTH - 1 then
                            col_counter <= col_counter + 1;
                        else
                            current_state <= LATCH_DATA;
                        end if;
                    end if;
                    
                    -- Kies data source: framebuffer of test pattern
                    if mode = '0' then
                        -- Framebuffer mode
                        R1 <= pixel_r1;
                        G1 <= pixel_g1;
                        B1 <= pixel_b1;
                        R2 <= pixel_r2;
                        G2 <= pixel_g2;
                        B2 <= pixel_b2;
                    else
                        -- Test pattern mode
                        case test_pattern is
                            when "000" =>  -- Checkerboard
                                if (to_integer(row_counter) + to_integer(col_counter)) mod 2 = 0 then
                                    R1 <= '1';
                                    G2 <= '1';
                                else
                                    R1 <= '0';
                                    G2 <= '0';
                                end if;
                                G1 <= '0';
                                B1 <= '0';
                                R2 <= '0';
                                B2 <= '0';
                                
                            when "001" =>  -- Horizontal lines
                                R1 <= '1';
                                G1 <= '0';
                                B1 <= '0';
                                R2 <= '0';
                                G2 <= '0';
                                B2 <= '1';
                                
                            when "010" =>  -- Vertical lines
                                if col_counter(0) = '0' then
                                    R1 <= '1';
                                    G1 <= '1';
                                    B1 <= '1';
                                    R2 <= '0';
                                    G2 <= '0';
                                    B2 <= '0';
                                else
                                    R1 <= '0';
                                    G1 <= '0';
                                    B1 <= '0';
                                    R2 <= '1';
                                    G2 <= '1';
                                    B2 <= '1';
                                end if;
                                
                            when "011" =>  -- Alle LEDs aan (wit)
                                R1 <= '1';
                                G1 <= '1';
                                B1 <= '1';
                                R2 <= '1';
                                G2 <= '1';
                                B2 <= '1';
                                
                            when "100" =>  -- Rood gradient
                                if col_counter < 16 then
                                    R1 <= '1';
                                    R2 <= '0';
                                else
                                    R1 <= '0';
                                    R2 <= '1';
                                end if;
                                G1 <= '0';
                                B1 <= '0';
                                G2 <= '0';
                                B2 <= '0';
                                
                            when others =>  -- Uit
                                R1 <= '0';
                                G1 <= '0';
                                B1 <= '0';
                                R2 <= '0';
                                G2 <= '0';
                                B2 <= '0';
                        end case;
                    end if;
                    
                when LATCH_DATA =>
                    clk_out_internal <= '0';
                    LAT <= '1';  -- Latch data naar outputs
                    current_state <= DISPLAY;
                    
                when DISPLAY =>
                    LAT <= '0';
                    OE <= '0';  -- Enable output
                    
                    -- Refresh delay
                    refresh_counter <= refresh_counter + 1;
                    if refresh_counter = 1000 then  -- Korte display tijd
                        refresh_counter <= (others => '0');
                        
                        -- Ga naar volgende rij
                        if row_counter < NUM_ROWS - 1 then
                            row_counter <= row_counter + 1;
                        else
                            row_counter <= (others => '0');
                        end if;
                        
                        current_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
    
    -- Row address outputs (interleaved: 0=rij1+17, 1=rij2+18, etc.)
    A <= row_counter(0);
    B <= row_counter(1);
    C <= row_counter(2);
    D <= row_counter(3);

end Behavioral;
