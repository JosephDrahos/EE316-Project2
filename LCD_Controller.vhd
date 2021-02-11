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
    I_CLK_50MHZ     : in std_logic;     -- Input clock signal
    Reset           : in std_logic;     --Reset signals
    data_in         : in std_logic_vector (9 downto 0);--control signals and data
    lcd_en          : in std_logic;
    BUSY            : out std_logic;
    RS, E, RW       : out std_logic;
    data_out        : out std_logic_vector (7 downto 0)
  );
end LCD_Controller;

architecture LUT of LCD_Controller is
  type LCD_STATE is (init, ready, send);
   signal state : LCD_STATE;
begin
  LCD_Controller_FSM : process (I_CLK_50MHZ, Reset)
    variable count : integer := 0; --clock counter
    begin
      if(rising_edge(I_CLK_50MHZ)) then
        case state is
          when init =>
            BUSY <= '1';
            count := count + 1;
            --wait 50 ms on startup
            if(count < (50000*clk_freq))then
                RS <= '0';
                RW <= '0';
					 state <= init;
            --wait 100 us
            elsif(count < (50100 * clk_freq)) then
              data_out <= "00110000";--init for 8 bit interface
              E <= '1';
              state <= init;
              --wait 4.1 ms
            elsif(count < (54200*clk_freq)) then
              data_out <= (others => '0');
              E <= '0';
              state <= init;
              --wait 100us
            elsif(count < (54300*clk_freq))then
              data_out <= "00110000";--init for 8 bit interface
              E <= '1';
              state <= init;
              --wait 1 ms
            elsif(count < (55300*clk_freq)) then
              data_out <= (others => '0');
              E <= '0';
              state <= init;
              --wait 100us
            elsif(count < (55400*clk_freq))then
              data_out <= "00110000";--init for 8 bit interface
              E <= '1';
              state <= init;
              --wait 1 ms
            elsif(count < (56400*clk_freq)) then
              data_out <= (others => '0');
              E <= '0';
              state <= init;
              --wait 100us
            elsif(count < (57500*clk_freq))then
              data_out <= "00110000";--no lines, char font
              E <= '1';
              state <= init;
              --wait 1 ms
            elsif(count < (58500*clk_freq)) then
              data_out <= (others => '0');
              E <= '0';
              state <= init;
              --wait 100us
            elsif(count < (58600*clk_freq))then
              data_out <= "00001100";--display on, cursor off, no blink
              E <= '1';
              state <= init;
              --wait 1 ms
            elsif(count < (59600*clk_freq)) then
              data_out <= (others => '0');
              E <= '0';
              state <= init;
              --wait 100us
            elsif(count < (59700*clk_freq))then
              data_out <= "00000110";--move the cursor, do not shift the display
              E <= '1';
              state <= init;
              --wait 1 ms
            elsif(count < (60700*clk_freq)) then
              data_out <= (others => '0');
              E <= '0';
              state <= init;
              --wait 100us
            elsif(count < (60800*clk_freq))then
              data_out <= "10000000";--set the cursor position to home address
              E <= '1';
              state <= init;
              --wait 1 ms
            elsif(count < (61800*clk_freq)) then
              data_out <= (others => '0');
              E <= '0';
              state <= init;
            else
              BUSY <= '0';
              count := 0;
              state <= ready;
            end if;

          when ready =>
            if(lcd_en = '1') then
              BUSY <= '1';
              RS <= data_in(9);
              RW <= data_in(8);
              data_out <= data_in(7 downto 0);
              count := 0;
              state <= send;
            else
              BUSY <= '0';
              RS <= '0';
              RW <= '0';
              data_out <= (others => '0');
              state <= ready;
            end if;

          when send =>
            BUSY <= '1';
            --cant exit until 4 ms
            if (count < (4000*clk_freq))then
              if(count < clk_freq) then
                E <= '0';
              elsif(count < (1500*clk_freq))then
                E <= '1';
              elsif(count < (3000*clk_freq))then
                E <= '0';
              end if;
              count := count + 1;
              state <= send;
            else
              count := 0;
              state <= ready;
            end if;

        end case;
        --reset
        if(Reset = '1')then
			 data_out <= "00000001";
          state <= init;
          count := 0;
        end if;
      end if;
  end process LCD_Controller_FSM;
end architecture LUT;
