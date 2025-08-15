library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity uart_tx is
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
end entity;

architecture behav of uart_tx is

signal div_cnt					: std_logic_vector(7 downto 0);
signal div_pos_en				: std_logic;
signal div_neg_en				: std_logic;
signal div_cnt_clr				: std_logic;

signal bit_cnt					: std_logic_vector(2 downto 0);
signal data_buf					: std_logic_vector(7 downto 0);

type state is(
	idle,
	send_start,
	send_data,
	send_stop
);
signal pstate					: state:= idle;


begin


process(sysclk,nRST)
begin
	if nRST = '0' then
		div_cnt <= (others => '0');
		div_pos_en <= '0';
		div_neg_en <= '0';
	
	elsif rising_edge(sysclk) then
		if div_cnt_clr = '1' then
			div_cnt <= (others => '0');
		else
			if div_cnt >= BAUD - '1' then
				div_cnt <= (others => '0');
			else
				div_cnt <= div_cnt + '1';
			end if;
		end if;
		
		if div_cnt = BAUD - 2 then
			div_pos_en <= '1';
		else
			div_pos_en <= '0';
		end if;
		
		if div_cnt = ('0'&BAUD(7 downto 1)) - 2 then
			div_neg_en <= '1';
		else
			div_neg_en <= '0';
		end if;

	end if;
end process;


process(sysclk,nRST)
begin
	if nRST = '0' then
		pstate <= idle;
		div_cnt_clr <= '0';
		bit_cnt <= (others => '0');
		data_buf <= (others => '1');
		
		busy_en <= '1';
		uart_txd <= '1';

	elsif rising_edge(sysclk) then
		case pstate is
			when idle =>
					if tx_data_vld = '1' then
						pstate <= send_start;
						div_cnt_clr <= '0';
						busy_en <= '1';
					else
						pstate <= idle;
						div_cnt_clr <= '1';
						busy_en <= '0';
					end if;
					
					bit_cnt <= (others => '0');
					data_buf <= tx_data;
					uart_txd <= '1';

			
			when send_start =>
					if div_pos_en = '1' then
						pstate <= send_data;
					else
						pstate <= send_start;
					end if;
					uart_txd <= '0';
					
			
			when send_data =>
					if div_pos_en = '1' then
						if bit_cnt = 7 then
							pstate <= send_stop;
						else
							pstate <= send_data;
						end if;
						bit_cnt <= bit_cnt + '1';
						data_buf <= '0'&data_buf(7 downto 1);
					else
						pstate <= send_data;
					end if;
					uart_txd <= data_buf(0);
			
			
			when send_stop =>
					if div_pos_en = '1' then
						pstate <= idle;
					else
						pstate <= send_stop;
					end if;
					uart_txd <= '1';
			
			
			when others =>
					pstate <= idle;
					
			
		end case;	
	end if;
end process;


end behav ;