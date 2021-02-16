-- TODO : Test process input


library IEEE;
use IEEE.std_logic_1164.all;

entity tb_LCD_Controller is
end tb_LCD_Controller;

architecture tb of tb_LCD_Vontroller is 
	component LCD_Controller 
    
    generic(
    clk_freq  : integer := 50  
  );
  port
  (
    I_CLK_50MHZ     : in std_logic;     
    Reset           : in std_logic;     
    data_in         : in std_logic_vector (9 downto 0);
    lcd_en          : in std_logic;
    BUSY            : out std_logic;
    RS, E, RW       : out std_logic;
    data_out        : out std_logic_vector (7 downto 0)
  );
end component;

signal I_CLK_50MHZ     : in std_logic;     
signal    Reset           : in std_logic;     
signal    data_in         : in std_logic_vector (9 downto 0);
signal    lcd_en          : in std_logic;
signal    BUSY            : out std_logic;
signal    RS, E, RW       : out std_logic;
signal    data_out        : out std_logic_vector (7 downto 0)

begin
	
    dut : LCD_Controller
    
    port map(
    		I_CLK_50MHZ  => I_CLK_50MHZ ;     
    		Reset        => Reset;     
    		data_in      => data_in;
    		lcd_en       => lcd_en;
    		BUSY         => BUSY;
    		RS           => RS;
                E            => E;
                RW           => RW;
    		data_out     => data_out; 
			
			
		clock_process: process
		begin 
			I_CLK_50MHZ <= '0';
			wait for clock_period/2;
			I_CLK_50MHZ <= '1';
			wait for clock_period/2;
		end process;
    test : process
			begin 
            
            
        
