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
      clk     			 : in std_logic;     -- Input clock signal
      reset_n           : in std_logic;     --Reset signals
		lcd_enable     		 : in std_logic;
      lcd_bus         : in std_logic_vector (9 downto 0);--RS RW data
      busy            : out std_logic;
      rs, e, rw       : out std_logic;
      lcd_data      : out std_logic_vector (7 downto 0)
    );
  end component LCD_Controller;

  signal lcd_data_in : std_logic_vector (9 downto 0);
  signal lcd_busy : std_logic;
  signal lcd_en : std_logic;
  type TOP_STATES is (init, ready, notpause, pause, pwm60, pwm120, pwm1000);
  signal state : TOP_STATES := init;
  shared variable count : integer := 0;
begin
  LCD : LCD_Controller
  port map(
    clk => I_CLK_50MHZ,
    reset_n => I_SYSTEM_RST,
    lcd_bus => lcd_data_in,
    busy => lcd_busy,
    lcd_enable => lcd_en,
    rs => RS,
    e => E,
    rw => RW,
    lcd_data => lcd_data_out
  );


  test : process (I_CLK_50MHZ, I_SYSTEM_RST)
	begin
		if(rising_edge(I_CLK_50MHZ))then
			lcd_on <= '1';
			lcd_blon <= '1';
			if(I_SYSTEM_RST = '0')then
				state <= init;
				count := 0;
			end if;
			
			case state is 
				when init =>
					if(count = 0 and lcd_busy = '0')then 
						lcd_en <= '1';
						lcd_data_in <= "0000000110";--shift right
						count := count + 1;
					elsif(count < 2 and lcd_busy = '0')then 
						lcd_en <= '1';
						lcd_data_in <= "0000000110";--shift right
						count := count + 1;
					elsif(count < 4 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001001001";--I
						count := count + 1;
					elsif(count < 6 and lcd_busy = '0')then
						lcd_data_in <= "1001101110";--n
						lcd_en <= '1';
						count := count + 1;
					elsif(count < 8 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001101001";--i
						count := count + 1;
					elsif(count < 10 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001110100";--t
						count := count + 1;
					elsif(count < 12 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001101001";--i
						count := count + 1;
					elsif(count < 14 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001100001";--a
						count := count + 1;
					elsif(count < 16 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001101100";--l
						count := count + 1;
					elsif(count < 18 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001101001";--i
						count := count + 1;
					elsif(count < 20 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001111010";--z
						count := count + 1;
					elsif(count < 22 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001101001";--i
						count := count + 1;
					elsif(count < 24 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001101110";--n
						count := count + 1;
					elsif(count < 26 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001100111";--g
						count := count + 1;
					elsif(count >= 26) then
						lcd_en <= '0';
						count := 0;
						state <= ready;
					else
		--				count <= "11111";
						lcd_en <= '0';
					end if;
				when ready =>
					if(count = 0 and lcd_busy = '0') then 
						lcd_en <= '1';
						--lcd_data_in <= "0000000001";--clear
						count := count + 1;
					elsif(count < 2 and lcd_busy = '0')then 
						lcd_en <= '1';
						lcd_data_in <= "0000000010";
						count := count + 1;
					elsif(count < 4 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001010010";--R
						count := count + 1;
					elsif(count < 6 and lcd_busy = '0')then
						lcd_data_in <= "1001100101";--e
						lcd_en <= '1';
						count := count + 1;
					elsif(count < 8 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001100001";--a
						count := count + 1;
					elsif(count < 10 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001100100";--d
						count := count + 1;
					elsif(count < 12 and lcd_busy = '0')then
						lcd_en <= '1';
						lcd_data_in <= "1001111001";--y
						count := count + 1;
					elsif(count >= 14 and lcd_busy = '0')then
						lcd_en <= '0';
						state <= notpause;
					else 
						lcd_en <= '0';
					end if;
				when notpause =>
					state <= notpause;
				when pause =>
					state <= pause;
				when pwm60 =>
					state <= pwm60;
				when pwm120 =>
					state <= pwm120;
				when pwm1000 =>
					state <= pwm1000;
			end case;
		end if;
  end process test;

end architecture;
