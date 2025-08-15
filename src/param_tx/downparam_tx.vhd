
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_CRC32_D8.all;

entity downparam_tx is
generic
(  sim     : std_logic := '0';
   IS_5G    : std_logic ;
   NOXGMII_HEAD : std_logic := '1'; ---'1':
   IS_BACK : std_logic := '0'; ---main or backup
   P_W     : INTEGER   := 4  ; ---Depend on IS_BACK AND eth_num
   ETH_IDX_F : INTEGER   := 0  ; ---STARTING INDEX ------
   ETH_IDX : INTEGER   := 0  ; 
   ETH_NUM : INTEGER   := 10 ;
   REALTIME_PARAM_EN   : std_logic:= '1';
   SCHED_NUM_PER_SEG   : integer := 4 
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
    ----to param07_sched
    tx07_cc_req     :  in   std_logic ; --tx one 0x7 packet ;if the unit has many eth port ,then notify 
    tx07_cc_idx     :  in   std_logic_vector(3 downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
    tx07_cc_ack     :  out  std_logic ;
    tx07_cc_end     :  in   std_logic ; ----all sched done ....(downparam_tx can switch its ping-pong now )
    tx07_cc_done    :  out  std_logic ;
    
    vsync_neg_i     : in std_logic ;
    rt_tx_done      : out std_logic ; ---rt_tx_done to tx 
    ---------------------------------------------------
    txparam_wren      : out std_logic ;
    txparam_wdata     : out std_logic_vector(72 downto 0);
    txparam_waddr_o   : out std_logic_vector( 8 downto 0); --512*80bit at most
	txdpram_posdec_en_xgmiitx  : in std_logic ;

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

	eth_mask_en_convclk			  : in  std_logic_vector(ETH_NUM-1 downto 0);
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)	
	

   );
end downparam_tx;

architecture beha of downparam_tx is

 constant SEL_P : integer := 1;
 constant A_W   : integer := 8; ---

 constant RFT_DETECT_RCV : std_logic_vector(7 downto 0) := X"07";
---recv 0xcc frame
-- recv RT PARAM FRAME HERE
--crc8
constant FT_FORWARD_PARAM : std_logic_vector(7 downto 0):= X"CC" ;
constant OFF_SUBBOARD     :  INTEGER := 1 ;

signal down_wrnum       :  std_logic_vector(10 downto 0); --64bit
signal down_wrcnt       :  integer range 0 to 7 ; --64bit
signal down_lastw       :  std_logic := '0';

signal down2RCV_rdata    : std_logic_vector(71 downto 0) := (others=>'0');
signal downp_wdata       : std_logic_vector(71 downto 0) := (others=>'0');
signal p_downlink_length : std_logic_vector(11 downto 0) := (others=>'0');
signal p_downlink_done   : std_logic := '0';
signal down_wren          : std_logic := '0';

signal p_downlink_waddr  : std_logic_vector(A_W downto 0) := (others=>'0');
signal txparam_waddr     :   std_logic_vector( 8 downto 0);
signal downparam_portnum : std_logic_vector(7 downto 0) := (others=>'0');

signal downlink_done_d1 : std_logic := '0';

signal down_append_en : std_logic := '0';

component rt_param_store is
generic
(  sim     : std_logic := '0';
   IS_5G    : std_logic ;
   P_W     : INTEGER   := 4  ; ---Depend on IS_BACK AND eth_num
   ETH_IDX : INTEGER   := 0  ; ---STARTING INDEX ------
   ETH_NUM : INTEGER   := 10 ;
   REALTIME_PARAM_EN   : std_logic:= '1'
);
port
(
    nRST            : in std_logic ;
    clk_i           : in std_logic ;
    p_Frame_en_i    : in std_logic ;
    p_Wren_i        : in std_logic ;
    p_Data_i        : in std_logic_vector(7 downto 0);
    p_Addr_i        : in std_logic_vector(10 downto 0);
 
	
	tx_rt_rdaddr    : in  std_logic_vector(11 downto 0);
    rt_rdata        : out std_logic_vector(72*(ETH_NUM/2)-1 downto 0);
    rt_area_brdcast          : out std_logic := '0';
    rt_gamut_brdcast         : out std_logic := '0';
    rt_bright_brdcast        : out std_logic := '0';
	
    rt_area_word_length      : out std_logic_vector(8 downto 0);
    rt_g1_word_length        : out std_logic_vector(8 downto 0);
    rt_g2_word_length        : out std_logic_vector(8 downto 0);
    rt_bright_word_length    : out std_logic_vector(8 downto 0);
	
	rt_area_eth_arrived      : out std_logic_vector(ETH_NUM-1 downto 0);
	rt_gamut1_eth_arrived	 : out std_logic_vector(ETH_NUM-1 downto 0);
	rt_gamut2_eth_arrived	 : out std_logic_vector(ETH_NUM-1 downto 0);
	rt_bright_eth_arrived	 : out std_logic_vector(ETH_NUM-1 downto 0);
	
    rt_area_para_en          : out std_logic := '0';
    rt_bright_para_en        : out std_logic := '0';
    rt_gamut_para_en         : out std_logic := '0';
	frm8a_rd_point           : in  std_logic_vector(9 downto 0);
	frm8a_man_en             : in std_logic;
	frm8a_wr_point_o         : out std_logic_vector(9 downto 0);
	
	real_eth_num_conv        : in std_logic_vector(3 downto 0)


   );
end component;
signal 	frm8a_rd_point              :   std_logic_vector(9 downto 0):=(others=>'0');
signal 	frm8a_rd_point_d1           :   std_logic_vector(9 downto 0):=(others=>'0');
signal 	frm8a_wr_point              :   std_logic_vector(9 downto 0);

signal	rt_area_eth_arrived      :  std_logic_vector(ETH_NUM-1 downto 0);
signal	rt_gamut1_eth_arrived	 :  std_logic_vector(ETH_NUM-1 downto 0);
signal	rt_gamut2_eth_arrived	 :  std_logic_vector(ETH_NUM-1 downto 0);
signal	rt_bright_eth_arrived	 :  std_logic_vector(ETH_NUM-1 downto 0);
	
	
    component paramBlkRam_512x72 is
        port (
            data      : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
            q         : out std_logic_vector(71 downto 0);                    -- dataout
            wraddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- wraddress
            rdaddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- rdaddress
            wren      : in  std_logic                     := 'X';             -- wren
            clock     : in  std_logic                     := 'X'              -- clk
        );
    end component paramBlkRam_512x72;


    signal cur_eth_sel_even    : integer range 0 to 20 -1 := 0;
    signal cur_eth_sel    : integer range 0 to 20 -1 := 0;
    signal d1_down_q      : std_logic_vector(71 downto 0);
    signal d1_rt_q        : std_logic_vector(71 downto 0);
    signal dly_eth_index  : std_logic_vector(P_W*(SEL_P+1)-1 DOWNTO 0);
    signal dly_pushen     : std_logic_vector(1*SEL_P  DOWNTO 0);
    signal dly_push_1st   : std_logic_vector(1*SEL_P  DOWNTO 0);
    signal dly_frm_type      : std_logic_vector(4*SEL_P-1  DOWNTO 0);
    signal dly_is_brdcast : std_logic_vector(1*SEL_P  DOWNTO 0);


    signal txparam_pingpong: std_logic := '0';
    signal down2Rcv_length : std_logic_vector(8 downto 0);
    signal rt_area_word_length    : std_logic_vector(8 downto 0);
    signal rt_g1_word_length      : std_logic_vector(8 downto 0);
    signal rt_g2_word_length      : std_logic_vector(8 downto 0);
    signal rt_bright_word_length  : std_logic_vector(8 downto 0); 
    signal tx_word_length         : std_logic_vector(8 downto 0);
    
    type sta_def is (IDLE_ST, TX_ST, TURN_ST, WAIT_ST, FLOW_ST ,WAIT_FRM8A_MAN_INFO,CHECK_RT_EFFECTIVE,GET_SHUTTER_INFO);
    signal pstate : sta_def := IDLE_ST;

    SIGNAL transfer_ack    : std_logic := '0';
    SIGNAL transfer_req    : std_logic := '0';
    SIGNAL push_en         : std_logic := '0';
    SIGNAL push_1st_en     : std_logic := '0';
    SIGNAL frm_type        : std_logic_vector(1 downto 0);
    SIGNAL port_cnt        : std_logic_vector(P_W-1 downto 0)  ;
    SIGNAL port_cnt_int        : integer ;
    SIGNAL tx_rdaddr       : std_logic_vector(A_W downto 0)  ;
    SIGNAL tx_cnt          : std_logic_vector(12 downto 0)  ; 
    signal down2Rcv_is_brd : std_logic:='0';
    --after 12 BYTE MAC
    constant CRC_MAC_INIT  : std_logic_vector(31 downto 0):=X"746110FC";
    signal  crc_data       : std_logic_vector( 7 downto 0) ;
    signal  crc_buf        : std_logic_vector(31 downto 0) ;
    signal  crc_res        : std_logic_vector(31 downto 0):=(others=>'1');
    signal crc_load_en     : std_logic:='0';
    signal crc_push_en     : std_logic:='0';
    signal transfer_frm_en : std_logic := '0';
    signal rt_p_frm_en     : std_logic := '0';
    signal downparam_is_brdcast     : std_logic := '0';
    signal rt_p_is_brdcast          : std_logic := '0';
    signal rt_p_sched_brdcast       : std_logic := '0';
    signal rt_area_brdcast          : std_logic := '0';
    signal rt_gamut_brdcast         : std_logic := '0';
    signal rt_bright_brdcast        : std_logic := '0';
    signal rt_rdata                 : std_logic_vector(72*(ETH_NUM/2)-1 downto 0) := (others=>'0');
    signal rt_downdata_en           : std_logic := '0';
    signal down2RCV_wren            : std_logic := '0';
    signal rt_area_para_en          : std_logic := '0';
    signal rt_bright_para_en        : std_logic := '0';
    signal rt_gamut_para_en         : std_logic := '0';
    signal tx_is_brdcast            : std_logic := '0';
    signal tx_is_firstWord          : std_logic := '0';
    signal hit_eth                  : std_logic := '0';
	signal cur_eth_num              : std_logic_vector(P_W-1 downto 0):=(others=>'0');
	signal cur_eth_num_buf          : std_logic_vector(7 downto 0):=(others=>'0');
	signal rt_frm_type              : std_logic_vector(7 downto 0):=(others=>'0');
	signal txdpram_num              : std_logic_vector(1 downto 0):=(others=>'0');
	signal txdpram_posdec_en_d1  : std_logic :='0';
	signal txdpram_posdec_en_d2  : std_logic :='0';
	signal txdpram_posdec_en_d3  : std_logic :='0';
    signal txdpram_posdec_pos    : std_logic :='0';
	signal txdpram_preinc_en     : std_logic :='0'; 
	
	signal rt_sched_eth_arrived        : std_logic_vector(ETH_NUM-1 downto 0);
	signal rt_eth_arrived_lock   : std_logic_vector(ETH_NUM-1 downto 0);
	
    ---shuttr sync or bright or gamut frame 
   signal   rt_area_frm_en    : std_logic := '0';
   signal   rt_bright_frm_en  : std_logic := '0';
   signal   rt_shutter_frm_en : std_logic := '0';
   signal   rt_gamut_frm_en   : std_logic := '0';
   signal   rcv_frmtype       : std_logic_vector(7 downto 0); ---rcv card frame type 
   signal   tsubfrm_idx        : std_logic_vector(7 downto 0); 
   signal   tx_is_07_flg      : std_logic := '0';
    component altera_std_synchronizer is 
    generic (depth : integer := 3);
    port 
    (  clk : in std_logic ;
       reset_n : in std_logic ;
       din     : in std_logic ;
       dout    : out std_logic
    );
    end component ;
    signal down_rt_waddr   : std_logic_vector(10 downto 0);
    signal tx_rt_rdaddr    : std_logic_vector(11 downto 0);
    signal downw_rt_msb    : std_logic_vector(1 downto 0);
    signal sel_rt_cnt      : std_logic_vector(1 downto 0);
    signal rt_sched_cnt    : std_logic_vector(1 downto 0);
    signal rt_sched_para_en: std_logic := '0';
    signal rt_word_length  : std_logic_vector(8 downto 0);
	signal rt_p_sched_blk_lock : std_logic_vector(1 downto 0);
	signal rt_txword_length_lock : std_logic_vector(8 downto 0);
	signal vsync_neg_i_d1  : std_logic;
	


signal flow_cnt   : std_logic_vector(12*ETH_NUM-1 downto 0) := (others=>'0');
signal flow_wait   : std_logic_vector(ETH_NUM-1 downto 0) := (others=>'0');
signal cycle_cnt   : std_logic_vector(4*ETH_NUM-1 downto 0) := (others=>'0');

signal frm8a_rd_point_main_d1 : std_logic_vector(9 downto 0);
signal frm8a_rd_point_back_d1 : std_logic_vector(9 downto 0);
signal frm8a_man_notify_en_d1 :  std_logic;

component shuttersync_sched is 
generic 
(  
	UNIT_INDEX   : INTEGER  := 2 ; --for fiber 2 or 4, for 5G 4 ;
	ETH_PER_UNIT : INTEGER  := 2 ; --EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
	SCHED_NUM_PER_SEG : integer := 4 ;
	IS_5G         : std_logic := '0' ;
	IS_BACK       : std_logic := '0' 

);
port 
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;
	vsync_neg             :  in  std_logic ;
	
    shutter_prefecth_en   :  in  std_logic;
	shutter_effective_en  :  out std_logic;
	
	shutter_enable_o      : out std_logic;
   --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    -----------------------------------------------------------------

	shutter_rd_addr       : in std_logic_vector(9 downto 0);
	shutter_rd_q          : out std_logic_vector(ETH_PER_UNIT*72-1 downto 0);
	
	shutter_frm_length    : out std_logic_vector(ETH_PER_UNIT*SCHED_NUM_PER_SEG*8-1 downto 0);
	shutter_frm_valid     : out std_logic_vector(ETH_PER_UNIT*SCHED_NUM_PER_SEG*1-1 downto 0);
	
	shutter_rsp_dvld      : in std_logic;
	shutter_rsp_data      : in std_logic_vector(71 downto 0);
	shutter_rd_eth_index  : out std_logic_vector(3 downto 0);
	shutter_rd_frm_index  : out std_logic_vector(14 downto 0);
	shutter_rd_req        : out std_logic;
	shutter_rd_ack        : in  std_logic;
	shutter_rd_frmvld             : in  std_logic;
	shutter_rd_end                : in  std_logic	;
	
	real_eth_num_conv             : in  std_logic_vector(3 downto 0)
	
		
);
end component;

signal	shutter_enable        :  std_logic;
signal  shutter_prefecth_en   :  std_logic;
signal	shutter_effective_en  :  std_logic;
signal	shutter_rd_addr       :  std_logic_vector(9 downto 0);
signal	shutter_rd_q          :  std_logic_vector(ETH_NUM*72-1 downto 0);

signal	shutter_frm_length    :  std_logic_vector(ETH_NUM*SCHED_NUM_PER_SEG*8-1 downto 0);
signal	shutter_frm_valid     :  std_logic_vector(ETH_NUM*SCHED_NUM_PER_SEG*1-1 downto 0);

signal  shutter_frm_cnt       :  std_logic_vector(1 downto 0):=(others=>'0');
signal  shutter_tx_length     :  std_logic_vector(7 downto 0):=(others=>'0');
signal  shutter_tx_vld        :  std_logic_vector(0 downto 0):=(others=>'0');

signal  shutter_tx_done       :  std_logic;
signal  shutter_abort         :  std_logic;
signal  d1_shutter_q          :  std_logic_vector(71 downto 0);
signal  cmd_data_buf          :  std_logic_vector(8 downto 0);

    
begin 




    process(nRST,clk_i)
    begin
        if nRST = '0' then
    ---down_wrcnt <= conv_integer(down_wrnum(2 downto 0));
          crc_res <= X"FFFFFFFF";
        ELSIF rising_edge(clk_i) then
           if crc_load_en = '1' then
              crc_res <= CRC_MAC_INIT ;---after 12 BYTE MAC ADDRESS
           elsif crc_push_en = '1' then
              crc_res <= nextCRC32_D8 (crc_data,crc_res);
           end if;
        end if;
    end process;
    process(crc_res)
    begin
        for i in 0 to 3 loop
          for j in 0 to 7 loop
             crc_buf((3-i)*8+ j) <= not crc_res(i*8+7-j);
          end loop;
        end loop;
    end process;
 vlds1: altera_std_synchronizer
     generic map (depth =>3)
     port map 
     (          clk     => clk_i  , 
				reset_n => nRST, 
				din     => txdpram_posdec_en_xgmiitx , 
				dout    => txdpram_posdec_en_d2  
     );
txdpram_posdec_pos <= '1' when 	txdpram_posdec_en_d3 = '1' and txdpram_posdec_en_d2 = '0' else '0'; --falling edge ...
	process(nRST,clk_i)
	begin
		if nRST = '0' then
			txdpram_num <=(others=>'0');
		elsif rising_edge(clk_i) then

			txdpram_posdec_en_d3 <= txdpram_posdec_en_d2 ;			
			
			if txdpram_preinc_en = '1' and txdpram_posdec_pos = '1' then
				txdpram_num <= txdpram_num ;
			elsif txdpram_preinc_en = '1' then
				txdpram_num <= txdpram_num +1;
			elsif txdpram_posdec_pos = '1' then
				txdpram_num <= txdpram_num -1;
			end if;
		end if;
	end process;

    process(nRST,clk_i)
    begin 
        if nRST = '0' then 
           cur_eth_num_buf <= (others=>'0');
        elsif rising_edge(clk_i) then 
            if transfer_frm_en = '1' then
				if downparam_portnum = X"FF" then
					cur_eth_num_buf <= (others=>'0');---FF start from eth 0
				elsif IS_5G ='0' then --1G /10G Fiber
                    if ETH_IDX_F = 0 then --two fibers
					    cur_eth_num_buf <= downparam_portnum;
				    else
					    cur_eth_num_buf <= downparam_portnum-real_eth_num_conv;
                    end if;
                else --5G ------4 eth ports (one eth per port)
                    if ETH_IDX_F = 0 then
                       cur_eth_num_buf <= downparam_portnum; --SHOULD BE ZERO

                    elsif ETH_IDX_F = 1 THEN
                       cur_eth_num_buf <= downparam_portnum-1;--SHOULD BE ZERO
                    elsif ETH_IDX_F = 2 THEN
                       cur_eth_num_buf <= downparam_portnum-2;--SHOULD BE ZERO
                    ELSE
                       cur_eth_num_buf <= downparam_portnum-3;
                    END IF;
				end if;
			end if;
       end if;
    end process;
    
    process(nRST,clk_i)
    begin 
        if nRST = '0' then
            downparam_is_brdcast  <= '0';

        elsif rising_edge(clk_i) then 
            if downparam_portnum = X"FF" then 
                downparam_is_brdcast <= '1';
            else 
                downparam_is_brdcast <= '0';
            end if;

        end if;
    end process;
	
	

    
    process(nRST,clk_i)
    begin 
        if nRST = '0' then
            transfer_frm_en      <= '0';
            rt_p_frm_en          <= '0';
            downlink_done_d1     <= '0';
            down_append_en     <= '0';
            crc_load_en          <= '0';
            crc_push_en          <= '0';         
            down_lastw           <= '0';
            hit_eth              <= '0';
						
        elsif rising_edge(clk_i) then 
            crc_data <= p_Data_i;  
            
            if p_Frame_en_i = '1' then  
                down_lastw        <= '0';
                if p_Wren_i = '1' and p_Addr_i = 0 then 
                    rt_p_frm_en       <= '0';
                    transfer_frm_en   <= '0';
                    if p_Data_i = FT_FORWARD_PARAM then
                       transfer_frm_en <= '1';
                       rt_frm_type     <= p_Data_i ; --param type 
                    else 
                       rt_frm_type     <= p_Data_i ; --param type
                       transfer_frm_en <= '0';
                    end if;                      
                end if; 


                if p_Wren_i = '1' and transfer_frm_en = '1' then			-- frm_cc
                    crc_push_en          <= '0';
                    crc_load_en          <= '0';
                    down2RCV_wren        <= '0';                    
                    downlink_done_d1  <= '0';
                    down_append_en <= '0';
                    if p_Addr_i = 0+OFF_SUBBOARD then
                        downparam_portnum <= p_Data_i;
                        down_wrnum        <= (others=>'0');
                        IF p_Data_i = X"FF" or 
                         ( p_Data_i >= ETH_IDX_F *conv_integer(real_eth_num_conv) AND p_Data_i < (ETH_IDX_F+1) *conv_integer(real_eth_num_conv)) then 
                                  hit_eth <= '1';
                        else 
                                  hit_eth <= '0';
                        end if;
						down_wrcnt <= 0;
                    elsif p_Addr_i = 3+OFF_SUBBOARD and hit_eth = '1' then 
                        --down_wrcnt <= 7;  --push data for next cycle              
                    elsif p_Addr_i = 4+OFF_SUBBOARD and hit_eth = '1' then
                        p_downlink_length(7 downto 0) <= p_Data_i;
                        down_wrcnt <= 0;

                    elsif p_Addr_i = 5+OFF_SUBBOARD and hit_eth = '1' then
                        p_downlink_length(11 downto 8) <= p_Data_i(3 downto 0);
                       --header
                        downp_wdata(71 downto 64)    <= (others=>'0');
                        downp_wdata (31 downto 16)   <=  X"00"&cur_eth_num_buf;
                        downp_wdata (15 downto 0)    <=  X"2211";
                        down_wrcnt                   <= 4;
                        crc_push_en                   <= '0';
                        crc_load_en                   <= '1';
                    elsif  p_Addr_i >= 6+OFF_SUBBOARD and hit_eth = '1' then
                        crc_load_en <= '0';
                        crc_push_En <= '1';
                        if p_Addr_i = 6+OFF_SUBBOARD then 
                             rcv_frmtype <= p_Data_i; ---rcv card frame type ------
                        end if;
                        downp_wdata(down_wrcnt*8+7 downto down_wrcnt*8) <= p_Data_i;
                        down_wrnum <= down_wrnum + '1';
                        if down_wrcnt = 7 then
                            down_wrcnt <= 0;
                        else
                            down_wrcnt <= down_wrcnt + 1;
                        end if;
                    else
                        crc_push_en <= '0';
                        crc_load_en <= '0';
                    end if;

                    if hit_eth = '1'  and down_wrnum = (p_downlink_length - 1)  and p_Addr_i > 7+OFF_SUBBOARD  then
                        p_downlink_done <= '1';
                    end if;

                    if down_wrcnt = 7 and hit_eth = '1' then
                      -- down_wren <= '1';
                        down_wren <= '1';
                        down2RCV_wren <= '1';
                    else
                        down_wren <= ('0');
                        down2RCV_wren        <= '0';
                    end if;

 
                end if;
            else
				   hit_eth  <= '0';
                   down2RCV_wren        <= '0';
                   crc_push_en <= '0';
                   crc_load_en <= '0';
                   downlink_done_d1 <= p_downlink_done;
                   if downlink_done_d1 = '1'   then
                       down_wren       <= ('1');
                       down2RCV_wren   <= transfer_frm_en;
                       case (down_wrcnt ) is    --has some data left
                           when 0      => downp_wdata(71 downto  0) <=X"F0"& X"070707FD"&CRC_buf;   down_append_en<='0';down_lastw<='1';
                           when 1      => downp_wdata(71 downto  8) <=X"E0"& X"0707FD"&CRC_buf;     down_append_en<='0';down_lastw<='1';
                           when 2      => downp_wdata(71 downto 16) <=X"C0"& X"07FD"&CRC_buf;       down_append_en<='0';down_lastw<='1';
                           when 3      => downp_wdata(71 downto 24) <=X"80"& X"FD"&CRC_buf;         down_append_en<='0';down_lastw<='1';
                           when 4      => downp_wdata(71 downto 32) <=X"00"&  CRC_buf(31 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when 5      => downp_wdata(71 downto 40) <=X"00"&  CRC_buf(23 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when 6      => downp_wdata(71 downto 48) <=X"00"&  CRC_buf(15 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when 7      => downp_wdata(71 downto 56) <=X"00"&  CRC_buf( 7 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when others => downp_wdata(71 downto 32) <=X"00"&  CRC_buf;              down_append_en<='1';down_lastw<='0';
                       end case;
                   elsif  down_append_en = '1' then
                        down_append_en <= '0';
                        down_lastw       <= '1';
                        case (down_wrcnt ) is    --has some data left
                           when 4      => down2RCV_wren <= transfer_frm_en;down_wren <= '1';downp_wdata(71 downto 0)  <=X"FF"&  X"07070707070707FD";
                           when 5      => down2RCV_wren <= transfer_frm_en;down_wren <= '1';downp_wdata(71 downto 0) <=X"FE"&  X"070707070707FD"&  CRC_buf(31 DOWNTO 24);
                           when 6      => down2RCV_wren <= transfer_frm_en;down_wren <= '1';downp_wdata(71 downto 0) <=X"FC"&  X"0707070707FD"&  CRC_buf(31 DOWNTO 16);
                           when 7      => down2RCV_wren <= transfer_frm_en;down_wren <= '1';downp_wdata(71 downto 0) <=X"F8"&  X"07070707FD"&  CRC_buf(31 DOWNTO 8);
                           when others => down2RCV_wren <= '0'            ;down_wren <= '0';downp_wdata(71 downto 0) <=X"FF"&  X"0707070707070707";
                       end case;
                   else
                       down_append_en  <= '0';
                       down_lastw      <= '0';
                       down_wren       <= ('0');
                       down2RCV_wren   <= ('0');

                   end if;
                   p_downlink_done <= '0';

              end if;


              if p_Addr_i = 2 + OFF_SUBBOARD and p_Wren_i = '1' and transfer_frm_en = '1'  then
                    p_downlink_waddr <= (others=>'0'); ----p_downlink_waddr <= (others => '0');
              elsif down_wren = '1' then
                    p_downlink_waddr <= p_downlink_waddr + '1';
              end if;

                if down_wren = '1' and down_lastw = '1' then
                    if transfer_frm_en = '1' then
                        down2Rcv_length <= ("0"&p_downlink_waddr(A_W-1 downto 0))+1;---(others=>'0');
                        down2Rcv_is_brd <= downparam_is_brdcast;
						cur_eth_num     <= cur_eth_num_buf(P_W-1 downto 0) ;---lock eth num

                    end if;                 
                end if;

        end if;
    end process;

   downCmd2RCV_i:   paramBlkRam_512x72
        port map(
            data      => downp_wdata      , -- datain
            q         => down2RCV_rdata   ,                    -- dataout
            wraddress => p_downlink_waddr , -- wraddress
            rdaddress => tx_rdaddr        ,  ------down2RCV_raddr   , -- rdaddress
            wren      => down2RCV_wren       ,            -- wren
            clock     => clk_i     -- clk
        ); 
        
   
    process(sel_rt_cnt,tx_rdaddr,port_cnt,frm8a_rd_point,frm8a_man_en,frm8a_wr_point)
	begin
		if sel_rt_cnt = "00" then
		
			if frm8a_man_en = '1' then  ----Z8T
				tx_rt_rdaddr  <= frm8a_rd_point(conv_integer(port_cnt))&sel_rt_cnt   & tx_rdaddr   ; 
			else ------Z8
				tx_rt_rdaddr  <= (not frm8a_wr_point(conv_integer(port_cnt)))&sel_rt_cnt   & tx_rdaddr   ; 
			end if;				
				
			-- if frm8a_rd_point(conv_integer(port_cnt))= '0' or frm8a_man_en= '0' then			
				-- tx_rt_rdaddr  <= '0'&sel_rt_cnt   & tx_rdaddr   ; 
			-- else
				-- tx_rt_rdaddr  <= '1'&sel_rt_cnt   & tx_rdaddr   ; 
			-- end if;
		else
			tx_rt_rdaddr  <= '0'&sel_rt_cnt   & tx_rdaddr   ; 
		end if;
	end process;
        
rt_param_inst: rt_param_store 
generic map
(  sim                => sim                ,
   IS_5G              => IS_5G              ,
   P_W                => P_W                ,
   ETH_IDX            => ETH_IDX            ,
   ETH_NUM            => ETH_NUM            ,
   REALTIME_PARAM_EN  => REALTIME_PARAM_EN 
)
port map
(
    nRST                     => nRST,
    clk_i                    => clk_i,
    p_Frame_en_i             => p_Frame_en_i_orig,
    p_Wren_i                 => p_Wren_i_orig,
    p_Data_i                 => p_Data_i_orig,
    p_Addr_i                 => p_Addr_i_orig,
                             
	                         
	tx_rt_rdaddr             => tx_rt_rdaddr,
    rt_rdata                 => rt_rdata ,
	                                                  
    rt_area_brdcast          => rt_area_brdcast       ,  
    rt_gamut_brdcast         => rt_gamut_brdcast      ,
    rt_bright_brdcast        => rt_bright_brdcast     ,
	                                                  
    rt_area_word_length      => rt_area_word_length   ,
    rt_g1_word_length        => rt_g1_word_length     ,
    rt_g2_word_length        => rt_g2_word_length     ,
    rt_bright_word_length    => rt_bright_word_length ,
	
	rt_area_eth_arrived      => rt_area_eth_arrived     ,
	rt_gamut1_eth_arrived	 => rt_gamut1_eth_arrived	,
	rt_gamut2_eth_arrived	 => rt_gamut2_eth_arrived	,
	rt_bright_eth_arrived	 => rt_bright_eth_arrived	,
	                                                  
    rt_area_para_en          => rt_area_para_en       ,
    rt_bright_para_en        => rt_bright_para_en     ,
    rt_gamut_para_en         => rt_gamut_para_en  ,
	frm8a_rd_point           => frm8a_rd_point,
	frm8a_man_en             => frm8a_man_en    ,
	real_eth_num_conv        => real_eth_num_conv,
	frm8a_wr_point_o         => frm8a_wr_point


   );
   
   frm8a_rd_point <= frm8a_rd_point_main when IS_BACK='0' else frm8a_rd_point_back;
   
   	----------flow_cnt  ----------------
	
	process(nRST,clk_i)
	begin
		if nRST = '0' then
			flow_cnt <= (others=>'0');
			flow_wait<= (others=>'0');
			cycle_cnt<= (others=>'0');
		
		elsif rising_edge(clk_i) then
		
			for i in 0 to ETH_NUM-1 loop
				if push_1st_en = '1' and i = port_cnt then
					flow_cnt((i+1)*12-1 downto i*12) <= tx_word_length&"000"+19+24;
					flow_wait(i)  <= '1';		
					cycle_cnt((i+1)*4-1 downto i*4)<=(others=>'0');
	            -----------when 1G,8 cycle 200M  = 5 cycle 125M------------
	            -----------when 5G,8 cycle 200M  = 25 cycle 625M------------
	
				elsif flow_wait(i) ='1' then 
					if cycle_cnt((i+1)*4-1 downto i*4) = 7 then
						if IS_5G = '1' then
							flow_cnt((i+1)*12-1 downto i*12) <= flow_cnt((i+1)*12-1 downto i*12) - 25; --200M				
						else
							flow_cnt((i+1)*12-1 downto i*12) <= flow_cnt((i+1)*12-1 downto i*12) - 5;
						end if;
						cycle_cnt((i+1)*4-1 downto i*4) <=(others=>'0');
					else
						cycle_cnt((i+1)*4-1 downto i*4) <= cycle_cnt((i+1)*4-1 downto i*4) + 1 ;
					end if;
		
					if IS_5G = '1' and flow_cnt((i+1)*12-1 downto i*12) <= 25 and cycle_cnt((i+1)*4-1 downto i*4) = 7 then 
						flow_wait(i) <= '0';
					elsif IS_5G = '0' and flow_cnt((i+1)*12-1 downto i*12) <= 5 and cycle_cnt((i+1)*4-1 downto i*4) = 7 then
						flow_wait(i) <= '0';
					end if;
				end if;
			end loop;
		end if;
	end process;		
		
	shutter_rd_addr <= shutter_frm_cnt&tx_rdaddr(7 downto 0);
	port_cnt_int    <= conv_integer(port_cnt);
	process(nRST,clk_i)
	begin
		if nRST = '0' then
		
			shutter_tx_length <= (others=>'0');
			shutter_tx_vld    <= (others=>'0');
			shutter_prefecth_en <= '0';
		elsif rising_edge(clk_i) then
			if shutter_frm_cnt = 0 then
				shutter_tx_length <= shutter_frm_length(port_cnt_int*SCHED_NUM_PER_SEG*8+8*1-1  downto port_cnt_int*SCHED_NUM_PER_SEG*8+8*0) ;
				shutter_tx_vld    <= shutter_frm_valid (port_cnt_int*SCHED_NUM_PER_SEG+1-1  downto port_cnt_int*SCHED_NUM_PER_SEG+0);

			elsif shutter_frm_cnt = 1 then
				shutter_tx_length <= shutter_frm_length(port_cnt_int*SCHED_NUM_PER_SEG*8+8*2-1  downto port_cnt_int*SCHED_NUM_PER_SEG*8+8*1) ;
				shutter_tx_vld    <= shutter_frm_valid (port_cnt_int*SCHED_NUM_PER_SEG+2-1  downto port_cnt_int*SCHED_NUM_PER_SEG+1);
	
			elsif shutter_frm_cnt = 2 then
				shutter_tx_length <= shutter_frm_length(port_cnt_int*SCHED_NUM_PER_SEG*8+8*3-1  downto port_cnt_int*SCHED_NUM_PER_SEG*8+8*2) ;
				shutter_tx_vld    <= shutter_frm_valid (port_cnt_int*SCHED_NUM_PER_SEG+3-1  downto port_cnt_int*SCHED_NUM_PER_SEG+2);

			else---if shutter_frm_cnt = 4 then
				shutter_tx_length <= shutter_frm_length(port_cnt_int*SCHED_NUM_PER_SEG*8+8*4-1  downto port_cnt_int*SCHED_NUM_PER_SEG*8+8*3) ;
				shutter_tx_vld    <= shutter_frm_valid (port_cnt_int*SCHED_NUM_PER_SEG+4-1  downto port_cnt_int*SCHED_NUM_PER_SEG+3);

			end if;	

			if vsync_neg_i = '1' then
				shutter_prefecth_en <= '0';
			elsif shutter_tx_done ='1'then
				shutter_prefecth_en <= not shutter_abort;
			end if;

			
		end if;
	end process;
			
			

    process(nRST,clk_i)
    begin
        if nRST = '0' then
			transfer_ack           <= '0';
            pstate                 <= IDLE_ST;
            rt_cmdfifo_wren        <= '0';
            tx_is_brdcast          <= '0';
            push_en                <= '0';
            push_1st_en            <= '0';
            tx_cnt                 <= (others=>'0');
			txdpram_preinc_en      <= '0';
            tx_is_07_flg           <= '0';
            rt_tx_done             <= '0'; ---real param tx done
            rt_sched_cnt           <= (others=>'0');
            rt_p_sched_blk_lock    <= (others=>'0');
            tx07_cc_ack            <= '0';
            tx07_cc_done           <= '0';
			rt_sched_para_en       <= '0';
			frm8a_man_notify_en_d1 <= '0';		
			shutter_frm_cnt        <= (others=>'0');
        elsif rising_edge(clk_i) then 
			vsync_neg_i_d1 <= vsync_neg_i ;
            if vsync_neg_i = '1' AND pstate = IDLE_ST  then --MAKE SURE 
                rt_sched_cnt <= rt_sched_cnt + 1;
            end if;
             ----sched here 
            if vsync_neg_i = '1' AND pstate = IDLE_ST then 
			 	rt_p_sched_blk_lock <= rt_sched_cnt;
                if rt_sched_cnt = 0 then 
                    rt_word_length      <= rt_area_word_length;
                    rt_sched_para_en    <= rt_area_para_en; 
                    rt_p_sched_brdcast  <= rt_area_brdcast;
					rt_sched_eth_arrived      <= rt_area_eth_arrived;
                elsif rt_sched_cnt = 1 then 
                    rt_word_length      <= rt_g1_word_length ;
                    rt_sched_para_en    <= rt_gamut_para_en;
                    rt_p_sched_brdcast  <= rt_gamut_brdcast;
					rt_sched_eth_arrived      <= rt_gamut1_eth_arrived;
                elsif rt_sched_cnt = 2 then 
                    rt_word_length      <= rt_g2_word_length ;
                    rt_sched_para_en    <= rt_gamut_para_en;
                    rt_p_sched_brdcast  <= rt_gamut_brdcast;
					rt_sched_eth_arrived      <= rt_gamut2_eth_arrived;
                else 
                    rt_word_length      <= rt_bright_word_length;
                    rt_sched_para_en    <= rt_bright_para_en;
                    rt_p_sched_brdcast  <= rt_bright_brdcast;
					rt_sched_eth_arrived      <= rt_bright_eth_arrived;
                end if;
            end if;
			

			frm8a_rd_point_d1 <= frm8a_rd_point;
            
            tx07_cc_ack <= '0';
            tx07_cc_done<= '0';
            rt_tx_done  <= '0'; ---real param tx done 
			shutter_tx_done <= '0';
			shutter_abort   <= '0';
          
            case(pstate) is 
                when IDLE_ST => 
                    push_en           <= '0';
                    push_1st_en       <= '0';
                    transfer_ack      <= '0';                  
                    tx_cnt            <= (others=>'0');
                    tx_rdaddr         <= (others=>'0');
                    rt_cmdfifo_wren   <= '0';
					txdpram_preinc_en <= '0';
                    tx_is_07_flg      <= '0';
					shutter_frm_cnt           <= (others=>'0');
                                      
                    if vsync_neg_i_d1 = '1'  then  ---higher priority 
						pstate <= WAIT_FRM8A_MAN_INFO ;
                      
                    elsif tx07_cc_req  = '1' then ---scheduling the 0x7 frame here 
                        tx07_cc_ack      <= '1';
                        port_cnt         <= tx07_cc_idx; 
                        tx_word_length   <= down2Rcv_length;
                        tx_is_07_flg     <= '1';
                        if NOXGMII_HEAD = '1' THEN  
                           cmd_data_buf <= (down2Rcv_length);
                        else                         
                           cmd_data_buf <= (down2Rcv_length+1);
                        end if;  
                        tx_is_brdcast    <= '0'; ---reuired by param07_sched,not by here 
                        pstate           <= WAIT_ST;
                        frm_type         <= (others=>'0');

                    else
                        pstate <= IDLE_ST;
                        port_cnt          <= (others=>'0');
                    end if;
					
				when WAIT_FRM8A_MAN_INFO => 
						if frm8a_man_notify_en = '1' then	
							
							port_cnt          <= (others=>'0');							
							----force tx frame 8A
							if (frm8a_rd_point /= frm8a_rd_point_d1) and frm8a_man_en = '1' then
								pstate                <= CHECK_RT_EFFECTIVE;---WAIT_ST;
								frm_type              <= "01";			
								sel_rt_cnt            <= "00";              
								tx_word_length        <= rt_area_word_length;
								rt_txword_length_lock <= rt_area_word_length;
								if NOXGMII_HEAD = '1' THEN 
									cmd_data_buf <= (rt_area_word_length);
								else
									cmd_data_buf <= (rt_area_word_length+1);
								end if;
								tx_is_brdcast       <= rt_area_brdcast  ;  
								rt_eth_arrived_lock <= rt_area_eth_arrived;
							elsif rt_sched_para_en = '1'  then
								sel_rt_cnt            <= rt_p_sched_blk_lock;---- current                  
								tx_word_length        <= rt_word_length;
								rt_txword_length_lock <= rt_word_length;
								if NOXGMII_HEAD = '1' THEN 
									cmd_data_buf <= (rt_word_length);
								else
									cmd_data_buf <= (rt_word_length+1);
								end if;
								pstate                <= CHECK_RT_EFFECTIVE;---WAIT_ST;
								frm_type              <= "01";
								tx_is_brdcast         <= rt_p_sched_brdcast  ; 
								rt_eth_arrived_lock   <= rt_sched_eth_arrived;
							else
								rt_tx_done    <= '1';
								-- pstate     <= IDLE_ST;
								pstate <= GET_SHUTTER_INFO ;
							end if;
						else
							pstate  <= WAIT_FRM8A_MAN_INFO;
						end if;
						
				when CHECK_RT_EFFECTIVE =>
				
					if tx_word_length = 0 then
						-- pstate <= IDLE_ST;
						rt_tx_done <= '1';
						pstate <= GET_SHUTTER_INFO ;
				    elsif tx_is_brdcast = '1'  then
						if rt_eth_arrived_lock(0) = '1' then
							if eth_mask_en_convclk(conv_integer(port_cnt)) = '1' then				-- eth(port_cnt) is masked when broadcast, go to TURN_ST polling
								pstate <= TURN_ST;
							else
								pstate <= WAIT_ST;
							end if;
						else
							rt_tx_done <= '1';
							pstate <= GET_SHUTTER_INFO ;
						end if;
					else
						if eth_mask_en_convclk(conv_integer(port_cnt)) = '1' then
							pstate <= TURN_ST;
						elsif rt_eth_arrived_lock(conv_integer(port_cnt))='1' then
							pstate <= WAIT_ST;
						else
							pstate <= TURN_ST;
						end if;
					end if;		
					
				when GET_SHUTTER_INFO =>---for length
				
					tx_cnt <= tx_cnt+1;
					tx_word_length <= '0'&shutter_tx_length;
					if NOXGMII_HEAD = '1' THEN 
						cmd_data_buf <= ('0'&shutter_tx_length);
					else
						cmd_data_buf <= (('0'&shutter_tx_length)+1);
					end if;
					frm_type      <= "10";
					tx_is_brdcast <= '0';
					
					if tx_cnt(0)='1' then
						if shutter_effective_en = '0' then
							pstate        <= IDLE_ST;
						elsif shutter_enable = '0' then
							shutter_abort <= '0';
							pstate        <= IDLE_ST;
							shutter_tx_done <= '1';							
						elsif tx07_cc_req = '1' then
							shutter_abort <= '1';
							pstate        <= IDLE_ST;
							shutter_tx_done <= '1';
						elsif shutter_tx_vld(0) ='1' then
							if eth_mask_en_convclk(conv_integer(port_cnt)) = '1' then
								pstate <= TURN_ST;
							else
								pstate <= WAIT_ST;
							end if;
							shutter_abort <= '0';							-- when abort is vld, all eth will be abort
						else
							pstate <= TURN_ST;
							shutter_abort <= '0';
						end if;
					else
						pstate <= GET_SHUTTER_INFO;
					end if;
									

                when WAIT_ST =>
					transfer_ack     <= '0';
					rt_cmdfifo_wren  <= '0';
					push_en          <= '0';
                   
                    tx_cnt            <= (OTHERS=>'0');
                   -- if rt_cmdfifo_wusedw < 2 then 
				    -- if  txdpram_num < 2 and flow_wait(conv_integer(port_cnt))='0' then
					if  txdpram_num < 2  then 
						pstate <= TX_ST;
						push_1st_en <= '1';
						txdpram_preinc_en <= '1';
                    else
						pstate      <= WAIT_ST;
						push_1st_en <= '0';
                    end if;

                when TX_ST =>
                    push_en           <= '1';
                    push_1st_en       <= '0';
                    tx_cnt            <= (OTHERS=>'0');
                    transfer_ack      <= '0';
                    rt_cmdfifo_wren   <= '0';
                    tx_word_length    <= tx_word_length - 1;
                    tx_rdaddr         <= tx_rdaddr + 1;
					txdpram_preinc_en <= '0';
					rt_cmdfifo_wdata(8 downto 0)   <= cmd_data_buf;
					rt_cmdfifo_wdata(12 downto 9)  <= port_cnt(3 downto 0);
                    if tx_word_length <= 1 then
                       pstate          <= TURN_ST;
                       rt_cmdfifo_wren <= '1';
                    else
                       pstate <= TX_ST;
                       rt_cmdfifo_wren <= '0';
                    end if;

                when TURN_ST =>
                    push_en           <= '0';
                    push_1st_en       <= '0';
                    rt_cmdfifo_wren   <= '0';
                    tx_rdaddr         <= (others=>'0');
                    if frm_type = "01"  then
						if tx_is_brdcast = '1' then
							tx_rdaddr(A_W) <= '0'; 
						elsif  port_cnt(0) = '0' then
							tx_rdaddr(A_W) <= '1';
						else
							tx_rdaddr(A_W) <= '0'; ----
						end if;
                    end if; 
                    tx_cnt            <= (OTHERS=>'0');
                       
                    if frm_type = 0 then
						tx_word_length   <= down2Rcv_length;
                       
						if tx_is_brdcast = '0'  then                      
							pstate        <= IDLE_ST; ----IDLE_ST;
							tx07_cc_done  <= tx_is_07_flg;  --07 frame (should be forward )
						elsif port_cnt = real_eth_num_conv-1 then 
							pstate   <= IDLE_ST; ----IDLE_ST;
							port_cnt <= (others=>'0');
						elsE  ---write again
							pstate   <= WAIT_ST;
							port_cnt  <= port_cnt + 1;
						end if;    
                    elsif frm_type = 1 then
						tx_word_length   <= rt_txword_length_lock; --same for all 
						if port_cnt = real_eth_num_conv-1 then 
							pstate      <= GET_SHUTTER_INFO; 
							rt_tx_done  <= '1';
							port_cnt    <= (others=>'0');
						else  ---write again
							pstate    <= CHECK_RT_EFFECTIVE;---WAIT_ST;
							port_cnt  <= port_cnt + 1;
						end if;  
					else ---frm_type = 2
						
						if port_cnt = real_eth_num_conv-1 then 
							if shutter_frm_cnt = SCHED_NUM_PER_SEG-1 then
								pstate <= IDLE_ST;
								shutter_tx_done <= '1';
							else
								pstate <= GET_SHUTTER_INFO;
							end if;	
							port_cnt    <= (others=>'0');
							shutter_frm_cnt <= shutter_frm_cnt + 1;
						else  
							pstate    <= GET_SHUTTER_INFO;
							port_cnt  <= port_cnt + 1;
						end if;  					
																		
                    end if;
   
                when others=> 
                    pstate <= IDLE_ST; 
            end case;
        end if;
    end process;

    process(nRST,clk_i)
    begin
        if nRST = '0' then
            dly_pushen   <= (others=>'0');
            dly_push_1st <= (others=>'0');
            dly_eth_index <= (others=>'0');
            dly_frm_type     <= (others=>'0');
        elsif rising_edge(clk_i) then
            dly_is_brdcast<=  dly_is_brdcast((SEL_P-1) downto 0)     &tx_is_brdcast;
            dly_pushen    <=  dly_pushen   ((SEL_P-1) downto 0)      &push_en;
            dly_push_1st  <=  dly_push_1st ((SEL_P-1) downto 0)      &push_1st_en;
            dly_frm_type     <=  dly_frm_type    (SEL_P*2-1 downto 0)      &frm_type;
            dly_eth_index <=  dly_eth_index((SEL_P)*P_W-1 downto 0)&port_cnt;
        end if;
    end process;


    cur_eth_sel_even <= conv_integer(dly_eth_index(P_W*(SEL_P)-1 downto P_W*(SEL_P-1)+1) );
	cur_eth_sel      <= conv_integer(dly_eth_index(P_W*(SEL_P)-1 downto P_W*(SEL_P-1))) ;

    process(nRST,clk_i)
    begin
        if nRST = '0' then
            txparam_wren     <= '0';
            txparam_waddr    <= (others=>'0');
            txparam_pingpong <= '0';
        elsif rising_edge(clk_i) then
		    txparam_waddr_o <= txparam_waddr;
            d1_down_q <= down2RCV_rdata;
            if dly_is_brdcast(SEL_P-1) = '1' THEN
                d1_rt_q   <= rt_rdata( (0+1)*72-1 downto 0*72);
            else
                d1_rt_q   <= rt_rdata( (cur_eth_sel_even+1)*72-1 downto cur_eth_sel_even*72);
            end if;
			d1_shutter_q <= shutter_rd_q((cur_eth_sel+1)*72-1 downto cur_eth_sel*72);
            if dly_push_1st(SEL_P) = '1' THEN
                if NOXGMII_HEAD = '1' then
                   txparam_wren   <= '0';
                else
                   txparam_wren   <= '1';
                end if;
                txparam_wdata    <= "1"&X"01"&X"D5555555555555FB";
                txparam_waddr    <=(others=>'0');
                txparam_pingpong <= not txparam_pingpong;
                if txparam_pingpong = '0' then
                   txparam_waddr(A_W) <= '0';  --MATCH WITH CMB module
                else
                   txparam_waddr(A_W) <= '1';
                end if;
                tx_is_firstWord <= '1';
            elsif dly_pushen(SEL_P) = '1' then
               tx_is_firstWord   <= '0';
               txparam_waddr     <= txparam_waddr + 1 ;
               txparam_wren      <= '1';
			-- 00:frmCC_07	01:frm_RT	10:shutter
                if dly_frm_type((SEL_P+1)*2-1 downto SEL_P*2) = 0 THEN
                    if dly_is_brdcast(SEL_P) = '1' and tx_is_firstWord = '1' THEN
                      txparam_wdata  <= "0"&d1_down_q;
                      --replace the eth port
                      txparam_wdata(23 downto 16) <= X"0"&dly_eth_index( (SEL_P+1)*P_W-1 downto SEL_P*P_W);
                    else
                      txparam_wdata  <= "0"&d1_down_q ;
                    end if;
                elsif dly_frm_type((SEL_P+1)*2-1 downto SEL_P*2) = 1 THEN
                    if dly_is_brdcast(SEL_P) = '1' and tx_is_firstWord = '1' THEN
                       txparam_wdata               <= "0"&d1_rt_q;
                       txparam_wdata(23 downto 16) <= x"0"&dly_eth_index( (SEL_P+1)*P_W-1 downto SEL_P*P_W);
                    else
                       txparam_wdata  <= "0"&d1_rt_q;
                    end if;
				elsif dly_frm_type((SEL_P+1)*2-1 downto SEL_P*2) = 2 then
					if  tx_is_firstWord = '1' then
                       txparam_wdata               <= "0"&d1_shutter_q;
                       txparam_wdata(23 downto 16) <= x"0"&dly_eth_index( (SEL_P+1)*P_W-1 downto SEL_P*P_W);
					else
						txparam_wdata              <= "0"&d1_shutter_q;
					end if;
				else
					
                end if;
            else
               txparam_wren <= '0';
            end if;
        end if;
     end process;
	 
	 
	 
shutter_sched: shuttersync_sched 
generic map
(  
	UNIT_INDEX        => ETH_IDX, --for fiber 2 or 4, for 5G 4 ;
	ETH_PER_UNIT      => ETH_NUM, --EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
	SCHED_NUM_PER_SEG => SCHED_NUM_PER_SEG,
	IS_5G             => IS_5G   ,
	IS_BACK           => IS_BACK 
)
port map
(
    nRST                    => nRST,
    clk                     => clk_i,
	vsync_neg               => vsync_neg_i,
	                        
    shutter_prefecth_en     => shutter_prefecth_en,
	shutter_effective_en    => shutter_effective_en,
	shutter_enable_o        => shutter_enable,
   --pbus                  
    p_Frame_en_i            => p_Frame_en_i_orig,
    p_Wren_i                => p_Wren_i_orig,
    p_Data_i                => p_Data_i_orig,
    p_Addr_i                => p_Addr_i_orig,
    ----------------------
                            
	shutter_rd_addr         => shutter_rd_addr,
	shutter_rd_q            => shutter_rd_q,
	                        
	shutter_frm_length      => shutter_frm_length,
	shutter_frm_valid       => shutter_frm_valid,
	                       
	shutter_rsp_dvld        => shutter_rsp_dvld      ,
	shutter_rsp_data        => shutter_rsp_data      ,
	shutter_rd_eth_index    => shutter_rd_eth_index  ,
	shutter_rd_frm_index    => shutter_rd_frm_index  ,
	shutter_rd_req          => shutter_rd_req        ,
	shutter_rd_ack          => shutter_rd_ack   ,
	shutter_rd_frmvld       => shutter_rd_frmvld,
	shutter_rd_end          => shutter_rd_end	,
	real_eth_num_conv       => real_eth_num_conv
	
		
);


end beha;