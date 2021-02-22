LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity tb is
end tb;

architecture Behavior of tb is
	component i2c_user_logic is 
	Generic(slave_addr : std_logic_vector(6 downto 0) := "1110001");
	PORT(
			clock		: in std_logic;
			dataIn	: in std_logic_vector(15 downto 0) := X"ABCD";
			outSCL	: inout std_logic;
			outSDA	: inout std_logic
	);
	end component;
	
	signal slave_addr : std_logic_vector(6 downto 0) := "1110001";
	signal clock: std_logic:='0';
	signal dataIn: std_logic_vector(15 downto 0) := X"ABCD";
	signal outSCL: std_logic;
	signal outSDA: std_logic ;
	type state_type is (start,write_data,repeat);
	signal state : state_type := start;
	signal address : std_logic_vector(6 downto 0);
	signal Cont 	: integer := 16383;
	signal busyReg, busySig, reset, enable, r_w, ackSig : std_logic;
	signal regData	: std_logic_vector(15 downto 0);
	signal dataOut	: std_logic_vector(7 downto 0);
	signal byteSel	: integer := 0;
	signal MaxByte : integer := 12;
	
	begin
	UUT: i2c_user_logic
		generic map(slave_addr=>"1110001")
		port map( clock=>clock, dataIn=>DataIn, outSCL=>outSCL, outSDA=>outSDA);
		clock <= not clock after 5 ns;
	process
	begin
		wait for 500 us;
		busySig <= '0';
		busyReg<= '1';
		wait for 50 us;
		byteSel<=9;
		wait for 50 us;
		regData<=dataIn;
		wait for 50 us;
		
		wait;
	end process;
	end behavior;
	
