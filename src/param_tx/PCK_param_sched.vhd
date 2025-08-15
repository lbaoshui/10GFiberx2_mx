
library IEEE;
use IEEE.std_logic_1164.all;

package PCK_param_sched is

constant FT_FORWARD_PARAM : std_logic_vector(7 downto 0):= X"CC" ;
constant FT_RT_PARAM      : std_logic_vector(7 downto 0):= X"8A" ;
constant FT_RT_BRIGHT     : std_logic_vector(7 downto 0):= X"44" ;
constant FT_RT_GAMUT      : std_logic_vector(7 downto 0):= X"4B" ;
constant FT_RT_SHUTTER    : std_logic_vector(7 downto 0):= X"4C" ;
--rev card frame type 
constant RFT_DETECT_RCV    : std_logic_vector(7 downto 0):= X"07" ;
constant FR_ABORT_DETECT_RCV    : std_logic_vector(7 downto 0):= X"51" ;

-- constant RFT_DETECT_RCV : std_logic_vector(7 downto 0) := X"07";
end  PCK_param_sched;


library IEEE;
use IEEE.std_logic_1164.all;

package body PCK_param_sched is
 

end PCK_param_sched;