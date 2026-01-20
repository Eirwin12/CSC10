library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity nibble_count is
	generic (max_count: natural:=9);
	port(
		klok, reset, enable: in std_ulogic;
		count: out std_ulogic_vector(7 downto 0);
		count_done: out std_ulogic
	);
end entity;

architecture imp of nibble_count is
	signal onthoud_waarde: std_ulogic_vector(7 downto 0) := (others => '0');--standaard ':=' voor inital value
begin
	count <= onthoud_waarde;
	process(klok, reset)
		variable temp: unsigned(3 downto 0);
	begin
		if reset = '0' then
			onthoud_waarde <= 8x"0";
			count_done <= '0';
		elsif enable = '1' and rising_edge(klok) then --bij rising edge optellen
			temp := unsigned(onthoud_waarde)+1;
			--alle andere gevallen, doe niks
			if temp >=10 then
				onthoud_waarde<=8x"0";
				count_done <= '1';
			else
				onthoud_waarde<= std_ulogic_vector(temp);
			end if;
		end if;
	end process;
end architecture;