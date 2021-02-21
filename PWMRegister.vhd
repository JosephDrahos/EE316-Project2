library ieee;
use ieee.std_logic_1164.all;

entity PWMReg is
port(
	clk 	: in std_logic;
	load	: in std_logic;
	xin		: in std_logic_vector(7 downto 0);
	y		: out std_logic_vector(7 downto 0));
end PWMReg;

architecture rtl of PWMReg is
begin

process(clk)
begin
	if rising_edge(clk) then
		if load = '1' then
			y <= xin;
		end if;
	end if;
end process;
end rtl;