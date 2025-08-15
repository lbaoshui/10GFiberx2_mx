--    File Name:  uart.vhd
--      Version:  1.1
--         Date:  January 22, 2000
--        Model:  Uart Chip
-- Dependencies:  txmit.hd, rcvr.vhd
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


library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity uart_top is
generic
(
    BAUD_DIV       : std_logic_vector(15 downto 0):=X"003D"
--2.5M       div_cnt=49   50x8ns=400ns 1bit
--2M         div_cnt=61
--115200bps div_cnt=1084
--9600bps   div_cnt=13019
-- BAUD= 1/(baud rate)/8  X 10e9 -1 , sysclk is 125M

);

PORT (
    nRST : in std_logic; ---ACTIVE LOW
    sysclk : in std_logic;-----, sysclk is 125M

    ---local interface
    uart_busy    : out std_logic;    ---tx busy
    txd_en       : in std_logic;     ---trans one byte en
    txd_data     : in std_logic_vector(7 downto 0);  ---trans one byte

    rxd_data     : out std_logic_vector(7 downto 0);  ---rx one byte
    rxd_en       : out std_logic;   ---rx one byte enable
    ---uart: 2 pins of uart
    rxd_top        : in std_logic;
    txd_top        : out std_logic

);
end uart_top;

architecture v1 of uart_top is
signal tbre :std_logic;
signal tsre :std_logic;
signal parity_error :std_logic;
signal framing_error :std_logic;
signal uart_src     :  std_logic;
signal wr_uart_en  :  std_logic;
signal din :std_logic_vector(7 downto 0);
signal dout :std_logic_vector(7 downto 0);
signal rxd  :  std_logic;
signal txd  :  std_logic;
signal data_ready  :  std_logic;
component txmit
generic
(
    BAUD       : std_logic_vector(15 downto 0):=X"003D"
);
port (
   nRST : in std_logic;
   sysclk : in std_logic;

   uart_busy: out std_logic;
   wr_uart_en : in std_logic;
   din : in std_logic_vector(7 downto 0);
   txd: out std_logic
   );
end component ;

component rcvr
generic
(
    BAUD       : std_logic_vector(15 downto 0):=X"003D"
);
port (
    nRST          : in std_logic ;
    sysclk        : in std_logic ;  -----, sysclk is 125M

    rxd           : in std_logic ;
  dout          : out std_logic_vector (7 downto 0) ;
  data_ready    : out std_logic;
  uart_src      : out std_logic
);
end component ;

begin
    wr_uart_en  <=  txd_en;
    din         <=  txd_data;
    rxd_data    <=  dout;
    rxd_en      <=  data_ready;
    rxd         <=  rxd_top;
    txd_top     <=  txd;
u1 : txmit
generic map
(
  BAUD => BAUD_DIV
)
PORT MAP
(
   nRST => nRST,
   sysclk => sysclk,

   uart_busy   => uart_busy,
   wr_uart_en => wr_uart_en,
   din => din,
   txd => txd
);

u2 : rcvr
 generic map
(
  BAUD => BAUD_DIV
)
PORT MAP
(
  nRST => nRST,
  sysclk => sysclk,

  rxd => rxd,
  data_ready => data_ready,
	uart_src     => uart_src,
  dout => dout
) ;





end v1 ;



