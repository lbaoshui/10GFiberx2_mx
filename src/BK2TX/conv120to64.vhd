library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity conv120to64 is 

generic
(  SERDES_5G_EN      : std_logic;
   ETHPORT_NUM       : integer ; --how many eth port 
   FIBER_NUM         : integer ;
   BKHSSI_NUM        : integer  
);
port 
( 
    
    nRST_txclk       : in  std_logic    ; ---
    txclk_i          : in  std_logic    ; --200M almost 

    vsync_neg_i      : in  std_logic   ;
    
    color_depth_i    : in  std_logic_vector(1 downto 0);
    