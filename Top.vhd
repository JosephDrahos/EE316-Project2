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
	 
	 
	 -- SRAM outputs
    SRAM_DATA_ADDR : out std_logic_vector(17 downto 0);
    DIO   : inout std_logic_vector(15 downto 0);
    CE  : out std_logic;
    WE  : out std_logic;     -- signal for writing to SRAM
    OE    : out std_logic;     -- Input signal for enabling output
    UB    : out std_logic;
    LB    : out std_logic;
		  
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
  ----------------
  -- COMPONENTS --
  ----------------

  -- SRAM controlller
  component SRAM_controller is
  port
  (
    I_CLK_50MHZ     : in std_logic;
    I_SYSTEM_RST_N  : in std_logic;
    COUNT_EN : in std_logic;
    RW         : in std_logic;
    DIO : inout std_logic_vector(15 downto 0);
    CE : out std_logic;
    WE    : out std_logic;
    OE    : out std_logic;
    UB    : out std_logic;
    LB    : out std_logic;
    IN_DATA      : in std_logic_vector(15 downto 0);
    IN_DATA_ADDR : in std_logic_vector(17 downto 0);
    OUT_DATA    : out std_logic_vector(15 downto 0);
    OUT_DATA_ADR : out std_logic_vector(17 downto 0)
  );
  end component SRAM_controller;
  
  -- ROM driver (auto generated signature)
  component ROM is
  	port
  	(
  		address		: in std_logic_vector (7 downto 0);
  		clock		  : in std_logic  := '1';
  		q		      : out std_logic_vector (15 downto 0)
  	);
  end component ROM;
  
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

  --fsm signals
  type TOP_STATES is (init, ready, test, pause, pwm60, pwm120, pwm1000);
  signal state : TOP_STATES := init;
  signal nextstate : TOP_STATES;
  signal pwmstate : TOP_STATES := pwm60;
  signal statechange : std_logic := '0';
  signal lcd_ready : std_logic := '1';
  
  --lcd signals
  signal lcd_data_in : std_logic_vector (9 downto 0);
  signal lcd_busy : std_logic;
  signal lcd_en : std_logic;
  
  -- sram Signals
  signal sram_data_address 	 : unsigned(17 downto 0);
  signal sram_data         	 : std_logic_vector(15 downto 0);
  signal out_data_signal       : std_logic_vector(15 downto 0);
  signal count_enable          : std_logic;
  signal sram_RW               : std_logic;
  
  -- ROM initialization signal
  signal rom_initialize     : std_logic := '0';
  signal rom_data           : std_logic_vector(15 downto 0);
  signal init_data_addr     : unsigned(17 downto 0) := (others => '1');
  
  --counter signals
  shared variable lcd_counter : integer := 0;
  signal one_hz_counter_signal : unsigned(25 downto 0) := (others => '0');
  
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

  
	 -- SRAM  controller port map
	 SRAM : SRAM_controller
	 port map(
		  I_CLK_50MHZ    => I_CLK_50MHZ,
		  I_SYSTEM_RST_N => I_SYSTEM_RST,
		  COUNT_EN       => count_enable,
		  RW             => sram_RW,
		  DIO            => DIO,
		  CE           => CE,
		  WE           => WE,
		  OE             => OE,
		  UB             => UB,
		  LB             => LB,
		  IN_DATA        => sram_data,
		  IN_DATA_ADDR   => std_logic_vector(sram_data_address),
		  OUT_DATA       => out_data_signal,
		  OUT_DATA_ADR   => SRAM_DATA_ADDR
	 );

	 -- ROM driver port map
    ROM_UNIT : ROM
    port map(
        address	=> std_logic_vector(init_data_addr(7 downto 0)),
        clock	  => I_CLK_50MHZ,
        q	      => rom_data
    );

  ONE_HZ_CLOCK : process (I_CLK_50MHZ, I_SYSTEM_RST)
     begin
       if(I_SYSTEM_RST = '0') then
		   one_hz_counter_signal <= (others => '0');
       elsif (rising_edge(I_CLK_50MHZ)) then
			one_hz_counter_signal <= one_hz_counter_signal + 1;
			--1 hz frequency
			if (one_hz_counter_signal = "10111110101111000001111111") then
				 one_hz_counter_signal <= (others => '0');
			else
			end if;
		end if;
	end process ONE_HZ_CLOCK;
  
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
							if(pwmstate = pwm60)then 
								nextstate <= pwm60;
							elsif(pwmstate = pwm120)then
								nextstate <= pwm120;
							elsif(pwmstate <= pwm1000)then
								nextstate <= pwm1000;
							else	
								nextstate <= pwm60;
							end if;
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
							if(pwmstate = pwm60)then 
								nextstate <= pwm60;
							elsif(pwmstate = pwm120)then
								nextstate <= pwm120;
							elsif(pwmstate <= pwm1000)then
								nextstate <= pwm1000;
							else	
								nextstate <= pwm60;
							end if;
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
				when others =>
					state <= init;
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
					if(statechange = '1')then
						lcd_counter := 0;
					end if;
					if(lcd_busy = '0')then
						if(lcd_counter < 4)then
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000000";--position
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
							lcd_data_in <= "1000100000";--space16
						elsif(lcd_counter < 40)then
							lcd_en <= '1';
							lcd_data_in <= "0011000000";--second line
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
						elsif(lcd_counter < 60)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 62)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 64)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 66)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 68)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 70)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 72)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter >= 72)then
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
							lcd_data_in <= "0010000011"; --position
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
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1001101111";--o
						elsif(lcd_counter < 20)then
							lcd_en <= '1';
							lcd_data_in <= "1001100100";--d
						elsif(lcd_counter < 22)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 26)then
							lcd_en <= '1';
							lcd_data_in <= "0011000100";--second line
						elsif(lcd_counter >= 26)then
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
							lcd_data_in <= "0010000011"; --position
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
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 20)then
							lcd_en <= '1';
							lcd_data_in <= "1001101111";--o
						elsif(lcd_counter < 22)then
							lcd_en <= '1';
							lcd_data_in <= "1001100100";--d
						elsif(lcd_counter < 24)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "0011000100";--second line
						elsif(lcd_counter >= 28)then
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
						if(lcd_counter < 4)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000001"; --position
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010000";--P
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001010111";--W
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1001000111";--G
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1001101110";--n
						elsif(lcd_counter < 20)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 22)then
							lcd_en <= '1';
							lcd_data_in <= "1001110010";--r
						elsif(lcd_counter < 24)then
							lcd_en <= '1';
							lcd_data_in <= "1001100001";--a
						elsif(lcd_counter < 26)then
							lcd_en <= '1';
							lcd_data_in <= "1001110100";--t
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "1001101001";--i
						elsif(lcd_counter < 30)then
							lcd_en <= '1';
							lcd_data_in <= "1001101111";--o
						elsif(lcd_counter < 33)then
							lcd_en <= '1';
							lcd_data_in <= "1001101110";--n
						elsif(lcd_counter < 36)then
							lcd_en <= '1';
							lcd_data_in <= "0011000110";--2ndline
						elsif(lcd_counter < 38)then
							lcd_en <= '1';
							lcd_data_in <= "1000110110";--6
						elsif(lcd_counter < 40)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 42)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 44)then
							lcd_en <= '1';
							lcd_data_in <= "1001001000";--H
						elsif(lcd_counter < 46)then
							lcd_en <= '1';
							lcd_data_in <= "1001011010";--Z
						elsif(lcd_counter >= 46)then
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
						if(lcd_counter < 4)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000001"; --position
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010000";--P
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001010111";--W
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1001000111";--G
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1001101110";--n
						elsif(lcd_counter < 20)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 22)then
							lcd_en <= '1';
							lcd_data_in <= "1001110010";--r
						elsif(lcd_counter < 24)then
							lcd_en <= '1';
							lcd_data_in <= "1001100001";--a
						elsif(lcd_counter < 26)then
							lcd_en <= '1';
							lcd_data_in <= "1001110100";--t
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "1001101001";--i
						elsif(lcd_counter < 30)then
							lcd_en <= '1';
							lcd_data_in <= "1001101111";--o
						elsif(lcd_counter < 33)then
							lcd_en <= '1';
							lcd_data_in <= "1001101110";--n
						elsif(lcd_counter < 36)then
							lcd_en <= '1';
							lcd_data_in <= "0011000101";--2ndline
						elsif(lcd_counter < 38)then
							lcd_en <= '1';
							lcd_data_in <= "1000110001";--1
						elsif(lcd_counter < 40)then
							lcd_en <= '1';
							lcd_data_in <= "1000110010";--2
						elsif(lcd_counter < 42)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 44)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 46)then
							lcd_en <= '1';
							lcd_data_in <= "1001001000";--H
						elsif(lcd_counter < 48)then
							lcd_en <= '1';
							lcd_data_in <= "1001011010";--Z
						elsif(lcd_counter >= 48)then
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
						if(lcd_counter < 4)then 
							lcd_ready <= '0';
							lcd_en <= '1';
							lcd_data_in <= "0010000001"; --position
						elsif(lcd_counter < 6)then
							lcd_en <= '1';
							lcd_data_in <= "1001010000";--P
						elsif(lcd_counter < 8)then
							lcd_en <= '1';
							lcd_data_in <= "1001010111";--W
						elsif(lcd_counter < 10)then
							lcd_en <= '1';
							lcd_data_in <= "1001001101";--M
						elsif(lcd_counter < 12)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 14)then
							lcd_en <= '1';
							lcd_data_in <= "1001000111";--G
						elsif(lcd_counter < 16)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 18)then
							lcd_en <= '1';
							lcd_data_in <= "1001101110";--n
						elsif(lcd_counter < 20)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 22)then
							lcd_en <= '1';
							lcd_data_in <= "1001110010";--r
						elsif(lcd_counter < 24)then
							lcd_en <= '1';
							lcd_data_in <= "1001100001";--a
						elsif(lcd_counter < 26)then
							lcd_en <= '1';
							lcd_data_in <= "1001110100";--t
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "1001101001";--i
						elsif(lcd_counter < 30)then
							lcd_en <= '1';
							lcd_data_in <= "1001101111";--o
						elsif(lcd_counter < 33)then
							lcd_en <= '1';
							lcd_data_in <= "1001101110";--n
						elsif(lcd_counter < 36)then
							lcd_en <= '1';
							lcd_data_in <= "0011000101";--2ndline
						elsif(lcd_counter < 38)then
							lcd_en <= '1';
							lcd_data_in <= "1000110001";--1
						elsif(lcd_counter < 40)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 42)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 44)then
							lcd_en <= '1';
							lcd_data_in <= "1000110000";--0
						elsif(lcd_counter < 46)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 48)then
							lcd_en <= '1';
							lcd_data_in <= "1001001000";--H
						elsif(lcd_counter < 50)then
							lcd_en <= '1';
							lcd_data_in <= "1001011010";--Z
						elsif(lcd_counter >= 50)then
							lcd_ready <= '1';
							lcd_counter := 0;
							lcd_en <= '0';
						end if;
						lcd_counter := lcd_counter + 1;
					else 
						lcd_en <= '0';
					end if;
				end case;
			
		end if;
  end process lcd_display;

end architecture;
