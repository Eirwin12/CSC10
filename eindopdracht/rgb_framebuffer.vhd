library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rgb_framebuffer is
	port (
		clock           : in  std_logic;
		reset           : in  std_logic;
	  
	  red_vector_write	: in std_logic_vector(31 downto 0);
	  blue_vector_write	: in std_logic_vector(31 downto 0);
	  green_vector_write	: in std_logic_vector(31 downto 0);
	  address			: in std_logic_vector(4 downto 0);
	  write           : in std_logic;
	  write_done      : out std_logic;
	  collumn_filled  : out std_ulogic;
	  change_row      : in std_ulogic;
	  enable_matrix   : in std_ulogic;
	  -- RGB Matrix Output Conduit
	  matrix_r1     : out std_logic;
	  matrix_g1     : out std_logic;
	  matrix_b1     : out std_logic;
	  matrix_r2     : out std_logic;
	  matrix_g2     : out std_logic;
	  matrix_b2     : out std_logic;
	  matrix_addr_a : out std_logic;
	  matrix_addr_b : out std_logic;
	  matrix_addr_c : out std_logic;
	  matrix_addr_d : out std_logic
	);
end entity rgb_framebuffer;

architecture rtl of rgb_framebuffer is

	--matrix heeft 32x32 leds. elke led heeft 3 bits nodig: 1 bit rood, 1 bit groen en 1 bit blauw. 
	--elke led is een logic_vector, waarbij rood bit 0, groen bit 2 en blauw bit 2 is. 
	--i.p.v. vector van vectoren maken (type row, type grid) zoals AI eerst heeft gedaan om alle leds te onthouden
	--is een 2D matrix overzichtelijker.
	--zie 8.3.4 van circuit design with vhdl hoe dit er ong. eruit ziet. 

	subtype color_vector is std_ulogic_vector(31 downto 0);--3 bit rgb-->1bit red, 1 bit green, 1 bit blue
	type rgb is array(2 downto 0) of color_vector;
	type matrix_grid2 is array(31 downto 0) of rgb;
--	sybtype rgb is std_ulogic_vector(2 downto 0);
--	type matrix_grid is array(31 downto 0, 31 downto 0) of rgb;
	signal framebuffer: matrix_grid2 := (others => (others => (others => '0')));

	-- Scanning signals
	signal row_addr : unsigned(3 downto 0) := (others => '0');  -- 0-15 voor 16 rij-paren
	signal col_count : unsigned(4 downto 0) := (others => '0'); -- 0-31 voor 32 kolommen
 
begin
    
	--alvast invullen zodat het voor mij duidelijk is. 
	process(reset, clock, enable_matrix, change_row)
		variable upper_row : integer range 0 to 31;
		variable lower_row : integer range 0 to 31;

		variable row_index: integer range 0 to 15;
		variable collumn_index: integer range 0 to 31;

		constant LOWER_ROW_OFFSET: natural := 16;
		
		type pixel_adress is array(0 to 1) of integer range 0 to 31;
		variable pixel_addr1 : pixel_adress;
		variable pixel_addr2 : pixel_adress;
	begin
		if reset then 
			row_addr <= (others => '0');
			col_count <= (others => '0');
			matrix_r1 <= '0';
			matrix_g1 <= '0';
			matrix_b1 <= '0';

			matrix_r2 <= '0';
			matrix_g2 <= '0';
			matrix_b2 <= '0';
			collumn_filled <= '0';
		elsif rising_edge(clock) then
			if change_row then
				row_addr <= row_addr+1;
				collumn_filled <= '0';
			elsif enable_matrix then
				-- Calculate addresses voor current column en row
				upper_row := to_integer(row_addr);              -- 0-7
				lower_row := to_integer(row_addr) + LOWER_ROW_OFFSET;         -- 16-23

				--vind de adressen van de pixel
				pixel_addr1 := (upper_row, to_integer(col_count));
				pixel_addr2 := (lower_row, to_integer(col_count));

				--verstuur de pixels naar de matrix toe. 
				matrix_r1 <= framebuffer(pixel_addr1(0))(0)(pixel_addr1(1));
				matrix_g1 <= framebuffer(pixel_addr1(0))(1)(pixel_addr1(1));
				matrix_b1 <= framebuffer(pixel_addr1(0))(2)(pixel_addr1(1));

				matrix_r2 <= framebuffer(pixel_addr2(0))(0)(pixel_addr2(1));
				matrix_g2 <= framebuffer(pixel_addr2(0))(1)(pixel_addr2(1));
				matrix_b2 <= framebuffer(pixel_addr2(0))(2)(pixel_addr2(1));

				-- Next column
				if col_count >= 31 then
					--last written value is valid for signals in process
					--only set collumn_filled high when this condition is met
					collumn_filled <= '1';
				end if;
				col_count <= col_count + 1;
			end if;
		end if;
	end process;
	
   process(reset, clock, write, address)
		variable row: integer range 0 to 31;
		variable col: integer range 0 to 31;
	begin
	
		row := to_integer(unsigned(address));
		--read verstuurd data naar master
		if reset then
			framebuffer <= (others => (others => (others => '0')));
			write_done <= '0';
--		elsif rising_edge(clock) then
--		elsif write = '1' then
		else
			framebuffer(row)(0) <= std_ulogic_vector(red_vector_write);
			framebuffer(row)(1) <= std_ulogic_vector(green_vector_write);
			framebuffer(row)(2) <= std_ulogic_vector(blue_vector_write);
--		else
--			for collumn in 0 to 31 loop
--				framebuffer(row)(collumn) <= (red_vector_write(collumn), green_vector_write(collumn), blue_vector_write(collumn));
--			end loop;
			write_done <= '1';
--		else
--			write_done <= '0';
		end if;
	end process;
    -- Output assignments
    matrix_addr_a <= std_logic(row_addr(0));
    matrix_addr_b <= std_logic(row_addr(1));
    matrix_addr_c <= std_logic(row_addr(2));
    matrix_addr_d <= std_logic(row_addr(3));
    
end architecture rtl;