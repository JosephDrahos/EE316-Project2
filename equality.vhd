library ieee;  
use ieee.std_logic_1164.all;  

entity equalTest is
port (
	A    	: in std_logic; 
    B	 	: in std_logic;
    equal   : out std_logic 
);
end equalTest;

architecture behavior of equalTest is 
begin
	equal <= '1' when (A = B)
	else '0'
end behavior;