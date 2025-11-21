-- altera vhdl_input_version vhdl_2008
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY hex7seg IS

	port (
		clock, resetn : in std_logic;
		write, chipselect : in std_logic;
		writedata : in std_logic_vector(31 downto 0);
		byteenable : in std_logic_vector(3 downto 0);
		display : OUT STD_LOGIC_VECTOR(55 downto 0)
	);
END hex7seg;

ARCHITECTURE Behavior OF hex7seg IS

	function hex_to_7_seg(
					number: std_logic_vector
					)return std_logic_vector is
		variable output: std_logic_vector(6 downto 0);
	begin
		case number is
			WHEN "0000" => output := "0000001";
			WHEN "0001" => output := "1001111";
			WHEN "0010" => output := "0010010";
			WHEN "0011" => output := "0000110";
			WHEN "0100" => output := "1001100";
			WHEN "0101" => output := "0100100";
			WHEN "0110" => output := "0100000";
			WHEN "0111" => output := "0001111";
			WHEN "1000" => output := "0000000";
			WHEN "1001" => output := "0001100";
			WHEN "1010" => output := "0001000";
			WHEN "1011" => output := "1100000";
			WHEN "1100" => output := "0110001";
			WHEN "1101" => output := "1000010";
			WHEN "1110" => output := "0110000";
			WHEN "1111" => output := "0111000";
		END CASE;
		return output;
	end function;

BEGIN
	--    - 0 -
	-- 5 |     | 1
	--    - 6 -
	-- 4 |     | 2
	--    - 3 -
	display <= reg_display;
	PROCESS (clock, resetn)
	BEGIN
		if resetn = '1' then
			reg_display <= (others => '0');
		elsif rising_edge(clock) then
			if chipselect = '1' then
				if write = '1' then
					if byteenable(0) then
						case writedata	(3 downto 0) is
							WHEN "0000" => reg_display(6 downto 0) <= "0000001";
							WHEN "0001" => reg_display(6 downto 0) <= "1001111";
							WHEN "0010" => reg_display(6 downto 0) <= "0010010";
							WHEN "0011" => reg_display(6 downto 0) <= "0000110";
							WHEN "0100" => reg_display(6 downto 0) <= "1001100";
							WHEN "0101" => reg_display(6 downto 0) <= "0100100";
							WHEN "0110" => reg_display(6 downto 0) <= "0100000";
							WHEN "0111" => reg_display(6 downto 0) <= "0001111";
							WHEN "1000" => reg_display(6 downto 0) <= "0000000";
							WHEN "1001" => reg_display(6 downto 0) <= "0001100";
							WHEN "1010" => reg_display(6 downto 0) <= "0001000";
							WHEN "1011" => reg_display(6 downto 0) <= "1100000";
							WHEN "1100" => reg_display(6 downto 0) <= "0110001";
							WHEN "1101" => reg_display(6 downto 0) <= "1000010";
							WHEN "1110" => reg_display(6 downto 0) <= "0110000";
							WHEN "1111" => reg_display(6 downto 0) <= "0111000";
						END CASE;
						case writedata(7 downto 4) is
							WHEN "0000" => reg_display(13 downto 7) <= "0000001";
							WHEN "0001" => reg_display(13 downto 7) <= "1001111";
							WHEN "0010" => reg_display(13 downto 7) <= "0010010";
							WHEN "0011" => reg_display(13 downto 7) <= "0000110";
							WHEN "0100" => reg_display(13 downto 7) <= "1001100";
							WHEN "0101" => reg_display(13 downto 7) <= "0100100";
							WHEN "0110" => reg_display(13 downto 7) <= "0100000";
							WHEN "0111" => reg_display(13 downto 7) <= "0001111";
							WHEN "1000" => reg_display(13 downto 7) <= "0000000";
							WHEN "1001" => reg_display(13 downto 7) <= "0001100";
							WHEN "1010" => reg_display(13 downto 7) <= "0001000";
							WHEN "1011" => reg_display(13 downto 7) <= "1100000";
							WHEN "1100" => reg_display(13 downto 7) <= "0110001";
							WHEN "1101" => reg_display(13 downto 7) <= "1000010";
							WHEN "1110" => reg_display(13 downto 7) <= "0110000";
							WHEN "1111" => reg_display(13 downto 7) <= "0111000";
						END CASE;
					elsif byteenable(1) then
						case writedata(11 downto 8) is
							WHEN "0000" => reg_display(20 downto 14) <= "0000001";
							WHEN "0001" => reg_display(20 downto 14) <= "1001111";
							WHEN "0010" => reg_display(20 downto 14) <= "0010010";
							WHEN "0011" => reg_display(20 downto 14) <= "0000110";
							WHEN "0100" => reg_display(20 downto 14) <= "1001100";
							WHEN "0101" => reg_display(20 downto 14) <= "0100100";
							WHEN "0110" => reg_display(20 downto 14) <= "0100000";
							WHEN "0111" => reg_display(20 downto 14) <= "0001111";
							WHEN "1000" => reg_display(20 downto 14) <= "0000000";
							WHEN "1001" => reg_display(20 downto 14) <= "0001100";
							WHEN "1010" => reg_display(20 downto 14) <= "0001000";
							WHEN "1011" => reg_display(20 downto 14) <= "1100000";
							WHEN "1100" => reg_display(20 downto 14) <= "0110001";
							WHEN "1101" => reg_display(20 downto 14) <= "1000010";
							WHEN "1110" => reg_display(20 downto 14) <= "0110000";
							WHEN "1111" => reg_display(20 downto 14) <= "0111000";
						END CASE;
						case writedata(15 downto 12) is
							WHEN "0000" => reg_display(27 downto 21) <= "0000001";
							WHEN "0001" => reg_display(27 downto 21) <= "1001111";
							WHEN "0010" => reg_display(27 downto 21) <= "0010010";
							WHEN "0011" => reg_display(27 downto 21) <= "0000110";
							WHEN "0100" => reg_display(27 downto 21) <= "1001100";
							WHEN "0101" => reg_display(27 downto 21) <= "0100100";
							WHEN "0110" => reg_display(27 downto 21) <= "0100000";
							WHEN "0111" => reg_display(27 downto 21) <= "0001111";
							WHEN "1000" => reg_display(27 downto 21) <= "0000000";
							WHEN "1001" => reg_display(27 downto 21) <= "0001100";
							WHEN "1010" => reg_display(27 downto 21) <= "0001000";
							WHEN "1011" => reg_display(27 downto 21) <= "1100000";
							WHEN "1100" => reg_display(27 downto 21) <= "0110001";
							WHEN "1101" => reg_display(27 downto 21) <= "1000010";
							WHEN "1110" => reg_display(27 downto 21) <= "0110000";
							WHEN "1111" => reg_display(27 downto 21) <= "0111000";
						END CASE;
					elsif byteenable(2) = '1' then
						case writedata(19 downto 16) is
							WHEN "0000" => reg_display(34 downto 28) <= "0000001";
							WHEN "0001" => reg_display(34 downto 28) <= "1001111";
							WHEN "0010" => reg_display(34 downto 28) <= "0010010";
							WHEN "0011" => reg_display(34 downto 28) <= "0000110";
							WHEN "0100" => reg_display(34 downto 28) <= "1001100";
							WHEN "0101" => reg_display(34 downto 28) <= "0100100";
							WHEN "0110" => reg_display(34 downto 28) <= "0100000";
							WHEN "0111" => reg_display(34 downto 28) <= "0001111";
							WHEN "1000" => reg_display(34 downto 28) <= "0000000";
							WHEN "1001" => reg_display(34 downto 28) <= "0001100";
							WHEN "1010" => reg_display(34 downto 28) <= "0001000";
							WHEN "1011" => reg_display(34 downto 28) <= "1100000";
							WHEN "1100" => reg_display(34 downto 28) <= "0110001";
							WHEN "1101" => reg_display(34 downto 28) <= "1000010";
							WHEN "1110" => reg_display(34 downto 28) <= "0110000";
							WHEN "1111" => reg_display(34 downto 28) <= "0111000";
						END CASE;
						case writedata(23 downto 20) is
							WHEN "0000" => reg_display(41 downto 35) <= "0000001";
							WHEN "0001" => reg_display(41 downto 35) <= "1001111";
							WHEN "0010" => reg_display(41 downto 35) <= "0010010";
							WHEN "0011" => reg_display(41 downto 35) <= "0000110";
							WHEN "0100" => reg_display(41 downto 35) <= "1001100";
							WHEN "0101" => reg_display(41 downto 35) <= "0100100";
							WHEN "0110" => reg_display(41 downto 35) <= "0100000";
							WHEN "0111" => reg_display(41 downto 35) <= "0001111";
							WHEN "1000" => reg_display(41 downto 35) <= "0000000";
							WHEN "1001" => reg_display(41 downto 35) <= "0001100";
							WHEN "1010" => reg_display(41 downto 35) <= "0001000";
							WHEN "1011" => reg_display(41 downto 35) <= "1100000";
							WHEN "1100" => reg_display(41 downto 35) <= "0110001";
							WHEN "1101" => reg_display(41 downto 35) <= "1000010";
							WHEN "1110" => reg_display(41 downto 35) <= "0110000";
							WHEN "1111" => reg_display(41 downto 35) <= "0111000";
						END CASE;
					elsif byteenable(3) = '1' then
						case writedata(27 downto 24) is
							WHEN "0000" => reg_display(48 downto 42) <= "0000001";
							WHEN "0001" => reg_display(48 downto 42) <= "1001111";
							WHEN "0010" => reg_display(48 downto 42) <= "0010010";
							WHEN "0011" => reg_display(48 downto 42) <= "0000110";
							WHEN "0100" => reg_display(48 downto 42) <= "1001100";
							WHEN "0101" => reg_display(48 downto 42) <= "0100100";
							WHEN "0110" => reg_display(48 downto 42) <= "0100000";
							WHEN "0111" => reg_display(48 downto 42) <= "0001111";
							WHEN "1000" => reg_display(48 downto 42) <= "0000000";
							WHEN "1001" => reg_display(48 downto 42) <= "0001100";
							WHEN "1010" => reg_display(48 downto 42) <= "0001000";
							WHEN "1011" => reg_display(48 downto 42) <= "1100000";
							WHEN "1100" => reg_display(48 downto 42) <= "0110001";
							WHEN "1101" => reg_display(48 downto 42) <= "1000010";
							WHEN "1110" => reg_display(48 downto 42) <= "0110000";
							WHEN "1111" => reg_display(48 downto 42) <= "0111000";
						END CASE;
						case writedata(31 downto 28) is
							WHEN "0000" => reg_display(55 downto 49) <= "0000001";
							WHEN "0001" => reg_display(55 downto 49) <= "1001111";
							WHEN "0010" => reg_display(55 downto 49) <= "0010010";
							WHEN "0011" => reg_display(55 downto 49) <= "0000110";
							WHEN "0100" => reg_display(55 downto 49) <= "1001100";
							WHEN "0101" => reg_display(55 downto 49) <= "0100100";
							WHEN "0110" => reg_display(55 downto 49) <= "0100000";
							WHEN "0111" => reg_display(55 downto 49) <= "0001111";
							WHEN "1000" => reg_display(55 downto 49) <= "0000000";
							WHEN "1001" => reg_display(55 downto 49) <= "0001100";
							WHEN "1010" => reg_display(55 downto 49) <= "0001000";
							WHEN "1011" => reg_display(55 downto 49) <= "1100000";
							WHEN "1100" => reg_display(55 downto 49) <= "0110001";
							WHEN "1101" => reg_display(55 downto 49) <= "1000010";
							WHEN "1110" => reg_display(55 downto 49) <= "0110000";
							WHEN "1111" => reg_display(55 downto 49) <= "0111000";
						END CASE;
					end if;
				end if;
			end if;
		end if;
	END PROCESS;
END Behavior;