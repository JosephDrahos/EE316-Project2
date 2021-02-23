--------------------------------------------------------------------------------
-- Filename     : pwmgeneration.vhd
-- Author       : Joseph Drahos
-- Date Created : 2021-9-2
-- Project      : EE316 Project 2
-- Description  : PWM Generation Code
--------------------------------------------------------------------------------

-----------------
--  Libraries  --
-----------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity pwmgenerator is
  port(
    clk : in std_logic;
    reset : in std_logic;
    en    : in std_logic;
    data_in : in std_logic_vector(7 downto 0);
    state : in std_logic_vector(2 downto 0);

    request_new_data : out std_logic;
    pwm_out : out std_logic
  );
end pwmgenerator;


architecture archpwmgenerator  of  pwmgenerator is
  signal sixtyhzcount : std_logic_vector(11 downto 0) := "110010110111";
  signal onehundredtwentyhzcount : std_logic_vector(11 downto 0) := "011001011011";
  signal onethousandhzcount : std_logic_vector(11 downto 0) := "000011000011";
  signal counter : unsigned(11 downto 0) := (others => '0');
  signal eightbitcounter: unsigned(7 downto 0) := (others => '0');
begin

  pwm : process (clk, reset)
    begin
      if(reset = '1')then
        counter <= (others => '0');
        eightbitcounter <= (others => '0');
      elsif(rising_edge(clk))then
         if(en = '1')then
           if(state = "100" or state = "101" or state = "110")then
             if(state = "100")then
               --8bit reset
               if(eightbitcounter = "11111111")then
                 eightbitcounter <= (others => '0');
               end if;

               --different frequency pwm change
               if(std_logic_vector(counter) = sixtyhzcount)then
                 counter <= (others => '0');
                 request_new_data <= '1';
               else
                 request_new_data <= '0';
               end if;
             elsif(state = "101")then
               if(std_logic_vector(counter) = onehundredtwentyhzcount)then
                 counter <= (others => '0');
                 request_new_data <= '1';
               else
                 request_new_data <= '0';
               end if;
             elsif(state = "110") then
               if(std_logic_vector(counter) = onethousandhzcount)then
                 counter <= (others => '0');
                 request_new_data <= '1';
               else
                 request_new_data <= '0';
               end if;
             end if;

             --pwm proportional to input data
             if(std_logic_vector(eightbitcounter) < data_in)then
               pwm_out <= '1';
             else
               pwm_out <= '0';
             end if;

             eightbitcounter <= eightbitcounter + 1;
             counter <= counter + 1;
           end if;

         end if;
       end if;
  end process pwm;

end architecture;
