library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hps_demo is
	port (
		      clock_50                       : in    std_logic                     := 'X';             -- clk
            hps_io_hps_io_gpio_inst_GPIO53 : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO63
            hps_io_hps_io_gpio_inst_GPIO54 : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO64
            ledr                    		 : out   std_logic_vector(7 downto 0);                     -- export
            memory_mem_a                   : out   std_logic_vector(12 downto 0);                    -- mem_a
            memory_mem_ba                  : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                  : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                 : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n               : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n               : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n             : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                  : inout std_logic_vector(7 downto 0)  := (others => 'X'); -- mem_dq
            memory_mem_dqs                 : inout std_logic                     := 'X';             -- mem_dqs
            memory_mem_dqs_n               : inout std_logic                     := 'X';             -- mem_dqs_n
            memory_mem_odt                 : out   std_logic;                                        -- mem_odt
            memory_mem_dm                  : out   std_logic;                                        -- mem_dm
            memory_oct_rzqin               : in    std_logic                     := 'X';				  -- oct_rzqin
            key                  			 : in    std_logic_vector(1 downto 1)  := (others => 'X'); -- reset_n
            SW                				 : in    std_logic_vector(7 downto 0)  := (others => 'X')  -- export
				);
end entity;

architecture hps of hps_demo is

    component hps_systeem is
        port (
            clk_clk                        : in    std_logic                     := 'X';             -- clk
            hps_io_hps_io_gpio_inst_GPIO53 : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO63
            hps_io_hps_io_gpio_inst_GPIO54 : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO64
            leds_export                    : out   std_logic_vector(7 downto 0);                     -- export
            memory_mem_a                   : out   std_logic_vector(12 downto 0);                    -- mem_a
            memory_mem_ba                  : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                  : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                 : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n               : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n               : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n             : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                  : inout std_logic_vector(7 downto 0)  := (others => 'X'); -- mem_dq
            memory_mem_dqs                 : inout std_logic                     := 'X';             -- mem_dqs
            memory_mem_dqs_n               : inout std_logic                     := 'X';             -- mem_dqs_n
            memory_mem_odt                 : out   std_logic;                                        -- mem_odt
            memory_mem_dm                  : out   std_logic;                                        -- mem_dm
            memory_oct_rzqin               : in    std_logic                     := 'X';             -- oct_rzqin
            reset_reset_n                  : in    std_logic                     := 'X';             -- reset_n
            switches_export                : in    std_logic_vector(7 downto 0)  := (others => 'X')  -- export
        );
    end component hps_systeem;
begin
    u0 : component hps_systeem
        port map (
            clk_clk                        => clock_50,                       --      clk.clk
            hps_io_hps_io_gpio_inst_GPIO53 => hps_io_hps_io_gpio_inst_GPIO53, --   hps_io.hps_io_gpio_inst_GPIO63
            hps_io_hps_io_gpio_inst_GPIO54 => hps_io_hps_io_gpio_inst_GPIO54, --         .hps_io_gpio_inst_GPIO64
            leds_export                    => ledr			,                    --     leds.export
            memory_mem_a                   => memory_mem_a,                   --   memory.mem_a
            memory_mem_ba                  => memory_mem_ba,                  --         .mem_ba
            memory_mem_ck                  => memory_mem_ck,                  --         .mem_ck
            memory_mem_ck_n                => memory_mem_ck_n,                --         .mem_ck_n
            memory_mem_cke                 => memory_mem_cke,                 --         .mem_cke
            memory_mem_cs_n                => memory_mem_cs_n,                --         .mem_cs_n
            memory_mem_ras_n               => memory_mem_ras_n,               --         .mem_ras_n
            memory_mem_cas_n               => memory_mem_cas_n,               --         .mem_cas_n
            memory_mem_we_n                => memory_mem_we_n,                --         .mem_we_n
            memory_mem_reset_n             => memory_mem_reset_n,             --         .mem_reset_n
            memory_mem_dq                  => memory_mem_dq,                  --         .mem_dq
            memory_mem_dqs                 => memory_mem_dqs,                 --         .mem_dqs
            memory_mem_dqs_n               => memory_mem_dqs_n,               --         .mem_dqs_n
            memory_mem_odt                 => memory_mem_odt,                 --         .mem_odt
            memory_mem_dm                  => memory_mem_dm,                  --         .mem_dm
            memory_oct_rzqin               => memory_oct_rzqin,               --         .oct_rzqin
            reset_reset_n                  => key(1),   			               --    reset.reset_n
            switches_export                => sw               				   -- switches.export
        );
end architecture;