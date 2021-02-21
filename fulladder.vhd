library ieee;
use ieee.std_logic_1164.all;

entity fulladder is
	port ( 
		cin, x, y	: 	in	Std_logic;
		s, cout		:	out	Std_logic);
end fulladder;

architecture behavioral of fulladder is
begin
	s <= x xor y xor cin;
	cout <= (x and y) or (cin and x) or (cin and y);
end behavioral;