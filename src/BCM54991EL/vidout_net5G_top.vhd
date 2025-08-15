
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vidout_net5G_top is
generic
(
    HSSI_NUM5G    : INTEGER := 4
);
port
(
    clk125M_in              : IN    std_logic ;
    clkin_5gsfp             : IN    std_logic ;
    nRST                    : IN    std_logic ;

    tx_parallel_data        : in  std_logic_vector(8*8*HSSI_NUM5G-1 downto 0);
    tx_control              : in  std_logic_vector(8*HSSI_NUM5G-1 downto 0);
    tx_clk                  : out std_logic;

    rx_clk                  : out std_logic_vector(HSSI_NUM5G-1 downto 0);
    rx_parallel_data        : out std_logic_vector(HSSI_NUM5G*8*8-1 downto 0);
    rx_control              : out std_logic_vector(HSSI_NUM5G*8-1 downto 0);
    eth_link_rxclk          : out std_logic_vector(HSSI_NUM5G-1 downto 0);

    config_rdack            : in std_logic;
    config_rdreq            : out std_logic;
    config_rdaddr           : out std_logic_vector(24 downto 0);
    config_rdlen            : out std_logic_vector(12 downto 0);
    flash_dpram_data        : in std_logic_vector(31 downto 0);
    flash_dpram_wraddr      : in std_logic_vector(8 downto 0);
    flash_dpram_wren        : in std_logic;

    PHYAB_RESET				: out   std_logic ;
	PHYAB_MDC				: out   std_logic ;
	PHYAB_MDIO				: inout std_logic ;
	PHYCD_RESET				: out   std_logic ;
	PHYCD_MDC				: out   std_logic ;
	PHYCD_MDIO				: inout std_logic ;

    tx_serial_5gdata          : out   std_logic_vector (HSSI_NUM5G-1 downto 0);
    rx_serial_5gdata          : in    std_logic_vector (HSSI_NUM5G-1 downto 0)
);
end vidout_net5G_top;

architecture beha of vidout_net5G_top is


component serdes8b10b_tx_5GBaseR is
generic
(
    HSSI_NUM : integer := 4
);
port
(
    reconfclk                 : in std_logic;
    refclk_125              : in std_logic ;
    tx_serial_data          : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_serial_data
    rx_serial_data          : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_serial_data

    tx_parallel_data        : in  std_logic_vector(8*8*HSSI_NUM-1 downto 0)  := (others => 'X'); -- tx_parallel_data
    tx_control              : in  std_logic_vector(8*HSSI_NUM-1 downto 0)   := (others => 'X');
    tx_clk                  : out std_logic;

    rx_clk                  : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_parallel_data        : out std_logic_vector(HSSI_NUM*8*8-1 downto 0);                     -- rx_parallel_data
    rx_control                : out std_logic_vector(HSSI_NUM*8-1 downto 0);                      -- rx_datak

    rx_errdetect            : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_disperr              : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_disperr
    rx_runningdisp          : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_runningdisp
    rx_patterndetect        : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_patterndetect
    rx_rmfifostatus         : out std_logic_vector(2*HSSI_NUM-1 downto 0);                     -- rx_rmfifostatus
    tx_enh_data_valid       : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');
    tx_enh_fifo_full        : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
    tx_enh_fifo_pfull       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pfull
    tx_enh_fifo_empty       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_empty
    tx_enh_fifo_pempty      : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pempty
    rx_enh_data_valid       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_data_valid
    rx_enh_fifo_full        : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_full
    rx_enh_fifo_empty       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_empty
    rx_enh_fifo_del         : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_del
    rx_enh_fifo_insert      : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_insert
    rx_enh_highber          : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_highber
    rx_enh_blk_lock         : out std_logic_vector(HSSI_NUM-1 downto 0);

    phy_reset  : in std_logic

);
end component;

signal  rx_control_5g           :   std_logic_vector(HSSI_NUM5G*8-1 downto 0);
signal  tx_enh_data_valid       :   std_logic_vector(HSSI_NUM5G-1 downto 0)   := (others => 'X');
signal  rx_errdetect            :   std_logic_vector(HSSI_NUM5G-1 downto 0);
signal  rx_disperr              :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_disperr
signal  rx_runningdisp          :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_runningdisp
signal  rx_patterndetect        :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_patterndetect
signal  rx_rmfifostatus         :   std_logic_vector(HSSI_NUM5G*2-1 downto 0);                     -- rx_rmfifostatus
signal  tx_enh_fifo_full        :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- tx_enh_fifo_full
signal  tx_enh_fifo_pfull       :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- tx_enh_fifo_pfull
signal  tx_enh_fifo_empty       :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- tx_enh_fifo_empty
signal  tx_enh_fifo_pempty      :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- tx_enh_fifo_pempty
signal  rx_enh_data_valid       :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_enh_data_valid
signal  rx_enh_fifo_full        :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_enh_fifo_full
signal  rx_enh_fifo_empty       :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_enh_fifo_empty
signal  rx_enh_fifo_del         :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_enh_fifo_del
signal  rx_enh_fifo_insert      :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_enh_fifo_insert
signal  rx_enh_highber          :   std_logic_vector(HSSI_NUM5G-1 downto 0);                      -- rx_enh_highber
signal  rx_enh_blk_lock         :   std_logic_vector(HSSI_NUM5G-1 downto 0);

signal  reconfclk  				 : std_logic:='0';
signal  rst_reconfclk  			 : std_logic:='0';

component PHY_RESET is
port(
    SYSCLK               : in std_logic;
    nRST                 : in std_logic;
    time_ms_en 			 : out std_logic;
    phy_rsta_done        : out std_logic;
    phy_reseta           : out std_logic

);
end component;

signal time_ms_en		: std_logic;
signal phy_rsta_done	:std_logic;
signal phy_reseta		:std_logic;

component config_phy is
port(
	nRST					: in std_logic;
	SYSCLK					: in std_logic;
    test                    : out std_logic;

	time_ms_en				: in std_logic ;

	config_rdack			: in std_logic;
	config_rdreq			: out std_logic;
	config_rdaddr		    : out std_logic_vector(24 downto 0);
	config_rdlen		    : out std_logic_vector(12 downto 0);

	flash_dpram_data    	: in std_logic_vector(31 downto 0);
	flash_dpram_wraddr      : in std_logic_vector(8 downto 0);
	flash_dpram_wren     	: in std_logic;

	phy_rsta_done			: in std_logic;

	phy0_mdc				: out std_logic;
	phy0_mdin				: in std_logic;
	phy0_mdout				: out std_logic;
	phy0_mdir				: out std_logic

);
end component;

signal phy0_mdir	:std_logic;
signal phy0_mdout	:std_logic;
signal phy0_mdin	:std_logic;
signal phy0_mdc 	:std_logic;
signal phy1_mdir	:std_logic;
signal phy1_mdout	:std_logic;
signal phy1_mdin	:std_logic;
signal phy1_mdc 	:std_logic;

begin

rst_reconfclk <= not nRST;

reconfclk <= clk125M_in;

rx_control <= rx_control_5g;
Serd_I: serdes8b10b_tx_5GBaseR
generic map (
    HSSI_NUM  => HSSI_NUM5G
)
port MAP
(
    reconfclk             => reconfclk ,
    refclk_125            => clkin_5gsfp ,
    tx_serial_data        => tx_serial_5gdata, -- tx_serial_data
    rx_serial_data        => rx_serial_5gdata, -- rx_serial_data
    tx_enh_data_valid     => tx_enh_data_valid ,
    tx_parallel_data      => tx_parallel_data  ,-- tx_parallel_data
    tx_control            => tx_control        ,
    tx_clk                => tx_clk            ,

    rx_clk                => rx_clk            ,
    rx_parallel_data      => rx_parallel_data  ,                    -- rx_parallel_data
    rx_control            => rx_control_5g        ,                    -- rx_datak
    rx_errdetect          => rx_errdetect      ,
    rx_disperr            => rx_disperr        ,                    -- rx_disperr
    rx_runningdisp        => rx_runningdisp    ,                    -- rx_runningdisp
    rx_patterndetect      => rx_patterndetect  ,                    -- rx_patterndetect
    rx_rmfifostatus       => rx_rmfifostatus   ,                    -- rx_rmfifostatus
    tx_enh_fifo_full      => tx_enh_fifo_full  ,                    -- tx_enh_fifo_full
    tx_enh_fifo_pfull     => tx_enh_fifo_pfull ,                    -- tx_enh_fifo_pfull
    tx_enh_fifo_empty     => tx_enh_fifo_empty ,                    -- tx_enh_fifo_empty
    tx_enh_fifo_pempty    => tx_enh_fifo_pempty,                    -- tx_enh_fifo_pempty
    rx_enh_data_valid     => rx_enh_data_valid ,                    -- rx_enh_data_valid
    rx_enh_fifo_full      => rx_enh_fifo_full  ,                    -- rx_enh_fifo_full
    rx_enh_fifo_empty     => rx_enh_fifo_empty ,                    -- rx_enh_fifo_empty
    rx_enh_fifo_del       => rx_enh_fifo_del   ,                    -- rx_enh_fifo_del
    rx_enh_fifo_insert    => rx_enh_fifo_insert,                    -- rx_enh_fifo_insert
    rx_enh_highber        => rx_enh_highber    ,                    -- rx_enh_highber
    rx_enh_blk_lock       => rx_enh_blk_lock   ,

    phy_reset             => rst_reconfclk

);
dataalign_generate : for i in  0 to HSSI_NUM5G-1 generate
eth_link_rxclk(i) <= '0' when rx_control_5g(i*8+7 downto i*8) = X"11" else '1';
end generate dataalign_generate;

PHY_RESET_inst : PHY_RESET
port map(
    SYSCLK               => clk125M_in,
    nRST                 => nRST,
    time_ms_en 			 => time_ms_en,
    phy_rsta_done        => phy_rsta_done,
    phy_reseta           => phy_reseta

);
PHYAB_RESET <= phy_reseta;
PHYCD_RESET <= phy_reseta;

config_phy_inst	: config_phy
port map(
	nRST					=> nRST,
	SYSCLK					=> clk125M_in,
    test                    => open,

	time_ms_en				=> time_ms_en,

	config_rdack			=> config_rdack,
	config_rdreq			=> config_rdreq,
	config_rdaddr		    => config_rdaddr,
	config_rdlen		    => config_rdlen,

	flash_dpram_data    	=> flash_dpram_data,
	flash_dpram_wraddr      => flash_dpram_wraddr,
	flash_dpram_wren     	=> flash_dpram_wren,

	phy_rsta_done			=> phy_rsta_done,
	phy0_mdc				=> phy0_mdc,
	phy0_mdin				=> phy0_mdin,
	phy0_mdout				=> phy0_mdout,
	phy0_mdir				=> phy0_mdir

);
PHYAB_MDIO <= phy0_mdout when phy0_mdir = '1' else 'Z'; --'0' : in , '1' : out
phy0_mdin <= PHYAB_MDIO;
PHYAB_MDC <= phy0_mdc;

config_phy1_inst	: config_phy
port map(
	nRST					=> nRST,
	SYSCLK					=> clk125M_in,
    test                    => open,

	time_ms_en				=> time_ms_en,

	config_rdack			=> config_rdack,
	config_rdreq			=> open,
	config_rdaddr		    => open,
	config_rdlen		    => open,

	flash_dpram_data    	=> flash_dpram_data,
	flash_dpram_wraddr      => flash_dpram_wraddr,
	flash_dpram_wren     	=> flash_dpram_wren,

	phy_rsta_done			=> phy_rsta_done,
	phy0_mdc				=> phy1_mdc,
	phy0_mdin				=> phy1_mdin,
	phy0_mdout				=> phy1_mdout,
	phy0_mdir				=> phy1_mdir

);
PHYCD_MDIO <= phy1_mdout when phy1_mdir = '1' else 'Z'; --'0' : in , '1' : out
phy1_mdin <= PHYCD_MDIO;
PHYCD_MDC <= phy1_mdc;


end ;
