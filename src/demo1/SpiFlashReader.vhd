-------------------------------------------------------------------------------
-- Copyright (c) 2013 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor:                Xilinx, Inc.
-- \   \   \/    Version:               1.00
--  \   \        Filename:              SpiFlashReader.vhd
--  /   /        Date Last Modified:    January 4 2013
-- /___/   /\    Date Created:          January 4 2013
-- \   \  /  \
--  \___\/\___\
--
--Device:       7 Series FPGAs
--Purpose:      Read data from SPI flash.
--Description:  Read data SPI flash using the SSD.
--Usage:
--  INPUTS:
--  OUTPUTS:
--Reference:
--Revision History:
--    Rev 1.00 (01/04/2013) - Created.
-------------------------------------------------------------------------------
library ieee;
Library UNISIM;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use UNISIM.vcomponents.all;

entity SpiFlashReader is
  port (
    -- Clock and control signals
    inClk               : in  std_logic;
    inReset_EnableB     : in  std_logic;

    -- Read range
    inReadStartAddr32   : in  std_logic_vector(31 downto 0);
    inReadWordCount32   : in  std_logic_vector(31 downto 0);  -- 0=Max count

    -- Data
    outReadData32       : out std_logic_vector(31 downto 0);

    -- Status signals
    outReadDataReady    : out std_logic;  -- '1' when next data work available
    inReadDataAck       : in  std_logic;  -- Set to '1' to read next word
    outReadDone         : out std_logic;  -- '1' when read inReadWordCount32 words

    -- SpiSerDes signals
    outSSDReset_EnableB : out std_logic;  -- Active-high, synchronous reset.
    outSSDStartTransfer : out std_logic;  -- Active-high, initiate transfer of DATAIN
    inSSDTransferDone   : in  std_logic;  -- DONE='1' when transfer is done
    outSSDData8Send     : out std_logic_vector(7 downto 0); -- Sent to SPI device
    inSSDData8Receive   : in  std_logic_vector(7 downto 0) -- Received from SPI device
  );
end SpiFlashReader;

architecture behavioral of SpiFlashReader is
  -- Set for input data bus width in bytes
  constant  cDataWordWidth    : integer := 4; -- 1 = 8-bit, 2 = 16-bit, or 4 = 32-bit
  -- SPI flash information
  ----------------+-------+-------+---------+-------+-------+--------+-----------+--------+--------
  --              |       |       |         | Write | Bulk  | Sector | Subsector | Page   | Read
  --              | Addr  | Size  | IDCODE  | Enable| Erase | Size   | Size      | Size   |Status
  -- Manufacturer |       | (READ)| (RDID)  | (WE)  | (BE)  | (SE)   | (SSE)     | (PP)   |(RFSR)
  -- Device       |       |       |         |       |TimeOut| TimeOut| TimeOut   | TimeOut|
  ----------------+-------+-------+---------+-------+-------+--------+-----------+--------+--------
  -- Micron       | 24-bit| 128Mb | x20BA18 |       |       | 65536B | 4096B     | 256B   |
  -- N25Q128B     |       | (x03) | (x9F)   | (x06) | (xC7) | (xD8)  | (x20)     | (x02)  | (x70)
  -- N25Q128E     |       |       |         |       | 250s  | 3s     | 0.8s      | 5ms    |
  --------------+-------+-------+---------+-------+-------+--------+-----------+--------  -------
  -- Micron       | 32-bit| 128Mb | x20BA19 |       |       | 65536B | 4096B     | 256B   |
  -- N25Q256E     |       | (x13) | (x9F)   | (x06) | (xC7) | (xDC)  | (x21)     | (x12)  | (x70)
  --              |       |       |         |       | 480s  | 3s     | 0.8s      | 5ms    |
  ----------------+-------+-------+---------+-------+-------+--------+-----------+--------+--------
  -- Customize these constants per the target SPI flash device
  -- Device command opcodes
  constant  cCmdREAD24        : std_logic_vector(7 downto 0)  := X"03";
  constant  cCmdREAD32        : std_logic_vector(7 downto 0)  := X"13";
  constant  cCmdRDID          : std_logic_vector(7 downto 0)  := X"9F";
  -- Device addressing (24-bit or 32-bits)
  constant  cAddrWidth        : integer                       := 24;  -- 24 or 32

  -- Registers
  signal  regReadStartAddr32  : std_logic_vector(31 downto 0) := X"00000000";
  signal  regWordCounter32    : std_logic_vector(31 downto 0) := X"00000000";
  signal  regData40           : std_logic_vector(39 downto 0) := X"0000000000";
  signal  regReadDataReady    : std_logic                     := '0';
  signal  regReadDone         : std_logic                     := '0';
  signal  regSSDReset_EnableB : std_logic                     := '1';
  signal  regSSDResetAfterSendWord  : std_logic               := '1';
  signal  regSSDStartTransfer : std_logic                     := '0';
  signal  regSSDData8Send     : std_logic_vector(7 downto 0)  := "00000000";
  signal  regCounter3         : std_logic_vector(2 downto 0)  := "000";

  -- Attributes
  attribute clock_signal            : string;
  attribute clock_signal of inClk   : signal is "yes";

  -- State definitions
  type    sReader is
  (
    sReaderInitialize,
    sReaderSendRead, sReaderCheckId,
    sReaderReadData, sReaderReadData1, sReaderReadData2,
    sReaderSendWord, sReaderSendWord1, sReaderSendWord2,
    sReaderDone
  );
  signal  stateReader         : sReader;
  signal  stateAfterSendWord  : sReader;

begin

  processReader : process (inClk)
  begin
    if (rising_edge(inClk)) then
      if (inReset_EnableB='1') then
        -- RESET
        -- Reset module output signals
        regData40           <= X"0000000000";
        regReadDataReady    <= '0';
        regReadDone         <= '0';
        -- Reset SpiSerDes control signals
        regSSDReset_EnableB <= '1';
        regSSDStartTransfer <= '0';
        regSSDData8Send     <= X"00";
        -- Setup for next state
        regData40           <= X"0000000000";
        stateReader        <= sReaderInitialize;

      else
        case (stateReader) is
          --------------------------------------------------------------------
          -- READER START
          -- Initialize the SPI bus: Wait for one byte to output to the SPI bus.
          -- STARTUP.USRCCLKO MUX needs a few clock cycles to switch.
          when sReaderInitialize =>
            regReadStartAddr32          <= inReadStartAddr32;
            regWordCounter32            <= inReadWordCount32;
            regData40                   <= X"0000000000";
            regCounter3                 <= "100";
            stateReader                 <= sReaderSendWord;
            stateAfterSendWord          <= sReaderSendRead;
            regSSDResetAfterSendWord    <= '1';

          --------------------------------------------------------------------
          -- Send READ command
          when sReaderSendRead =>
            if (regReadStartAddr32=X"FFFFFFFF") then
              regData40                   <= cCmdRDID & X"00000000";
              regCounter3                 <= "100";
              stateReader                 <= sReaderSendWord;
              stateAfterSendWord          <= sReaderCheckId;
              regSSDResetAfterSendWord    <= '1';
            else
              if (cAddrWidth=32) then
                regData40                 <= cCmdREAD32 & regReadStartAddr32;
                regCounter3               <= "101";
              else
                regData40                 <= cCmdREAD24 & regReadStartAddr32(23 downto 0) & X"00";
                regCounter3               <= "100";
              end if;
              stateReader                 <= sReaderSendWord;
              stateAfterSendWord          <= sReaderReadData;
              regSSDResetAfterSendWord    <= '0';
            end if;

          --------------------------------------------------------------------
          -- Read loop until done (read N words)
          when sReaderReadData =>
            regData40                   <= X"0000000000";
            regCounter3                 <= std_logic_vector(to_unsigned(cDataWordWidth,3));
            stateReader                 <= sReaderSendWord;
            stateAfterSendWord          <= sReaderReadData1;
            regSSDResetAfterSendWord    <= '0';

          when sReaderReadData1 =>
            regReadDataReady            <= '1';
            regWordCounter32            <= regWordCounter32 - 1;
            stateReader                 <= sReaderReadData2;

          when sReaderReadData2 =>
            if (inReadDataAck = '1') then
              regReadDataReady          <= '0';
              if (regWordCounter32 = 0) then
                stateReader             <= sReaderDone;
              else
                stateReader             <= sReaderReadData;
              end if;
            end if;

          --------------------------------------------------------------------
          -- CHECK DEVICE ID
          when sReaderCheckId =>
            regReadDataReady            <= '1';
            stateReader                 <= sReaderDone;

          --------------------------------------------------------------------
          -- Send/read word
          when sReaderSendWord =>
            regSSDReset_EnableB <= '0';
            regSSDData8Send     <= regData40(39 downto 32);
            regSSDStartTransfer <= '1';
            stateReader         <= sReaderSendWord1;

          when sReaderSendWord1 =>
            regCounter3         <= regCounter3 - 1;
            regSSDData8Send     <= regData40(31 downto 24);
            stateReader         <= sReaderSendWord2;

          when sReaderSendWord2 =>
            if (regCounter3="000") then
              regSSDStartTransfer <= '0';
            end if;
            if (inSSDTransferDone = '1') then
              regData40 <= regData40(31 downto 0) & inSSDData8Receive;
              if (regCounter3 = "000") then
                regSSDReset_EnableB <= regSSDResetAfterSendWord;
                stateReader         <= stateAfterSendWord;
              else
                stateReader         <= sReaderSendWord1;
              end if;
            end if;

          --------------------------------------------------------------------
          -- Done state
          when sReaderDone  =>
            regSSDReset_EnableB <= '1';
            regReadDone         <= '1';

          when others =>
            stateReader         <= sReaderDone;
        end case;
      end if;
    end if;
  end process processReader;

  -- Assign outputs
  outReadData32       <= regData40(31 downto 0);
  outReadDataReady    <= regReadDataReady;
  outReadDone         <= regReadDone;
  outSSDReset_EnableB <= regSSDReset_EnableB;
  outSSDStartTransfer <= regSSDStartTransfer;
  outSSDData8Send     <= regSSDData8Send;

end behavioral;

