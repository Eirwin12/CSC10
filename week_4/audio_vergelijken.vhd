ENTITY audio IS
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
END audio ;

architecture imp of audio is 


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
            leds_export       => CONNECTED_TO_leds_export,       --         leds.export
            reset_reset_n     => CONNECTED_TO_reset_reset_n,     --        reset.reset_n
            switches_export   => CONNECTED_TO_switches_export,   --     switches.export
            audio_ADCDAT      => CONNECTED_TO_audio_ADCDAT,      --        audio.ADCDAT
            audio_ADCLRCK     => CONNECTED_TO_audio_ADCLRCK,     --             .ADCLRCK
            audio_BCLK        => CONNECTED_TO_audio_BCLK,        --             .BCLK
            audio_DACDAT      => CONNECTED_TO_audio_DACDAT,      --             .DACDAT
            audio_DACLRCK     => CONNECTED_TO_audio_DACLRCK,     --             .DACLRCK
            audio_config_SDAT => CONNECTED_TO_audio_config_SDAT, -- audio_config.SDAT
            audio_config_SCLK => CONNECTED_TO_audio_config_SCLK, --             .SCLK
            clk_clk           => CONNECTED_TO_clk_clk,           --          clk.clk
            audio_clk_clk     => CONNECTED_TO_audio_clk_clk      --    audio_clk.clk
        );


end imp;