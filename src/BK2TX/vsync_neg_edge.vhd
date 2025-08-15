library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;

entity vsync_neg_edge is 
generic (DLY_CY : integer := 3);
port 
(
  vsync_async : in std_logic ; --register out 
  nRST        : in std_logic ;
  clk         : in std_logic ; 
  vsync_neg   : out std_logic;  
  vsync_synced: out std_logic 
);
end vsync_neg_edge;

architecture beha of vsync_neg_edge is 
signal dly_vsync        : std_logic := '0';
signal vsync_synced_buf : std_logic := '0';
component vsync_cross is
generic (DLY_CY : integer := 3);
port 
(
  vsync_async : in std_logic ; 
  nRST        : in std_logic ;
  clk         : in std_logic ;  
  vsync_synced: out std_logic 
);
end component ;
begin 

vcrs2_i: vsync_cross  
    generic map(DLY_CY =>5 )
    port map
    (
      vsync_async  => vsync_async ,
      nRST         => nRST        ,
      clk          => clk       ,
      vsync_synced => vsync_synced_buf
    ); 
    vsync_synced <= vsync_synced_buf;
   process(nRST,clk)
   begin 
    if nRST = '0'    then 
        dly_vsync <= '0';
        vsync_neg <= '0';
    elsif rising_edge(clk) then 
        dly_vsync <= vsync_synced_buf;
        if dly_vsync = '1' and vsync_synced_buf ='0' then --falling 
           vsync_neg <= '1';
        else 
           vsync_neg<= '0';
        end if;
    end if;   
   end process;

end beha; 
