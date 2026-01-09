library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rgb_framebuffer is
    port (
        -- Clock en Reset (Platform Designer interface names)
        clock           : in  std_logic;
        reset           : in  std_logic;
		  red_vector_0		: in std_logic_vector(31 downto 0);
		  blue_vector_0	: in std_logic_vector(31 downto 0);
		  green_vector_0	: in std_logic_vector(31 downto 0);
        
		  red_vector_1		: in std_logic_vector(31 downto 0);
		  blue_vector_1	: in std_logic_vector(31 downto 0);
		  green_vector_1	: in std_logic_vector(31 downto 0);
        
        -- RGB Matrix Output Conduit
        matrix_r1     : out std_logic;
        matrix_g1     : out std_logic;
        matrix_b1     : out std_logic;
        matrix_r2     : out std_logic;
        matrix_g2     : out std_logic;
        matrix_b2     : out std_logic;
        matrix_addr_a : out std_logic;
        matrix_addr_b : out std_logic;
        matrix_addr_c : out std_logic;
        matrix_clk    : out std_logic;
        matrix_lat    : out std_logic;
        matrix_oe_n   : out std_logic
    );
end entity rgb_framebuffer;

architecture rtl of rgb_framebuffer is
    -- Framebuffer RAM (32x32 pixels, elk 32-bit RGB)
    type ram_type is array (0 to 1023) of std_logic_vector(31 downto 0);
    signal framebuffer : ram_type := (others => (others => '0'));
    
    -- Scanning signals
    signal row_addr : unsigned(2 downto 0) := (others => '0');  -- 0-7 voor 8 rij-paren
    signal col_count : unsigned(4 downto 0) := (others => '0'); -- 0-31 voor 32 kolommen
    
    -- Clock divider (50MHz → ~1MHz voor shift clock)
    signal clk_counter : unsigned(5 downto 0) := (others => '0');
    signal shift_clk : std_logic := '0';
    
    --FSM display
    type state_type is (IDLE, SHIFT, LATCH, DISPLAY, NEXT_ROW);
    signal state : state_type := IDLE;
    
    
    -- Pixel data voor huidige kolom
    signal pixel1 : std_logic_vector(23 downto 0); -- Upper half (row 0-15)
    signal pixel2 : std_logic_vector(23 downto 0); -- Lower half (row 16-31)
    
    -- Shift clock output
    signal matrix_clk_internal : std_logic := '0';
    
    -- Display timer
    signal display_counter : unsigned(7 downto 0) := (others => '0');
    
	 --wordt dit uberhaubt gebruikt??
--    -- PWM voor helderheid (bit-plane modulation)
--    signal pwm_counter : unsigned(7 downto 0) := (others => '0');
    signal bit_plane : unsigned(2 downto 0) := (others => '0'); -- 0-7 voor 8-bit kleur
	 
	--gemaakt in hwp01. is volledig getest en zou gwn moeten werken. 
	component pwm_generator is
		generic(
			divisor: natural;--deling om van 50MHz naar 1Hz
			duty_cycle: natural--waardes van 100 tot 0
		);
		port(
			input_clock: in std_ulogic;
			reset: in std_ulogic;
			output_clock: out std_ulogic
		);
	end component;
	
	component clock_divider is
	generic(
		divisor: natural--deling om van 50MHz naar 1Hz
	);
	port(
		input_clock: in std_ulogic;
		reset: in std_ulogic;
		output_clock: out std_ulogic
	);
	end component;
begin
    
	--mag in principe ook zo weg. avalon interface is een laag hoger
	-- en zit in zijn eigen vhd bestand
	-- zie reg32_avalon_slave.vhd
--    -- Avalon-MM Interface: Read/Write naar framebuffer
--    process(clock_sink_clk, reset_sink_reset)
--    begin
--        if reset_sink_reset = '1' then
--            framebuffer <= (others => (others => '0'));
--            avalon_slave_readdata <= (others => '0');
--            avalon_slave_waitrequest <= '0';
--        elsif rising_edge(clock_sink_clk) then
--            avalon_slave_waitrequest <= '0';
--            
--            -- Write naar framebuffer
--            if avalon_slave_write = '1' then
--                framebuffer(to_integer(unsigned(avalon_slave_address))) <= avalon_slave_writedata;
--            end if;
--            
--            -- Read van framebuffer
--            if avalon_slave_read = '1' then
--                avalon_slave_readdata <= framebuffer(to_integer(unsigned(avalon_slave_address)));
--            end if;
--        end if;
--    end process;
    
	--included clock divider van hwp01. is betrouwbaarder (en meer in hoe vhdl bedoelt is) 
	--dan wat AI nu genereert (alles in 1 file proppen
--    -- Clock divider voor shift clock
--    process(clock_sink_clk, reset_sink_reset)
--    begin
--        if reset_sink_reset = '1' then
--            clk_counter <= (others => '0');
--            shift_clk <= '0';
--        elsif rising_edge(clock_sink_clk) then
--            clk_counter <= clk_counter + 1;
--            
--            -- Toggle elke 25 cycles (50MHz / 50 = 1MHz shift clock)
--            if clk_counter = 24 then
--                shift_clk <= not shift_clk;
--                clk_counter <= (others => '0');
--            end if;
--        end if;
--    end process;

	 output_clock: clock_divider
	 generic map (
		divisor => 25)
	 port map (
		input_clock => clock,
		reset => reset,
		output_clock =>matrix_clk_internal
	 );
    
	 --werkt waarschijnlijk, maar FSM is niet volgens template
	 --Quartus zal waarschijnlijk niet zien dat dit een FSM is
	 
	 --persoonlijk, de template is beter leesbaar(?)
    -- Matrix Scanning FSM
    process(clock_sink_clk, reset_sink_reset)
        variable upper_row : integer range 0 to 31;
        variable lower_row : integer range 0 to 31;
        variable pixel_addr1 : integer range 0 to 1023;
        variable pixel_addr2 : integer range 0 to 1023;
    begin
        if reset_sink_reset = '1' then
            state <= IDLE;
            row_addr <= (others => '0');
            col_count <= (others => '0');
            matrix_clk_internal <= '0';
            matrix_lat <= '0';
            matrix_oe_n <= '1';  -- Disabled
            bit_plane <= (others => '0');
            pwm_counter <= (others => '0');
            display_counter <= (others => '0');
            
        elsif rising_edge(clock_sink_clk) then
            
            case state is
                
                when IDLE =>
                    col_count <= (others => '0');
                    matrix_oe_n <= '1';  -- Disable output
                    matrix_lat <= '0';
                    state <= SHIFT;
                    
                when SHIFT =>
                    -- Clock data uit naar shift registers
                    if shift_clk = '1' and clk_counter = 0 then
                        -- Calculate addresses voor current column en row
                        upper_row := to_integer(row_addr);              -- 0-7
                        lower_row := to_integer(row_addr) + 16;         -- 16-23
                        
                        -- Address = Y * 32 + X
                        pixel_addr1 := upper_row * 32 + to_integer(col_count);
                        pixel_addr2 := lower_row * 32 + to_integer(col_count);
                        
                        -- Fetch pixel data
                        pixel1 <= framebuffer(pixel_addr1)(23 downto 0);
                        pixel2 <= framebuffer(pixel_addr2)(23 downto 0);
                        
                        -- Clock toggle
                        matrix_clk_internal <= '1';
                        
                        -- Next column
                        if col_count = 31 then
                            col_count <= (others => '0');
                            state <= LATCH;
                        else
                            col_count <= col_count + 1;
                        end if;
                    elsif shift_clk = '0' and clk_counter = 0 then
                        matrix_clk_internal <= '0';
                    end if;
                    
                when LATCH =>
                    -- Latch data in LED drivers
                    matrix_clk_internal <= '0';
                    matrix_lat <= '1';
                    display_counter <= (others => '0');
                    state <= DISPLAY;
                    
                when DISPLAY =>
                    -- Enable output en wacht
                    matrix_lat <= '0';
                    matrix_oe_n <= '0';  -- Enable output
                    
                    -- Wait voor brightness control
                    display_counter <= display_counter + 1;
                    
                    -- Display tijd afhankelijk van bit plane (2^bit_plane cycles)
                    if display_counter = shift_left(to_unsigned(1, 8), to_integer(bit_plane)) then
                        matrix_oe_n <= '1';  -- Disable output
                        state <= NEXT_ROW;
                    end if;
                    
                when NEXT_ROW =>
                    -- Next bit plane of next row
                    if bit_plane = 7 then
                        bit_plane <= (others => '0');
                        
                        -- Next row pair
                        if row_addr = 7 then
                            row_addr <= (others => '0');
                        else
                            row_addr <= row_addr + 1;
                        end if;
                    else
                        bit_plane <= bit_plane + 1;
                    end if;
                    
                    state <= IDLE;
                    
                when others =>
                    state <= IDLE;
                    
            end case;
        end if;
    end process;
    
    -- Output RGB bits gebaseerd op bit-plane modulation
    -- Compare current bit of color met bit_plane
    process(pixel1, pixel2, bit_plane)
        variable bit_pos : integer range 0 to 7;
    begin
        bit_pos := to_integer(bit_plane);
        
        -- Upper half (R1, G1, B1)
        matrix_r1 <= pixel1(16 + bit_pos);  -- Red bits 16-23
        matrix_g1 <= pixel1(8 + bit_pos);   -- Green bits 8-15
        matrix_b1 <= pixel1(bit_pos);       -- Blue bits 0-7
        
        -- Lower half (R2, G2, B2)
        matrix_r2 <= pixel2(16 + bit_pos);
        matrix_g2 <= pixel2(8 + bit_pos);
        matrix_b2 <= pixel2(bit_pos);
    end process;
    
    -- Output assignments
    matrix_addr_a <= std_logic(row_addr(0));
    matrix_addr_b <= std_logic(row_addr(1));
    matrix_addr_c <= std_logic(row_addr(2));
    matrix_clk <= matrix_clk_internal;
    
end architecture rtl;
