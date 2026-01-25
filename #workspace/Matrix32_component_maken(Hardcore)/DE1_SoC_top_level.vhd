-- ============================================================================
-- DE1-SoC Top Level Design voor Matrix32 LED met HPS
-- ============================================================================
-- Dit is de top-level entity die alle signalen van het Platform Designer
-- systeem (soc_system) verbindt met de fysieke pins van de DE1-SoC board.
--
-- Features:
--   - HPS (Hard Processor System) met Linux
--   - DDR3 Memory interface
--   - HPS Peripherals (Ethernet, USB, SD Card, UART, etc.)
--   - Matrix32 LED Controller
--   - KEY inputs voor reset/control
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DE1_SoC_top_level is
    port (
        -- ====================================================================
        -- Clock Inputs
        -- ====================================================================
        CLOCK_50        : in    std_logic;  -- 50 MHz onboard clock
        CLOCK2_50       : in    std_logic;  -- 50 MHz clock #2
        CLOCK3_50       : in    std_logic;  -- 50 MHz clock #3
        CLOCK4_50       : in    std_logic;  -- 50 MHz clock #4
        
        -- ====================================================================
        -- KEY Inputs (Push buttons, active low)
        -- ====================================================================
        KEY             : in    std_logic_vector(3 downto 0);
        
        -- ====================================================================
        -- SW Switches
        -- ====================================================================
        SW              : in    std_logic_vector(9 downto 0);
        
        -- ====================================================================
        -- LEDs (for debug/status)
        -- ====================================================================
        LEDR            : out   std_logic_vector(9 downto 0);
        
        -- ====================================================================
        -- HPS DDR3 Memory Interface
        -- ====================================================================
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
        
        -- ====================================================================
        -- HPS Ethernet (EMAC1)
        -- ====================================================================
        HPS_ENET_GTX_CLK: out   std_logic;
        HPS_ENET_INT_N  : inout std_logic;
        HPS_ENET_MDC    : out   std_logic;
        HPS_ENET_MDIO   : inout std_logic;
        HPS_ENET_RX_CLK : in    std_logic;
        HPS_ENET_RX_DATA: in    std_logic_vector(3 downto 0);
        HPS_ENET_RX_DV  : in    std_logic;
        HPS_ENET_TX_DATA: out   std_logic_vector(3 downto 0);
        HPS_ENET_TX_EN  : out   std_logic;
        
        -- ====================================================================
        -- HPS QSPI Flash
        -- ====================================================================
        HPS_FLASH_DATA  : inout std_logic_vector(3 downto 0);
        HPS_FLASH_DCLK  : out   std_logic;
        HPS_FLASH_NCSO  : out   std_logic;
        
        -- ====================================================================
        -- HPS SD Card
        -- ====================================================================
        HPS_SD_CLK      : out   std_logic;
        HPS_SD_CMD      : inout std_logic;
        HPS_SD_DATA     : inout std_logic_vector(3 downto 0);
        
        -- ====================================================================
        -- HPS USB OTG
        -- ====================================================================
        HPS_USB_CLKOUT  : in    std_logic;
        HPS_USB_DATA    : inout std_logic_vector(7 downto 0);
        HPS_USB_DIR     : in    std_logic;
        HPS_USB_NXT     : in    std_logic;
        HPS_USB_STP     : out   std_logic;
        
        -- ====================================================================
        -- HPS SPI
        -- ====================================================================
        HPS_SPI_CLK     : out   std_logic;
        HPS_SPI_MOSI    : out   std_logic;
        HPS_SPI_MISO    : in    std_logic;
        HPS_SPI_SS      : out   std_logic;
        
        -- ====================================================================
        -- HPS UART (Console)
        -- ====================================================================
        HPS_UART_RX     : in    std_logic;
        HPS_UART_TX     : out   std_logic;
        
        -- ====================================================================
        -- HPS I2C
        -- ====================================================================
        HPS_I2C0_SDAT   : inout std_logic;
        HPS_I2C0_SCLK   : inout std_logic;
        HPS_I2C1_SDAT   : inout std_logic;
        HPS_I2C1_SCLK   : inout std_logic;
        
        -- ====================================================================
        -- GPIO Header 0 (40-pin expansion header)
        -- Gebruik deze voor Matrix32 LED outputs
        -- ====================================================================
        GPIO_0          : inout std_logic_vector(35 downto 0);
        
        -- ====================================================================
        -- GPIO Header 1 (40-pin expansion header)
        -- ====================================================================
        GPIO_1          : inout std_logic_vector(35 downto 0)
    );
end entity DE1_SoC_top_level;

architecture rtl of DE1_SoC_top_level is
    
    -- ========================================================================
    -- Component Declaration voor soc_system (gegenereerd door Platform Designer)
    -- ========================================================================
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
    end component soc_system;
    
    -- ========================================================================
    -- Internal Signals
    -- ========================================================================
    signal reset_n : std_logic;
    
    -- Matrix32 LED signals
    signal matrix_r1, matrix_g1, matrix_b1 : std_logic;
    signal matrix_r2, matrix_g2, matrix_b2 : std_logic;
    signal matrix_a, matrix_b, matrix_c, matrix_d : std_logic;
    signal matrix_clk, matrix_lat, matrix_oe : std_logic;
    
    -- HPS signals (internal copies voor debugging)
    signal hps_eth_tx_en : std_logic;
    
begin
    
    -- ========================================================================
    -- Reset Logic
    -- KEY[0] is gebruikt als reset (active low)
    -- ========================================================================
    reset_n <= KEY(0);
    
    -- ========================================================================
    -- Debug LEDs
    -- Toon status van enkele HPS signalen op de onboard LEDs
    -- ========================================================================
    LEDR(0) <= reset_n;              -- LED0: Reset status
    LEDR(1) <= hps_eth_tx_en;        -- LED1: Ethernet TX activity (output from HPS)
    LEDR(2) <= HPS_ENET_RX_DV;       -- LED2: Ethernet RX activity (input to HPS)
    LEDR(3) <= '1';                  -- LED3: Power indicator
    LEDR(9 downto 4) <= (others => '0');
    
    -- Connect internal signal to output
    HPS_ENET_TX_EN <= hps_eth_tx_en;
    
    -- ========================================================================
    -- Matrix32 LED Output Mapping naar GPIO_0
    -- 
    -- Pin Assignment voor GPIO_0 (40-pin header):
    -- Let op: Pas dit aan volgens je werkelijke hardware aansluiting!
    -- ========================================================================
    
    -- RGB Data Upper Half (bits 0-16)
    GPIO_0(0)  <= matrix_r1;    -- R1
    GPIO_0(1)  <= matrix_g1;    -- G1
    GPIO_0(2)  <= matrix_b1;    -- B1
    
    -- RGB Data Lower Half (bits 17-32)
    GPIO_0(3)  <= matrix_r2;    -- R2
    GPIO_0(4)  <= matrix_g2;    -- G2
    GPIO_0(5)  <= matrix_b2;    -- B2
    
    -- Row Address (A, B, C, D)
    GPIO_0(6)  <= matrix_a;     -- A
    GPIO_0(7)  <= matrix_b;     -- B
    GPIO_0(8)  <= matrix_c;     -- C
    GPIO_0(9)  <= matrix_d;     -- D
    
    -- Control Signals
    GPIO_0(10) <= matrix_clk;   -- CLK (Shift clock)
    GPIO_0(11) <= matrix_lat;   -- LAT (Latch)
    GPIO_0(12) <= matrix_oe;    -- OE (Output Enable)
    
    -- Resterende GPIO_0 pins als inputs (tri-state)
    GPIO_0(35 downto 13) <= (others => 'Z');
    
    -- GPIO_1 niet gebruikt, alles tri-state
    GPIO_1 <= (others => 'Z');
    
    -- ========================================================================
    -- Platform Designer System Instantiation
    -- ========================================================================
    u0 : component soc_system
        port map (
            -- Clock & Reset
            clk_clk                         => CLOCK_50,
            reset_reset_n                   => reset_n,
            
            -- KEY Inputs
            key_external_export             => KEY,
            
            -- Matrix32 LED Outputs
            matrix_external_r1              => matrix_r1,
            matrix_external_g1              => matrix_g1,
            matrix_external_b1              => matrix_b1,
            matrix_external_r2              => matrix_r2,
            matrix_external_g2              => matrix_g2,
            matrix_external_b2              => matrix_b2,
            matrix_external_a               => matrix_a,
            matrix_external_b               => matrix_b,
            matrix_external_c               => matrix_c,
            matrix_external_d               => matrix_d,
            matrix_external_clk             => matrix_clk,
            matrix_external_lat             => matrix_lat,
            matrix_external_oe              => matrix_oe,
            
            -- HPS DDR3 Memory
            memory_mem_a                    => HPS_DDR3_ADDR,
            memory_mem_ba                   => HPS_DDR3_BA,
            memory_mem_ck                   => HPS_DDR3_CK_P,
            memory_mem_ck_n                 => HPS_DDR3_CK_N,
            memory_mem_cke                  => HPS_DDR3_CKE,
            memory_mem_cs_n                 => HPS_DDR3_CS_N,
            memory_mem_ras_n                => HPS_DDR3_RAS_N,
            memory_mem_cas_n                => HPS_DDR3_CAS_N,
            memory_mem_we_n                 => HPS_DDR3_WE_N,
            memory_mem_reset_n              => HPS_DDR3_RESET_N,
            memory_mem_dq                   => HPS_DDR3_DQ,
            memory_mem_dqs                  => HPS_DDR3_DQS_P,
            memory_mem_dqs_n                => HPS_DDR3_DQS_N,
            memory_mem_odt                  => HPS_DDR3_ODT,
            memory_mem_dm                   => HPS_DDR3_DM,
            memory_oct_rzqin                => HPS_DDR3_RZQ,
            
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

end architecture rtl;
