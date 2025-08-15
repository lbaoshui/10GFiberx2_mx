--#######################################################################
--
--  LOGIC CORE:          PHY_RESET              
--  MODULE NAME:         PHY_RESET()
--  COMPANY:             
--                          
--
--  REVISION HISTORY:  
--
--  Revision 0.1  07/20/2007  Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  this module is to detect video input port and send out display data by giga port, 
--
--  Copyright (C)   Beijing ColorLight Tech. Inc.
--
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity PHY_RESET is
port(
    SYSCLK               : in std_logic;
    nRST                 : in std_logic;
    time_ms_en 			 : out std_logic;
    phy_rsta_done        : out std_logic;
    phy_reseta           : out std_logic

);
end entity;

architecture behav of PHY_RESET is

signal ms_cnt            	   	: std_logic_vector( 19 downto 0);
signal p_rsta_done          	: std_logic := '0';
signal time_2s					: std_logic_vector(11 downto 0);
signal time_ms_en_buf 			: std_logic;


begin
phy_rsta_done <= p_rsta_done;
time_ms_en <= time_ms_en_buf;

process(nRST,SYSCLK)
begin
    if nRST = '0' then
        time_ms_en_buf <= '0';
        ms_cnt <= (others => '0');
    elsif rising_edge(SYSCLK) then
        if( ms_cnt >= x"1E848")then  -- one ms
        	time_ms_en_buf <= '1' ;
            ms_cnt <= (others=>'0');
        else
            time_ms_en_buf <= '0';
            ms_cnt <= ms_cnt + '1';
        end if;
    end if;
end process;

process(nRST,sysclk)
begin
    if( nRST = '0')then
        phy_reseta  <= '0';
        p_rsta_done <= '0';
	    time_2s<=(others=>'0');	
    elsif rising_edge(sysclk) then	
		if(time_2s >= 2000)then
			phy_reseta <='1';
			p_rsta_done <='1';
		elsif (time_ms_en_buf='1') then
			time_2s<=time_2s+'1';
		end if;     
   end if;              
end process; 

end behav;

