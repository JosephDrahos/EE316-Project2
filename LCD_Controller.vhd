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
port
(
  I_CLK_50MHZ     : in std_logic;     -- Input clock signal
  Reset           : in std_logic;     --Reset signals
  data_in         : in std_logic_vector (15 downto 0);
  mode            : in std_logic_vector (2 downto 0);

  RS              : out std_logic;
  E               : out std_logic;
  RW              : out std_logic;
  data_inout      : inout std_logic_vector (7 downto 0)
);
end LCD_Controller;


architecture LUT of LCD_Controller is
  type LCD_STATE is (i1, i2, i3, i4, i5, i6, i7, i8,
                     ready,
                     t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14,
                     p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15,
                     pwm1, pwm2, pwm3, pwm4, pwm5, pwm6, pwm7, pwm8, pwm9, pwm10, pwm11,
                     pwm12, pwm13, pwm14, pwm15,
                     60hz1, 60hz2, 60hz3, 60hz4, 60hz5,
                     120hz1, 120hz2, 120hz3, 120hz4, 120hz5, 120hz6,
                     1000hz1, 1000hz2, 1000hz3, 1000hz4, 1000hz5, 1000hz6, 1000hz7);

   signal state : LCD_STATE;
begin
  LCD_Controller_FSM : process (I_CLK_50MHZ, Reset, mode)
    begin
      if(rising_edge(I_CLK_50MHZ)) then
        case state is

        end case;
      end if;
  end process LCD_Controller_FSM;
end architecture LUT;
