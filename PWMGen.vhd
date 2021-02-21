library ieee;
use ieee.std_logic_1164.all;

entity PWMGen is
port(
	clk 	: in std_logic;
	rst		: in std_logic;
	din  	: in std_logic_vector(7 downto 0);
	pwm 	: out std_logic;
end PWM Gen;

architecture structural of PWMGen is

component Counter is
port(
	clk 	: in std_logic;
	rst		: in std_logic;
	en  	: in std_logic;
	x 		: out std_logic;
	output	: out std_logic_vector(7 downto 0));
end component;

component PWMReg is
port(
	clk 	: in std_logic;
	load	: in std_logic;
	xin		: in std_logic_vector(7 downto 0);
	y		: out std_logic_vector(7 downto 0));
end component;

component PWMComparator is
port(
	a 		: in std_logic_vector(7 downto 0);
	b		: in std_logic_vector(7 downto 0);
	clk		: in std_logic;
	c		: out std_logic);
end component;
	
component RSLatch is
port(
	s 		: in std_logic;
	r		: in std_logic;
	clk		: in std_logic;
	q		: out std_logic);
end component;
	
begin

process(clk)
begin 
	if rising_edge(clk) then
		--Counter inputs
		rst <= rst;
		en <= '1'; -- not sure if this is correct
	
		--Register inputs
		load <= x;
		xin <= din;
		
		--Comparator inputs
		a <= y;
		b <= output;
		
		--rs_latch inputs
		r <= c;
		s <= x;
		
		--final output 
		pwm <= q;
	end if;

end structural;
	