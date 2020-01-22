library ieee;
Library UNISIM;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use UNISIM.vcomponents.all;

entity SpiQuickBootDemo is
  port
  (
    -- Status signals
    outLED              : out std_logic_vector(7 downto 0);

    -- SPI flash ports
    -- outSpiClk is output through STARTUPE2.USRCCLKO
    outSpiCsB           : out std_logic;
    outSpiMosi          : out std_logic;
    inSpiMiso           : in  std_logic;
    outSpiWpB           : out std_logic; -- SPI flash write protect
    outSpiHoldB         : out std_logic;

    -- System clock
    SYSCLK_N            : in  std_logic;
    SYSCLK_P            : in  std_logic
  );
end SpiQuickBootDemo;

architecture behavioral of SpiQuickBootDemo is

  component JtagToSpiFlashProgrammer is
  port
  (
    inBscanDrck           : in  std_logic;  -- Connect to BSCANE2.DRCK
    inBscanSel            : in  std_logic;  -- Connect to BSCANE2.SEL
    inBscanCapture        : in  std_logic;  -- Connect to BSCANE2.CAPTURE
    inBscanShift          : in  std_logic;  -- Connect to BSCANE2.SHIFT
    inBscanUpdate         : in  std_logic;  -- Connect to BSCANE2.UPDATE
    inBscanTdi            : in  std_logic;  -- Connect to BSCANE2.TDI
    outBscanTdo           : out std_logic;  -- Connect to BSCANE2.TDO
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
  end component JtagToSpiFlashProgrammer;

  component SpiFlashProgrammer is
  port
  (
    inClk               : in  std_logic;
    inReset_EnableB     : in  std_logic;
    inCheckIdOnly       : in  std_logic;
    inVerifyOnly        : in  std_logic;
    inData32            : in  std_logic_vector(31 downto 0);
    inDataWriteEnable   : in  std_logic;
    outReady_BusyB      : out std_logic;
    outDone             : out std_logic;
    outError            : out std_logic;
    outErrorIdcode      : out std_logic;
    outErrorErase       : out std_logic;
    outErrorProgram     : out std_logic;
    outErrorTimeOut     : out std_logic;
    outErrorCrc         : out std_logic;
    outStarted          : out std_logic;
    outInitializeOK     : out std_logic;
    outCheckIdOK        : out std_logic;
    outEraseSwitchWordOK: out std_logic;
    outEraseOK          : out std_logic;
    outProgramOK        : out std_logic;
    outVerifyOK         : out std_logic;
    outProgramSwitchWordOK: out std_logic;

    -- Signals for SpiSerDes - Connect to instance of SpiSerDes
    outSSDReset_EnableB : out std_logic;
    outSSDStartTransfer : out std_logic;
    inSSDTransferDone   : in  std_logic;
    outSSDData8Send     : out std_logic_vector(7 downto 0);
    inSSDData8Receive   : in  std_logic_vector(7 downto 0)
  );
  end component SpiFlashProgrammer;

  component JtagToSpiFlashReader is
  port
  (
    inBscanTck            : in  std_logic;  -- Connect to BSCANE2.DRCK
    inBscanSel            : in  std_logic;  -- Connect to BSCANE2.SEL
    inBscanCapture        : in  std_logic;  -- Connect to BSCANE2.CAPTURE
    inBscanShift          : in  std_logic;  -- Connect to BSCANE2.SHIFT
    inBscanUpdate         : in  std_logic;  -- Connect to BSCANE2.UPDATE
    inBscanTdi            : in  std_logic;  -- Connect to BSCANE2.TDI
    outBscanTdo           : out std_logic;  -- Connect to BSCANE2.TDO
    outSFRReset_EnableB   : out std_logic;
    outSFRStartAddr32     : out std_logic_vector(31 downto 0);
    outSFRWordCount32     : out std_logic_vector(31 downto 0);
    inSFRData32           : in  std_logic_vector(31 downto 0);
    inSFRDataReady        : in  std_logic;
    outSFRDataAck         : out std_logic;
    inSFRDone             : in  std_logic
  );
  end component JtagToSpiFlashReader;

  component SpiFlashReader is
  port (
    inClk               : in  std_logic;
    inReset_EnableB     : in  std_logic;
    inReadStartAddr32   : in  std_logic_vector(31 downto 0);
    inReadWordCount32   : in  std_logic_vector(31 downto 0);
    outReadData32       : out std_logic_vector(31 downto 0);
    outReadDataReady    : out std_logic;
    inReadDataAck       : in  std_logic;
    outReadDone         : out std_logic;
    outSSDReset_EnableB : out std_logic;
    outSSDStartTransfer : out std_logic;
    inSSDTransferDone   : in  std_logic;
    outSSDData8Send     : out std_logic_vector(7 downto 0);
    inSSDData8Receive   : in  std_logic_vector(7 downto 0)
  );
  end component SpiFlashReader;

  component MuxToSpiSerDes is
  port
  (
    inMuxSelect           : in  std_logic;  -- 0 = select port0; 1 = select port1
    inPort0Reset_EnableB  : in  std_logic;
    inPort0StartTransfer  : in  std_logic;
    outPort0TransferDone  : out std_logic;
    inPort0Data8Send      : in  std_logic_vector(7 downto 0);
    outPort0Data8Receive  : out std_logic_vector(7 downto 0);
    inPort1Reset_EnableB  : in  std_logic;
    inPort1StartTransfer  : in  std_logic;
    outPort1TransferDone  : out std_logic;
    inPort1Data8Send      : in  std_logic_vector(7 downto 0);
    outPort1Data8Receive  : out std_logic_vector(7 downto 0);
    outPortYReset_EnableB : out std_logic;
    outPortYStartTransfer : out std_logic;
    inPortYTransferDone   : in  std_logic;
    outPortYData8Send     : out std_logic_vector(7 downto 0);
    inPortYData8Receive   : in  std_logic_vector(7 downto 0)
  );
  end component MuxToSpiSerDes;

  component SpiSerDes is
  port
  (
    inClk           : in  std_logic;
    inReset_EnableB : in  std_logic;
    inStartTransfer : in  std_logic;
    outTransferDone : out std_logic;
    inData8Send     : in  std_logic_vector(7 downto 0);
    outData8Receive : out std_logic_vector(7 downto 0);
    outSpiCsB       : out std_logic;
    outSpiClk       : out std_logic;
    outSpiMosi      : out std_logic;
    inSpiMiso       : in  std_logic
  );
  end component SpiSerDes;

  component blinker is
  port (
    inClk     : in  std_logic;
    outLED    : out std_logic
  );
  end component blinker;


  signal  intBscan1Capture       : std_logic;
  signal  intBscan1Drck          : std_logic;
  signal  intBscan1Reset         : std_logic;
  signal  intBscan1Sel           : std_logic;
  signal  intBscan1Shift         : std_logic;
  signal  intBscan1Tck           : std_logic;
  signal  intBscan1Tdi           : std_logic;
  signal  intBscan1Update        : std_logic;
  signal  intBscan1Tdo           : std_logic;
  signal  intBufgTck             : std_logic;

  signal  intBscan2Capture       : std_logic;
  signal  intBscan2Drck          : std_logic;
  signal  intBscan2Reset         : std_logic;
  signal  intBscan2Sel           : std_logic;
  signal  intBscan2Shift         : std_logic;
  signal  intBscan2Tck           : std_logic;
  signal  intBscan2Tdi           : std_logic;
  signal  intBscan2Update        : std_logic;
  signal  intBscan2Tdo           : std_logic;

  signal  intSFPReset_EnableB   : std_logic;
  signal  intSFPCheckIdOnly     : std_logic;
  signal  intSFPVerifyOnly      : std_logic;
  signal  intSFPData32          : std_logic_vector(31 downto 0);
  signal  intSFPDataWriteEnable : std_logic;
  signal  intSFPReady_BusyB     : std_logic;
  signal  intSFPDone            : std_logic;
  signal  intSFPError           : std_logic;
  signal  intSFPErrorIdcode     : std_logic;
  signal  intSFPErrorErase      : std_logic;
  signal  intSFPErrorProgram    : std_logic;
  signal  intSFPErrorTimeOut    : std_logic;
  signal  intSFPErrorCrc        : std_logic;
  signal  intSFPStarted           : std_logic;
  signal  intSFPInitializeOK      : std_logic;
  signal  intSFPCheckIdOK         : std_logic;
  signal  intSFPEraseSwitchWordOK : std_logic;
  signal  intSFPEraseOK           : std_logic;
  signal  intSFPProgramOK         : std_logic;
  signal  intSFPVerifyOK          : std_logic;
  signal  intSFPProgramSwitchWordOK : std_logic;

  signal intSFRSSDReset_EnableB : std_logic;
  signal intSFRSSDStartTransfer : std_logic;
  signal intSFRSSDTransferDone  : std_logic;
  signal intSFRSSDData8Send     : std_logic_vector(7 downto 0);
  signal intSFRSSDData8Receive  : std_logic_vector(7 downto 0);
  signal intSFPSSDReset_EnableB : std_logic;
  signal intSFPSSDStartTransfer : std_logic;
  signal intSFPSSDTransferDone  : std_logic;
  signal intSFPSSDData8Send     : std_logic_vector(7 downto 0);
  signal intSFPSSDData8Receive  : std_logic_vector(7 downto 0);
  signal intSSDReset_EnableB    : std_logic;
  signal intSSDStartTransfer    : std_logic;
  signal intSSDTransferDone     : std_logic;
  signal intSSDData8Send        : std_logic_vector(7 downto 0);
  signal intSSDData8Receive     : std_logic_vector(7 downto 0);

  signal intSFRReset_EnableB    : std_logic;
  signal intSFRStartAddr32      : std_logic_vector(31 downto 0);
  signal intSFRWordCount32      : std_logic_vector(31 downto 0);
  signal intSFRData32           : std_logic_vector(31 downto 0);
  signal intSFRDataReady        : std_logic;
  signal intSFRDataAck          : std_logic;
  signal intSFRDone             : std_logic;
  signal intSpiClk              : std_logic;

  signal isysclk                : std_logic;
  signal sysclk                 : std_logic;
  signal intBlinker             : std_logic;

  attribute clock_signal                : string;
  attribute clock_signal of intBufgTck  : signal is "yes";


begin

  iBscan1 : BSCANE2
  generic map (
    JTAG_CHAIN => 1
  )
  port map (
    CAPTURE => intBscan1Capture,
    DRCK    => intBscan1Drck,
    RESET   => intBscan1Reset,
    SEL     => intBscan1Sel,
    SHIFT   => intBscan1Shift,
    TCK     => intBscan1Tck,
    TDI     => intBscan1Tdi,
    UPDATE  => intBscan1Update,
    TDO     => intBscan1Tdo
  );

  iBUFGTCK : BUFG
  port map (
    O => intBufgTck, -- 1-bit output: Clock output
    I => intBscan1Tck -- 1-bit input: Clock input
  );

  iJtagToSpiFlashProgrammer : JtagToSpiFlashProgrammer
  port map
  (
    inBscanDrck           => intBufgTck,
    inBscanSel            => intBscan1Sel,
    inBscanCapture        => intBscan1Capture,
    inBscanShift          => intBscan1Shift,
    inBscanUpdate         => intBscan1Update,
    inBscanTdi            => intBscan1Tdi,
    outBscanTdo           => intBscan1Tdo,
    outSFPReset_EnableB   => intSFPReset_EnableB,
    outSFPCheckIdOnly     => intSFPCheckIdOnly,
    outSFPVerifyOnly      => intSFPVerifyOnly,
    outSFPData32          => intSFPData32,
    outSFPDataWriteEnable => intSFPDataWriteEnable,
    inSFPReady_BusyB      => intSFPReady_BusyB,
    inSFPDone             => intSFPDone,
    inSFPError            => intSFPError,
    inSFPErrorIdcode      => intSFPErrorIdcode,
    inSFPErrorErase       => intSFPErrorErase,
    inSFPErrorProgram     => intSFPErrorProgram,
    inSFPErrorTimeOut     => intSFPErrorTimeOut,
    inSFPErrorCrc         => intSFPErrorCrc,
    inSFPStarted          => intSFPStarted,
    inSFPInitializeOK     => intSFPInitializeOK,
    inSFPCheckIdOK        => intSFPCheckIdOK,
    inSFPEraseSwitchWordOK=> intSFPEraseSwitchWordOK,
    inSFPEraseOK          => intSFPEraseOK,
    inSFPProgramOK        => intSFPProgramOK,
    inSFPVerifyOK         => intSFPVerifyOK,
    inSFPProgramSwitchWordOK=> intSFPProgramSwitchWordOK
  );

  iSpiFlashProgrammer: SpiFlashProgrammer
  port map
  (
    inClk                 => intBufgTck,
    inReset_EnableB       => intSFPReset_EnableB,
    inCheckIdOnly         => intSFPCheckIdOnly,
    inVerifyOnly          => intSFPVerifyOnly,
    inData32              => intSFPData32,
    inDataWriteEnable     => intSFPDataWriteEnable,
    outReady_BusyB        => intSFPReady_BusyB,
    outDone               => intSFPDone,
    outError              => intSFPError,
    outErrorIdcode        => intSFPErrorIdcode,
    outErrorErase         => intSFPErrorErase,
    outErrorProgram       => intSFPErrorProgram,
    outErrorTimeOut       => intSFPErrorTimeOut,
    outErrorCrc           => intSFPErrorCrc,
    outStarted            => intSFPStarted,
    outInitializeOK       => intSFPInitializeOK,
    outCheckIdOK          => intSFPCheckIdOK,
    outEraseSwitchWordOK  => intSFPEraseSwitchWordOK,
    outEraseOK            => intSFPEraseOK,
    outProgramOK          => intSFPProgramOK,
    outVerifyOK           => intSFPVerifyOK,
    outProgramSwitchWordOK=> intSFPProgramSwitchWordOK,
    outSSDReset_EnableB   => intSFPSSDReset_EnableB,
    outSSDStartTransfer   => intSFPSSDStartTransfer,
    inSSDTransferDone     => intSFPSSDTransferDone,
    outSSDData8Send       => intSFPSSDData8Send,
    inSSDData8Receive     => intSFPSSDData8Receive
  );

  iBscan2 : BSCANE2
  generic map (
    JTAG_CHAIN => 2
  )
  port map (
    CAPTURE => intBscan2Capture,
    DRCK    => intBscan2Drck,
    RESET   => intBscan2Reset,
    SEL     => intBscan2Sel,
    SHIFT   => intBscan2Shift,
    TCK     => intBscan2Tck,
    TDI     => intBscan2Tdi,
    UPDATE  => intBscan2Update,
    TDO     => intBscan2Tdo
  );

  iJtagToSpiFlashReader : JtagToSpiFlashReader
  port map
  (
    inBscanTck            => intBufgTck,
    inBscanSel            => intBscan2Sel,
    inBscanCapture        => intBscan2Capture,
    inBscanShift          => intBscan2Shift,
    inBscanUpdate         => intBscan2Update,
    inBscanTdi            => intBscan2Tdi,
    outBscanTdo           => intBscan2Tdo,
    outSFRReset_EnableB   => intSFRReset_EnableB,
    outSFRStartAddr32     => intSFRStartAddr32,
    outSFRWordCount32     => intSFRWordCount32,
    inSFRData32           => intSFRData32,
    inSFRDataReady        => intSFRDataReady,
    outSFRDataAck         => intSFRDataAck,
    inSFRDone             => intSFRDone
  );

  iSpiFlashReader : SpiFlashReader
  port map (
    inClk               => intBufgTck,
    inReset_EnableB     => intSFRReset_EnableB,
    inReadStartAddr32   => intSFRStartAddr32,
    inReadWordCount32   => intSFRWordCount32,
    outReadData32       => intSFRData32,
    outReadDataReady    => intSFRDataReady,
    inReadDataAck       => intSFRDataAck,
    outReadDone         => intSFRDone,
    outSSDReset_EnableB => intSFRSSDReset_EnableB,
    outSSDStartTransfer => intSFRSSDStartTransfer,
    inSSDTransferDone   => intSFRSSDTransferDone,
    outSSDData8Send     => intSFRSSDData8Send,
    inSSDData8Receive   => intSFRSSDData8Receive
  );

  iMuxToSpiSerDes : MuxToSpiSerDes
  port map
  (
    inMuxSelect           => intBscan1Sel,
    inPort0Reset_EnableB  => intSFRSSDReset_EnableB,
    inPort0StartTransfer  => intSFRSSDStartTransfer,
    outPort0TransferDone  => intSFRSSDTransferDone,
    inPort0Data8Send      => intSFRSSDData8Send,
    outPort0Data8Receive  => intSFRSSDData8Receive,
    inPort1Reset_EnableB  => intSFPSSDReset_EnableB,
    inPort1StartTransfer  => intSFPSSDStartTransfer,
    outPort1TransferDone  => intSFPSSDTransferDone,
    inPort1Data8Send      => intSFPSSDData8Send,
    outPort1Data8Receive  => intSFPSSDData8Receive,
    outPortYReset_EnableB => intSSDReset_EnableB,
    outPortYStartTransfer => intSSDStartTransfer,
    inPortYTransferDone   => intSSDTransferDone,
    outPortYData8Send     => intSSDData8Send,
    inPortYData8Receive   => intSSDData8Receive
  );

  iSpiSerDes: SpiSerDes port map
  (
    inClk           => intBufgTck,
    inReset_EnableB => intSSDReset_EnableB,
    inStartTransfer => intSSDStartTransfer,
    outTransferDone => intSSDTransferDone,
    inData8Send     => intSSDData8Send,
    outData8Receive => intSSDData8Receive,
    outSpiCsB       => outSpiCsB,
    outSpiClk       => intSpiClk,
    outSpiMosi      => outSpiMosi,
    inSpiMiso       => inSpiMiso
  );

  STARTUPE2_inst : STARTUPE2
  port map (
    CLK => '0',
    GSR => '0', -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
    GTS => '0', -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
    KEYCLEARB => '1',
    PACK => '1', -- 1-bit input: PROGRAM acknowledge input
    USRCCLKO => intSpiClk, -- 1-bit input: User CCLK input
    USRCCLKTS => '0',
    USRDONEO => '1',
    USRDONETS => '1'
  );

  -- Components for demo design to distinguish configuration
  IBUFGDS_inst : IBUFGDS
  generic map (
    DIFF_TERM => FALSE, -- Differential Termination
    IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
    IOSTANDARD => "LVDS")
  port map (
    O   => isysclk, -- Clock buffer output
    I   => SYSCLK_P, -- Diff_p clock buffer input (connect directly to top-level port)
    IB  => SYSCLK_N -- Diff_n clock buffer input (connect directly to top-level port)
  );

  BUFG_inst : BUFG
  port map (
    O => sysclk, -- 1-bit output: Clock output
    I => isysclk -- 1-bit input: Clock input
  );

  iBlinker  : blinker
  port map
  (
    inClk   => sysclk,
    outLED  => intBlinker
  );

  -- Assign outputs
  outLED(0) <= intSFPReady_BusyB;
  outLED(1) <= intSFPDone;
  outLED(2) <= intSFPError;
  outLED(3) <= intSFPCheckIdOK;
  outLED(4) <= intSFPEraseOK;
  outLED(5) <= intSFPProgramOK;
  outLED(6) <= intSFPVerifyOK;
  outLED(7) <= intBlinker;

  outSpiWpB   <= intSFPCheckIdOK;
  outSpiHoldB <= '1';

end architecture behavioral;
