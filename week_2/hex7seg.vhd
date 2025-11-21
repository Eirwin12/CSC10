LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY hex7seg IS
	PORT ( hex : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
	display : OUT STD_LOGIC_VECTOR(0 TO 6) );
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


	PROCESS (hex)
	BEGIN
		display <= hex_to_7_seg(hex);
	END PROCESS;
END Behavior;