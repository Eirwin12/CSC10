library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY audio_vergelijken IS
	PORT (
		CLOCK_50 : IN STD_LOGIC ;
		KEY : IN STD_LOGIC_VECTOR (0 DOWNTO 0) ;
		SW : IN STD_LOGIC_VECTOR (9 DOWNTO 0) ;
		LEDR : OUT STD_LOGIC_VECTOR (9 DOWNTO 0) ;
		AUD_ADCDAT : IN STD_LOGIC ;
		AUD_ADCLRCK : INOUT STD_LOGIC ;
		AUD_BCLK : INOUT STD_LOGIC ;
		AUD_DACDAT : OUT STD_LOGIC ;
		AUD_DACLRCK : INOUT STD_LOGIC ;
		AUD_XCK : OUT STD_LOGIC ;
		FPGA_I2C_SDAT : INOUT STD_LOGIC ;
		FPGA_I2C_SCLK : OUT STD_LOGIC
	);
END audio_vergelijken;

architecture imp of audio_vergelijken is 

    component audio is
        port (
            leds_export       : out   std_logic_vector(9 downto 0);                    -- export
            reset_reset_n     : in    std_logic                    := 'X';             -- reset_n
            switches_export   : in    std_logic_vector(9 downto 0) := (others => 'X'); -- export
            audio_ADCDAT      : in    std_logic                    := 'X';             -- ADCDAT
            audio_ADCLRCK     : in    std_logic                    := 'X';             -- ADCLRCK
            audio_BCLK        : in    std_logic                    := 'X';             -- BCLK
            audio_DACDAT      : out   std_logic;                                       -- DACDAT
            audio_DACLRCK     : in    std_logic                    := 'X';             -- DACLRCK
            audio_config_SDAT : inout std_logic                    := 'X';             -- SDAT
            audio_config_SCLK : out   std_logic;                                       -- SCLK
            clk_clk           : in    std_logic                    := 'X';             -- clk
            audio_clk_clk     : out   std_logic                                        -- clk
        );
    end component audio;
	 
begin
    u0 : component audio
        port map (
            leds_export       => LEDR,       			  --     leds.export
            reset_reset_n     => KEY(0),   				  --     reset.reset_n
            switches_export   => SW,   					  --     switches.export
            audio_ADCDAT      => AUD_ADCDAT,      		  --     audio.ADCDAT
            audio_ADCLRCK     => AUD_ADCLRCK,     		  --          .ADCLRCK
            audio_BCLK        => AUD_BCLK,        		  --          .BCLK
            audio_DACDAT      => AUD_DACDAT,      		  --          .DACDAT
            audio_DACLRCK     => AUD_DACLRCK,     		  --          .DACLRCK
            audio_config_SDAT => FPGA_I2C_SDAT, 		  --	   audio_config.SDAT
            audio_config_SCLK => FPGA_I2C_SCLK,         --                 .SCLK
            clk_clk           => CLOCK_50,              --     clk.clk
            audio_clk_clk     => AUD_XCK      			  --     audio_clk.clk
        );
end imp;