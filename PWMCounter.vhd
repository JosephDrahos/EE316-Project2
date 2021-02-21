--the adder portion of this needs work

library ieee;
use ieee.std_logic_1164.all;

entity Counter is
port(
	clk 	: in std_logic;
	rst		: in std_logic;
	en  	: in std_logic;
	x 		: out std_logic;
	output	: out std_logic_vector(7 downto 0));
end Counter;

architecture rtl of Counter is

signal a, b : std_logic_vector(7 downto 0):= "00000000";

component PWMReg is
port(
	clk 	: in std_logic;
	load	: in std_logic;
	xin		: in std_logic_vector(7 downto 0);
	y		: out std_logic_vector(7 downto 0));
end component;

component equalTest is
port (
	A    	: in std_logic; 
    B	 	: in std_logic;
    equal   : out std_logic 
);
end component;

--component fulladder is
--	port ( 
--		cin, x, y	: 	in	Std_logic;
--		s, cout		:	out	Std_logic);
--end component;

begin
process(clk)
	if rising_edge(clk) then
		D <= (a + b);		--syntax may be wrong
		a <= Q;
		A <= Q;
		B <= b;
		if equal = '1' then
			x <= equal;
		end if;	
		output <= Q;
		
	end process;
end rtl;	