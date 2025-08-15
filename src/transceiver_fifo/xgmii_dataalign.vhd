--#######################################################################
--
--  REVISION HISTORY:
--
--  Revision 0.1  2019/09/03  Description: Initial .
--  yxx
--  Copyright (C)   Beijing ColorLight Tech. Inc.
--
--#######################################################################
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xgmii_dataalign is
generic
(
    SIM         : std_logic := '0'
);
port
(
    rx_clk                  : in std_logic;
    rx_parallel_data        : in std_logic_vector(63 downto 0);                     -- rx_parallel_data
    rx_control              : in std_logic_vector(7 downto 0);                      -- rx_datak

    data_c_align            : out std_logic_vector(7 downto 0);
    data_align              : out std_logic_vector(63 downto 0)

);
end xgmii_dataalign ;

architecture beha_top of xgmii_dataalign is
signal align : std_logic;
signal xgmii_rx_c : std_logic_vector(7 downto 0);
signal xgmii_rx_c_d1 : std_logic_vector(7 downto 0);
signal xgmii_rx_d : std_logic_vector(63 downto 0);
signal xgmii_rx_d_d1 : std_logic_vector(63 downto 0);

begin
xgmii_rx_c       <= rx_control;
xgmii_rx_d       <= rx_parallel_data;

process(rx_clk)
begin
if rising_Edge(rx_clk) then
	xgmii_rx_c_d1 <= xgmii_rx_c;
	xgmii_rx_d_d1 <= xgmii_rx_d;
	if xgmii_rx_c = X"01" then
		align <= '0';
	elsif xgmii_rx_c = X"1F" then
		align <= '1';
	end if;
	if align = '0' or (align = '1' and xgmii_rx_c = X"01") then
		data_align   <= xgmii_rx_d_d1;
		data_c_align <= xgmii_rx_c_d1;
	else
		data_align   <= xgmii_rx_d(31 downto 0)&xgmii_rx_d_d1(63 downto 32);
		data_c_align <= xgmii_rx_c( 3 downto 0)&xgmii_rx_c_d1(7 downto 4);
	end if;
end if;
end process;

end;
