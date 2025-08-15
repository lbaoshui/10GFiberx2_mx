library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;
use work.PCK_version_FPGA_def.all;

entity Z8_boardout is
generic
(
    SIM                 : STD_LOGIC := '0';
   -- CONS_VER_HIGH       : std_logic_vector := X"01";
   -- CONS_VER_LOW        : std_logic_vector := X"30" ;
    TXSUBCARD_TYPE      : std_logic_vector := SUBCARD_1G_FIBER;
 ---   FIBERPORT_NUM       : integer := 2;
    SERDES_SPEED_MSB    : integer := 10;
    SERDES_SPEED_LSB    : integer := 0;
    BAUD_DIV            : std_logic_vector := X"000B";
    SERDES_5G_EN        : std_logic := '0';
    SERDES_10G_EN       : std_logic := '1';
	
    DDR_NUM             : integer   := 1  ;
	DDRD_W              :  integer := 320;
	DDR_AW              :  integer := 23;
	DDR_DW              :  integer := 320;
    BURST_W             :  integer := 7  ; --with  in pxiel	
    TAGW                :  integer :=  4   ;	
    WRC_W               :  INTEGER := 53 ;  --WRITE CMD WIDTH
    CREQ_W              :  integer := 35  ; ---read command
    CRSP_W              :  integer := 44  ; ---read response for net port ,we need to add additional	

    BKHSSI_NUM          : integer := 5;		-- vid and vs data occupy 4 channels, para data occupy 1 channel
	PARA_HSSI_NUM		: integer := 1;
	ETHPORT_NUM         : integer := 10; --PER FIBER
    FIBER_NUM           : integer := 2;
    HSSI_NUM5G          : integer := 4;
    FLASH_PROTECT_EN    : std_logic:= '1';
	FLASH_PROTECT_ALL   : std_logic:= '0';---'1':protect all, '0':protect half,only protect backup
	FLASH_TYPE          : integer := 0 ;   ------0:MT25QU256, 1:MT25QU01G
	DUAL_BOOT_EN        : integer := 1
);
port
(
    CLKUSR                      : in  std_logic;
    clkin_156M_5g               : in  std_logic;
    clkin_156M_sfp              : in  std_logic;
    clkin_125M                  : in  std_logic;

    led                         : out std_logic_vector(1 downto 0);
    rxd_frmbk                   : in  std_logic;
    txd_tobk                    : out std_logic;
    txd_info                    : out std_logic;
	
	
    mem_pll_ref_clk            : in std_logic_vector(DDR_NUM-1 downto 0) ;    -- 133.0 MHz - Reference clock for DDR3
    mem_oct_rzqin              : in std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_ck                     : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_ck_n                   : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_a                      : out std_logic_vector(DDR_NUM*13-1 downto 0) ;
    mem_ba                     : out std_logic_vector(DDR_NUM *3 -1 downto 0) ;
    mem_cke                    : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_cs_n                   : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_odt                    : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_reset_n                : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_we_n                   : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_ras_n                  : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_cas_n                  : out std_logic_vector(DDR_NUM-1 downto 0) ;
    mem_dqs                    : inout std_logic_vector(DDR_NUM *5 -1 downto 0);
    mem_dqs_n                  : inout std_logic_vector(DDR_NUM *5 -1 downto 0);
    mem_dq                     : inout std_logic_vector(DDR_NUM *40 -1 downto 0);
    mem_dm                     : out std_logic_vector(DDR_NUM *5 -1 downto 0)  ;	
	
    --PHYAB_RESET                 : out   std_logic ;
    --PHYAB_MDC                   : out   std_logic ;
    --PHYAB_MDIO                  : inout std_logic ;
    --PHYCD_RESET                 : out   std_logic ;
    --PHYCD_MDC                   : out   std_logic ;
    --PHYCD_MDIO                  : inout std_logic ;
    --tx_serial_5gdata            : out   std_logic_vector (HSSI_NUM5G-1 downto 0);
    --rx_serial_5gdata            : in    std_logic_vector (HSSI_NUM5G-1 downto 0);

    rx_serial_data              : in std_logic_vector(BKHSSI_NUM-1 downto 0)  := (others => 'X');		-- channel 0~3 is vid and vs data, channel 4 is para data

    tx_serial_sfpdata           : out std_logic_vector(FIBER_NUM-1 downto 0);
    rx_serial_sfpdata           : in  std_logic_vector(FIBER_NUM-1 downto 0)   := (others => 'X')

);
end Z8_boardout;

architecture behaviour of Z8_boardout is

constant VID_HSSI_NUM		: integer		:= BKHSSI_NUM- PARA_HSSI_NUM;
signal txd_autolight : std_logic ;

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
signal config_rdreq            :  std_logic:='0';
signal config_rdaddr           :  std_logic_vector(24 downto 0);
signal config_rdlen            :  std_logic_vector(12 downto 0);
signal flash_dpram_data        :  std_logic_vector(31 downto 0);
signal flash_dpram_wraddr      :  std_logic_vector(8 downto 0);
signal flash_dpram_wren        :  std_logic;

-- signal tx_parallel_data_5g : std_logic_vector(8*8*HSSI_NUM5G-1 downto 0);
-- signal tx_control_5g : std_logic_vector(8*HSSI_NUM5G-1 downto 0);
-- signal tx_clk_5g : std_logic;
-- signal rx_parallel_data_5g : std_logic_vector(8*8*HSSI_NUM5G-1 downto 0);
-- signal rx_control_5g : std_logic_vector(8*HSSI_NUM5G-1 downto 0);
-- signal rx_clk_5g : std_logic_vector(HSSI_NUM5G-1 downto 0);

component main_pll is
port (
	rst      : in  std_logic := 'X'; -- reset
	refclk   : in  std_logic := 'X'; -- clk
	locked   : out std_logic;        -- export
	outclk_0 : out std_logic         -- clk
);
end component main_pll;

signal RST              : std_logic;
signal led_cnt          : std_logic_vector(23 downto 0) := (others=>'0');
signal main_pll_locked  : std_logic;
signal sysclk           : std_logic := '0';

component resetmodule is
generic
(
    FIBER_NUM : integer ;
    BKHSSI_NUM : integer
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
end component;

signal nRST_sys            : std_logic;
signal RST_sys             : std_logic;
signal nRST_bk_rxclk         : std_logic_vector(BKHSSI_NUM-1 downto 0);
signal nRST_rxclk1         : std_logic_vector(FIBER_NUM-1 downto 0);
signal nRST_sfptxclk       : std_logic;

constant CLK_NUM : integer:=7;

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
    BKHSSI_NUM : integer := 2
);
port
(
    reconfclk                   : in std_logic;
    refclk                      : in std_logic;
    rx_serial_data              : in std_logic_vector(BKHSSI_NUM-1 downto 0)  := (others => 'X');

    rx_clk                      : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_parallel_data            : out std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_control                  : out std_logic_vector(BKHSSI_NUM*8-1 downto 0);

    rx_enh_data_valid           : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_full            : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_empty           : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_del             : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_fifo_insert          : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_highber              : out std_logic_vector(BKHSSI_NUM-1 downto 0);
    rx_enh_blk_lock             : out std_logic_vector(BKHSSI_NUM-1 downto 0);

    phy_reset                   : in std_logic;
	serdes_rxlock               : out std_logic_vector(BKHSSI_NUM-1 downto 0)
);
end component;

signal rx_bk_clk               :   std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_bk_parallel_data        :   std_logic_vector(BKHSSI_NUM*64-1 downto 0);
signal rx_bk_control              :   std_logic_vector(BKHSSI_NUM*8-1 downto 0);
signal	serdes_rxlock             :   std_logic_vector(BKHSSI_NUM-1 downto 0);

signal  nRST_bk2fiber_clk      :   std_logic := '0';
signal  bk2fiber_clk           :   std_logic := '0';
signal  bk2fiber_parallel_data :   std_logic_vector(FIBER_NUM*64-1 downto 0);
signal  bk2fiber_control       :   std_logic_vector(FIBER_NUM*8-1 downto 0);


signal rx_bk_enh_data_valid       :   std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_bk_enh_fifo_full        :   std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_bk_enh_fifo_empty       :   std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_bk_enh_fifo_del         :   std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_bk_enh_fifo_insert      :   std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_bk_enh_highber          :   std_logic_vector(BKHSSI_NUM-1 downto 0);
signal rx_bk_enh_blk_lock         :   std_logic_vector(BKHSSI_NUM-1 downto 0);

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
    rx_serial_sfpdata           : in std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');

    sfp_txclk                   : out std_logic;
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

signal fiber_link                  : std_logic_vector(FIBER_NUM-1 downto 0);

signal sfp_txclk                   : std_logic;
signal xgmii_tx_data               : std_logic_vector(FIBER_NUM*64-1 downto 0);
signal xgmii_tx_ctrl               : std_logic_vector(FIBER_NUM*8-1 downto 0);
signal sfp_rxclk                   : std_logic_vector(FIBER_NUM-1 downto 0);
signal xgmii_rx_data               : std_logic_vector(FIBER_NUM*64-1 downto 0);
signal xgmii_rx_ctrl               : std_logic_vector(FIBER_NUM*8-1 downto 0);
signal xgmii_rx_updata             : std_logic_vector(FIBER_NUM*64-1 downto 0);
signal xgmii_rx_upctrl             : std_logic_vector(FIBER_NUM*8-1 downto 0);


signal tx_enh_data_valid_sfp       : std_logic_vector(FIBER_NUM-1 downto 0) := (others => '1');
signal tx_enh_fifo_full_sfp        : std_logic_vector(FIBER_NUM-1 downto 0);
signal tx_enh_fifo_pfull_sfp       : std_logic_vector(FIBER_NUM-1 downto 0);
signal tx_enh_fifo_empty_sfp       : std_logic_vector(FIBER_NUM-1 downto 0);
signal tx_enh_fifo_pempty_sfp      : std_logic_vector(FIBER_NUM-1 downto 0);
signal rx_enh_data_valid_sfp       : std_logic_vector(FIBER_NUM-1 downto 0);
signal rx_enh_fifo_full_sfp        : std_logic_vector(FIBER_NUM-1 downto 0);
signal rx_enh_fifo_empty_sfp       : std_logic_vector(FIBER_NUM-1 downto 0);
signal rx_enh_fifo_del_sfp         : std_logic_vector(FIBER_NUM-1 downto 0);
signal rx_enh_fifo_insert_sfp      : std_logic_vector(FIBER_NUM-1 downto 0);
signal rx_enh_highber_sfp          : std_logic_vector(FIBER_NUM-1 downto 0);
signal rx_enh_blk_lock_sfp         : std_logic_vector(FIBER_NUM-1 downto 0);

component convto_xgmii_sfp is
generic
(
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
end component;

component para_serdes_top is
generic
(
	PARA_HSSI_NUM			: integer		:= 1
);
port
(
	nRST_sys				: in std_logic;
	sysclk					: in std_logic;
	
    xgm_rstn	         	: in std_logic;
    xgmclk	             	: in std_logic;
    xgm_rx_data			   	: in std_logic_vector(PARA_HSSI_NUM*64-1 downto 0);
    xgm_rx_k	         	: in std_logic_vector(PARA_HSSI_NUM*8 -1 downto 0);
	
	frame_ss				: out std_logic;                    
    rx_data_vld				: out std_logic;                    
    rx_data					: out std_logic_vector(7 downto 0);
	
	clr_serdesinfo_sys		: in std_logic;
	serdes_pck_cnt_sys		: out std_logic_vector(32-1 downto 0);
	serdes_fe_cnt_sys		: out std_logic_vector(16-1 downto 0);
	serdes_crc_err_sys		: out std_logic_vector(16-1 downto 0)

);
end component;

signal serdes_frame_ss_sys				: std_logic						:='0';
signal serdes_rx_vld_sys				: std_logic						:='0';
signal serdes_rxd_sys					: std_logic_vector(7 downto 0)	:=(others => '0');
signal clr_serdesinfo_sys				: std_logic						:='0';


component uart_param_top is
generic
(
    CONS_VER_HIGH       : std_logic_vector(7  downto 0);
    CONS_VER_LOW        : std_logic_vector(7  downto 0);
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0);
    FIBERPORT_NUM       : integer;
    ETHPORT_NUM         : integer; --PER FIBER
    SERDES_SPEED_MSB    : integer;
    SERDES_SPEED_LSB    : integer;
    BAUD_DIV            : std_logic_vector(15 downto 0);
	DDR_NUM             : integer
    ---HSSI_NUM            : integer:= 2
);
port
(
    ---to reduce the clock domain in HDMI region
	nRST_cmd        : in std_logic ;
	cmd_clk         : in std_logic;

    p_Frame_en_cmd    : out std_logic ;
    p_Wren_cmd        : out std_logic ;
    p_Data_cmd        : out std_logic_vector(7 downto 0);
    p_Addr_cmd        : out std_logic_vector(10 downto 0);
   cur_slot_num_cmd   : out std_logic_vector(15  downto 0);
   ---------------------------------

    nRST            : in std_logic ;
    sysclk          : in std_logic;
	
	serdes_frame_ss		: in std_logic;
	serdes_rx_vld		: in std_logic;
	serdes_rx_data		: in std_logic_vector(7 downto 0);

    ---uart: 2 pins of uart
    rxd_top         : in  std_logic ;  --from top pad
    txd_top         : out std_logic ; ---to top pad
    txd_info_top    : out std_logic ; ---to top pad
    txd_autolight   : OUT std_logic   ; --to top pad 
    --info
    err_num         : in std_logic_vector(63 downto 0);
    err_num_fiber   : in std_logic_vector(63 downto 0);
    crc_info        : in std_logic_vector(7 downto 0);
    eth_link        : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    fiber_link      : in std_logic_vector(FIBERPORT_NUM-1 downto 0);

    time_ms_en_sys   : in std_logic ;
    autobright_en    : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    autobright_val   : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM*8-1 downto 0);


    p_Frame_en_o    : out std_logic ;
    p_Wren_o        : out std_logic ;
    p_Data_o        : out std_logic_vector(7 downto 0);
    p_Addr_o        : out std_logic_vector(10 downto 0);
    cur_slot_num    : out std_logic_vector(15 downto 0);

	get_curr_temp_phy_sys : in std_logic_vector(FIBERPORT_NUM*16-1 downto 0);

	Up_cmd_fifo_empty_sys  : in std_logic_vector(FIBERPORT_NUM-1 downto 0); 
	Up_cmd_fifo_rden_sys   : out  std_logic_vector(FIBERPORT_NUM-1 downto 0); 
	Up_cmd_fifo_q_sys      : in std_logic_vector(FIBERPORT_NUM*29-1 downto 0);
    Up_ReadAddr_sys        : out  std_logic_vector(11 downto 0);
    Up_ReadData_sys        : in std_logic_vector(FIBERPORT_NUM*8-1 downto 0) ;
	
	backup_flag_sys      : in std_logic_vector(3 downto 0);
	error_check_num_sys     : in std_logic_vector(VID_HSSI_NUM*16-1 downto 0);		-- only need to upload info of 4 vid serdes
	subbrdin_packet_cnt_sys : in std_logic_vector(VID_HSSI_NUM*32-1 downto 0);
	error_fe_num_sys        : in std_logic_vector(VID_HSSI_NUM*16-1 downto 0);
	serdes_rxlock           : in std_logic_vector(BKHSSI_NUM-1 downto 0);
	
	real_eth_num_sys         : in std_logic_vector(3 downto 0);
	ddr_verify_end_sys       : in std_logic_vector(DDR_NUM-1 downto 0);
	ddr_verify_success_sys   : in std_logic_vector(DDR_NUM-1 downto 0)

);
end component;
signal err_num          : std_logic_vector(63 downto 0);

signal Up_ReadEn_o      : std_logic;
signal Up_req           : std_logic_vector(FIBER_NUM-1 downto 0);
signal Up_ack           : std_logic_vector(FIBER_NUM-1 downto 0);
signal Up_end           : std_logic_vector(FIBER_NUM-1 downto 0);
signal Up_ReadLength_i  : std_logic_vector(11*FIBER_NUM-1 downto 0);
signal Up_ReadAddr_o    : std_logic_vector(11 downto 0);
signal Up_ReadData_i    : std_logic_vector(8*FIBER_NUM-1 downto 0);

signal p_Frame_en_o     : std_logic;
signal p_Wren_o         : std_logic;
signal p_Data_o         : std_logic_vector(7 downto 0);
signal p_Addr_o         : std_logic_vector(10 downto 0);
signal cur_slot_num_sys : std_logic_vector(15 downto 0);
signal crc_info         : std_logic_vector(7 downto 0) := (others => '0');

component top_update is
generic(
    FLASH_PROTECT_EN                    : std_logic:= '1';
	FLASH_PROTECT_ALL                   : std_logic:= '0';---'1':protect all, '0':protect half,only protect backup
	FLASH_TYPE                          : integer := 0 ;   ------0:MT25QU256, 1:MT25QU01G

    FRAME_W                             : integer:= 12;
    FLASH_ADDR_W_INBYTE                 : integer:= 25;
    FLASH_DATA_W                        : integer:= 32;
	DUAL_BOOT_EN                        : integer := 1
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
    PORTNUM_EVERY_FIBER : integer:= 10;
    HSSI_NUM            : integer:= 2;
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0)
);
port
(
    nRST                : in  std_logic;
    sysclk              : in  std_logic;
    nRST_rxclk          : in  std_logic_vector(HSSI_NUM-1 downto 0);
    rxclk               : in  std_logic_vector(HSSI_NUM-1 downto 0);
    nRST_txclk          : in  std_logic;
    txclk               : in  std_logic;
	nRST_convclk        : in  std_logic;
	convclk_i           : in  std_logic;
    xgmii_tx_data       : in  std_logic_vector(HSSI_NUM*64-1 downto 0);
    xgmii_tx_ctrl       : in  std_logic_vector(HSSI_NUM*8-1 downto 0);
    xgmii_rx_updata     : in  std_logic_vector(HSSI_NUM*64-1 downto 0);
    xgmii_rx_upctrl     : in  std_logic_vector(HSSI_NUM*8-1 downto 0);
    cur_slot_num_sys    : in  std_logic_vector(3 downto 0);

    eth_link_sys            : out std_logic_vector(HSSI_NUM*ETHPORT_NUM-1 downto 0);
    -- err_num_fiber_sys       : out std_logic_vector(HSSI_NUM*32-1 downto 0);
    subframe_FB_serdrx             : out std_logic_vector(HSSI_NUM-1 downto 0);
    autolight_outen_sys     : out std_logic_vector(PORTNUM_EVERY_FIBER*HSSI_NUM-1 downto 0);
    autolight_outval_sys    : out std_logic_vector(PORTNUM_EVERY_FIBER*8*HSSI_NUM-1 downto 0);
    
    up08_timeout_notify  : out std_logic_vector(HSSI_NUM-1 downto 0) ;---time out now ......
    Up08_startimer       : in  std_logic_vector(HSSI_NUM-1 downto 0) ; --NOTIFY ,turn signal ,0to1 or  1to0 
    Up08_net_rel_idx_conv : in  std_logic_vector(8-1 downto 0) ; 
    quick08_wren_convclk         :  in std_logic  ;
    quick08_waddr_convclk        :  in std_logic_vector(10 downto 0);
    quick08_wdata_convclk        :  in std_logic_vector( 7 downto 0);
    quick08_flg          :  in std_logic_vector(HSSI_NUM-1 downto 0);
    quick08_filter_en    :  in std_logic_vector(HSSI_NUM-1 downto 0);--up 08 filtered or not -----
    quick08_addr_len     :  in std_logic_vector(7 downto 0);    
  
	Up_cmd_fifo_empty_sys  : out std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_rden_sys   : in  std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_q_sys      : out std_logic_vector(HSSI_NUM*29-1 downto 0);
    Up_ReadAddr_sys        : in  std_logic_vector(11 downto 0);
    Up_ReadData_sys        : out std_logic_vector(HSSI_NUM*8-1 downto 0) ;
	
	real_eth_num_sys       : in  std_logic_vector(3 downto 0)

);
end component;

signal	Up_cmd_fifo_empty_sys  : std_logic_vector(FIBER_NUM-1 downto 0); 
signal	Up_cmd_fifo_rden_sys   : std_logic_vector(FIBER_NUM-1 downto 0); 
signal	Up_cmd_fifo_q_sys      : std_logic_vector(FIBER_NUM*29-1 downto 0);
signal  Up_ReadAddr_sys        : std_logic_vector(11 downto 0);
signal  Up_ReadData_sys        : std_logic_vector(FIBER_NUM*8-1 downto 0) ;
	
	
signal	over_2ms_en         :  std_logic_vector(FIBER_NUM-1 downto 0);
SIGNAL   autolight_outen_sys     :   std_logic_vector(ETHPORT_NUM*FIBER_NUM-1 downto 0);
SIGNAL   autolight_outval_sys    :   std_logic_vector(ETHPORT_NUM*8*FIBER_NUM-1 downto 0);
signal   up08_timeout_conv        :   std_logic_vector(FIBER_NUM-1 downto 0) ;---time out now ......
signal   Up08_startimer_conv      :    std_logic_vector(FIBER_NUM-1 downto 0) ; 
signal   Up08_net_rel_idx_conv    :    std_logic_vector(8-1 downto 0) ; 
 
signal subframe_FB_serdrx      : std_logic_vector(FIBER_NUM-1 downto 0);
signal subframe_FB_d1   : std_logic_vector(FIBER_NUM-1 downto 0 ) := (others=>'0');
signal subframe_FB_d2   : std_logic_vector(FIBER_NUM-1 downto 0 ) := (others=>'0');
signal subframe_FB_d3   : std_logic_vector(FIBER_NUM-1 downto 0 ) := (others=>'0');
signal dly_cnt          : std_logic_vector(FIBER_NUM*30-1 downto 0);
signal eth_link_sys         : std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
signal err_num_fiber_sys    : std_logic_vector(FIBER_NUM*32-1 downto 0);

component time_ms_gen is
generic
(
 IS_156M: integer := 0   --0: 125M 1 : 156M
);
port ( nRST         : in  std_logic  ;
       clk          : in std_logic ;
       time_ms_en_o : out std_logic;
       --conv domain
       nRST_conv      : in  std_logic ;
       conv_clk       : in  std_logic ;
       time_ms_en_conv: out std_logic 
     );
end component;

signal time_ms_en_conv : std_logic;
signal time_ms_en_125  : std_logic;

component altclkctrl is
port (
    inclk  : in  std_logic := 'X'; -- inclk
    outclk : out std_logic         -- outclk
);
end component altclkctrl;
signal clk125M_in_groble : std_LOGIC;
signal clk156M_in_groble : std_LOGIC;

signal    nRST_conv          :   std_logic ;
signal	  clk_conv           :   std_logic;
signal    p_Frame_en_conv    :  std_logic ;
signal    p_Wren_conv        :  std_logic ;
signal    p_Data_conv        :  std_logic_vector(7 downto 0);
signal    p_Addr_conv        :  std_logic_vector(10 downto 0);
signal    cur_slot_num_conv  :  std_logic_vector(15 downto 0);

 ---conv clock domain 
signal   unit_connected_conv       :  std_logic_vector(FIBER_NUM-1 DOWNTO 0); --the unit is connected ;
signal   eth_connected_conv        :  std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);    ------
     --conv clock domain 
signal   quick08_wren_conv         :   std_logic  ;
signal   quick08_waddr_conv        :   std_logic_vector(10 downto 0);
signal   quick08_wdata_conv        :   std_logic_vector( 7 downto 0);
 
    

component bk2fiber_conv is
generic
(  SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic := '0';
   FIBER_NUM         : integer   ;
   ETHPORT_NUM       : integer   := 10 ;  -- PER FIBER
   BKHSSI_NUM        : integer

);
port
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);


    nRST_conv           : in  std_logic    ; ---
    convclk_i              : in  std_logic    ; --200M almost
    time_ms_en_conv         : in std_logic ;
    p_Frame_en_conv         : in std_logic ;
    p_Wren_conv           : in std_logic ;
    p_Data_conv           : in std_logic_vector(7 downto 0);
    p_Addr_conv           : in std_logic_vector(10 downto 0);
    cur_slot_num         : in std_logic_vector(15 downto 0);
    
     ---conv clock domain 
    unit_connected_conv       : in  std_logic_vector(FIBER_NUM-1 DOWNTO 0); --the unit is connected ;
    eth_connected_conv        : in  std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);    ------
    up08_start_timer_conv     :  out std_logic_vector(FIBER_NUM-1 DOWNTO 0);  --NOTIFY ,one pulse only  
    Up08_net_rel_idx_conv     :  out std_logic_vector(8-1 DOWNTO 0);  --NOTIFY ,one pulse only  
    up08_timeout_conv         :  in  std_logic_vector(FIBER_NUM-1 downto 0);  --every unit up one 
    --conv clock domain  
    xgmii_txclk          : in  std_logic; ---_vector(FIBER_NUM-1 downto 0) ;
    nRST_xgmii           : in  std_logic; ---_vector(FIBER_NUM-1 downto 0) ;
    xgmii_data           : out std_logic_vector(FIBER_NUM*64-1 downto 0);
    xgmii_control        : out std_logic_vector(FIBER_NUM*8 -1 downto 0);
	trigger_forrecon_convclk : out std_logic;
	
	sysclk                   : in std_logic;
	nRST_sys                 : in std_logic;
    p_Frame_en_sys           : in std_logic ;
    p_Wren_sys               : in std_logic ;
    p_Data_sys               : in std_logic_vector(7 downto 0);
    p_Addr_sys               : in std_logic_vector(10 downto 0);
    quick08_wren_conv         :  out std_logic  ;
    quick08_waddr_conv        :  out std_logic_vector(10 downto 0);
    quick08_wdata_conv        :  out std_logic_vector( 7 downto 0);
    quick08_flg_conv          :  out std_logic_vector(FIBER_NUM-1 downto 0)  ;
    quick08_filter_en_conv    :  out std_logic_vector(FIBER_NUM-1 downto 0)  ;  --up 08 filtered or not -----
    quick08_addr_len_conv     :  out std_logic_vector(7 downto 0);   
    
	backup_flag_sys      : out std_logic_vector(3 downto 0);
	error_check_num_sys     : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);
	subbrdin_packet_cnt_sys : out std_logic_vector(BKHSSI_NUM*32-1 downto 0);
	error_fe_num_sys        : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);
	
	shutter_rsp_dvld              : in  std_logic_vector(FIBER_NUM-1 downto 0);
	shutter_rsp_data              : in  std_logic_vector(72-1 downto 0);
	shutter_rd_eth_index          : out std_logic_vector(FIBER_NUM*4-1 downto 0);
	shutter_rd_frm_index          : out std_logic_vector(FIBER_NUM*15-1 downto 0);
	shutter_rd_req                : out std_logic_vector(FIBER_NUM-1 downto 0);
	shutter_rd_ack                : in  std_logic_vector(FIBER_NUM-1 downto 0)	;	
	shutter_rd_frmvld             : in  std_logic_vector(FIBER_NUM-1 downto 0);
	shutter_rd_end                : in  std_logic_vector(FIBER_NUM-1 downto 0);
	
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)
	
);
end component ;
signal 	trigger_forrecon_convclk :  std_logic;
signal	error_check_num_sys     :  std_logic_vector(BKHSSI_NUM*16-1 downto 0);
signal	subbrdin_packet_cnt_sys :  std_logic_vector(BKHSSI_NUM*32-1 downto 0);
signal	error_fe_num_sys        :  std_logic_vector(BKHSSI_NUM*16-1 downto 0);

signal   quick08_flg_conv          :    std_logic_vector(FIBER_NUM-1 downto 0)  ;
signal   quick08_filter_en_conv    :    std_logic_vector(FIBER_NUM-1 downto 0)  ;  --up 08 filtered or not -----
signal   quick08_addr_len_conv     :    std_logic_vector(7 downto 0); 

signal	backup_flag_sys      :  std_logic_vector(3 downto 0):=(others=>'0');

signal	shutter_rsp_dvld              :  std_logic_vector(FIBER_NUM-1 downto 0);
signal	shutter_rsp_data              :  std_logic_vector(72-1 downto 0);
signal	shutter_rd_eth_index          :  std_logic_vector(FIBER_NUM*4-1 downto 0);
signal	shutter_rd_frm_index          :  std_logic_vector(FIBER_NUM*15-1 downto 0);
signal	shutter_rd_req                :  std_logic_vector(FIBER_NUM-1 downto 0);
signal	shutter_rd_ack                :  std_logic_vector(FIBER_NUM-1 downto 0)	;
signal	shutter_rd_frmvld             :  std_logic_vector(FIBER_NUM-1 downto 0);
signal	shutter_rd_end                :  std_logic_vector(FIBER_NUM-1 downto 0)	;
	

component altera_a10_xcvr_clock_module  is
 port   (clk_in : in std_logic );
end component ;


component ed_synth_emif_0 is
    port (

        --pll_extra_clk_0     : out   std_logic;
        --------------------------------------------------
        amm_ready_0         : out   std_logic;                                         -- waitrequest_n
        amm_read_0          : in    std_logic                      := 'X';             -- read
        amm_write_0         : in    std_logic                      := 'X';             -- write
        amm_address_0       : in    std_logic_vector(22 downto 0)  := (others => 'X'); -- address
        amm_readdata_0      : out   std_logic_vector(319 downto 0);                    -- readdata
        amm_writedata_0     : in    std_logic_vector(319 downto 0) := (others => 'X'); -- writedata
        amm_burstcount_0    : in    std_logic_vector(6 downto 0)   := (others => 'X'); -- burstcount
        amm_byteenable_0    : in    std_logic_vector(39 downto 0)  := (others => 'X'); -- byteenable
        amm_readdatavalid_0 : out   std_logic;                                         -- readdatavalid
        emif_usr_clk        : out   std_logic;                                         -- clk
        emif_usr_reset_n    : out   std_logic;                                         -- reset_n
        global_reset_n      : in    std_logic                      := 'X';             -- reset_n
        mem_ck              : out   std_logic_vector(0 downto 0);                      -- mem_ck
        mem_ck_n            : out   std_logic_vector(0 downto 0);                      -- mem_ck_n
        mem_a               : out   std_logic_vector(12 downto 0);                     -- mem_a
        mem_ba              : out   std_logic_vector(2 downto 0);                      -- mem_ba
        mem_cke             : out   std_logic_vector(0 downto 0);                      -- mem_cke
        mem_cs_n            : out   std_logic_vector(0 downto 0);                      -- mem_cs_n
        mem_odt             : out   std_logic_vector(0 downto 0);                      -- mem_odt
        mem_reset_n         : out   std_logic_vector(0 downto 0);                      -- mem_reset_n
        mem_we_n            : out   std_logic_vector(0 downto 0);                      -- mem_we_n
        mem_ras_n           : out   std_logic_vector(0 downto 0);                      -- mem_ras_n
        mem_cas_n           : out   std_logic_vector(0 downto 0);                      -- mem_cas_n
        mem_dqs             : inout std_logic_vector(4 downto 0)   := (others => 'X'); -- mem_dqs
        mem_dqs_n           : inout std_logic_vector(4 downto 0)   := (others => 'X'); -- mem_dqs_n
        mem_dq              : inout std_logic_vector(39 downto 0)  := (others => 'X'); -- mem_dq
        mem_dm              : out   std_logic_vector(4 downto 0);                      -- mem_dm
        oct_rzqin           : in    std_logic                      := 'X';             -- oct_rzqin
        pll_ref_clk         : in    std_logic                      := 'X';             -- clk
        local_cal_success   : out   std_logic;                                         -- local_cal_success
        local_cal_fail      : out   std_logic                                          -- local_cal_fail
    );
end component ed_synth_emif_0;


component shutter_ddr3_op is 
generic 
(  
	DDRD_W      :  integer := 320;
	DDR_AW      :  integer := 23;
	DDR_DW      :  integer := 320;
	DDR_NUM     :  integer := 1;
    BURST_W     :  integer := 7  ; --with  in pxiel	
    TAGW        :  integer :=  4   ;	
    WRC_W       :  INTEGER := 53 ;  --WRITE CMD WIDTH
    CREQ_W      :  integer := 35  ; ---read command
    CRSP_W      :  integer := 41  ; ---read response for net port ,we need to add additional	
	GRP_NUM     :  integer := 2;
	GRP_SIZE    :  integer := 2

);
port  
(
    nRST                    : in  std_logic ;
    clk                     : in  std_logic ;
	                        
	pframe_en               : in  std_logic;
	pwren                   : in  std_logic;
	paddr                   : in  std_logic_vector(10 downto 0);
	pdata                   : in  std_logic_vector(7 downto 0);
	
    global_reset_n          : out std_logic_vector(DDR_NUM-1 downto 0); ---reset the ddr control & recalib
    ddr3_pll_locked         : in  std_logic_vector(DDR_NUM-1 downto 0);
    local_cal_success       : in  std_logic_vector(DDR_NUM-1 downto 0) ; ----,   //           status.local_cal_success, When high, indicates that PHY calibration was successful
    local_cal_fail          : in  std_logic_vector(DDR_NUM-1 downto 0) ; ----,      //                 .local_cal_fail,    When high, indicates that PHY calibration failed
    emif_usr_reset_n        : in  std_logic_vector(DDR_NUM-1 downto 0) ; ----,    // emif_usr_reset_n.reset_n,           Reset for the user clock domain. Asynchronous assertion and synchronous deassertion
    emif_usr_clk            : in  std_logic_vector(DDR_NUM-1 downto 0) ; ----,        //     emif_usr_clk.clk,               User clock domain
    amm_ready_0             : in  std_logic_vector(DDR_NUM-1 downto 0) ; ---- '1' : ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
    amm_read_0              : out std_logic_vector(DDR_NUM-1 downto 0)           ; ---- active high ,          //                 .read,              Read request signal
    amm_write_0             : out std_logic_vector(DDR_NUM-1 downto 0)           ; ---- active high,         //                 .write,             Write request signal
    amm_address_0           : out std_logic_vector(DDR_NUM*DDR_AW-1 downto 0); --[22:0]    ; ----   ,       //                 .address,           Address for the read/write request
    amm_readdata_0          : in  std_logic_vector(DDR_NUM*DDR_DW-1 downto 0); --[319:0]   ; ----   ,      //                 .readdata,          Read data
    amm_writedata_0         : out std_logic_vector(DDR_NUM*DDR_DW-1 downto 0); -- [319:0]  ; ----   ,     //                 .writedata,         Write data
    amm_burstcount_0        : out std_logic_vector(DDR_NUM*BURST_W-1 DOWNTO 0); -- [6:0]    ; ----       ,    //                 .burstcount,        Number of transfers in each read/write burst
    amm_byteenable_0        : out std_logic_vector(DDR_NUM*(DDR_DW/8)-1 Downto 0); -- [39:0]   ; ----       ,    //                 .byteenable,        Byte-enable for write data
    amm_readdatavalid_0     : in  std_logic_vector(DDR_NUM-1 downto 0)       ;
	
	shutter_rsp_dvld        : out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rsp_data        : out std_logic_vector(72-1 downto 0);
	shutter_rd_eth_index    : in  std_logic_vector(GRP_NUM*4-1 downto 0);
	shutter_rd_frm_index    : in  std_logic_vector(GRP_NUM*15-1 downto 0);
	shutter_rd_req          : in  std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_ack          : out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_end          :  out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_frmvld       :  out std_logic_vector(GRP_NUM-1 downto 0)	;
	
	real_eth_num_conv       :  in  std_logic_vector(3 downto 0);
	ddr_verify_end_o        : out std_logic_vector(DDR_NUM-1 downto 0);
	ddr_verify_success_o    : out std_logic_vector(DDR_NUM-1 downto 0)	
	
				
);
end component ;

signal   ddr3_global_reset_n       :   std_logic_vector(DDR_NUM-1 downto 0); ---reset the ddr control & recalib
signal   ddr3_pll_locked           :   std_logic_vector(DDR_NUM-1 downto 0) := (others=>'1');
signal   emif_usr_reset_n          :   std_logic_vector(DDR_NUM-1 downto 0) ; ----,    // emif_usr_reset_n.reset_n,           Reset for the user clock domain. Asynchronous assertion and synchronous deassertion
signal   emif_usr_clk              :   std_logic_vector(DDR_NUM-1 downto 0) ; ----,        //     emif_usr_clk.clk,               User clock domain
signal   ddr3_amm_ready_0          :   std_logic_vector(DDR_NUM-1 downto 0) ; ---- '1' : ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
signal   ddr3_amm_read_0           :   std_logic_vector(DDR_NUM-1 downto 0)           ; ---- active high ,          //                 .read,              Read request signal
signal   ddr3_amm_write_0          :   std_logic_vector(DDR_NUM-1 downto 0)           ; ---- active high,         //                 .write,             Write request signal
signal   ddr3_amm_address_0        :   std_logic_vector(DDR_NUM*DDR_AW-1 downto 0); --[22:0]    ; ----   ,       //                 .address,           Address for the read/write request
signal   ddr3_amm_readdata_0       :   std_logic_vector(DDR_NUM*DDR_DW-1 downto 0); --[319:0]   ; ----   ,      //                 .readdata,          Read data
signal   ddr3_amm_writedata_0      :   std_logic_vector(DDR_NUM*DDR_DW-1 downto 0); -- [319:0]  ; ----   ,     //                 .writedata,         Write data
signal   ddr3_amm_burstcount_0     :   std_logic_vector(DDR_NUM*BURST_W-1 DOWNTO 0); -- [6:0]    ; ----       ,    //                 .burstcount,        Number of transfers in each read/write burst
signal   ddr3_amm_byteenable_0     :   std_logic_vector(DDR_NUM*(DDR_DW/8)-1 Downto 0); -- [39:0]   ; ----       ,    //                 .byteenable,        Byte-enable for write data
signal   ddr3_amm_readdatavalid_0  :   std_logic_vector(DDR_NUM-1 downto 0)       ;

signal   ddr3_local_cal_success    : std_logic_vector(DDR_NUM-1 downto 0) :=(others=>'0');
signal   ddr3_local_cal_fail       : std_logic_vector(DDR_NUM-1 downto 0) :=(others=>'0');
  
signal   real_eth_num_conv         : std_logic_vector(3 downto 0):=(others=>'0');
signal   real_eth_num_sys          : std_logic_vector(3 downto 0):=(others=>'0');
signal   eth_set_en                : std_logic;

signal	ddr_verify_end_emif           : std_logic_vector(DDR_NUM-1 downto 0);
signal	ddr_verify_success_emif       : std_logic_vector(DDR_NUM-1 downto 0);
  
signal	ddr_verify_end_sys            : std_logic_vector(DDR_NUM-1 downto 0);
signal	ddr_verify_success_sys        : std_logic_vector(DDR_NUM-1 downto 0);

component cross_domain is 
	generic (
	   DATA_WIDTH: integer:=8 
	);
	port 
	(   clk0      : in std_logic;
		nRst0     : in std_logic;		
		datain    : in std_logic_vector(DATA_WIDTH-1 downto 0);
		datain_req: in std_logic;
		
		clk1: in std_logic;
		nRst1: in std_logic;
		data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
		dataout_valid:out std_logic  ---just pulse only
	);
end component ;

component altera_std_synchronizer is  
  port   
     (
		clk : in std_logic ;
		reset_n : in std_logic ; 
		din     : in std_logic ;
		dout    : out std_logic
				);  
end component; 

begin


 main_pll_inst : main_pll
 port map
 (
 	rst      => RST_sys        ,        -- reset
 	refclk   => clkin_125M     ,  ----clkin_156M,        -- clk
 	locked   => main_pll_locked,        -- export
 	outclk_0 => clk_conv        -- clk
 );
sysclk <= clkin_125M;
--altclkctrl_inst : altclkctrl
--port map (
--    inclk  => clkin_156M,  --  altclkctrl_input.inclk
--    outclk => clk156M_in_groble  -- altclkctrl_output.outclk
--);
--clk156M_in_groble <= clkin_156M;

c100_ie: if SIM = '0' generate
clkusr_i: altera_a10_xcvr_clock_module
    port map( clk_in =>CLKUSR);
end generate c100_ie;

resetmodule_inst : resetmodule
generic map
(
    FIBER_NUM  => FIBER_NUM,
    BKHSSI_NUM => BKHSSI_NUM
)
port map
(
    sysclk              => sysclk,
    tx_clk              => sfp_txclk,
    rx_clk0             => rx_bk_clk,
    rx_clk1             => sfp_rxclk,
    pll_lock            => '1',

    conv_clk            => clk_conv  ,
    nRST_conv           => nRST_conv ,


    nRST_sys            => nRST_sys,
    RST_sys             => RST_sys,
    nRST_rxclk0         => nRST_bk_rxclk,
    nRST_rxclk1         => nRST_rxclk1,
    nRST_txclk          => nRST_sfptxclk
);

--clk_set <= clkin_125M&clkin_156M_sfp&clkin_156M_5g&rx_clk(1)&rx_clk(0)&sfp_txclk&tx_clk_5g;

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

serdes_datain_inst : serdes_datain  --transceiver
generic map
(

    BKHSSI_NUM => BKHSSI_NUM
)
port map
(
    reconfclk                   => sysclk      ,
    refclk                      => clkin_125M  ,--clkin_156M_sfp,
    rx_serial_data              => rx_serial_data,

    rx_clk                      => rx_bk_clk,
    rx_parallel_data            => rx_bk_parallel_data,
    rx_control                  => rx_bk_control,

    rx_enh_data_valid           => rx_bk_enh_data_valid,
    rx_enh_fifo_full            => rx_bk_enh_fifo_full,
    rx_enh_fifo_empty           => rx_bk_enh_fifo_empty,
    rx_enh_fifo_del             => rx_bk_enh_fifo_del,
    rx_enh_fifo_insert          => rx_bk_enh_fifo_insert,
    rx_enh_highber              => rx_bk_enh_highber,
    rx_enh_blk_lock             => rx_bk_enh_blk_lock,

    phy_reset                   => RST_sys,
	serdes_rxlock               => serdes_rxlock
);

serdes_10g_gene: if SERDES_5G_EN = '0' generate
serdes_dataout_inst : serdes_dataout --fiber interface
generic map
(
    HSSI_NUM => FIBER_NUM
)
port map
(
    reconfclk                   => CLKUSR,
    refclk                      => clkin_156M_sfp,
    tx_serial_sfpdata           => tx_serial_sfpdata,
    rx_serial_sfpdata           => rx_serial_sfpdata,

    sfp_txclk                   => sfp_txclk,
    xgmii_tx_data               => xgmii_tx_data,
    xgmii_tx_ctrl               => xgmii_tx_ctrl,

    sfp_rxclk                   => sfp_rxclk,
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
end generate serdes_10g_gene;

bk2fiber: bk2fiber_conv
   generic map
   (
      SIM                => SIM ,
      ETHPORT_NUM        => ETHPORT_NUM ,  -- PER FIBER
      SERDES_5G_EN       => SERDES_5G_EN,
      FIBER_NUM          => FIBER_NUM  ,
      BKHSSI_NUM         => VID_HSSI_NUM
   )
    port MAP
    (
        nRST_bk_rxclk                   => nRST_bk_rxclk(VID_HSSI_NUM-1 downto 0)       ,
        rx_bk_clk                       => rx_bk_clk(VID_HSSI_NUM-1 downto 0)           ,
        rx_bk_parallel_data             => rx_bk_parallel_data(VID_HSSI_NUM*64-1 downto 0) ,
        rx_bk_control                   => rx_bk_control(VID_HSSI_NUM*8-1 downto 0)       ,

    	nRST_conv           => nRST_conv        ,
        convclk_i           => clk_conv         , ---200M
        time_ms_en_conv     => time_ms_en_conv  ,
        p_Frame_en_conv     => p_Frame_en_conv  ,
        p_Wren_conv         => p_Wren_conv      ,
        p_Data_conv         => p_Data_conv      ,
        p_Addr_conv         => p_Addr_conv      ,
        cur_slot_num        => cur_slot_num_conv     ,
        
        unit_connected_conv      =>  unit_connected_conv    , ----the unit is connected ;
        eth_connected_conv       =>  eth_connected_conv     , ---downto 0);    ------
        up08_start_timer_conv    =>  Up08_startimer_conv     , ----up08_start_timer_conv  , --- --NOTIFY ,one pulse only  
        Up08_net_rel_idx_conv    =>  Up08_net_rel_idx_conv     , ----up08_start_timer_conv  , --- --NOTIFY ,one pulse only  
        up08_timeout_conv        =>   up08_timeout_conv       , ---up08_timeout_conv      , -----every unit up one 
        --conv clock domain     =>   --conv clock domain    , ---
        quick08_wren_conv       =>   quick08_wren_conv       , ---
        quick08_waddr_conv      =>   quick08_waddr_conv      , ---
        quick08_wdata_conv      =>   quick08_wdata_conv      , ---
        quick08_flg_conv        =>   quick08_flg_conv        , ---
        quick08_filter_en_conv  =>   quick08_filter_en_conv  , ------
        quick08_addr_len_conv   =>   quick08_addr_len_conv   , ---
                                 
    	
        xgmii_txclk              => sfp_txclk          ,
        nRST_xgmii               => nRST_sfptxclk      , --200M
        xgmii_data               => xgmii_tx_data ,
        xgmii_control            => xgmii_tx_ctrl ,
		trigger_forrecon_convclk => trigger_forrecon_convclk,
        
        p_Frame_en_sys          => p_Frame_en_o  ,
        p_Wren_sys              => p_Wren_o      ,
        p_Data_sys              => p_Data_o      ,
        p_Addr_sys              => p_Addr_o      ,
        
		sysclk                  => sysclk,
		nRST_sys                => nRST_sys ,
		backup_flag_sys         => backup_flag_sys ,
	    error_check_num_sys     => error_check_num_sys(VID_HSSI_NUM*16-1 downto 0)     ,
	    subbrdin_packet_cnt_sys => subbrdin_packet_cnt_sys(VID_HSSI_NUM*32-1 downto 0) ,
	    error_fe_num_sys        => error_fe_num_sys(VID_HSSI_NUM*16-1 downto 0),
		
		shutter_rsp_dvld         => shutter_rsp_dvld       ,
		shutter_rsp_data         => shutter_rsp_data       ,
		shutter_rd_eth_index     => shutter_rd_eth_index   ,
		shutter_rd_frm_index     => shutter_rd_frm_index   ,
		shutter_rd_req           => shutter_rd_req         ,
		shutter_rd_ack           => shutter_rd_ack   ,
		shutter_rd_frmvld        => shutter_rd_frmvld,
		shutter_rd_end           => shutter_rd_end ,
		real_eth_num_conv        => real_eth_num_conv


    );


-- convto_xgmii_sfp_down : for i in  0 to FIBER_NUM-1 generate
-- xgmii_down_inst : convto_xgmii_sfp
-- generic map
-- (
    -- SERDES_5G_EN                    => SERDES_5G_EN,
    -- CURRENT_PORT                    => i
-- )
-- port map
-- (
    -- nRST_rxclk                      => nRST_bk2fiber_clk ,
    -- rx_clk                          => bk2fiber_clk      ,
    -- rx_parallel_data                => bk2fiber_parallel_data(64*i+63 downto 64*i),
    -- rx_control                      => bk2fiber_control(8*i+7 downto 8*i),

    -- nRST_txclk                      => nRST_sfptxclk,
    -- tx_clk                          => sfp_txclk,
    -- xgmii_tx_data                   => xgmii_tx_data(64*i+63 downto 64*i),
    -- xgmii_tx_ctrl                   => xgmii_tx_ctrl(8*i+7 downto 8*i),
    -- err_num                         => err_num(32*i+31 downto 32*i)
-- );
-- end generate convto_xgmii_sfp_down;


convto_xgmii_sfp_up : for i in  0 to FIBER_NUM-1 generate
xgmii_up_inst : convto_xgmii_sfp
generic map
(
    SERDES_5G_EN                    => '0',
    CURRENT_PORT                    => i
)
port map
(
    nRST_rxclk                      => nRST_rxclk1(i),
    rx_clk                          => sfp_rxclk(i),
    rx_parallel_data                => xgmii_rx_data(64*i+63 downto 64*i),
    rx_control                      => xgmii_rx_ctrl(8*i+7 downto 8*i),

    nRST_txclk                      => nRST_rxclk1(i),
    tx_clk                          => sfp_rxclk(i),
    xgmii_tx_data                   => xgmii_rx_updata(64*i+63 downto 64*i),
    xgmii_tx_ctrl                   => xgmii_rx_upctrl(8*i+7 downto 8*i),
    err_num                         => open
);

end generate convto_xgmii_sfp_up;

process(sysclk,nRST_sys)
begin
    if nRST_sys = '0' then
        led_cnt <= (others => '0');
        led <= (others => '0');
		subframe_FB_d1 <= (others=>'0');
        subframe_FB_d2 <= (others=>'0');
        subframe_FB_d3 <= (others=>'0');

    elsif rising_edge(sysclk) then
        led_cnt <= led_cnt + '1';
        subframe_FB_d1 <= subframe_FB_serdrx;
        subframe_FB_d2 <= subframe_FB_d1;
        subframe_FB_d3 <= subframe_FB_d2;
        for i in 0 to FIBER_NUM-1 loop
            if subframe_FB_d3(i) = '1' then
                dly_cnt(i*30+29 downto i*30) <= (others => '1');
            elsif dly_cnt(i*30+29) = '1' then
                dly_cnt(i*30+29 downto i*30) <= dly_cnt(i*30+29 downto i*30) - '1';
            end if;
            if dly_cnt(i*30+29) = '1' then
                led(i) <= led_cnt(23);
            else
                led(i) <= '0';
            end if;
            -- fiber_link(i) <= dly_cnt(i*30+29);
        end loop;
    end if;
end process;

process(sysclk, nRST_sys)
begin
	if nRST_sys = '0' then
		clr_serdesinfo_sys <= '0';
	elsif rising_edge(sysclk) then
		if p_Frame_en_o = '1' then
			if p_Wren_o = '1' and p_Addr_o = 0 then
				if p_Data_o = X"3C" then
					clr_serdesinfo_sys <= '1';
				else
					clr_serdesinfo_sys <= '0';
				end if;
			end if;
		end if;		
	end if;
end process;

serdes_5g_gene: if SERDES_5G_EN = '1' generate
--serdes_out_5g : vidout_net5G_top
--generic map
--(
--    HSSI_NUM5G              => HSSI_NUM5G
--)
--port map
--(
--    clk125M_in              => sysclk,
--    clkin_5gsfp             => clkin_156M_5g,
--    nRST                    => nRST_sys,

--    tx_parallel_data        => tx_parallel_data_5g,
--    tx_control              => tx_control_5g,
--    tx_clk                  => tx_clk_5g,

--    rx_clk                  => rx_clk_5g,
--    rx_parallel_data        => rx_parallel_data_5g,
--    rx_control              => rx_control_5g,
--    eth_link_rxclk          => eth_link_rxclk,

--    config_rdack            => config_rdack,
--    config_rdreq            => config_rdreq,
--    config_rdaddr           => config_rdaddr,
--    config_rdlen            => config_rdlen,
--    flash_dpram_data        => flash_dpram_data,
--    flash_dpram_wraddr      => flash_dpram_wraddr,
--    flash_dpram_wren        => flash_dpram_wren,

--    PHYAB_RESET             => PHYAB_RESET,
--    PHYAB_MDC               => PHYAB_MDC,
--    PHYAB_MDIO              => PHYAB_MDIO,
--    PHYCD_RESET             => PHYCD_RESET,
--    PHYCD_MDC               => PHYCD_MDC,
--    PHYCD_MDIO              => PHYCD_MDIO,

--    tx_serial_5gdata        => tx_serial_5gdata,
--    rx_serial_5gdata        => rx_serial_5gdata
--);
end generate serdes_5g_gene;


para_serdes_inst : para_serdes_top
generic map
(
	PARA_HSSI_NUM			=> PARA_HSSI_NUM
)
port map
(
	nRST_sys				=> nRST_sys,
	sysclk					=> sysclk,

    xgm_rstn	         	=> nRST_bk_rxclk(BKHSSI_NUM-1),
    xgmclk	             	=> rx_bk_clk(BKHSSI_NUM-1),
    xgm_rx_data			   	=> rx_bk_parallel_data(BKHSSI_NUM*64-1 downto (BKHSSI_NUM-PARA_HSSI_NUM)*64),
    xgm_rx_k	         	=> rx_bk_control(BKHSSI_NUM*8-1 downto (BKHSSI_NUM-PARA_HSSI_NUM)*8),

	frame_ss				=> serdes_frame_ss_sys,
    rx_data_vld				=> serdes_rx_vld_sys,
    rx_data					=> serdes_rxd_sys,

	clr_serdesinfo_sys		=> clr_serdesinfo_sys,
	serdes_pck_cnt_sys		=> subbrdin_packet_cnt_sys(BKHSSI_NUM*32-1 downto (BKHSSI_NUM-PARA_HSSI_NUM)*32),
	serdes_fe_cnt_sys		=> error_fe_num_sys(BKHSSI_NUM*16-1 downto (BKHSSI_NUM-PARA_HSSI_NUM)*16),
	serdes_crc_err_sys		=> error_check_num_sys(BKHSSI_NUM*16-1 downto (BKHSSI_NUM-PARA_HSSI_NUM)*16)

);


p_uart_inst : uart_param_top
generic map
(
    CONS_VER_HIGH       => PCK_CONS_VER_HIGH,
    CONS_VER_LOW        => PCK_CONS_VER_LOW,
    TXSUBCARD_TYPE      => TXSUBCARD_TYPE,
    FIBERPORT_NUM        => FIBER_NUM , ---PORT_NUM,
    ETHPORT_NUM          => ETHPORT_NUM ,
    SERDES_SPEED_MSB    => SERDES_SPEED_MSB,
    SERDES_SPEED_LSB    => SERDES_SPEED_LSB,
    BAUD_DIV            => BAUD_DIV,
	DDR_NUM             => DDR_NUM
    ---HSSI_NUM            => FIBER_NUM
)
port map
(
   ---to reduce the clock domain in HDMI region
	nRST_cmd          => nRST_conv    ,
	cmd_clk           => clk_conv     ,

    p_Frame_en_cmd    =>  p_Frame_en_conv  ,
    p_Wren_cmd        =>  p_Wren_conv      ,
    p_Data_cmd        =>  p_Data_conv      ,
    p_Addr_cmd        =>  p_Addr_conv      ,
    cur_slot_num_cmd   =>  cur_slot_num_conv      ,

   ---------------------------------------
    nRST                => nRST_sys,
    sysclk              => sysclk,

	-- from para serdes
	serdes_frame_ss		=> serdes_frame_ss_sys,
	serdes_rx_vld		=> serdes_rx_vld_sys,
	serdes_rx_data		=> serdes_rxd_sys,

    ---uart: 2 pins of uart
    rxd_top             => rxd_frmbk,
    txd_top             => txd_tobk,
    txd_info_top        => txd_info,
    txd_autolight       => txd_autolight,

    --info
    err_num             => err_num,
    err_num_fiber       => err_num_fiber_sys,
    crc_info            => crc_info,
    eth_link            => eth_link_sys,
    fiber_link          => subframe_FB_serdrx,

    time_ms_en_sys      => time_ms_en_125  ,
    autobright_en       => autolight_outen_sys  ,
    autobright_val      => autolight_outval_sys ,


    p_Frame_en_o        => p_Frame_en_o,
    p_Wren_o            => p_Wren_o,
    p_Data_o            => p_Data_o,
    p_Addr_o            => p_Addr_o,
    cur_slot_num        => cur_slot_num_sys,

	get_curr_temp_phy_sys => (others=>'0') ,

	Up_cmd_fifo_empty_sys  => Up_cmd_fifo_empty_sys ,
	Up_cmd_fifo_rden_sys   => Up_cmd_fifo_rden_sys  ,
	Up_cmd_fifo_q_sys      => Up_cmd_fifo_q_sys     ,
    Up_ReadAddr_sys        => Up_ReadAddr_sys       ,
    Up_ReadData_sys        => Up_ReadData_sys       ,


	backup_flag_sys      => backup_flag_sys ,
	error_check_num_sys     => error_check_num_sys(VID_HSSI_NUM*16-1 downto 0)      ,		-- only need to upload info of 4 vid serdes
	subbrdin_packet_cnt_sys => subbrdin_packet_cnt_sys(VID_HSSI_NUM*32-1 downto 0)  ,
	error_fe_num_sys        => error_fe_num_sys(VID_HSSI_NUM*16-1 downto 0)         ,
	serdes_rxlock           => serdes_rxlock ,
	real_eth_num_sys        => real_eth_num_sys,
	ddr_verify_end_sys      => ddr_verify_end_sys,
	ddr_verify_success_sys  => ddr_verify_success_sys

);

uart_64to8_inst : uart_64to8
generic map
(
   PORTNUM_EVERY_FIBER  => ETHPORT_NUM,
    HSSI_NUM            => FIBER_NUM,
	TXSUBCARD_TYPE      => TXSUBCARD_TYPE
)
port map
(
    nRST                => nRST_sys,
    sysclk              => sysclk,
    nRST_rxclk          => nRST_rxclk1,
    rxclk               => sfp_rxclk,
    nRST_txclk          => nRST_sfptxclk,
    txclk               => sfp_txclk,
	nRST_convclk        => nRST_conv,
	convclk_i           => clk_conv ,
    xgmii_tx_data       => xgmii_tx_data,
    xgmii_tx_ctrl       => xgmii_tx_ctrl,
    xgmii_rx_updata     => xgmii_rx_updata,
    xgmii_rx_upctrl     => xgmii_rx_upctrl,
    cur_slot_num_sys        => cur_slot_num_sys(3 downto 0),

  eth_link_sys            => eth_link_sys,
--   err_num_fiber_sys       => err_num_fiber_sys,
    subframe_FB_serdrx      => subframe_FB_serdrx,
    up08_timeout_notify     => up08_timeout_conv   ,
    Up08_startimer          => Up08_startimer_conv ,
    Up08_net_rel_idx_conv    => Up08_net_rel_idx_conv ,
    autolight_outen_sys     => autolight_outen_sys ,
    autolight_outval_sys    => autolight_outval_sys,
    quick08_wren_convclk            =>  quick08_wren_conv       ,
    quick08_waddr_convclk           =>  quick08_waddr_conv      ,
    quick08_wdata_convclk           =>  quick08_wdata_conv      ,
    quick08_flg             =>  quick08_flg_conv        ,
    quick08_filter_en       =>  quick08_filter_en_conv  ,
    quick08_addr_len        =>  quick08_addr_len_conv   ,

	Up_cmd_fifo_empty_sys   =>  Up_cmd_fifo_empty_sys  ,
	Up_cmd_fifo_rden_sys    =>  Up_cmd_fifo_rden_sys   ,
	Up_cmd_fifo_q_sys       =>  Up_cmd_fifo_q_sys      ,
    Up_ReadAddr_sys         =>  Up_ReadAddr_sys        ,
    Up_ReadData_sys         =>  Up_ReadData_sys   ,
	real_eth_num_sys        =>  real_eth_num_sys

);
    -- eth_link_sys <= (others=>'1') ;
    -- eth_link_sys            <= eth_link_status_sys;----(others=>'1') ;
    err_num_fiber_sys       <= (others=>'0') ;
    subframe_FB_serdrx      <=  subframe_FB_serdrx  ;


top_update_inst : top_update
generic map
(
    FLASH_PROTECT_EN    => FLASH_PROTECT_EN,    
	FLASH_PROTECT_ALL   => FLASH_PROTECT_ALL ,  ---'1':protect all, '0':protect half,only protect backup
	FLASH_TYPE          => FLASH_TYPE,     ------0:MT25QU256, 1:MT25QU01G

    FRAME_W             => 11,
    FLASH_ADDR_W_INBYTE => 25,
    FLASH_DATA_W        => 32 ,
	DUAL_BOOT_EN        => DUAL_BOOT_EN
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
    time_ms_en_o    => time_ms_en_125,
    nRST_conv       => nRST_conv , 
    conv_clk        => clk_conv , 
    time_ms_en_conv => time_ms_en_conv 

);

ddr3_inst_gen : for i in 0 to DDR_NUM-1 generate
ddr3_inst:ed_synth_emif_0 port map
(
    amm_ready_0         => ddr3_amm_ready_0(i),         --  output,    width = 1,       ctrl_amm_0.waitrequest_n
    amm_read_0          => ddr3_amm_read_0(i),          --   input,    width = 1,                 .read
    amm_write_0         => ddr3_amm_write_0(i),         --   input,    width = 1,                 .write
    amm_address_0       => ddr3_amm_address_0(23*(i+1)-1 downto 23*i),       --   input,   width = 23,                 .address
    amm_readdata_0      => ddr3_amm_readdata_0(320*(i+1)-1 downto 320*i),      --  output,  width = 320,                 .readdata
    amm_writedata_0     => ddr3_amm_writedata_0(320*(i+1)-1 downto 320*i),     --   input,  width = 320,                 .writedata
    amm_burstcount_0    => ddr3_amm_burstcount_0(7*(i+1)-1 downto 7*i),    --   input,    width = 7,                 .burstcount
    amm_byteenable_0    => ddr3_amm_byteenable_0(40*(i+1)-1 downto 40*i),    --   input,   width = 40,                 .byteenable
    amm_readdatavalid_0 => ddr3_amm_readdatavalid_0(i), --  output,    width = 1,                 .readdatavalid

    emif_usr_clk        => emif_usr_clk(i),             --  output,    width = 1,     emif_usr_clk.clk
    emif_usr_reset_n    => emif_usr_reset_n(i),         --  output,    width = 1, emif_usr_reset_n.reset_n

    global_reset_n      => ddr3_global_reset_n (i),                        --   input,    width = 1,   global_reset_n.reset_n
    mem_ck              => mem_ck(i downto i),                    --  output,    width = 1,              mem.mem_ck
    mem_ck_n            => mem_ck_n(i downto i),                  --  output,    width = 1,                 .mem_ck_n
    mem_a               => mem_a(13*(i+1)-1 downto 13*i),         --  output,   width = 13,                 .mem_a
    mem_ba              => mem_ba(3*(i+1)-1 downto 3*i),          --  output,    width = 3,                 .mem_ba
    mem_cke             => mem_cke(i downto i),                   --  output,    width = 1,                 .mem_cke
    mem_cs_n            => mem_cs_n(i downto i),                  --  output,    width = 1,                 .mem_cs_n
    mem_odt             => mem_odt(i downto i),                   --  output,    width = 1,                 .mem_odt
    mem_reset_n         => mem_reset_n(i downto i),               --  output,    width = 1,                 .mem_reset_n
    mem_we_n            => mem_we_n(i downto i),                  --  output,    width = 1,                 .mem_we_n
    mem_ras_n           => mem_ras_n(i downto i),                 --  output,    width = 1,                 .mem_ras_n
    mem_cas_n           => mem_cas_n(i downto i),                 --  output,    width = 1,                 .mem_cas_n
    mem_dqs             => mem_dqs(5*(i+1)-1 downto 5*i),         --   inout,    width = 5,                 .mem_dqs
    mem_dqs_n           => mem_dqs_n(5*(i+1)-1 downto 5*i),       --   inout,    width = 5,                 .mem_dqs_n
    mem_dq              => mem_dq(40*(i+1)-1 downto 40*i),        --   inout,   width = 40,                 .mem_dq
    mem_dm              => mem_dm(5*(i+1)-1 downto 5*i),                     --  output,    width = 5,                 .mem_dm
    oct_rzqin           => mem_oct_rzqin(i),             --   input,    width = 1,              oct.oct_rzqin
    pll_ref_clk         => mem_pll_ref_clk(i),           --   input,    width = 1,      pll_ref_clk.clk

    local_cal_success   => ddr3_local_cal_success(i),   -- output,    width = 1,           status.local_cal_success
    local_cal_fail      => ddr3_local_cal_fail(i)       --  output,    width = 1,                 .local_cal_fail
);


ddr_end_i: altera_std_synchronizer    
    port   map
    (
		clk      => sysclk,
		reset_n  => nRST_sys,
		din      => ddr_verify_end_emif(i),
		dout     => ddr_verify_end_sys(i)
	); 
	
ddr_succ_i: altera_std_synchronizer    
    port   map
    (
		clk      => sysclk,
		reset_n  => nRST_sys,
		din      => ddr_verify_success_emif(i),
		dout     => ddr_verify_success_sys(i)
	); 				
	
end generate ddr3_inst_gen;


ddr3_pll_locked <= (others=>'1');

shutter_ddr3_inst: shutter_ddr3_op 
generic map
(  
	DDRD_W        => DDRD_W   ,
	DDR_AW        => DDR_AW   ,
	DDR_DW        => DDR_DW   ,
	DDR_NUM       => DDR_NUM  ,
    BURST_W       => BURST_W  ,
    TAGW          => TAGW     ,
    WRC_W         => WRC_W    ,
    CREQ_W        => CREQ_W   ,
    CRSP_W        => CRSP_W   ,
	GRP_NUM       => FIBER_NUM,
	GRP_SIZE      => ETHPORT_NUM

)
port map
(
    nRST                    => nRST_conv ,
    clk                     => clk_conv,
	                        
	pframe_en               => p_Frame_en_conv,
	pwren                   => p_Wren_conv,
	paddr                   => p_Addr_conv,
	pdata                   => p_Data_conv,
	
    global_reset_n          => ddr3_global_reset_n,
    ddr3_pll_locked         => ddr3_pll_locked,
    local_cal_success       => ddr3_local_cal_success,    ----,   //           status.local_cal_success, When high, indicates that PHY calibration was successful
    local_cal_fail          => ddr3_local_cal_fail ,           ----,      //                 .local_cal_fail,    When high, indicates that PHY calibration failed
    emif_usr_reset_n        => emif_usr_reset_n,       ----,    // emif_usr_reset_n.reset_n,           Reset for the user clock domain. Asynchronous assertion and synchronous deassertion
    emif_usr_clk            => emif_usr_clk           ,                              ----    //     emif_usr_clk.clk,               User clock domain
    amm_ready_0             => ddr3_amm_ready_0            ,                              ----: ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
    amm_read_0              => ddr3_amm_read_0             ,                              ---- ---- active high ,          //                 .read,              Read request signal
    amm_write_0             => ddr3_amm_write_0            ,                              ---- ---- active high,         //                 .write,             Write request signal
    amm_address_0           => ddr3_amm_address_0          ,                              ---- //                 .address,           Address for the read/write request
    amm_readdata_0          => ddr3_amm_readdata_0         ,                              ----//                 .readdata,          Read data
    amm_writedata_0         => ddr3_amm_writedata_0        ,                              ----/                 .writedata,         Write data
    amm_burstcount_0        => ddr3_amm_burstcount_0       ,                              ----   //                 .burstcount,        Number of transfers in each read/write burst
    amm_byteenable_0        => ddr3_amm_byteenable_0       ,                              ---- ,    //                 .byteenable,        Byte-enable for write data
    amm_readdatavalid_0     => ddr3_amm_readdatavalid_0    ,                              ----
	
	shutter_rsp_dvld        => shutter_rsp_dvld      ,
	shutter_rsp_data        => shutter_rsp_data      ,
	shutter_rd_eth_index    => shutter_rd_eth_index  ,
	shutter_rd_frm_index    => shutter_rd_frm_index  ,
	shutter_rd_req          => shutter_rd_req        ,
	shutter_rd_ack          => shutter_rd_ack   ,		
	shutter_rd_frmvld       => shutter_rd_frmvld,
	shutter_rd_end          => shutter_rd_end  ,
	real_eth_num_conv       => real_eth_num_conv,
	ddr_verify_end_o        => ddr_verify_end_emif,
	ddr_verify_success_o    => ddr_verify_success_emif
	
				
);



process(nRST_conv,clk_conv)
begin
	if nRST_conv ='0' then
	
		real_eth_num_conv  <= conv_std_logic_vector(10,4);
		eth_set_en    <= '0';
	elsif rising_edge(clk_conv) then
		if p_Frame_en_conv = '1' and p_Wren_conv = '1'  then
			if p_Addr_conv = 0 then
				if p_Data_conv = X"27" then
					eth_set_en <= '1';
				else	
					eth_set_en <= '0';
				end if;
			elsif p_Addr_conv = 4 and eth_set_en = '1' then
				if p_Data_conv = 0 then ----eth 1G
					real_eth_num_conv  <= conv_std_logic_vector(10,4);
				elsif p_Data_conv = 4 then----eth 0~5G
					real_eth_num_conv  <= conv_std_logic_vector(4,4);
				else
					real_eth_num_conv  <= conv_std_logic_vector(10,4);
				end if;
			end if;
		end if;
	end if;
end process;
		
eth_num_inst: cross_domain   
    generic map(
     	DATA_WIDTH => 4 
    ) 
    port map
    (   clk0          => clk_conv   ,   
     	nRst0         => nRST_conv ,   		
     	datain        => real_eth_num_conv,     
     	datain_req    =>  '1' , 
     		
     	clk1          => sysclk    ,
     	nRst1         => nRST_sys  , 
     	data_out      => real_eth_num_sys ,  
     	dataout_valid => open  
    ); 		

	
	
end;
