library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Z8_boardout_tb is
generic
(
    HSSI_NUM : integer := 2
);
end Z8_boardout_tb;

architecture behaviour of Z8_boardout_tb is

component Z8_boardout is
generic
(
    HSSI_NUM : integer := 2
);
port 
(
    CLKUSR                      : in std_logic;
    clkin_156M                  : in std_logic;
    
    rx_serial_data              : in std_logic_vector(HSSI_NUM-1 downto 0)  := (others => 'X');
    
    tx_serial_sfpdata           : out std_logic_vector(HSSI_NUM-1 downto 0);                      
    rx_serial_sfpdata           : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X')
    
);
end component;

signal CLKUSR                      : std_logic := '1';
signal clkin_156M                  : std_logic := '1';
signal rx_serial_data              : std_logic_vector(HSSI_NUM-1 downto 0)  := (others => 'X');
signal tx_serial_sfpdata           : std_logic_vector(HSSI_NUM-1 downto 0);                      
signal rx_serial_sfpdata           : std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');

begin

CLKUSR     <= not CLKUSR after 5 ns;
clkin_156M <= not clkin_156M after 3.2 ns;

Z8_boardout_inst : Z8_boardout
generic map
(
    HSSI_NUM => HSSI_NUM
)
port map
(
    CLKUSR                      => CLKUSR, 
    clkin_156M                  => clkin_156M,

    rx_serial_data              => rx_serial_data,

    tx_serial_sfpdata           => tx_serial_sfpdata,  
    rx_serial_sfpdata           => tx_serial_sfpdata
    
);

end;
