library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity SpiFlashProgrammer_TB is
    end SpiFlashProgrammer_TB;

architecture behavioral of SpiFlashProgrammer_TB is
    signal  inClk               : std_logic := '1';
    signal  inCheckIdOnly       : std_logic;
    signal  inVerifyOnly        : std_logic;
    signal  inReset_EnableB     : std_logic;
    signal  outReady_BusyB      : std_logic;
    signal  inData32            : std_logic_vector(31 downto 0);
    signal  inDataWriteEnable   : std_logic;
    signal  outSpiCsB           : std_logic;
    signal  outSpiClk           : std_logic;
    signal  outSpiMosi          : std_logic;
    signal  inSpiMiso           : std_logic;
    signal  outDone             : std_logic;
    signal  outError            : std_logic;
    signal  outErrorIdcode      : std_logic;
    signal  outErrorErase       : std_logic;
    signal  outErrorProgram     : std_logic;
    signal  outErrorTimeOut     : std_logic;
    signal  outErrorCrc         : std_logic;
    signal  outStarted          : std_logic;
    signal  outInitializeOK     : std_logic;
    signal  outCheckIdOK        : std_logic;
    signal  outEraseSwitchWordOK: std_logic;
    signal  outEraseOK          : std_logic;
    signal  outProgramOK        : std_logic;
    signal  outVerifyOK         : std_logic;
    signal  outProgramSwitchWordOK: std_logic;
    signal  outSpiWpB           : std_logic;
    signal  outSpiHoldB         : std_logic := '1';
    signal  spiVcc              : std_logic_vector(31 downto 0) := X"00000CE4";

    signal  intSSDReset_EnableB : std_logic;
    signal  intSSDStartTransfer : std_logic;
    signal  intSSDTransferDone  : std_logic;
    signal  intSSDData8Send     : std_logic_vector(7 downto 0);
    signal  intSSDData8Receive  : std_logic_vector(7 downto 0);


    signal I : integer;
    signal J : integer;

    constant  tClkPeriod        : time := 10 ns;
    constant  tHalfClkPeriod    : time := tClkPeriod / 2;
    constant  tFpgaClkToData    : time := 1 ns;
    constant  tDataToNextClk    : time := 9 ns;
    constant  tStrobe           : time := 9 ns;
    constant  tStrobeToNextClk  : time := 1 ns;
    constant  tPowerup           : time := 1 ms;

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

    component N25Qxxx is
        port
        (
            S         : in std_logic;
            C         : in std_logic;
            HOLD_DQ3  : inout std_logic;
            DQ0       : inout std_logic;
            DQ1       : inout std_logic;
            Vcc       : in std_logic_vector(31 downto 0);
            Vpp_W_DQ2 : inout std_logic
        );
    end component N25Qxxx;


begin

    iSpiFlashProgrammer: SpiFlashProgrammer
    port map
    (
        inClk               => inClk,
        inReset_EnableB     => inReset_EnableB,
        inCheckIdOnly       => inCheckIdOnly,
        inVerifyOnly        => inVerifyOnly,
        inData32            => inData32,
        inDataWriteEnable   => inDataWriteEnable,
        outReady_BusyB      => outReady_BusyB,
        outDone             => outDone,
        outError            => outError,
        outErrorIdcode      => outErrorIdcode,
        outErrorErase       => outErrorErase,
        outErrorProgram     => outErrorProgram,
        outErrorTimeOut     => outErrorTimeOut,
        outErrorCrc         => outErrorCrc,
        outStarted          => outStarted,
        outInitializeOK     => outInitializeOK,
        outCheckIdOK        => outCheckIdOK,
        outEraseSwitchWordOK=> outEraseSwitchWordOK,
        outEraseOK          => outEraseOK,
        outProgramOK        => outProgramOK,
        outVerifyOK         => outVerifyOK,
        outProgramSwitchWordOK=> outProgramSwitchWordOK,
        outSSDReset_EnableB => intSSDReset_EnableB,
        outSSDStartTransfer => intSSDStartTransfer,
        inSSDTransferDone   => intSSDTransferDone,
        outSSDData8Send     => intSSDData8Send,
        inSSDData8Receive   => intSSDData8Receive
    );

    iSpiSerDes: SpiSerDes port map
    (
        inClk           => inClk,
        inReset_EnableB => intSSDReset_EnableB,
        inStartTransfer => intSSDStartTransfer,
        outTransferDone => intSSDTransferDone,
        inData8Send     => intSSDData8Send,
        outData8Receive => intSSDData8Receive,
        outSpiCsB       => outSpiCsB,
        outSpiClk       => outSpiClk,
        outSpiMosi      => outSpiMosi,
        inSpiMiso       => inSpiMiso
    );

    iN25Qxxx : N25Qxxx
    port map
    (
        S         => outSpiCsB,
        C         => outSpiClk,
        HOLD_DQ3  => outSpiHoldB,
        DQ0       => outSpiMosi,
        DQ1       => inSpiMiso,
        Vcc       => spiVcc,
        Vpp_W_DQ2 => outSpiWpB
    );

    inClk <= not inClk after (tHalfClkPeriod);

    stimulus : process
    begin
        inReset_EnableB   <= '1';
        inCheckIdOnly     <= '0';
        inVerifyOnly      <= '0';
        inData32          <= X"00000000";
        inDataWriteEnable <= '0';

    --wait for powerup; -- Need this for real N25Qxxx sim model
    --spiVcc                <= X"00000000";
    --wait for tClkPeriod * 2;
    --spiVcc                <= X"00000CE4";
    --wait for tPowerup;

        wait for tClkPeriod;
        wait for tStrobe;
        assert outDone = '0'  report "SFP Done expected 0" severity note;
        assert outError = '0' report "Error expected 0" severity note;
        wait for tStrobeToNextClk;

    -- CHECK ID Only
        wait for tClkPeriod;
        wait for tHalfClkPeriod;
        inCheckIdOnly   <= '1';
        inReset_EnableB <= '0';
        wait for tHalfClkPeriod;
        wait for tClkPeriod;

        wait for tClkPeriod * 90;
        wait for tFpgaClkToData;
        inReset_EnableB <= '1';
        inCheckIdOnly   <= '0';
        wait for tDataToNextClk;

        wait for tClkPeriod * 10;

    -- VERIFY Only - Partial
        wait for tClkPeriod;
        wait for tHalfClkPeriod;
        inVerifyOnly    <= '1';
        inReset_EnableB <= '0';
        wait for tHalfClkPeriod;
        wait for tClkPeriod;

        wait for tClkPeriod * 500;
        wait for tFpgaClkToData;
        inReset_EnableB <= '1';
        inVerifyOnly    <= '0';
        wait for tDataToNextClk;

        wait for tClkPeriod * 10;

    -- PROGRAM
        wait for tFpgaClkToData;
        inReset_EnableB <= '0';
        wait for tDataToNextClk;

        wait for tClkPeriod * 420;

        for J in 0 to 255 loop
            for I in 0 to 63 loop
                wait for tFpgaClkToData;
                inData32          <= std_logic_vector(to_unsigned(I,32));
                wait for tClkPeriod * 40;
                inDataWriteEnable <= '1';
                wait for tClkPeriod;
                inDataWriteEnable <= '0';
                wait for tDataToNextClk;
            end loop;

            wait for tClkPeriod * 60;
        end loop;

        wait for tFpgaClkToData;
        inReset_EnableB       <= '1';
        wait for tDataToNextClk;


        wait;

    end process stimulus;

end architecture behavioral;

