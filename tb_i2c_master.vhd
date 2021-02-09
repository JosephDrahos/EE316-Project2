LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY tb_i2c_master IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
END tb_i2c_master;

ARCHITECTURE behavioral OF tb_i2c_master IS

COMPONENT i2c_master IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END COMPONENT;
signal clk       : STD_LOGIC:='0';                    --system clock
signal reset_n   : STD_LOGIC;                    --active low reset
signal ena       : STD_LOGIC;                    --latch in command
signal addr      : STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
signal rw        : STD_LOGIC;                    --'0' is write, '1' is read
signal data_wr   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
signal busy      : STD_LOGIC;                    --indicates transaction in progress
signal data_rd   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
signal ack_error : STD_LOGIC;                    --flag if improper acknowledge from slave
signal sda       : STD_LOGIC;                    --serial data output of i2c bus
signal scl       : STD_LOGIC;                   --serial clock output of i2c bus
BEGIN
DUT: i2c_master 
  GENERIC MAP(
    input_clk => 100_000_000, --input clock speed from user logic in Hz
    bus_clk   =>  100_000)   --speed the i2c bus (scl) will run at in Hz
  PORT MAP(
    clk, reset_n, ena, addr, rw, data_wr, busy, data_rd, ack_error, sda, scl); 
 	clk <= not clk after 5 ns;
 	addr <= "1110001";
 	data_wr <= X"A5";

process
begin
	reset_n <= '0';
	ena <= '0';
 	rw <= '0';	
	wait for 50 us;
	reset_n <= '1';
	wait for 50 us;
	ena <= '1';
	wait for 500 us;
	ena <= '0';
	wait for 100 us;
 	rw <= '1';
	wait for 50 us;
	ena <= '1';
	wait for 550 us;
	ena <= '0';
	wait for 50 us;
	
	wait;
end process;
end behavioral;

  
                      