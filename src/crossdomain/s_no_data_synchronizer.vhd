library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--use work.const_def_pack.all;

--only for many bits that has no relation 

entity s_no_data_synchronizer is
generic (
    D_W    : integer := 2   ;
    DLY_CY : integer := 3);
port 
(
  data_in     : in std_logic_vector(D_W-1 downto 0) ; 
  nRST        : in std_logic ;
  clk         : in std_logic ; 
  data_synced : out std_logic_vector(D_W-1 downto 0) 
);
end s_no_data_synchronizer ;

architecture beha of s_no_data_synchronizer is
 
signal data_buf_sys        : std_logic_vector(D_W*DLY_CY-1 downto 0):=(others=>'0');
signal data_final          : std_logic_vector(D_W-1 downto 0) :=(others=>'0');
 
attribute syn_keep : boolean;
attribute syn_srlstyle : string;
attribute syn_keep of data_buf_sys : signal is true; 
--2021
attribute altera_attribute : string;
attribute altera_attribute of data_buf_sys : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;

 
begin 

    process(nRST,clk)
    begin
        if nRST = '0' then
            data_buf_sys <= (OTHERS=>'0');
            data_final   <= (OTHERS=>'0');
        elsif rising_edge(clk) then
            data_buf_sys <= data_buf_sys((DLY_CY-1)*D_W-1 downto 0) & data_in;
            data_final   <= data_buf_sys(DLY_CY*D_W-1 downto (DLY_CY-1)*D_W);
        end if;
    end process;
    
    data_synced <= data_final;

end beha;