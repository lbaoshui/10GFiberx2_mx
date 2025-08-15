library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----use work.const_def_pack.all;

entity vsync_cross is
generic (DLY_CY : integer := 3);
port 
(
  vsync_async : in std_logic ; 
  nRST        : in std_logic ;
  clk         : in std_logic ;  
  vsync_synced: out std_logic 
);
end vsync_cross ;

architecture beha of vsync_cross is
 
signal vsync_buf_sys        : std_logic_vector(DLY_CY-1 downto 0):=(others=>'0');
signal vsync_final          : std_logic :='0';

attribute syn_keep : boolean;
attribute syn_srlstyle : string;
attribute syn_keep of vsync_buf_sys : signal is true; 
--2021
attribute altera_attribute : string;
attribute altera_attribute of vsync_buf_sys : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON";


begin 

    process(nRST,clk)
    begin
        if nRST = '0' then
            vsync_buf_sys <= (OTHERS=>'0');
            vsync_final   <= '0';
            
        elsif rising_edge(clk) then
            vsync_buf_sys <= vsync_buf_sys(DLY_CY-2 downto 0) & vsync_async;
            vsync_final   <= vsync_buf_sys(DLY_CY-1);  
        end if;
    end process;
     
    vsync_synced <= vsync_final;

end beha;