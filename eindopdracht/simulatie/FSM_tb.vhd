library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench_fsm is
end entity;

architecture tb of testbench_fsm is

	component fsm_display is
		port (
		        clk, rst: in std_ulogic;
		        start_button, timer_repeated, collumn_filled, write, write_done: in std_ulogic;
			--matrix outputs
		        reset_matrix, enable_matrix, enable_latch, row_change, write_matrix: out std_ulogic;
			--external unit outputs. 
			reset_clk, reset_counter, enable_counter: out std_ulogic
	    );
	end component;
	signal clock_tb, reset_tb: std_ulogic := '0';
	signal start_button_tb, timer_repeated_tb, collumn_filled_tb, write_tb, write_done_tb: std_ulogic;
	signal reset_matrix_tb, enable_matrix_tb, enable_latch_tb, row_change_tb, write_matrix_tb: std_ulogic;
	signal reset_clk_tb, reset_counter_tb, enable_counter_tb: std_ulogic;
	constant CLOCK_CYCLE: time := 20 ns;
begin
	dut: fsm_display
	port map (
		clk => clock_tb,
		rst => reset_tb,
		start_button => start_button_tb,
		timer_repeated => timer_repeated_tb,
		collumn_filled => collumn_filled_tb,
		write => write_tb,
		write_done => write_done_tb,
		reset_matrix => reset_matrix_tb,
		enable_matrix => enable_matrix_tb,
		enable_latch => enable_latch_tb, 
		row_change => row_change_tb,
		write_matrix => write_matrix_tb,
		reset_clk => reset_clk_tb, 
		reset_counter => reset_counter_tb, 
		enable_counter => enable_counter_tb
	);
	clock_tb <= clock_tb xor '1' after CLOCK_CYCLE/2;
	process
	begin
		wait for CLOCK_CYCLE;
		--aanname: ik start in idle
		assert reset_matrix_tb = '1' report "matrix not in reset" severity error;
		assert enable_matrix_tb = '0' report "matrix is enabled" severity error;
		assert enable_latch_tb = '0' report "latch isn't on" severity error;
		assert reset_clk_tb = '1' report "clock isn't reset" severity error;
		assert reset_counter_tb = '1' report "counter isn't reset" severity error;
		assert enable_counter_tb = '0' report "counter isn't enabled" severity error;
		assert row_change_tb = '0' report "writting while we shouldn't be able to" severity error;
		assert write_matrix_tb = '0' report "can write to matrix, while it should be possible" severity error;

		start_button_tb <= '1';
		--zet systeem aan
		wait for CLOCK_CYCLE;
		assert reset_matrix_tb = '0' report "matrix in reset" severity error;
		assert enable_matrix_tb = '1' report "matrix isn't enabled" severity error;
		assert enable_latch_tb = '0' report "latch isn't on" severity error;
		assert reset_clk_tb = '0' report "clock is reset" severity error;
		assert reset_counter_tb = '1' report "counter isn't reset" severity error;
		assert enable_counter_tb = '0' report "counter isn't enabled" severity error;
		assert row_change_tb = '0' report "writting while we shouldn't be able to" severity error;
		assert write_matrix_tb = '0' report "can write to matrix, while it should be possible" severity error;

		wait for CLOCK_CYCLE;
		collumn_filled_tb <= '1';
		start_button_tb <= '0';
		--moet nu in brightness adjust. 
		wait for CLOCK_CYCLE;
		assert reset_matrix_tb = '0' report "matrix not in reset" severity error;
		assert enable_matrix_tb = '1' report "matrix isn't enabled" severity error;
		assert enable_latch_tb = '1' report "latch isn't on" severity error;
		assert reset_clk_tb = '0' report "clock isn't reset" severity error;
		assert reset_counter_tb = '0' report "counter is reset" severity error;
		assert enable_counter_tb = '1' report "counter is enabled" severity error;
		assert row_change_tb = '0' report "writting while we shouldn't be able to" severity error;
		assert write_matrix_tb = '0' report "can write to matrix, while it should be possible" severity error;

		--blijf 1 cycle om de volgende rij te bepalen
		collumn_filled_tb <= '0';
		timer_repeated_tb <= '1';
		wait for CLOCK_CYCLE;
		assert reset_matrix_tb = '0' report "matrix not in reset" severity error;
		assert enable_matrix_tb = '1' report "matrix isn't enabled" severity error;
		assert row_change_tb = '1' report "writting while we shouldn't be able to" severity error;

		--zet terug naar running
		wait for CLOCK_CYCLE;
		assert reset_matrix_tb = '0' report "matrix in reset" severity error;
		assert enable_matrix_tb = '1' report "matrix isn't enabled" severity error;
		assert enable_latch_tb = '0' report "latch isn't on" severity error;
		assert reset_clk_tb = '0' report "clock is reset" severity error;
		assert reset_counter_tb = '1' report "counter isn't reset" severity error;
		assert enable_counter_tb = '0' report "counter isn't enabled" severity error;
		assert row_change_tb = '0' report "writting while we shouldn't be able to" severity error;
		assert write_matrix_tb = '0' report "can write to matrix, while it should be possible" severity error;

		--zet in brightness control en dan in get new value 
		collumn_filled_tb <= '1';
		wait for CLOCK_CYCLE;
		write_tb <= '1';
		write_done_tb <= '0';
		wait for CLOCK_CYCLE;
		assert write_matrix_tb = '1' report "can't write to matrix, while it should be possible" severity error;
		write_done_tb <= '1';
		wait for CLOCK_CYCLE;
		assert write_matrix_tb = '0' report "can write to matrix, while it should be possible" severity error;
		
		--reset teset.
		reset_tb <= '1';
		wait for CLOCK_CYCLE;
		reset_tb <= '0';
		--aanname: ik start in idle
		assert reset_matrix_tb = '1' report "matrix not in reset" severity error;
		assert enable_matrix_tb = '0' report "matrix is enabled" severity error;
		assert enable_latch_tb = '0' report "latch isn't on" severity error;
		assert reset_clk_tb = '1' report "clock isn't reset" severity error;
		assert reset_counter_tb = '1' report "counter isn't reset" severity error;
		assert enable_counter_tb = '0' report "counter isn't enabled" severity error;
		assert row_change_tb = '0' report "writting while we shouldn't be able to" severity error;
		assert write_matrix_tb = '0' report "can write to matrix, while it should be possible" severity error;
		report "Test completed.";
		std.env.stop;
	end process;
end architecture;