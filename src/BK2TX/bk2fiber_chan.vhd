library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;


entity bk2fiber_chan is
generic
(
   SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic;
   ETHPORT_NUM       : integer ; --how many eth port
   FIBER_NUM         : integer ;
   BKHSSI_NUM        : integer ;

   NOXGMII_HEAD      : std_logic := '1'; --'1' :no  D55555555555FB
   G12_9BYTE_EN      : STD_LOGIC := '1' ;  --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS
   TEST_12BIT_TO_8BIT : integer := 0
);
port
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);
    vsync_out_rxc         : out std_logic ;


    req_f9_upload         : in  std_logic    ; ---
    nRST_conv             : in  std_logic    ; ---
    convclk_i             : in  std_logic    ; --200M almost
    xgmii_wren            : out std_logic_vector(ETHPORT_NUM-1 downto 0);
    xgmii_data_out        : out std_logic_vector(FIBER_NUM*64-1 downto 0);
    xgmii_control         : out std_logic_vector(FIBER_NUM*8 -1 downto 0);
    vsync_out_conv        : out std_logic ;
    vsync_neg_conv_o      : out std_logic ;
    ---packet count       

    vidinfo_wren          : out std_logic_vector(ETHPORT_NUM-1 downto 0);
    --bit10: broadcast
    --bit 9: '0': down cmd, '1':RT
    --BIT8~0: LENGTH IN 64BIT including end flag
    vidinfo_wdata         : out  std_logic_vector(20 downto 0);


    p_Frame_en_conv       : in std_logic ;
    p_Wren_conv           : in std_logic ;
    p_Data_conv           : in std_logic_vector(7 downto 0);
    p_Addr_conv           : in std_logic_vector(10 downto 0);
    cur_slot_num          : in std_logic_vector(15 downto 0);


    secret_data           : in  std_logic_vector(47 downto 0):= (others => '0');
	rcv_led	              : in std_logic_vector(1 downto 0);
	backup_flag           : in std_logic_vector(ETHPORT_NUM-1 downto 0);

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
     hlg_type             : in  std_logic_vector(7 downto 0):= (others => '0') ;
	 color_depth_o        : out std_logic_vector(1 downto 0);
	eth_bright_value      : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_R           : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_G           : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	eth_color_B           : in std_logic_vector(ETHPORT_NUM*8-1 downto 0);
	low_bright_en         : in std_logic;
    virtual_pix_en        : in  std_logic_vector(1 downto 0):= (others => '0');
    virtual_direction     : in  std_logic_vector(1 downto 0):= (others => '0');
	colorspace            : in std_logic_vector(2  downto 0);
	PN_frame_type         : in std_logic_vector(19 downto 0);
	bright_weight         : in std_logic_vector(89 downto 0);
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

end bk2fiber_chan;

architecture beha of bk2fiber_chan is

constant F_AW : integer := 10;
constant P_W  : integer := 11;
constant V_W  : integer := 5 ;
constant PX_W : integer := 12;

signal eco_k_val : std_logic_vector(7 downto 0):=(7=>'1',others=>'0');
signal eco_k_vld : std_logic := '0';


component bk_serdes_rcv is
generic
(
   SIM : std_logic := '0' ;
   P_W : integer := 11 ;
   V_W : integer := 5  ;
  F_AW : integer := 10
);
port
(
  nRST_rxc              : in  std_logic ;
  rx_bk_clk             : in  std_logic ;
  rx_bk_parallel_data   : in std_logic_vector(  64-1 downto 0);
  rx_bk_control         : in std_logic_vector(  8 -1 downto 0);
  vsync_notify_rxc      : out std_logic ; --rxc

  nRST_txc              : in   std_logic ;
  txclk_i               : in   std_logic ;
  vsync_txc_o           : out  std_logic ;
  vsync_neg_txc         : out  std_logic ;
  rd_done_notify_txc    : in   std_logic ;
  vid_rdreq_txc         : in   std_logic   ; -- rdaddress
  vid_rdata_txc         : out  std_logic_vector(71 downto 0);
  vid_rdempty_txc       : out  std_logic;
  vid_rdusedw_txc       : out  std_logic_vector(9 downto 0);
  vid_pck_empty_txc     : out  std_logic      ;
  vid_pckcnt_txc        : out  std_logic_vector(P_W-1   DOWNTO 0)    ;
  --------
  vinfo_raddr           : in   std_logic_vector( V_W -1 downto 0  )  ; -- rdaddress
  vinfo_rdata           : OUT  std_logic_vector(64-1   downto 0  )  ;

  clr_serdesinfo_convclk        : in  std_logic;
  subbrdin_packet_cnt_rxbkclk      : out std_logic_vector(32-1 downto 0);
  error_fe_num_rxbkclk          : out std_logic_vector(16-1 downto 0);
  error_check_num_rxbkclk       : out std_logic_vector(16-1 downto 0)
);
end component ;

signal trans_rdusedw       : std_logic_vector(F_AW*BKHSSI_NUM-1 downto 0);
signal trans_fifo_q        : std_logic_vector(  72*BKHSSI_NUM-1 downto 0);

signal pixel_bytes_buf : std_logic_vector(17 downto 0) := (others=>'0');
signal pix_nibble_buf  : std_logic_vector(18 downto 0) := (others=>'0');
signal pix_nibbles     : std_logic_vector(16 downto 0) := (others=>'0');
signal pixel_bytes     : std_logic_vector(15 downto 0) := (others=>'0');
signal pixel_num       : std_logic_vector(15 downto 0) := (others=>'0');
signal color_depth     : std_logic_vector(1 downto 0) := (others=>'0');
signal eth_port        : std_logic_vector(3 downto 0);
signal frm_end_f_en    : std_logic ;
signal frm_start_F_en  : std_logic ;
signal push_header_en  : std_logic ;
signal push_Frm_type   : std_logic_vector(1 downto 0);
signal push_out_en     : std_logic ;
signal push_bytenum    : std_logic_vector(3 downto 0); --at most 8 bytes

component crc64_top is
generic
(

 B_W : integer := 4 ; --at most 8 bytes
 D_W : integer := 64;
 D_LSB_F: integer := 1; ---'1': data is lsb BYTE first, '0': data is msb first (first out)
 CRC_W: integer:= 32 ;
 INV_BYTE_BIT: integer:=1   -- 1 : bit7 bit0 swap FOR NEW,  '0': no swap for OLD (2003 VERSION)
);
port
(
   nRST       : in  std_logic;
   clr_i      : in  std_logic ;
   clk_i      : in  std_logic ;
   frm_en_i   : in  std_logic ;
   ctrl_i     : in  std_logic_vector((D_W/8)-1 DOWNTO 0);
   data_i     : in  std_logic_vector(D_W-1 downto 0);
   bnum_i     : in  std_logic_vector(B_W-1 downto 0);
   din_en_i   : in  std_logic ;
   last_en_i  : in  std_logic ;
   first_en_i : in  std_logic ;

   --delayed one-clock version of the inputs
   den_o      : out  std_logic ;
   laste_o    : out  std_logic ;
   frm_en_o   : out  std_logic ;
   ctrl_o     : out  std_logic_vector((D_W/8)-1 DOWNTO 0);

   firsten_o  : out std_logic ;
   bnum_o     : out std_logic_vector(B_W-1   downto 0);
   total_bnum : out std_logic_vector(14 downto 0);
   data_o     : out std_logic_vector(D_W-1   downto 0);
   crc_o      : out std_logic_vector(CRC_W-1 downto 0)
);
end component ;

signal vinfo_raddr           :    std_logic_vector(V_W*BKHSSI_NUM-1 downto 0);
signal vinfo_rdata           :    std_logic_vector(64*BKHSSI_NUM-1  DOWNTO 0);
signal vid_rdreq_en          :    std_logic_vector(BKHSSI_NUM-1     DOWNTO 0);-- rdaddress
-- signal vid_rdata_txc         :    std_logic_vector(72*BKHSSI_NUM    downto 0);
signal vid_rdempty_txc       :    std_logic_vector(BKHSSI_NUM-1     DOWNTO 0);
signal vid_rdusedw_txc       :    std_logic_vector(10*BKHSSI_NUM-1  DOWNTO 0);
signal vid_pck_empty_txc     :    std_logic_vector(BKHSSI_NUM-1     DOWNTO 0);
signal vid_pckcnt_txc        :    std_logic_vector(P_W*BKHSSI_NUM-1 DOWNTO 0)    ;
signal vsync_notify_rxc      :    std_logic_vector( BKHSSI_NUM-1 DOWNTO 0)    ;
signal vsync_neg_conv         :    std_logic_vector( BKHSSI_NUM-1 DOWNTO 0)    ;
signal vsync_conv             :    std_logic_vector( BKHSSI_NUM-1 DOWNTO 0)    ;
signal vsync_arrived_conv     :    std_logic     ;
signal vsync_arrived_ack     :    std_logic     ;
signal rd_done_notify_conv     :    std_logic  := '0'   ;

constant VSYNC_FRM_DUR  : integer := 128; --128 cycles here

   signal dly_fifo_rdata : std_logic_vector(72*2-1 downto 0);
   signal px_R_value : std_logic_vector(PX_W*4-1 downto 0);
   signal px_G_value : std_logic_vector(PX_W*4-1 downto 0);
   signal px_B_value : std_logic_vector(PX_W*4-1 downto 0);
   signal px_value   : STD_LOGIC_VECTOR(30*4-1 downto 0); --at most 120bit
   signal bright_coef_R: std_logic_vector(8 downto 0);
   signal bright_coef_G: std_logic_vector(8 downto 0);
   signal bright_coef_B: std_logic_vector(8 downto 0);
   signal mul_res_R    : std_logic_vector((PX_W+9)*4-1 downto 0);
   signal mul_res_G    : std_logic_vector((PX_W+9)*4-1 downto 0);
   signal mul_res_B    : std_logic_vector((PX_W+9)*4-1 downto 0);
   signal px_mul_R    : std_logic_vector(PX_W*4-1 downto 0);
   signal px_mul_G    : std_logic_vector(PX_W*4-1 downto 0);
   signal px_mul_B    : std_logic_vector(PX_W*4-1 downto 0);
   signal filter8_fifo_q : STD_LOGIC_VECTOR(24*4-1 DOWNTO 0);
   signal filter10_fifo_q: STD_LOGIC_VECTOR(32*4-1 DOWNTO 0);
   signal filter12_fifo_q: STD_LOGIC_VECTOR(40*3-1 DOWNTO 0);
   signal TEST_12t8_fifo_q : std_logic_vector(24*3 -1 downto 0);

signal brightness_manual_en_buf:    std_logic_vector(1*ETHPORT_NUM-1 DOWNTO 0)    ;
signal brightness_manual_buf   :    std_logic_vector(8*ETHPORT_NUM-1 DOWNTO 0)    ;

type ARRAY_10x9  is array (0 to 9)  of std_logic_vector(8 downto 0);
signal coef_sel_R : ARRAY_10x9;
signal coef_sel_G : ARRAY_10x9;
signal coef_sel_B : ARRAY_10x9;

SIGNAL lowbright_en_f : STD_LOGIC := '1';
type state_def is (push_viddata_st,parse_done_st,wait_st,
      parse_sync_st,tx_sync_st,idle_st,parse_vinfo_st);
signal pstate : state_def:=wait_st;
signal wait_cnt  : std_logic_vector(2 downto 0);
-- signal loop_cnt  : std_logic_vector(3 downto 0);
signal tx_cnt   : std_logic_vector(8 downto 0);

signal backup_flag_sign : std_logic_vector(3 downto 0) := (others=>'0');
signal pck_type    : std_logic_vector(7 downto 0);
signal pck_len_128 : std_logic_vector(15 downto 0);
signal col_start   : std_logic_vector(15 downto 0);
signal row_cur     : std_logic_vector(15 downto 0);

constant CT_W : integer := 5;

signal cycle_cnt           : std_logic_vector(CT_W-1 downto 0); --at most 14
signal d1_cycl_cnt_b       : std_logic_vector(CT_W-1 downto 0); --at most 14
signal dly_cnt             : std_logic_vector(7 downto 0); --at most 14
signal lock_data           : std_logic_vector(119 downto 0); --at most 14
signal txsync_wdata        : std_logic_vector(63  downto 0); --at most 14
signal txdata_wdata        : std_logic_vector(63  downto 0); --at most 14
signal txdata_info         : std_logic_vector(8  downto 0); --at most 14
signal txdata_wren         : std_logic := '0'; --at most 14
signal colort_B        : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1'); --at most 14
signal colort_G        : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1'); --at most 14
signal colort_R        : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1'); --at most 14
signal brighttemp_set_buf  : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1'); --at most 14
signal bright_coeff        : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1'); --at most 14
signal bright_coef_sel     : std_logic_vector(8 -1  downto 0) := (OTHERS=>'1'); --at most 14
signal colort_R_sel        : std_logic_vector(8 -1  downto 0) := (OTHERS=>'1'); --at most 14
signal colort_G_sel        : std_logic_vector(8 -1  downto 0) := (OTHERS=>'1'); --at most 14
signal colort_B_sel        : std_logic_vector(8 -1  downto 0) := (OTHERS=>'1'); --at most 14

signal brightness_buf      : std_logic_vector(9*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1');
signal chrome_mult_out_R   : std_logic_vector(17*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1');
signal chrome_mult_out_G   : std_logic_vector(17*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1');
signal chrome_mult_out_B   : std_logic_vector(17*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1');

signal chroma_r   : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1');
signal chroma_g   : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1');
signal chroma_b   : std_logic_vector(8*ETHPORT_NUM-1  downto 0) := (OTHERS=>'1');


---signal req_f9_upload       : std_logic := '0';
signal req_f9_upload_buf   : std_logic := '0';

signal rcv_led_flick       : std_logic_vector(7 downto 0):=(others=>'1');
signal first_8b_b          :  std_logic := '0';
signal first_8b            :  std_logic := '0';
signal crc_clr_i            :  std_logic := '0';
signal crc_wren_in          :  std_logic := '0';
signal crc_firstw           :  std_logic := '0';
signal crc_lastw            :  std_logic := '0';
signal crc_bnum             :  std_logic_vector(3  downto 0);
signal crc_wdata            :  std_logic_vector(63 downto 0);

constant SEL_P : INTEGER := 3;
signal   dly_cyclecnt         : std_logic_vector((SEL_P+1)*CT_W-1  DOWNTO 0) := (others=>'0');
signal   dly_push_header_en   : std_logic_vector(SEL_P*1        DOWNTO 0) := (others=>'0');
signal   dly_frm_end_f_en     : std_logic_vector(SEL_P*1        DOWNTO 0) := (others=>'0');
signal   dly_frm_start_F_en   : std_logic_vector(SEL_P*1        DOWNTO 0) := (others=>'0');
signal   dly_push_Frm_type    : std_logic_vector((SEL_P+1)*2-1  DOWNTO 0) := (others=>'0');
signal   dly_fifo_rdreq       : std_logic_vector(SEL_P*1        DOWNTO 0) := (others=>'0');
signal   dly_push_en          : std_logic_vector(SEL_P*1        DOWNTO 0) := (others=>'0');
signal   dly_first_8          : std_logic_vector(SEL_P*1+1        DOWNTO 0) := (others=>'0');
signal   dly_push_bnum        : std_logic_vector((SEL_P+1)*4-1  DOWNTO 0) := (others=>'0');
signal   dly_netport          : std_logic_vector((SEL_P+1)*4-1  DOWNTO 0) := (others=>'0');
SIGNAL   dly_pushen_sel       : STD_LOGIC ;
SIGNAL   dly_pushhead_sel     : STD_LOGIC ;
SIGNAL   dly_pushhead_sel_b   : STD_LOGIC ;
SIGNAL   dly_frmstart_sel_en  : STD_LOGIC ;
SIGNAL   dly_frm_end_sel_en   : STD_LOGIC ;
SIGNAL   dly_frm_type_sel     : STD_LOGIC_VECTOR(1 DOWNTO 0) ;
SIGNAL   dly_cycle_sel        : STD_LOGIC_VECTOR(CT_W-1 DOWNTO 0) ;
SIGNAL   dly_first8_sel       : STD_LOGIC ;
signal   netport_sel          : std_logic_VECTOR(7 DOWNTO 0) ;
signal   dly_rdreq_sel        : std_logic;
signal   px_bcnt_sel          : std_logic_VECTOR(CT_W-1 DOWNTO 0) ;
signal   vbyte_cnt            : std_logic_VECTOR(CT_W-1 DOWNTO 0) ;
signal   crc_wren_out         : std_logic ;
signal   crc_laste_o        : std_logic ;
signal   crc_frm_en_o       : std_logic ;
signal   crc_firsten_o      : std_logic ;
signal   crc_bn_out         : std_logic_vector(3  downto 0);
signal   txdata_d1          : std_logic_vector(63 downto 0);
signal   txdata_d2          : std_logic_vector(63 downto 0);
signal   txdata_out         : std_logic_vector(63 downto 0);
signal   crc_o              : std_logic_vector(31 downto 0);

signal   rcv_led_buf            : std_logic:='0';

signal   dly_vsync_conv : std_logic ;
signal   px12_is_odd    : std_logic ;
signal   append_en      : std_logic ;
signal   app_byten      : std_logic_vector(3 downto 0);
signal   crc_buf        : std_logic_vector(31 downto 0);
signal   xgmii_cnt      : std_logic_vector(9  downto 0);
signal   frame_remapping_vsync_idx: std_logic_vector(3 downto 0):=(others=>'0');
signal   frame_remapping_en       : std_logic:='0';
signal   frm_remapin_vsync_idx_x2 : integer range 0 to 18 := 0;
signal   frm_remapin_vsync_idx_x4 : integer range 0 to 36 := 0;
signal   frm_remapin_vsync_idx_x9 : integer range 0 to 81 := 0;
signal   brightness_manual_en_buf_B: std_logic_vector(10-1 DOWNTO 0) :=(OTHERS=>'0');
signal   brightness_manual_buf_B   : std_logic_vector(10*8-1 DOWNTO 0);

signal   info_3d                    : std_logic_vector(39 downto 0);

signal   eth_lock                   : std_logic_vector(3 downto 0);
signal   eth_lock_d1                : std_logic_vector(3 downto 0);
signal   eth_lock_d2_int            : integer;
signal   pix_num_lock			    : std_logic_vector(8 downto 0);
signal   pix_num_lock_d1		    : std_logic_vector(8 downto 0);
signal   pix_num_lock_d2		    : std_logic_vector(8 downto 0);
signal   color_depth_lock		    : std_logic_vector(1 downto 0);
signal   color_depth_lock_d1		: std_logic_vector(1 downto 0);
signal   color_depth_lock_d2		: std_logic_vector(1 downto 0);
signal   vsync_frm_en               : std_logic; 
signal   vsync_frm_en_lock          : std_logic; 
signal   vsync_frm_en_lock_d1       : std_logic; 
signal   vsync_frm_en_lock_d2       : std_logic; 
signal   vidfrm_type                : std_logic;
signal   rcv_card_idx               : std_logic_vector(15 downto 0);
signal   frm_cnt                    : std_logic_vector(11 downto 0);
signal   last_frm_en                : std_logic;


	 
attribute syn_keep : boolean;
attribute syn_srlstyle : string;
attribute syn_keep of frm8a_man_en : signal is true; 

--2021
attribute altera_attribute : string;
attribute altera_attribute of frm8a_man_en : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON";


begin

color_depth_o <= color_depth;

  lowbright_en_f <= '1';

align_i: for i in 0 to BKHSSI_NUM-1 GENERATE

       rcv_bk_i:  bk_serdes_rcv
     generic map
     (  P_W  =>  P_W ,
        SIM  =>  SIM ,
        V_W  =>  V_W ,
       F_AW  => F_AW
     )
     port map
     (
       nRST_rxc              => nRST_bk_rxclk(i),
       rx_bk_clk             => rx_bk_clk (i)   ,
       rx_bk_parallel_data   =>rx_bk_parallel_data(  (i+1)*64-1 downto i*64),
       rx_bk_control         =>rx_bk_control      (  (i+1)*8 -1 downto i*8 ) ,
       vsync_notify_rxc      => vsync_notify_rxc(i)  , --rxc

       nRST_txc              => nRST_conv ,
       txclk_i               => convclk_i   ,
       vsync_txc_o           => vsync_conv(i),
       vsync_neg_txc         => vsync_neg_conv(i),
       rd_done_notify_txc    => rd_done_notify_conv ,
       vid_rdreq_txc         => vid_rdreq_en(i), -- rdaddress
       vid_rdata_txc         => trans_fifo_q((i+1)*72-1  downto i*72),
       vid_rdempty_txc       => vid_rdempty_txc(i) ,
       vid_rdusedw_txc       => vid_rdusedw_txc((i+1)*10-1 downto I*10) ,
       vid_pck_empty_txc     => vid_pck_empty_txc( i ) ,
       vid_pckcnt_txc        => vid_pckcnt_txc   ( (i+1)*P_W-1   DOWNTO  i*P_W )  ,
       --------
       vinfo_raddr           => vinfo_raddr    ( (i+1)*V_W-1 downto i*V_W ), -- rdaddress
       vinfo_rdata           => vinfo_rdata    ( (i+1)*64-1  downto i*64)   ,

	   clr_serdesinfo_convclk        => clr_serdesinfo_convclk,
	   subbrdin_packet_cnt_rxbkclk      => subbrdin_packet_cnt_rxbkclk((i+1)*32-1 downto i*32),
	   error_fe_num_rxbkclk          => error_fe_num_rxbkclk((i+1)*16-1 downto i*16),
	   error_check_num_rxbkclk       => error_check_num_rxbkclk((i+1)*16-1 downto i*16)
     );

END GENERATE align_i;


   vsync_out_rxc  <= vsync_notify_rxc(0);
   vsync_out_conv  <= vsync_conv(0);
   vsync_neg_conv_o<= vsync_neg_conv(0);
   dly_vsync_conv  <= vsync_conv(0);




   -----------------------------------------------------


    process(pixel_num,color_depth)
    begin
	    if color_depth = COLOR12_DEPTH and TEST_12BIT_TO_8BIT = 1 then
		     pixel_bytes_buf<= ("0"&pixel_num&"0") + pixel_num;
            pix_nibble_buf <= ("0"&pixel_num&"00") + (pixel_num&"0");
        elsif color_depth = COLOR8_DEPTH  then
            pixel_bytes_buf<= ("0"&pixel_num&"0") + pixel_num;
            pix_nibble_buf <= ("0"&pixel_num&"00") + (pixel_num&"0");
         elsif color_depth = COLOR10_DEPTH then
            pixel_bytes_buf <= (pixel_num&"00");
            pix_nibble_buf  <= (pixel_num&"000");
         else --12bit 5 bytes
             if G12_9BYTE_EN ='0'THEN
                 pixel_bytes_buf <=(pixel_num&"00")+pixel_num;
                 pix_nibble_buf <=(pixel_num&"000")+(pixel_num&"0");
             ELSE
                ---1 pixel :4.5 byte = 9 nibbles
                pix_nibble_buf <= (pixel_num &"000")+pixel_num;
                if pixel_num(0) = '0' then
                  pixel_bytes_buf <=(pixel_num(15 downto 1)&"000")+pixel_num(15 downto 1);
                else --the end bytes is 5 for the odd number of pixels
                  pixel_bytes_buf <=(pixel_num(15 downto 1)&"000")+pixel_num(15 downto 1)+5;
                end if;
             END IF;
         end if;
    end process;

    process(convclk_i,nRST_conv)
    begin
        if nRST_conv = '0' then
            vsync_arrived_conv <= '0';
        elsif  rising_edge(convclk_i) then
             if vsync_neg_conv(0) = '1' then
                vsync_arrived_conv<= '1';
             elsif vsync_arrived_ack = '1' then
                vsync_arrived_conv <= '0';
             end if;
        end if;
    end process;

process(convclk_i,nRST_conv)
begin
	if nRST_conv = '0' then
		rcv_led_buf <= '0' ;
		backup_flag_sign <= X"8";
	elsif rising_edge(convclk_i) then

		for i in 0 to ETHPORT_NUM-1 loop
			if i = netport_sel then
				if backup_flag(i)= '0' then
					rcv_led_buf <= rcv_led(0);
					backup_flag_sign <= X"8";
				else
					rcv_led_buf <= rcv_led(1);
					backup_flag_sign <= X"5";
				end if;

			end if;
		end loop;
	end if;
end process;

rcv_led_flick ( 7 downto 0) <= '1'&rcv_led_buf&'0'&rcv_led_buf&x"0"; ----



   px_value <= dly_fifo_rdata(127 downto  72)&dly_fifo_rdata( 63 downto 0);
   process(px_value,color_depth)
   begin
     px_B_value <= (others=>'0');
     px_G_value <= (others=>'0');
     px_R_value <= (others=>'0');
     ---B 7:0 , G 15:8,R 23:16, 2bit,2bit, 2bit --no 30bit only,2'b00
     if color_depth = COLOR10_DEPTH or color_depth = COLOR8_DEPTH then
          for i in 0 to 3  loop--4 px here
             px_B_value( (I+1)*PX_W-1 DOWNTO I*PX_W) <= px_value ( i*30+9 downto  i*30 +  0 )&"00";
             px_G_value( (I+1)*PX_W-1 DOWNTO I*PX_W) <= px_value ( i*30+19 downto i*30 + 10 )&"00";
             px_R_value( (I+1)*PX_W-1 DOWNTO I*PX_W) <= px_value ( i*30+29 downto i*30 + 20 )&"00";
          END loop;
     else
          for i in 0 to 2  loop--3 px here (12bit)
             px_B_value( (I+1)*PX_W-1 DOWNTO I*PX_W) <= px_value ( i*40+11 downto  i*40 +  0 );
             px_G_value( (I+1)*PX_W-1 DOWNTO I*PX_W) <= px_value ( i*40+23 downto  i*40 + 12 );
             px_R_value( (I+1)*PX_W-1 DOWNTO I*PX_W) <= px_value ( i*40+35 downto  i*40 + 24 );
          END loop;
     end if;
   end process;




   ---96bit data
   ---pixel_val
    process(convclk_i,nRST_conv)
   begin
        if nRST_conv = '0' then
             bright_coef_R <= (8=>'1',others=>'0');
             bright_coef_G <= (8=>'1',others=>'0');
             bright_coef_B <= (8=>'1',others=>'0');
        elsif rising_edge(convclk_i) then
            if low_bright_en = '1' then
               bright_coef_R <= (8=>'1',others=>'0');
               bright_coef_G <= (8=>'1',others=>'0');
               bright_coef_B <= (8=>'1',others=>'0');
            else
                case( conv_integer(eth_port)) is
                   when 0       => bright_coef_R <= coef_sel_R(0); bright_coef_G <= coef_sel_G(0 ); bright_coef_B <= coef_sel_B(0);
                   when 1       => bright_coef_R <= coef_sel_R(1); bright_coef_G <= coef_sel_G(1 ); bright_coef_B <= coef_sel_B(1);
                   when 2       => bright_coef_R <= coef_sel_R(2); bright_coef_G <= coef_sel_G(2 ); bright_coef_B <= coef_sel_B(2);
                   when 3       => bright_coef_R <= coef_sel_R(3); bright_coef_G <= coef_sel_G(3 ); bright_coef_B <= coef_sel_B(3);
                   when 4       => bright_coef_R <= coef_sel_R(4); bright_coef_G <= coef_sel_G(4 ); bright_coef_B <= coef_sel_B(4);
                   when 5       => bright_coef_R <= coef_sel_R(5); bright_coef_G <= coef_sel_G(5 ); bright_coef_B <= coef_sel_B(5);
                   when 6       => bright_coef_R <= coef_sel_R(6); bright_coef_G <= coef_sel_G(6 ); bright_coef_B <= coef_sel_B(6);
                   when 7       => bright_coef_R <= coef_sel_R(7); bright_coef_G <= coef_sel_G(7 ); bright_coef_B <= coef_sel_B(7);
                   when 8       => bright_coef_R <= coef_sel_R(8); bright_coef_G <= coef_sel_G(8 ); bright_coef_B <= coef_sel_B(8);
                   when 9       => bright_coef_R <= coef_sel_R(9); bright_coef_G <= coef_sel_G(9 ); bright_coef_B <= coef_sel_B(9);
                   when OTHERS  => bright_coef_R <= coef_sel_R(0); bright_coef_G <= coef_sel_G(0); bright_coef_B <= coef_sel_B(0);
                end case;
           end if;
        end if;
    end process;

   process(convclk_i,nRST_conv)
   begin
         if rising_edge(convclk_i) then
            for i in 0 to 3  loop--4 px here FOR 8BIT/10BIT, 3 PX FOR 12BIT HERE
             mul_res_R((I+1)*(PX_W+9)-1 DOWNTO I*(PX_W+9) ) <= bright_coef_R * px_R_value( (I+1)*PX_W-1 DOWNTO I*PX_W);
             mul_res_G((I+1)*(PX_W+9)-1 DOWNTO I*(PX_W+9) ) <= bright_coef_G * px_G_value( (I+1)*PX_W-1 DOWNTO I*PX_W);
             mul_res_B((I+1)*(PX_W+9)-1 DOWNTO I*(PX_W+9) ) <= bright_coef_B * px_B_value( (I+1)*PX_W-1 DOWNTO I*PX_W);
            end loop;
        end if;
    end process;

   process(convclk_i,nRST_conv)
   begin
         if rising_edge(convclk_i) then
            for i in 0 to 3  loop--4 px here
             px_mul_R((I+1)*PX_W-1 DOWNTO I*PX_W) <= mul_res_R( I*(PX_W+9)+PX_W+7 DOWNTO I*(PX_W+9) + 8);
             px_mul_G((I+1)*PX_W-1 DOWNTO I*PX_W) <= mul_res_G( I*(PX_W+9)+PX_W+7 DOWNTO I*(PX_W+9) + 8);
             px_mul_B((I+1)*PX_W-1 DOWNTO I*PX_W) <= mul_res_B( I*(PX_W+9)+PX_W+7 DOWNTO I*(PX_W+9) + 8);
            end loop;
        end if;
    end process;



    process(px_mul_R,px_mul_G,px_mul_B,px12_is_odd)
    begin
       for i in 0 to 3 loop --4 px
          -- filter8_fifo_q((i+1)*24-1 downto i*24) <=
             -- px_mul_B((i+1)*PX_W-1  downto i*PX_W+PX_W-8)&
             -- px_mul_G((i+1)*PX_W-1  downto i*PX_W+PX_W-8) &
             -- px_mul_R((i+1)*PX_W-1  downto i*PX_W+PX_W-8);
		   filter8_fifo_q((i+1)*24-1 downto i*24) <=
              px_mul_R((i+1)*PX_W-1  downto i*PX_W+PX_W-8)&
              px_mul_G((i+1)*PX_W-1  downto i*PX_W+PX_W-8) &
              px_mul_B((i+1)*PX_W-1  downto i*PX_W+PX_W-8);
       end loop;

        for i in 0 to 3 loop --120bit at most
          -- filter10_fifo_q((i+1)*32-1 downto i*32) <=
             -- "00"&px_mul_B((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                  -- px_mul_G((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                  -- px_mul_R((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                  -- px_mul_B((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                  -- px_mul_G((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                  -- px_mul_R((i+1)*PX_W-1 downto (i+1)*PX_W-8)  ;
          filter10_fifo_q((i+1)*32-1 downto i*32) <=
             "00"&px_mul_B((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                  px_mul_G((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                  px_mul_R((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                  px_mul_R((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                  px_mul_G((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                  px_mul_B((i+1)*PX_W-1 downto (i+1)*PX_W-8)  ;
       end loop;

        for i in 0 to 2 loop
            if G12_9BYTE_EN = '0' THEN  --10 BYTES @2 PIXELS
                 filter12_fifo_q((i+1)*40-1 downto i*40) <=
                 "00"&px_mul_B((i+1)*PX_W-11 downto (i+1)*PX_W-12) &
                      px_mul_G((i+1)*PX_W-11 downto (i+1)*PX_W-12) &
                      px_mul_R((i+1)*PX_W-11 downto (i+1)*PX_W-12) &
                  "00"&px_mul_B((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                      px_mul_G((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                      px_mul_R((i+1)*PX_W-9 downto (i+1)*PX_W-10) &
                      px_mul_R((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                      px_mul_G((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                      px_mul_B((i+1)*PX_W-1 downto (i+1)*PX_W-8)  ;
                 -- px_mul_B(i*10+1 downto i*10+0)&px_mul_G(i*10+1 downto i*10+0) & px_mul_R(i*10+1 downto i*10+0)&
                 -- px_mul_B(i*10+9 downto i*10+2)&px_mul_G(i*10+9 downto i*10+2) & px_mul_R(i*10+9 downto i*10+2);
            ELSE -- 9 BYTES @ 2 PIXELS
                if (px12_is_odd = '0'  and (i = 0 or i = 2)) or
                   (px12_is_odd = '1'  and (i = 1) ) then
                      filter12_fifo_q((i+1)*36-1 downto i*36) <=
                         px_mul_R((i+1)*PX_W-9 downto (i+1)*PX_W-12) &
                         px_mul_G((i+1)*PX_W-9 downto (i+1)*PX_W-12) &
                         px_mul_B((i+1)*PX_W-9 downto (i+1)*PX_W-12) &
                         px_mul_B((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                         px_mul_G((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                         px_mul_R((i+1)*PX_W-1 downto (i+1)*PX_W-8)  ;
                else
                    filter12_fifo_q((i+1)*36-1 downto i*36) <=
                         px_mul_G((i+1)*PX_W-9 downto (i+1)*PX_W-12) &
                         px_mul_B((i+1)*PX_W-9 downto (i+1)*PX_W-12) &
                         px_mul_B((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                         px_mul_G((i+1)*PX_W-1 downto (i+1)*PX_W-8)   &
                         px_mul_R((i+1)*PX_W-1 downto (i+1)*PX_W-8)  &
                         px_mul_R((i+1)*PX_W-9 downto (i+1)*PX_W-12) ;
                end if;
            END IF;
        end loop;

	    for i in 0 to 2 loop
			TEST_12t8_fifo_q ((i+1)*24-1 downto i*24) <=
				px_mul_R((i+1)*PX_W-1  downto i*PX_W+PX_W-8)&
                px_mul_G((i+1)*PX_W-1  downto i*PX_W+PX_W-8) &
                px_mul_B((i+1)*PX_W-1  downto i*PX_W+PX_W-8);
		end loop;
    end process;

    process(convclk_i,nRST_conv)
    begin
      if nRST_conv = '0' then
          px12_is_odd <= '0';
      elsif rising_edge(convclk_i) then
          if dly_vsync_conv = '1' then
             px12_is_odd <= '0';
          elsif dly_frm_start_F_en(SEL_P-1) = '1' then
             px12_is_odd <= '0';
          elsif dly_fifo_rdreq(SEL_P-1) = '1' then
             px12_is_odd <= not px12_is_odd;
          end if;
      end if;
    end process;

    process(convclk_i,nRST_conv)
    begin
      if nRST_conv = '0' then
		frm8a_man_notify_en <= '0';
		frm8a_rd_point_main <= (OTHERS=>'1');
		frm8a_rd_point_back <= (OTHERS=>'1');
		frm8a_man_en        <= '1';
        eco_k_vld           <= '0';
        eco_k_val           <= (7=>'1',others=>'0');
      elsif rising_edge(convclk_i) then
				frm8a_man_notify_en   <= '0';
                if pstate = parse_sync_st then
                       case conv_integer(tx_cnt) is
                           -- when 3    => rcv_led    <= vinfo_rdata(ETHPORT_NUM*2-1 downto 0);
						   when 3    => 
									frame_remapping_en            <= vinfo_rdata(4);
									frame_remapping_vsync_idx         <= vinfo_rdata(3 downto 0);
                                    info_3d                           <= vinfo_rdata(57 downto 18);
                                    eco_k_vld                         <= vinfo_rdata(17);
                                    eco_k_val                         <= vinfo_rdata(12 downto 5);
                           when 4    => brightness_manual_en_buf_B(0) <= vinfo_rdata(8);
                           when 5    => brightness_manual_en_buf_B(1) <= vinfo_rdata(8);
                           when 6    => brightness_manual_en_buf_B(2) <= vinfo_rdata(8);
                           when 7    => brightness_manual_en_buf_B(3) <= vinfo_rdata(8);
                           when 8    => brightness_manual_en_buf_B(4) <= vinfo_rdata(8);
                           when 9    => brightness_manual_en_buf_B(5) <= vinfo_rdata(8);
                           when 10   => brightness_manual_en_buf_B(6) <= vinfo_rdata(8);
                           when 11   => brightness_manual_en_buf_B(7) <= vinfo_rdata(8);
                           when 12   => brightness_manual_en_buf_B(8) <= vinfo_rdata(8);
                           when 13   => brightness_manual_en_buf_B(9) <= vinfo_rdata(8);
						   when 14   => 
										frm8a_man_en          <= vinfo_rdata(31);
										frm8a_rd_point_main   <= vinfo_rdata(9 downto 0);
						                frm8a_rd_point_back   <= vinfo_rdata(19 downto 10);
										frm8a_man_notify_en   <= '1';
                           when others => null;
                        end case;

                        case conv_integer(tx_cnt) is
                             when 4  => brightness_manual_buf_B(0*8+7 downto 0*8) <= vinfo_rdata(7 downto 0);
                             when 5  => brightness_manual_buf_B(1*8+7 downto 1*8) <= vinfo_rdata(7 downto 0);
                             when 6  => brightness_manual_buf_B(2*8+7 downto 2*8) <= vinfo_rdata(7 downto 0);
                             when 7  => brightness_manual_buf_B(3*8+7 downto 3*8) <= vinfo_rdata(7 downto 0);
                             when 8  => brightness_manual_buf_B(4*8+7 downto 4*8) <= vinfo_rdata(7 downto 0);
                             when 9  => brightness_manual_buf_B(5*8+7 downto 5*8) <= vinfo_rdata(7 downto 0);
                             when 10 => brightness_manual_buf_B(6*8+7 downto 6*8) <= vinfo_rdata(7 downto 0);
                             when 11 => brightness_manual_buf_B(7*8+7 downto 7*8) <= vinfo_rdata(7 downto 0);
                             when 12 => brightness_manual_buf_B(8*8+7 downto 8*8) <= vinfo_rdata(7 downto 0);
                             when 13 => brightness_manual_buf_B(9*8+7 downto 9*8) <= vinfo_rdata(7 downto 0);
                             when others => null;
                         end case;
                end if;
      end if;
    end process;

	brightness_manual_en_buf <= (others=>'0');---brightness_manual_en_buf_B(ETHPORT_NUM-1  downto  0);
	brightness_manual_buf    <= brightness_manual_buf_B(ETHPORT_NUM*8-1   downto  0);

    process(convclk_i,nRST_conv)
	begin
		if nRST_conv = '0' then
			brightness_buf(8 downto 0)<=(8=>'1',others=>'0');
			brightness_buf(17 downto 9)<=(17=>'1',others=>'0');
		elsif rising_edge(convclk_i) then
			for i in 0 to ETHPORT_NUM-1 loop
				if brightness_manual_en_buf(i) = '1' then
					brightness_buf((i+1)*9-1 downto i*9) <= ('0'&brightness_manual_buf((i+1)*8-1 downto i*8))+1;
					bright_coeff((i+1)*8-1 downto i*8)   <= brightness_manual_buf((i+1)*8-1 downto i*8);
				else
					brightness_buf((i+1)*9-1 downto i*9) <= ('0'&eth_bright_value((i+1)*8-1 downto i*8))+1;
					bright_coeff((i+1)*8-1 downto i*8)   <= eth_bright_value((i+1)*8-1 downto i*8);
				end if;

				chrome_mult_out_R((i+1)*17-1 downto i*17) <= brightness_buf((i+1)*9-1 downto i*9)*eth_color_R((i+1)*8-1 downto i*8);
				chrome_mult_out_G((i+1)*17-1 downto i*17) <= brightness_buf((i+1)*9-1 downto i*9)*eth_color_G((i+1)*8-1 downto i*8);
				chrome_mult_out_B((i+1)*17-1 downto i*17) <= brightness_buf((i+1)*9-1 downto i*9)*eth_color_B((i+1)*8-1 downto i*8);

				chroma_r((i+1)*8-1 downto i*8) <= chrome_mult_out_R((i+1)*17-2 downto i*17+8);
				chroma_g((i+1)*8-1 downto i*8) <= chrome_mult_out_G((i+1)*17-2 downto i*17+8);
				chroma_b((i+1)*8-1 downto i*8) <= chrome_mult_out_B((i+1)*17-2 downto i*17+8);

				if chroma_r((i+1)*8-1 downto i*8) = 0 then
					coef_sel_R(i) <= (others=>'0');
				else
					coef_sel_R(i) <= ('0'&chroma_r((i+1)*8-1 downto i*8))+'1';
				end if;

				if chroma_g((i+1)*8-1 downto i*8) = 0 then
					coef_sel_G(i) <= (others=>'0');
				else
					coef_sel_G(i) <= ('0'&chroma_g((i+1)*8-1 downto i*8))+'1';
				end if;

				if chroma_b((i+1)*8-1 downto i*8) = 0 then
					coef_sel_B(i) <= (others=>'0');
				else
					coef_sel_B(i) <= ('0'&chroma_b((i+1)*8-1 downto i*8))+'1';
				end if;


			end loop;
		end if;
	end process;





process(convclk_i,nRST_conv)
begin
    if nRST_conv = '0' then
        pstate   <= wait_st;
        wait_cnt <= (others=>'0');
        -- loop_cnt <= (others=>'0');
        tx_cnt   <= (others=>'0');
        push_header_en <= '0';
        frm_end_f_en   <= '0';
        frm_start_F_en <= '0';
        rd_done_notify_conv <= '0';
        push_Frm_type  <= (others=>'0');
        vid_rdreq_en   <= (others=>'0');
        vsync_param_update_en <= '0';
    elsif rising_edge(convclk_i) then
        dly_fifo_rdata <= trans_fifo_q ;
    --------------------------------------------------------
        if vsync_conv(0) = '1' then --no parsing
            pstate         <= parse_sync_st;
            wait_cnt       <= (others=>'0');
            eth_port       <= (others=>'0');
            tx_cnt         <= (others=>'0');
            frm_cnt        <= (others=>'0');
            rcv_card_idx   <= (others=>'0');
            vid_rdreq_en       <= (others=>'0'); --to release the fifo_rdreq here
            push_header_en <= '0';
            frm_end_f_en   <= '0';
            frm_start_F_en <= '0';
			push_out_en    <= '0';
            push_Frm_type  <= (others=>'0');
            vinfo_raddr    <= (others=>'0');
            rd_done_notify_conv <= '0';
            first_8b        <= '0';
            first_8b_b          <= '0';
        else
            case(pstate) is
				when wait_st =>
					if vsync_conv(0) = '1' then
						pstate <= parse_sync_st;
					else
						pstate <= wait_st;
					end if;
                when parse_sync_st =>  --we should consider the flowctnr
                    if  tx_cnt = 32 then
                        tx_cnt <= (others=>'0');
                        pstate  <= tx_sync_st;
                        vsync_param_update_en <= '0';
                    else
                        tx_cnt <= tx_cnt + 1;
                    end if;
                    eth_port        <= (others=>'0');
                    vid_rdreq_en    <= (others=>'0');
                    vinfo_raddr     <= tx_cnt(V_W-1 downto 0)&tx_cnt(V_W-1 downto 0) ;
                    rd_done_notify_conv <= '0';

                when tx_sync_st =>
                    vid_rdreq_en   <= (others=>'0');
                    if tx_cnt = VSYNC_FRM_DUR  then ----including the gap and
                       tx_cnt    <= (others=>'0');
                       if eth_port = real_eth_num_conv-1 then
                           pstate   <= idle_st;
                           vsync_param_update_en <= '1';
                       else
                           pstate   <= tx_sync_st;
                           eth_port <= eth_port + 1;
                       end if;
                    else
                       tx_cnt   <= tx_cnt +1 ;
                       pstate   <= tx_sync_st;
                    end if;
                    push_bytenum  <= conv_std_logic_vector(3+5,4);
                    push_frm_type <= FRM_VSYNC(1 downto 0); ---
                    if tx_cnt = 16 then
                       frm_end_f_en   <= '0';
                       frm_start_F_en <= '0';
                       push_header_en <= '1';
                    elsif tx_cnt = 17 then
                       frm_end_f_en   <= '0';
                       frm_start_F_en <= '1';
                       push_header_en <= '1';
                    elsif tx_cnt = 16+63 then
                       frm_end_f_en   <= '1';
                       frm_start_F_en <= '0';
                       push_header_en <= '0';
                    else
                       frm_end_f_en   <= '0';
                       frm_start_F_en <= '0';
                       push_header_en <= '0';
                    end if;

                    if tx_cnt >= 16 and  tx_cnt <  16+64 then
                        push_out_en  <= '1';
                    else
                        push_out_en <= '0';
                    end if;
					

                         --begin to
				when idle_st =>
                    rd_done_notify_conv <= '0';
                    wait_cnt <= (others=>'0');
                    eth_port <= (others=>'0');
                    tx_cnt   <= (others=>'0');
                    first_8b     <= '0';
                    first_8b_b   <= '0';

                    if vid_pck_empty_txc(0) = '0' and vid_pck_empty_txc(1) = '0' then
                        pstate <= parse_vinfo_st;
                        vid_rdreq_en <= (others=>'1');
                    else
                        pstate <= idle_st;
                        vid_rdreq_en <= (others=>'0');
                    end if;

                    frm_end_f_en   <= '0';
                    frm_start_F_en <= '0';
                    push_header_en <= '0';
                    push_Frm_type  <= "00";


                when parse_vinfo_st =>
                    vid_rdreq_en <= (others=>'0');
                    if tx_cnt = 3 then --parse
                        tx_cnt <= (others=>'0');
                        pstate <= push_viddata_st;
                    else
                        tx_cnt <= tx_cnt + 1;
                    end if;


                    ------------------------------------------------
					last_frm_en<= trans_fifo_q(7); 
                    pck_type   <= trans_fifo_q(15 downto 8 );
                    pck_len_128<= trans_fifo_q(31 downto 16); --128bit how many
                    pixel_num  <= trans_fifo_q(47 downto 32);
                    pixel_bytes<= pixel_bytes_buf(15 downto 0);
                    pix_nibbles<= pix_nibble_buf (16 downto 0);
                    col_start  <= trans_fifo_q(63 downto 48);
                    row_cur    <= trans_fifo_q(87 downto 72);
                    color_depth<= trans_fifo_q(89 downto 88); --color depth
                    
                    vidfrm_type<= trans_fifo_q(95);
                    eth_port   <= trans_fifo_q(99 downto 96); --eth port index 0~9
					rcv_card_idx   <= trans_fifo_q(115 downto 100);
					frm_cnt        <= trans_fifo_q(127 downto 116);
                    -----------------------------------------
                    cycle_cnt     <= (others=>'0');
                    first_8b_b    <= '1';
                    first_8b      <= '0';
                    push_out_en   <= '0';
                    push_frm_type <= pck_type(1 downto 0);
                     --first is 0XFB
                     --second is SRCMAC FRM_TYPE
                     --
                    if tx_cnt = 2 or tx_cnt = 3 then
                       push_header_en <= '1';
                       if tx_cnt = 3 then
                         frm_start_F_en <= '1';
                         rd_done_notify_conv <= '1';
                       else
                         frm_start_F_en <= '0';
                         rd_done_notify_conv<= '0';
                       end if;
                    else
                       push_header_en <= '0';
                       frm_start_F_en <= '0';
                       rd_done_notify_conv<= '0';
                    end if;
                    frm_end_f_en <= '0';
                    vbyte_cnt    <= (others=>'0');

                when push_viddata_st =>
                    rd_done_notify_conv <= '0';
                    push_header_en <= '0';
                    frm_start_F_en <= '0';
                    first_8b_b     <= '0';
                    first_8b       <= first_8b_b;
                    push_out_en    <= '1';
                    if first_8b_b  = '1' then
                        --at least 3 bytes for 24bit
                        --at least 4 bytes for 30bit
                        --at least 5 bytrs for 12bits
                        if G12_9BYTE_EN = '0' THEN
                            if pixel_bytes <= 3 then --push done -----
                               pstate       <= parse_done_st;
                               push_bytenum <= pixel_bytes(3 downto 0)+5;  --additional for CRC only
                               frm_end_f_en <= '1';
                            else
                               pstate       <= push_viddata_st;
                               -- push_bytenum <= conv_std_logic_vector(3,4);
                               push_bytenum <= conv_std_logic_vector(8,4);
                               frm_end_f_en <= '0';
                            end if;
                        ELSE --2 px occupy 9 bytes
                            IF pix_nibbles <= 3*2 THEN
                               pstate       <= parse_done_st;
                               IF pix_nibbles(0) ='0' THEN
                                  push_bytenum <= pix_nibbles(4 downto 1)+5; --for CRC calculation
                               ELSE
                                  push_bytenum <= pix_nibbles(4 downto 1)+1+5;--for CRC calculation
                               END IF;
                               frm_end_f_en <= '1';
                            else
                               pstate       <= push_viddata_st;
                               -- push_bytenum <= conv_std_logic_vector(3,4);
                               push_bytenum <= conv_std_logic_vector(3+5,4);--for CRC calculation
                               frm_end_f_en <= '0';
                            END IF;
                        END IF;
                    else
                        if G12_9BYTE_EN = '0' THEN --1 px occupy 5 bytes
                            if pixel_bytes   <= 8  then
                                 pstate       <= parse_done_st;
                                 push_bytenum <= pixel_bytes(3 downto 0);
                                 frm_end_f_en <= '1';
                             else
                                pstate       <= push_viddata_st;
                                push_bytenum <= conv_std_logic_vector(8,4);
                                frm_end_f_en <= '0';
                             end if;
                        else --2 px occupy 9 bytes
                             if pix_nibbles   <= 8*2 then
                                 pstate       <= parse_done_st;
                                 if pix_nibbles(0) = '0' then
                                    push_bytenum <= pix_nibbles(4 downto 1);
                                 else
                                    push_bytenum <= pix_nibbles(4 downto 1)+1;
                                 end if;
                                 frm_end_f_en <= '1';
                             else
                                pstate       <= push_viddata_st;
                                push_bytenum <= conv_std_logic_vector(8,4);
                                frm_end_f_en <= '0';
                             end if;
                        end if;
                    end if;

                    if first_8b_b = '1' then
                            pixel_bytes <= pixel_bytes - 3 ; --3 bytes
                            pix_nibbles <= pix_nibbles - 6;
                    else
                            pixel_bytes <= pixel_bytes - 8 ; --8 bytes
                            pix_nibbles <= pix_nibbles - 16;
                    end if;


                    if TEST_12BIT_TO_8BIT = 1 and color_depth = COLOR12_DEPTH then
						if cycle_cnt = 8 then
							cycle_cnt <= (others=>'0');
						else
							cycle_cnt <= cycle_cnt + 1;
						end if;

						if pck_len_128 = 0 then
							vid_rdreq_en <=(others=>'0');
						else
							if cycle_cnt = 3 then
								vid_rdreq_en <=(others=>'0');
							else
								vid_rdreq_en <=(others=>'1');
							    pck_len_128  <= pck_len_128 -1;
							end if;
						end if;

                    elsif color_depth = COLOR8_DEPTH then --96 bit to 64bit
                             --2 to 3 convertion
                             --first 3 byte for header
                             --D5  55 55 55 55  55   55  FB
                             -- v  v  v  FRM 0   NET  SMC TMAC
                        if cycle_cnt = 2 then
                            cycle_cnt <= (others=>'0');
                        else
                            cycle_cnt <= cycle_cnt + 1;
                        end if;
						if pck_len_128 = 0 then
							vid_rdreq_en   <= (others=>'0');
						else
							if cycle_cnt = 0 then
								vid_rdreq_en   <= (others=>'1');
								pck_len_128    <= pck_len_128 - 1 ;
							elsif cycle_cnt = 1 then
								vid_rdreq_en   <= (others=>'0');
							else --2
								vid_rdreq_en   <= (others=>'1');
								pck_len_128    <= pck_len_128 - 1 ;

							end if;
						end if;

                    elsif color_depth= COLOR10_DEPTH then --128bit
                             ---consume 3 bytes here
                             ---every two
                        if cycle_cnt = 1 then
                            cycle_cnt <= (others=>'0');
                        else
                            cycle_cnt <= cycle_cnt + 1;
                        end if;
						if pck_len_128 = 0 then
							vid_rdreq_en <= (others=>'0');
                        else
							if cycle_cnt = 0 then
								vid_rdreq_en    <= (others=>'1');
								pck_len_128 <= pck_len_128 - 1 ;
							else
								vid_rdreq_en    <= (others=>'0');
							end if;
						end if;

                    else
                             --not finished yet

                        if G12_9BYTE_EN='0' and cycle_cnt = 14 then --120bit ---> 64bit
                            cycle_cnt <= (others=>'0');
                        elsif G12_9BYTE_EN='1' and cycle_cnt = 26 then --120bit ---> 64bit
                            cycle_cnt <= (others=>'0');
                        else
                            cycle_cnt <= cycle_cnt + 1;
                        end if;
                             ---8 120bit ---> 15 8bytes
					    if pck_len_128 = 0 then
							vid_rdreq_en <= (others=>'0');
						else
							if G12_9BYTE_EN='0'  then --10bytes@2 pixels
								case( conv_integer(cycle_cnt)) is
									when  0   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  1   => vid_rdreq_en  <= (others=>'0');
									when  2   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  3   => vid_rdreq_en  <= (others=>'0');
									when  4   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  5   => vid_rdreq_en  <= (others=>'0');
									when  6   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  7   => vid_rdreq_en  <= (others=>'0');
									when  8   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  9   => vid_rdreq_en  <= (others=>'0');
									when  10  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  11  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  12  => vid_rdreq_en  <= (others=>'0');
									when  13  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  14  => vid_rdreq_en  <= (others=>'0');
									when others=> vid_rdreq_en <= (others=>'0');
								end case;
							else --9byte@2 pixels
								case( conv_integer(cycle_cnt)) is
									when  0   => vid_rdreq_en  <= (others=>'1'); 	pck_len_128 <= pck_len_128 - 1 ;
									when  1   => vid_rdreq_en  <= (others=>'0');
									when  2   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  3   => vid_rdreq_en  <= (others=>'0');
									when  4   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  5   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  6   => vid_rdreq_en  <= (others=>'0');
									when  7   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  8   => vid_rdreq_en  <= (others=>'0');
									when  9   => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  10  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  11  => vid_rdreq_en  <= (others=>'0');
									when  12  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  13  => vid_rdreq_en  <= (others=>'0');
									when  14  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  15  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  16  => vid_rdreq_en  <= (others=>'0');
									when  17  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  18  => vid_rdreq_en  <= (others=>'0');
									when  19  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  20  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  21  => vid_rdreq_en  <= (others=>'0');
									when  22  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  23  => vid_rdreq_en  <= (others=>'0');
									when  24  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  25  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when  26  => vid_rdreq_en  <= (others=>'1');	pck_len_128 <= pck_len_128 - 1 ;
									when others=> vid_rdreq_en <= (others=>'0');
								end case;
							end if;
						end if;
                    end if;

                when parse_done_st =>
                    rd_done_notify_conv <= '0';
                    first_8b_b     <= '0';
                    first_8b       <= '0';
                    push_out_en    <= '0';
                    push_header_en <= '0';
                    frm_end_f_en   <= '0';
                    frm_start_F_en <= '0';
                    vid_rdreq_en   <= (others=>'0');
                    if tx_cnt = 4 then
                       tx_cnt <= (others=>'0');
                       pstate <= idle_st;
                    else
                       pstate <= parse_done_st;
                       tx_cnt <= tx_cnt + 1;
                    end if;
                when others=>
				    pstate       <= idle_st;
                    vid_rdreq_en <= (others=>'0');
                    push_out_en  <= '0';
            end case;
        end if;
    end if;
end process;


process(nRST_conv,convclk_i)
begin
    if nRST_conv = '0' then
        req_f9_upload_buf <= '0' ;
    elsif rising_edge(convclk_i) then
        -- if pstate = tx_sync_st and tx_sync_cnt = 53 then
        if pstate = tx_sync_st and tx_cnt = VSYNC_FRM_DUR and eth_port = real_eth_num_conv-1 then
            req_f9_upload_buf <= '0' ;
        elsif req_f9_upload = '1' then
            req_f9_upload_buf <= '1' ;
        end if;
    end if;
end process;

process(convclk_i,nRST_conv)
begin
    if nRST_conv = '0' then
        bright_coef_sel <=  (OTHERS=>'1');
        colort_R_sel    <=  (OTHERS=>'1');
        colort_G_sel    <=  (OTHERS=>'1');
        colort_B_sel    <=  (OTHERS=>'1');
    elsif rising_edge(convclk_i) then
        bright_coef_sel <=   bright_coeff ( conv_integer(eth_port)*8+7 downto conv_integer(eth_port)*8+0 );
        colort_R_sel    <=    chroma_r   ( conv_integer(eth_port)*8+7 downto conv_integer(eth_port)*8+0 );
        colort_G_sel    <=    chroma_g   ( conv_integer(eth_port)*8+7 downto conv_integer(eth_port)*8+0 );
        colort_B_sel    <=    chroma_b   ( conv_integer(eth_port)*8+7 downto conv_integer(eth_port)*8+0 );

        if dly_cnt = 0 then
            txsync_wdata(63 downto 40) <= X"FFFFFF";
            txsync_wdata(39 DOWNTO 0)  <= X"0000000000";
        elsif dly_cnt = 1 then
            txsync_wdata(63 downto 40) <= X"010000"; ----send card sign 01
            txsync_wdata(39 DOWNTO 0)  <= X"0000000000";
		elsif dly_cnt = 2 then
            txsync_wdata(63 downto 48) <= colort_G_sel&colort_R_sel ;
            txsync_wdata(47 downto 40) <= "0000000"&req_f9_upload_buf ;
            --bit3: eco k vld 20230826 
            -- txsync_wdata(39 DOWNTO 0)  <= "0000"&eco_k_vld&low_bright_en &"00"&bright_coef_sel&X"00"&function_enable(7 downto 0)&X"00"  ;
            txsync_wdata(39 DOWNTO 0)  <= "0000"&eco_k_vld&low_bright_en &'0' & low_bright_en &bright_coef_sel&X"00"&function_enable(7 downto 0)&X"00"  ;
        elsif dly_cnt = 3 then
            txsync_wdata(63 downto 40) <= secret_data(15 downto 0)&rcv_led_flick;
            txsync_wdata(39 downto 8)  <= X"FFFF0000";
            txsync_wdata(7 downto 0 )  <= colort_B_sel;
        elsif dly_cnt = 4 then
            txsync_wdata(63 downto 40) <= HDR_rr(7 downto 0)&HDR_rr(15 downto 8)&HDR_type;
            txsync_wdata(39 downto 32) <= "0000000" & HDR_enable;
            txsync_wdata(31 downto 0 ) <=  secret_data(47 downto 16);
        elsif dly_cnt = 5 then
            txsync_wdata(63 downto 40) <= HDR_rb(7 downto 0)&HDR_rb(15 downto 8)&HDR_rg(7 downto 0);                             
            txsync_wdata(39 downto 0)  <= HDR_rg(15 downto 8)&HDR_bb(7 downto 0)&HDR_bb(15 downto 8)&HDR_gg(7 downto 0)&HDR_gg(15 downto 8);                           
        elsif dly_cnt = 6 then 
            txsync_wdata(63 downto 40) <= HDR_bg(7 downto 0)&HDR_bg(15 downto 8)&HDR_br(7 downto 0);
            txsync_wdata(39 downto 0)  <= HDR_br(15 downto 8)&HDR_gb(7 downto 0)&HDR_gb(15 downto 8)&HDR_gr(7 downto 0)&HDR_gr(15 downto 8);
        elsif dly_cnt = 7 then 
            txsync_wdata(63 downto 56) <=    "00"&invert_dissolve_level(frm_remapin_vsync_idx_x4+3 downto frm_remapin_vsync_idx_x4)&PN_frame_type(frm_remapin_vsync_idx_x2+1 downto frm_remapin_vsync_idx_x2);
            txsync_wdata(55 downto 0)  <=    info_3d&HLG_type &  ("00"&HDR_coef);
        elsif dly_cnt = 8 then
            txsync_wdata(63 downto 48) <=  (others=>'0');
            txsync_wdata(47 downto 32) <=  "000000" & virtual_direction & "000000" & virtual_pix_en;
			txsync_wdata(31 downto 24) <= (others=>'0');
			txsync_wdata(23 downto 16) <= frame_remapping_en&"000"&frame_remapping_vsync_idx;
            txsync_wdata(15 downto 0)  <=  "0000000"&bright_weight(frm_remapin_vsync_idx_x9+8 downto frm_remapin_vsync_idx_x9);
        elsif dly_cnt = 9 then
            txsync_wdata(63 downto 40) <=  (others=>'0');
            txsync_wdata(39 downto 0)  <=  (others=>'0');
        elsif dly_cnt = 10 then
            txsync_wdata(63 downto 40) <=  (others=>'0');
            txsync_wdata(39 downto 0)  <=  (others=>'0');
        elsif dly_cnt = 11 then
            txsync_wdata(63 downto 56) <=  "00000"&colorspace;
            txsync_wdata(55 downto 0)  <=  (others=>'0');
        elsif dly_cnt = 12 then 
            txsync_wdata(63 downto 16) <=  (others=>'0');            
            txsync_wdata(15 downto 8)  <=   eco_k_val;  --- eco k value , one frame delay (determined in BK)
			txsync_wdata(7 downto 0)   <=  (others=>'0');
        else
            txsync_wdata(63 downto 40) <=  (others=>'0');
            txsync_wdata(39 downto 0)  <=  (others=>'0');
        end if;

    end if;
end process;
frm_remapin_vsync_idx_x2 <= conv_integer(frame_remapping_vsync_idx&'0');--*2
frm_remapin_vsync_idx_x4 <= conv_integer(frame_remapping_vsync_idx&"00");--*4
frm_remapin_vsync_idx_x9 <= conv_integer(frame_remapping_vsync_idx&"000")+conv_integer(frame_remapping_vsync_idx);--*9


       dly_pushen_sel         <=   dly_push_en(SEL_P);
       dly_pushhead_sel       <=   dly_push_header_en(SEL_P);
       dly_pushhead_sel_b     <=   dly_push_header_en(SEL_P-1);
       dly_frmstart_sel_en    <=   dly_frm_start_F_en(SEL_P) ;
       dly_cycle_sel          <=   dly_cyclecnt( (SEL_P+1)*CT_W-1 downto SEL_P*CT_W) ;
       dly_first8_sel         <=   dly_first_8(SEL_P );
       netport_sel            <=   X"0"&dly_netport( (SEL_P+1)*4-1 downto SEL_P*4) ;
       dly_rdreq_sel          <=   dly_fifo_rdreq(SEL_P);
       dly_frm_end_sel_en     <=   dly_frm_end_f_en(SEL_P);
       dly_frm_type_sel       <=   dly_push_Frm_type((SEL_P+1)*2-1 downto SEL_P*2);
       px_bcnt_sel            <=   dly_cycle_sel ;




   process(convclk_i,nRST_conv)
   begin
        if nRST_conv = '0' then
            dly_cyclecnt       <= (others=>'0');
            dly_push_header_en <= (others=>'0');
            dly_frm_end_f_en   <= (others=>'0');
            dly_frm_start_F_en <= (others=>'0');
            dly_push_Frm_type  <= (others=>'0');
            dly_push_en        <= (others=>'0');
            dly_netport        <= (others=>'0');
            d1_cycl_cnt_b      <= (others=>'0');
			lock_data          <= (others=>'0');
        elsif rising_edge(convclk_i) then
            d1_cycl_cnt_b      <= cycle_cnt;
            dly_cyclecnt       <= dly_cyclecnt((SEL_P )*CT_W-1 downto 0)&d1_cycl_cnt_b; ---loop_cnt;
            dly_netport        <= dly_netport ((SEL_P )*4-1 downto 0)&eth_port;
            dly_push_bnum      <= dly_push_bnum     ((SEL_P )*4-1 downto 0)&push_bytenum;
            dly_first_8        <= dly_first_8       ((SEL_P )*1  downto 0)&first_8b;
            dly_frm_end_f_en   <= dly_frm_end_f_en  ((SEL_P )*1-1 downto 0)&frm_end_f_en;
            dly_frm_start_F_en <= dly_frm_start_F_en((SEL_P )*1-1 downto 0)&frm_start_F_en;
            dly_push_Frm_type  <= dly_push_Frm_type ((SEL_P )*2-1 downto 0)&push_frm_type;
            dly_fifo_rdreq     <= dly_fifo_rdreq    ((SEL_P )*1-1 downto 0)&vid_rdreq_en(0);
            ---flag to push
            txdata_info(3 downto  0)   <= dly_push_bnum((SEL_P+1)*4-1 DOWNTO SEL_P*4); --bytenum
            txdata_info(4)             <= dly_frmstart_sel_en;
            txdata_info(5)             <= dly_frm_end_sel_en;
            txdata_info(6)             <= dly_pushhead_sel;
            txdata_info(8 downto 7)    <= dly_frm_type_sel;



            if dly_vsync_conv = '1' then --no parsing
                dly_push_header_en <= (others=>'0');
                dly_push_en        <= (others=>'0');
                txdata_wren        <= '0';
				vsync_frm_en       <= '0';
            else
                dly_push_header_en <= dly_push_header_en(SEL_P-1 DOWNTO 0)&push_header_en;
                dly_push_en        <= dly_push_en(SEL_P-1 DOWNTO 0)&push_out_en;

                --vsync 0x1 frame
                if dly_frm_type_sel = FRM_VSYNC THEN
					vsync_frm_en   <= '1';
                   IF dly_pushhead_sel = '1' then
                       if dly_frmstart_sel_en = '0' then
                           txdata_wren <= '1';
                           txdata_wdata<= X"D5555555555555FB"; --64bit
                           dly_cnt     <= (others=>'0');
                       else
                           txdata_wren <= '1';
                           txdata_wdata(63 downto 40)<= X"FF00FF" ; ---
                           txdata_wdata(39 downto 32)<= X"01"; ---VSYNC FRAME
                           if SERDES_5G_EN = '0' THEN
                              txdata_wdata(31 downto  0)<= X"00"&netport_sel&X"2211";
                           ELSE
                              txdata_wdata(31 downto  0)<= X"00"&x"00"&X"2211";
                           END IF;
                           dly_cnt  <= dly_cnt + 1;
                       end if;

                   elsif dly_pushen_sel = '1' then
                         txdata_wren <= '1';
                         if dly_cnt(4) = '0' then
                             dly_cnt <= dly_cnt + 1 ;
                         end if;
                         txdata_wdata <= txsync_wdata;
                   else
                       txdata_wren <= '0';
                   end if;

                elsif dly_pushhead_sel = '1' then --video
					vsync_frm_en   <= '0';
                    if dly_frmstart_sel_en = '0' then
                       txdata_wren <= '1';
                       txdata_wdata<= X"D5555555555555FB"; --64bit
                    else
						txdata_wren <= '1';
						if vidfrm_type = '0' then
							txdata_wdata(63 downto 56)<= col_start(15 downto 8);
							txdata_wdata(55 downto 40)<= row_cur(7 downto 0)&row_cur(15 downto 8);
							if color_depth = COLOR12_DEPTH and TEST_12BIT_TO_8BIT = 1 then
								txdata_wdata(39 downto 32)<= X"55"; --8BIT
							elsif color_depth = COLOR8_DEPTH  then
								txdata_wdata(39 downto 32)<= X"55"; --8BIT
							elsif color_depth = COLOR10_DEPTH then
								txdata_wdata(39 downto 32)<= X"54"; --10BIT
							else
								txdata_wdata(39 downto 32)<= X"53"; --12BIT
							end if;
						else
						
							txdata_wdata(63 downto 56)<= rcv_card_idx(15 downto 8);
							txdata_wdata(55 downto 40)<= (others=>'0');---serial number
							if color_depth = COLOR12_DEPTH and TEST_12BIT_TO_8BIT = 1 then
								txdata_wdata(39 downto 32)<= X"5A"; --8BIT
							elsif color_depth = COLOR8_DEPTH  then
								txdata_wdata(39 downto 32)<= X"5A"; --8BIT
							elsif color_depth = COLOR10_DEPTH then
								txdata_wdata(39 downto 32)<= X"5B"; --10BIT
							else
								txdata_wdata(39 downto 32)<= X"5C"; --12BIT
							end if;						
						end if;
						
						if SERDES_5G_EN = '0' then
							txdata_wdata(31 downto  0)<= x"00"&netport_sel&X"2211";
						else
							txdata_wdata(31 downto  0)<= x"00"&X"00"&X"2211";
						end if;
                    end if;
                elsif dly_pushen_sel = '1' then
                    txdata_wren <= '1';
					if TEST_12BIT_TO_8BIT = 1 and color_depth = COLOR12_DEPTH then
					    lock_data(119 downto 72) <=(others=>'0');
						if dly_first8_sel = '1' then
							txdata_wdata(63 downto 40) <= filter8_fifo_q(23 downto 0); --lsb data
							if vidfrm_type = '0' then								
								txdata_wdata(39 downto 32) <= X"88";
								txdata_wdata(31 downto 24) <= backup_flag_sign&X"8";
								txdata_wdata(23 downto 0)  <= pixel_num(7 downto 0)&pixel_num(15 downto 8)&col_start(7 downto 0);
								
							else
															
								txdata_wdata(39 downto 32) <= frm_cnt(7 downto 0);
								
								txdata_wdata(31 downto 28) <= backup_flag_sign;
								txdata_wdata(27 downto 24 )<= frm_cnt(11 downto 8);
								
								txdata_wdata(23 downto 16) <= pixel_num(7 downto 0);
								
								txdata_wdata(15)           <= last_frm_en;-----last packet in cur card  
								txdata_wdata(14 downto 9)  <= (others=>'0');---rsv
								txdata_wdata(8)            <= pixel_num(8);
								
								txdata_wdata(7 downto 0)   <= rcv_card_idx(7 downto 0);
							end if;
							lock_data(71 downto 0)     <= filter8_fifo_q(71 downto 0);							
						else
							if dly_rdreq_sel = '1' then --120bit
								lock_data(71 downto 0)<= filter8_fifo_q(71 downto 0);
							end if;
							case conv_integer(px_bcnt_sel) is
								when 0 => txdata_wdata <= filter8_fifo_q(3*8-1 downto 0*8)&lock_data(9*8-1 downto 4*8);
								when 1 => txdata_wdata <= filter8_fifo_q(2*8-1 downto 0*8)&lock_data(9*8-1 downto 3*8);
								when 2 => txdata_wdata <= filter8_fifo_q(1*8-1 downto 0*8)&lock_data(9*8-1 downto 2*8);
								when 3 => txdata_wdata <= lock_data(9*8-1 downto 1*8);
								when 4 => txdata_wdata <= filter8_fifo_q(8*8-1 downto 0*8);
							    when 5 => txdata_wdata <= filter8_fifo_q(7*8-1 downto 0*8)&lock_data(9*8-1 downto 8*8);
								when 6 => txdata_wdata <= filter8_fifo_q(6*8-1 downto 0*8)&lock_data(9*8-1 downto 7*8);
								when 7 => txdata_wdata <= filter8_fifo_q(5*8-1 downto 0*8)&lock_data(9*8-1 downto 6*8);
								when others => txdata_wdata <= filter8_fifo_q(4*8-1 downto 0*8)&lock_data(9*8-1 downto 5*8);
							end case;
						end if;

                    elsif color_depth = COLOR8_DEPTH then --8bit
                        if dly_cycle_sel = 0 then
                           if dly_first8_sel = '1' then
                               txdata_wdata(63 downto 40) <= filter8_fifo_q(23 downto 0); --lsb data
								if vidfrm_type = '0' then								
									txdata_wdata(39 downto 32) <= X"88";
									txdata_wdata(31 downto 24) <= backup_flag_sign&X"8";
									txdata_wdata(23 downto 0)  <= pixel_num(7 downto 0)&pixel_num(15 downto 8)&col_start(7 downto 0);
								
								else
									txdata_wdata(39 downto 32) <= frm_cnt(7 downto 0);
								
									txdata_wdata(31 downto 28) <= backup_flag_sign;
									txdata_wdata(27 downto 24 )<= frm_cnt(11 downto 8);
								
									txdata_wdata(23 downto 16) <= pixel_num(7 downto 0);
								
									txdata_wdata(15)           <= last_frm_en;-----last packet in cur card  
									txdata_wdata(14 downto 9)  <= (others=>'0');---rsv
									txdata_wdata(8)            <= pixel_num(8);
								
									txdata_wdata(7 downto 0)   <= rcv_card_idx(7 downto 0);
								end if;
                               lock_data(71 downto 0)     <= filter8_fifo_q(95 downto 24);
                           else
                               txdata_wdata(63 downto 40) <= filter8_fifo_q(23 downto 0); --lsb data
                               txdata_wdata(39 downto 0 ) <= lock_data(39 downto 0) ;
                               lock_data(71 downto 0)     <= filter8_fifo_q(95 downto 24);
                           end if;
                        elsif dly_cycle_sel = 1 then
                             txdata_wdata(63 downto 0) <= lock_data( 63 downto 0);
                        else
                             txdata_wdata(63 downto 8)  <= filter8_fifo_q(55 downto 0);
                             txdata_wdata(7 downto 0)   <= lock_data(71 downto 64);
                             lock_data(39 downto 0)     <= filter8_fifo_q(95 downto 56);
                        end if;
                    elsif color_depth = COLOR10_DEPTH then --10bit
                        if dly_cycle_sel = 0 then
                           if dly_first8_sel = '1' then
                              txdata_wdata(63 downto 40) <= filter10_fifo_q(23 downto 0); --lsb data
								if vidfrm_type = '0' then								
									txdata_wdata(39 downto 32) <= X"AA";
									txdata_wdata(31 downto 24) <= backup_flag_sign&X"A";
									txdata_wdata(23 downto 0)  <= pixel_num(7 downto 0)&pixel_num(15 downto 8)&col_start(7 downto 0);
								
								else
									txdata_wdata(39 downto 32) <= frm_cnt(7 downto 0);
								
									txdata_wdata(31 downto 28) <= backup_flag_sign;
									txdata_wdata(27 downto 24 )<= frm_cnt(11 downto 8);
								
									txdata_wdata(23 downto 16) <= pixel_num(7 downto 0);
								
									txdata_wdata(15)           <= last_frm_en;-----last packet in cur card  
									txdata_wdata(14 downto 9)  <= (others=>'0');---rsv
									txdata_wdata(8)            <= pixel_num(8);
								
									txdata_wdata(7 downto 0)   <= rcv_card_idx(7 downto 0);
								end if;
                              lock_data(103 downto 0)    <= filter10_fifo_q(127 downto 24);
                            else
                               txdata_wdata(63 downto 40) <= filter10_fifo_q (23 downto 0);
                               txdata_wdata(39 downto 0)  <= lock_data(39 downto 0);
                               lock_data(103 downto 0)    <= filter10_fifo_q(127 downto 24);
                            end if;
                        elsif dly_cycle_sel = 1 then
                             txdata_wdata           <= lock_data(63  downto 0);
                             lock_data(39 downto 0) <= lock_data(103 downto 64);
                        else
                        end if;
                    else  --12bit
                        if dly_first8_sel = '1' then
                           txdata_wdata(63 downto 40) <= filter12_fifo_q(23 downto 0); --lsb data
								if vidfrm_type = '0' then								
									txdata_wdata(39 downto 32) <= X"CC";
									txdata_wdata(31 downto 24) <= backup_flag_sign&X"C";
									txdata_wdata(23 downto 0)  <= pixel_num(7 downto 0)&pixel_num(15 downto 8)&col_start(7 downto 0);
								
								else
									txdata_wdata(39 downto 32) <= frm_cnt(7 downto 0);
								
									txdata_wdata(31 downto 28) <= backup_flag_sign;
									txdata_wdata(27 downto 24 )<= frm_cnt(11 downto 8);
								
									txdata_wdata(23 downto 16) <= pixel_num(7 downto 0);
								
									txdata_wdata(15)           <= last_frm_en;-----last packet in cur card  
									txdata_wdata(14 downto 9)  <= (others=>'0');---rsv
									txdata_wdata(8)            <= pixel_num(8);
								
									txdata_wdata(7 downto 0)   <= rcv_card_idx(7 downto 0);
								end if;
                           lock_data(119 downto 0)    <= filter12_fifo_q(119 downto 0);
                        else
                           if dly_rdreq_sel = '1' then --120bit
                               lock_data(119 downto 0)     <= filter12_fifo_q(119 downto 0);
                           end if;
                           --120bit only
                           IF G12_9BYTE_EN = '0' THEN
                                case conv_integer(px_bcnt_sel) is---- >= 8 then
                                      -- when 0     => txdata_wdata <= filter12_fifo_q(8*8-1 downto 0*8);
                                      -- when 1     => txdata_wdata <= filter12_fifo_q(7*8-1 downto 0*8)&lock_data(15*8-1 downto 14*8);
                                      -- when 2     => txdata_wdata <= filter12_fifo_q(6*8-1 downto 0*8)&lock_data(15*8-1 downto 13*8);
                                      -- when 3     => txdata_wdata <= filter12_fifo_q(5*8-1 downto 0*8)&lock_data(15*8-1 downto 12*8);
                                      -- when 4     => txdata_wdata <= filter12_fifo_q(4*8-1 downto 0*8)&lock_data(15*8-1 downto 11*8);
                                      -- when 5     => txdata_wdata <= filter12_fifo_q(3*8-1 downto 0*8)&lock_data(15*8-1 downto 10*8);
                                      -- when 6     => txdata_wdata <= filter12_fifo_q(2*8-1 downto 0*8)&lock_data(15*8-1 downto  9*8);
                                      -- when 7     => txdata_wdata <= filter12_fifo_q(1*8-1 downto 0*8)&lock_data(15*8-1 downto  8*8);
                                      -- when 8     => txdata_wdata <= lock_data(15*8-1 downto 7*8);
                                      -- when 9     => txdata_wdata <= lock_data(14*8-1 downto 6*8);
                                      -- when 10    => txdata_wdata <= lock_data(13*8-1 downto 5*8);
                                      -- when 11    => txdata_wdata <= lock_data(12*8-1 downto 4*8);
                                      -- when 12    => txdata_wdata <= lock_data(11*8-1 downto 3*8);
                                      -- when 13    => txdata_wdata <= lock_data(10*8-1 downto 2*8);
                                      -- when 14    => txdata_wdata <= lock_data( 9*8-1 downto 1*8);
                                      -- when others=> txdata_wdata <= lock_data( 8*8-1 downto 0*8);
									when 0     => txdata_wdata <= filter12_fifo_q(3*8-1 downto 0*8)&lock_data(15*8-1 downto 10*8);
									when 1     => txdata_wdata <= lock_data(11*8-1  downto 3*8);
									when 2     => txdata_wdata <= filter12_fifo_q(4*8-1 downto 0*8)&lock_data(15*8-1 downto 11*8);
									when 3     => txdata_wdata <= lock_data(12*8-1 downto 4*8);
									when 4     => txdata_wdata <= filter12_fifo_q(5*8-1 downto 0*8)&lock_data(15*8-1 downto 12*8);
									when 5     => txdata_wdata <= lock_data(13*8-1 downto 5*8);
									when 6     => txdata_wdata <= filter12_fifo_q(6*8-1 downto 0*8)&lock_data(15*8-1 downto 13*8);
									when 7     => txdata_wdata <= lock_data(14*8-1 downto 6*8);
									when 8     => txdata_wdata <= filter12_fifo_q(7*8-1 downto 0*8)&lock_data(15*8-1 downto 14*8);
									when 9     => txdata_wdata <= lock_data(15*8-1 downto 7*8);
									when 10    => txdata_wdata <= filter12_fifo_q(8*8-1 downto 0*8);
									when 11    => txdata_wdata <= filter12_fifo_q(1*8-1 downto 0*8)&lock_data(15*8-1 downto 8*8);
									when 12    => txdata_wdata <= lock_data(9*8-1 downto 1*8);
									when 13    => txdata_wdata <= filter12_fifo_q(2*8-1 downto 0*8)&lock_data(15*8-1 downto 9*8);
									when others =>txdata_wdata <= lock_data(10*8-1 downto 2*8);
                                end case;
                            ELSE
                                  case conv_integer(px_bcnt_sel) is---- >= 8 then

                                      when 0     => txdata_wdata <= filter12_fifo_q(24-1 downto 0 )&lock_data(107 downto 68);
                                      when 1     => txdata_wdata <= lock_data(88-1 downto 24);
                                      when 2     => txdata_wdata <= filter12_fifo_q(44-1 downto 0 )&lock_data(108-1 downto 88);
                                      when 3     => txdata_wdata <= lock_data(108-1 downto 44);
                                      when 4     => txdata_wdata <= filter12_fifo_q(64-1 downto  0 );
                                      when 5     => txdata_wdata <= filter12_fifo_q(20-1 downto 0)&lock_data(108-1 downto 64);
                                      when 6     => txdata_wdata <= lock_data(84-1 downto  20);
                                      when 7     => txdata_wdata <= filter12_fifo_q(40-1 downto 0)&lock_data(108-1 downto  84);
                                      when 8     => txdata_wdata <= lock_data(104-1 downto  40);
                                      when 9     => txdata_wdata <= filter12_fifo_q(60-1 downto 0)&lock_data(108-1 downto 104);
                                      when 10    => txdata_wdata <= filter12_fifo_q(16-1 downto 0)&lock_data(108-1 downto 60);
                                      when 11    => txdata_wdata <= lock_data(80-1 downto 16);
                                      when 12    => txdata_wdata <= filter12_fifo_q(36-1 downto 0)&lock_data(108-1 downto 80);
                                      when 13    => txdata_wdata <= lock_data( 100-1 downto 36);
                                      when 14    => txdata_wdata <= filter12_fifo_q(56-1 downto 0)&lock_data(108-1 downto 100);
                                      when 15    => txdata_wdata <=  filter12_fifo_q(12-1 downto 0)&lock_data(108-1 downto 56);
                                      when 16    => txdata_wdata <=  lock_data( 76-1 downto 12);
                                      when 17    => txdata_wdata <=  filter12_fifo_q(32-1 downto 0)&lock_data(108-1 downto 76);
                                      when 18    => txdata_wdata <=  lock_data(96-1 downto 32);
                                      when 19    => txdata_wdata <=  filter12_fifo_q(52-1 downto 0)&lock_data(108-1 downto 96);
                                      when 20    => txdata_wdata <=  filter12_fifo_q(8-1 downto 0)&lock_data(108-1 downto 52);
                                      when 21    => txdata_wdata <=  lock_data(72-1 downto 8 );
                                      when 22    => txdata_wdata <=  filter12_fifo_q(28-1 downto 0)&lock_data(108-1 downto 72);
                                      when 23    => txdata_wdata <=  lock_data(92-1 downto 28 );
                                      when 24    => txdata_wdata <=  filter12_fifo_q(48-1 downto 0)&lock_data(108-1 downto 92);
                                      when 25    => txdata_wdata <=  filter12_fifo_q(4-1 downto 0)&lock_data(108-1 downto 48 );
                                      when 26    => txdata_wdata <=  lock_data(68-1 downto 4 );
                                   when others=> txdata_wdata <= lock_data( 8*8-1 downto 0*8);
                                   end case;
                            END IF;
                        end if;
                    end if;
                else
                    txdata_wren <= '0';
                end if;
            end if;
        end if;
    end process;

    process(nRST_conv,convclk_i)
    begin
        if nRST_conv = '0' then
               crc_clr_i   <= '0';
               crc_wren_in  <= '0';
        elsif rising_edge(convclk_i) then
            if dly_vsync_conv = '1' then
                  crc_clr_i <= '1';
            else
                  crc_clr_i <= dly_pushhead_sel_b and (not dly_frm_start_F_en(SEL_P-1)); ---wait finished before
            end if;
            if dly_vsync_conv = '1' then
                crc_wren_in <= '0';
            elsif txdata_info(6)= '1' then ----dly_pushhead_sel ='1' then
                crc_wren_in <= '1';
            elsif txdata_wren = '1' then ----dly_pushen_sel = '1' then
                crc_wren_in <= '1';
            else
                crc_wren_in <= '0';
            end if;

            if txdata_info(6)= '1' then ---- dly_pushhead_sel ='1' then
                if  txdata_info(4)='0' then ----dly_frmstart_sel_en = '0' then
                   crc_wdata  <= X"2222665544332211";
                   crc_firstw <= '1';
                   crc_bnum   <= X"8";
				   eth_lock   <= eth_port;
				   pix_num_lock <= pixel_num(8 downto 0);
				   color_depth_lock <= color_depth;
				   vsync_frm_en_lock<= vsync_frm_en;
                else
                   crc_firstw <= '0';
                   crc_wdata  <= txdata_wdata(63 downto 32)&X"66554433";
                   crc_bnum   <= X"8";
                end if;
            elsif txdata_wren = '1' then ----dly_pushen_sel = '1' then
                crc_firstw <= '0';
                crc_wdata  <= txdata_wdata(63 downto 0);
                crc_bnum   <= txdata_info(3 downto  0);
            else
                crc_firstw <= '0';
                crc_wdata  <= txdata_wdata(63 downto 0);
                crc_bnum   <= txdata_info(3 downto  0);
            end if;
            crc_lastw  <= txdata_info(5);
            --crc_firstw <= txdata_info(4);
			eth_lock_d1     <= eth_lock;
			eth_lock_d2_int <= conv_integer(eth_lock_d1);
			pix_num_lock_d1 <= pix_num_lock;
			pix_num_lock_d2 <= pix_num_lock_d1;
			color_depth_lock_d1 <= color_depth_lock;
			color_depth_lock_d2 <= color_depth_lock_d1;
			vsync_frm_en_lock_d1 <= vsync_frm_en_lock;
			vsync_frm_en_lock_d2 <= vsync_frm_en_lock_d1;
			
			
        end if;
    end process;
        -----------------------------------
        ----crc top is called here  ----no
      calc_crc: crc64_top
       generic map
       (

        B_W  => 4 , --at most 8 bytes
        D_W  => 64 ,
        D_LSB_F=> 1 , ---'1': data is lsb BYTE first, '0': data is msb first (first out)
        CRC_W  => 32 ,
        INV_BYTE_BIT => 1    -- 1 : bit7 bit0 swap FOR NEW,  '0': no swap for OLD (2003 VERSION)
       )
       port map
       (
          nRST       => nRST_conv,
          clr_i      => crc_clr_i ,
          clk_i      => convclk_i ,
          frm_en_i   => txdata_wren ,
          ctrl_i     => (others=>'0'),
          data_i     => crc_wdata(63 downto 0),
          bnum_i     => crc_bnum ,
          din_en_i   => crc_wren_in,
          last_en_i  => crc_lastw,
          first_en_i => crc_firstw,

          --delayed one-clock version of the inputs
          den_o      => crc_wren_out,
          laste_o    => crc_laste_o,
          frm_en_o   => crc_frm_en_o ,
          ctrl_o     => open ,

          firsten_o  => crc_firsten_o ,
          bnum_o     => crc_bn_out,
          total_bnum => open ,
          data_o     => open ,
          crc_o      => crc_o
       );

     process(nRST_conv,convclk_i)
     begin
        if nRST_conv = '0' then
            txdata_d1  <= X"07070707"&X"07070707";
            txdata_d2  <= X"07070707"&X"07070707";
            txdata_out <= X"07070707"&X"07070707";
        elsif rising_edge(convclk_i) then
            txdata_d1  <= txdata_wdata;
            txdata_d2  <= txdata_d1;
            txdata_out <= txdata_d2;
        end if;
     end process;

     process(crc_o)
     begin
         for i in 0 to 31 loop
            crc_buf(i) <= not crc_o(31-i);
         end loop;
     end process;

process(nRST_conv,convclk_i)
begin
    if nRST_conv = '0' then
        append_en      <= '0';
        xgmii_wren     <= (others=>'0');
        xgmii_control  <= X"FF";
        xgmii_data_out <= X"07070707"&X"07070707";
        vidinfo_wren   <= (others=>'0');
        xgmii_cnt      <= (others=>'0');
    elsif rising_edge(convclk_i) then

        if dly_vsync_conv = '1' then
            append_en      <= '0';
            xgmii_control  <= X"FF";
            xgmii_data_out <= X"07070707"&X"07070707";
            xgmii_wren     <= (others=>'0');
            app_byten      <= X"0";
            vidinfo_wren   <= (others=>'0');
            vidinfo_wdata  <= (others=>'0');
            xgmii_cnt      <= (others=>'0');
        elsif crc_wren_out = '1' then

            xgmii_cnt   <= xgmii_cnt + 1 ;
            if crc_laste_o = '1' then
                xgmii_wren(eth_lock_d2_int)  <= '1';
                vidinfo_wren(eth_lock_d2_int)   <= '1';
				
				vidinfo_wdata(20)               <= vsync_frm_en_lock_d2;
				vidinfo_wdata(19 downto 11)     <= pix_num_lock_d2;
				vidinfo_wdata(10 downto 9)      <= color_depth_lock_d2;
                IF NOXGMII_HEAD = '1' THEN
                    if crc_bn_out <= 3 then  ---append 4 byte crc and FD ECP
                       append_en     <= '0';
                       vidinfo_wdata(8 downto 0)<= xgmii_cnt(8 downto 0) ;
                    else
                       append_en     <= '1';
                       vidinfo_wdata(8 downto 0)<= xgmii_cnt(8 downto 0)+1;
                    end if;
                ELSE
                    if crc_bn_out <= 3 then  ---append 4 byte crc and FD ECP
                       append_en     <= '0';
                       vidinfo_wdata(8 downto 0)<= xgmii_cnt(8 downto 0)+1;
                    else
                       append_en     <= '1';
                       vidinfo_wdata(8 downto 0)<= xgmii_cnt(8 downto 0)+2;
                    end if;
                END IF;
                case(conv_integer(crc_bn_out)) is
                    when 1 =>app_byten <= X"0"; xgmii_control <= X"E0";xgmii_data_out<=X"0707"&XGMII_ECP & crc_buf&txdata_out(7 downto 0);
                    when 2 =>app_byten <= X"0"; xgmii_control <= X"C0";xgmii_data_out<=X"07"&XGMII_ECP & crc_buf&txdata_out(15 downto 0);
                    when 3 =>app_byten <= X"0"; xgmii_control <= X"80";xgmii_data_out<=     XGMII_ECP & crc_buf&txdata_out(23 downto 0);
                    when 4 =>app_byten <= X"1"; xgmii_control <= X"00";xgmii_data_out<=                 crc_buf&txdata_out(31 downto 0);
                    when 5 =>app_byten <= X"2"; xgmii_control <= X"00";xgmii_data_out<=    crc_buf(23 DOWNTO 0)&txdata_out(39 downto 0);
                    when 6 =>app_byten <= X"3"; xgmii_control <= X"00";xgmii_data_out<=    crc_buf(15 DOWNTO 0)&txdata_out(47 downto 0);
                    when 7 =>app_byten <= X"4"; xgmii_control <= X"00";xgmii_data_out<=    crc_buf( 7 DOWNTO 0)&txdata_out(55 downto 0);
                    when 8 =>app_byten <= X"5"; xgmii_control <= X"00";xgmii_data_out<=    txdata_out(63 downto 0);
                    when others=> app_byten <= X"0";
                end case;
            else
                append_en      <= '0';
                vidinfo_wren   <=  (others=>'0');
                xgmii_data_out <= txdata_out(63 downto 0);
                if NOXGMII_HEAD = '1' and crc_firsten_o = '1' then
                    xgmii_wren  <= (others=>'0');
                else
					xgmii_wren  <= (others=>'0');
                    xgmii_wren(eth_lock_d2_int)  <= '1';
                end if;
                if crc_firsten_o = '1' then
                    xgmii_control <= X"01";
                else
                    xgmii_control <= X"00";
                end if;
            end if;
        elsif append_en = '1' then
            vidinfo_wren   <=  (others=>'0');
            xgmii_wren(eth_lock_d2_int)     <= '1';
            xgmii_cnt      <= xgmii_cnt + 1 ;
            append_en      <= '0';
            case(conv_integer(app_byten)) is
                when 1      => xgmii_control <= X"FF";xgmii_data_out <= X"07070707070707"&XGMII_ECP;
                when 2      => xgmii_control <= X"FE";xgmii_data_out <= X"070707070707"&XGMII_ECP&crc_buf(31 DOWNTO 24);
                when 3      => xgmii_control <= X"FC";xgmii_data_out <= X"0707070707"&XGMII_ECP&crc_buf(31 DOWNTO 16);
                when 4      => xgmii_control <= X"F8";xgmii_data_out <= X"07070707"&XGMII_ECP&crc_buf(31 DOWNTO 8);
                when 5      => xgmii_control <= X"F0";xgmii_data_out <= X"070707"&XGMII_ECP&crc_buf(31 DOWNTO 0);
                when OTHERS => xgmii_control <= X"F0";xgmii_data_out <= X"070707"&XGMII_ECP&crc_buf(31 DOWNTO 0);
            end case;
        else
            vidinfo_wren   <= (others=>'0');
            append_en      <= '0';
            xgmii_wren     <= (others=>'0');
            xgmii_cnt      <= (others=>'0');
            xgmii_control  <= X"FF";
            xgmii_data_out <= X"07070707"&X"07070707";
        end if;
    end if;
end process;

end beha;

