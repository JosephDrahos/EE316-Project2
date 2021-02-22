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
	 buttons : in std_logic_vector(3 downto 0);--button 0 to toggle init
															 --button 1 to toggle between test and pause
															 --button 2 to toggle between test and pwm 
															 --button 3 to toggle between different frequencies
	 
	 -- SRAM outputs
    SRAM_DATA_ADDR : out std_logic_vector(17 downto 0);
    DIO   : inout std_logic_vector(15 downto 0);
    CE    : out std_logic;
    WE    : out std_logic;       -- signal for writing to SRAM
    OE    : out std_logic;     -- Input signal for enabling output
    UB    : out std_logic;
    LB    : out std_logic;
		  
    --LCD Outputs
    RS              : out std_logic;
    E               : out std_logic;
    RW              : out std_logic;
	 lcd_on			  : out std_logic;
	 lcd_blon		  : out std_logic;
	 lcd_data_out    : out std_logic_vector (7 downto 0);
	 
	 --I2C Controller Outputs
	 SCL				: inout std_logic;
	 SDA	  			: inout std_logic
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
      reset_n         : in std_logic;     --Reset signals
		lcd_enable      : in std_logic;
      lcd_bus         : in std_logic_vector (9 downto 0);--RS RW data
      busy            : out std_logic;
      rs, e, rw       : out std_logic;
      lcd_data      : out std_logic_vector (7 downto 0)
    );
  end component LCD_Controller;
  
  component i2c_user_logic is
   Generic(slave_addr : std_logic_vector(6 downto 0) := "1110001");
	port(
		clock				: in std_logic;
		dataIn			: in std_logic_vector(15 downto 0);
		outSCL			: inout STD_logic;
		outSDA 			: inout std_logic
	);
	end component i2c_user_logic;

  component debounce is
	 port(
		I_CLK 			  : in std_logic;
		I_RESET_N        : in std_logic;  -- System reset (active low)
		I_BUTTON         : in std_logic;  -- Button data to be debounced
		O_BUTTON         : out std_logic  -- Debounced button data
	 );
  end component debounce;
  
  component binary_to_hexascii is
	port(
		clk 	: in std_logic;
		input : in std_logic_vector(7 downto 0);
		output : out std_logic_vector(15 downto 0)
	);
  end component binary_to_hexascii;
  
  --debounced buttons signal
  signal buttons_debounce : std_logic_vector(3 downto 0);
  
  --fsm signals
  type TOP_STATES is (init, ready, test, pause, pwm60, pwm120, pwm1000);
  signal state : TOP_STATES := init;
  signal nextstate : TOP_STATES;
  signal pwmstate : TOP_STATES := pwm60;
  signal allowchange : std_logic := '1';
  signal statechange : std_logic := '0';
  signal lcd_ready : std_logic := '1';
  signal entered_init : std_logic := '1';
  signal left_init : std_logic := '0';
  
  --lcd signals
  signal lcd_data_in : std_logic_vector (9 downto 0);
  signal lcd_busy : std_logic;
  signal lcd_en : std_logic;
  signal hex_address_in_binary : std_logic_vector(15 downto 0);
  signal hex_data_in_binary : std_logic_vector(31 downto 0);
  
  --i2c user logic signals
  signal clock, outSDA, outSCL	: std_logic;
  signal slave_addr					: std_logic_vector(6 downto 0);
  signal dataIn 						: std_logic_vector(15 downto 0);
  signal cont 							: std_logic_vector(31 downto 0);
  
  -- sram Signals
  signal sram_data_address 	 : unsigned(17 downto 0);
  signal sram_data         	 : std_logic_vector(15 downto 0);
  signal out_data_signal       : std_logic_vector(15 downto 0);
  signal count_enable          : std_logic;
  signal sram_RW               : std_logic;
  signal sram_ready 				 : std_logic;

  
  -- ROM initialization signal
  signal rom_initialize     : std_logic := '0';
  signal rom_data           : std_logic_vector(15 downto 0);
  signal init_data_addr     : unsigned(17 downto 0) := (others => '1');
  signal rom_write          : unsigned(17 downto 0) := (others => '0');
  
  --counter signals
  shared variable lcd_counter : integer := 0;
  signal one_hz_counter_signal : unsigned(25 downto 0) := (others => '0');
  signal counter_paused : std_logic := '1';
  
 begin
  --debounces the input buttons
  button_debounce: for i in 0 to 3 generate
	debounce_button: debounce
		port map
		(
			I_CLK 	=> I_CLK_50MHZ,
			I_RESET_N => not I_SYSTEM_RST,
			I_BUTTON  => buttons(i),
			O_BUTTON  => buttons_debounce(i)
		);
	end generate button_debounce;
 
  hex1 : binary_to_hexascii port map(I_CLK_50MHZ, std_logic_vector(sram_data_address(7 downto 0)), hex_address_in_binary);
  hex2 : binary_to_hexascii port map(I_CLK_50MHZ, out_data_signal(15 downto 8), hex_data_in_binary(31 downto 16));
  hex3 : binary_to_hexascii port map(I_CLK_50MHZ, out_data_signal(7 downto 0), hex_data_in_binary(15 downto 0));
  
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
		  CE             => CE,
		  WE             => WE,
		  OE             => OE,
		  UB             => UB,
		  LB             => LB,
		  IN_DATA        => sram_data,
		  IN_DATA_ADDR   => std_logic_vector(sram_data_address),
		  OUT_DATA       => out_data_signal,
		  OUT_DATA_ADR   => SRAM_DATA_ADDR
	 );
	
	--i2c controller port map
	inst1: i2c_user_logic
	port map(
		clock 	=> clock,
		dataIn	=> dataIn,
		outSDA 	=> outSDA,
		outSCL 	=> outSCL
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
			if (state = init ) then
             if (rom_write = "110000110101000000") then  --101
                 count_enable <= '1';
             else
                 count_enable <= '0';
             end if;
         elsif(state = test)then
				one_hz_counter_signal <= one_hz_counter_signal + 1;
				--1 hz frequency
				if (one_hz_counter_signal = "10111110101111000001111111") then
					count_enable <= '1';
					one_hz_counter_signal <= (others => '0');
				else
					count_enable <= '0';
				end if;
			end if;
		end if;
	end process ONE_HZ_CLOCK;
  
  SRAM_process : process(I_CLK_50MHZ, I_SYSTEM_RST)
	begin
		if(I_SYSTEM_RST = '0')then
			sram_data <= (others => '0');
			rom_initialize <= '0';
			init_data_addr <= (others => '1');
			sram_ready <= '0';
		elsif(rising_edge(I_CLK_50MHZ))then
			case state is 
				when init =>
					sram_RW <= '0';
					
					if(entered_init = '1')then
						sram_ready <= '0';
						init_data_addr <= (others => '1');
					end if;
					
					if (init_data_addr /= "000000000100000000") then
						 sram_data_address <= init_data_addr;
						 sram_data         <= rom_data;
					end if;
					
					if(sram_ready <= '0')then
						rom_write <= rom_write + 1;
						if (rom_write = "110000110101000000") then
							 rom_write <= (others => '0');
							 init_data_addr <= init_data_addr + 1;

							 if (init_data_addr = "000000000011111111") then
								  sram_data <= (others => '0');
								  sram_data_address <= (others => '0');
								  rom_initialize <= '1';
								  sram_ready <= '1';
							 end if;
						 end if;
					 end if;
				 when ready =>
				 
				 when test =>
					sram_RW <= '1';
					if(left_init = '1')then
						sram_data_address <= (others => '0');
					end if;
					if(count_enable = '1')then
						if (sram_data_address(7 downto 0) = "11111111" and counter_paused = '0') then
							  sram_data_address <= (others  => '0');
						elsif (counter_paused = '0') then
							  sram_data_address <= sram_data_address + 1;
						end if;
					end if;
				 when pause =>
				 
				 when pwm60 =>
				 
				 when pwm120 =>
				 
				 when pwm1000 =>
				 
			end case;
		end if;	
  end process SRAM_process;
  
  i2c_user_logic_process : process(I_CLK_50MHZ, I_SYSTEM_RST)
	begin
		if(rising_edge(I_CLK_50MHZ))then
			if (cont < "11111111111111111111111100000000") then
				dataIn<="0000001101010101";
			else 
				dataIn<="0000000111110000";
			end if;
			if (cont = "11111111111111111111111111111111") then
				cont <= "00000000000000000000000000000000";
			end if;
			case state is
				when init =>
				
				when test =>
					dataIn <= out_data_signal;
				
				when pause=>
				
				when pwm60 =>
				 
				when pwm120 =>
				 
				when pwm1000 =>
				 
			end case;
			end if;
	end process i2c_user_logic_process;
  
  
  top_fsm : process (I_CLK_50MHZ, I_SYSTEM_RST)
	begin
		if(rising_edge(I_CLK_50MHZ))then
			if(I_SYSTEM_RST = '0')then
				state <= ready;
				nextstate <= init;
			end if;
			case state is 
				when init =>
					entered_init <= '0';
					if(lcd_ready = '1' and buttons_debounce(0) = '1' and sram_ready = '1')then --waits for displays to finish
						state <= ready;
						nextstate <= test;
						statechange <= '1';
						left_init <= '1';
					else 
						state <= init;
					end if;
				when ready =>
					if(statechange = '1')then
						statechange <= '0';
					end if;
					if(left_init = '1')then
						left_init <= '0';
					end if;
					if(lcd_ready = '1')then	--waits for displays to finish
						if(nextstate = init)then
							entered_init <= '1';
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
					counter_paused <= '0';
					if(lcd_ready = '1')then --waits for displays to finish
						if(buttons_debounce(1) = '0')then
							nextstate <= pause;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(2) = '0')then
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
						elsif(buttons_debounce(0) = '0')then
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
					counter_paused <= '1';
					if(lcd_ready = '1')then --waits for displays to finish
						if(buttons_debounce(1) = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(2) = '0')then
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
						elsif(buttons_debounce(0) = '0')then
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
						if(buttons_debounce(2) = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(0) = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(3) = '0')then
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
						if(buttons_debounce(2) = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(0) = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(3) = '0')then
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
						if(buttons_debounce(2) = '0')then
							nextstate <= test;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(0) = '0')then
							nextstate <= init;
							state <= ready;
							statechange <= '1';
						elsif(buttons_debounce(3) = '0')then
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
						elsif(lcd_counter < 23)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 26)then
							lcd_en <= '1';
							lcd_data_in <= "0011000100";--second line
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_address_in_binary(15 downto 8); --1st hexaddress location
						elsif(lcd_counter < 30)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_address_in_binary(7 downto 0); --2st hexaddress location
						elsif(lcd_counter < 32)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 34)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(31 downto 24); --1st hex data
						elsif(lcd_counter < 36)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(23 downto 16); --2st hex data
						elsif(lcd_counter < 38)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(15 downto 8); --3rd hex data
						elsif(lcd_counter < 40)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(7 downto 0); --4th hex data
						elsif(lcd_counter >= 40)then
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
						elsif(lcd_counter < 25)then
							lcd_en <= '1';
							lcd_data_in <= "1001100101";--e
						elsif(lcd_counter < 28)then
							lcd_en <= '1';
							lcd_data_in <= "0011000100";--second line
						elsif(lcd_counter < 30)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_address_in_binary(15 downto 8); --1st hexaddress location
						elsif(lcd_counter < 32)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_address_in_binary(7 downto 0); --2st hexaddress location
						elsif(lcd_counter < 34)then
							lcd_en <= '1';
							lcd_data_in <= "1000100000";--space
						elsif(lcd_counter < 36)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(31 downto 24); --1st hex data
						elsif(lcd_counter < 38)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(23 downto 16); --2st hex data
						elsif(lcd_counter < 40)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(15 downto 8); --3rd hex data
						elsif(lcd_counter < 42)then
							lcd_en <= '1';
							lcd_data_in <= "10" & hex_data_in_binary(7 downto 0); --4th hex data
						elsif(lcd_counter >= 42)then
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

