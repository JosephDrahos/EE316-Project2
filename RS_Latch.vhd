-- architecture needs work

library ieee;
use ieee.std_logic_1164.all;

entity RSLatch is
port(
	s 		: in std_logic;
	r		: in std_logic;
	clk		: in std_logic;
	q		: out std_logic);
end RSLatch;

architecture rtl of RSLatch is
component and_gate is
port(
  x : in std_logic;
  y : in std_logic;
  output: out std_logic);
end component;

component or_gate is
port(
  c : in std_logic;
  d : in std_logic;
  e : in std_logic;
  output2 : out std_logic);
end component;

component register2 is
port (
	D2   : in std_logic; 
    clk : in std_logic;
	en  : in std_logic;
    Q2   : out std_logic 
);
end component;

begin

process(clk)
begin
	if rising_edge(clk) then
		x <= r;
		y <= s;
		
		d <= r;
		e <= s;
		c <= output;
		
		D2 <= s;
		en <= output;
		tri_inp1 <= Q2;
		
		D2 <= not(output);
		en <= output;
		tri_inp2 < = Q2;
		
		q <= tri_out;

end process;
end rtl;