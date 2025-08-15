library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Z8_boardout is
generic
(
    CONS_VER_HIGH       : std_logic_vector := X"00";
    CONS_VER_LOW        : std_logic_vector := X"5E";
    TXSUBCARD_TYPE      : std_logic_vector := X"80";
    PORT_NUM            : integer := 2;
    SERDES_SPEED_MSB    : integer := 10;
    SERDES_SPEED_LSB    : integer := 0;
    BAUD_DIV            : std_logic_vector := X"000B";
    HSSI_NUM            : integer := 2;
    HSSI_NUM5G          : integer := 4
);
port
(
    --CLKUSR                      : in  std_logic;
    clkin_156M                  : in  std_logic;
    clkin_125M                  : in  std_logic;

    led                         : out std_logic;
    rxd_frmbk                   : in  std_logic;
    txd_tobk                    : out std_logic;
    txd_info                    : out std_logic;

    PHYAB_RESET                 : out   std_logic ;
    PHYAB_MDC                   : out   std_logic ;
    PHYAB_MDIO                  : inout std_logic ;
    PHYCD_RESET                 : out   std_logic ;
    PHYCD_MDC                   : out   std_logic ;
    PHYCD_MDIO                  : inout std_logic ;
    tx_serial_5gdata            : out   std_logic_vector (HSSI_NUM5G-1 downto 0);
    rx_serial_5gdata            : in    std_logic_vector (HSSI_NUM5G-1 downto 0);

    rx_serial_data              : in std_logic_vector(HSSI_NUM-1 downto 0)  := (others => 'X');

    tx_serial_sfpdata           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_serial_sfpdata           : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X')

);
end Z8_boardout;

architecture behaviour of Z8_boardout is

component vidout_net5G_top is
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

    rx_clk                  : out std_logic;
    rx_parallel_data        : out std_logic_vector(HSSI_NUM5G*8*8-1 downto 0);
    rx_control              : out std_logic_vector(HSSI_NUM5G*8-1 downto 0);

    config_rdack            : in std_logic;
    config_rdreq            : out std_logic;
    config_rdaddr           : out std_logic_vector(24 downto 0);
    config_rdlen            : out std_logic_vector(12 downto 0);
    flash_dpram_data        : in std_logic_vector(31 downto 0);
    flash_dpram_wraddr      : in std_logic_vector(8 downto 0);
    flash_dpram_wren        : in std_logic;

    PHYAB_RESET             : out   std_logic ;
    PHYAB_MDC               : out   std_logic ;
    PHYAB_MDIO              : inout std_logic ;
    PHYCD_RESET             : out   std_logic ;
    PHYCD_MDC               : out   std_logic ;
    PHYCD_MDIO              : inout std_logic ;

    tx_serial_5gdata          : out   std_logic_vector (HSSI_NUM5G-1 downto 0);
    rx_serial_5gdata          : in    std_logic_vector (HSSI_NUM5G-1 downto 0)
);
end component;

signal config_rdack            :  std_logic;
signal config_rdreq            :  std_logic;
signal config_rdaddr           :  std_logic_vector(24 downto 0);
signal config_rdlen            :  std_logic_vector(12 downto 0);
signal flash_dpram_data        :  std_logic_vector(31 downto 0);
signal flash_dpram_wraddr      :  std_logic_vector(8 downto 0);
signal flash_dpram_wren        :  std_logic;

signal tx_parallel_data_5g : std_logic_vector(8*8*HSSI_NUM5G-1 downto 0);
signal tx_control_5g : std_logic_vector(8*HSSI_NUM5G-1 downto 0);
signal tx_clk_5g : std_logic;
signal rx_parallel_data_5g : std_logic_vector(8*8*HSSI_NUM5G-1 downto 0);
signal rx_control_5g : std_logic_vector(8*HSSI_NUM5G-1 downto 0);
signal rx_clk_5g : std_logic;

component main_pll is
port (
	rst      : in  std_logic := 'X'; -- reset
	refclk   : in  std_logic := 'X'; -- clk
	locked   : out std_logic;        -- export
	outclk_0 : out std_logic         -- clk
);
end component main_pll;

signal RST              : std_logic;
signal rst_cnt          : std_logic_vector(9 downto 0) := (others=>'0');
signal main_pll_locked  : std_logic;
signal sysclk           : std_logic := '0';

component resetmodule is
generic
(
    HSSI_NUM : integer
);
port
(
    sysclk              : in std_logic;
    tx_clk              : in std_logic;
    rx_clk0             : in std_logic_vector(HSSI_NUM-1 downto 0);
    rx_clk1             : in std_logic_vector(HSSI_NUM-1 downto 0);
    pll_lock            : in std_logic;

    nRST_sys            : out std_logic;
    RST_sys             : out std_logic;
    nRST_rxclk0         : out std_logic_vector(HSSI_NUM-1 downto 0);
    nRST_rxclk1         : out std_logic_vector(HSSI_NUM-1 downto 0);
    nRST_txclk          : out std_logic
);
end component;

signal nRST_sys            : std_logic;
signal RST_sys             : std_logic;
signal nRST_rxclk0         : std_logic_vector(HSSI_NUM-1 downto 0);
signal nRST_rxclk1         : std_logic_vector(HSSI_NUM-1 downto 0);
signal nRST_sfptxclk       : std_logic;

constant CLK_NUM : integer:=10;

component multi_measure is
generic
(
    CLK_NUM : integer := 10
);
port
(
    sysclk     : in  std_logic ;  --125M
    nRST_sys   : in  std_logic ;
    clk_set    : in  std_logic_vector(CLK_NUM-1 downto 0);
    mask_out   : out std_logic := '0';
    clk_cnt    : out std_logic_vector(CLK_NUM*32-1 downto 0)

);
end component;

signal clk_set          : std_logic_vector(CLK_NUM-1 downto 0);

component serdes_datain is
generic
(
    HSSI_NUM : integer := 2
);
port
(
    reconfclk                   : in std_logic;
    refclk                      : in std_logic;
    rx_serial_data              : in std_logic_vector(HSSI_NUM-1 downto 0)  := (others => 'X');

    rx_clk                      : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_parallel_data            : out std_logic_vector(HSSI_NUM*64-1 downto 0);
    rx_control                  : out std_logic_vector(HSSI_NUM*8-1 downto 0);

    rx_enh_data_valid           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_full            : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_empty           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_del             : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_insert          : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_highber              : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_blk_lock             : out std_logic_vector(HSSI_NUM-1 downto 0);

    phy_reset                   : in std_logic
);
end component;

signal rx_clk                  :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_parallel_data        :   std_logic_vector(HSSI_NUM*64-1 downto 0);
signal rx_control              :   std_logic_vector(HSSI_NUM*8-1 downto 0);

signal rx_enh_data_valid       :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_full        :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_empty       :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_del         :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_insert      :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_highber          :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_blk_lock         :   std_logic_vector(HSSI_NUM-1 downto 0);

component serdes_dataout is
generic
(
    HSSI_NUM : integer := 2
);
port
(
    reconfclk                   : in std_logic;
    refclk                      : in std_logic;
    tx_serial_sfpdata           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_serial_sfpdata          : in std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');

    sfp_txclk                   : out std_logic_vector(HSSI_NUM-1 downto 0);
    xgmii_tx_data               : in std_logic_vector(HSSI_NUM*64-1 downto 0)  := (others => 'X');
    xgmii_tx_ctrl               : in std_logic_vector(HSSI_NUM*8-1 downto 0)   := (others => 'X');

    sfp_rxclk                   : out std_logic_vector(HSSI_NUM-1 downto 0);
    xgmii_rx_data               : out std_logic_vector(HSSI_NUM*64-1 downto 0);
    xgmii_rx_ctrl               : out std_logic_vector(HSSI_NUM*8-1 downto 0);

    tx_enh_data_valid           : in std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');
    tx_enh_fifo_full            : out std_logic_vector(HSSI_NUM-1 downto 0);
    tx_enh_fifo_pfull           : out std_logic_vector(HSSI_NUM-1 downto 0);
    tx_enh_fifo_empty           : out std_logic_vector(HSSI_NUM-1 downto 0);
    tx_enh_fifo_pempty          : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_data_valid           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_full            : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_empty           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_del             : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_insert          : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_highber              : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_blk_lock             : out std_logic_vector(HSSI_NUM-1 downto 0);

    phy_reset                   : in std_logic
);
end component;

signal sfp_txclk                   : std_logic_vector(HSSI_NUM-1 downto 0);
signal xgmii_tx_data               : std_logic_vector(HSSI_NUM*64-1 downto 0);
signal xgmii_tx_ctrl               : std_logic_vector(HSSI_NUM*8-1 downto 0);
signal sfp_rxclk                   : std_logic_vector(HSSI_NUM-1 downto 0);
signal xgmii_rx_data               : std_logic_vector(HSSI_NUM*64-1 downto 0);
signal xgmii_rx_ctrl               : std_logic_vector(HSSI_NUM*8-1 downto 0);
signal xgmii_rx_updata             : std_logic_vector(HSSI_NUM*64-1 downto 0);
signal xgmii_rx_upctrl             : std_logic_vector(HSSI_NUM*8-1 downto 0);


signal tx_enh_data_valid_sfp       : std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X');
signal tx_enh_fifo_full_sfp        : std_logic_vector(HSSI_NUM-1 downto 0);
signal tx_enh_fifo_pfull_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal tx_enh_fifo_empty_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal tx_enh_fifo_pempty_sfp      : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_data_valid_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_full_sfp        : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_empty_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_del_sfp         : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_insert_sfp      : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_highber_sfp          : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_blk_lock_sfp         : std_logic_vector(HSSI_NUM-1 downto 0);

component convto_xgmii_sfp is
port
(
    nRST_rxclk                      : in std_logic;
    rx_clk                          : in std_logic;
    rx_parallel_data                : in std_logic_vector(63 downto 0);
    rx_control                      : in std_logic_vector(7 downto 0);

    nRST_txclk                      : in std_logic;
    tx_clk                          : in std_logic;
    xgmii_tx_data                   : out std_logic_vector(63 downto 0);
    xgmii_tx_ctrl                   : out std_logic_vector(7 downto 0)
);
end component;

component test_harness is
generic
(
	HSSI_NUM    : integer:= 24
);
port(
	reset					: in  std_logic;

    -- tx_clk_156m				: in  std_logic_vector(HSSI_NUM-1 downto 0);
	-- xgmii_tx_d 				: out std_logic_vector(64*HSSI_NUM-1 downto 0);
	-- xgmii_tx_c				: out std_logic_vector(8*HSSI_NUM-1 downto 0);

    -- tx_enh_data_valid       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
    -- tx_enh_fifo_full        : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
    -- tx_enh_fifo_pfull       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pfull
    -- tx_enh_fifo_empty       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_empty
    -- tx_enh_fifo_pempty      : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pempty
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
end component;

component xgmii5g_fifo is
    port (
        data    : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
        wrreq   : in  std_logic                     := 'X';             -- wrreq
        rdreq   : in  std_logic                     := 'X';             -- rdreq
        wrclk   : in  std_logic                     := 'X';             -- wrclk
        rdclk   : in  std_logic                     := 'X';             -- rdclk
        q       : out std_logic_vector(71 downto 0);                    -- dataout
        rdempty : out std_logic                                         -- rdempty
    );
end component xgmii5g_fifo;

signal xgmii5g_fifo_data_b1  : std_logic_vector(71 downto 0);
signal xgmii5g_fifo_data     : std_logic_vector(71 downto 0);
signal xgmii5g_fifo_wren     : std_logic_vector(HSSI_NUM5G-1 downto 0);
signal xgmii5g_fifo_rden     : std_logic_vector(HSSI_NUM5G-1 downto 0);
signal xgmii5g_fifo_rden_d1  : std_logic_vector(HSSI_NUM5G-1 downto 0);
signal xgmii5g_fifo_q        : std_logic_vector(HSSI_NUM5G*72-1 downto 0);
signal xgmii5g_fifo_rdempty  : std_logic_vector(HSSI_NUM5G-1 downto 0);
signal frame_head_en         : std_logic := '0';

component uart_param_top is
generic
(
    CONS_VER_HIGH       : std_logic_vector(7  downto 0);
    CONS_VER_LOW        : std_logic_vector(7  downto 0);
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0);
    PORT_NUM            : integer;
    SERDES_SPEED_MSB    : integer;
    SERDES_SPEED_LSB    : integer;
    BAUD_DIV            : std_logic_vector(15 downto 0);
    HSSI_NUM            : integer:= 2
);
port
(
    nRST            : in std_logic ;
    sysclk          : in std_logic;
    ---uart: 2 pins of uart
    rxd_top         : in  std_logic ;  --from top pad
    txd_top         : out std_logic ; ---to top pad
    txd_info_top    : out std_logic ; ---to top pad

    --info
    crc_info        : in std_logic_vector(7 downto 0);

    p_Frame_en_o    : out std_logic ;
    p_Wren_o        : out std_logic ;
    p_Data_o        : out std_logic_vector(7 downto 0);
    p_Addr_o        : out std_logic_vector(10 downto 0);
    cur_slot_num    : out std_logic_vector(15 downto 0);

    Up_ReadEn_o         : out std_logic;
    Up_req              : in  std_logic_vector(HSSI_NUM-1 downto 0);
    Up_ack              : out std_logic_vector(HSSI_NUM-1 downto 0);
    Up_ReadLength_i     : in  std_logic_vector(10 downto 0);
    Up_ReadAddr_o       : out std_logic_vector(10 downto 0);
    Up_ReadData_i       : in  std_logic_vector(7 downto 0)  ---latency is 2 ,after Up_ReadAddr_o;
);
end component;

signal Up_ReadEn_o      : std_logic;
signal Up_req           : std_logic_vector(HSSI_NUM-1 downto 0);
signal Up_ack           : std_logic_vector(HSSI_NUM-1 downto 0);
signal Up_ReadLength_i  : std_logic_vector(10 downto 0);
signal Up_ReadAddr_o    : std_logic_vector(10 downto 0);
signal Up_ReadData_i    : std_logic_vector(7 downto 0);

signal p_Frame_en_o     : std_logic;
signal p_Wren_o         : std_logic;
signal p_Data_o         : std_logic_vector(7 downto 0);
signal p_Addr_o         : std_logic_vector(10 downto 0);
signal cur_slot_num     : std_logic_vector(15 downto 0);
signal crc_info         : std_logic_vector(7 downto 0);

component top_update is
generic(
    FLASH_PROTECT_EN                    : std_logic:= '1';

    FRAME_W                             : integer:= 12;
    FLASH_ADDR_W_INBYTE                 : integer:= 25;
    FLASH_DATA_W                        : integer:= 32
);
port(
    nRST                                : in  std_logic;
    sysclk                              : in  std_logic;
    time_ms_en                          : in  std_logic;
    --para
    pframe_ss                           : in  std_logic;
    pwren                               : in  std_logic;
    paddr                               : in  std_logic_vector(FRAME_W-1 downto 0);
    pdata                               : in  std_logic_vector(7 downto 0);

    config_rdack                        : out std_logic;
    config_rdreq                        : in  std_logic;
    config_rdaddr                       : in  std_logic_vector(24 downto 0);
    config_rdlen                        : in  std_logic_vector(12 downto 0);
    flash_dpram_data                    : out std_logic_vector(31 downto 0);
    flash_dpram_wraddr                  : out std_logic_vector(8 downto 0);
    flash_dpram_wren                    : out std_logic;

    update_crc_right                    : out std_logic;
    update_prog_done                    : out std_logic;
    update_crc_done                     : out std_logic;
    update_erase_done                   : out std_logic

);
end component;

component uart_64to8 is
generic
(
    HSSI_NUM            : integer:= 2
);
port
(
    nRST                : in  std_logic;
    sysclk              : in  std_logic;
    nRST_rxclk          : in  std_logic;
    rxclk               : in  std_logic;
    xgmii_rx_updata     : in  std_logic_vector(HSSI_NUM*64-1 downto 0);
    xgmii_rx_upctrl     : in  std_logic_vector(HSSI_NUM*8-1 downto 0);
    cur_slot_num        : in  std_logic_vector(3 downto 0);


    Up_ack              : in  std_logic_vector(HSSI_NUM-1 downto 0);
    Up_req              : out std_logic_vector(HSSI_NUM-1 downto 0);
    Up_ReadEn_o         : in  std_logic;
    Up_ReadLength_i     : out std_logic_vector(10 downto 0);
    Up_ReadAddr_o       : in  std_logic_vector(10 downto 0);
    Up_ReadData_i       : out std_logic_vector(7 downto 0)  ---latency is 2 ,after Up_ReadAddr_o;

);
end component;

component time_ms_gen is
generic
(
 IS_156M: integer := 0   --0: 125M 1 : 156M
);
port ( nRST         : in  std_logic  ;
       clk          : in std_logic ;
       time_ms_en_o : out std_logic
     );
end component;

signal time_ms_en_125 : std_logic;

--component altclkctrl is
--port (
--    inclk  : in  std_logic := 'X'; -- inclk
--    outclk : out std_logic         -- outclk
--);
--end component altclkctrl;
--signal clk125M_in_groble : std_LOGIC;
--signal clk156M_in_groble : std_LOGIC;

begin

--process(clkin_156M)
--begin
--    if rising_edge(clkin_156M) then
--        if rst_cnt(9) = '0' then
--            rst_cnt <= rst_cnt + '1';
--        end if;
--    end if;
--end process;
--RST <= not rst_cnt(9);

--main_pll_inst : main_pll
--port map
--(
--	rst      => RST,        -- reset
--	refclk   => clkin_156M,        -- clk
--	locked   => main_pll_locked,        -- export
--	outclk_0 => sysclk        -- clk
--);
sysclk <= clkin_125M;
--altclkctrl_inst : altclkctrl
--port map (
--    inclk  => clkin_156M,  --  altclkctrl_input.inclk
--    outclk => clk156M_in_groble  -- altclkctrl_output.outclk
--);

resetmodule_inst : resetmodule
generic map
(
    HSSI_NUM => HSSI_NUM
)
port map
(
    sysclk              => sysclk,
    tx_clk              => sfp_txclk(0),
    rx_clk0             => rx_clk,
    rx_clk1             => sfp_rxclk,
    pll_lock            => '1',

    nRST_sys            => nRST_sys,
    RST_sys             => RST_sys,
    nRST_rxclk0         => nRST_rxclk0,
    nRST_rxclk1         => nRST_rxclk1,
    nRST_txclk          => nRST_sfptxclk
);

--clk_set <= sysclk&clk156M_in_groble&rx_clk(0)&rx_clk(1)&sfp_txclk(0)&sfp_rxclk(0)&rx_clk_5g&tx_clk_5g&CLKUSR&CLKUSR;

--multi_measure_inst : multi_measure
--generic map
--(
--    CLK_NUM => CLK_NUM
--)
--port map
--(
--    sysclk     => sysclk,
--    nRST_sys   => nRST_sys,
--    clk_set    => clk_set,
--    mask_out   => open,
--    clk_cnt    => open

--);

serdes_datain_inst : serdes_datain
generic map
(
    HSSI_NUM => HSSI_NUM
)
port map
(
    reconfclk                   => sysclk,
    refclk                      => clkin_156M,
    rx_serial_data              => rx_serial_data,

    rx_clk                      => rx_clk,
    rx_parallel_data            => rx_parallel_data,
    rx_control                  => rx_control,

    rx_enh_data_valid           => rx_enh_data_valid,
    rx_enh_fifo_full            => rx_enh_fifo_full,
    rx_enh_fifo_empty           => rx_enh_fifo_empty,
    rx_enh_fifo_del             => rx_enh_fifo_del,
    rx_enh_fifo_insert          => rx_enh_fifo_insert,
    rx_enh_highber              => rx_enh_highber,
    rx_enh_blk_lock             => rx_enh_blk_lock,

    phy_reset                   => RST_sys
);

serdes_dataout_inst : serdes_dataout
generic map
(
    HSSI_NUM => HSSI_NUM
)
port map
(
    reconfclk                   => sysclk,
    refclk                      => clkin_156M,
    tx_serial_sfpdata           => tx_serial_sfpdata,
    rx_serial_sfpdata           => rx_serial_sfpdata,

    sfp_txclk                  => sfp_txclk,
    xgmii_tx_data               => xgmii_tx_data,
    xgmii_tx_ctrl               => xgmii_tx_ctrl,

    sfp_rxclk                  => sfp_rxclk,
    xgmii_rx_data               => xgmii_rx_data,
    xgmii_rx_ctrl               => xgmii_rx_ctrl,

    tx_enh_data_valid           => tx_enh_data_valid_sfp,
    tx_enh_fifo_full            => tx_enh_fifo_full_sfp,
    tx_enh_fifo_pfull           => tx_enh_fifo_pfull_sfp,
    tx_enh_fifo_empty           => tx_enh_fifo_empty_sfp,
    tx_enh_fifo_pempty          => tx_enh_fifo_pempty_sfp,
    rx_enh_data_valid           => rx_enh_data_valid_sfp,
    rx_enh_fifo_full            => rx_enh_fifo_full_sfp,
    rx_enh_fifo_empty           => rx_enh_fifo_empty_sfp,
    rx_enh_fifo_del             => rx_enh_fifo_del_sfp,
    rx_enh_fifo_insert          => rx_enh_fifo_insert_sfp,
    rx_enh_highber              => rx_enh_highber_sfp,
    rx_enh_blk_lock             => rx_enh_blk_lock_sfp,

    phy_reset                   => RST_sys
);

convto_xgmii_sfp_generate : for i in  0 to HSSI_NUM-1 generate
xgmii_down_inst : convto_xgmii_sfp
port map
(
    nRST_rxclk                      => nRST_rxclk0(i),
    rx_clk                          => rx_clk(i),
    rx_parallel_data                => rx_parallel_data(64*i+63 downto 64*i),
    rx_control                      => rx_control(8*i+7 downto 8*i),

    nRST_txclk                      => nRST_sfptxclk,
    tx_clk                          => sfp_txclk(0),
    xgmii_tx_data                   => xgmii_tx_data(64*i+63 downto 64*i),
    xgmii_tx_ctrl                   => xgmii_tx_ctrl(8*i+7 downto 8*i)
);
xgmii_up_inst : convto_xgmii_sfp
port map
(
    nRST_rxclk                      => nRST_rxclk1(i),
    rx_clk                          => sfp_rxclk(i),
    rx_parallel_data                => xgmii_rx_data(64*i+63 downto 64*i),
    rx_control                      => xgmii_rx_ctrl(8*i+7 downto 8*i),

    nRST_txclk                      => nRST_rxclk1(0),
    tx_clk                          => sfp_rxclk(0),
    xgmii_tx_data                   => xgmii_rx_updata(64*i+63 downto 64*i),
    xgmii_tx_ctrl                   => xgmii_rx_upctrl(8*i+7 downto 8*i)
);

end generate convto_xgmii_sfp_generate;

led <= '0' when (rx_parallel_data_5g /= 0 and rx_control_5g /= 0) else '1';
serdes_out_5g : vidout_net5G_top
generic map
(
    HSSI_NUM5G              => HSSI_NUM5G
)
port map
(
    clk125M_in              => sysclk,
    clkin_5gsfp             => clkin_156M,
    nRST                    => nRST_sys,

    tx_parallel_data        => tx_parallel_data_5g,
    tx_control              => tx_control_5g,
    tx_clk                  => tx_clk_5g,

    rx_clk                  => rx_clk_5g,
    rx_parallel_data        => rx_parallel_data_5g,
    rx_control              => rx_control_5g,

    config_rdack            => config_rdack,
    config_rdreq            => config_rdreq,
    config_rdaddr           => config_rdaddr,
    config_rdlen            => config_rdlen,
    flash_dpram_data        => flash_dpram_data,
    flash_dpram_wraddr      => flash_dpram_wraddr,
    flash_dpram_wren        => flash_dpram_wren,

    PHYAB_RESET             => PHYAB_RESET,
    PHYAB_MDC               => PHYAB_MDC,
    PHYAB_MDIO              => PHYAB_MDIO,
    PHYCD_RESET             => PHYCD_RESET,
    PHYCD_MDC               => PHYCD_MDC,
    PHYCD_MDIO              => PHYCD_MDIO,

    tx_serial_5gdata        => tx_serial_5gdata,
    rx_serial_5gdata        => rx_serial_5gdata
);
process(sfp_txclk(0))
begin
    if rising_edge(sfp_txclk(0)) then
        if xgmii_tx_ctrl(15 downto 8) = X"01" then
            frame_head_en <= '1';
        else
            frame_head_en <= '0';
        end if;
        if frame_head_en = '1' then
            xgmii5g_fifo_data_b1(19 downto 16) <= (others => '0');
        else
            xgmii5g_fifo_data_b1(19 downto 16) <= xgmii_tx_data(19+64 downto 16+64);
        end if;
        xgmii5g_fifo_data_b1(71 downto 20) <= xgmii_tx_ctrl(15 downto 8)&xgmii_tx_data(127 downto 84);
        xgmii5g_fifo_data_b1(15 downto 0) <= xgmii_tx_data(79 downto 64);
        xgmii5g_fifo_data <= xgmii5g_fifo_data_b1;
    end if;
end process;

convto_xgmii_5g_generate : for i in  0 to HSSI_NUM5G-1 generate
process(sfp_txclk(0))
begin
    if rising_edge(sfp_txclk(0)) then
        if frame_head_en = '1' and xgmii_tx_data(19+64 downto 16+64) = i then
            xgmii5g_fifo_wren(i) <= '1';
        elsif xgmii5g_fifo_wren(i) = '1' and xgmii5g_fifo_data(71 downto 64) = X"FF" then
            xgmii5g_fifo_wren(i) <= '0';
        end if;
    end if;
end process;

convto_xgmii_5g_inst : xgmii5g_fifo
port map
(
        data    => xgmii5g_fifo_data,
        wrreq   => xgmii5g_fifo_wren(i),
        rdreq   => xgmii5g_fifo_rden(i),
        wrclk   => sfp_txclk(0),
        rdclk   => tx_clk_5g,
        q       => xgmii5g_fifo_q(i*72+71 downto i*72),
        rdempty => xgmii5g_fifo_rdempty(i)
);
xgmii5g_fifo_rden(i) <= not xgmii5g_fifo_rdempty(i);
end generate convto_xgmii_5g_generate;

process(tx_clk_5g)
begin
    if rising_edge(tx_clk_5g) then
        xgmii5g_fifo_rden_d1 <= xgmii5g_fifo_rden;
        for i in 0 to HSSI_NUM5G-1 loop
            if xgmii5g_fifo_rden_d1(i) = '1' then
                tx_parallel_data_5g(i*64+63 downto i*64) <= xgmii5g_fifo_q(i*72+63 downto i*72);
                tx_control_5g(i*8+7 downto i*8) <= xgmii5g_fifo_q(i*72+71 downto i*72+64);
            else
                tx_parallel_data_5g(i*64+63 downto i*64) <= X"0707070707070707";
                tx_control_5g(i*8+7 downto i*8) <= X"FF";
            end if;
        end loop;
    end if;
end process;


p_uart_inst : uart_param_top
generic map
(
    CONS_VER_HIGH       => CONS_VER_HIGH,
    CONS_VER_LOW        => CONS_VER_LOW,
    TXSUBCARD_TYPE      => TXSUBCARD_TYPE,
    PORT_NUM            => PORT_NUM,
    SERDES_SPEED_MSB    => SERDES_SPEED_MSB,
    SERDES_SPEED_LSB    => SERDES_SPEED_LSB,
    BAUD_DIV            => BAUD_DIV,
    HSSI_NUM            => HSSI_NUM
)
port map
(
    nRST                => nRST_sys,
    sysclk              => sysclk,
    ---uart: 2 pins of uart
    rxd_top             => rxd_frmbk,
    txd_top             => txd_tobk,
    txd_info_top        => txd_info,

    --info
    crc_info            => crc_info,

    p_Frame_en_o        => p_Frame_en_o,
    p_Wren_o            => p_Wren_o,
    p_Data_o            => p_Data_o,
    p_Addr_o            => p_Addr_o,
    cur_slot_num        => cur_slot_num,

    Up_ReadEn_o         => Up_ReadEn_o,
    Up_req              => Up_req,
    Up_ack              => Up_ack,
    Up_ReadLength_i     => Up_ReadLength_i,
    Up_ReadAddr_o       => Up_ReadAddr_o,
    Up_ReadData_i       => Up_ReadData_i

);

uart_64to8_inst : uart_64to8
generic map
(
    HSSI_NUM            => HSSI_NUM
)
port map
(
    nRST                => nRST_sys,
    sysclk              => sysclk,
    nRST_rxclk          => nRST_rxclk1(0),
    rxclk               => sfp_rxclk(0),
    xgmii_rx_updata     => xgmii_rx_updata,
    xgmii_rx_upctrl     => xgmii_rx_upctrl,
    cur_slot_num        => cur_slot_num(3 downto 0),

    Up_ReadEn_o         => Up_ReadEn_o,
    Up_req              => Up_req,
    Up_ack              => Up_ack,
    Up_ReadLength_i     => Up_ReadLength_i,
    Up_ReadAddr_o       => Up_ReadAddr_o,
    Up_ReadData_i       => Up_ReadData_i

);


crc_info(3) <= '0';
crc_info(7 downto 5) <= (others => '0');

top_update_inst : top_update
generic map
(
    FLASH_PROTECT_EN    => '1',

    FRAME_W             => 11,
    FLASH_ADDR_W_INBYTE => 25,
    FLASH_DATA_W        => 32
)
port map
(
    nRST                => nRST_sys,
    sysclk              => sysclk,
    time_ms_en          => time_ms_en_125,
    --para
    pframe_ss           => p_Frame_en_o,
    pwren               => p_Wren_o,
    paddr               => p_Addr_o,
    pdata               => p_Data_o,

    config_rdack        => config_rdack,
    config_rdreq        => config_rdreq,
    config_rdaddr       => config_rdaddr,
    config_rdlen        => config_rdlen,
    flash_dpram_data    => flash_dpram_data,
    flash_dpram_wraddr  => flash_dpram_wraddr,
    flash_dpram_wren    => flash_dpram_wren,

    update_crc_right    => crc_info(0),
    update_prog_done    => crc_info(1),
    update_crc_done     => crc_info(2),
    update_erase_done   => crc_info(4)
);

ms_g_125: time_ms_gen
generic map
(
    IS_156M =>  0   --0: 125M 1 : 156M
)
port map(
    nRST            => nRST_sys ,
    clk             => sysclk ,
    time_ms_en_o    => time_ms_en_125
);


end;
