library ieee;  
use ieee.std_logic_1164.all;  

entity register2 is
port (
	D2   : in std_logic; 
    clk : in std_logic;
	en  : in std_logic;
    Q2   : out std_logic 
);
end register2;

architecture rtl of register2 is 
begin

process(clk)
begin
	if rising_edge(clk) then 
		if en = '1' then
			Q <= D;
		end if;
	end if;
end process;
end rtl;