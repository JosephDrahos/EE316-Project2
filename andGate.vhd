library IEEE;
use IEEE.std_logic_1164.all;

entity and_gate is
port(
  x : in std_logic;
  y : in std_logic;
  output: out std_logic);
end and_gate;

architecture rtl of and_gate is 
begin
	process(a,b) is
    begin
    	output <= a and b;
    end process;
end rtl;