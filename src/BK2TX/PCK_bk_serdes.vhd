                               
-----------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

package PCK_bk_serdes is

constant FRM_VID             : std_logic_vector(   8-1 downto 0) := X"00"; 
constant FRM_VSYNC           : std_logic_vector(   8-1 downto 0) := X"01"; 
constant FRM_AUD             : std_logic_vector(   8-1 downto 0) := X"02";  
constant FRM_RTPARA          : std_logic_vector(   8-1 downto 0) := X"03";  
constant COLOR8_DEPTH        : std_logic_vector(1 downto 0) := "00";
constant COLOR10_DEPTH       : std_logic_vector(1 downto 0) := "01";
constant COLOR12_DEPTH       : std_logic_vector(1 downto 0) := "10";

   
constant XGMII_ECP : std_logic_vector(7 downto 0)  := X"FD";
constant XGMII_IDLE : std_logic_vector(7 downto 0) := X"07";
constant XGMII_SCP : std_logic_vector(7 downto 0)  := X"FB";

-------------
constant SUBCARD_1G_FIBER : std_logic_vector(7 downto 0)  := X"80";
constant SUBCARD_5G_TX    : std_logic_vector(7 downto 0)  := X"83";
constant SUBCARD_FIBERx4  : std_logic_vector(7 downto 0)  := X"87";
constant SUBCARD_5G_FIBERx4  : std_logic_vector(7 downto 0)  := X"85";
constant SUBCARD_FIBERx2_to_ETHx8orx4  : std_logic_vector(7 downto 0)  := X"86";
---------------
constant TX_SPEED_1G    : std_logic_vector(2 downto 0)  :=  "000";
constant TX_SPEED_5G    : std_logic_vector(2 downto 0)  :=  "001";
constant TX_SPEED_2P5G  : std_logic_vector(2 downto 0)  :=  "010";
constant TX_SPEED_10G   : std_logic_vector(2 downto 0)  :=  "011";

constant ALTERA_FPGA           : std_logic_vector(7 downto 0) := X"01";
constant ALTERA_027            : std_logic_vector(7 downto 0) := X"10";
constant ALTERA_032            : std_logic_vector(7 downto 0) := X"11";
----constant FPGA032_EN            : integer := 0;   --20221122 wangac 

   
end  PCK_bk_serdes;


library IEEE;
use IEEE.std_logic_1164.all;

package body PCK_bk_serdes is
 

end PCK_bk_serdes;

