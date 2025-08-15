library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity test_harness is
generic
(
	HSSI_NUM    : integer:= 24
);
port(
	reset					: in  std_logic;
    
    tx_clk_156m				: in  std_logic_vector(HSSI_NUM-1 downto 0);
	xgmii_tx_d 				: out std_logic_vector(64*HSSI_NUM-1 downto 0);
	xgmii_tx_c				: out std_logic_vector(8*HSSI_NUM-1 downto 0);

    tx_enh_data_valid       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
    tx_enh_fifo_full        : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
    tx_enh_fifo_pfull       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pfull
    tx_enh_fifo_empty       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_empty
    tx_enh_fifo_pempty      : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pempty
    rx_enh_data_valid       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_data_valid
    rx_enh_fifo_full        : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_full
    rx_enh_fifo_empty       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_empty
    rx_enh_fifo_del         : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_del
    rx_enh_fifo_insert      : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_insert
    rx_enh_highber          : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_highber
    rx_enh_blk_lock         : in  std_logic_vector(HSSI_NUM-1 downto 0);     
    
    rx_clk_156m			    : in  std_logic_vector(HSSI_NUM-1 downto 0);	
    xgmii_rx_d 				: in  std_logic_vector(64*HSSI_NUM-1 downto 0);
	xgmii_rx_c				: in  std_logic_vector(8*HSSI_NUM-1 downto 0);

	led						: out std_logic;					--status
	status					: out std_logic_vector(HSSI_NUM-1 downto 0)
);
end entity;

architecture behav of test_harness is

component xgmii_src is
port(
	xgmii_tx_clk			: in  std_logic;
	reset					: in  std_logic;
    
    tx_enh_data_valid       : out std_logic ;                      -- tx_enh_fifo_full
    tx_enh_fifo_full        : in  std_logic ;                      -- tx_enh_fifo_full
    tx_enh_fifo_pfull       : in  std_logic ;                      -- tx_enh_fifo_pfull
    tx_enh_fifo_empty       : in  std_logic ;                      -- tx_enh_fifo_empty
    tx_enh_fifo_pempty      : in  std_logic ;                      -- tx_enh_fifo_pempty

	frame_req				: in  std_logic;
	frame_ack				: out std_logic;
	frame_done				: out std_logic;
	frame_free				: out std_logic;
	frame_length			: in  std_logic_vector(13 downto 0);
	frame_type				: in  std_logic_vector(3 downto 0);

	xgmii_tx_d 				: out std_logic_vector(64-1 downto 0);
	xgmii_tx_c 				: out std_logic_vector(8-1 downto 0)
	
);
end component;

component xgmii_sink is
port(
	xgmii_rx_clk			: in  std_logic;
	reset					: in  std_logic;
    
    rx_enh_data_valid       : in  std_logic ;                      -- rx_enh_data_valid
    rx_enh_fifo_full        : in  std_logic ;                      -- rx_enh_fifo_full
    rx_enh_fifo_empty       : in  std_logic ;                      -- rx_enh_fifo_empty
    rx_enh_fifo_del         : in  std_logic ;                      -- rx_enh_fifo_del
    rx_enh_fifo_insert      : in  std_logic ;                      -- rx_enh_fifo_insert
    rx_enh_highber          : in  std_logic ;                      -- rx_enh_highber
    rx_enh_blk_lock         : in  std_logic ;     
   
	xgmii_rx_d 				: in  std_logic_vector(63 downto 0);
	xgmii_rx_c				: in  std_logic_vector(7  downto 0);
	status					: out std_logic_vector(4 downto 0)	
);
end component;

signal status_buf									: std_logic_vector(HSSI_NUM*5-1 downto 0):= (others => '0');
signal frame_req									: std_logic_vector(HSSI_NUM-1 downto 0):= (others => '0');
signal frame_ack									: std_logic_vector(HSSI_NUM-1 downto 0):= (others => '0');
signal frame_done									: std_logic_vector(HSSI_NUM-1 downto 0):= (others => '0');
signal frame_free									: std_logic_vector(HSSI_NUM-1 downto 0):= (others => '0');
signal frame_length									: std_logic_vector(HSSI_NUM*14-1 downto 0):= (others => '0');
signal frame_cnt									: std_logic_vector(HSSI_NUM*4-1 downto 0):= (others => '0');
signal reset_tx                                     : std_logic_vector(HSSI_NUM-1 downto 0):=(others=>'0');
signal reset_rx                                     : std_logic_vector(HSSI_NUM-1 DOWNTO 0):=(OTHERS=>'0');
signal rx_clk_156m_conv                             : std_logic_vector(HSSI_NUM-1 DOWNTO 0):=(OTHERS=>'0');

begin

CHL_GENE: for i in 0 to HSSI_NUM-1 generate

process(reset_tx(i),tx_clk_156m(i) )
begin
	if reset_tx(i) = '1' then
		frame_req(i) <= '0';
		frame_cnt(i*4+3 downto i*4) <= (others => '0');
	
	elsif rising_edge(tx_clk_156m(i) ) then
		if frame_free(i) = '0' then
			frame_cnt(i*4+3 downto i*4) <= (others => '0');
		elsif frame_cnt(i*4+3) = '0' then
			frame_cnt(i*4+3 downto i*4) <= frame_cnt(i*4+3 downto i*4) + '1';
		end if;
		
		if frame_cnt(i*4+3 downto i*4) = 7 then
			frame_req(i) <= '1';
		else
			frame_req(i) <= '0';
		end if;
		
		frame_length(i*14+13 downto i*14) <= "00"&x"100";

	end if;
end process;

xgmii_src_inst: xgmii_src
port map(
	xgmii_tx_clk			    => tx_clk_156m(i),
	reset					    => reset_tx(i),
    
    tx_enh_data_valid           => tx_enh_data_valid(i) ,                     -- tx_enh_fifo_full
    tx_enh_fifo_full            => tx_enh_fifo_full(i)  ,                     -- tx_enh_fifo_full
    tx_enh_fifo_pfull           => tx_enh_fifo_pfull(i) ,                     -- tx_enh_fifo_pfull
    tx_enh_fifo_empty           => tx_enh_fifo_empty(i) ,                     -- tx_enh_fifo_empty
    tx_enh_fifo_pempty          => tx_enh_fifo_pempty(i),                     -- tx_enh_fifo_pempty

	frame_req					=> frame_req(i)	                        ,
	frame_ack					=> frame_ack(i)		                    ,
	frame_done					=> frame_done(i)		                ,
	frame_free					=> frame_free(i)		                ,
	frame_length				=> frame_length(i*14+13 downto i*14)	,
	frame_type					=> "0000"								,

	xgmii_tx_d 					=> xgmii_tx_d (i*64+63 downto 64*i),
	xgmii_tx_c					=> xgmii_tx_c (i*8+7   downto 8*i)
	
);

xgmii_sink_inst: xgmii_sink
port map(
	xgmii_rx_clk			=> rx_clk_156m(i),
	reset					=> reset_rx(i),
    
    rx_enh_data_valid       => rx_enh_data_valid(i) ,                    -- rx_enh_data_valid
    rx_enh_fifo_full        => rx_enh_fifo_full(i)  ,                    -- rx_enh_fifo_full
    rx_enh_fifo_empty       => rx_enh_fifo_empty(i) ,                    -- rx_enh_fifo_empty
    rx_enh_fifo_del         => rx_enh_fifo_del(i)   ,                    -- rx_enh_fifo_del
    rx_enh_fifo_insert      => rx_enh_fifo_insert(i),                    -- rx_enh_fifo_insert
    rx_enh_highber          => rx_enh_highber(i)    ,                    -- rx_enh_highber
    rx_enh_blk_lock         => rx_enh_blk_lock(i)   ,   

	xgmii_rx_d 				=> xgmii_rx_d (i*64+63 downto 64*i)   ,
	xgmii_rx_c				=> xgmii_rx_c(i*8+7  downto 8*i)   ,
	status					=> status_buf(i*5+4 downto i*5)
);

status(i) <= status_buf(i*5+4);
end generate CHL_GENE;

led <= not xgmii_rx_d (0) when status_buf /=0 else '1';

end behav;

