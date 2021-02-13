library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

ENTITY user_logic is 
	PORT(
			i1			: in std_logic_vector (7 downto 0) := "01110110";
			i2			: in std_logic_vector (7 downto 0) := "01110110";
			i3			: in std_logic_vector (7 downto 0) := "01110110";
			i4			: in std_logic_vector (7 downto 0) := "01110111";
			i5			: in std_logic_vector (7 downto 0) := "00000111";
			i6			: in std_logic_vector (7 downto 0) := "01111010";
			i7			: inout std_logic_vector (7 downto 0);
			i8			: inout std_logic_vector (7 downto 0); 
			i9			: inout std_logic_vector (7 downto 0);
			i10		: inout std_logic_vector (7 downto 0);
			sixteen	: in std_logic_vector (15 downto 0) := "1010101111001101";
		--	sel	 	: in std_logic_vector (3 downto 0) := "
			output	: out std_logic_vector (7 downto 0)
		);	
	end user_logic;

architecture Behavior of user_logic is

TYPE sel_states IS (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10);
signal state		: sel_states := s1;


begin
	
	i7 <= "0000" & sixteen(15 downto 12);
	i8 <= "0000" & sixteen(11 downto 8);
	i9 <= "0000" & sixteen(7 downto 4);
	i10 <= "0000" & sixteen(3 downto 0);

end behavior;	
	
--busy register logic (SHOULD PROBABLY GO IN TOP FILE)
entity busy_reg is 
	port
	(
		busy	: in std_logic;
		Q		: out std_logic;
	);
end busy_reg;

architecture behavioral of busy_reg is
begin
	process
	begin
		if busy = '1' then	
			q <= '1';
		else
			q <= '0';
	end process;
	process 
	begin
		when s1 =>
			output <= i1;
			if(q='1')then
				state <= s2;
			else
			end if;
		when s2 =>
			output <= i2;
			if(q='1')then
				state <= s3;
			else
			end if;
		when s3 =>
			output <= i3;
			if(q='1')then
				state <= s4;
			else
			end if;
		when s4 =>
			output <= i4;
			if(q='1')then
				state <= s5;
			else
			end if;
		when s5 =>
			output <= i5;
			if(q='1')then
				state <= s6;
			else
			end if;
		when s6 =>
			output <= i6;
			if(q='1')then
				state <= s7;
			else
			end if;
		when s7 =>
			output <= i7;
			if(q='1')then
				state <= s8;
			else
			end if;
		when s8 =>
			output <= i8;
			if(q='1')then
				state <= s9;
			else
			end if;
		when s9 =>
			output <= i9;
			if(q='1')then
				state <= s10;
			else
			end if;
		when s10 =>
			output <= i10;
			if(q='1')then
				state <= s7;
			else
			end if;
		end case;	
end behavioral;
	
	