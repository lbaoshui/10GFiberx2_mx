library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity uart is
generic(
	BAUD						: std_logic_vector(7 downto 0):= x"20"
);
port(
	nRST						: in  std_logic;
	sysclk						: in  std_logic;
	
	uart_rxd					: in  std_logic;
	uart_txd					: out std_logic;
	--rx
	frame_ss					: out std_logic;
	rx_data_vld					: out std_logic;
	rx_data						: out std_logic_vector(7 downto 0);
	--tx
	busy_en						: out std_logic;
	tx_data_vld					: in  std_logic;
	tx_data						: in  std_logic_vector(7 downto 0)
);
end entity;

architecture behav of uart is


component uart_rx is
generic(
	BAUD						: std_logic_vector(7 downto 0):= x"20"
);
port(
	nRST						: in  std_logic;
	sysclk						: in  std_logic;
	
	uart_rxd					: in  std_logic;
	
	frame_ss					: out std_logic;
	rx_data_vld					: out std_logic;
	rx_data						: out std_logic_vector(7 downto 0)
);
end component;


component uart_tx is
generic(
	BAUD						: std_logic_vector(7 downto 0):= x"20"
);
port(
	nRST						: in  std_logic;
	sysclk						: in  std_logic;
	
	uart_txd					: out std_logic;
	
	busy_en						: out std_logic;
	tx_data_vld					: in  std_logic;
	tx_data						: in  std_logic_vector(7 downto 0)
);
end component;




begin


uart_rx_inst: uart_rx
generic map(
	BAUD						=> BAUD
)                        
port map(                     
	nRST						=> nRST			,
	sysclk						=> sysclk       ,
	                      
	uart_rxd					=> uart_rxd     ,
	               
	frame_ss					=> frame_ss		,
	rx_data_vld					=> rx_data_vld	,
	rx_data						=> rx_data		
);


uart_tx_inst: uart_tx
generic map(
	BAUD						=> BAUD
)                             
port map(                      
	nRST						=> nRST			,
	sysclk						=> sysclk		,
	                          
	uart_txd					=> uart_txd	    ,
	                          
	busy_en						=> busy_en		,
	tx_data_vld					=> tx_data_vld	,
	tx_data						=> tx_data		
);




end behav ;