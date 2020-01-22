-------------------------------------------------------------------------------
-- Copyright (c) 2013 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor:                Xilinx, Inc.
-- \   \   \/    Version:               1.00
--  \   \        Filename:              JtagToSpiFlashProgrammer.vhd
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

entity JtagToSpiFlashProgrammer is
  port
  (
    -- Connections to JTAG BSCANE2
    inBscanDrck           : in  std_logic;  -- Connect to BSCANE2.DRCK
    inBscanSel            : in  std_logic;  -- Connect to BSCANE2.SEL
    inBscanCapture        : in  std_logic;  -- Connect to BSCANE2.CAPTURE
    inBscanShift          : in  std_logic;  -- Connect to BSCANE2.SHIFT
    inBscanUpdate         : in  std_logic;  -- Connect to BSCANE2.UPDATE
    inBscanTdi            : in  std_logic;  -- Connect to BSCANE2.TDI
    outBscanTdo           : out std_logic;  -- Connect to BSCANE2.TDO

    -- Connections for SpiFlashProgrammer
    outSFPReset_EnableB   : out std_logic;
    outSFPCheckIdOnly     : out std_logic;
    outSFPVerifyOnly      : out std_logic;
    outSFPData32          : out std_logic_vector(31 downto 0);
    outSFPDataWriteEnable : out std_logic;
    inSFPReady_BusyB      : in  std_logic;
    inSFPDone             : in  std_logic;
    inSFPError            : in  std_logic;
    inSFPErrorIdcode      : in  std_logic;
    inSFPErrorErase       : in  std_logic;
    inSFPErrorProgram     : in  std_logic;
    inSFPErrorTimeOut     : in  std_logic;
    inSFPErrorCrc         : in  std_logic;
    inSFPStarted          : in  std_logic;
    inSFPInitializeOK     : in  std_logic;
    inSFPCheckIdOK        : in  std_logic;
    inSFPEraseSwitchWordOK: in  std_logic;
    inSFPEraseOK          : in  std_logic;
    inSFPProgramOK        : in  std_logic;
    inSFPVerifyOK         : in  std_logic;
    inSFPProgramSwitchWordOK: in  std_logic
  );
end JtagToSpiFlashProgrammer;

architecture behavioral of JtagToSpiFlashProgrammer is

  -- Constants
  constant  cStartTokenProgram: std_logic_vector(15 downto 0) := X"CA75";
  constant  cStartTokenCheckId: std_logic_vector(15 downto 0) := X"1DCD";
  constant  cStartTokenVerify : std_logic_vector(15 downto 0) := X"1423";

  -- Registers
  signal  regSFPReset_EnableB : std_logic                     := '1';
  signal  regSFPReady_BusyB   : std_logic                     := '0';
  signal  regJtagShift32      : std_logic_vector(31 downto 0) := X"00000000";

  -- Signals
  signal  intStartProgram     : std_logic;
  signal  intCheckIdOnly      : std_logic;
  signal  intVerifyOnly       : std_logic;

  -- Attributes
  attribute clock_signal                : string;
  attribute clock_signal of inBscanDrck : signal is "yes";

  function to_std_logic(inBoolean: boolean) return std_logic is
  begin
    if inBoolean then
      return('1');
    else
      return('0');
    end if;
  end function To_Std_Logic;

begin
  -- Capture and keep a local copy of inSFPReady_BusyB
  processSFPReadyBusyB : process (inBscanCapture)
  begin
    if (rising_edge(inBscanCapture)) then
      regSFPReady_BusyB <= inSFPReady_BusyB;
    end if;
  end process processSFPReadyBusyB;

  -- JTAG data shift register
  processShiftRegister : process (inBscanDrck)
  begin
    if (rising_edge(inBscanDrck)) then
      if (inBscanCapture = '1') then
        -- Parallel load
        regJtagShift32(0)             <= regSFPReady_BusyB;
        regJtagShift32(1)             <= inSFPDone;
        regJtagShift32(2)             <= inSFPError;
        regJtagShift32(3)             <= inSFPErrorIdcode;
        regJtagShift32(4)             <= inSFPErrorErase;
        regJtagShift32(5)             <= inSFPErrorProgram;
        regJtagShift32(6)             <= inSFPErrorTimeOut;
        regJtagShift32(7)             <= inSFPErrorCrc;
        regJtagShift32(8)             <= inSFPStarted;
        regJtagShift32(9)             <= inSFPInitializeOK;
        regJtagShift32(10)            <= inSFPCheckIdOK;
        regJtagShift32(11)            <= inSFPEraseSwitchWordOK;
        regJtagShift32(12)            <= inSFPEraseOK;
        regJtagShift32(13)            <= inSFPProgramOK;
        regJtagShift32(14)            <= inSFPVerifyOK;
        regJtagShift32(15)            <= inSFPProgramSwitchWordOK;
        regJtagShift32(31 downto 16)  <= X"0000";
      elsif (inBscanShift = '1') then
        -- Right shift
        regJtagShift32  <= inBscanTdi & regJtagShift32(31 downto 1);
      end if;
    end if;
  end process processShiftRegister;

  -- Wait for start token from JTAG - Extra protection from accidental reprogramming
  processWaitForStartToken : process (inBscanUpdate,inBscanSel)
  begin
    if (inBscanSel  = '0') then
      regSFPReset_EnableB <= '1';
    elsif (rising_edge(inBscanUpdate)) then
      if ((intStartProgram='1') or (intCheckIdOnly='1') or (intVerifyOnly='1')) then
        regSFPReset_EnableB <= '0';
      end if;
    end if;
  end process processWaitForStartToken;

  intStartProgram <= to_std_logic(regJtagShift32(15 downto 0) = cStartTokenProgram);
  intCheckIdOnly  <= to_std_logic(regJtagShift32(15 downto 0) = cStartTokenCheckId);
  intVerifyOnly   <= to_std_logic(regJtagShift32(15 downto 0) = cStartTokenVerify);

  -- Assign outputs
  outBscanTdo           <= regJtagShift32(0);
  outSFPReset_EnableB   <= regSFPReset_EnableB;
  outSFPCheckIdOnly     <= intCheckIdOnly;
  outSFPVerifyOnly      <= intVerifyOnly;
  outSFPData32          <= regJtagShift32;
  outSFPDataWriteEnable <= (inBscanUpdate and regSFPReady_BusyB);
end behavioral;

