-- ============================================================================
-- Matrix32_LED Avalon Wrapper voor Platform Designer
-- Voor DE1-SoC (Cyclone V)
-- ============================================================================
-- Dit bestand wraps de Matrix32_LED core met een Avalon Memory-Mapped
-- Slave interface zodat het gebruikt kan worden in Platform Designer
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Matrix32_LED_avalon is
    Port (
        -- ====================================================================
        -- Avalon Clock and Reset Interface
        -- ====================================================================
        csi_clk             : in  std_logic;
        rsi_reset_n         : in  std_logic;  -- Active-low reset
        
        -- ====================================================================
        -- Avalon Memory-Mapped Slave Interface
        -- Address Map:
        --   0x00: CONTROL      - [0]: Enable, [1]: Mode (0=framebuffer, 1=pattern)
        --   0x04: PATTERN      - [2:0]: Test pattern select (0-7)
        --   0x08: FB_ADDR      - [11:0]: Framebuffer write address
        --   0x0C: FB_DATA      - [7:0]: Framebuffer write data (8 pixels)
        --   0x10: STATUS       - [Read-only] Component status
        -- ====================================================================
        avs_s0_address      : in  std_logic_vector(2 downto 0);  -- 5 registers (0x00-0x10)
        avs_s0_write        : in  std_logic;
        avs_s0_writedata    : in  std_logic_vector(31 downto 0);
        avs_s0_read         : in  std_logic;
        avs_s0_readdata     : out std_logic_vector(31 downto 0);
        avs_s0_chipselect   : in  std_logic;
        
        -- ====================================================================
        -- Conduit to External LED Matrix (exported to top level)
        -- Deze signalen worden geëxporteerd naar GPIO pins
        -- ====================================================================
		  q_export : out std_logic_vector(31 downto 0)
    );
end Matrix32_LED_avalon;

architecture Behavioral of Matrix32_LED_avalon is
    
    -- ========================================================================
    -- Component Declaration - Matrix32_LED Core
    -- ========================================================================
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
    
    -- ========================================================================
    -- Avalon Memory-Mapped Registers
    -- ========================================================================
    signal reg_control      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_pattern      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_fb_addr      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_fb_data      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_status       : std_logic_vector(31 downto 0) := (others => '0');
    
    -- ========================================================================
    -- Internal Signals
    -- ========================================================================
    signal reset_internal   : std_logic;
    signal enable           : std_logic;
    signal mode             : std_logic;
    signal test_pattern_int : std_logic_vector(2 downto 0);
    signal fb_write_enable  : std_logic;
    signal fb_write_trigger : std_logic;
    
begin
    
    -- ========================================================================
    -- Reset Conversion: Avalon (active-low) → Internal (active-high)
    -- ========================================================================
    reset_internal <= not rsi_reset_n;
    
    -- ========================================================================
    -- Extract Control Signals from Registers
    -- ========================================================================
    enable           <= reg_control(0);
    mode             <= reg_control(1);  -- 0=framebuffer, 1=test pattern
    test_pattern_int <= reg_pattern(2 downto 0);
    
    -- Framebuffer write enable: trigger op write naar FB_DATA register
    fb_write_enable  <= fb_write_trigger;
    
    -- ========================================================================
    -- Instantiate Matrix32_LED Core
    -- ========================================================================
    matrix_core : Matrix32_LED
        port map (
            clk             => csi_clk,
            reset           => reset_internal,
            R1              => Q_export(0),
            G1              => Q_export(1),
            B1              => Q_export(2),
            R2              => Q_export(3),
            G2              => Q_export(4),
            B2              => Q_export(5),
            A               => Q_export(6),
            B               => Q_export(7),
            C               => Q_export(8),
            D               => Q_export(9),
            CLK_out         => Q_export(10),
            LAT             => Q_export(11),
            OE              => Q_export(12),
            fb_write_enable => fb_write_enable,
            fb_write_addr   => reg_fb_addr(11 downto 0),
            fb_write_data   => reg_fb_data(7 downto 0),
            mode            => mode,
            test_pattern    => test_pattern_int
        );
    
    -- ========================================================================
    -- Avalon Slave Write Process
    -- Handles register writes from CPU
    -- ========================================================================
    avalon_write : process(csi_clk, reset_internal)
    begin
        if reset_internal = '1' then
            reg_control    <= (others => '0');
            reg_pattern    <= (others => '0');
            reg_fb_addr    <= (others => '0');
            reg_fb_data    <= (others => '0');
            fb_write_trigger <= '0';
            
        elsif rising_edge(csi_clk) then
            fb_write_trigger <= '0';  -- Default: no write
            
            -- Write to registers when chipselect and write are asserted
            if avs_s0_chipselect = '1' and avs_s0_write = '1' then
                case avs_s0_address is
                    when "000" =>  -- Address 0x00: Control Register
                        reg_control <= avs_s0_writedata;
                        
                    when "001" =>  -- Address 0x04: Pattern Register
                        reg_pattern <= avs_s0_writedata;
                        
                    when "010" =>  -- Address 0x08: FB_ADDR Register
                        reg_fb_addr <= avs_s0_writedata;
                        
                    when "011" =>  -- Address 0x0C: FB_DATA Register (trigger write)
                        reg_fb_data <= avs_s0_writedata;
                        fb_write_trigger <= '1';  -- Trigger framebuffer write
                        
                    when others =>
                        null;  -- Read-only or reserved
                end case;
            end if;
        end if;
    end process avalon_write;
    
    -- ========================================================================
    -- Avalon Slave Read Process
    -- Handles register reads from CPU
    -- ========================================================================
    avalon_read : process(avs_s0_chipselect, avs_s0_read, avs_s0_address, 
                          reg_control, reg_pattern, reg_fb_addr, reg_fb_data, reg_status)
    begin
        avs_s0_readdata <= (others => '0');  -- Default
        
        if avs_s0_chipselect = '1' and avs_s0_read = '1' then
            case avs_s0_address is
                when "000" =>  -- Address 0x00: Control Register
                    avs_s0_readdata <= reg_control;
                    
                when "001" =>  -- Address 0x04: Pattern Register
                    avs_s0_readdata <= reg_pattern;
                    
                when "010" =>  -- Address 0x08: FB_ADDR Register
                    avs_s0_readdata <= reg_fb_addr;
                    
                when "011" =>  -- Address 0x0C: FB_DATA Register
                    avs_s0_readdata <= reg_fb_data;
                    
                when "100" =>  -- Address 0x10: Status Register (Read-only)
                    avs_s0_readdata <= reg_status;
                    
                when others =>
                    avs_s0_readdata <= (others => '0');
            end case;
        end if;
    end process avalon_read;
    
    -- ========================================================================
    -- Status Register Update
    -- Read-only register showing component state
    -- ========================================================================
    process(csi_clk)
    begin
        if rising_edge(csi_clk) then
            reg_status(0)           <= enable;
            reg_status(3 downto 1)  <= test_pattern_int;
            reg_status(7 downto 4)  <= (others => '0');  -- Reserved
            reg_status(31 downto 8) <= (others => '0');  -- Reserved
        end if;
    end process;

end Behavioral;
