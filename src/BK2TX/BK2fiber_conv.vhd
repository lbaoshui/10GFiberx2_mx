library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;


entity bk2fiber_conv is
generic
(  SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic := '0';
   FIBER_NUM         : integer   ;
   ETHPORT_NUM       : integer   := 10 ;  -- PER FIBER
   BKHSSI_NUM        : integer   ;
   G12_9BYTE_EN      : STD_LOGIC := '0'   --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS
);
port
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);


    nRST_conv           : in  std_logic    ; ---
    convclk_i              : in  std_logic    ; --200M almost
    time_ms_en_conv        : in  std_logic ;
    p_Frame_en_conv         : in std_logic ;
    p_Wren_conv             : in std_logic ;
    p_Data_conv             : in std_logic_vector(7 downto 0);
    p_Addr_conv             : in std_logic_vector(10 downto 0);
    cur_slot_num            : in std_logic_vector(15 downto 0);
    ---conv clock domain 
    unit_connected_conv       : in  std_logic_vector(FIBER_NUM-1 DOWNTO 0); --the unit is connected ;
    eth_connected_conv        : in  std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);    ------
    up08_start_timer_conv     :  out std_logic_vector(FIBER_NUM-1 DOWNTO 0);  --NOTIFY ,turn signal ,0to1 or  1to0 
    up08_timeout_conv         :  in  std_logic_vector(FIBER_NUM-1 downto 0); --every unit up one 
    Up08_net_rel_idx_conv     :  out std_logic_vector(7 downto 0);  
    --conv clock domain 
  
  
    xgmii_txclk          : in  std_logic ; ---_vector(FIBER_NUM-1 downto 0) ;
    nRST_xgmii           : in  std_logic ; ---_vector(FIBER_NUM-1 downto 0) ;
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
	shutter_rd_ack                : in  std_logic_vector(FIBER_NUM-1 downto 0);
	shutter_rd_frmvld             : in  std_logic_vector(FIBER_NUM-1 downto 0);
	shutter_rd_end                : in  std_logic_vector(FIBER_NUM-1 downto 0);
	
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)


);

end bk2fiber_conv;

architecture beha of bk2fiber_conv is

 -- signal   Up08_net_rel_idx_conv     :     std_logic_vector(7 downto 0);   --NOTIFY ,one pulse only  
 -- signal   up08_start_timer_conv     :     std_logic_vector(FIBER_NUM-1 DOWNTO 0);  --NOTIFY ,one pulse only  
 -- signal   up08_timeout_conv         :     std_logic_vector(FIBER_NUM-1 downto 0); --every unit up one 
   

signal    rt_tx_done      :    std_logic_vector(FIBER_NUM-1 downto 0);
signal    tx07_cc_req     :    std_logic_vector(FIBER_NUM-1 downto 0); --tx one 0x7 packet ;if the unit has many eth port ,then notify 
signal    tx07_cc_idx     :    std_logic_vector(3 downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
signal    tx07_cc_ack     :    std_logic_vector(FIBER_NUM-1 downto 0);
signal    tx07_cc_txdone  :    std_logic_vector(FIBER_NUM-1 downto 0); --when data is tx out to FIBER or 5G port 
signal    tx07_cc_end     :    std_logic_vector(FIBER_NUM-1 downto 0);----all sched done ....(downparam_tx can switch its ping-pong now )
signal    p_Frame_en_f_conv    :   std_logic_vector(FIBER_NUM-1 DOWNTO 0) ;
signal    p_Wren_f_conv        :   std_logic_vector(FIBER_NUM-1 downto 0) ;
signal    p_Data_f_conv        :   std_logic_vector(7 downto 0);
signal    p_Addr_f_conv        :   std_logic_vector(10 downto 0);   
   
  
component param_sched is 
generic ( 
	UNIT_NUM    : INTEGER := 4 ; --for fiber 2 or 4, for 5G 4 ;
	ETH_PER_UNIT: INTEGER:=1 ;--EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
    IS_5G      : std_logic := '0'

);
port 
(  nRST : in  std_logic ;
   clk  : in  std_logic ;
   
   vsync_i                : in std_logic ; -----
   rt_tx_done             : in std_logic_vector(UNIT_NUM-1 downto 0) ;
    --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    cur_slot_num          : in std_logic_vector(15 downto 0);  
    ----
    quick08_wren         :  out std_logic  ;
    quick08_waddr        :  out std_logic_vector(10 downto 0);
    quick08_wdata        :  out std_logic_vector( 7 downto 0);
    quick08_flg          :  out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;
    quick08_filter_en    :  out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;  --up 08 filtered or not -----
    quick08_addr_len     :  out std_logic_vector(7 downto 0);    
    --dispatch to downparam_tx 
    p_Frame_en_o         : out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;
    p_Wren_o             : out std_logic_vector(UNIT_NUM-1 downto 0) ;
    p_Data_o             : out std_logic_vector(7 downto 0);
    p_Addr_o             : out std_logic_vector(10 downto 0);   
   ---------------------------------------------------------------------    
    unit_connected       : in  std_logic_vector(UNIT_NUM-1 DOWNTO 0); --the unit is connected ;
    eth_connected        : in  std_logic_vector(UNIT_NUM*ETH_PER_UNIT-1 downto 0);    ------
    -------------------------------------------------------------
    tx07_cc_req     :  out std_logic_vector(UNIT_NUM-1 downto 0); --tx one 0x7 packet ;if the unit has many eth port ,then notify 
    tx07_cc_idx     :  out std_logic_vector(3 downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
    tx07_cc_ack     :  in  std_logic_vector(UNIT_NUM-1 downto 0);
    tx07_cc_txdone  :  in  std_logic_vector(UNIT_NUM-1 downto 0); --when data is tx out to FIBER or 5G port 
    tx07_cc_end     :  out std_logic_vector(UNIT_NUM-1 downto 0) ; ----all sched done ....(downparam_tx can switch its ping-pong now )
    up08_start_timer:  out std_logic_vector(UNIT_NUM-1 DOWNTO 0);  --NOTIFY ,one pulse only 
    Up08_net_rel_idx:  out std_logic_vector(7 downto 0);          
    up08_timeout    :  in  std_logic_vector(UNIT_NUM-1 downto 0) ; --every unit up one 
	
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)
  );    
end component ;

-- signal    quick08_flg_conv          :  std_logic_vector(FIBER_NUM-1 DOWNTO 0) ;

-- signal    quick08_filter_en_conv    :   std_logic_vector(FIBER_NUM-1 downto 0)  ;  --up 08 filtered or not -----
-- signal    quick08_addr_len_conv     :   std_logic_vector(7 downto 0);   
	
component param_filter07 is 
 port ( 
   nRST                   : in  std_logic ;
   clk                    : in  std_logic ;    
    --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    ----    
    quick08_wren          :  out std_logic  ;
    quick08_waddr         :  out std_logic_vector(10 downto 0);
    quick08_wdata         :  out std_logic_vector( 7 downto 0); 
    quick08_filter_en     :  out std_logic  ;  --up 08 filtered or not -----
    quick08_addr_len      :  out std_logic_vector(7 downto 0)  
  ); 
 end component ;
 
signal xgmii_txout : std_logic_vector( FIBER_NUM*72-1 downto 0);
component bk2fiber_oneFiber is
generic
(  SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic := '0';
---   FIBER_NUM         : integer   ;
   P_W               : INTEGER   :=  4  ; ---Depend on IS_BACK AND eth_num
   ETH_IDX           : INTEGER   :=  0  ; ---STARTING INDEX ------
   ETHPORT_NUM       : integer   := 10 ;  -- PER FIBER
   BKHSSI_NUM        : integer   ;
   G12_9BYTE_EN      : STD_LOGIC := '1'   --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS
);
port
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);

	vsync_neg_conv_o      : out std_logic;
    rt_tx_done            : out std_logic;

    nRST_conv            : in  std_logic    ; ---
    convclk_i            : in  std_logic    ; --200M almost
    p_Frame_en_conv      : in std_logic ;
    p_Wren_conv          : in std_logic ;
    p_Data_conv          : in std_logic_vector(7 downto 0);
    p_Addr_conv          : in std_logic_vector(10 downto 0);
    cur_slot_num         : in std_logic_vector(15 downto 0);
	
    p_Frame_en_f_conv      : in std_logic ;
    p_Wren_f_conv          : in std_logic ;
    p_Data_f_conv          : in std_logic_vector(7 downto 0);
    p_Addr_f_conv          : in std_logic_vector(10 downto 0);
	

    tx07_cc_req          : in   std_logic ; --tx one 0x7 packet ;if the unit has many eth port ,then notify 
    tx07_cc_idx          : in   std_logic_vector(3           downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
    tx07_cc_ack          : out  std_logic ;
    tx07_cc_txdone       : out  std_logic ; --when data is tx out to FIBER or 5G port 
 
    xgmii_txclk          : in  std_logic  ;
    nRST_xgmii           : in  std_logic  ;
    xgmii_data           : out std_logic_vector( 64-1 downto 0);
    xgmii_control        : out std_logic_vector( 8 -1 downto 0);

    secret_data          : in  std_logic_vector(47 downto 0):= (others => '0');

	rcv_led		         : in std_logic_vector(1 downto 0);
	backup_flag          : in std_logic_vector(ETHPORT_NUM-1 downto 0);
    req_f9_upload        : in  std_logic    ; ---

    hdr_enable           : in  std_logic:= '0';
    hdr_type             : in  std_logic_vector(7 downto 0):= (others => '0');
    hdr_rr               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_rg               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_rb               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gr               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gg               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gb               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_br               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_bg               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_bb               : in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_coef             : in  std_logic_vector(5 downto 0):= (others => '0');
    hlg_type             : in  std_logic_vector(7 downto 0):= (others => '0');
	color_depth_o        : out std_logic_vector(1 downto 0);

    virtual_pix_en       : in  std_logic_vector(1 downto 0):= (others => '0');
    virtual_direction    : in  std_logic_vector(1 downto 0):= (others => '0');

    colorspace           : in std_logic_vector(2  downto 0);
	PN_frame_type        : in std_logic_vector(19 downto 0);
	bright_weight        : in std_logic_vector(89 downto 0);
	invert_dissolve_level : in std_logic_vector(10*4-1 downto 0);
    vsync_param_update_en : out std_logic;
	function_enable       : in  std_logic_vector(15 downto 0);

	eth_bright_value     : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_R          : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_G          : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_B          : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	low_bright_en        : in std_logic;

	clr_serdesinfo_convclk        : in  std_logic;
	subbrdin_packet_cnt_rxbkclk   : out std_logic_vector(BKHSSI_NUM*32-1 downto 0);
	error_fe_num_rxbkclk          : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);
	error_check_num_rxbkclk       : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);

	eth_forbid_en_convclk         : in std_logic_vector(ETHPORT_NUM-1 downto 0);
	eth_mask_en_convclk			  : in std_logic_vector(ETHPORT_NUM-1 downto 0);
	
	shutter_rsp_dvld              : in std_logic;
	shutter_rsp_data              : in std_logic_vector(71 downto 0);
	shutter_rd_eth_index          : out std_logic_vector(3 downto 0);
	shutter_rd_frm_index          : out std_logic_vector(14 downto 0);
	shutter_rd_req                : out std_logic;
	shutter_rd_ack                : in  std_logic;
	shutter_rd_frmvld             : in  std_logic;
	shutter_rd_end                : in  std_logic;
	
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)
	
);

end component;
signal  req_f9_upload        :    std_logic  := '0'   ; ---
signal	subbrdin_packet_cnt_rxbkclk   :  std_logic_vector(BKHSSI_NUM*32-1 downto 0);
signal	error_fe_num_rxbkclk          :  std_logic_vector(BKHSSI_NUM*16-1 downto 0);
signal	error_check_num_rxbkclk       :  std_logic_vector(BKHSSI_NUM*16-1 downto 0);

signal    vsync_neg_conv_o     :    std_logic_vector(FIBER_NUM-1 downto 0);
signal    secret_data          :    std_logic_vector(47 downto 0):= (others => '0');
signal    hdr_enable           :    std_logic:= '0';
signal    hdr_type             :    std_logic_vector(7 downto 0):= (others => '0');
signal    hdr_rr               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_rg               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_rb               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_gr               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_gg               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_gb               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_br               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_bg               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_bb               :    std_logic_vector(15 downto 0):= (others => '0');
signal    hdr_coef             :    std_logic_vector(5 downto 0):= (others => '0');
signal    hlg_type             :    std_logic_vector(7 downto 0):= (others => '0');
signal    virtual_pix_en       :    std_logic_vector(1 downto 0);
signal    virtual_direction    :    std_logic_vector(1 downto 0);

signal  	error_exist_en_rxbkclk        :  std_logic_vector(2*2-1 downto 0);

component global_ctrl is
generic
(  SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic := '0';
   FIBER_NUM         : integer   ;
   ETHPORT_NUM       : integer   := 10   -- PER FIBER
);
port
(

    nRST_conv             : in  std_logic    ; ---
    convclk_i             : in  std_logic    ; --200M almost

    vsync_neg             : in std_logic  ;
    time_ms_en_conv       : in std_logic ;
    p_Frame_en_conv       : in std_logic ;
    p_Wren_conv           : in std_logic ;
    p_Data_conv           : in std_logic_vector(7 downto 0);
    p_Addr_conv           : in std_logic_vector(10 downto 0);

	rcv_led_out		   : out std_logic_vector(1 downto 0);
	backup_flag        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);

	HDR_enable         : out std_logic;
	HDR_type           : out std_logic_vector(7 downto 0);
	HDR_rr             : out std_logic_vector(15 downto 0);
	HDR_rg             : out std_logic_vector(15 downto 0);
	HDR_rb             : out std_logic_vector(15 downto 0);
	HDR_gr             : out std_logic_vector(15 downto 0);
	HDR_gg             : out std_logic_vector(15 downto 0);
	HDR_gb             : out std_logic_vector(15 downto 0);
	HDR_br             : out std_logic_vector(15 downto 0);
	HDR_bg             : out std_logic_vector(15 downto 0);
	HDR_bb             : out std_logic_vector(15 downto 0);
	HDR_coef           : out std_logic_vector(5 downto 0);
	HLG_type           : out std_logic_vector(7 downto 0);
	secret_data        : out std_logic_vector(47 downto 0);
    virtual_pix_en     : out std_logic_vector(1 downto 0);
    virtual_direction  : out std_logic_vector(1 downto 0);
    
    req_f9_upload      : out std_logic ;

	eth_bright_value   : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	eth_color_R        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	eth_color_G        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	eth_color_B        : out std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
	low_bright_en      : out std_logic;

	eth_forbid_en_convclk      : out std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
	eth_mask_en_convclk		  : out std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
	clr_serdesinfo_convclk : out std_logic;

	colorspace_buf         : out std_logic_vector(2  downto 0);
	PN_frame_type_buf      : out std_logic_vector(19 downto 0);
	bright_weight_buf      : out std_logic_vector(89 downto 0);
	invert_dissolve_level_buf      : out std_logic_vector(10*4-1 downto 0);
	vsync_param_update_en  : in  std_logic_vector(FIBER_NUM-1 downto 0);
	function_enable        : out std_logic_vector(15 downto 0)
);

end component;

signal 	backup_flag_sel        : std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
signal  eth_forbid_en_sel      : std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
signal	eth_bright_value_sel       :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
signal	eth_color_R_sel            :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
signal	eth_color_G_sel            :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
signal	eth_color_B_sel           :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);


signal 	clr_serdesinfo_convclk : std_logic;
signal	rcv_led_out		   :  std_logic_vector(1 downto 0);
signal	backup_flag        :  std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
signal  color_depth_o      :  std_logic_vector(3 downto 0);
signal  color_depth_buf    :  std_logic_vector(1 downto 0);
signal 	function_enable    :  std_logic_vector(15 downto 0);

signal	eth_bright_value   :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
signal	eth_color_R        :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
signal	eth_color_G        :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);
signal	eth_color_B        :  std_logic_vector(FIBER_NUM*ETHPORT_NUM*8-1 downto 0);

signal	low_bright_en      :  std_logic;
signal	eth_forbid_en_convclk      :  std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0);
signal eth_mask_en_convclk		: std_logic_vector(FIBER_NUM*ETHPORT_NUM-1 downto 0)			:= (others => '0');

signal  colorspace         :  std_logic_vector(2  downto 0);
signal  PN_frame_type      :  std_logic_vector(19 downto 0);
signal  bright_weight      :  std_logic_vector(89 downto 0);
signal  invert_dissolve_level      :  std_logic_vector(10*4-1 downto 0);
signal  vsync_param_update_en  :  std_logic_vector(FIBER_NUM-1 downto 0);


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
end component;

signal error_exist_en_d1 : std_logic_vector(3 downto 0):=(others=>'0');
signal backup_flag_d1    : std_logic_vector(3 downto 0):=(others=>'0');
signal backup_flag_d2    : std_logic_vector(3 downto 0):=(others=>'0');

component altera_std_synchronizer is 
  generic (depth : integer := 3);
  port   
     (
				    clk : in std_logic ;
				reset_n : in std_logic ; 
				din     : in std_logic ;
				dout    : out std_logic
				);  
 end component;
 
 
	
begin  

process(convclk_i)
begin
	if rising_edge(convclk_i) then
		color_depth_buf <= color_depth_o(1 downto 0);
		if color_depth_buf = "00" and color_depth_o = "01" then
			trigger_forrecon_convclk <= '1';
		else
			trigger_forrecon_convclk <= '0';
		end if;
	end if;
end process;

packet_cross_i : for i in 0 to 3 generate
cross_i :  cross_domain
	generic map (
	   DATA_WIDTH  => 32
	)
	port map
	(   clk0             => rx_bk_clk(i),
		nRst0            => nRST_bk_rxclk(i),
		datain           => subbrdin_packet_cnt_rxbkclk((i+1)*32-1 downto i*32),
		datain_req       => '1',

		clk1             => sysclk,
		nRst1            => nRST_sys,
		data_out         => subbrdin_packet_cnt_sys((i+1)*32-1 downto i*32),
		dataout_valid    => open

	);
cross1_i :  cross_domain
	generic map (
	   DATA_WIDTH  => 16
	)
	port map
	(   clk0             => rx_bk_clk(i),
		nRst0            => nRST_bk_rxclk(i),
		datain           => error_check_num_rxbkclk((i+1)*16-1 downto i*16),
		datain_req       => '1',

		clk1             => sysclk,
		nRst1            => nRST_sys,
		data_out         => error_check_num_sys((i+1)*16-1 downto i*16),
		dataout_valid    => open

	);
cross2_i :  cross_domain
	generic map (
	   DATA_WIDTH  => 16
	)
	port map
	(   clk0             => rx_bk_clk(i),
		nRst0            => nRST_bk_rxclk(i),
		datain           => error_fe_num_rxbkclk((i+1)*16-1 downto i*16),
		datain_req       => '1',

		clk1             => sysclk,
		nRst1            => nRST_sys,
		data_out         => error_fe_num_sys((i+1)*16-1 downto i*16),
		dataout_valid    => open

	);
end generate packet_cross_i;

backup_flag_sys <= backup_flag_d2;

 p_sched_i: param_sched   
    generic map( 
       UNIT_NUM     =>  FIBER_NUM , --4  FOR 5G for fiber 2 or 4, for 5G 4 ;
       ETH_PER_UNIT =>  ETHPORT_NUM ,--1  FOR 5G  --EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
	   IS_5G        =>  SERDES_5G_EN
    ) 
port map
(  nRST  => nRST_conv ,
   clk   => convclk_i  ,
   
   vsync_i                =>vsync_neg_conv_o(0) ,
   rt_tx_done             => rt_tx_done ,
    --pbus 
    p_Frame_en_i          =>  p_Frame_en_conv     ,
    p_Wren_i              =>  p_Wren_conv         ,
    p_Data_i              =>  p_Data_conv         ,
    p_Addr_i              =>  p_Addr_conv         ,
	cur_slot_num          =>  cur_slot_num ,
    ----clock domain is conv here 
    quick08_wren         =>   quick08_wren_conv        , ---
    quick08_waddr        =>   quick08_waddr_conv       , ---
    quick08_wdata        =>   quick08_wdata_conv       , ---
	quick08_flg          =>   quick08_flg_conv,
    quick08_filter_en    =>   quick08_filter_en_conv   , --------
    quick08_addr_len     =>   quick08_addr_len_conv    , ---
    --dispatch to downparam_tx 
    p_Frame_en_o         =>  p_Frame_en_f_conv   ,
    p_Wren_o             =>  p_Wren_f_conv       ,
    p_Data_o             =>  p_Data_f_conv       ,
    p_Addr_o             =>  p_Addr_f_conv       ,
   ---------------------------------------------------------------------    
    unit_connected      =>   unit_connected_conv ,
    eth_connected       =>   eth_connected_conv  ,
    -------------------------------------------------------------
    tx07_cc_req        =>  tx07_cc_req      ,--- --tx one 0x7 packet ;if the unit has many eth port ,then notify 
    tx07_cc_idx        =>  tx07_cc_idx      ,---ernal index in one unit  at most 10 eth port ,which port to 
    tx07_cc_ack        =>  tx07_cc_ack      ,---
    tx07_cc_txdone     =>  tx07_cc_txdone   ,--- --when data is tx out to FIBER or 5G port 
    tx07_cc_end        =>  open      ,---wnparam_tx can switch its ping-pong now )
    up08_start_timer   =>   up08_start_timer_conv,--NOTIFY ,turn signal ,0to1 or  1to0 
    Up08_net_rel_idx   =>   Up08_net_rel_idx_conv,---  --NOTIFY ,
    up08_timeout       =>   up08_timeout_conv  ,   --- --every unit up one 
	real_eth_num_conv  =>   real_eth_num_conv
  ); 


        -- c2s_detect3_i: cross_domain  generic map ( DATA_WIDTH  => 8)
	      -- port map
	      -- (    clk0             => convclk_i ,
	           -- nRst0            => nRST_conv  ,
	           -- datain           => quick08_addr_len_conv,
	           -- datain_req       => '1',		                 
	           -- clk1             => sysclk,
	           -- nRst1            => nRST_sys,
	           -- data_out         => quick08_addr_len_sys,
	           -- dataout_valid    => open      	
	      -- );  

  
    -- c2s_n_i: cross_domain  generic map ( DATA_WIDTH  => 8)
	      -- port map
	      -- (    clk0             => convclk_i ,
	           -- nRst0            => nRST_conv  ,
	           -- datain           => Up08_net_rel_idx_conv ,
	           -- datain_req       => '1',		                 
	           -- clk1             => sysclk,
	           -- nRst1            => nRST_sys,
	           -- data_out         => Up08_net_rel_idx_sys ,
	           -- dataout_valid    => open	      	
	      -- );
 -- crs_notif_i: for i in 0 to FIBER_NUM-1 generate 
      -- c2s_n_i: cross_domain  generic map ( DATA_WIDTH  => 1)
	      -- port map
	      -- (    clk0             => convclk_i ,
	           -- nRst0            => nRST_conv  ,
	           -- datain           => (others=>'0'),
	           -- datain_req       => up08_start_timer_conv(i),		                 
	           -- clk1             => sysclk,
	           -- nRst1            => nRST_sys,
	           -- data_out         => open ,
	           -- dataout_valid    => up08_start_timer_sys(i)	      	
	      -- );
      -- s2c_n_i: cross_domain  generic map ( DATA_WIDTH  => 1)
	      -- port map
	      -- (    clk0             =>  sysclk,
	           -- nRst0            =>  nRST_sys,
	           -- datain           =>  (others=>'0') ,
	           -- datain_req       =>  up08_timeout_sys(i),			                 
	           -- clk1             =>  convclk_i   ,
	           -- nRst1            =>  nRST_conv   ,
	           -- data_out         =>  open        ,
	           -- dataout_valid    =>  up08_timeout_conv(i)      	
	      -- );   

   -- c2s_n_i: altera_std_synchronizer generic map (depth =>4) port map 
      -- (clk     => sysclk ,
       -- reset_n => nRST_sys ,
       -- din     => up08_start_timer_conv(i),
       -- dout    => up08_start_timer_sys(i)
     -- );	
   -- s2c_n_i: altera_std_synchronizer generic map (depth =>4) port map 
      -- (clk     => convclk_i ,
       -- reset_n => nRST_conv ,
       -- din     => up08_timeout_sys(i),
       -- dout    => up08_timeout_conv(i)
     -- );	

	 
   -- quick_detect: altera_std_synchronizer generic map (depth =>4) port map 
      -- (clk     => sysclk ,
       -- reset_n => nRST_sys ,
       -- din     => quick08_filter_en_conv(i),
       -- dout    => quick08_filter_en_sys(i)
     -- );	
   -- flg_detect: altera_std_synchronizer generic map (depth =>4) port map 
      -- (clk     => sysclk ,
       -- reset_n => nRST_sys ,
       -- din     => quick08_flg_conv(i),
       -- dout    => quick08_flg_sys(i)
     -- );		 
		  
 -- end generate crs_notif_i;
  chan_i: for i in 0 to FIBER_NUM-1 GENERATE
        oneFiber_i: bk2fiber_oneFiber
        generic map
        (
           SIM               => SIM ,
           SERDES_5G_EN      => SERDES_5G_EN,
           ETHPORT_NUM       => ETHPORT_NUM , --how many eth port IN ONE FIBER
           ETH_IDX           => i ,
           BKHSSI_NUM        => 2,
           G12_9BYTE_EN      =>G12_9BYTE_EN    --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS
        )
        port map
        (
          nRST_bk_rxclk         =>  nRST_bk_rxclk       ( (i+1)* 2-1 downto i*2  ) ,
          rx_bk_clk             =>  rx_bk_clk           ( (i+1)* 2-1 downto i*2  ) ,
          rx_bk_parallel_data   =>  rx_bk_parallel_data ((i+1)*64*2-1 downto i*64*2 ),
          rx_bk_control         =>  rx_bk_control       ((i+1)* 8*2-1 downto i*8*2  ),

		  vsync_neg_conv_o      =>  vsync_neg_conv_o(i),
		  rt_tx_done            =>  rt_tx_done(i),	  	
		  rcv_led		        =>  rcv_led_out ,
	      backup_flag           =>  backup_flag_sel((i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM) ,

          nRST_conv             =>  nRST_conv  ,
          convclk_i             =>  convclk_i     , 
          p_Frame_en_conv       =>  p_Frame_en_conv   , 
          p_Wren_conv           =>  p_Wren_conv       , 
          p_Data_conv           =>  p_Data_conv              , 
          p_Addr_conv           =>  p_Addr_conv              , 
          cur_slot_num          =>  cur_slot_num     , 
		  
		  p_Frame_en_f_conv     =>  p_Frame_en_f_conv(i)   , 
		  p_Wren_f_conv         =>  p_Wren_f_conv    (i)   , 
		  p_Data_f_conv         =>  p_Data_f_conv              , 
		  p_Addr_f_conv         =>  p_Addr_f_conv              , 
          
          tx07_cc_req      =>  tx07_cc_req    (i) , ---- --tx one 0x7 packet ;if the unit has many eth port ,then notify 
          tx07_cc_idx      =>  tx07_cc_idx    , ----((i+1)*4-1 downto i*4) , ----nal index in one unit  at most 10 eth port ,which port to 
          tx07_cc_ack      =>  tx07_cc_ack    (i) , ----
          tx07_cc_txdone   =>  tx07_cc_txdone (i) , ---- --when data is tx out to FIBER or 5G port 
 
    
           req_f9_upload          => req_f9_upload , ---
           secret_data          => secret_data       , 
           hdr_enable           => hdr_enable        ,
           hdr_type             => hdr_type          ,
           hdr_rr               => hdr_rr            ,
           hdr_rg               => hdr_rg            ,
           hdr_rb               => hdr_rb            ,
           hdr_gr               => hdr_gr            ,
           hdr_gg               => hdr_gg            ,
           hdr_gb               => hdr_gb            ,
           hdr_br               => hdr_br            ,
           hdr_bg               => hdr_bg            ,
           hdr_bb               => hdr_bb            ,
           hdr_coef             => hdr_coef          ,
           hlg_type             => hlg_type          ,

           virtual_pix_en       => virtual_pix_en    ,
           virtual_direction    => virtual_direction ,

           colorspace            => colorspace              ,
           PN_frame_type         => PN_frame_type           ,
           bright_weight         => bright_weight           ,
		   invert_dissolve_level => invert_dissolve_level   ,
           vsync_param_update_en => vsync_param_update_en(i),
		   function_enable       => function_enable ,

           xgmii_txclk          => xgmii_txclk  , ---(i) ,
           nRST_xgmii           => nRST_xgmii   , ---(i) ,
           xgmii_data           => xgmii_data   ( i *64+63 downto i*64),
           xgmii_control        => xgmii_control( i *8 + 7 downto i* 8) ,
		   color_depth_o      => 	 color_depth_o ((i+1)*2-1 downto i*2)   ,

			eth_bright_value  =>  eth_bright_value_sel((i+1)*ETHPORT_NUM*8-1 downto i*ETHPORT_NUM*8) ,
			eth_color_R       =>  eth_color_R_sel((i+1)*ETHPORT_NUM*8-1 downto i*ETHPORT_NUM*8)       ,
			eth_color_G       =>  eth_color_G_sel((i+1)*ETHPORT_NUM*8-1 downto i*ETHPORT_NUM*8)      ,
			eth_color_B       =>  eth_color_B_sel((i+1)*ETHPORT_NUM*8-1 downto i*ETHPORT_NUM*8)       ,
			low_bright_en     =>  low_bright_en   ,

	        clr_serdesinfo_convclk      => clr_serdesinfo_convclk,
	        subbrdin_packet_cnt_rxbkclk => subbrdin_packet_cnt_rxbkclk((i+1)*32*2-1 downto i*32*2 ),
	        error_fe_num_rxbkclk        => error_fe_num_rxbkclk((i+1)*16*2-1 downto i*16*2 ),
	        error_check_num_rxbkclk     => error_check_num_rxbkclk((i+1)*16*2-1 downto i*16*2 ),

			eth_forbid_en_convclk             => eth_forbid_en_sel((i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM),
			eth_mask_en_convclk				  => eth_mask_en_convclk((i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM),
			
	        shutter_rsp_dvld                  => shutter_rsp_dvld(i)    ,    
	        shutter_rsp_data                  => shutter_rsp_data(72-1 downto 0),         
	        shutter_rd_eth_index              => shutter_rd_eth_index ((i+1)*4-1 downto i*4),       
	        shutter_rd_frm_index              => shutter_rd_frm_index  ((i+1)*15-1 downto i*15),       
	        shutter_rd_req                    => shutter_rd_req (i)    ,             
	        shutter_rd_ack                    => shutter_rd_ack (i)    ,
			shutter_rd_frmvld                 => shutter_rd_frmvld(i),
			shutter_rd_end                	  => shutter_rd_end(i)	,
			
			real_eth_num_conv                 => real_eth_num_conv




        );

    end generate chan_i;
	
	
process(nRST_conv,convclk_i)	
begin
	if nRST_conv = '0' then
	
	elsif rising_edge(convclk_i) then
		if real_eth_num_conv = 10 then
			backup_flag_sel        	<= backup_flag;
			eth_forbid_en_sel      	<= eth_forbid_en_convclk;
			eth_bright_value_sel    <= eth_bright_value;
			eth_color_R_sel         <= eth_color_R;
			eth_color_G_sel         <= eth_color_G;
			eth_color_B_sel         <= eth_color_B;
		else------ eth num = 4
			backup_flag_sel   <= "000000"&backup_flag(7 downto 4)&"000000"&backup_flag(3 downto 0);
			eth_forbid_en_sel <= "000000"&eth_forbid_en_convclk(7 downto 4)&"000000"&eth_forbid_en_convclk(3 downto 0);
			eth_bright_value_sel <= (others=>'0');
			eth_bright_value_sel(4*8-1 downto 0) <= eth_bright_value(4*8-1 downto 0 );
			eth_bright_value_sel(4*8+ETHPORT_NUM*8-1 downto ETHPORT_NUM*8) <= eth_bright_value(8*8-1 downto 4*8 );
	
			eth_color_R_sel <= (others=>'0');
			eth_color_R_sel(4*8-1 downto 0) <= eth_color_R(4*8-1 downto 0 );
			eth_color_R_sel(4*8+ETHPORT_NUM*8-1 downto ETHPORT_NUM*8) <= eth_color_R(8*8-1 downto 4*8 );	
			eth_color_G_sel <= (others=>'0');
			eth_color_G_sel(4*8-1 downto 0) <= eth_color_G(4*8-1 downto 0 );
			eth_color_G_sel(4*8+ETHPORT_NUM*8-1 downto ETHPORT_NUM*8) <= eth_color_G(8*8-1 downto 4*8 );	
			eth_color_B_sel <= (others=>'0');
			eth_color_B_sel(4*8-1 downto 0) <= eth_color_B(4*8-1 downto 0 );
			eth_color_B_sel(4*8+ETHPORT_NUM*8-1 downto ETHPORT_NUM*8) <= eth_color_B(8*8-1 downto 4*8 );	
		end if;
	end if;
end process;

param_inst: global_ctrl
generic map
(  SIM               => SIM           ,
   SERDES_5G_EN      => SERDES_5G_EN  ,
   FIBER_NUM         => FIBER_NUM     ,
   ETHPORT_NUM       => ETHPORT_NUM
)
port map
(

    nRST_conv         => nRST_conv,
    convclk_i         => convclk_i,

    time_ms_en_conv   => time_ms_en_conv    ,
    vsync_neg         => vsync_neg_conv_o(0),
    p_Frame_en_conv   => p_Frame_en_conv  ,
    p_Wren_conv       => p_Wren_conv      ,
    p_Data_conv       => p_Data_conv      ,
    p_Addr_conv       => p_Addr_conv      ,

	rcv_led_out		  => rcv_led_out ,
	backup_flag       => backup_flag ,
    req_f9_upload     => req_f9_upload ,
	HDR_enable        =>  HDR_enable   ,
	HDR_type          =>  HDR_type     ,
	HDR_rr            =>  HDR_rr       ,
	HDR_rg            =>  HDR_rg       ,
	HDR_rb            =>  HDR_rb       ,
	HDR_gr            =>  HDR_gr       ,
	HDR_gg            =>  HDR_gg       ,
	HDR_gb            =>  HDR_gb       ,
	HDR_br            =>  HDR_br       ,
	HDR_bg            =>  HDR_bg       ,
	HDR_bb            =>  HDR_bb       ,
	HDR_coef          =>  HDR_coef     ,
	HLG_type          =>  HLG_type     ,
	secret_data       =>  secret_data  ,
	virtual_pix_en    =>  virtual_pix_en   ,
	virtual_direction =>  virtual_direction,
	eth_bright_value  =>  eth_bright_value ,
	eth_color_R       =>  eth_color_R      ,
	eth_color_G       =>  eth_color_G      ,
	eth_color_B       =>  eth_color_B      ,
	low_bright_en     =>  low_bright_en   ,
	eth_forbid_en_convclk     =>  eth_forbid_en_convclk,
	eth_mask_en_convclk		=> eth_mask_en_convclk,
	clr_serdesinfo_convclk => clr_serdesinfo_convclk,
    colorspace_buf         => colorspace    ,
	PN_frame_type_buf      => PN_frame_type ,
	bright_weight_buf      => bright_weight ,
	invert_dissolve_level_buf      => invert_dissolve_level,
	vsync_param_update_en  => vsync_param_update_en,
	function_enable        => function_enable

);

end beha;



