library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----use work.const_def_pack.all;

entity xgmii_cmb is 
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
  

   vidfifo_rdata     : in  std_logic_vector(72*ETH_NUM-1 downto 0);
   vidfifo_rden      : out std_logic_vector(ETH_NUM-1 downto 0) ; 
   vidinfo_empty     : in  std_logic_vector(ETH_NUM-1 downto 0) ; 
   vidinfo_rden      : out std_logic_vector(ETH_NUM-1 downto 0) ; 
   vidinfo_rdata     : in  std_logic_vector(21*ETH_NUM-1 downto 0);
 
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
   eth_forbid_en_convclk    : in std_logic_vector(ETH_NUM-1 downto 0);
   eth_mask_en_convclk		: in std_logic_vector(ETH_NUM-1 downto 0);
   
   real_eth_num             : in std_logic_vector(3 downto 0)
);

end xgmii_cmb ;

architecture beha of xgmii_cmb is 
constant M_W    : INTEGER := 5 ;
constant SEL_P  : integer:= 0;
signal  mask_cnt      : std_logic_vector(M_W DOWNTO 0):=(OTHERS=>'0');
signal  vsync_dur     : std_logic_vector(11  DOWNTO 0):=(OTHERS=>'0');  
signal  vsync_frm_cnt : std_logic_vector(M_W DOWNTO 0):=(OTHERS=>'0');
signal  VSYNC_CNT_OVER: std_logic  := '0';  
signal  vsync_req   : std_logic := '0';
signal  vsync_ack   : std_logic := '0';
signal  push_source   : std_logic ;
signal  tx_push_en    : std_logic  := '0';
signal  tx_first_en   : std_logic  := '0';
signal  tx_last_en    : std_logic  := '0';

signal  dly_push_en     : std_logic_vector(SEL_P downto 0):=(others=>'0');
signal  dly_push_first   : std_logic_vector(SEL_P downto 0):=(others=>'0');
signal  dly_push_last    : std_logic_vector(SEL_P downto 0):=(others=>'0');
signal  dly_push_src     : std_logic_vector(SEL_P downto 0):=(others=>'0');
type st_def_p is (IDLE_ST, TXPARAM_ST, TXVID_ST, TURN_ST);
signal pstate : st_def_p := IDLE_ST ;

signal push_first_sel     : std_logic ;
signal push_sel_en        : std_logic ;
signal push_last_sel      : std_logic ;
signal push_sel_src       : std_logic ; 

signal rt_cnt             : std_logic_vector(2 downto 0); 
signal rtcmdfifo_ack      : std_logic := '0';
signal rtcmdfifo_req      : std_logic := '0';
signal rtcmd_length       : std_logic_vector(8 downto 0)  ;
signal rtcmd_eth_index_int    : integer  ;
signal rt_cmdfifo_busy    : std_logic := '0';
signal rt_is_ping         : std_logic := '0';
signal rt_msb_addr        : std_logic := '0'; 
                          
signal vidinfo_ack        : std_logic_vector(ETH_NUM-1 downto 0);
signal vidinfo_req        : std_logic_vector(ETH_NUM-1 downto 0);
signal vidinfo_cmd        : std_logic_vector(ETH_NUM*21-1 downto 0)  ;
signal vidinfo_busy       : std_logic_vector(ETH_NUM-1 downto 0);
signal vidinfo_cnt        : std_logic_vector(ETH_NUM*2-1 downto 0)  ;
signal txparam_raddr_buf  : std_logic_vector(8 downto 0)  ;
signal txcnt              : std_logic_vector(8 downto 0)  ;
signal tx_vid_frm_en      : std_logic := '0';
signal wait_txidle_cnt    : std_logic_vector(2 downto 0):=(others=>'0');
signal eth_forbid_en_d1   : std_logic_vector(ETH_NUM-1 downto 0):=(others=>'0');
signal eth_forbid_en_d2   : std_logic_vector(ETH_NUM-1 downto 0):=(others=>'0');

signal eth_mask_en_d1		: std_logic_vector(ETH_NUM-1 downto 0);
signal eth_mask_en_d2		: std_logic_vector(ETH_NUM-1 downto 0);
signal eth_mask_en			: std_logic_vector(ETH_NUM-1 downto 0);

signal xgmii_txout_buf           : std_logic_vector(71 downto 0):=(others=>'0');
signal xgmii_txout_buf_d1        : std_logic_vector(71 downto 0):=(others=>'0');
signal xgmii_txout_buf_d2        : std_logic_vector(71 downto 0):=(others=>'0');
signal eth_forbid_en             : std_logic := '0';
signal eth_sign_en               : std_logic := '0';
signal cur_eth_num               : integer range 0 to ETH_NUM-1;
signal txdpram_posdec_en_notify  : std_logic:='0';

signal check_sum_buf                : std_logic_vector(63 downto 0);
signal check_sum                    : std_logic_vector(7 downto 0);


CONSTANT V_W : integer := 26; --156.25M 24Hz  156.25M/24  =  C6AEA1/2  = 12Hz 
signal vsync_dur_cnt                   : std_logic_vector(V_W downto 0);
signal vsync_dur_last                  : std_logic_vector(V_W downto 0);
signal vsync_dur_lock                  : std_logic_vector(V_W downto 0);
signal vsync_dur_last_M                  : std_logic_vector(V_W downto 0);
CONSTANT MASK_PARAM_TX_INT                 : integer := 512;
signal mask_param_tx                       : std_logic_vector(V_W downto 0);
signal mask_param_en                       : std_logic;
signal mask_param_en_buf				   : std_logic;
signal vsync_exist                         : std_logic;
signal period_stable                       : std_logic;

signal vidfifo_rdata_sel                   : std_logic_vector(71 downto 0);

component simul_eth_timing is
generic(
	VID_NUM_IN_SLOT						: integer:= 8

);
port(
	nRST								: in  std_logic;
	sysclk								: in  std_logic;
    color_depth							: in  std_logic_vector(1 downto 0);

    output_eth_type						: in	std_logic_vector(2 downto 0);			-- "000":1G,	"001":fix 5G,	"100":average 2.5G,flexible
	
    vidout_vsync_neg                    : in  std_logic;
    pack_cmd_wren                       : in  std_logic;
    pack_cmd_data                       : in  std_logic_vector(14 downto 0);
    ch_vld                              : in  std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
    ch_sel                              : in  std_logic_vector(3 downto 0);
    
	vidinfo_req                         : in  std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);	                        
	simul_eth_almost_empty_en           : out std_logic;
	simul_eth_empty_en                  : out std_logic;
	
	simul_eth_almost_full_o             : out std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
	simul_eth_almost_empty_o            : out std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
	simul_eth_empty_o                   : out std_logic_vector(VID_NUM_IN_SLOT-1 downto 0);
	packet_gap_5g                       : in  std_logic_vector(9 downto 0)
    
);
end component;
signal ch_sel                              : std_logic_vector(3 downto 0);
signal output_eth_type                     : std_logic_vector(2 downto 0);
signal color_depth                         : std_logic_vector(1 downto 0);
signal packet_gap_5g                       : std_logic_vector(9 downto 0);
signal	simul_eth_almost_empty_en          :  std_logic;
signal	simul_eth_empty_en                 :  std_logic;

signal	simul_eth_almost_full            :  std_logic_vector(ETH_NUM-1 downto 0);
signal	simul_eth_almost_empty           :  std_logic_vector(ETH_NUM-1 downto 0);
signal	simul_eth_empty                  :  std_logic_vector(ETH_NUM-1 downto 0);
	
signal eth_index                           :  std_logic_vector(3 downto 0);
signal length_info                         :  std_logic_vector(8 downto 0);
signal frm_type                            :  std_logic_vector(1 downto 0);
signal flow_cmd_wren                       :  std_logic;
signal flow_cmd_data                       :  std_logic_vector(14 downto 0);
signal flow_cmd_wren_buf                   :  std_logic_vector(2 downto 0);
signal flow_cmd_data_buf                   :  std_logic_vector(3*15-1 downto 0);
signal loop_cnt                            :  integer range 0 to ETH_NUM-1;
signal ch_cnt                              :  integer range 0 to ETH_NUM-1;
signal loop_cnt_lock                       :  integer range 0 to ETH_NUM-1;
signal vid_req                             :  std_logic;
signal vid_ack                             :  std_logic;
signal real_eth_num_int                    :  integer ;

-- attribute syn_keep : boolean;
-- attribute syn_srlstyle : string;
-- attribute syn_keep of eth_forbid_en_d1 : signal is true;
-- attribute syn_keep of eth_forbid_en_d2 : signal is true;

-- attribute altera_attribute : string;
-- attribute altera_attribute of eth_forbid_en_d1 : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
-- attribute altera_attribute of eth_forbid_en_d2 : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;

--=============================dedbug========================================
component issp is
	port (
		source : out std_logic_vector(1 downto 0);                    -- source
		probe  : in  std_logic_vector(0 downto 0) := (others => 'X')  -- probe
	);
end component issp;
signal issp_source							:  std_logic_vector(1 downto 0);
signal issp_probe							:  std_logic_vector(0 downto 0);
signal issp_source0_d1						:  std_logic;
signal issp_source0_d2						:  std_logic;

signal xgmii_txout_d1						:  std_logic_vector(71 downto 0);
signal xgmii_ctrl							:  std_logic_vector(7 downto 0);
signal xgmii_data							:  std_logic_vector(63 downto 0);
type st_p is (debug_idle,debug_data);
signal debug_pstate : st_p := debug_idle ;
signal inint_en								:  std_logic;
signal time_us_en							:  std_logic;
signal time_ms_en							:  std_logic;
signal time_us_cnt							:  std_logic_vector(7 downto 0);
signal time_ms_cnt							:  std_logic_vector(17 downto 0);
signal cnt									:  std_logic_vector(7 downto 0);
signal eth_num_buf							:  std_logic_vector(7 downto 0);
signal frame_type								:  std_logic_vector(7 downto 0);
signal subfrm_type							:  std_logic_vector(7 downto 0);
signal frm_1A_en							:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_01_en							:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_03_en							:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_05_en							:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_08_en							:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_en_d1							:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_01_en_d1						:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_03_en_d1						:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_05_en_d1						:  std_logic_vector(ETH_NUM-1 downto 0);
signal frm_1A_08_en_d1						:  std_logic_vector(ETH_NUM-1 downto 0);
signal clr_flg								:  std_logic;--_vector(ETH_NUM-1 downto 0);
signal frm_1A_en_cnt						:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_cnt_min						:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_time_us_cnt					:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_time_us_cnt_min				:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_01_en_cnt						:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_01_cnt_min					:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_01_time_us_cnt				:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_01_time_us_cnt_min			:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_03_en_cnt						:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_03_cnt_min					:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_03_time_us_cnt				:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_03_time_us_cnt_min			:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_05_en_cnt						:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_05_cnt_min					:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_05_time_us_cnt				:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_05_time_us_cnt_min			:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_08_en_cnt						:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_08_cnt_min					:  std_logic_vector(ETH_NUM*32-1 downto 0);
signal frm_1A_08_time_us_cnt				:  std_logic_vector(ETH_NUM*11-1 downto 0);
signal frm_1A_08_time_us_cnt_min			:  std_logic_vector(ETH_NUM*11-1 downto 0);

attribute KEEP: string;
attribute KEEP of inint_en : signal is "TRUE";
attribute KEEP of clr_flg : signal is "TRUE";
attribute KEEP of time_us_en : signal is "TRUE";
attribute KEEP of time_ms_en : signal is "TRUE";
attribute KEEP of cnt : signal is "TRUE";
attribute KEEP of eth_num_buf : signal is "TRUE";
attribute KEEP of frame_type : signal is "TRUE";
attribute KEEP of subfrm_type	: signal is "TRUE";
attribute KEEP of frm_1A_en	: signal is "TRUE";
attribute KEEP of frm_1A_01_en	: signal is "TRUE";
attribute KEEP of frm_1A_03_en	: signal is "TRUE";
attribute KEEP of frm_1A_05_en	: signal is "TRUE";
attribute KEEP of frm_1A_08_en	: signal is "TRUE";
attribute KEEP of frm_1A_en_cnt: signal is "TRUE";
attribute KEEP of frm_1A_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_time_us_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_01_en_cnt: signal is "TRUE";
attribute KEEP of frm_1A_01_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_01_time_us_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_03_en_cnt: signal is "TRUE";
attribute KEEP of frm_1A_03_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_03_time_us_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_05_en_cnt: signal is "TRUE";
attribute KEEP of frm_1A_05_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_05_time_us_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_08_en_cnt: signal is "TRUE";
attribute KEEP of frm_1A_08_cnt_min: signal is "TRUE";
attribute KEEP of frm_1A_08_time_us_cnt_min: signal is "TRUE";

begin 

	real_eth_num_int <= conv_integer(real_eth_num);

   txparam_raddr <= txparam_raddr_buf;
   
   process(nRST,clk_i)
   begin 
    if nRST = '0' then 
        rtcmdfifo_req   <= '0';
        rt_cmdfifo_rden <= '0'; 
        rt_cmdfifo_busy <= '0';
        rt_is_ping      <= '0';
        rt_msb_addr     <= '0';
    elsif rising_edge(clk_i) then 
        if rt_cmdfifo_busy = '1' then
           rt_cmdfifo_rden <= '0';        
           if rt_cnt(1) = '1' then
                rt_cnt <= (others=>'0');
                rt_cmdfifo_busy <= '0'; 
                rtcmdfifo_req   <= '1';
                rt_is_ping      <= not rt_is_ping;
                rt_msb_addr     <= rt_is_ping;
                rtcmd_length    <= rt_cmdfifo_rdata(8 downto 0);                
                rtcmd_eth_index_int <= conv_integer(rt_cmdfifo_rdata(12 downto 9));                
           else
                rt_cnt <= rt_cnt + 1 ;
           end if;
        elsif rtcmdfifo_req = '1' then 
             rt_cmdfifo_rden <= '0'; 
             if rtcmdfifo_ack = '1' then 
                rtcmdfifo_req <= '0';
             end if;
             rt_cnt <= (others=>'0');
        -- elsif rt_cmdfifo_empty = '0' and mask_param_en = '0' then 
		elsif rt_cmdfifo_empty = '0'  then 
             rtcmdfifo_req    <= '0';
             rt_cmdfifo_rden  <= '1';
             rt_cmdfifo_busy  <= '1';
             rt_cnt <= (others=>'0');
        else 
            rtcmdfifo_req   <= '0';
            rt_cmdfifo_rden <= '0';
        end if;
    end if;
   end process;
 

mask_param_tx <= conv_std_logic_vector(MASK_PARAM_TX_INT,V_W+1); 
    process(nRST,clk_i)
    begin
		if nRST = '0' then
			vsync_exist    <= '0';	
			vsync_dur_cnt  <= (others=>'0');
			vsync_dur_last <= (others=>'0');
			period_stable  <= '0';	
			mask_param_en  <= '0';	
			mask_param_en_buf <= '0';			
		elsif rising_edge(clk_i) then
            if vsync_neg_i = '1' then --stable constant -
				vsync_exist      <= '1';
                vsync_dur_cnt    <= (others=>'0');
                vsync_dur_last   <= vsync_dur_cnt;
				vsync_dur_lock   <= vsync_dur_cnt;
				mask_param_en_buf <= '0';
				
                if vsync_dur_cnt(V_W) = '1' then  --invalid 
                    period_stable <= '0';
                elsif vsync_dur_cnt < X"40000" THEN ---240Hz 156.25M/240*0.5 = 4F790 (480Hz)
                    period_stable <= '0';
                elsif vsync_dur_lock >= vsync_dur_cnt then 
                    if vsync_dur_lock <= vsync_dur_cnt + 16384 then ----                        
                        period_stable <= '1';
                    else                         
                        period_stable <= '0';
                    end if;
                else 
                    if vsync_dur_cnt < vsync_dur_lock+16384 then 
                        period_stable <= '1';
                    else 
                        period_stable <= '0';
                    end if;
                end if;
            else  
                if vsync_dur_cnt(V_W)= '0' then 
                    vsync_dur_cnt <= vsync_dur_cnt + 1;
					vsync_exist   <= '1';
				else
					vsync_exist   <= '0';
                end if;
				
				if vsync_dur_last >0 then
					vsync_dur_last <= vsync_dur_last-1 ;
					if vsync_dur_last<= mask_param_tx then
						mask_param_en_buf <= '1';
					else
						mask_param_en_buf <= '0';
					end if ;
				end if;				
            end if;
			
			if period_stable = '0' or vsync_exist = '0' then
				mask_param_en  <= '0';
			else
				mask_param_en  <= mask_param_en_buf;
			end if;		
		end if;
	end process;
   
   
   process(nRST,clk_i)
   begin 
    if nRST = '0' then 
        mask_cnt  <= (others=>'0');
        vsync_dur <= (others=>'0');
    elsif rising_edge(clk_i) then 
        if vsync_neg_i = '1' then 
            mask_cnt      <= (others=>'0');
            vsync_dur     <= (others=>'0');
            vsync_frm_cnt <= (others=>'0');
        elsif mask_cnt(M_W) = '0' then 
            mask_cnt <= mask_cnt + 1;
        else 
            if vsync_dur(11) = '0' then 
                vsync_dur <= vsync_Dur + 1;
            end if;
            
            if tx_vid_frm_en = '1' then --at most 10 netport for one gour  
              if vsync_frm_cnt(M_W) = '1' then  --let vsync passed here 
                  vsync_frm_cnt <= vsync_frm_cnt + 1; 
              end if;
            end if;           
        end if;
        if vsync_neg_i = '1' then 
             VSYNC_CNT_OVER <= '0'; 
        --every 0X1 128 cycle at most , 1280 cycles reserved  
        ELSif (vsync_frm_cnt >= real_eth_num) OR (vsync_dur(11) = '1') THEN --to avoid deadlock
             VSYNC_CNT_OVER <= '1';
        else  
             VSYNC_CNT_OVER <= '0';
        end if;
        
        if vsync_neg_i  = '1' then 
           vsync_req <= '1';
        elsif vsync_ack = '1' then 
           vsync_req <= '0';
        end if;
    end if;
  end process;
  
  vidinfo_inst: for i in 0 to ETH_NUM-1 generate
  
   process(nRST,clk_i)
   begin 
    if nRST = '0' then 
        vidinfo_rden(i) <= '0'; 
        vidinfo_req(i)  <= '0'; 
        vidinfo_busy(i) <= '0'; 
    elsif rising_edge(clk_i) then 
        if vsync_neg_i = '1' or mask_cnt(M_W) = '0' THEN 
            vidinfo_rden(i) <= '0';
            vidinfo_req(i)  <= '0';
            vidinfo_busy(i)  <= '0';
            vidinfo_cnt((i+1)*2-1 downto i*2)   <= (others=>'0');
        else 
            if vidinfo_busy(i) = '1' then
                vidinfo_rden(i) <= '0';
                if vidinfo_cnt(i*2) = '1' then 
                    vidinfo_req(i) <= '1';
                    vidinfo_busy(i)<= '0';
                    vidinfo_cmd((i+1)*21-1 downto i*21) <= vidinfo_rdata((i+1)*21-1 downto i*21);
                    vidinfo_cnt((i+1)*2-1 downto i*2)   <= (others=>'0');
                else 
                    vidinfo_cnt((i+1)*2-1 downto i*2)  <= vidinfo_cnt((i+1)*2-1 downto i*2)  + 1;
                end if; 
            elsif vidinfo_req(i) = '1' then  
                vidinfo_rden(i) <= '0';             
                vidinfo_cnt((i+1)*2-1 downto i*2) <= (others=>'0');            
                if vidinfo_ack(i) = '1' then 
                   vidinfo_req(i) <= '0'; 
                end if;   
            elsif vidinfo_empty(i) = '0' then 
                vidinfo_rden(i)  <= '1';
                vidinfo_req(i)   <= '0';
                vidinfo_busy(i)  <= '1';
                vidinfo_cnt((i+1)*2-1 downto i*2)   <= (others=>'0');
            else
                vidinfo_cnt((i+1)*2-1 downto i*2)   <= (others=>'0');
                vidinfo_req(i)  <= '0';
                vidinfo_rden(i) <= '0';
            end if;
                                
         end if;
    end if;
  end process;
end generate vidinfo_inst;
  
flow_cmd_data <= frm_type&eth_index&length_info;

ch_sel <= conv_std_logic_vector(loop_cnt,4);




process(nRST,clk_i)
begin
	if nRST = '0' then
		ch_cnt  <= 0;
		vid_req <= '0';
	elsif rising_edge(clk_i) then
					
		if vsync_neg_i = '1' or mask_cnt(M_W) = '0' THEN 
			ch_cnt  <= 0;
			vid_req <= '0';	
		else			
			if vid_ack = '1' then
				if ch_cnt = real_eth_num_int-1 then
					ch_cnt <= 0;
				else
					ch_cnt <= ch_cnt + 1;
				end if;
				vid_req <= '0';
			else
				if simul_eth_empty_en = '1' then
					if simul_eth_empty(ch_cnt) = '1' then
						vid_req <= '1';
					else
						if ch_cnt = real_eth_num_int-1 then
							ch_cnt <= 0;
						else
							ch_cnt <= ch_cnt + 1;
						end if;
						vid_req <= '0';
					end if;
				elsif simul_eth_almost_empty_en = '1' then
					if simul_eth_almost_empty(ch_cnt) = '1' then
						vid_req <= '1';
					else
						if ch_cnt = real_eth_num_int-1 then
							ch_cnt <= 0;
						else
							ch_cnt <= ch_cnt + 1;
						end if;
						vid_req <= '0';
					end if;	
				else
					if simul_eth_almost_full(ch_cnt) = '0' and vidinfo_req(ch_cnt) = '1' then
						vid_req <= '1';
					else
						if ch_cnt = real_eth_num_int-1 then
							ch_cnt <= 0;
						else
							ch_cnt <= ch_cnt + 1;
						end if;
						vid_req <= '0';
					end if;	
				end if;
			end if;
		end if;
	end if;
end process;
					

 
   process(nRST,clk_i)
   begin 
    if nRST = '0' then 
        rtcmdfifo_ack <= '0';
        vsync_ack     <= '0';
        vidinfo_ack   <= (others=>'0');
        vidfifo_rden  <= (others=>'0');
        tx_push_en    <= '0';
        tx_first_en    <= '0';
        tx_last_en     <= '0';
        tx_vid_frm_en <= '0';
		wait_txidle_cnt <=(others=>'0');
    elsif rising_edge(clk_i) then 
        
        case(pstate) is 
            when IDLE_ST => -- AND VSYNC_CNT_OVER = '0'
            tx_vid_frm_en  <= '0';
            rtcmdfifo_ack  <= '0';
            vsync_ack      <= '0';
            vidinfo_ack    <= (others=>'0');
			vid_ack        <= '0';
            vidfifo_rden   <= (others=>'0');
            tx_first_en    <= '0';
            tx_last_en     <= '0'; 
            tx_push_en     <= '0';
            txdpram_posdec_en_xgmiitx <= '0';			  
                           
            if vsync_req  = '1' or vsync_neg_i = '1' then 
                pstate    <= IDLE_ST;
                vsync_ack <= '1';
            elsif mask_cnt(M_W) = '1'  then --wait a while for async fifo clear 
				if wait_txidle_cnt /= 0 then
					wait_txidle_cnt <= wait_txidle_cnt -1 ;
                elsif VSYNC_CNT_OVER = '0' then --to let vsync passed 
				
					frm_type       <= '0'&vidinfo_cmd((loop_cnt+1)*21-1);
					eth_index      <= conv_std_logic_vector(loop_cnt,4);
					color_depth    <= vidinfo_cmd(loop_cnt*21+10 downto loop_cnt*21+9);
					length_info    <= vidinfo_cmd(loop_cnt*21+19 downto loop_cnt*21+11);--for vsync  nonsense
					txcnt          <= vidinfo_cmd(loop_cnt*21+8 downto loop_cnt*21);	
					loop_cnt_lock  <= loop_cnt;

					if eth_mask_en(loop_cnt) = '1' then
						if rtcmdfifo_req = '1' and simul_eth_almost_full(rtcmd_eth_index_int)='0' and rtcmd_eth_index_int= loop_cnt then
							pstate         <= TXPARAM_ST;
							txcnt          <= rtcmd_length;
							rtcmdfifo_ack  <= '1';  
							tx_first_en    <= '1'; 
							push_source    <= '0';  
							flow_cmd_wren  <= '1';
							frm_type       <= "10";
							eth_index      <= conv_std_logic_vector(rtcmd_eth_index_int,4);
							length_info    <= rtcmd_length;----number of 64bit cycle
						end if;
						if vidinfo_req(loop_cnt)='1' then
							vidinfo_ack(loop_cnt) <= '1';
						end if;
                    elsif vidinfo_req(loop_cnt) = '1'  then --to let vsync passed 
						pstate         <= TXVID_ST;						
						vidinfo_ack(loop_cnt) <= '1';											
						tx_first_en    <= '1';
						push_source    <= '1';
						flow_cmd_wren  <= '1';						
                    else 
                        pstate <= IDLE_ST;
                    end if;
					
					if loop_cnt = real_eth_num_int-1 then
						loop_cnt <= 0 ;
					else
						loop_cnt <= loop_cnt+1;
					end if;
					
                else 
                    if rtcmdfifo_req = '1' and simul_eth_almost_full(rtcmd_eth_index_int)='0' then --cmd has high priority 
                        pstate         <= TXPARAM_ST;
                        txcnt          <= rtcmd_length;
                        rtcmdfifo_ack  <= '1';  
                        tx_first_en    <= '1'; 
                        push_source    <= '0';  
						flow_cmd_wren  <= '1';
						frm_type       <= "10";
						eth_index      <= conv_std_logic_vector(rtcmd_eth_index_int,4);
						length_info    <= rtcmd_length;----number of 64bit cycle
					else
					
						txcnt          <= vidinfo_cmd(ch_cnt*21+8 downto ch_cnt*21);
						color_depth    <= vidinfo_cmd(ch_cnt*21+10 downto ch_cnt*21+9);
						length_info    <= vidinfo_cmd(ch_cnt*21+19 downto ch_cnt*21+11);---pixel num 
						frm_type       <= '0'&vidinfo_cmd((ch_cnt+1)*21-1);
						loop_cnt_lock  <= ch_cnt;
						eth_index      <= conv_std_logic_vector(ch_cnt,4);
						
						if vid_req = '1' then
							vid_ack <= '1';
							vidinfo_ack(ch_cnt) <= '1'; 
							if eth_mask_en(ch_cnt) = '0' then
								pstate         <= TXVID_ST;
								tx_first_en    <= '1';
								push_source    <= '1';
								flow_cmd_wren  <= '1';
							else
								pstate         <= IDLE_ST;
								tx_first_en    <= '0';
								push_source    <= '0';
								flow_cmd_wren  <= '0';	
							end if;
						else
							pstate  <= IDLE_ST;
						end if;
												               
                    end if;
                end if;                 
                    
              else 
                   pstate <= IDLE_ST;             
              end if;
              
              
              txparam_raddr_buf <= rt_msb_addr&X"00"; ---
            
            when TXVID_ST =>             
                tx_vid_frm_en <= tx_first_en;            
                tx_first_en   <= '0';
                rtcmdfifo_ack <= '0';
				vid_ack       <= '0';
                vidinfo_ack   <= (others=>'0');
                vidfifo_rden(loop_cnt_lock)  <= '1';
				flow_cmd_wren <= '0';
                 tx_push_en    <= '1';
                 if vsync_req = '1' then --abort now 
                     vsync_ack <= '1';
                     tx_last_en <= '1';
                     pstate    <= IDLE_ST; --abort now ... 
                 elsif txcnt <= 1 then 
                    pstate <= IDLE_ST;
                    tx_last_en <= '0';
					wait_txidle_cnt <= "011";
                 else 
                    txcnt      <= txcnt - 1;
                    tx_last_en<= '0';
                end if;
				
            when TXPARAM_ST =>
                 tx_first_en   <= '0';
                 tx_push_en    <= '1';
                 rtcmdfifo_ack <= '0';
				flow_cmd_wren <= '0';
                vidinfo_ack   <= (others=>'0');               
                tx_last_en    <= '0'; 
				vidinfo_ack   <= (others=>'0');
                txparam_raddr_buf <= txparam_raddr_buf + 1;
                if txcnt  <= 1 then 
                    pstate <= IDLE_ST;
					wait_txidle_cnt <= "011";
					txdpram_posdec_en_xgmiitx <= '1';
                 else 
                    txcnt  <= txcnt - 1;
                end if;
            when others=>
                pstate <= IDLE_ST;         
        end case;
    end if;
  end process;
  
  process(nRST,clk_i)
  begin 
      if nRST = '0' then 
          dly_push_en    <= (others=>'0');
          dly_push_first <= (others=>'0');
          dly_push_last  <= (others=>'0');
          dly_push_src   <= (others=>'0');
      elsif rising_edge(clk_i) then 
          --dly_push_en    <= dly_push_en   (SEL_P-1 downto 0)&tx_push_en;
          --dly_push_first <= dly_push_first(SEL_P-1 downto 0)&tx_first_en;
          --dly_push_last  <= dly_push_last (SEL_P-1 downto 0)&tx_last_en;
          --dly_push_src   <= dly_push_src  (SEL_P-1 downto 0)&push_source;
		  dly_push_en(0)    <= tx_push_en;
		  dly_push_first(0) <= tx_first_en;
		  dly_push_last(0)  <= tx_last_en;
		  dly_push_src(0)   <= push_source;
		  
		  
      end if;
  end process;
  
  push_first_sel <=   dly_push_first(SEL_P) ;
  push_sel_en    <=   dly_push_en(SEL_P)    ;
  push_last_sel  <=   dly_push_last(SEL_P)  ;
  push_sel_src   <=   dly_push_src(SEL_P)   ;
  
  vidfifo_rdata_sel <= vidfifo_rdata((loop_cnt_lock+1)*72-1 downto loop_cnt_lock*72);
  cur_eth_num <= conv_integer(vidfifo_rdata_sel(23 downto 16)) when push_sel_src = '1' else conv_integer(txparam_rdata(23 downto 16)) ; 
  process(nRST,clk_i)
  begin 
    if nRST = '0' then 
        xgmii_txout_buf <= X"FF"&X"07070707"&X"07070707";
		eth_mask_en_d1 <= (others => '0');
		eth_mask_en_d2 <= (others => '0');
		eth_mask_en <= (others => '0');
    elsif rising_edge(clk_i) then 
	    eth_forbid_en_d1 <= eth_forbid_en_convclk;
		eth_forbid_en_d2 <= eth_forbid_en_d1;
		
		eth_mask_en_d1 <= eth_mask_en_convclk;
		eth_mask_en_d2 <= eth_mask_en_d1;
		eth_mask_en <= eth_mask_en_d2;
		
		xgmii_txout_buf_d1 <= xgmii_txout_buf;
		xgmii_txout_buf_d2 <= xgmii_txout_buf_d1;
		
        if  push_first_sel = '1' THEN
            xgmii_txout_buf <= X"01"&X"D55555555555"&check_sum&X"FB";
			eth_sign_en <= '1';
        ELSIF push_sel_en = '1' THEN 
            IF push_last_sel = '1' THEN --abort 
                xgmii_txout_buf <= X"FF"&X"07070707"&X"070707FD";
            elsif push_sel_src  = '1' THEN 
                xgmii_txout_buf <= vidfifo_rdata_sel(71 downto 0);
				eth_sign_en <= '0';
				if eth_sign_en = '1' then
					eth_forbid_en <= eth_forbid_en_d2(cur_eth_num);
				end if;
					
            else 
                xgmii_txout_buf <= txparam_rdata(71 downto 0);
				eth_sign_en <= '0';
				if eth_sign_en = '1' then
					eth_forbid_en <= eth_forbid_en_d2(cur_eth_num);
				end if;
            end if;
        else 
            xgmii_txout_buf <= X"FF"&X"07070707"&X"07070707";
        end if; 

        if eth_forbid_en = '1' then
			xgmii_txout_d1 <= X"FF"&X"07070707"&X"07070707";
		else
			xgmii_txout_d1 <= xgmii_txout_buf_d2;
		end if;
		
		if  xgmii_txout_buf(71 downto 64) = X"01" then
            check_sum_buf       <= (others => '0');                          
        elsif xgmii_txout_buf(71 downto 64) /= X"FF" then 
            check_sum_buf   <= check_sum_buf + xgmii_txout_buf(63 downto 0);
        end if;
		
		flow_cmd_wren_buf <= flow_cmd_wren_buf(1 downto 0)&flow_cmd_wren;
		flow_cmd_data_buf <= flow_cmd_data_buf(2*15-1 downto 0)&flow_cmd_data;
		
    end if;
  end process;
xgmii_txout <= xgmii_txout_d1;

--==============debug=====================
u0 : component issp
		port map (
			source => issp_source, -- sources.source
			probe  => issp_probe   --  probes.probe
		);
		
xgmii_ctrl <= xgmii_txout_d1(71 downto 64);  
xgmii_data <= xgmii_txout_d1(63 downto 0);
process(nRST,clk_i)
begin 
	if nRST = '0' then 
		debug_pstate <= debug_idle;
		cnt <= (others => '0');
		eth_num_buf <= (others => '0');
		frm_1A_en 		<= (others => '0');
		frm_1A_01_en 	<= (others => '0');
		frm_1A_03_en 	<= (others => '0');
		frm_1A_05_en 	<= (others => '0');
		frm_1A_08_en 	<= (others => '0');
	elsif rising_edge(clk_i) then 			
		case (debug_pstate) is 
			when debug_idle => 
				if xgmii_ctrl = X"01" and xgmii_data(7 downto 0) = X"FB" then
					debug_pstate <= debug_data;
				else
					debug_pstate <= debug_idle;
				end if;
				cnt <= (others => '0');
			when debug_data => 
				if xgmii_ctrl /= X"00" then
					debug_pstate <= debug_idle;
				else
					debug_pstate <= debug_data;
				end if;
				
				if xgmii_ctrl = X"00" then
					cnt <= cnt + '1' ;
				end if;
				
				if cnt = 0 then
					eth_num_buf <= xgmii_data(23 downto 16);
					frame_type <= xgmii_data(39 downto 32);
				elsif cnt = 1 then	
					subfrm_type <= xgmii_data(15 downto 8);
				elsif cnt = 2 then
					if frame_type = X"1A" then
						frm_1A_en(conv_integer(eth_num_buf)) <= '1';
					else
						frm_1A_en(conv_integer(eth_num_buf)) <= '0';
					end if;
					if frame_type = X"1A" and subfrm_type = X"01" then
						frm_1A_01_en(conv_integer(eth_num_buf)) <= '1';
					else
						frm_1A_01_en(conv_integer(eth_num_buf)) <= '0';
					end if;					
					if frame_type = X"1A" and subfrm_type = X"03" then
						frm_1A_03_en(conv_integer(eth_num_buf)) <= '1';
					else
						frm_1A_03_en(conv_integer(eth_num_buf)) <= '0';
					end if;
					if frame_type = X"1A" and subfrm_type = X"05" then
						frm_1A_05_en(conv_integer(eth_num_buf)) <= '1';
					else
						frm_1A_05_en(conv_integer(eth_num_buf)) <= '0';
					end if;
					if frame_type = X"1A" and subfrm_type = X"08" then
						frm_1A_08_en(conv_integer(eth_num_buf)) <= '1';
					else
						frm_1A_08_en(conv_integer(eth_num_buf)) <= '0';
					end if;
				end if;
			
			when others => debug_pstate <= debug_idle;
		end case;			
	end if;
end process; 

process(nRST,clk_i)
begin 
	if nRST = '0' then 
		inint_en <= '1';
		time_us_en <= '0';
		time_ms_en <= '0';
		time_us_cnt <= (others => '0');
		time_ms_cnt <= (others => '0');
		clr_flg <= '0';
		frm_1A_en_cnt <= (others => '0');
		frm_1A_cnt_min <= (others => '0');
		frm_1A_time_us_cnt <= (others => '0');
		frm_1A_time_us_cnt_min <= (others => '1');
		frm_1A_01_en_cnt <= (others => '0');
		frm_1A_01_cnt_min <= (others => '0');
		frm_1A_01_time_us_cnt <= (others => '0');
		frm_1A_01_time_us_cnt_min <= (others => '1');
		frm_1A_03_en_cnt <= (others => '0');
		frm_1A_03_cnt_min <= (others => '0');
		frm_1A_03_time_us_cnt <= (others => '0');
		frm_1A_03_time_us_cnt_min <= (others => '1');
		frm_1A_05_en_cnt <= (others => '0');
		frm_1A_05_cnt_min <= (others => '0');
		frm_1A_05_time_us_cnt <= (others => '0');
		frm_1A_05_time_us_cnt_min <= (others => '1');
		frm_1A_08_en_cnt <= (others => '0');
		frm_1A_08_cnt_min <= (others => '0');
		frm_1A_08_time_us_cnt <= (others => '0');
		frm_1A_08_time_us_cnt_min <= (others => '1');
	elsif rising_edge(clk_i) then
		if time_us_cnt = 156 then--156.25M
			time_us_en <= '1';
			time_us_cnt <= (others => '0');
		else
			time_us_en <= '0';
			time_us_cnt <= time_us_cnt + '1';
		end if;		
		if time_ms_cnt = 156250 then--156.25M
			time_ms_en <= '1';
			time_ms_cnt <= (others => '0');
		else
			time_ms_en <= '0';
			time_ms_cnt <= time_ms_cnt + '1';
		end if;
		
		issp_source0_d1 <= issp_source(0);
		issp_source0_d2 <= issp_source0_d1;
		if issp_source0_d1 = '1' and issp_source0_d2 = '0' then
			clr_flg <= '1';
		else
			clr_flg <= '0';
		end if;
		
		for i in 0 to ETH_NUM-1 loop
			frm_1A_en_d1(i)	<= frm_1A_en(i);
			frm_1A_01_en_d1(i)	<= frm_1A_01_en(i);
			frm_1A_03_en_d1(i)	<= frm_1A_03_en(i);
			frm_1A_05_en_d1(i)	<= frm_1A_05_en(i);
			frm_1A_05_en_d1(i)	<= frm_1A_05_en(i);			
			
			--1A frame
			if clr_flg = '1' then 
				frm_1A_en_cnt <= (others => '0');
				frm_1A_cnt_min <= (others => '0');
				frm_1A_time_us_cnt <= (others => '0');
				frm_1A_time_us_cnt_min <= (others => '1');
			elsif frm_1A_en(i) = '1' and frm_1A_en_d1(i) = '0' then
				frm_1A_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				if frm_1A_time_us_cnt((i+1)*11-1 downto i*11) < frm_1A_time_us_cnt_min((i+1)*11-1 downto i*11) then
					frm_1A_time_us_cnt_min((i+1)*11-1 downto i*11) <= frm_1A_time_us_cnt((i+1)*11-1 downto i*11);
					frm_1A_cnt_min((i+1)*32-1 downto i*32) <= frm_1A_en_cnt((i+1)*32-1 downto i*32);
				end if;
				frm_1A_en_cnt((i+1)*32-1 downto i*32) <= frm_1A_en_cnt((i+1)*32-1 downto i*32);
			elsif time_us_en = '1' and frm_1A_time_us_cnt((i+1)*11-1) = '0' then
				frm_1A_time_us_cnt((i+1)*11-1 downto i*11) <= frm_1A_time_us_cnt((i+1)*11-1 downto i*11) + '1';
			end if;
			
			--1A 01 frame
			if clr_flg = '1' then 
				frm_1A_01_en_cnt <= (others => '0');
				frm_1A_01_cnt_min <= (others => '0');
				frm_1A_01_time_us_cnt <= (others => '0');
				frm_1A_01_time_us_cnt_min <= (others => '1');
			elsif frm_1A_01_en(i) = '1' and frm_1A_01_en_d1(i) = '0' then
				frm_1A_01_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				if frm_1A_01_time_us_cnt((i+1)*11-1 downto i*11) < frm_1A_01_time_us_cnt_min((i+1)*11-1 downto i*11) then
					frm_1A_01_time_us_cnt_min((i+1)*11-1 downto i*11) <= frm_1A_01_time_us_cnt((i+1)*11-1 downto i*11);
					frm_1A_01_cnt_min((i+1)*32-1 downto i*32) <= frm_1A_01_en_cnt((i+1)*32-1 downto i*32);
				end if;
				frm_1A_01_en_cnt((i+1)*32-1 downto i*32) <= frm_1A_01_en_cnt((i+1)*32-1 downto i*32);
			elsif time_us_en = '1' and frm_1A_01_time_us_cnt((i+1)*11-1) = '0' then
				frm_1A_01_time_us_cnt((i+1)*11-1 downto i*11) <= frm_1A_01_time_us_cnt((i+1)*11-1 downto i*11) + '1';
			end if;
			--1A 03 frame
			if clr_flg = '1' then 
				frm_1A_03_en_cnt((i+1)*32-1 downto i*32) <= (others => '0');
				frm_1A_03_cnt_min((i+1)*32-1 downto i*32) <= (others => '0');
				frm_1A_03_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				frm_1A_03_time_us_cnt_min((i+1)*11-1 downto i*11) <= (others => '1');
			elsif frm_1A_03_en(i) = '1' and frm_1A_03_en_d1(i) = '0' then
				frm_1A_03_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				if frm_1A_03_time_us_cnt((i+1)*11-1 downto i*11) < frm_1A_03_time_us_cnt_min((i+1)*11-1 downto i*11) then
					frm_1A_03_time_us_cnt_min((i+1)*11-1 downto i*11) <= frm_1A_03_time_us_cnt((i+1)*11-1 downto i*11);
					frm_1A_03_cnt_min((i+1)*32-1 downto i*32) <= frm_1A_03_en_cnt((i+1)*32-1 downto i*32);
				end if;
				frm_1A_03_en_cnt((i+1)*32-1 downto i*32) <= frm_1A_03_en_cnt((i+1)*32-1 downto i*32);
			elsif time_us_en = '1' and frm_1A_03_time_us_cnt((i+1)*11-1) = '0' then
				frm_1A_03_time_us_cnt((i+1)*11-1 downto i*11) <= frm_1A_03_time_us_cnt((i+1)*11-1 downto i*11) + '1';
			end if;
			--1A 05 frame
			if clr_flg = '1' then 
				frm_1A_05_en_cnt((i+1)*32-1 downto i*32) <= (others => '0');
				frm_1A_05_cnt_min((i+1)*32-1 downto i*32) <= (others => '0');
				frm_1A_05_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				frm_1A_05_time_us_cnt_min((i+1)*11-1 downto i*11) <= (others => '1');
			elsif frm_1A_05_en(i) = '1' and frm_1A_05_en_d1(i) = '0' then
				frm_1A_05_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				if frm_1A_05_time_us_cnt((i+1)*11-1 downto i*11) < frm_1A_05_time_us_cnt_min((i+1)*11-1 downto i*11) then
					frm_1A_05_time_us_cnt_min((i+1)*11-1 downto i*11) <= frm_1A_05_time_us_cnt((i+1)*11-1 downto i*11);
					frm_1A_05_cnt_min((i+1)*32-1 downto i*32) <= frm_1A_05_en_cnt((i+1)*32-1 downto i*32);
				end if;
				frm_1A_05_en_cnt((i+1)*32-1 downto i*32) <= frm_1A_05_en_cnt((i+1)*32-1 downto i*32);
			elsif time_us_en = '1' and frm_1A_05_time_us_cnt((i+1)*11-1) = '0' then
				frm_1A_05_time_us_cnt((i+1)*11-1 downto i*11) <= frm_1A_05_time_us_cnt((i+1)*11-1 downto i*11) + '1';
			end if;
			--1A 08 frame
			if clr_flg = '1' then 
				frm_1A_08_en_cnt((i+1)*32-1 downto i*32) <= (others => '0');
				frm_1A_08_cnt_min((i+1)*32-1 downto i*32) <= (others => '0');
				frm_1A_08_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				frm_1A_08_time_us_cnt_min((i+1)*11-1 downto i*11) <= (others => '1');
			elsif frm_1A_08_en(i) = '1' and frm_1A_08_en_d1(i) = '0' then
				frm_1A_08_time_us_cnt((i+1)*11-1 downto i*11) <= (others => '0');
				if frm_1A_08_time_us_cnt((i+1)*11-1 downto i*11) < frm_1A_08_time_us_cnt_min((i+1)*11-1 downto i*11) then
					frm_1A_08_time_us_cnt_min((i+1)*11-1 downto i*11) <= frm_1A_08_time_us_cnt((i+1)*11-1 downto i*11);
					frm_1A_08_cnt_min((i+1)*32-1 downto i*32) <= frm_1A_08_en_cnt((i+1)*32-1 downto i*32);
				end if;
				frm_1A_08_en_cnt((i+1)*32-1 downto i*32) <= frm_1A_08_en_cnt((i+1)*32-1 downto i*32);
			elsif time_us_en = '1' and frm_1A_08_time_us_cnt((i+1)*11-1) = '0' then
				frm_1A_08_time_us_cnt((i+1)*11-1 downto i*11) <= frm_1A_08_time_us_cnt((i+1)*11-1 downto i*11) + '1';
			end if;		
		end loop; 
	end if;
end process;
--========================================
  
eth_flow_ctrl: simul_eth_timing 
generic map(
	VID_NUM_IN_SLOT						=> ETH_NUM

)
port map(
	nRST								=> nRST,
	sysclk								=> clk_i,
    color_depth							=> color_depth,
                                       
    output_eth_type						=> output_eth_type,
	                                   
    vidout_vsync_neg                    => vsync_neg_i,
    pack_cmd_wren                       => flow_cmd_wren_buf(2),
    pack_cmd_data                       => flow_cmd_data_buf(3*15-1 downto 2*15),
    ch_vld                              => (others=>'1'),
    ch_sel                              => ch_sel,
                                       
	vidinfo_req                         =>   vidinfo_req,                               
	simul_eth_almost_empty_en           => simul_eth_almost_empty_en , 
	simul_eth_empty_en                  => simul_eth_empty_en        , 
	                                                                
	simul_eth_almost_full_o             => simul_eth_almost_full   , 
	simul_eth_almost_empty_o            => simul_eth_almost_empty  , 
	simul_eth_empty_o                   => simul_eth_empty        , 
	packet_gap_5g                       => packet_gap_5g
    
);
  
output_eth_type <= "100" when real_eth_num = 4
              else "000";
                
  
  
check_sum <= check_sum_buf(8*8-1 downto 8*7) +
             check_sum_buf(8*7-1 downto 8*6) +
             check_sum_buf(8*6-1 downto 8*5) +
             check_sum_buf(8*5-1 downto 8*4) +
             check_sum_buf(8*4-1 downto 8*3) +
             check_sum_buf(8*3-1 downto 8*2) +
             check_sum_buf(8*2-1 downto 8*1) +
             check_sum_buf(8*1-1 downto 8*0) ; 

end beha;