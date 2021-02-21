library ieee;
use ieee.std_logic_1164.all;

entity PWMComparator is
port(
	a 		: in std_logic_vector(7 downto 0);
	b		: in std_logic_vector(7 downto 0);
	clk		: in std_logic;
	c		: out std_logic);
end PWMComparator;

architecture rtl of PWMComparator is
component register1 is
port(
	D   : in std_logic; 
    clk : in std_logic;
    Q   : out std_logic);
end component;

component equalTest is
port (
	A    	: in std_logic; 
    B	 	: in std_logic;
    equal   : out std_logic 
);
end component;

begin

process(clk)
begin
	if rising_edge(clk) then
		A <= a;
		B <= b;
		if equal = '1' then
			D <= equal;
			c <= Q;
		end if;
end process;
end rtl;