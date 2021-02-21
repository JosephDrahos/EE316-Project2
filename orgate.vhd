library IEEE;
use IEEE.std_logic_1164.all;

entity or_gate is
port(
  c : in std_logic;
  d : in std_logic;
  e : in std_logic;
  output2: out std_logic);
end or_gate;

architecture rtl of or_gate_gate is 
begin
	process(c,d) is
    begin
    	output <= c or d or e;
    end process;
end rtl;