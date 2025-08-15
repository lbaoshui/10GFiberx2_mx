library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity uart_rx is
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
end entity;

architecture behav of uart_rx is

signal uart_rxd_buf				: std_logic_vector(3 downto 0);
signal uart_rx_neg				: std_logic;
signal div_cnt					: std_logic_vector(7 downto 0);
signal div_cnt_clr				: std_logic;
signal clk_pos_en				: std_logic;
signal clk_neg_en				: std_logic;

signal bit_cnt					: std_logic_vector(2 downto 0);
signal data_buf					: std_logic_vector(7 downto 0);

type state is(
	idle,
	rcv_start,
	rcv_data,
	rcv_stop
);
signal pstate					: state:= idle;

signal baud_cnt					: std_logic_vector(7 downto 0);
signal bit_en					: std_logic;
signal frame_bit_cnt			: std_logic_vector(5 downto 0);




begin


process(sysclk,nRST)
begin
	if nRST = '0' then
		uart_rxd_buf <= (others => '1');
		uart_rx_neg <= '0';
		
	elsif rising_edge(sysclk) then
		uart_rxd_buf <= uart_rxd_buf(2 downto 0)&uart_rxd;
		
		if uart_rxd_buf(3 downto 2) = "10" then
			uart_rx_neg <= '1';
		else
			uart_rx_neg <= '0';
		end if;	
	
	end if;
end process;


process(sysclk,nRST)
begin
	if nRST = '0' then
		div_cnt <= (others => '0');
		clk_pos_en <= '0';
		clk_neg_en <= '0';

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
			clk_pos_en <= '1';
		else
			clk_pos_en <= '0';
		end if;
		
		if div_cnt = ('0'&BAUD(7 downto 1)) - 2 then
			clk_neg_en <= '1';
		else
			clk_neg_en <= '0';
		end if;
	
	end if;
end process;


process(sysclk,nRST)
begin
	if nRST = '0' then
		pstate <= idle;
		div_cnt_clr <= '1';
		bit_cnt <= (others => '0');
		rx_data_vld <= '0';
	
	elsif rising_edge(sysclk) then
		rx_data <= data_buf;
		case pstate is
			when idle =>
					if uart_rx_neg = '1' then
						pstate <= rcv_start;
						div_cnt_clr <= '0';
					else
						pstate <= idle;
						div_cnt_clr <= '1';
					end if;
					
					bit_cnt <= (others => '0');
					rx_data_vld <= '0';
						
			
			when rcv_start =>
					if clk_pos_en = '1' then
						pstate <= rcv_data;
					else
						pstate <= rcv_start;
					end if;
			
			
			when rcv_data =>
					if clk_pos_en = '1' then
						if bit_cnt = 7 then
							pstate <= rcv_stop;
							rx_data_vld <= '1';
						else
							pstate <= rcv_data;
							rx_data_vld <= '0';
						end if;
						bit_cnt <= bit_cnt + '1';
					else
						pstate <= rcv_data;		
						rx_data_vld <= '0';
					end if;
					
					if clk_neg_en = '1' then
						data_buf <= uart_rxd_buf(3)&data_buf(7 downto 1);
					end if;

			
			when rcv_stop => 
					if clk_neg_en = '1' then
						pstate <= idle;
						div_cnt_clr <= '1';
					else
						pstate <= rcv_stop;
						div_cnt_clr <= '0';
					end if;
					
					rx_data_vld <= '0';
			
			
			when others => 
					pstate <= idle;
					
					
		end case;
	end if;
end process;


process(sysclk,nRST)
begin
	if nRST = '0' then
		frame_ss <= '0';
		baud_cnt <= (others => '0');
		bit_en <= '0';
		frame_bit_cnt <= (others => '1');
	
	elsif rising_edge(sysclk) then
		if uart_rxd_buf(3) = '0' then
			baud_cnt <= (others => '0');
			bit_en <= '0';
			frame_bit_cnt <= (others => '0');
		else
			if baud_cnt >= BAUD - '1' then
				baud_cnt <= (others => '0');
				bit_en <= '1';
			else
				baud_cnt <= baud_cnt + '1';
				bit_en <= '0';
			end if;
			
			if frame_bit_cnt(5) = '0' then
				if bit_en = '1' then
					frame_bit_cnt <= frame_bit_cnt + '1';
				end if;
			end if;
		end if;
		
		frame_ss <= not frame_bit_cnt(5);

	end if;
end process;



end behav ;