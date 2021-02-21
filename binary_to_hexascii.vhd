library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
  entity binary_to_hexascii is
	port(
		clk : in std_logic;
		input : in std_logic_vector(7 downto 0);
		output : out std_logic_vector(15 downto 0)
	);
  end entity;
  
  architecture behavioral of binary_to_hexascii is
	begin
		process (clk) begin
			if(rising_edge(clk))then
				if(input(7 downto 4) = "0000")then --0
					output(15 downto 8) <= "00110000";
				elsif(input(7 downto 4) = "0001")then --1
					output(15 downto 8) <= "00110001";
				elsif(input(7 downto 4) = "0010")then --2
					output(15 downto 8) <= "00110010";
				elsif(input(7 downto 4) = "0011")then --3
					output(15 downto 8) <= "00110011";
				elsif(input(7 downto 4) = "0100")then --4
					output(15 downto 8) <= "00110100";
				elsif(input(7 downto 4) = "0101")then --5
					output(15 downto 8) <= "00110101";
				elsif(input(7 downto 4) = "0110")then --6
					output(15 downto 8) <= "00110110";
				elsif(input(7 downto 4) = "0111")then --7
					output(15 downto 8) <= "00110111";
				elsif(input(7 downto 4) = "1000")then --8
					output(15 downto 8) <= "00111000";
				elsif(input(7 downto 4) = "1001")then --9
					output(15 downto 8) <= "00111001";
				elsif(input(3 downto 0) = "1001")then --9
					output(7 downto 0) <= "00111001";
				elsif(input(7 downto 4) = "1010")then --A
					output(15 downto 8) <= "01000001";
				elsif(input(7 downto 4) = "1011")then --B
					output(15 downto 8) <= "01000010";
				elsif(input(7 downto 4) = "1100")then --C
					output(15 downto 8) <= "01000011";
				elsif(input(7 downto 4) = "1101")then --D
					output(15 downto 8) <= "01000100";
				elsif(input(7 downto 4) = "1110")then --E
					output(15 downto 8) <= "01000101";
				elsif(input(7 downto 4) = "1111")then --F
					output(15 downto 8) <= "01000110";
				end if;
				
				if(input(3 downto 0) = "0000")then --0
					output(7 downto 0) <= "00110000";
				elsif(input(3 downto 0) = "0001")then --1
					output(7 downto 0) <= "00110001";
				elsif(input(3 downto 0) = "0010")then --2
					output(7 downto 0) <= "00110010";
				elsif(input(3 downto 0) = "0011")then --3
					output(7 downto 0) <= "00110011";
				elsif(input(3 downto 0) = "0100")then --4
					output(7 downto 0) <= "00110100";
				elsif(input(3 downto 0) = "0101")then --5
					output(7 downto 0) <= "00110101";
				elsif(input(3 downto 0) = "0110")then --6
					output(7 downto 0) <= "00110110";
				elsif(input(3 downto 0) = "0111")then --7
					output(7 downto 0) <= "00110111";
				elsif(input(3 downto 0) = "1000")then --8
					output(7 downto 0) <= "00111000";
				elsif(input(3 downto 0) = "1001")then --9
					output(7 downto 0) <= "00111001";
				elsif(input(3 downto 0) = "1010")then --A
					output(7 downto 0) <= "01000001";
				elsif(input(3 downto 0) = "1011")then --B
					output(7 downto 0) <= "01000010";
				elsif(input(3 downto 0) = "1100")then --C
					output(7 downto 0) <= "01000011";
				elsif(input(3 downto 0) = "1101")then --D
					output(7 downto 0) <= "01000100";
				elsif(input(3 downto 0) = "1110")then --E
					output(7 downto 0) <= "01000101";
				elsif(input(3 downto 0) = "1111")then --F
					output(7 downto 0) <= "01000110";
				end if;
			end if;
		end process;
  end architecture behavioral;