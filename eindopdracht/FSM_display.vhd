library ieee;
use ieee.std_logic_1164.all;

entity fsm_display is
	port (
        clk, rst: in std_ulogic;
        start_button, timer_repeated, collumn_filled, write, write_done: in std_ulogic;
		  --matrix outputs
        reset_matrix, enable_matrix, enable_latch, row_change, write_matrix: out std_ulogic;
		  --external unit outputs. 
		  reset_clk, reset_counter, enable_counter: out std_ulogic
    );
end fsm_display;

architecture behavior of fsm_display is
	--hier moet eigenlijk 2/4 states erbij
	--1 voor lezen, 1 voor schrijven. dubbel om terug te gaan naar de juiste state (of extra input/geheugen?
   type state_type is (IDLE, SHIFT_ROW, GET_NEW_VALUE_TO_BRIGHTNESS_ADJUST, NEXT_ROW);
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
	 variable state_before_write: state_type;
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
					 nx_state <= NEXT_ROW;
				  else
					 nx_state <= SHIFT_ROW;
				  end if;
				when NEXT_ROW =>
					nx_state <= SHIFT_ROW;
				when GET_NEW_VALUE_TO_BRIGHTNESS_ADJUST =>
					 if write_done then
						nx_state <= SHIFT_ROW;
					 else
						nx_state <= GET_NEW_VALUE_TO_BRIGHTNESS_ADJUST;
					 end if;
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
					write_matrix <= '0';
					
            when SHIFT_ROW =>
				--gebeurt wanneer 1 rij klaar is. 
					reset_matrix <= '0';
					enable_matrix <= '1';
					enable_latch <= '0';
					reset_clk <= '0';
					reset_counter <= '0';
					enable_counter <= '0';
					row_change <= '0';
					write_matrix <= '0';
				when NEXT_ROW =>
					reset_matrix <= '0';
               enable_matrix <= '0';
     				enable_latch <= '1';
					reset_clk <= '0';
					reset_counter <= '1';
					enable_counter <= '0';
					row_change <= '1';
					write_matrix <= '0';

				when GET_NEW_VALUE_TO_BRIGHTNESS_ADJUST =>
					reset_matrix <= '0';
               				enable_matrix <= '1';
               				enable_latch <= '1';
					reset_clk <= '0';
					reset_counter <= '0';
					enable_counter <= '1';
					row_change <= '0';
					write_matrix <= '1';
				
        end case;
    end process;

end architecture;