library ieee;
use ieee.std_logic_1164.all;

entity fsm_display is
	port (
        clk, rst: in std_ulogic;
        start_button, input2, ...: in std_ulogic;
        reset_buffer, reset_clk, freeze_matrix: out std_ulogic
    );
end fsm_display;

architecture behavior of fsm_display is
   type state_type is (IDLE, SHIFT, LATCH, DISPLAY, NEXT_ROW);
	signal pr_state, nx_state: state_type;
begin

    process(clk, rst)
    begin
        if rst then
            pr_state <= idle;
        elsif rising_edge(clk) then
            pr_state <= nx_state;
        end if;
    end process;

	 --when to change to new state
    process(pr_state, start_button, input2, ...)
    begin
        case pr_state is
          when IDLE =>
				  --ik neem aan starten bij druk van een knop
              if start_button then
                nx_state <= SHIFT;
              else
                nx_state <= IDLE;
              end if;
            when SHIFT =>
				  if freezing_but then
				    nx_state <= freeze;--latch??
				  else
				    nx_state <= SHIFT;
				  end if;
            when LATCH =>
                ...;
            when DISPLAY =>
                ...;
				when NEXT_ROW =>
					 ...;
        end case;
    end process;

	 --what to do in state
    process(pr_state)
    begin
        case pr_state is
            when idle =>
					reset_buffer = '1';
					reset_clock = '1';
					freeze_matrix = '1';
            when SHIFT =>
					reset_buffer = '0';
					reset_clock = '0';
                freeze_matrix = '0';
            when LATCH =>
                ...;
            when DISPLAY =>
                ...;
				when NEXT_ROW =>
					...;
        end case;
    end process;

end architecture;


    process(clock_sink_clk, reset_sink_reset)
        variable upper_row : integer range 0 to 31;
        variable lower_row : integer range 0 to 31;
        variable pixel_addr1 : integer range 0 to 1023;
        variable pixel_addr2 : integer range 0 to 1023;
    begin
        if reset_sink_reset = '1' then
            state <= IDLE;

            
        elsif rising_edge(clock_sink_clk) then
            
            case state is
                
                when IDLE =>
                    col_count <= (others => '0');
                    matrix_oe_n <= '1';  -- Disable output
                    matrix_lat <= '0';
						  --wanneer willen we beginnen??
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