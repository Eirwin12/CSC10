-- altera vhdl_input_version vhdl_2008
library IEEE;
use IEEE.std_logic_1164.all;

entity reg32_avalon_interface is
	port (
		clock, resetn : in std_logic;
		read, write, chipselect : in std_logic;
		readdata : out std_logic_vector(31 downto 0);
		writedata : in std_logic_vector(31 downto 0);
		byteenable : in std_logic_vector(3 downto 0);
		Q_export : out std_logic_vector(31 downto 0)
	);
end reg32_avalon_interface;

architecture rtl of reg32_avalon_interface is
	type registers is array (0 to 0) of std_logic_vector(31 downto 0);
	signal regs: registers;
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
begin
	process(clock, resetn)
	begin
		if not resetn then
			for i in 0 to 0 loop
				regs(i) <= (others => '0');
			end loop;
		elsif rising_edge(clock) then
			if chipselect then
				if read then
					readdata <= regs(0);
				elsif write then
					if byteenable(0) then
						regs(0)(6 downto 0) <= hex_to_7_seg(writedata(3 downto 0));
						regs(0)(13 downto 7) <= hex_to_7_seg(writedata(7 downto 4));
					end if;
					if byteenable(1) then
						regs(0)(20 downto 14) <= hex_to_7_seg(writedata(11 downto 8));
						regs(0)(27 downto 21) <= hex_to_7_seg(writedata(15 downto 12));
					end if;
--					if byteenable(2) then
--						regs(0)(23 downto 16) <= writedata(23 downto 16);
--					end if;
--					if byteenable(3) then
--						regs(0)(31 downto 24) <= writedata(31 downto 24);
--					end if;
				end if;
			end if;
		end if;
	end process;
	Q_export <= regs(0);
end architecture rtl;