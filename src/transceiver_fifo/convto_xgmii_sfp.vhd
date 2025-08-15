library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity convto_xgmii_sfp is
generic
(
    Q20_EN                          : std_logic := '1';  ---
    SERDES_5G_EN                    : std_logic := '1';
    CURRENT_PORT                    : integer := 0
);
port
(
    nRST_rxclk                      : in std_logic;
    rx_clk                          : in std_logic;
    rx_parallel_data                : in std_logic_vector(63 downto 0);
    rx_control                      : in std_logic_vector(7 downto 0);

    nRST_txclk                      : in std_logic;
    tx_clk                          : in std_logic;
    xgmii_tx_data                   : out std_logic_vector(63 downto 0);
    xgmii_tx_ctrl                   : out std_logic_vector(7 downto 0);
    err_num                         : out std_logic_vector(31 downto 0)
);
end convto_xgmii_sfp;

architecture behaviour of convto_xgmii_sfp is

component xgmii_dataalign is
port
(
    rx_clk                  : in std_logic;
    rx_parallel_data        : in std_logic_vector(63 downto 0);                     -- rx_parallel_data
    rx_control              : in std_logic_vector(7 downto 0);                      -- rx_datak

    data_c_align            : out std_logic_vector(7 downto 0);
    data_align              : out std_logic_vector(63 downto 0)

);
end component;

signal xgmii_data_c_align       : std_logic_vector(7 downto 0);
signal xgmii_data_align         : std_logic_vector(63 downto 0);

component trans_fifo_in is
   port (
			data    : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
			wrreq   : in  std_logic                     := 'X';             -- wrreq
			rdreq   : in  std_logic                     := 'X';             -- rdreq
			wrclk   : in  std_logic                     := 'X';             -- wrclk
			rdclk   : in  std_logic                     := 'X';             -- rdclk
            aclr    : in  std_logic                     := 'X';  
			q       : out std_logic_vector(71 downto 0);                    -- dataout
			rdusedw : out std_logic_vector(9 downto 0);                     -- rdusedw
			wrusedw : out std_logic_vector(9 downto 0);                     -- wrusedw
			rdempty : out std_logic;                                        -- rdempty
			wrfull  : out std_logic                                         -- wrfull
		);
   
end component trans_fifo_in;

type state is (idle,fifo_rd,fifo_delay);
signal pstate: state := idle;
SIGNAL rdusedw :   std_logic_vector(9 downto 0);  
signal trans_fifo_data_b1           : std_logic_vector(71 downto 0);
signal trans_fifo_data              : std_logic_vector(71 downto 0);
signal trans_fifo_wrreq             : std_logic := '0';
signal trans_fifo_rdreq             : std_logic := '0';
signal trans_fifo_rdempty           : std_logic;
signal frame_head_en                : std_logic;
signal port_sel                     : integer range 0 to 1;

signal trans_fifo_q                 : std_logic_vector(71 downto 0);

signal rdreq_en                     : std_logic;
signal rdreq_en_d1                  : std_logic;

signal delay_cnt                    : std_logic_vector(1 downto 0) := (others => '0');
signal cnt                          : std_logic_vector(14 downto 0) := (others => '0');

signal check_sum_buf_rx             : std_logic_vector(63 downto 0);
signal check_sum_rx                 : std_logic_vector(7 downto 0);
signal check_sum_buf_tx             : std_logic_vector(63 downto 0);
signal check_sum_tx                 : std_logic_vector(7 downto 0);
signal err                          : std_logic := '0';
signal err_num_buf                  : std_logic_vector(31 downto 0):= (others => '0');

constant  DLY_W : integer := 16 ;
signal dly_cnt                     : std_logic_vector(DLY_W downto 0):= (others => '0');
signal trans_fifo_wrfull           : std_logic := '0';
signal trans_fifo_wrreq_buf        : std_logic := '0';

signal fif_aclr :std_logic := '1';

begin

xgmii_dataalign_inst : xgmii_dataalign
port map
(
    rx_clk                  => rx_clk,
    rx_parallel_data        => rx_parallel_data,                     -- rx_parallel_data
    rx_control              => rx_control,                     -- rx_datak

    data_c_align            => xgmii_data_c_align,
    data_align              => xgmii_data_align

);

-- port_sel <= 0 when (CURRENT_PORT = 0 or CURRENT_PORT = 2) else 1;
---FOR 4 fiber port (CURRENT PORT IS BACKUP)
 port_sel <= 0 when (CURRENT_PORT = 0 or CURRENT_PORT = 2) else 1;

fif_aclr <= not nRST_rxclk;

trans_fifo_in_inst : trans_fifo_in
port map
(
	data    => trans_fifo_data,
	wrreq   => trans_fifo_wrreq_buf,
	rdreq   => trans_fifo_rdreq,
	wrclk   => rx_clk,
	rdclk   => tx_clk,
	q       => trans_fifo_q,
    aclr    => fif_aclr ,
	rdusedw  =>  rdusedw,
	wrusedw  => open ,                     -- wrusedw
    wrfull  => trans_fifo_wrfull ,
    rdempty => trans_fifo_rdempty
);
trans_fifo_wrreq_buf <=     trans_fifo_wrreq ;----when trans_fifo_wrfull ='0' else '0';
trans_fifo_rdreq     <= '0' when (trans_fifo_rdempty = '1' or (rdreq_en_d1 = '1' and trans_fifo_q(71) /= '0')) else rdreq_en;

process(nRST_rxclk,rx_clk)
begin
    if nRST_rxclk = '0' then
        trans_fifo_wrreq <= '0';
        frame_head_en <= '0';
		
    elsif rising_edge (rx_clk) then
	    if dly_cnt(DLY_W) = '0' then 
		    dly_cnt <= dly_cnt + 1;
		end if;
        if SERDES_5G_EN = '0' then
            if dly_cnt(DLY_W) = '0' then 
			      trans_fifo_wrreq <= '0';
			elsif xgmii_data_c_align = X"01" and xgmii_data_align(7 downto 0) = X"FB" and xgmii_data_align(63 downto 16)=X"D55555555555"then ---need to fixed 
                trans_fifo_wrreq <= '1';
            elsif trans_fifo_wrreq = '1' and trans_fifo_data(71) /= '0' then
                trans_fifo_wrreq <= '0';
            end if;
            trans_fifo_data(71 downto 16) <= xgmii_data_c_align&xgmii_data_align(63 downto 16);
            trans_fifo_data(7 downto 0) <= xgmii_data_align(7 downto 0);
            if dly_cnt(DLY_W) = '1' and xgmii_data_c_align = X"01" then
                trans_fifo_data(15 downto 8) <= check_sum_tx;
            else
                trans_fifo_data(15 downto 8) <= xgmii_data_align(15 downto 8);
            end if;
        else
		    if dly_cnt(DLY_W) = '0' then 
			     frame_head_en <= '0';
            elsif xgmii_data_c_align = X"01" and xgmii_data_align(7 downto 0) = X"FB" and xgmii_data_align(63 downto 16)=X"D55555555555"then
                 frame_head_en <= '1';
            else
                 frame_head_en <= '0';
            end if;
			
			if dly_cnt(DLY_W) = '0' then 
			      trans_fifo_wrreq <= '0';
            -- elsif frame_head_en = '1' and xgmii_data_align(19 downto 16) = port_sel then
            elsif (frame_head_en = '1' and Q20_EN='1'  ) 
            OR  ( frame_head_en = '1'  and Q20_EN='0' and xgmii_data_align(19 downto 16) = port_sel) then
                trans_fifo_wrreq <= '1';
            elsif trans_fifo_wrreq = '1' and trans_fifo_data(71) /= '0' then
                trans_fifo_wrreq <= '0';
            end if;
            if frame_head_en = '1' then
                trans_fifo_data_b1(19 downto 16) <= (others => '0');
            else
                trans_fifo_data_b1(19 downto 16) <= xgmii_data_align(19 downto 16);
            end if;
            trans_fifo_data_b1(71 downto 20) <= xgmii_data_c_align&xgmii_data_align(63 downto 20);
            trans_fifo_data_b1(15 downto 0) <= xgmii_data_align(15 downto 0);
            trans_fifo_data(71 downto 16) <= trans_fifo_data_b1(71 downto 16);
            trans_fifo_data(7 downto 0) <= trans_fifo_data_b1(7 downto 0);
            if trans_fifo_data_b1(71 downto 64) = X"01" then
                trans_fifo_data(15 downto 8) <= check_sum_tx;
            else
                trans_fifo_data(15 downto 8) <= trans_fifo_data_b1(15 downto 8);
            end if;
        end if;
    end if;
end process;

process(rx_clk)
begin
    if rising_edge(rx_clk) then
        if xgmii_data_c_align = X"01" and xgmii_data_align(7 DOWNTO 0)= X"FB" and xgmii_data_align(63 downto 16)=X"D55555555555" then
            check_sum_buf_rx <= (others => '0');
        elsif xgmii_data_c_align /= X"FF" then
            check_sum_buf_rx <= check_sum_buf_rx + xgmii_data_align;
        end if;
        if xgmii_data_c_align = X"01" and  xgmii_data_align(7 DOWNTO 0)= X"FB" and xgmii_data_align(63 downto 16)=X"D55555555555" and xgmii_data_align(15 downto 8) /= check_sum_rx then
            err <= '1';
        else
            err <= '0';
        end if;
        if err = '1' then
            err_num_buf <= err_num_buf + '1';
        end if;
        if trans_fifo_wrreq = '1' then
            if trans_fifo_data(71 downto 64) = X"01" AND trans_fifo_data (7 DOWNTO 0)= X"FB" then
                check_sum_buf_tx <= (others => '0');
            elsif trans_fifo_data(71 downto 64) /= X"FF" then
                check_sum_buf_tx <= check_sum_buf_tx + trans_fifo_data(63 downto 0);
            end if;
        end if;
    end if;
end process;
check_sum_rx <= check_sum_buf_rx(8*8-1 downto 8*7) + check_sum_buf_rx(8*7-1 downto 8*6) + check_sum_buf_rx(8*6-1 downto 8*5) + check_sum_buf_rx(8*5-1 downto 8*4) + check_sum_buf_rx(8*4-1 downto 8*3) + check_sum_buf_rx(8*3-1 downto 8*2) + check_sum_buf_rx(8*2-1 downto 8*1) + check_sum_buf_rx(8*1-1 downto 8*0);
check_sum_tx <= check_sum_buf_tx(8*8-1 downto 8*7) + check_sum_buf_tx(8*7-1 downto 8*6) + check_sum_buf_tx(8*6-1 downto 8*5) + check_sum_buf_tx(8*5-1 downto 8*4) + check_sum_buf_tx(8*4-1 downto 8*3) + check_sum_buf_tx(8*3-1 downto 8*2) + check_sum_buf_tx(8*2-1 downto 8*1) + check_sum_buf_tx(8*1-1 downto 8*0);
err_num <= err_num_buf;
process(nRST_txclk,tx_clk)
begin
    if nRST_txclk = '0' then
        rdreq_en <= '0';
        rdreq_en_d1 <= '0';
        delay_cnt <= (others=>'0');
        cnt <= (others=>'0');
        pstate <= idle;
        xgmii_tx_ctrl <= (others=>'1');
    elsif rising_edge(tx_clk) then
        if rdreq_en_d1 = '1' then
            --if trans_fifo_q(71 downto 64) = X"01" then
            --    xgmii_tx_data(15 downto 8) <= 222 check_sum_tx;  ---bad cross ------
            --else
            --    xgmii_tx_data(15 downto 8) <= trans_fifo_q(15 downto 8);
            --end if;
            --xgmii_tx_data(63 downto 16) <= trans_fifo_q(63 downto 16);
            --xgmii_tx_data(7 downto 0) <= trans_fifo_q(7 downto 0);
            xgmii_tx_data <= trans_fifo_q(63 downto 0);
            xgmii_tx_ctrl <= trans_fifo_q(71 downto 64);
        else
            xgmii_tx_data <= X"0707070707070707";
            xgmii_tx_ctrl <= (others=>'1');
        end if;
        rdreq_en_d1 <= trans_fifo_rdreq;

        case pstate is
            when idle =>
                delay_cnt <= (others=>'0');
                cnt <= (others=>'0');
                if rdusedw >= 4 then ------enough data here trans_fifo_rdempty = '0' then
                    pstate <= fifo_rd;
                    rdreq_en <= '1';
                else
                    pstate <= idle;
                    rdreq_en <= '0';
                end if;

            when fifo_rd =>
                if cnt(14) = '1' then --AT MOST 16384 , IT IS TOO LONG HERE 
                    pstate <= fifo_delay; ---- WAIT A WHILE  idle;
                    rdreq_en <= '0';
                elsif rdreq_en_d1 = '1' and trans_fifo_q(71) /= '0' then
                    pstate <= fifo_delay;
                    rdreq_en <= '0';
                else
                    pstate <= fifo_rd;
                    rdreq_en <= '1';
                end if;
                cnt <= cnt + '1';

            when fifo_delay =>
                cnt <= (others=>'0');
                rdreq_en <= '0';
                --delay_cnt(0) <= not delay_cnt(0);
                --if delay_cnt(0) = '1' then
                    pstate <= idle;
                --else
                --    pstate <= fifo_delay;
                --end if;
            when others =>
                pstate <= idle;
        end case;
    end if;
end process;



end;
