library IEEE;
use IEEE.std_logic_1164.all;
--PCK_version for 032 FPGA .
package PCK_version_FPGA_def is

constant     PCK_CONS_VER_HIGH            : std_logic_vector  :=X"0A";
constant     PCK_CONS_VER_LOW             : std_logic_vector  :=X"12";
constant     PCK_PCB_M_VER                : std_logic_vector  :=x"03"; --NOT USED 
constant     PCK_PCB_S_VER                : std_logic_vector  :=X"00"; --NOT USED 

--0: 027
--1: 032 
constant      FPGA032_EN             : integer := 1;   --20221122 wangac 

-- 0: MT Flash
-- 1: MX Flash
constant	MX_FLASH_EN				: integer := 1;

end PCK_version_FPGA_def;

library IEEE;
use IEEE.std_logic_1164.all;

package body PCK_version_FPGA_def is


end PCK_version_FPGA_def;