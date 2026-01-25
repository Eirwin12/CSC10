-- ============================================================================
-- DE1-SoC Top Level voor Matrix32 LED Controller met HPS
-- Cyclone V 5CSEMA5F31C6N
-- ============================================================================
-- Dit bestand integreert:
--   - HPS (Hard Processor System) met Linux
--   - DDR3 Memory interface
--   - HPS Peripherals (Ethernet, USB, SD Card, UART, etc.)
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
        -- LEDs (debug) - INTERNAL ONLY voor HPS design
        -- Niet naar externe pins gerouteerd vanwege HPS pin conflicts
        -- ==================================================================
        -- LEDR poort verwijderd - gebruikt intern alleen voor debug signalen
        
        -- ==================================================================
        -- HPS DDR3 Memory Interface
        -- ==================================================================
        HPS_DDR3_ADDR   : out   std_logic_vector(14 downto 0);
        HPS_DDR3_BA     : out   std_logic_vector(2 downto 0);
        HPS_DDR3_CK_P   : out   std_logic;
        HPS_DDR3_CK_N   : out   std_logic;
        HPS_DDR3_CKE    : out   std_logic;
        HPS_DDR3_CS_N   : out   std_logic;
        HPS_DDR3_RAS_N  : out   std_logic;
        HPS_DDR3_CAS_N  : out   std_logic;
        HPS_DDR3_WE_N   : out   std_logic;
        HPS_DDR3_RESET_N: out   std_logic;
        HPS_DDR3_DQ     : inout std_logic_vector(31 downto 0);
        HPS_DDR3_DQS_P  : inout std_logic_vector(3 downto 0);
        HPS_DDR3_DQS_N  : inout std_logic_vector(3 downto 0);
        HPS_DDR3_ODT    : out   std_logic;
        HPS_DDR3_DM     : out   std_logic_vector(3 downto 0);
        HPS_DDR3_RZQ    : in    std_logic;
        
        -- ==================================================================
        -- HPS Ethernet (EMAC1)
        -- ==================================================================
        HPS_ENET_GTX_CLK: out   std_logic;
        HPS_ENET_INT_N  : inout std_logic;
        HPS_ENET_MDC    : out   std_logic;
        HPS_ENET_MDIO   : inout std_logic;
        HPS_ENET_RX_CLK : in    std_logic;
        HPS_ENET_RX_DATA: in    std_logic_vector(3 downto 0);
        HPS_ENET_RX_DV  : in    std_logic;
        HPS_ENET_TX_DATA: out   std_logic_vector(3 downto 0);
        HPS_ENET_TX_EN  : out   std_logic;
        
        -- ==================================================================
        -- HPS QSPI Flash
        -- ==================================================================
        HPS_FLASH_DATA  : inout std_logic_vector(3 downto 0);
        HPS_FLASH_DCLK  : out   std_logic;
        HPS_FLASH_NCSO  : out   std_logic;
        
        -- ==================================================================
        -- HPS SD Card
        -- ==================================================================
        HPS_SD_CLK      : out   std_logic;
        HPS_SD_CMD      : inout std_logic;
        HPS_SD_DATA     : inout std_logic_vector(3 downto 0);
        
        -- ==================================================================
        -- HPS USB OTG
        -- ==================================================================
        HPS_USB_CLKOUT  : in    std_logic;
        HPS_USB_DATA    : inout std_logic_vector(7 downto 0);
        HPS_USB_DIR     : in    std_logic;
        HPS_USB_NXT     : in    std_logic;
        HPS_USB_STP     : out   std_logic;
        
        -- ==================================================================
        -- HPS SPI
        -- ==================================================================
        HPS_SPI_CLK     : out   std_logic;
        HPS_SPI_MOSI    : out   std_logic;
        HPS_SPI_MISO    : in    std_logic;
        HPS_SPI_SS      : out   std_logic;
        
        -- ==================================================================
        -- HPS UART (Console)
        -- ==================================================================
        HPS_UART_RX     : in    std_logic;
        HPS_UART_TX     : out   std_logic;
        
        -- ==================================================================
        -- HPS I2C
        -- ==================================================================
        HPS_I2C0_SDAT   : inout std_logic;
        HPS_I2C0_SCLK   : inout std_logic;
        HPS_I2C1_SDAT   : inout std_logic;
        HPS_I2C1_SCLK   : inout std_logic;
        
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
    
    -- Platform Designer systeem met HPS (gegenereerd uit soc_system.qsys)
    component soc_system is
        port (
            clk_clk                         : in    std_logic;
            key_external_export             : in    std_logic_vector(3 downto 0);
            matrix_external_r1              : out   std_logic;
            matrix_external_g1              : out   std_logic;
            matrix_external_b1              : out   std_logic;
            matrix_external_r2              : out   std_logic;
            matrix_external_g2              : out   std_logic;
            matrix_external_b2              : out   std_logic;
            matrix_external_a               : out   std_logic;
            matrix_external_b               : out   std_logic;
            matrix_external_c               : out   std_logic;
            matrix_external_d               : out   std_logic;
            matrix_external_clk             : out   std_logic;
            matrix_external_lat             : out   std_logic;
            matrix_external_oe              : out   std_logic;
            reset_reset_n                   : in    std_logic;
            memory_mem_a                    : out   std_logic_vector(14 downto 0);
            memory_mem_ba                   : out   std_logic_vector(2 downto 0);
            memory_mem_ck                   : out   std_logic;
            memory_mem_ck_n                 : out   std_logic;
            memory_mem_cke                  : out   std_logic;
            memory_mem_cs_n                 : out   std_logic;
            memory_mem_ras_n                : out   std_logic;
            memory_mem_cas_n                : out   std_logic;
            memory_mem_we_n                 : out   std_logic;
            memory_mem_reset_n              : out   std_logic;
            memory_mem_dq                   : inout std_logic_vector(31 downto 0);
            memory_mem_dqs                  : inout std_logic_vector(3 downto 0);
            memory_mem_dqs_n                : inout std_logic_vector(3 downto 0);
            memory_mem_odt                  : out   std_logic;
            memory_mem_dm                   : out   std_logic_vector(3 downto 0);
            memory_oct_rzqin                : in    std_logic;
            hps_io_hps_io_emac1_inst_TX_CLK : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD0   : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD1   : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD2   : out   std_logic;
            hps_io_hps_io_emac1_inst_TXD3   : out   std_logic;
            hps_io_hps_io_emac1_inst_RXD0   : in    std_logic;
            hps_io_hps_io_emac1_inst_MDIO   : inout std_logic;
            hps_io_hps_io_emac1_inst_MDC    : out   std_logic;
            hps_io_hps_io_emac1_inst_RX_CTL : in    std_logic;
            hps_io_hps_io_emac1_inst_TX_CTL : out   std_logic;
            hps_io_hps_io_emac1_inst_RX_CLK : in    std_logic;
            hps_io_hps_io_emac1_inst_RXD1   : in    std_logic;
            hps_io_hps_io_emac1_inst_RXD2   : in    std_logic;
            hps_io_hps_io_emac1_inst_RXD3   : in    std_logic;
            hps_io_hps_io_qspi_inst_IO0     : inout std_logic;
            hps_io_hps_io_qspi_inst_IO1     : inout std_logic;
            hps_io_hps_io_qspi_inst_IO2     : inout std_logic;
            hps_io_hps_io_qspi_inst_IO3     : inout std_logic;
            hps_io_hps_io_qspi_inst_SS0     : out   std_logic;
            hps_io_hps_io_qspi_inst_CLK     : out   std_logic;
            hps_io_hps_io_sdio_inst_CMD     : inout std_logic;
            hps_io_hps_io_sdio_inst_D0      : inout std_logic;
            hps_io_hps_io_sdio_inst_D1      : inout std_logic;
            hps_io_hps_io_sdio_inst_CLK     : out   std_logic;
            hps_io_hps_io_sdio_inst_D2      : inout std_logic;
            hps_io_hps_io_sdio_inst_D3      : inout std_logic;
            hps_io_hps_io_usb1_inst_D0      : inout std_logic;
            hps_io_hps_io_usb1_inst_D1      : inout std_logic;
            hps_io_hps_io_usb1_inst_D2      : inout std_logic;
            hps_io_hps_io_usb1_inst_D3      : inout std_logic;
            hps_io_hps_io_usb1_inst_D4      : inout std_logic;
            hps_io_hps_io_usb1_inst_D5      : inout std_logic;
            hps_io_hps_io_usb1_inst_D6      : inout std_logic;
            hps_io_hps_io_usb1_inst_D7      : inout std_logic;
            hps_io_hps_io_usb1_inst_CLK     : in    std_logic;
            hps_io_hps_io_usb1_inst_STP     : out   std_logic;
            hps_io_hps_io_usb1_inst_DIR     : in    std_logic;
            hps_io_hps_io_usb1_inst_NXT     : in    std_logic;
            hps_io_hps_io_spim1_inst_CLK    : out   std_logic;
            hps_io_hps_io_spim1_inst_MOSI   : out   std_logic;
            hps_io_hps_io_spim1_inst_MISO   : in    std_logic;
            hps_io_hps_io_spim1_inst_SS0    : out   std_logic;
            hps_io_hps_io_uart0_inst_RX     : in    std_logic;
            hps_io_hps_io_uart0_inst_TX     : out   std_logic;
            hps_io_hps_io_i2c0_inst_SDA     : inout std_logic;
            hps_io_hps_io_i2c0_inst_SCL     : inout std_logic;
            hps_io_hps_io_i2c1_inst_SDA     : inout std_logic;
            hps_io_hps_io_i2c1_inst_SCL     : inout std_logic
        );
    end component;
    
    -- ========================================================================
    -- Internal Signals
    -- ========================================================================
    signal reset_n : std_logic;
    signal hps_eth_tx_en : std_logic;  -- Internal signal voor TX_EN (om te kunnen lezen)
    
    -- Debug signals (internal only - not routed to external pins in HPS design)
    signal debug_leds : std_logic_vector(9 downto 0);
    
begin
    
    -- ========================================================================
    -- Reset Logic
    -- KEY(0) is active-low reset button
    -- ========================================================================
    reset_n <= KEY(0);
    
    -- ========================================================================
    -- Debug LEDs (internal signals only - niet naar externe pins)
    -- In HPS designs zijn de meeste I/O pins gereserveerd, dus geen fysieke LEDs
    -- ========================================================================
    debug_leds(0) <= reset_n;              -- LED0: Reset status
    debug_leds(1) <= hps_eth_tx_en;        -- LED1: Ethernet TX activity
    debug_leds(2) <= HPS_ENET_RX_DV;       -- LED2: Ethernet RX activity
    debug_leds(3) <= '1';                  -- LED3: Power indicator
    debug_leds(9 downto 4) <= (others => '0');
    
    -- Connect internal signal to output
    HPS_ENET_TX_EN <= hps_eth_tx_en;
    
    -- ========================================================================
    -- Platform Designer System Instantiation met HPS
    -- ========================================================================
    u0: soc_system
        port map (
            -- Clock and reset
            clk_clk             => CLOCK_50,
            reset_reset_n       => reset_n,
            
            -- KEY buttons (active low)
            key_external_export => KEY,
            
            -- Matrix LED signals → Direct naar GPIO_1 pins
            matrix_external_r1  => GPIO_1(0),   -- R1
            matrix_external_g1  => GPIO_1(1),   -- G1
            matrix_external_b1  => GPIO_1(2),   -- B1
            matrix_external_r2  => GPIO_1(4),   -- R2
            matrix_external_g2  => GPIO_1(5),   -- G2
            matrix_external_b2  => GPIO_1(6),   -- B2
            matrix_external_a   => GPIO_1(8),   -- A
            matrix_external_b   => GPIO_1(9),   -- B
            matrix_external_c   => GPIO_1(10),  -- C
            matrix_external_d   => GPIO_1(11),  -- D
            matrix_external_clk => GPIO_1(12),  -- CLK
            matrix_external_lat => GPIO_1(13),  -- LAT
            matrix_external_oe  => GPIO_1(14),  -- OE
            
            -- HPS DDR3 Memory
            memory_mem_a        => HPS_DDR3_ADDR,
            memory_mem_ba       => HPS_DDR3_BA,
            memory_mem_ck       => HPS_DDR3_CK_P,
            memory_mem_ck_n     => HPS_DDR3_CK_N,
            memory_mem_cke      => HPS_DDR3_CKE,
            memory_mem_cs_n     => HPS_DDR3_CS_N,
            memory_mem_ras_n    => HPS_DDR3_RAS_N,
            memory_mem_cas_n    => HPS_DDR3_CAS_N,
            memory_mem_we_n     => HPS_DDR3_WE_N,
            memory_mem_reset_n  => HPS_DDR3_RESET_N,
            memory_mem_dq       => HPS_DDR3_DQ,
            memory_mem_dqs      => HPS_DDR3_DQS_P,
            memory_mem_dqs_n    => HPS_DDR3_DQS_N,
            memory_mem_odt      => HPS_DDR3_ODT,
            memory_mem_dm       => HPS_DDR3_DM,
            memory_oct_rzqin    => HPS_DDR3_RZQ,
            
            -- HPS Ethernet (EMAC1)
            hps_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK,
            hps_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0),
            hps_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1),
            hps_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2),
            hps_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3),
            hps_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0),
            hps_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1),
            hps_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2),
            hps_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3),
            hps_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO,
            hps_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC,
            hps_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV,
            hps_io_hps_io_emac1_inst_TX_CTL => hps_eth_tx_en,
            hps_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK,
            
            -- HPS QSPI Flash
            hps_io_hps_io_qspi_inst_IO0     => HPS_FLASH_DATA(0),
            hps_io_hps_io_qspi_inst_IO1     => HPS_FLASH_DATA(1),
            hps_io_hps_io_qspi_inst_IO2     => HPS_FLASH_DATA(2),
            hps_io_hps_io_qspi_inst_IO3     => HPS_FLASH_DATA(3),
            hps_io_hps_io_qspi_inst_SS0     => HPS_FLASH_NCSO,
            hps_io_hps_io_qspi_inst_CLK     => HPS_FLASH_DCLK,
            
            -- HPS SD Card
            hps_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD,
            hps_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0),
            hps_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1),
            hps_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2),
            hps_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3),
            hps_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK,
            
            -- HPS USB
            hps_io_hps_io_usb1_inst_D0      => HPS_USB_DATA(0),
            hps_io_hps_io_usb1_inst_D1      => HPS_USB_DATA(1),
            hps_io_hps_io_usb1_inst_D2      => HPS_USB_DATA(2),
            hps_io_hps_io_usb1_inst_D3      => HPS_USB_DATA(3),
            hps_io_hps_io_usb1_inst_D4      => HPS_USB_DATA(4),
            hps_io_hps_io_usb1_inst_D5      => HPS_USB_DATA(5),
            hps_io_hps_io_usb1_inst_D6      => HPS_USB_DATA(6),
            hps_io_hps_io_usb1_inst_D7      => HPS_USB_DATA(7),
            hps_io_hps_io_usb1_inst_CLK     => HPS_USB_CLKOUT,
            hps_io_hps_io_usb1_inst_STP     => HPS_USB_STP,
            hps_io_hps_io_usb1_inst_DIR     => HPS_USB_DIR,
            hps_io_hps_io_usb1_inst_NXT     => HPS_USB_NXT,
            
            -- HPS SPI
            hps_io_hps_io_spim1_inst_CLK    => HPS_SPI_CLK,
            hps_io_hps_io_spim1_inst_MOSI   => HPS_SPI_MOSI,
            hps_io_hps_io_spim1_inst_MISO   => HPS_SPI_MISO,
            hps_io_hps_io_spim1_inst_SS0    => HPS_SPI_SS,
            
            -- HPS UART
            hps_io_hps_io_uart0_inst_RX     => HPS_UART_RX,
            hps_io_hps_io_uart0_inst_TX     => HPS_UART_TX,
            
            -- HPS I2C
            hps_io_hps_io_i2c0_inst_SDA     => HPS_I2C0_SDAT,
            hps_io_hps_io_i2c0_inst_SCL     => HPS_I2C0_SCLK,
            hps_io_hps_io_i2c1_inst_SDA     => HPS_I2C1_SDAT,
            hps_io_hps_io_i2c1_inst_SCL     => HPS_I2C1_SCLK
        );

end Behavioral;
