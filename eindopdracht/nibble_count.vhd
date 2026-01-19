library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity counter is
	generic (max_count: natural:=9);
	port(
		klok, reset, enable: in std_ulogic;
		count: out std_ulogic_vector(7 downto 0);
		count_done: out std_ulogic
	);
end entity;

architecture imp of counter is

begin
	process(klok, reset)
		variable onthoud_waarde: unsigned(7 downto 0):= 7x"0";
	begin
		if reset = '1' then
			onthoud_waarde <= 7x"0";
			count_done <= '0';
		elsif enable = '1' and rising_edge(klok) then --bij rising edge optellen
			onthoud_waarde := onthoud_waarde+1;
			if onthoud_waarde >=max_count then
				count_done <= '1';
			end if;
			count <= onthoud_waarde;
		--alle andere gevallen, doe niks
		end if;
	end process;
end architecture;