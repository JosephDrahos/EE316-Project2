--------------------------------------------------------------------------------
-- Filename     : LCD_Controller.vhd
-- Author       : Joseph Drahos
-- Date Created : 2021-9-2
-- Project      : EE316 Project 2
-- Description  : LCD Controller Code
--------------------------------------------------------------------------------

-----------------
--  Libraries  --
-----------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--------------
--  Entity  --
--------------
entity LCD_Controller is
  generic(
    clk_freq  : integer := 50  --system clock frequency
  );
  port
  (
    clk     : in std_logic;     -- Input clock signal
    reset_n           : in std_logic;     --Reset signals
    lcd_bus         : in std_logic_vector (9 downto 0);--control signals and data
    lcd_enable          : in std_logic;
    busy            : out std_logic;
    rs, e, rw       : out std_logic;
    lcd_data        : out std_logic_vector (7 downto 0)
  );
end LCD_Controller;

architecture LUT of LCD_Controller is
  type LCD_STATE is (init, ready, send);
   signal state : LCD_STATE;
begin
  LCD_Controller_FSM : process (clk, reset_n)
    variable count : integer := 0; --clock counter
    begin
      if(rising_edge(clk)) then
        case state is
          when init =>
            busy <= '1';
            count := count + 1;
            --wait 50 ms on startup
            if(count < (50000*clk_freq))then
                rs <= '0';
                rw <= '0';
					 state <= init;
            --wait 10us
            elsif(count < (50010 * clk_freq)) then
              lcd_data <= "00111000";--init for 8 bit interface
              e <= '1';
              state <= init;
              --wait 50us
            elsif(count < (50060*clk_freq)) then
              lcd_data <= (others => '0');
              e <= '0';
              state <= init;
              --wait 10us
            elsif(count < (50070*clk_freq))then
              lcd_data <= "00001100";--init for 8 bit interface
              e <= '1';
              state <= init;
              --wait 50us
            elsif(count < (50120*clk_freq)) then
              lcd_data <= (others => '0');
              e <= '0';
              state <= init;
              --wait 10us
            elsif(count < (50130*clk_freq))then
              lcd_data <= "00000001";--display clear
              e <= '1';
              state <= init;
              --wait 2 ms
            elsif(count < (52130*clk_freq)) then
              lcd_data <= (others => '0');
              e <= '0';
              state <= init;
              --wait 10us
            elsif(count < (52140*clk_freq))then
              lcd_data <= "00000110";--entry mode decrement and shift off
              e <= '1';
              state <= init;
              --wait 60 us
            elsif(count < (52200*clk_freq)) then
              lcd_data <= (others => '0');
              e <= '0';
              state <= init;
            else
              busy <= '0';
              count := 0;
              state <= ready;
            end if;

          when ready =>
            if(lcd_enable = '1') then
              busy <= '1';
              rs <= lcd_bus(9);
              rw <= lcd_bus(8);
              lcd_data <= lcd_bus(7 downto 0);
              count := 0;
              state <= send;
            else
              busy <= '0';
              rs <= '0';
              rw <= '0';
              lcd_data <= (others => '0');
              state <= ready;
            end if;

          when send =>
            busy <= '1';
            --dont exit for 50us
            if (count < (50*clk_freq))then
              if(count < clk_freq) then
                e <= '0';
              elsif(count < (15*clk_freq))then
                e <= '1';
              elsif(count < (30*clk_freq))then
                e <= '0';
              end if;
              count := count + 1;
              state <= send;
            else
              count := 0;
              state <= ready;
            end if;

        end case;
        --reset
        if(reset_n = '0')then
          count := 0;
          state <= init;
        end if;
      end if;
  end process LCD_Controller_FSM;
end architecture LUT;
