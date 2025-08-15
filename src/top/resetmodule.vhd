library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity resetmodule is
generic
(
    BKHSSI_NUM : integer;
    FIBER_NUM : integer
);
port
(
    sysclk              : in std_logic;
    tx_clk              : in std_logic;
    rx_clk0             : in std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_clk1             : in std_logic_vector(FIBER_NUM-1 downto 0);
    pll_lock            : in std_logic;
    
    conv_clk            : in  std_logic ;  
    nRST_conv           : out std_logic;

    nRST_sys            : out std_logic;
    RST_sys             : out std_logic;
    nRST_rxclk0         : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    nRST_rxclk1         : out std_logic_vector(FIBER_NUM-1 downto 0);
    nRST_txclk          : out std_logic
);
end resetmodule;

architecture behaviour of resetmodule is

signal rst_cnt                  : std_logic_vector(9 downto 0);
signal nRST_i                   : std_logic := '0';

signal nRST_i_d1_txclk          : std_logic := '0';
signal nRST_i_d2_txclk          : std_logic := '0';
signal nRST_i_d1_rxclk0         : std_logic_vector(BKHSSI_NUM-1 downto 0) := (others=>'0');
signal nRST_i_d2_rxclk0         : std_logic_vector(BKHSSI_NUM-1 downto 0) := (others=>'0');
signal nRST_i_d1_rxclk1         : std_logic_vector(FIBER_NUM-1 downto 0) := (others=>'0');
signal nRST_i_d2_rxclk1         : std_logic_vector(FIBER_NUM-1 downto 0) := (others=>'0');


begin

process(sysclk,pll_lock)
begin
    if( pll_lock = '0' )then
        rst_cnt <= (others=>'0');
    elsif rising_edge(sysclk) then
        if rst_cnt(9) = '0' then
            rst_cnt <= rst_cnt + '1';
        end if;
    end if;
end process;

process(sysclk,pll_lock)
begin
    if( pll_lock = '0' )then
        nRST_i <= '0';
    elsif rising_edge(sysclk) then
        if rst_cnt < X"00FF" then
            nRST_i <= '0';
        else
            nRST_i <= '1';
        end if;
   end if;
end process;

nRST_conv <= nRST_i;

nRST_sys <= nRST_i;
RST_sys <= not nRST_i;

process(tx_clk)
begin
    if rising_edge(tx_clk) then
        nRST_i_d1_txclk <= nRST_i;
        nRST_i_d2_txclk <= nRST_i_d1_txclk;
        nRST_txclk <= nRST_i_d2_txclk;
    end if;
end process;

RX_CLK_RESET_GEN : for i in 0 to BKHSSI_NUM-1 generate
    process(rx_clk0(i))
    begin
        if rising_edge(rx_clk0(i)) then
            nRST_i_d1_rxclk0(i) <= nRST_i;
            nRST_i_d2_rxclk0(i) <= nRST_i_d1_rxclk0(i);
            nRST_rxclk0(i) <= nRST_i_d2_rxclk0(i);
        end if;
    end process;
end generate RX_CLK_RESET_GEN;

FRX_CLK_RESET_GEN : for i in 0 to FIBER_NUM-1 generate
    process(rx_clk1(i))
    begin
        if rising_edge(rx_clk1(i)) then
            nRST_i_d1_rxclk1(i) <= nRST_i;
            nRST_i_d2_rxclk1(i) <= nRST_i_d1_rxclk1(i);
            nRST_rxclk1(i) <= nRST_i_d2_rxclk1(i);
        end if;
    end process;

end generate FRX_CLK_RESET_GEN;

end;

