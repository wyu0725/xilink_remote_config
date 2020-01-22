-------------------------------------------------------------------------------
-- Copyright (c) 2013 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor:                Xilinx, Inc.
-- \   \   \/    Version:               1.00
--  \   \        Filename:              blinker.vhd
--  /   /        Date Last Modified:    January 21 2013
-- /___/   /\    Date Created:          January 21 2013
-- \   \  /  \
--  \___\/\___\
--
--Devices:      7 series FPGAs
--Purpose:      Blinks LED on KC705
--Description:
--Usage:
--Signal Timing:
--Reference:
--Revision History:
--    Revision (YYYY/MM/DD) - [User] Description
--    Rev 1.00 (2013/01/21) - [RMK] Created.
-------------------------------------------------------------------------------
Library UNISIM;
library ieee;
use UNISIM.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity blinker is
  port (
    inClk     : in  std_logic;
    outLED    : out std_logic
  );
end blinker;

architecture behavioral of blinker is

  signal  regCounter32  : std_logic_vector(31 downto 0) := X"00000000";

begin

  processCount : process(inClk)
  begin
    if (rising_edge(inClk)) then
      regCounter32 <= regCounter32 + 1;
    end if;
  end process processCount;

  outLED  <= regCounter32(27) and regCounter32(26);
end behavioral;

