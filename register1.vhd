library ieee;  
use ieee.std_logic_1164.all;  

entity register1 is
port (
	D   : in std_logic; 
    clk : in std_logic;
    Q   : out std_logic 
);
end register1;

architecture rtl of register1 is 
begin

process(clk)
begin
	if rising_edge(clk) then 
		Q <= D; 
	end if;
end process;
end rtl;