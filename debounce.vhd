library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


  entity debounce is
  port(I_CLK : in std_logic;
  I_RESET_N        : in std_logic;  -- System reset (active low)
  I_BUTTON         : in std_logic;  -- Button data to be debounced
  O_BUTTON         : out std_logic  -- Debounced button data
  );
  end entity debounce;

  architecture behavioral of debounce is

  -------------
  -- SIGNALS --
  -------------
  signal s_button_previous : std_logic := '0';
  signal s_button_output   : std_logic := '0';

begin

  ------------------------------------------------------------------------------
  -- Process Name     : DEBOUNCE_CNTR
  -- Sensitivity List : I_CLK           : System clock
  --                    I_RESET_N       : System reset (active low logic)
  -- Useful Outputs   : s_button_output : The debounced button signal
  -- Description      : Process to debounce an input from push button.
  ------------------------------------------------------------------------------
  DEBOUNCE_CNTR: process (I_CLK, I_RESET_N)
    variable v_debounce_max_count : integer := 500000;
    variable v_debounce_counter   : integer range 0 TO v_debounce_max_count := 0;
  begin
    if (I_RESET_N = '1') then
      v_debounce_counter :=  0;
      s_button_output    <= '0';
      s_button_previous  <= '0';

    elsif (rising_edge(I_CLK)) then
      -- Output logic (output when input has been stable for counter period)
      if (v_debounce_counter = v_debounce_max_count) then
        s_button_output <= I_BUTTON;
      else
        s_button_output <= s_button_output;
      end if;

      -- Counter logic (while signal has not changed, increment counter)
      if ((s_button_previous = '1') xor (I_BUTTON = '1')) then
        v_debounce_counter := 0;
      elsif (v_debounce_counter = v_debounce_max_count) then
        v_debounce_counter := 0;
      else
        v_debounce_counter := v_debounce_counter + 1;
      end if;

      -- Set previous value to current value
      s_button_previous <= I_BUTTON;
    end if;
  end process DEBOUNCE_CNTR;
  ------------------------------------------------------------------------------

  -- Assign final debounced output
  O_BUTTON <= s_button_output;

end architecture behavioral;