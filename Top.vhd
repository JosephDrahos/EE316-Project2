-----------------
--  Libraries  --
-----------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity Top is
  port(
    I_SYSTEM_RST : in std_logic;
    I_CLK_50MHZ : in std_logic;

    --LCD Outputs
    RS              : out std_logic;
    E               : out std_logic;
    RW              : out std_logic;
	 lcd_on			  : out std_logic;
	 lcd_blon		  : out std_logic;
	 lcd_data_out    : out std_logic_vector (7 downto 0)
  );
end Top;

architecture archTop  of  Top is
  component LCD_Controller is
    port
    (
      I_CLK_50MHZ     : in std_logic;     -- Input clock signal
      Reset           : in std_logic;     --Reset signals
      data_in         : in std_logic_vector (9 downto 0);--RS RW data
      lcd_en     		 : in std_logic;
      BUSY            : out std_logic;
      RS, E, RW       : out std_logic;
      data_out      : out std_logic_vector (7 downto 0)
    );
  end component LCD_Controller;

  signal lcd_data_in : std_logic_vector (9 downto 0);
  signal lcd_busy : std_logic;
  signal lcd_en : std_logic;
  shared variable count : integer := 0;
begin
  LCD : LCD_Controller
  port map(
    I_CLK_50MHZ => I_CLK_50MHZ,
    Reset => I_SYSTEM_RST,
    data_in => lcd_data_in,
    BUSY => lcd_busy,
    lcd_en => lcd_en,
    RS => RS,
    E => E,
    RW => RW,
    data_out => lcd_data_out
  );


  test : process (I_CLK_50MHZ, I_SYSTEM_RST)
	begin
		if(rising_edge(I_CLK_50MHZ))then
			lcd_on <= '1';
			lcd_blon <= '1';
			if(count < (5) and lcd_busy = '0')then
				lcd_en <= '1';
				lcd_data_in <= "1001001001";--I
				count := count + 1;
			else
				lcd_en <= '0';
--			elsif(count = "00001" and lcd_busy = '0')then
--				--lcd_data_in <= "1001101110";--n
--				lcd_en <= '0';
--				count <= count + 1;
--			elsif(count = "00010" and lcd_busy = '0')then
--				--lcd_data_in <= "1001101001";--i
--				count <= count + 1;
--			elsif(count = "00011" and lcd_busy = '0')then
--				--lcd_data_in <= "1001110100";--t
--				count <= count + 1;
--			elsif(count = "00100" and lcd_busy = '0')then
--				--lcd_data_in <= "1001101001";--i
--				count <= count + 1;
--			elsif(count = "00101" and lcd_busy = '0')then
--				--lcd_data_in <= "1001100001";--a
--				count <= count + 1;
--			elsif(count = "00110" and lcd_busy = '0')then
--				--lcd_data_in <= "1001101100";--l
--				count <= count + 1;
--			elsif(count = "00111" and lcd_busy = '0')then
--				--lcd_data_in <= "1001101001";--i
--				count <= count + 1;
--			elsif(count = "01000" and lcd_busy = '0')then
--				--lcd_data_in <= "1001111010";--z
--				count <= count + 1;
--			elsif(count = "01001" and lcd_busy = '0')then
--				--lcd_data_in <= "1001101001";--i
--				count <= count + 1;
--			elsif(count = "01010" and lcd_busy = '0')then
--				--lcd_data_in <= "1001101110";--n
--				count <= count + 1;
--			elsif(count = "01011" and lcd_busy = '0')then
--				--lcd_data_in <= "1001100111";--g
--				count <= count + 1;
--			else
--				count <= "11111";
--				lcd_en <= '0';
			end if;
		end if;
  end process test;

end architecture;
