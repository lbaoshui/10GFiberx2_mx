--    File Name:  txmit.vhd
--      Version:  1.1
--         Date:  January 22, 2000
--        Model:  Transmitter Chip
--
--      Company:  Xilinx
--
--
--   Disclaimer:  THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY
--                WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY
--                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
--                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
--
--                Copyright (c) 2000 Xilinx, Inc.
--                All rights reserved

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity txmit is
generic
(
    BAUD       : std_logic_vector(15 downto 0):=X"003D"
--2.5M       div_cnt=49   50x8ns=400ns 1bit
--2M         div_cnt=61 --->3D
--115200bps div_cnt=1084 --->43C
--9600bps   div_cnt=13019
-- BAUD= 1/(baud rate)/8  X 10e9 -1, sysclk is 125M
);
port (
    nRST        : in std_logic ;
    sysclk      : in std_logic;

    uart_busy   : out std_logic;
    wr_uart_en  : in std_logic ;
	din         : in std_logic_vector(7 downto 0) ;
	txd         : out std_logic ---to FPGA pin
) ;
end txmit ;

architecture v1 of txmit is
type state is (idle,tx_start_wait,tx_start,tx_data,tx_stop,tx_delay);
signal pstate: state := idle;

signal tx_buf       : std_logic_vector (7 downto 0) ;
signal parity       : std_logic ;

signal bits_sent    : std_logic_vector (3 downto 0) ;

signal div_cnt      : std_logic_vector(15 downto 0);   --125MHz to 115200.  1085times divider
signal clk1x_en     : std_logic;
signal delay_cnt    : std_logic_vector(1 downto 0):=(others => '0');
---constant BAUD       : std_logic_vector(15 downto 0):=X"003D";  ---only change here ----
--2.5M       div_cnt=49   50x8ns=400ns 1bit
--2M         div_cnt=61
--115200bps div_cnt=1084
--9600bps   div_cnt=13019
-- BAUD= 1/(baud rate)/8  X 10e9 -1

begin

fp:process(nRST,sysclk)
begin
    if nRST = '0' then
        div_cnt <= (others => '0');
        clk1x_en <= '0';
    elsif rising_edge(sysclk) then
        if div_cnt = BAUD then
            div_cnt <= (others => '0');
            clk1x_en <= '1';
        else
            div_cnt <= div_cnt + '1';
            clk1x_en <= '0';
        end if;
    end if;
end process;

process (nRST,sysclk)
begin
    if nRST = '0' then
        txd <= '1';
		tx_buf <= (others => '0');
        pstate <= idle;
        uart_busy <= '0';
        delay_cnt <= (others => '0');
        bits_sent <= (others => '0');
   elsif rising_edge(sysclk) then

        case pstate is
            when idle =>
                txd <= '1';
                bits_sent <= (others => '0');

                if wr_uart_en = '1' then
                    uart_busy <= '1';
                    pstate <= tx_start_wait;
                    tx_buf <= din;
                else
                    pstate <= idle;
                    uart_busy <= '0';
                end if;

            when tx_start_wait =>    --wait for the time to align
                txd <= '1';

                if clk1x_en = '1' then
                    pstate <= tx_start;
                else
                    pstate <= tx_start_wait;
                end if;

            when tx_start =>
                if clk1x_en = '1' then
                    txd <= '0';
                    pstate <= tx_data;
                else
                    pstate <= tx_start;
                end if;


            when tx_data =>
                if clk1x_en = '1' then
                    txd <= tx_buf(0);

                    bits_sent <= bits_sent + '1';
                    tx_buf <= '0'&tx_buf(7 downto 1);
                    if bits_sent = 7 then
                        pstate <= tx_stop;
                    else
                        pstate <= tx_data;
                    end if;
                else
                    pstate <= tx_data;
                end if;

            when tx_stop =>
                delay_cnt <= "00";

                if clk1x_en = '1' then
                    txd <= '1';
                    pstate <= tx_delay;
                else
                    pstate <= tx_stop;
                end if;

            when tx_delay =>

                if clk1x_en = '1' then
                    delay_cnt <= delay_cnt + '1';
                end if;

                if delay_cnt > 2 then
                    pstate <= idle;
                    uart_busy <= '0';
                else
                    pstate <= tx_delay;
                end if;

--			if clk1x_en = '1' then
--				pstate <= idle;
--				uart_busy <= '0';
--			else
--				pstate <= tx_delay;
--			end if;



         when others => null;
     end case;

   end if ;
end process ;


end ;




