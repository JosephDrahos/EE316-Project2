-- TODO : Test process input


library IEEE;
use IEEE.std_logic_1164.all;

entity tb_LCD_Controller is
end tb_LCD_Controller;

architecture tb of tb_LCD_Controller is 
	component LCD_Controller 
    
    generic(
    clk_freq  : integer := 50  
  );
  port
  (
    clk             : in std_logic;     
    reset_n         : in std_logic;     
    data_in         : in std_logic_vector (9 downto 0);
    
    lcd_enable      : in std_logic;
    BUSY            : out std_logic;
    RS, E, RW       : out std_logic;
    data_out        : out std_logic_vector (7 downto 0)
  );
end component;

signal    clk             : in std_logic;     
signal    reset_n         : in std_logic;     
signal    data_in         : in std_logic_vector (9 downto 0);
signal    lcd_enable          : in std_logic;
signal    BUSY            : out std_logic;
signal    RS, E, RW       : out std_logic;
signal    data_out        : out std_logic_vector; (7 downto 0)
clock_process: process
begin
	
    dut : LCD_Controller
    
    port map(
    		clk          => clk ,     
    		reset_n      => reset_n,     
    		data_in      => data_in,
    		
            lcd_enable   => lcd_enable,
    		BUSY         => BUSY,
    		RS           => RS,
            E            => E,
            RW           => RW,
    		data_out     => data_out);
			
			
		clock_process: process
		begin 
			clk <= '0';
			wait for clock_period/2;
			clk <= '1';
			wait for clock_period/2;
		end process;
    test : process
			begin
            	
                reset_n <= '1';
                wait for 50 ms;
                reset_n <= '0';
                lcd_enable <= '0';
                count <= '50000';
                wait for 10 us;
                lcd_enable <= '1';
                wait 10 us;
                lcd_enable <= '0';
                


			end process;
            
            
 end tb;
