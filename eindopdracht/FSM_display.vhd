library ieee;
use ieee.std_logic_1164.all;

entity fsm_display is
	port (
        clk, rst: in std_ulogic;
        start_button, timer_repeated, collumn_filled: in std_ulogic;
		  --matrix outputs
        reset_matrix, enable_matrix, enable_latch, row_change: out std_ulogic;
		  --external unit outputs. 
		  reset_clk, reset_counter, enable_counter: out std_ulogic
    );
end fsm_display;

architecture behavior of fsm_display is
	--hier moet eigenlijk 2/4 states erbij
	--1 voor lezen, 1 voor schrijven. dubbel om terug te gaan naar de juiste state (of extra input/geheugen?
   type state_type is (IDLE, SHIFT_ROW, BRIGHTNESS_ADJUST, NEXT_ROW);
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
    process(pr_state, start_button, timer_repeated)
    begin
        case pr_state is
          when IDLE =>
				  --ik neem aan starten bij druk van een knop
              if start_button then
                nx_state <= SHIFT_ROW;
              else
                nx_state <= IDLE;
              end if;
            when SHIFT_ROW =>
				  if collumn_filled then
					 nx_state <= BRIGHTNESS_ADJUST;
				  else
				    nx_state <= SHIFT_ROW;
				  end if;
				when BRIGHTNESS_ADJUST =>
					 if timer_repeated then
						nx_state <= SHIFT_ROW;
				    else
						nx_state <= BRIGHTNESS_ADJUST;
					 end if;
				when NEXT_ROW =>
					nx_state <= SHIFT_ROW;
        end case;
    end process;

	 --what to do in state
    process(pr_state)
    begin
        case pr_state is
            when idle =>
					reset_matrix <= '1';
					enable_matrix <= '0';
               enable_latch <= '0';
					reset_clk <= '1';
					reset_counter <= '1';
					enable_counter <= '0';
					row_change <= '0';
					
            when SHIFT_ROW =>
				--gebeurt wanneer 1 rij klaar is. 
					reset_matrix <= '0';
					enable_matrix <= '1';
					enable_latch <= '0';
					reset_clk <= '0';
					reset_counter <= '1';
					enable_counter <= '0';
					row_change <= '0';
					
				when BRIGHTNESS_ADJUST =>
					reset_matrix <= '0';
               enable_matrix <= '0';
               enable_latch <= '1';
					reset_clk <= '0';
					reset_counter <= '0';
					enable_counter <= '1';
					row_change <= '0';
					
				when NEXT_ROW =>
					reset_matrix <= '0';
               enable_matrix <= '0';
               enable_latch <= '1';
					reset_clk <= '0';
					reset_counter <= '0';
					enable_counter <= '1';
					row_change <= '1';
        end case;
    end process;

end architecture;