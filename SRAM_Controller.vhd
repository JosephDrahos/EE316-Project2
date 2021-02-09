--------------------------------------------------------------------------------
-- Filename     : SRAM_Controller.vhd
-- Author       : Joseph Drahos
-- Date Created : 2021-9-2
-- Project      : EE316 Project 2
-- Description  : SRAM Controller Code
--------------------------------------------------------------------------------

-----------------
--  Libraries  --
-----------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--------------
--  Entity  --
--------------
entity SRAM_controller is
port
(
  -- Clocks & Resets
  I_CLK_50MHZ     : in std_logic;                    -- Input clock signal

  I_SYSTEM_RST_N  : in std_logic;                    -- Input signal to reset SRAM data form ROM

  COUNT_EN : in std_logic;

  RW         : in std_logic;

  DIO : inout std_logic_vector(15 downto 0);

  CE : out std_logic;

  -- Read/Write enable signals
  WE    : out std_logic;     -- signal for writing to SRAM
  OE    : out std_logic;     -- Input signal for enabling output

  UB    : out std_logic;
  LB    : out std_logic;

  -- digit selection input
  IN_DATA      : in std_logic_vector(15 downto 0);    -- gives the values of the digits to be illuminated
                                                            -- bits 0-3: digit 1; bits 4-7: digit 2, bits 8-11: digit 3
                                                            -- bits 12-15: digit 4

  IN_DATA_ADDR : in std_logic_vector(17 downto 0);


  -- seven segment display digit selection port
  OUT_DATA    : out std_logic_vector(15 downto 0);       -- if bit is 1 then digit is activated and if bit is 0 digit is inactive
                                                            -- bits 0-3: digit 1; bits 3-7: digit 2, bit 7: digit 4

  OUT_DATA_ADR : out std_logic_vector(17 downto 0)

  );
end SRAM_controller;


--------------------------------
--  Architecture Declaration  --
--------------------------------
architecture rtl of SRAM_controller is

  -------------
  -- SIGNALS --
  -------------

  -- state machine states for SRAM read and write FSM
  type SRAM_STATE is (INIT,
                      READY,
                      WRITE1,
                      WRITE2,
                      READ1,
                      READ2);

  signal current_state : SRAM_STATE;  -- current state of the

  signal read_data       : std_logic_vector(15 downto 0);

  signal tri_state : std_logic;

begin
------------------------------------------------------------------------------
  -- Process Name     : SRAM_Controller_FSM
  -- Sensitivity List : I_CLK_50MHZ    	: 100 MHz global clock (1 bit)
  --                    MEM_RESET    	: Global Reset line (1 bit)
  --			              R_W		: Read/Write State input (1 bit)
  --                    Count_EN      : 
  --			              IN_DATA		: Input data (16 bits)
  --			              IN_DATA_ADDRESS	: SRAM data address 
  -- Useful Outputs   : WE 		: Write Enable SRAM Input (1 bit)
  --			              CE		: Chip Enable SRAM Input (1 bit)
  --			              OE		: Output Enable SRAM Input (1 bit)
  --			              LB		: Lower-byte Control SRAM Input (1 bit)
  --			              UB 		: Upper-byte Control SRAM Input (1 bit)
  --			
  -- Description      : Finite State Machine Logic for SRAM Controller
  --			Changes between 6 states: Init, Ready, Read1, Read2, Write1, Write2
  ------------------------------------------------------------------------------
 SRAM_Controller_FSM : process (I_CLK_50MHZ, RW, COUNT_EN)
     begin
     if (rising_edge(I_CLK_50MHZ)) then
         case current_state is
             when INIT =>
                 tri_state <= '0';
                 WE     <= '1';
                 OE     <= '1';
                 -- check for written ROM
                 current_state <= READY;
             when READY =>
                 tri_state <= '0';
                 WE     <= '1';
                 OE     <= '1';
                 if (COUNT_EN = '1') then
                   if (RW = '0') then  
                      current_state <= WRITE1;
                   elsif (RW = '1') then
                     current_state <= READ1;
                   end if;
                 end if;
            when READ1 =>
                tri_state <= '0';
                WE     <= '1';
                OE     <= '0';
                current_state <= READ2;
            when READ2 =>
                read_data      <= DIO;
                tri_state <= '0';
                WE     <= '1';
                OE     <= '0';
                current_state <= READY;
            when WRITE1 =>
                tri_state <= '1';
                WE     <= '0';
                OE     <= '1';
                current_state <= WRITE2;
            when WRITE2 =>
                tri_state <= '1';
                WE     <= '0';
                OE     <= '1';
                current_state <= READY;
            -- Error condition, should never occur
            when others =>
                tri_state <= '0';
                WE     <= '1';
                OE     <= '1';
                current_state <= READY;
            end case;
     end if;
 end process SRAM_Controller_FSM;

  DIO          <= IN_DATA when tri_state = '1' else (others => 'Z');
  CE           <= '0';
  UB           <= '0';
  LB           <= '0';
  OUT_DATA     <= read_data;
  OUT_DATA_ADR <= IN_DATA_ADDR;

end architecture rtl;
