-------------------------------------------------------------------------------
-- Copyright (c) 2013 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor:                Xilinx, Inc.
-- \   \   \/    Version:               1.00
--  \   \        Filename:              JtagToSpiFlashReader.vhd
--  /   /        Date Last Modified:    January 4 2013
-- /___/   /\    Date Created:          January 4 2013
-- \   \  /  \
--  \___\/\___\
--
--Devices:      7 series FPGAs
--Purpose:      JTAG to SPIFlashProgrammer bridge.
--Description:  Bridges JTAG port to a SPI flash programmer.
--              Defines a 32-bit JTAG data register.
--                Data that is shifted into the 32-bit register is forwarded
--                to the SPI flash programmer when the SPI flash programmer
--                is not busy.
--                Captures SPI flash programmer status to export.
--Usage:        FPGA design:  Instantiate a BSCANE2 primitive and connect to
--              this module. Also, instantiate a SpiFlashProgrammer and connect
--              to this module.
--              JTAG:
--                1. Load the USERx instruction to select the BSCANE2 instance.
--                2. Load the start token into the 32-bit data register to
--                   enable the SPI flash programmer.
--                3. Load all of the data to be programmed via the 32-bit data
--                   register. Note: For each data shift, if the JTAG TDO output
--                   indicates that the SPI flash programmer was busy, then the
--                   shifted TDI input data was not updated to the SPI flash
--                   programmer, i.e. you must repeat the data load.
--Signal Timing:
--Reference:
--Revision History:
--    Revision (YYYY/MM/DD) - [User] Description
--    Rev 1.00 (2013/01/04) - [RMK] Created.
-------------------------------------------------------------------------------
library ieee;
library UNISIM;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use UNISIM.vcomponents.all;

entity JtagToSpiFlashReader is
  port
  (
    -- Connections to JTAG BSCANE2
    inBscanTck            : in  std_logic;  -- Connect to BSCANE2.TCK
    inBscanSel            : in  std_logic;  -- Connect to BSCANE2.SEL
    inBscanCapture        : in  std_logic;  -- Connect to BSCANE2.CAPTURE
    inBscanShift          : in  std_logic;  -- Connect to BSCANE2.SHIFT
    inBscanUpdate         : in  std_logic;  -- Connect to BSCANE2.UPDATE
    inBscanTdi            : in  std_logic;  -- Connect to BSCANE2.TDI
    outBscanTdo           : out std_logic;  -- Connect to BSCANE2.TDO

    -- Connections for SpiFlashReader
    outSFRReset_EnableB   : out std_logic;
    outSFRStartAddr32     : out std_logic_vector(31 downto 0);
    outSFRWordCount32     : out std_logic_vector(31 downto 0);
    inSFRData32           : in  std_logic_vector(31 downto 0);
    inSFRDataReady        : in  std_logic;
    outSFRDataAck         : out std_logic;
    inSFRDone             : in  std_logic
  );
end JtagToSpiFlashReader;

architecture behavioral of JtagToSpiFlashReader is
  -- Registers
  signal  regSFRReset_EnableB : std_logic                     := '1';
  signal  regSFRDataReady     : std_logic                     := '0';
  signal  regJtagShift33      : std_logic_vector(32 downto 0) := "000000000000000000000000000000000";
  signal  regStartAddr32      : std_logic_vector(31 downto 0) := X"00000000";

  -- Signals

  -- Attributes
  attribute clock_signal                : string;
  attribute clock_signal of inBscanTck : signal is "yes";
begin
  -- Capture and keep a local copy of inSFRDataReady
  processSFRDataReady : process (inBscanCapture)
  begin
    if (rising_edge(inBscanCapture)) then
      regSFRDataReady <= inSFRDataReady;
    end if;
  end process processSFRDataReady;

  -- JTAG data shift register
  processShiftRegister : process (inBscanTck)
  begin
    if (rising_edge(inBscanTck)) then
      if (inBscanCapture = '1') then
        -- Load ready + data32
        regJtagShift33  <= regSFRDataReady & inSFRData32;
      elsif (inBscanShift = '1') then
        -- Right shift
        regJtagShift33  <= inBscanTdi & regJtagShift33(32 downto 1);
      end if;
    end if;
  end process processShiftRegister;

  processBscanUpdate : process (inBscanUpdate, inBscanSel)
  begin
    if (inBscanSel = '0') then
      regSFRReset_EnableB <= '1';
      regStartAddr32      <= X"00000000";
    elsif (rising_edge(inBscanUpdate)) then
      regSFRReset_EnableB <= '0';
      regStartAddr32      <= regJtagShift33(31 downto 0);
    end if;
  end process processBscanUpdate;

  -- Assign outputs
  outBscanTdo           <= regJtagShift33(0);
  outSFRDataAck         <= inBscanUpdate and regSFRDataReady;
  outSFRReset_EnableB   <= regSFRReset_EnableB;
  outSFRStartAddr32     <= regStartAddr32;
  outSFRWordCount32     <= X"00000000";   -- Set word count to MAX
end behavioral;

