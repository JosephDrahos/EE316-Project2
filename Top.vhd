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
	 initbutton : in std_logic; --button to toggle init
	 testpausebutton : in std_logic; --button to toggle between test and pause
	 testpwmbutton : in std_logic; --button to toggle between test and pwm 
	 pwmbutton : in std_logic; --button to toggle between different frequencies
	 
	 
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

  signal old_reset_value : std_logic := '1';
  signal lcd_data_in : std_logic_vector (9 downto 0);
  signal lcd_busy : std_logic;
  signal lcd_en : std_logic;
  type TOP_STATES is (init, ready, test, pause, pwm60, pwm120, pwm1000);
  signal state : TOP_STATES := init;
  signal nextstate : TOP_STATES;
  signal pwmstate : TOP_STATES := pwm60;
  signal statechange : std_logic := '0';
  signal lcd_ready : std_logic := '1';
  shared variable lcd_counter : integer := 0;
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

--todo: wont enter pwm states 
  top_fsm : process (I_CLK_50MHZ, I_SYSTEM_RST)
	begin
		if(rising_edge(I_CLK_50MHZ))then
			if(I_SYSTEM_RST = '0')then
				state <= ready;
				nextstate <= init;
			end if;
			case state is 
				when init =>
					if(lcd_ready = '1' and initbutton = '1')then --waits for displays to finish
						state <= ready;
						nextstate <= test;
						statechange <= '1';
					else 
						state <= init;
					end if;
				when ready =>
					if(statechange = '1')then
						statechange <= '0';
					end if;
					if(lcd_ready = '1')then	--waits for displays to finish
						if(nextstate = init)then
							state <= init;
						elsif(nextstate = test)then
							state <= test;
						elsif(nextstate = pause)then
							state <= pause;
						elsif(nextstate = pwm60)then
							state <= pwm60;
						elsif(nextstate = pwm120)then
							state <= pwm120;
						elsif(nextstate = pwm1000)then
							state <= pwm1000;
						elsif(nextstate = ready)then
							state <= ready;
						end if;
					else
						state <= ready;
					end if;
				when test =>
					if(lcd_ready = '1')then --waits for displays to finish
						if(testpausebutton = '0')then
							nextstate <= pause;
							state <= ready;
							statechange <= '1';
						elsif(testpwmbutton = '0')then
							nextstate <= pwmstate;
							state <= ready;
							statechange <= '1';
						elsif(initbutton = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						else
							nextstate <= test;
						end if;
					else 
						state <= test;
					end if;
				when pause =>
					if(lcd_ready = '1')then --waits for displays to finish
						if(testpausebutton = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(testpwmbutton = '0')then
							nextstate <= pwmstate;
							state <= ready;
							statechange <= '1';
						elsif(initbutton = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						else
							nextstate <= test;
						end if;
					else 
						state <= pause;
					end if;
				when pwm60 =>
					if(lcd_ready = '1')then --waits for displays to finish
						if(testpwmbutton = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(initbutton = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						elsif(pwmbutton = '0')then
							nextstate <= pwm120;
							pwmstate <= pwm120;
							state <= ready;
							statechange <= '1';
						else
							nextstate <= pwm60;
						end if;
					else 
						state <= pwm60;
					end if;
				when pwm120 =>
					if(lcd_ready = '1')then --waits for displays to finish
						if(testpwmbutton = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(initbutton = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						elsif(pwmbutton = '0')then
							nextstate <= pwm1000;
							pwmstate <= pwm1000;
							state <= ready;
							statechange <= '1';
						else
							nextstate <= pwm120;
						end if;
					else 
						state <= pwm120;
					end if;
				when pwm1000 =>
					if(lcd_ready = '1')then --waits for displays to finish
						if(testpwmbutton = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(initbutton = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						elsif(pwmbutton = '0')then
							nextstate <= pwm60;
							pwmstate <= pwm60;
							state <= ready;
							statechange <= '1';
						else
							nextstate <= pwm1000;
						end if;
					else 
						state <= pwm1000;
					end if;
			end case;
		end if;
  end process top_fsm;
  
  lcd_display : process (I_CLK_50MHZ, I_SYSTEM_RST)
	begin
		if(rising_edge(I_CLK_50MHZ))then
			lcd_on <= '1';
			lcd_blon <= '1';
			if(statechange = '1')then
				lcd_counter := 0;
			end if;
			
			case state is
				when init =>
					if(lcd_busy = '0')then
						if(lcd_counter < 4)then
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000010";--shift right
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001001001";--I
						elsif(lcd_counter < 8)then
							lcd_data_in <= "1001101110";--n
							lcd_en <= '1';
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1001101001";--i
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1001110100";--t
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1001101001";--i
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1001100001";--a
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1001101100";--l
						elsif(lcd_counter < 20)then
							lcd_en <= '1';
							lcd_data_in <= "1001101001";--i
						elsif(lcd_counter < 22)then
							lcd_en <= '1';
							lcd_data_in <= "1001111010";--z
						elsif(lcd_counter < 24)then
							lcd_en <= '1';
							lcd_data_in <= "1001101001";--i
						elsif(lcd_counter < 26)then
							lcd_en <= '1';
							lcd_data_in <= "1001101110";--n
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "1001100111";--g
						elsif(lcd_counter >= 28) then
							lcd_ready <= '1';
							lcd_en <= '0';
							lcd_counter := 0;
						end if;
						lcd_counter := lcd_counter + 1;
					else
						lcd_en <= '0';
					end if;
				when ready =>
					--ready clears display due to clear command causing issues
					if(lcd_busy = '0')then
						if(lcd_counter < 2)then
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000001";--position
						elsif(lcd_counter < 4)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 20)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 22)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 24)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 26)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 30)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 32)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 34)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 36)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 38)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 40)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 42)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 44)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 46)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 48)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 50)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 52)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 54)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 56)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 58)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter >= 60)then
							lcd_ready <= '1';
							lcd_en <= '0';
							lcd_counter := 0;
						end if;
						lcd_counter := lcd_counter + 1;
					else
						lcd_en <= '0';
					end if;
				when test =>
					if(lcd_busy = '0')then
						if(lcd_counter < 4)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000110"; --position
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010100";--T
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1001110011";--s
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1001110100";--t
						elsif(lcd_counter >= 14)then
							lcd_ready <= '1';
							lcd_counter := 0;
							lcd_en <= '0';
						end if;
						lcd_counter := lcd_counter + 1;
					else 
						lcd_en <= '0';
					end if;
				when pause =>
					if(lcd_busy = '0')then
						if(lcd_counter < 4)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000110"; --position
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010000";--P
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001100001";--a
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1001110101";--u
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1001110011";--s
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter >= 16)then
							lcd_ready <= '1';
							lcd_counter := 0;
							lcd_en <= '0';
						end if;
						lcd_counter := lcd_counter + 1;
					else 
						lcd_en <= '0';
					end if;
				when pwm60 =>
					if(lcd_busy = '0')then
						if(lcd_counter < 2)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000110"; --position
						elsif(lcd_counter < 4)then
							lcd_en <= '1';
							lcd_data_in <= "1001010000";--P
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010111";--W
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1000110110";--6
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter >= 12)then
							lcd_ready <= '1';
							lcd_counter := 0;
							lcd_en <= '0';
						end if;
						lcd_counter := lcd_counter + 1;
					else 
						lcd_en <= '0';
					end if;
				when pwm120 =>
					if(lcd_busy = '0')then
						if(lcd_counter < 2)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000101"; --position
						elsif(lcd_counter < 4)then
							lcd_en <= '1';
							lcd_data_in <= "1001010000";--P
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010111";--W
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1000110001";--1
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1000110010";--2
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter >= 14)then
							lcd_ready <= '1';
							lcd_counter := 0;
							lcd_en <= '0';
						end if;
						lcd_counter := lcd_counter + 1;
					else 
						lcd_en <= '0';
					end if;
				when pwm1000 =>
					if(lcd_busy = '0')then
						if(lcd_counter < 2)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000100"; --position
						elsif(lcd_counter < 4)then
							lcd_en <= '1';
							lcd_data_in <= "1001010000";--P
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010111";--W
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1000110001";--1
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter >= 18)then
							lcd_ready <= '1';
							lcd_counter := 0;
							lcd_en <= '0';
						end if;
						lcd_counter := lcd_counter + 1;
					else 
						lcd_en <= '0';
					end if;
				end case;
			
			old_reset_value <= I_SYSTEM_RST;
		end if;
  end process lcd_display;

end architecture;
