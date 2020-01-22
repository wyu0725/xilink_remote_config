-------------------------------------------------------------------------------
-- Copyright (c) 2013 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor:                Xilinx, Inc.
-- \   \   \/    Version:               1.00
--  \   \        Filename:              MuxToSpiSerDes.vhd
--  /   /        Date Last Modified:    January 4 2013
-- /___/   /\    Date Created:          January 4 2013
-- \   \  /  \
--  \___\/\___\
--
--Device:       7 Series FPGAs
--Purpose:      MUX for multiple module access to SpiSerDes.
--Description:  Select between two ports that access the SpiSerDes.
--Usage:        Connect one module to port0.
--              Connect the other module to port1.
--              Connect the Y port to the SpiSerDes.
--              Select the active port via the inMuxSelect signal = 0 or 1.
--Reference:
--              See the SpiSerDes module for descriptions of the signals.
--Revision History:
--    Rev 1.00 (01/04/2013) - Created.
-------------------------------------------------------------------------------
library ieee;
Library UNISIM;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use UNISIM.vcomponents.all;

entity MuxToSpiSerDes is
  port
  (
    -- MUX port select
    inMuxSelect           : in  std_logic;  -- 0 = select port0; 1 = select port1

    -- Port0
    inPort0Reset_EnableB  : in  std_logic;
    inPort0StartTransfer  : in  std_logic;
    outPort0TransferDone  : out std_logic;
    inPort0Data8Send      : in  std_logic_vector(7 downto 0);
    outPort0Data8Receive  : out std_logic_vector(7 downto 0);

    -- Port1
    inPort1Reset_EnableB  : in  std_logic;
    inPort1StartTransfer  : in  std_logic;
    outPort1TransferDone  : out std_logic;
    inPort1Data8Send      : in  std_logic_vector(7 downto 0);
    outPort1Data8Receive  : out std_logic_vector(7 downto 0);

    -- MUX portY
    outPortYReset_EnableB : out std_logic;
    outPortYStartTransfer : out std_logic;
    inPortYTransferDone   : in  std_logic;
    outPortYData8Send     : out std_logic_vector(7 downto 0);
    inPortYData8Receive   : in  std_logic_vector(7 downto 0)
  );
end MuxToSpiSerDes;

architecture behavioral of MuxToSpiSerDes is

begin

  -- Assign outputs
  outPortYReset_EnableB <= inPort0Reset_EnableB when (inMuxSelect = '0') else inPort1Reset_EnableB;
  outPortYStartTransfer <= inPort0StartTransfer when (inMuxSelect = '0') else inPort1StartTransfer;
  outPortYData8Send     <= inPort0Data8Send     when (inMuxSelect = '0') else inPort1Data8Send;
  outPort0TransferDone  <= inPortYTransferDone;
  outPort1TransferDone  <= inPortYTransferDone;
  outPort0Data8Receive  <= inPortYData8Receive;
  outPort1Data8Receive  <= inPortYData8Receive;

end behavioral;

