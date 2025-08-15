--    File Name:  rcvr.vhd
--      Version:  1.1
--         Date:  January 22, 2000
--        Model:  Uart Chip
-- Dependencies:  uart.vhd
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
--

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

-- use work.PCK_CRC32_D8.all;

entity rcvr is
generic
(
    BAUD       : std_logic_vector(15 downto 0):=X"003D"
--2.5M       div_cnt=49   50x8ns=400ns 1bit
--2M         div_cnt=61  --->3D
--115200bps div_cnt=1084  --->43C
--9600bps   div_cnt=13019
-- BAUD= 1/(baud rate)/8  X 10e9 -1, sysclk is 125M
);
port (
    nRST          : in std_logic ;
    sysclk        : in std_logic ;  -----, sysclk is 125M

    rxd           : in std_logic ;
	dout          : out std_logic_vector (7 downto 0) ;
	data_ready    : out std_logic;
	uart_src      : out std_logic
) ;
end rcvr ;

architecture v1 of rcvr is
signal rxd0b         : std_logic ;
signal rxd0         : std_logic ;
signal rxd1         : std_logic ;
signal rxd2         : std_logic ;
signal counter_en   : std_logic ;
signal bits_rcvd    : unsigned (3 downto 0) ;
signal rx_buf       : std_logic_vector (7 downto 0) ;
signal div_cnt      : std_logic_vector(15 downto 0);   --125MHz to 115200*16.  68 times divider
signal bit_rcv_over    : std_logic ;
---constant BAUD       : std_logic_vector(15 downto 0):=X"003D";  ---only change here ----
--2.5M       div_cnt=49   50x8ns=400ns 1bit
--115200bps div_cnt=1084
--9600bps   div_cnt=13019
 -- BAUD= 1/(baud rate)/8  X 10e9 -1
type state is (idle,rx_start,rx_data,rx_stop,rx_wait);
signal pstate: state := idle;

begin

process (nRST,sysclk)
begin
	if nRST = '0' then
		rxd1 <= '1' ;
		rxd2 <= '1' ;
		rxd0b <= '1';
		rxd0  <= '1';
		
		bit_rcv_over <= '0';
		div_cnt <= (others => '0');
	elsif rising_edge(sysclk) then

        -- if div_cnt = BAUD then
			-- bit_rcv_over <= '1';
		-- elsif counter_en='1' then
			-- bit_rcv_over <= '0';
		-- end if;
        if div_cnt = BAUD-1 then
			bit_rcv_over <= '1';
		else---if counter_en='1' then
			bit_rcv_over <= '0';
		end if;


        if div_cnt = BAUD or counter_en='0'then
			div_cnt <= (others => '0');
		elsif counter_en='1' then
			div_cnt <= div_cnt + '1';
		end if;


		rxd2 <= rxd1 ;
		rxd1 <= rxd0 ;
		rxd0 <= rxd0b ;
		rxd0b <= rxd ;
	end if ;
end process ;


process (nRST,sysclk)
begin
	if nRST = '0' then
		data_ready <= '0';
		rx_buf <= (others => '0');
		pstate <= idle;
		uart_src <= '0';
		dout <= (others => '0');
        counter_en<='0';
	elsif rising_edge(sysclk) then

    case pstate is
        when idle =>
           bits_rcvd <= (others => '0');
            data_ready <= '0';
            if rxd1 = '0' and rxd2 = '1' then
                pstate <= rx_start;
				uart_src <= '1';
                counter_en<='1';
            else
                pstate <= idle;
                counter_en<='0';
            end if;

        when rx_start =>
            if bit_rcv_over = '1' then
                pstate <= rx_data;
            else
                pstate <= rx_start;
            end if;

        when rx_data =>
            if div_cnt = '0'&BAUD(15 downto 1) then
                -- rx_buf <= rxd&rx_buf(7 downto 1);
                rx_buf <= rxd0&rx_buf(7 downto 1);
            end if;
            if bit_rcv_over = '1' then
                if bits_rcvd = 7 then
                    pstate <= rx_stop;
                else
                    pstate <= rx_data;
                end if;
                 bits_rcvd <= bits_rcvd + '1';
            else
                pstate <= rx_data;
            end if;

         when rx_stop =>
            if div_cnt = '0'&BAUD(15 downto 1) then
                dout <= rx_buf;
                data_ready <= '1';
                pstate <= idle;
            else
                data_ready <= '0';
                pstate <= rx_stop;
            end if;


            -- if bit_rcv_over = '1' then
                -- --pstate <= rx_wait;
                -- pstate <= idle;
            -- else
                -- pstate <= rx_stop;
            -- end if;

        when rx_wait =>
            data_ready <= '0';
            if bit_rcv_over = '1' then
                pstate <= idle;
            else
                pstate <= rx_wait;
            end if;

        when others => null;

    end case;

   end if ;
end process ;


end ;




