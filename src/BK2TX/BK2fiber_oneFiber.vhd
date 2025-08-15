library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;


entity bk2fiber_oneFiber is
generic
(  SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic := '0';
   FIBER_NUM         : integer   := 1  ;  ---2 to 2

   NOXGMII_HEAD      : std_logic := '1'; --'1' :no  D55555555555FB
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

	vsync_neg_conv_o     : out std_logic;
    rt_tx_done           : out std_logic;
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

    tx07_cc_req           : in   std_logic ; --tx one 0x7 packet ;if the unit has many eth port ,then notify 
    tx07_cc_idx           : in   std_logic_vector(3           downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
    tx07_cc_ack           : out  std_logic ;
    tx07_cc_txdone        : out  std_logic ; --when data is tx out to FIBER or 5G port 
    xgmii_txclk           : in  std_logic  ;
    nRST_xgmii            : in  std_logic  ;
    xgmii_data            : out std_logic_vector( 64-1 downto 0);
    xgmii_control         : out std_logic_vector( 8 -1 downto 0);

    secret_data          :in  std_logic_vector(47 downto 0):= (others => '0');
    req_f9_upload         : in  std_logic    ; ---
	rcv_led		         : in std_logic_vector(1 downto 0);
	backup_flag          : in std_logic_vector(ETHPORT_NUM-1 downto 0);

    hdr_enable           :in  std_logic:= '0';
    hdr_type             :in  std_logic_vector(7 downto 0):= (others => '0');
    hdr_rr               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_rg               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_rb               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gr               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gg               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gb               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_br               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_bg               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_bb               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_coef             :in  std_logic_vector(5 downto 0):= (others => '0');
    hlg_type             :in  std_logic_vector(7 downto 0):= (others => '0');
	color_depth_o        : out std_logic_vector(1 downto 0);

    virtual_pix_en       :in  std_logic_vector(1 downto 0):= (others => '0');
    virtual_direction    :in  std_logic_vector(1 downto 0):= (others => '0');

    colorspace           : in std_logic_vector(2  downto 0);
	PN_frame_type        : in std_logic_vector(19 downto 0);
	bright_weight        : in std_logic_vector(89 downto 0);
	invert_dissolve_level : in std_logic_vector(10*4-1 downto 0);
    vsync_param_update_en : out std_logic;
	function_enable       : in  std_logic_vector(15 downto 0);
    
	eth_bright_value   : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_R        : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_G        : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_B        : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	low_bright_en      : in std_logic;

	clr_serdesinfo_convclk           : in  std_logic;
	subbrdin_packet_cnt_rxbkclk      : out std_logic_vector(BKHSSI_NUM*32-1 downto 0);
	error_fe_num_rxbkclk             : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);
	error_check_num_rxbkclk          : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);
	eth_forbid_en_convclk            : in std_logic_vector(ETHPORT_NUM-1 downto 0);
	eth_mask_en_convclk				: in std_logic_vector(ETHPORT_NUM-1 downto 0);
	
	shutter_rsp_dvld                 : in  std_logic;
	shutter_rsp_data                 : in  std_logic_vector(71 downto 0);
	shutter_rd_eth_index             : out std_logic_vector(3 downto 0);
	shutter_rd_frm_index             : out std_logic_vector(14 downto 0);
	shutter_rd_req                   : out std_logic;
	shutter_rd_ack                   : in  std_logic;
	shutter_rd_frmvld                : in  std_logic;
	shutter_rd_end                   : in  std_logic;

	real_eth_num_conv                : in  std_logic_vector(3 downto 0)	
	
);

end bk2fiber_oneFiber;

architecture beha of bk2fiber_oneFiber is

signal xgmii_txout : std_logic_vector(  FIBER_NUM*72-1 downto 0);
component bk2fiber_chan is
generic
(
   SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic;
   NOXGMII_HEAD      : std_logic;
   ETHPORT_NUM       : integer ; --how many eth port
   FIBER_NUM         : integer ;
   BKHSSI_NUM        : integer ;
   G12_9BYTE_EN      : STD_LOGIC := '1'   --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS
);
port
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);
    vsync_out_rxc         : out std_logic ;


    nRST_conv            : in  std_logic    ; ---
    convclk_i            : in  std_logic    ; --200M almost
    xgmii_wren           : out std_logic_vector(ETHPORT_NUM-1 downto 0);
    xgmii_data_out       : out std_logic_vector(FIBER_NUM*64-1 downto 0);
    xgmii_control        : out std_logic_vector(FIBER_NUM*8 -1 downto 0);
    vsync_out_conv       : out std_logic ;
    vsync_neg_conv_o     : out std_logic ;
    ---packet count


    vidinfo_wren         : out std_logic_vector(ETHPORT_NUM-1 downto 0);
    --bit10: broadcast
    --bit 9: '0': down cmd, '1':RT
    --BIT8~0: LENGTH IN 64BIT including end flag
    vidinfo_wdata        : out  std_logic_vector(20 downto 0);


    p_Frame_en_conv       : in std_logic ;
    p_Wren_conv           : in std_logic ;
    p_Data_conv           : in std_logic_vector(7 downto 0);
    p_Addr_conv           : in std_logic_vector(10 downto 0);
    cur_slot_num          : in std_logic_vector(15 downto 0);


    secret_data          : in  std_logic_vector(47 downto 0):= (others => '0');
	rcv_led		         : in  std_logic_vector(1 downto 0);
	backup_flag          : in  std_logic_vector(ETHPORT_NUM-1 downto 0);
    req_f9_upload        : in  std_logic    ; ---
    hdr_enable           :in  std_logic:= '0';
    hdr_type             :in  std_logic_vector(7 downto 0):= (others => '0');
    hdr_rr               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_rg               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_rb               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gr               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gg               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_gb               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_br               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_bg               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_bb               :in  std_logic_vector(15 downto 0):= (others => '0');
    hdr_coef             :in  std_logic_vector(5 downto 0):= (others => '0');
    hlg_type             :in  std_logic_vector(7 downto 0):= (others => '0') ;
	color_depth_o        : out std_logic_vector(1 downto 0);
	eth_bright_value     : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_R          : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_G          : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_B          : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	low_bright_en        : in std_logic;
    virtual_pix_en       :in  std_logic_vector(1 downto 0):= (others => '0');
    virtual_direction    :in  std_logic_vector(1 downto 0):= (others => '0');
    colorspace           : in std_logic_vector(2  downto 0);
	PN_frame_type        : in std_logic_vector(19 downto 0);
	bright_weight        : in std_logic_vector(89 downto 0);
	invert_dissolve_level : in std_logic_vector(10*4-1 downto 0);
    vsync_param_update_en : out std_logic;
	function_enable       : in  std_logic_vector(15 downto 0);

	clr_serdesinfo_convclk        : in  std_logic;
	subbrdin_packet_cnt_rxbkclk   : out std_logic_vector(BKHSSI_NUM*32-1 downto 0);
	error_fe_num_rxbkclk          : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);
	error_check_num_rxbkclk       : out std_logic_vector(BKHSSI_NUM*16-1 downto 0);
	
	frm8a_rd_point_main           : out std_logic_vector(9 downto 0);
	frm8a_rd_point_back           : out std_logic_vector(9 downto 0);
    frm8a_man_notify_en           : out std_logic;
	frm8a_man_en                  : out std_logic;
	
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)
);
end component;
signal   vidinfo_full         :   std_logic ;
signal   vidinfo_wusedw       :   std_logic_vector(6 -1 downto 0);
signal   vidinfo_wren         :   std_logic_vector(ETHPORT_NUM-1 downto 0) ;
signal   vidinfo_wdata        :   std_logic_vector(21-1  downto 0);
signal   vidinfo_empty        :   std_logic_vector(ETHPORT_NUM-1 downto 0) ;
signal   vidinfo_rden         :   std_logic_vector(ETHPORT_NUM-1 downto 0) ;
signal   vidinfo_rdata        :   std_logic_vector(ETHPORT_NUM*21 -1 downto 0);

signal	frm8a_rd_point_main           :  std_logic_vector(9 downto 0);
signal	frm8a_rd_point_back           :  std_logic_vector(9 downto 0);
signal 	frm8a_man_notify_en           :  std_logic;
signal  frm8a_man_en                  :  std_logic;


component downparam_tx is
generic
(  sim     : std_logic := '0';
   IS_5G    : std_logic ;
   IS_BACK : std_logic := '0'; ---main or backup
   NOXGMII_HEAD : std_logic := '1'; ---'1':
   P_W     : INTEGER   := 4  ; ---Depend on IS_BACK AND eth_num
   ETH_IDX_F : INTEGER   := 0  ; ---STARTING INDEX ------
   ETH_IDX : INTEGER   := 0  ; 
   ETH_NUM : INTEGER   := 10
);
port
(
    nRST            : in std_logic ;
    clk_i           : in std_logic ;
    p_Frame_en_i    : in std_logic ;
    p_Wren_i        : in std_logic ;
    p_Data_i        : in std_logic_vector(7 downto 0);
    p_Addr_i        : in std_logic_vector(10 downto 0);
    cur_slot_num    : in std_logic_vector(15 downto 0);
	
    p_Frame_en_i_orig    : in std_logic ;
    p_Wren_i_orig        : in std_logic ;
    p_Data_i_orig        : in std_logic_vector(7 downto 0);
    p_Addr_i_orig        : in std_logic_vector(10 downto 0);

    vsync_neg_i     : in std_logic ;
    rt_tx_done      : out std_logic ; ---rt_tx_done to tx 
    ---------------------------------------------------
    txparam_wren      : out std_logic ;
    txparam_wdata     : out std_logic_vector(72 downto 0);
    txparam_waddr_o   : out std_logic_vector( 8 downto 0); --512*80bit at most

	txdpram_posdec_en_xgmiitx  : in std_logic ;
    
    tx07_cc_req     :  in   std_logic ; --tx one 0x7 packet ;if the unit has many eth port ,then notify 
    tx07_cc_idx     :  in   std_logic_vector(3 downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
    tx07_cc_ack     :  out  std_logic ;
    tx07_cc_done    :  out  std_logic ;
  
    
    ---rtparam_wren      : out std_logic ;
    ---rtparam_wdata     : out std_logic_vector(72 downto 0);
    ---rtparam_waddr     : out std_logic_vector(8 downto 0);
    -----------------------------------------------------------
    rt_cmdfifo_wusedw : in  std_logic_vector(4 downto 0);
    rt_cmdfifo_full   : in  std_logic ;
    rt_cmdfifo_wren   : out std_logic;
    --bit10: broadcast
    --bit 9: '0': down cmd, '1':RT
    --BIT8~0: LENGTH IN 64BIT including end flag
    rt_cmdfifo_wdata  : out std_logic_vector(12 downto 0);  --length of 64bits

	frm8a_rd_point_main           : in std_logic_vector(9 downto 0);
	frm8a_rd_point_back           : in std_logic_vector(9 downto 0);
	frm8a_man_notify_en           : in std_logic;
	frm8a_man_en                  : in std_logic;
	
	shutter_rsp_dvld              : in std_logic;
	shutter_rsp_data              : in std_logic_vector(71 downto 0);
	shutter_rd_eth_index          : out std_logic_vector(3 downto 0);
	shutter_rd_frm_index          : out std_logic_vector(14 downto 0);
	shutter_rd_req                : out std_logic;
	shutter_rd_ack                : in  std_logic;
	shutter_rd_frmvld             : in  std_logic;
	shutter_rd_end                : in  std_logic;
	
	eth_mask_en_convclk			  : in  std_logic_vector(ETHPORT_NUM-1 downto 0);
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)

   );
end  component ;

SIGNAL  rt_cmdfifo_rusedw :   std_logic_vector(6 -1  downto 0):=(others=>'0');
SIGNAL  rt_cmdfifo_empty  :   std_logic ;
SIGNAL  rt_cmdfifo_rden   :   std_logic ;
SIGNAL  rt_cmdfifo_rdata  :   std_logic_vector(13 -1  downto 0) ;

signal   rt_cmdfifo_wusedw :   std_logic_vector(5  -1 downto 0);
signal   rt_cmdfifo_full   :   std_logic  ;
signal   rt_cmdfifo_wren   :   std_logic  ;
signal   rt_cmdfifo_wdata  :   std_logic_vector(13 -1 downto 0);

component xgmii_cmb is
generic
(
  NOXGMII_HEAD : STD_LOGIC;
  ETH_NUM : INTEGER := 10

);
port
(
  nRST   : in std_logic;
  clk_i  : in std_logic;

   vsync_neg_i       : in std_logic;


   vidfifo_rdata     : in  std_logic_vector(ETHPORT_NUM*72-1 downto 0);
   vidfifo_rden      : out std_logic_vector(ETHPORT_NUM-1 downto 0);
   vidinfo_empty     : in  std_logic_vector(ETHPORT_NUM-1 downto 0);
   vidinfo_rden      : out std_logic_vector(ETHPORT_NUM-1 downto 0);
   vidinfo_rdata     : in  std_logic_vector(ETHPORT_NUM*21-1 downto 0);

   txparam_rden      : out std_logic ;
   txparam_rdata     : in  std_logic_vector(72 downto 0);
   txparam_raddr     : out std_logic_vector( 8 downto 0); --512*80bit at most
   txdpram_posdec_en_xgmiitx  : out std_logic ;

   rt_cmdfifo_rusedw : in  std_logic_vector(5 downto 0);
   rt_cmdfifo_empty  : in  std_logic ;
   rt_cmdfifo_rden   : out std_logic;
    --bit10: broadcast
    --bit 9: '0': down cmd, '1':RT
    --BIT8~0: LENGTH IN 64BIT including end flag
   rt_cmdfifo_rdata  : in  std_logic_vector(12 downto 0) ; --length of 64bits
   ----to fiber interface
   xgmii_txout      : out std_logic_vector(71 downto 0);

   eth_forbid_en_convclk    : in std_logic_vector(ETHPORT_NUM-1 downto 0);
   eth_mask_en_convclk		: in std_logic_vector(ETHPORT_NUM-1 downto 0);
   
   real_eth_num             : in std_logic_vector(3 downto 0)
);

end component ;

signal   vsync_out_rxc       : std_logic ;
signal   txdpram_posdec_en_xgmiitx  :  std_logic := '0';

signal   vsync_neg_xgmii     : std_logic ;
signal   vsync_synced_xgmii  : std_logic ;

signal   vsync_out_conv      : std_logic ;
signal   vsync_neg_conv      : std_logic ;
signal   vid_fifo_wren       : std_logic_vector(ETHPORT_NUM-1 downto 0) ;
signal   vid_fifo_wren_buf   : std_logic_vector(ETHPORT_NUM-1 downto 0) ;
signal   vid_fifo_wdata      : std_logic_vector( 72-1    downto 0):=(others=>'0');
----signal   tx_control      :   std_logic_vector(FIBER_NUM*8 -1    downto 0);
signal   vidfifo_empty       : std_logic_vector(ETHPORT_NUM-1 downto 0) ;
signal   vidfifo_full        : std_logic_vector(ETHPORT_NUM-1 downto 0) ;

signal   vidfifo_rdata       : std_logic_vector(ETHPORT_NUM*72 -1 downto 0);
signal   vidfifo_rden        : std_logic_vector(ETHPORT_NUM-1 downto 0) ;
signal   real_eth_num_xgmii  : std_logic_vector(3 downto 0);

signal pfifo_aclr : std_logic := '0';
   component tx_vid_fifo is
        port (
            data    : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
            wrreq   : in  std_logic                     := 'X';             -- wrreq
            rdreq   : in  std_logic                     := 'X';             -- rdreq
            wrclk   : in  std_logic                     := 'X';             -- wrclk
            rdclk   : in  std_logic                     := 'X';             -- rdclk
            aclr    : in  std_logic                     := 'X';             -- aclr
            q       : out std_logic_vector(71 downto 0);                    -- dataout
            rdempty : out std_logic;                                        -- rdempty
            wrfull  : out std_logic                                         -- wrfull
        );
    end component tx_vid_fifo;
    component txInfoFifo is
        port (
            data    : in  std_logic_vector(20 downto 0) := (others => 'X'); -- datain
            wrreq   : in  std_logic                     := 'X';             -- wrreq
            rdreq   : in  std_logic                     := 'X';             -- rdreq
            wrclk   : in  std_logic                     := 'X';             -- wrclk
            rdclk   : in  std_logic                     := 'X';             -- rdclk
            aclr    : in  std_logic                     := 'X';             -- aclr
            q       : out std_logic_vector(20 downto 0);                    -- dataout
            rdempty : out std_logic;                                        -- rdempty
            wrfull  : out std_logic                                         -- wrfull
        );
    end component txInfoFifo;


    component txParamFifo is
        port (
            data    : in  std_logic_vector(12 downto 0) := (others => 'X'); -- datain
            wrreq   : in  std_logic                     := 'X';             -- wrreq
            rdreq   : in  std_logic                     := 'X';             -- rdreq
            wrclk   : in  std_logic                     := 'X';             -- wrclk
            rdclk   : in  std_logic                     := 'X';             -- rdclk
            aclr    : in  std_logic                     := 'X';             -- aclr
            q       : out std_logic_vector(12 downto 0);                    -- dataout
            rdusedw : out std_logic_vector(4 downto 0);                     -- rdusedw
            wrusedw : out std_logic_vector(4 downto 0);                     -- wrusedw
            rdempty : out std_logic;                                        -- rdempty
            wrfull  : out std_logic                                         -- wrfull
        );
    end component txParamFifo;


    component txParam_dram is
        port (
            data      : in  std_logic_vector(72 downto 0) := (others => 'X'); -- datain
            q         : out std_logic_vector(72 downto 0);                    -- dataout
            wraddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- wraddress
            rdaddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- rdaddress
            wren      : in  std_logic                     := 'X';             -- wren
            wrclock   : in  std_logic                     := 'X';             -- clk
            rdclock   : in  std_logic                     := 'X'              -- clk
        );
    end component txParam_dram;

signal     txparam_wdata : std_logic_vector(  73-1 downto    0) ;     --      data.datain
signal     txparam_rdata : std_logic_vector(  73-1 downto    0) ;        --         q.dataout
signal     txparam_waddr : std_logic_vector(  11-1 downto    0) ; -- wraddress.wraddress
signal     txparam_raddr : std_logic_vector(  9-1  downto    0) ; -- rdaddress.rdaddress
signal     txparam_wren  : std_logic  ;                        --      wren.wren
SIGNAL     txparam_rden  :   std_logic ;
      component vsync_neg_edge is
           generic (DLY_CY : integer := 3);
           port
           (
             vsync_async : in  std_logic ; --register out
             nRST        : in  std_logic ;
             clk         : in  std_logic ;
             vsync_neg   : out std_logic;
             vsync_synced: out std_logic
           );
     end component;
	 
	 
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



begin

         pfifo_aclr <= not nRST_conv;
		 vsync_neg_conv_o <= vsync_neg_conv;

         bk_rcv_i: bk2fiber_chan
        generic map
        (
           SIM               => SIM ,
           NOXGMII_HEAD      => NOXGMII_HEAD,
           SERDES_5G_EN      => SERDES_5G_EN,
           ETHPORT_NUM       => ETHPORT_NUM , --how many eth port IN ONE FIBER
           FIBER_NUM         => 1,
           BKHSSI_NUM        => 2,
           G12_9BYTE_EN      =>G12_9BYTE_EN    --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS
        )
        port map
        (
           nRST_bk_rxclk         =>  nRST_bk_rxclk       ( 2-1 downto     0  ) ,
           rx_bk_clk             =>  rx_bk_clk           ( 2-1 downto     0  ) ,
           rx_bk_parallel_data   =>  rx_bk_parallel_data (64*2-1 downto   0  ),
           rx_bk_control         =>  rx_bk_control       ( 8*2-1 downto   0  ),
           vsync_out_rxc         =>  vsync_out_rxc      ,

           nRST_conv            =>  nRST_conv  ,
           convclk_i            =>  convclk_i     ,
           xgmii_wren           =>  vid_fifo_wren_buf   ,
           xgmii_data_out       =>  vid_fifo_wdata ( 63 downto    0   ),
           xgmii_control        =>  vid_fifo_wdata ( 71 downto   64  ),
           vsync_out_conv       =>  vsync_out_conv  ,
           vsync_neg_conv_o     =>  vsync_neg_conv  ,
           ----------------------------------------

           vidinfo_wren         => vidinfo_wren ,
           vidinfo_wdata        => vidinfo_wdata(  21-1 downto 0  ),

           p_Frame_en_conv       =>  p_Frame_en_conv   ,
           p_Wren_conv           =>  p_Wren_conv       ,
           p_Data_conv           =>  p_Data_conv       ,
           p_Addr_conv           =>  p_Addr_conv       ,
           cur_slot_num          =>  cur_slot_num     ,

		   rcv_led		         =>  rcv_led,
	       backup_flag           =>  backup_flag,
          req_f9_upload          =>  req_f9_upload  ,----       : in  std_logic    ; ---
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
		   color_depth_o        => color_depth_o ,
	       eth_bright_value     => eth_bright_value ,
	       eth_color_R          => eth_color_R      ,
	       eth_color_G          => eth_color_G      ,
	       eth_color_B          => eth_color_B      ,
	       low_bright_en        => low_bright_en    ,
           virtual_pix_en       => virtual_pix_en   ,
           virtual_direction    => virtual_direction,
           colorspace           => colorspace       ,
           PN_frame_type        => PN_frame_type    ,
           bright_weight        => bright_weight    ,
		   invert_dissolve_level  => invert_dissolve_level ,
           vsync_param_update_en => vsync_param_update_en,
		   function_enable       => function_enable,
	       clr_serdesinfo_convclk        => clr_serdesinfo_convclk    ,
	       subbrdin_packet_cnt_rxbkclk   => subbrdin_packet_cnt_rxbkclk  ,
	       error_fe_num_rxbkclk          => error_fe_num_rxbkclk      ,
	       error_check_num_rxbkclk       => error_check_num_rxbkclk,
		   frm8a_rd_point_main           => frm8a_rd_point_main,
		   frm8a_rd_point_back           => frm8a_rd_point_back,
		   frm8a_man_notify_en           => frm8a_man_notify_en,
		   frm8a_man_en                  => frm8a_man_en,
		   real_eth_num_conv             => real_eth_num_conv
        );

      vs_crs: vsync_neg_edge
            port map
            (
              vsync_async  => vsync_out_rxc , --register out
              nRST         => nRST_xgmii ,
              clk          => xgmii_txclk ,
              vsync_neg    => vsync_neg_xgmii ,
              vsync_synced => vsync_synced_xgmii
            );
			
	data_buff_inst: for i in 0 to ETHPORT_NUM-1 generate
        vidinfo :   txInfoFifo
        port map (
            data    => vidinfo_wdata(21-1 downto 0),    --  fifo_input.datain
            wrreq   => vidinfo_wren(i)      ,   --            .wrreq
            rdreq   => vidinfo_rden(i)    ,   --            .rdreq
            wrclk   => convclk_i         ,   --            .wrclk
            rdclk   => xgmii_txclk      ,   --            .rdclk
            aclr    => vsync_out_conv  ,    --            .aclr
            q       => vidinfo_rdata ((i+1)*21-1 downto i*21) ,       -- fifo_output.dataout
            rdempty => vidinfo_empty(i)   , --            .rdempty
            wrfull  => open       --            .wrfull
        );

       vid_buf: tx_vid_fifo
        port map(
            data    => vid_fifo_wdata(72-1 downto 0), -- datain
            wrreq   => vid_fifo_wren(i)       ,         -- wrreq
            rdreq   => vidfifo_rden(i)        ,              -- rdreq
            wrclk   => convclk_i         ,            -- wrclk
            rdclk   => xgmii_txclk        ,             -- rdclk
            aclr    => vsync_out_conv      ,             -- aclr
            q       => vidfifo_rdata ((i+1)*72-1 downto i*72),                     -- dataout
            rdempty => vidfifo_empty(i) ,                                       -- rdempty
            wrfull  => vidfifo_full(i)                                         -- wrfull
        );
		vid_fifo_wren(i) <= vid_fifo_wren_buf(i) when vidfifo_full(i) = '0' else  '0';

	end generate;

       para_ch: downparam_tx
        generic map
        (  sim      => sim  ,
           IS_5G   => SERDES_5G_EN,
           NOXGMII_HEAD => NOXGMII_HEAD,
           IS_BACK  => '0' , ---main or backup
           P_W      => P_W , ---Depend on IS_BACK AND eth_num
		   ETH_IDX_F => 0 , ---STARTING INDEX ------
		   ETH_IDX   => ETH_IDX ,
           ETH_NUM   => ETHPORT_NUM  ----ETHPORT_NUM 
        ) 
        port MAP
        (
            nRST            =>  nRST_conv  ,
            clk_i           =>  convclk_i     ,
            p_Frame_en_i    =>  p_Frame_en_f_conv ,
            p_Wren_i        =>  p_Wren_f_conv     ,
            p_Data_i        =>  p_Data_f_conv     ,
            p_Addr_i        =>  p_Addr_f_conv     ,
            cur_slot_num    =>  cur_slot_num   ,
			p_Frame_en_i_orig    => p_Frame_en_conv ,
			p_Wren_i_orig        => p_Wren_conv     ,
			p_Data_i_orig        => p_Data_conv     ,
			p_Addr_i_orig        => p_Addr_conv     ,

            vsync_neg_i     =>  vsync_neg_conv  ,
			rt_tx_done      =>  rt_tx_done ,  ---rt_tx_done to tx 
            tx07_cc_req     =>  tx07_cc_req  , -----tx one 0x7 packet ;if the unit has many eth port ,then notify 
            tx07_cc_idx     =>  tx07_cc_idx     , ---ctor(3 downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
            tx07_cc_ack     =>  tx07_cc_ack  , ---
            tx07_cc_done    =>  tx07_cc_txdone , --- 
            
            ---------------------------------------------------
            txparam_wren      => txparam_wren     ,
            txparam_wdata     => txparam_wdata ( 73-1 downto  0  ) ,
            txparam_waddr_o   => txparam_waddr ( 9-1  downto  0  ) , --512*80bit at most
			txdpram_posdec_en_xgmiitx  => txdpram_posdec_en_xgmiitx,
               -----------------------------------------------------------
            rt_cmdfifo_wusedw  =>rt_cmdfifo_wusedw( 5-1 downto 0) ,
            rt_cmdfifo_full    =>rt_cmdfifo_full ,
            rt_cmdfifo_wren    =>rt_cmdfifo_wren ,
            --bit10: broadcast
            --bit 9: '0': down cmd, '1':RT
            --BIT8~0: LENGTH IN 64BIT including end flag
            rt_cmdfifo_wdata  => rt_cmdfifo_wdata( 13-1 downto 0) , --length of 64bits
			frm8a_rd_point_main    => frm8a_rd_point_main,
			frm8a_rd_point_back    => frm8a_rd_point_back,
			frm8a_man_notify_en    => frm8a_man_notify_en,
			frm8a_man_en           => frm8a_man_en,
	        shutter_rsp_dvld           => shutter_rsp_dvld      ,   
	        shutter_rsp_data           => shutter_rsp_data      , 
	        shutter_rd_eth_index       => shutter_rd_eth_index  , 
	        shutter_rd_frm_index       => shutter_rd_frm_index  , 
	        shutter_rd_req             => shutter_rd_req        , 
	        shutter_rd_ack             => shutter_rd_ack  ,
			shutter_rd_frmvld          => shutter_rd_frmvld,
			shutter_rd_end             => shutter_rd_end	,
			eth_mask_en_convclk		   => eth_mask_en_convclk,
			real_eth_num_conv          => real_eth_num_conv
       );

       param_cmd_i :   txParamFifo
        port map (
            data    => rt_cmdfifo_wdata( 13-1 downto 0  )  ,    --  fifo_input.datain
            wrreq   => rt_cmdfifo_wren  ,   --            .wrreq
            wrclk   => convclk_i   ,   --            .wrclk
                             -- rdusedw
            wrusedw => rt_cmdfifo_wusedw( 5-1 downto 0) ,                     -- wrusedw

            rdreq   => rt_cmdfifo_rden                      ,   --            .rdreq
            rdusedw => rt_cmdfifo_rusedw( 5-1 downto 0),
            rdclk   => xgmii_txclk  ,   --            .rdclk
            aclr    => pfifo_aclr     ,    --            .aclr
            q       => rt_cmdfifo_rdata( 13-1 downto 0 ) ,       -- fifo_output.dataout
            rdempty => rt_cmdfifo_empty  , --            .rdempty
            wrfull  => rt_cmdfifo_full     --            .wrfull
        );
      paramcmd_data_i :  txParam_dram
        port map (
            data      => txparam_wdata (  73-1 downto 0 ) ,      --      data.datain
            q         => txparam_rdata (  73-1 downto 0 ) ,         --         q.dataout
            wraddress => txparam_waddr (  9-1 downto  0 )  , -- wraddress.wraddress
            rdaddress => txparam_raddr (  9-1 downto  0 )  , -- rdaddress.rdaddress
            wren      => txparam_wren    ,      --      wren.wren
            wrclock   => convclk_i       ,   --   wrclock.clk
            rdclock   => xgmii_txclk      --   rdclock.clk
        );


      out_cmb_i:  xgmii_cmb
      generic map
      (
        NOXGMII_HEAD => NOXGMII_HEAD,
        ETH_NUM      => ETHPORT_NUM

      )
      port MAP
      (
        nRST    => nRST_xgmii   ,
        clk_i   => xgmii_txclk ,

         vsync_neg_i => vsync_neg_xgmii ,

         vidfifo_rdata     =>  vidfifo_rdata  ,
         vidfifo_rden      =>  vidfifo_rden    ,
         vidinfo_empty     =>  vidinfo_empty   ,
         vidinfo_rden      =>  vidinfo_rden    ,
         vidinfo_rdata     =>  vidinfo_rdata  ,

         txparam_rden      =>  txparam_rden  ,
         txparam_rdata     =>  txparam_rdata (  73-1 downto  0),
         txparam_raddr     =>  txparam_raddr (  9-1 downto   0), --512*80bit at most
		 txdpram_posdec_en_xgmiitx  => txdpram_posdec_en_xgmiitx ,

         rt_cmdfifo_rusedw  => rt_cmdfifo_rusedw( 6-1 downto  0),
         rt_cmdfifo_empty   => rt_cmdfifo_empty ,
         rt_cmdfifo_rden    => rt_cmdfifo_rden  ,
          --bit10: broadcast
          --bit 9: '0': down cmd, '1':RT
          --BIT8~0: LENGTH IN 64BIT including end flag
         rt_cmdfifo_rdata  => rt_cmdfifo_rdata( 13-1 downto  0),  --length of 64bits
         ----to fiber interface
         xgmii_txout               => xgmii_txout  ,
		 eth_forbid_en_convclk     => eth_forbid_en_convclk,
		 eth_mask_en_convclk	   => eth_mask_en_convclk,
		 real_eth_num              => real_eth_num_xgmii
      );


      xgmii_data       <= xgmii_txout (  63  downto    0 );
      xgmii_control    <= xgmii_txout (  71  downto   64);

eth_num_cross: cross_domain  
	generic map (
	   DATA_WIDTH => 4
	)
	port map 
	(   clk0           => convclk_i,
		nRst0          => nRST_conv,
		datain         => real_eth_num_conv,
		datain_req     => '1',
		              
		clk1           => xgmii_txclk,
		nRst1          => nRST_xgmii,
		data_out       => real_eth_num_xgmii,
		dataout_valid  => open
	);



end beha;



