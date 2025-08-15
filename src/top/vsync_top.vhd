library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vsync_top is 
port 
(
    sysclk              : in  std_logic; 
    nRST_sys            : in  std_logic;
	vsync_i        		: in std_logic;
    vsync   	        : out std_logic  
);
end vsync_top;

architecture behaviour of vsync_top is 
 
constant VYSNC_TIME_60HZ : std_logic_vector(23 downto 0):= x"1FCA05";

signal cnt : std_logic_vector(23 downto 0); 

begin 

process(nRST_sys,sysclk) 
begin
    if nRST_sys = '0' then
        cnt <= (others=>'0');
    elsif rising_edge (sysclk) then
        if cnt = VYSNC_TIME_60HZ then
            cnt <= (others=>'0');
        else
            cnt <= cnt + '1';
        end if;
        
        if cnt >= (VYSNC_TIME_60HZ - 10) then
			vsync <= '1';
        else
			vsync <= '0';
        end if;
    end if;
end process;

end; 