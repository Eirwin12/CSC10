library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM_generator is
	generic(
		divisor: natural := 50e6;--deling om van 50MHz naar 1Hz
		duty_cycle: natural := 50--waardes van 100 tot 0
	);
	port(
		input_clock: in std_ulogic;
		reset: in std_ulogic;
		output_clock: out std_ulogic
	);
end entity;

architecture imp of PWM_generator is
	constant period: natural := divisor*2;
	constant on_period: natural := period/100*duty_cycle;--eerst period*duty_cycle/100. geeft te grote waarde?
begin
	process(input_clock, reset)
	variable count: natural :=0;
	begin
		if not reset then
			count :=0;
			output_clock <= '0';
		elsif rising_edge(input_clock) then
			if count < on_period then
				output_clock <= '1';
			else
				output_clock <= '0';
			end if;
			if count = period then
				count := 0;
			else
				count := count+1;
			end if;
--			output_clock <= '1' when (count < divisor) else '0';
--			count <= 0 when (count = double_div) else (count + 1);
		end if;
	end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_divider is
	generic(
		divisor: natural := 50e6--deling om van 50MHz naar 1Hz
	);
	port(
		input_clock: in std_ulogic;
		reset: in std_ulogic;
		output_clock: out std_ulogic
	);
end entity;

architecture imp of clock_divider is
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
	constant duty_cycle_50: natural := 50;
begin
	clk_div: pwm_generator
	generic map(
		divisor => divisor,
		duty_cycle => duty_cycle_50
	)
	port map(
		input_clock => input_clock,
		reset => reset,
		output_clock => output_clock
	);
end architecture;