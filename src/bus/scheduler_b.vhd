--#######################################################################
--
--  REVISION HISTORY:
--
--  Revision 0.1  2017/04/26  Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--
--  interface with DDR3 and video input and output
---
--   interface to DDR3 controller
--      1) write videoinput data into ddr3
--      2) fetch data for serdes
---   no reset at all ;;

--   if async mode is used, we must make sure the data fifos and DATA dpram are not overflowing ...
---      for cmd fifo and data fifo is read/write async
--       if async_mode is used, preusedw should be used ....

--    note : we must maker sure the picture width is larger than 16 pixels , (span 2 bursts) for writing
--           otherwise , the following logic may behavior badly, if so, we can use the pure MASK dpram here ...
--           for  the start and end position are overlapped together
--           if so, we need to handle it ......
--    wrd_rmask[6] : '0' start,  '1': end
--    wrd_rmask[5:0] : byoffset in the 32bytes
--            for start (bit6=0),
--                         0 , all bytes are enabled,
--                         1: LSB first byte are masked out ,
--                        31: LSB lsb byte is left unmasked
--                        32: all byte are masked out
--            for end  (bit6=1) ,  0,  all bytes are maske out
--                         1: only first byte are enabled(not mask),
--                        31: only the MSB are masked out ...
--                        32: all bytes are enabled
--------
--  Copyright (C)   Beijing ColorLight Tech. Inc.
--
--#######################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;




entity scheduler_b is
generic
(
  DDRB_RSTALL_EN  :  std_logic := '0';
  READ_RST_ONLY   :   STD_LOGIC ;
  ASYNC_MODE      :  STD_LOGIC := '0'; --DDR3 IS async mode or not , '1': async ,'0: sync
  READ_HIGH_PRIO  :  STD_LOGIC := '0';
  WRC_W           : integer := 48; --WRite command FIFO width
  RRC_W           : integer := 48 ;  --READ command  FIFO width  ;
  DDRA_W          : INTEGER := 26 ;
  DDRD_W          : INTEGER := 320;
  BURST_W         : INTEGER := 7;
  RD_TWO_BURST_SUPPROT: STD_LOGIC :='0'  ---NOT SUPPROTED YET
);
port
(
   ddrb_vsync_neg_ddr : in std_logic ;  --20171103 wangac
   op_ddr_dur_SYS     : in std_logic ;  --20171103 wangac
   ------------------------------------------
   
      ---for ddr3 check
    sys_ddr_core_nrst  : in std_logic;
	ddr_verify_end     : out std_logic;
	ddr_verify_success : out std_logic;
	
    global_reset_n     : in std_logic; ---reset the ddr control & recalib 
    ddr3_pll_locked    : in std_logic;
    local_cal_success  : in  std_logic ; ----,   //           status.local_cal_success, When high, indicates that PHY calibration was successful
	local_cal_fail     : in  std_logic ; ----,      //                 .local_cal_fail,    When high, indicates that PHY calibration failed
	emif_usr_reset_n   : in  std_logic ; ----,    // emif_usr_reset_n.reset_n,           Reset for the user clock domain. Asynchronous assertion and synchronous deassertion
	emif_usr_clk       : in  std_logic ; ----,        //     emif_usr_clk.clk,               User clock domain
	amm_ready_0        : in  std_logic ; ---- '1' : ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
	amm_read_0         : out std_logic           ; ---- active high ,          //                 .read,              Read request signal
	amm_write_0        : out std_logic           ; ---- active high,         //                 .write,             Write request signal
	amm_address_0      : out  std_logic_vector(DDRA_W-1 downto 0); --[22:0]    ; ----   ,       //                 .address,           Address for the read/write request
	amm_readdata_0     : in   std_logic_vector(DDRD_W-1 downto 0); --[319:0]   ; ----   ,      //                 .readdata,          Read data
	amm_writedata_0    : out  std_logic_vector(DDRD_W-1 downto 0); -- [319:0]  ; ----   ,     //                 .writedata,         Write data
	amm_burstcount_0   : out  std_logic_vector(BURST_W-1 DOWNTO 0); -- [6:0]    ; ----       ,    //                 .burstcount,        Number of transfers in each read/write burst
	amm_byteenable_0   : out  std_logic_vector((DDRD_W/8)-1 Downto 0); -- [39:0]   ; ----       ,    //                 .byteenable,        Byte-enable for write data
	amm_readdatavalid_0: in   std_logic       ; 
        --ddr3_init_done_i			: in  std_logic;  --from ddr3 control, pulse only 
    ddr3_init_done_level_o : out  std_logic := '0';  ---level output ------
	
	check_amm_readdatavalid_0 : in   std_logic       ;
	check_amm_readdata_0      : in   std_logic_vector(DDRD_W-1 downto 0);
   
   
   ---write queue interface 
   wrc_cmdfifo_empty    : in    std_logic ;
   wrc_cmdfifo_rden     : out   std_logic :='0';
   wrc_cmdfifo_q        : in    std_logic_vector(WRC_W-1 downto 0);

   wrd_raddr            : out   std_logic_vector(8 downto 0);
   wrd_rdata            : in    std_logic_vector(DDRD_W-1 downto 0);
   wrd_rden_o           : out   std_logic ;
   wrd_raddr_stall      : out   std_logic ; --rdaddr stall
   wrd_rdoutclk_en      : out   std_logic ; --q out clk en
   wrd_rdinclk_en       : out   std_logic ; --rdclken
   wrd_byteen            : in    std_logic_vector((DDRD_W/8)-1 downto 0);  --mask fifo (, bit6: start or last, others , offset)
   ---wrd_rden             : out   std_logic :='0';

   --read queue interface
   rrc_cmdfifo_empty  : in    std_logic  ; --at most
   rrc_cmdfifo_rdusedw: in    std_logic_vector(4 downto 0);
   rrc_cmdfifo_rden   : out   std_logic :='0';
   rrc_cmdfifo_q      : in    std_logic_vector(RRC_W-1 downto 0);

   rrd_wdata          : out   std_logic_vector(DDRD_W-1 downto 0);
   rrd_wren           : out   std_logic := '0';
   rrd_wrusedw        : in    std_logic_vector(12 downto 0) ;

   bad_read_flag      : out std_logic ;
   bad_write_flag     : out std_logic
);
end scheduler_b ;


architecture beha of scheduler_b is
constant DDR3_CMD_READ				: std_logic_vector(3 downto 0) := "0001";
constant DDR3_CMD_WRITE				: std_logic_vector(3 downto 0) := "0010";

SIGNAL rrd_wfifo_is_enough : STD_LOGIC := '0';

type mainstate_def is (ddr3_init, main_idle,ddr3_wait_ack ,wait_ddr3_read, wait_ddr3_write);
signal pstate : mainstate_def := ddr3_init ;

---initial ddr3 &
-- signal init_cnt         : std_logic_vector( 15 downto 0);
-- signal init_srvcd       : std_logic ;
-- signal init_start_hit   : std_logic ;
-- signal rst_srvcd        : std_logic ;
-- signal init_start_hit_1 : std_logic ;
-- signal mem_rst_n            : std_logic;
-- signal init_start           : std_logic;

-- signal ddr3_is_read      : std_logic := '0';
-- signal ddr3_init_done_d1 : std_logic := '0';
-----end

type wrsubstate_def is (WR_ST_DDR3INIT, WR_ST_IDLE   ,WR_ST_CMDWAIT,
                        WR_ST_WAITACK,WR_ST_WAITDONE ---, WR_ST_AGAIN
						, WR_ST_VSYNCA , WR_ST_PREFETCH2D
        );
signal wr_substate : wrsubstate_def := WR_ST_DDR3INIT ;

signal wr_req              : std_logic := '0';
signal wr_ack              : std_logic := '0';
signal wr_start_addr       : std_logic_vector(DDRA_W-1 downto 0) := (others=>'0');
signal wr_start_burstaddr  : std_logic_vector(DDRA_W-1 downto 0) := (others=>'0');
signal wr_burstlen         : std_logic_vector(BURST_W-1 downto 0) := (others=>'0');
-- signal wr_end_boff         : std_logic_vector(6 downto 0) := (others=>'0');
-- signal wr_start_boff       : std_logic_vector(6 downto 0) := (others=>'0');
signal wr_trans_dur        : std_logic := '0';
signal wr_trans_done       : std_logic ;
-- signal wr_is_2_burst       : std_logic := '0';

type RDsubstate_def is (RD_ST_DDR3INIT, RD_ST_IDLE   ,RD_ST_CMDWAIT,
                           RD_ST_WAITACK,RD_ST_WAITDONE, RD_ST_AGAIN
						   , RD_ST_VSYNCA
        );
signal rd_substate : RDsubstate_def := RD_ST_DDR3INIT ;


signal rd_req               : std_logic := '0';
signal rd_ack               : std_logic := '0';
signal rd_start_addr        : std_logic_vector(DDRA_W-1 downto 0) := (others=>'0');
signal rd_start_burstaddr   : std_logic_vector(DDRA_W-1 downto 0) := (others=>'0');
-- signal rd_end_burstaddr     : std_logic_vector(DDRA_W-1 downto 0) := (others=>'0');
signal rd_burstlen          : std_logic_vector(BURST_W-1 downto 0) := (others=>'0');
-- signal rd_end_boff          : std_logic_vector(6 downto 0) := (others=>'0');
-- signal rd_start_boff        : std_logic_vector(6 downto 0) := (others=>'0');
signal rd_trans_dur         : std_logic := '0';
signal rd_trans_done        : std_logic ;
-- signal rrc_cmdfifo_q_d1     : std_logic_vector(RRC_W-1   downto 0) := (others=>'0');
-- signal rd_first_burstlen    : std_logic_vector(BURST_W-1 downto 0);
-- signal rd_total_burstlen    : std_logic_vector(BURST_W-1 downto 0);
-- signal rd_endpart_burstaddr : std_logic_vector(7 downto 0);
-- signal rd_is_2burst_flag   : std_logic := '0';
signal rd_is_2_burst       : std_logic := '0';

signal ddr3_read_done    : std_logic ; --one transaction is done

signal ddr3_data_last      : std_logic := '0';
signal ddr3_256b_cnt       : std_logic_vector(BURST_W-1 downto 0) := (others=>'0'); --unit is 512bit (burst)
signal ddr3_256b_cnt_d1    : std_logic_vector(BURST_W-1 downto 0) := (others=>'0'); --unit is 512bit (burst)
signal ddr3_burst_len      : std_logic_vector(BURST_W-1 downto 0) := (others=>'0'); --unit is 512bit (burst)
-- signal ddr3_start_boff     : std_logic_vector(5 downto 0) := (others=>'0'); --unit is 512bit (burst)
-- signal ddr3_end_boff       : std_logic_vector(5 downto 0) := (others=>'0'); --unit is 512bit (burst)
signal ddr3_is_read        : std_logic := '0';
signal ddr3_write_done     : std_logic ; --one transaction is done

---signal pstate_is_idle    : std_logic ;  --indicate pstate is entering idle ...
signal ddr3_init_done_d1  : std_logic_vector(1 downto 0) := (others=>'0');
-- signal ddr3_init_done_sel : std_logic  := '0';
signal ddr3_init_done_level : std_logic  := '0';

-- signal ddr3_start_mask      : std_logic_vector(63 downto 0);
-- signal ddr3_end_mask        : std_logic_vector(63 downto 0);

-- signal ddr3_s0_mask         : std_logic_vector(31 downto 0);
-- signal ddr3_e0_mask         : std_logic_vector(31 downto 0);
-- signal ddr3_s1_mask         : std_logic_vector(31 downto 0);
-- signal ddr3_e1_mask         : std_logic_vector(31 downto 0);

signal  wr_wcnt  : std_logic_vector(8 downto 0) := (others=>'0');
signal  rd_wcnt  : std_logic_vector(8 downto 0) := (others=>'0');

-- signal wrd_async_mask_map : std_logic_vector(31 downto 0);
-- signal wrd_sync_data_mask : std_logic_vector(31 downto 0);
---signal wrd_async_mask_map : std_logic_vector(31 downto 0);

SIGNAL rrd_preusedw      : STD_LOGIC_VECTOR(10 DOWNTO 0):=(OTHERS=>'0');
SIGNAL rrd_suspend_burst : STD_LOGIC_VECTOR(10 DOWNTO 0):=(OTHERS=>'0');
signal rd_cmd_vld        : std_logic ;

signal frame_rst       : std_logic := '0';
signal frame_ack       : std_logic := '0';
signal op_ddr_dur_ddr  : std_logic_vector(3 downto 0):=(others=>'0');
attribute syn_keep : boolean;
attribute syn_srlstyle : string;
attribute syn_keep of op_ddr_dur_ddr : signal is true;


constant OP_MSB        : integer := 15 ;
signal op_timeout      : std_logic_vector(OP_MSB downto 0):=(others=>'0');
signal pstate_is_read  : std_logic := '0';
signal wrd_rden_buf    : std_logic := '0';
signal wrd_rdaddr_ddr3 : std_logic_vector(8 downto 0);

signal  reg_pll_locked         :    std_logic_vector(3 downto 0);
signal  reg_local_cal_succ     :    std_logic_vector(3 downto 0) ; ----,   //           status.local_cal_success, When high, indicates that PHY calibration was successful
signal	reg_local_cal_fail     :    std_logic_vector(3 downto 0) ; ----,      //
signal	wr_burstcnt            :    std_logic_vector(BURST_W-1 downto 0) ; ----,      //

signal ddr3_init_done_s    : std_logic ;
signal ddr3_nRST           : std_logic ;
signal ddr3_clk            : std_logic ;
signal ddr_write_0         : std_logic ;
signal ddr_read_0          : std_logic ;
signal wrd_prefetch_en     : std_logic ;
signal wrd_datafetch_en    : std_logic ;
SIGNAL ddr3_datain_rdy     : STD_LOGIC ;
SIGNAL ddr3_read_data_valid : STD_LOGIC;


signal clkcnt_1frame      : std_logic_vector(27 downto 0);
signal clkcnt_1frame_buf  : std_logic_vector(27 downto 0);
signal ddr_using          : std_logic;
signal ddr_using_cnt      : std_logic_vector(27 downto 0);
signal ddr_using_cnt_buf  : std_logic_vector(27 downto 0);
signal test               : std_logic;
signal ddr3_check_done    : std_logic ; 
signal amm_write_0_checker    : std_logic ; 
signal amm_read_0_checker : STD_LOGIC;      
signal amm_address_0_checker : std_logic_vector(DDRA_W-1 downto 0);
signal amm_address_0_buf : std_logic_vector(DDRA_W-1 downto 0);
signal amm_readdata_0_checker : std_logic_vector(DDRD_W-1 downto 0);
signal amm_writedata_0_checker : std_logic_vector(DDRD_W-1 downto 0);
signal amm_burstcount_0_checker   : std_logic_vector(BURST_W-1 downto 0);
signal amm_burstcount_0_buf   : std_logic_vector(6 downto 0);
signal amm_byteenable_0_checker   : std_logic_vector((DDRD_W/8)-1 downto 0);
type checker_def is (ddr_verify_b,ddr_verify_wr, ddr_verify_rd   ,ddr_verify_a
        );
signal pstate_check : checker_def := ddr_verify_b ;
signal ddr_wr_vld_pre : std_logic:='0';
signal burst_cnt						: std_logic_vector(BURST_W-1 downto 0);
signal verify_data_buf					: std_logic_vector(7 downto 0);
signal verify_data_error_buf			: std_logic_vector(DDRD_W/8-1 downto 0);
signal verify_data_error				: std_logic;

--ddr init
signal ddr_verify_nrst_buf				: std_logic_vector(3 downto 0);
signal ddr_verify_nrst					: std_logic;
signal local_cal_success_flag			: std_logic;
signal local_cal_fail_flag				: std_logic;
signal pll_locked_buf					: std_logic_vector(5 downto 0);
signal local_cal_success_buf			: std_logic_vector(5 downto 0);
signal local_cal_fail_buf				: std_logic_vector(5 downto 0);
signal pll_locked_flag					: std_logic;

signal	step_error					:	std_logic_vector(4 downto 0);
 component altera_std_synchronizer is  
  port   
     (
				    clk : in std_logic ;
				reset_n : in std_logic ; 
				din     : in std_logic ;
				dout    : out std_logic
				);  
 end component; 
 
component ddr3_check is
generic
(
  DDRB_RSTALL_EN  :  std_logic := '0';
  READ_RST_ONLY   :   STD_LOGIC ;
  ASYNC_MODE      :  STD_LOGIC := '0'; --DDR3 IS async mode or not , '1': async ,'0: sync
  READ_HIGH_PRIO  :  STD_LOGIC := '0';
  WRC_W           : integer := 48; --WRite command FIFO width
  RRC_W           : integer := 48 ;  --READ command  FIFO width  ;
  DDRA_W          : INTEGER := 23 ;
  DDRD_W          : INTEGER := 320;
  BURST_W         : INTEGER := 7;
  RD_TWO_BURST_SUPPROT: STD_LOGIC :='0'  ---NOT SUPPROTED YET
);
port
(
	ddr3_nRST		: in		std_logic;
	ddr3_clk		: in		std_logic;
	
	local_cal_success_flag		: in	std_logic;
	pll_locked_flag				: in	std_logic;
	ddr_verify_nrst				: in	std_logic;
	
	ddr3_pll_locked				: in	std_logic;
    local_cal_success			: in	std_logic; ----,   //           status.local_cal_success, When high, indicates that PHY calibration was successful
    local_cal_fail				: in	std_logic; ----,      //                 .local_cal_fail,    When high, indicates that PHY calibration failed
    amm_ready_0					: in	std_logic; ---- '1' : ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
    amm_read_0_checker			: out	std_logic; ---- active high ,          //                 .read,              Read request signal
    amm_write_0_checker			: out	std_logic; ---- active high,         //                 .write,             Write request signal
    amm_address_0_checker		: out	std_logic_vector(DDRA_W-1 downto 0); --[22:0]    ; ----   ,       //                 .address,           Address for the read/write request
    check_amm_readdata_0		: in	std_logic_vector(DDRD_W-1 downto 0); --[319:0]   ; ----   ,      //                 .readdata,          Read data
    amm_writedata_0_checker		: out	std_logic_vector(DDRD_W-1 downto 0); -- [319:0]  ; ----   ,     //                 .writedata,         Write data
    amm_burstcount_0_checker	: out	std_logic_vector(BURST_W-1 DOWNTO 0); -- [6:0]    ; ----       ,    //                 .burstcount,        Number of transfers in each read/write burst
    amm_byteenable_0_checker	: out	std_logic_vector((DDRD_W/8)-1 Downto 0); -- [39:0]   ; ----       ,    //                 .byteenable,        Byte-enable for write data
    check_amm_readdatavalid_0	: in	std_logic;
	
	ddr_verify_end				: out	std_logic;
	ddr_verify_success			: out	std_logic;
	ddr3_check_done				: out	std_logic;
	verify_data_error_buf		: out	std_logic_vector(DDRD_W/8-1 downto 0);
	verify_data_error			: out	std_logic;
	step_error					: out	std_logic_vector(4 downto 0)
);

end component;


begin

 ddr3_nRST <= emif_usr_reset_n ;
 ddr3_clk  <= emif_usr_clk     ;

process(ddr3_clk,ddr3_nRST)
begin
if ddr3_nRST = '0' then
    clkcnt_1frame <= (others => '0');
    clkcnt_1frame_buf <= (others => '0');
    ddr_using_cnt <= (others => '0');
    ddr_using_cnt_buf <= (others => '0');
    ddr_using <= '0';
    test <= '0';
elsif rising_edge(ddr3_clk) then
    if ddrb_vsync_neg_ddr = '1' then
        clkcnt_1frame_buf <= (others => '0');
        clkcnt_1frame <= clkcnt_1frame_buf;
    else
        clkcnt_1frame_buf <= clkcnt_1frame_buf + '1';
    end if;
    if (amm_ready_0 = '1' and ddr_write_0 = '1') or amm_readdatavalid_0 = '1' then
        ddr_using <= '1';
    else
        ddr_using <= '0';
    end if;
    if ddrb_vsync_neg_ddr = '1' then
        ddr_using_cnt_buf <= (others => '0');
        ddr_using_cnt <= ddr_using_cnt_buf;
    elsif ddr_using = '1' then
        ddr_using_cnt_buf <= ddr_using_cnt_buf + '1';
    end if;
    if clkcnt_1frame = X"FFFFFFF" and ddr_using_cnt = X"FFFFFFF" then
        test <= '1';
    else
        test <= '0';
    end if;
end if;
end process;


  --------------------------ddr3 checker---------------
-- process(ddr3_nRST,ddr3_clk)
-- begin
	-- if ddr3_nRST = '0' then
		-- pstate_check <= ddr_verify_b;
		-- ddr_verify_end <= '0';
		-- ddr_verify_success <= '0';
        -- ddr3_check_done <= '0';
		-- amm_writedata_0_checker <=(others=>'0');
        -- amm_write_0_checker <= '0';
		-- amm_read_0_checker <='0';
        -- amm_address_0_checker <=(others=>'0');
		-- amm_burstcount_0_checker <=(others=>'0');
        -- amm_byteenable_0_checker <=(others=>'0');
		-- verify_data_error_buf <= (others => '0');
		-- verify_data_error <= '0';
		-- burst_cnt <= (others => '0');
		-- ddr_wr_vld_pre <= '1';
	-- elsif rising_edge(ddr3_clk)then
		-- if (ddr_wr_vld_pre = '1' ) or (amm_ready_0 = '1') then
			-- for i in 0 to DDRD_W/8-1 loop
				-- amm_writedata_0_checker(i*8+7 downto i*8) <= conv_std_logic_vector(0,8-BURST_W)&burst_cnt;
			-- end loop;
		-- else
			-- for i in 0 to DDRD_W/8-1 loop
				-- amm_writedata_0_checker(i*8+7 downto i*8) <= verify_data_buf;
			-- end loop;
		-- end if;
		-- amm_byteenable_0_checker <= (others => '1');
		
		-- if ddr_verify_nrst = '0' then
			-- verify_data_error_buf <= (others => '0');
		-- else
			-- if check_amm_readdatavalid_0 = '1' then
				-- for i in 0 to DDRD_W/8-1 loop
					-- if check_amm_readdata_0(i*8+7 downto i*8) = conv_std_logic_vector(0,8-BURST_W)&burst_cnt then
						-- verify_data_error_buf(i) <= '0';
					-- else
						-- verify_data_error_buf(i) <= '1';
					-- end if;
				-- end loop;
			-- end if;		
		-- end if;
		
		-- if ddr_verify_nrst = '0' then
			-- pstate_check <= ddr_verify_b;
			-- ddr_verify_end <= '0';
			-- ddr_verify_success <= '0';
			-- verify_data_error <= '0';
			-- ddr3_check_done <= '0';
			-- amm_write_0_checker <= '0';
		    -- amm_read_0_checker <='0';
            -- amm_address_0_checker <=(others=>'0');
			-- burst_cnt <= (others => '0');
			-- ddr_wr_vld_pre <= '1';
		-- else
			-- case pstate_check is 
				-- when ddr_verify_b =>
					-- if  local_cal_success_flag = '1' and pll_locked_flag = '1' then
								
						-- pstate_check <= ddr_verify_wr;
						-- amm_write_0_checker <= '1';
						-- burst_cnt <= burst_cnt + '1';	
						-- ddr_wr_vld_pre <= '0';						
					-- else

						-- pstate_check <= ddr_verify_b;
						-- amm_write_0_checker <= '0';
						-- burst_cnt <= (others => '0');
						-- ddr_wr_vld_pre <= '1';

					-- end if;

					-- amm_read_0_checker <='0';
					-- amm_burstcount_0_checker <= conv_std_logic_vector(64,BURST_W);
					-- verify_data_buf <= conv_std_logic_vector(0,8-BURST_W)&burst_cnt;
					-- ddr_verify_end <= '0';
					-- ddr_verify_success <= '0';
					-- ddr3_check_done <= '0';
				
				-- when ddr_verify_wr =>
					-- if burst_cnt(BURST_W-1) = '1' and amm_ready_0 = '1' then
						-- pstate_check <= ddr_verify_rd;
						-- burst_cnt <= (others => '0');
							
						-- amm_write_0_checker <= '0';
						-- amm_read_0_checker <= '1';
					-- else
						-- pstate_check <= ddr_verify_wr;
						-- if amm_ready_0 = '1' then
							-- burst_cnt <= burst_cnt + '1';
						-- end if;
							
						-- amm_write_0_checker <= '1';
						-- amm_read_0_checker <= '0';
					-- end if;
						
					-- if amm_ready_0 = '1' then
						-- verify_data_buf <= conv_std_logic_vector(0,8-BURST_W)&burst_cnt;
					-- end if;
					
				-- when ddr_verify_rd =>
						-- if burst_cnt(BURST_W-1) = '1' then
							-- pstate_check <= ddr_verify_a;
							-- burst_cnt <= (others => '0');
							
							-- amm_read_0_checker <= '0';
						-- else
							-- pstate_check <= ddr_verify_rd;
							-- if check_amm_readdatavalid_0 = '1' then
								-- burst_cnt <= burst_cnt + '1';
							-- end if;
							
							-- if amm_ready_0 = '1' then
								-- amm_read_0_checker <= '0';
							-- end if;
						-- end if;
						
						-- if verify_data_error_buf > 0 then
							-- verify_data_error <= '1';
						-- end if;
	
						
				-- when ddr_verify_a =>

						-- pstate_check <= ddr_verify_a;

						-- ddr_verify_end <= '1';
						-- ddr_verify_success <= not verify_data_error;
						-- ddr3_check_done <= not verify_data_error;					
				-- when others =>	pstate_check <= ddr_verify_a;
			-- end case;
		-- end if;
	-- end if;
-- end process;
 

ddr3_check_inst : ddr3_check 
generic map
(
  DDRB_RSTALL_EN  		=> DDRB_RSTALL_EN,
  READ_RST_ONLY   		=> READ_RST_ONLY,
  ASYNC_MODE      		=> ASYNC_MODE,
  READ_HIGH_PRIO  		=> READ_HIGH_PRIO,
  WRC_W           		=> WRC_W,
  RRC_W           		=> RRC_W,
  DDRA_W          		=> DDRA_W,
  DDRD_W          		=> DDRD_W,
  BURST_W         		=> BURST_W,
  RD_TWO_BURST_SUPPROT	=> RD_TWO_BURST_SUPPROT
)
port map
(
	ddr3_nRST					=> ddr3_nRST,
	ddr3_clk					=> ddr3_clk,

	local_cal_success_flag		=> local_cal_success_flag,
	pll_locked_flag				=> pll_locked_flag,
	ddr_verify_nrst				=> ddr_verify_nrst,

	ddr3_pll_locked				=> ddr3_pll_locked,
    local_cal_success			=> local_cal_success,
    local_cal_fail				=> local_cal_fail,
    amm_ready_0					=> amm_ready_0,
    amm_read_0_checker			=> amm_read_0_checker,
    amm_write_0_checker			=> amm_write_0_checker,
    amm_address_0_checker		=> amm_address_0_checker,
    check_amm_readdata_0		=> check_amm_readdata_0,
    amm_writedata_0_checker		=> amm_writedata_0_checker,
    amm_burstcount_0_checker	=> amm_burstcount_0_checker,
    amm_byteenable_0_checker	=> amm_byteenable_0_checker,
    check_amm_readdatavalid_0	=> check_amm_readdatavalid_0,

	ddr_verify_end				=> ddr_verify_end			,
	ddr_verify_success			=> ddr_verify_success		,
	ddr3_check_done				=> ddr3_check_done			,
	verify_data_error_buf		=> verify_data_error_buf	,
	verify_data_error			=> verify_data_error		,
	step_error					=> step_error				

);




----------------------------ddr3 checker---------------
  verify_r_i: altera_std_synchronizer    
     port   map
     (
				    clk  => ddr3_clk,
				reset_n  => ddr3_nRST,
				din      => sys_ddr_core_nrst,
				dout     => ddr_verify_nrst_buf(2)
				);  
  ls_r_i: altera_std_synchronizer    
     port   map
     (
				    clk  => ddr3_clk,
				reset_n  => ddr3_nRST,
				din      => local_cal_success,
				dout     => local_cal_success_buf(2)
				);  
      lf_r_i: altera_std_synchronizer    
     port   map
     (
				    clk  => ddr3_clk,
				reset_n  => ddr3_nRST,
				din      => local_cal_fail,
				dout     => local_cal_fail_buf(2 )
				);  
    lp_r_i: altera_std_synchronizer    
     port   map
     (
				    clk  => ddr3_clk,
				reset_n  => ddr3_nRST,
				din      => ddr3_pll_locked,
				dout     =>pll_locked_buf(2)
				);             
 process(ddr3_nRST,ddr3_clk)  --DDR3 User Interface sclk
begin
    if (ddr3_nRST = '0') then
         pll_locked_buf(5 downto 3)     <= (others=>'0');
         local_cal_success_buf(5 downto 3) <= (others=>'0');
         local_cal_fail_buf(5 downto 3) <= (others=>'0');
    elsif rising_edge(ddr3_clk) then 
		pll_locked_buf(5 downto 3) <= pll_locked_buf(4 downto 2);--- downto 0)&ddr3_pll_locked;
		local_cal_success_buf(5 downto 3) <= local_cal_success_buf(4 downto 2);---- downto 0)&local_cal_success;
		local_cal_fail_buf(5 downto 3) <= local_cal_fail_buf(4 downto 2);----downto 0)&local_cal_fail;
		 
	---	ddr_verify_nrst_buf <= ddr_verify_nrst_buf(2 downto 0)&sys_ddr_core_nrst;
		ddr_verify_nrst <= ddr_verify_nrst_buf(2);
		
		if local_cal_success_buf(5 downto 3) = "111" then
			local_cal_success_flag <= '1';
		else
			local_cal_success_flag <= '0';
		end if;
		
		if pll_locked_buf(5 downto 3) = "111" then
			pll_locked_flag <= '1';
		else
			pll_locked_flag <= '0';
		end if;
    end if;
end process;


----initial ddr3 & ddr3 controller ----------------------------------------------



-- ddr3_init_done_sel <=  ddr3_init_done_d1(9);

process(ddr3_nRST,ddr3_clk)  --DDR3 User Interface sclk
begin
    if ddr3_nRST = '0' then
        ddr3_init_done_d1 <= (others=>'0');
        ddr3_init_done_level <= '0';
    elsif rising_edge(ddr3_clk) then
	    ddr3_init_done_level_o <= ddr3_init_done_level;
		ddr3_init_done_d1 <=ddr3_init_done_d1(0 downto 0)& ddr3_check_done ;
        -- ddr3_init_done_d1 <=ddr3_init_done_d1(0 downto 0)& ddr3_init_done_s ;
        if ddr3_init_done_d1(0) = '1' then
                ddr3_init_done_level <= '1';
        end if;

    end if;
end process;
-------------------------------------------------------------------------------------
process(ddr3_nRST,ddr3_clk)
begin
	if ddr3_nRST  = '0' then
			frame_rst <= '0';
			op_ddr_dur_ddr <= (others=>'0');
	elsif rising_edge(ddr3_clk) THEN
		op_ddr_dur_ddr <= op_ddr_dur_ddr(2 downto 0)& op_ddr_dur_sys;
		if ddrb_vsync_neg_ddr = '1' and op_ddr_dur_ddr(3) ='0' then
			frame_rst <= '1';
		elsif frame_ack = '1' then
			frame_rst <= '0';
		end if;
	end if;
end process;
-------------------------------------------------------------------------------------
   wrd_raddr        <= wrd_rdaddr_ddr3;
   ---wrd_rden_o       <= wrd_rden_buf ;
   wrd_rden_buf     <= wr_trans_dur and  (ddr_write_0 and amm_ready_0)  ; ---writing into ddr3
   --wrd_rden_buf     <= wrd_datafetch_en and  (ddr_write_0 and amm_ready_0)  ; ---writing into ddr3


   wrd_raddr_stall <= (not (wr_trans_dur and ddr_write_0 and amm_ready_0)) when wrd_prefetch_en ='0' else '0';
   wrd_rden_o      <= ((wr_trans_dur and ddr_write_0 and amm_ready_0)) when wrd_prefetch_en ='0' else '1';
   wrd_rdinclk_en  <= '1';
   wrd_rdoutclk_en <= (wr_trans_dur and  (ddr_write_0 and amm_ready_0)) when wrd_prefetch_en ='0' else '1';

   amm_writedata_0  <= wrd_rdata  when ddr3_check_done='1' else  amm_writedata_0_checker;

   amm_byteenable_0 <= wrd_byteen  when ddr3_check_done='1' else amm_byteenable_0_checker;   
   amm_write_0      <= ddr_write_0 when ddr3_check_done='1' else amm_write_0_checker;
   amm_read_0       <= ddr_read_0  when (test = '0' and ddr3_check_done='1')  else amm_read_0_checker;
   amm_address_0	<= amm_address_0_buf when ddr3_check_done='1' else amm_address_0_checker;
   amm_burstcount_0	<= amm_burstcount_0_buf when ddr3_check_done='1' else amm_burstcount_0_checker;   
   
   
   
   process(ddr3_nRST, ddr3_clk) ---debug only
   begin
		if ddr3_nRSt = '0' then
		elsif rising_edge(ddr3_clk) then
			if ddr_write_0 ='1' and amm_ready_0 = '1'  and wrd_rdata /= 0  then
				bad_write_flag <= '1';
		    else
				bad_write_flag <= '0';
			end if;
			if amm_readdatavalid_0='1'   and amm_readdata_0 /= 0  then
				bad_read_flag <= '1';
		    else
				bad_read_flag <= '0';
			end if;
		end if;
  end process;
-------------------------------------------------------------------------------------
wr_trans_done <= '1' when ddr3_write_done = '1' else '0';
process(ddr3_nRST, ddr3_clk)
begin
    if ddr3_nRST = '0' then
         wr_substate     <= WR_ST_DDR3INIT;
         wr_req          <= '0';
         wr_trans_dur    <= '0';
         wr_wcnt         <= (others=>'0');
         wrc_cmdfifo_rden<= '0';
		 wrd_rdaddr_ddr3 <= (others=>'0');
         wrd_prefetch_en <= '0';
         wrd_datafetch_en<= '0';
         wr_burstcnt     <= (others=>'0');
    elsif rising_edge(ddr3_clk) then
		 if DDRB_RSTALL_EN = '1' AND frame_rst = '1' and op_ddr_dur_ddr(3) ='0' then -----ddrb_vsync_neg_ddr = '1' THEN
			if ddr3_init_done_level = '1' then
				wr_substate <= WR_ST_VSYNCA;
			else
				wr_substate <= WR_ST_DDR3INIT;
			end if;

		    wr_req          <= '0';
			wr_trans_dur    <= '0';
			wr_wcnt         <= (others=>'0');
			wrc_cmdfifo_rden<= '0';
			wrd_rdaddr_ddr3 <= (others=>'0');
            wr_burstcnt     <= (others=>'0');
            wrd_prefetch_en <= '0';
            wrd_datafetch_en<= '0';
		 ELSE
          case(wr_substate ) is
              when WR_ST_DDR3INIT =>
                    if ddr3_init_done_level = '1' then
                        wr_substate <= WR_ST_IDLE ;
                    else
                        wr_substate <= WR_ST_DDR3INIT;
                    end if;
                    wr_req  <= '0';
                    wr_trans_dur    <= '0';
                    wr_wcnt     <= (others=>'0');
					wrc_cmdfifo_rden <= '0';
					wrd_rdaddr_ddr3 <= (others=>'0');

                    wrd_prefetch_en <= '0';
                    wrd_datafetch_en<= '0';
			 when WR_ST_VSYNCA =>
				  	wr_req  <= '0';
                    wr_trans_dur    <= '0';
					wrc_cmdfifo_rden <= '0';
					wrd_rdaddr_ddr3 <= (others=>'0');
					if wr_wcnt(8) = '1' then
						wr_wcnt     <= (others=>'0');
						wr_substate <= WR_ST_IDLE;
			       else
						wr_wcnt  <= wr_wcnt + 1 ;
				   end if;

                    wrd_prefetch_en <= '0';
                    wrd_datafetch_en<= '0';

             when WR_ST_IDLE =>
                   wr_req          <= '0';
                   wr_trans_dur    <= '0';
                   wr_wcnt         <= (others=>'0');
				   wrd_rdaddr_ddr3 <= (others=>'0');
                   if wrc_cmdfifo_empty = '0' then
                        wrc_cmdfifo_rden <= '1';
                        wr_substate      <= WR_ST_CMDWAIT;
                   else
                        wrc_cmdfifo_rden <= '0';
                        wr_substate      <= WR_ST_IDLE;
                   end if;

                    wrd_prefetch_en <= '0';
                    wrd_datafetch_en<= '0';

            when WR_ST_CMDWAIT =>
                   wr_trans_dur    <= '0';
                   wrc_cmdfifo_rden <= '0';
                   if wr_wcnt(1) = '1' then
                        wr_wcnt             <= (others=>'0');
                        wr_substate         <= WR_ST_PREFETCH2D; ----WR_ST_WAITACK;
                        wr_req              <= '0';
                        -----burst info is ready .....
                        wr_start_burstaddr  <= wrc_cmdfifo_q(DDRA_W-1 downto 0); --start  addres ,unit is burst
                        wr_burstlen         <= wrc_cmdfifo_q(34 downto 28); --burst length (unit is burst)
                        wrd_rdaddr_ddr3     <= wrc_cmdfifo_q(51 downto 43); ---offset ;

                        wrd_prefetch_en <= '1'; --dpram fetch ,while prefetch stage
                        wrd_datafetch_en<= '1'; --Indicate  dpram fetch
                   else
                       wr_wcnt         <= wr_wcnt + 1 ;
                       wr_req          <= '0';
                       wr_substate     <= WR_ST_CMDWAIT;
                       wrd_prefetch_en <= '0';
                       wrd_datafetch_en<= '0';
                   end if;



            when WR_ST_PREFETCH2D =>  --Fetch first two data if any
                if wr_wcnt(1) = '1' then
                    wr_substate     <= WR_ST_WAITACK;
                    wr_wcnt         <= (others=>'0');
                    wr_req          <= '1';
                    wrd_prefetch_en <= '0';
                    if wrd_datafetch_en = '1' then --enable next address to be ready ...
                        wrd_rdaddr_ddr3 <= wrd_rdaddr_ddr3 + 1;
                    end if;
                else
                    wr_req      <= '0';
                    wr_wcnt     <= wr_wcnt + 1;
                    wr_substate <= WR_ST_PREFETCH2D;
                    if wr_wcnt = 0 then
                       if wr_burstlen = 1 then --only one cycles for data
                            -----while for dpram ,it need 2 cycles to pop data ready
                            wrd_prefetch_en <= '1';
                            wrd_datafetch_en<= '0';
                            wrd_rdaddr_ddr3 <= wrd_rdaddr_ddr3; --no updating address
                             --pipe data out to sit on the dpram out
                            wr_burstcnt     <= (others=>'0');
                       else
                            wr_burstcnt     <= wr_burstlen - 2; ----reduced 2 ---
                            wrd_rdaddr_ddr3 <= wrd_rdaddr_ddr3 + 1;
                            wrd_prefetch_en <= '1';
                            if wr_burstlen = 2 then
                                wrd_datafetch_en<= '0';
                            else
                                wrd_datafetch_en<= '1';
                            end if;
                       end if;
                    else --if wr_wcnt = 1 then
                          wrd_prefetch_en <= '0';
                    end if;
                end if;

            when WR_ST_WAITACK =>
                     wr_wcnt             <= (others=>'0');
                     wrc_cmdfifo_rden <= '0';
                     wrd_prefetch_en <= '0';
                     IF wr_ack = '1' then
                        wr_req  <= '0';
                       wr_substate <= WR_ST_WAITDONE ;
                       wr_trans_dur    <= '1';
                     else
                          wr_substate <= WR_ST_WAITACK ;
                          wr_trans_dur    <= '0';
                          wr_req <= '1';
                      end if;
            when WR_ST_WAITDONE =>
                    wr_req           <= '0';
                    wrd_prefetch_en  <= '0';
                    wrc_cmdfifo_rden <= '0';
                    wr_wcnt             <= (others=>'0');
					if wrd_rden_buf = '1' and wr_burstcnt /= 0  then
						wrd_rdaddr_ddr3 <= wrd_rdaddr_ddr3 + 1 ;
                        wr_burstcnt     <= wr_burstcnt - 1;
                        wrd_datafetch_en<= '0'; --last data reading ....
                    else

					end if;
					if op_timeout(OP_MSB) = '1' THEN
					    wr_substate     <= WR_ST_IDLE;
                        wr_trans_dur    <= '0';
                    elsif wr_trans_done = '1' then
                        wr_substate     <= WR_ST_IDLE;
                        wr_trans_dur    <= '0';
                    else
                        wr_substate     <= WR_ST_WAITDONE ;
                        wr_trans_dur    <= '1';
                    end if;
            WHEN OTHERS=>
                    wr_req           <= '0';
                    wrc_cmdfifo_rden <= '0';
                    wr_trans_dur    <= '0';
                    wr_wcnt         <= (others=>'0');
                    wr_substate     <= WR_ST_IDLE;

          end case;
      END IF;
    end if;
end process;
-------------------------------------------------------------------------------------
--sync mode
 rrd_async_enoughi: IF ASYNC_MODE = '0' generate
            rrd_wfifo_is_enough <= '1' when rrd_wrusedw  < 512 - 128 else '0'; --Note : if async mode is used ,
 end generate rrd_async_enoughi;

 --async mode
 rrd_sync_enoughi: if ASYNC_MODE = '1' generate
    --rrd_wfifo_is_enough
     rrd_wfifo_is_enough <= '1' when rrd_preusedw < 512-128 else '0';
     rd_cmd_vld          <= rd_req and rd_ack ;
     process(ddr3_nRST,ddr3_clk)
     begin
            if ddr3_nRST = '0' then
                 rrd_suspend_burst <= (others=>'0');
            elsif rising_edge(ddr3_clk) then
                ----if ddr3_init_done_d1(0) = '1' then
                if ddr3_init_done_d1(0) = '1' or ((DDRB_RSTALL_EN='1' OR READ_RST_ONLY= '1') and (frame_rst ='1' or   rd_substate= RD_ST_VSYNCA ) and op_ddr_dur_ddr(3) ='0' ) then
                    rrd_suspend_burst <= (others=>'0');
                elsif rd_cmd_vld  = '1' and (ddr3_read_data_valid = '1' and rd_trans_dur = '1'  ) then
                    rrd_suspend_burst <= rrd_suspend_burst + (rd_burstlen ) - 1;
                elsif rd_cmd_vld = '1' then
                    rrd_suspend_burst <= rrd_suspend_burst + (rd_burstlen );
                elsif ddr3_read_data_valid = '1' and rd_trans_dur = '1' then
                    rrd_suspend_burst <= rrd_suspend_burst - 1 ;
                end if;

                -- if ddr3_init_done_d1(0) = '1' or (DDRB_RSTALL_EN='1' and (ddrb_vsync_neg_ddr ='1' or  rd_substate = RD_ST_VSYNCA ) ) then
                if ddr3_init_done_d1(0) = '1' or ((DDRB_RSTALL_EN='1' OR READ_RST_ONLY= '1') and (frame_rst ='1' or  rd_substate = RD_ST_VSYNCA )and op_ddr_dur_ddr(3) ='0' ) then
                    rrd_preusedw <= (others=>'1');
                else
                     rrd_preusedw <= (rrd_suspend_burst) + rrd_wrusedw(10 downto 0); --fifo depth is 512 (if changed)
                end if;
            end if;
     end process;
 end generate rrd_sync_enoughi;



rd_trans_done <= '1' when ddr3_read_done = '1' else '0';
process(ddr3_nRST, ddr3_clk)
begin
    if ddr3_nRST = '0' then
         rd_substate     <= RD_ST_DDR3INIT;
         rd_req          <= '0';
         rd_trans_dur    <= '0';
         rd_wcnt         <= (others=>'0');
         rd_is_2_burst   <= '0';
         rrc_cmdfifo_rden <= '0';
    elsif rising_edge(ddr3_clk) then
		-- if DDRB_RSTALL_EN = '1' AND ddrb_vsync_neg_ddr = '1' THEN
		if (DDRB_RSTALL_EN = '1' or READ_RST_ONLY= '1'  )AND frame_rst = '1' and op_ddr_dur_ddr(3) = '0' THEN
			        if ddr3_init_done_level = '1' then
			        	rd_substate <= RD_ST_VSYNCA;
			        else
			        	rd_substate <= RD_ST_DDR3INIT;
			        end if;
					rd_req      <= '0';
                    rrc_cmdfifo_rden <= '0';
                    rd_wcnt     <= (others=>'0');
                    rd_trans_dur    <= '0';
					rd_is_2_burst   <= '0';

		 ELSE
			if rd_ack = '1' then
				rd_trans_dur <= '1';
			else
				if op_timeout(OP_MSB)='1' then
					rd_trans_dur <= '0';
				elsif rd_trans_done = '1' then
					rd_trans_dur <= '0';
				end if;
			end if;
          case(rd_substate ) is
              when RD_ST_DDR3INIT =>
                    if ddr3_init_done_level = '1' then
                        rd_substate <= RD_ST_IDLE ;
                    else
                        rd_substate <= RD_ST_DDR3INIT;
                    end if;
                    rd_req  <= '0';
                     rd_is_2_burst       <= '0';
                    -- rd_trans_dur    <= '0';
                   --- wr_is_2_burst       <= '0';
                    rd_wcnt     <= (others=>'0');
                    rrc_cmdfifo_rden <= '0';

             when RD_ST_VSYNCA =>
					rd_req      <= '0';
                    rrc_cmdfifo_rden <= '0';
					rd_is_2_burst   <= '0';
                    rd_wcnt         <= (others=>'0');
                    -- rd_trans_dur    <= '0';
					IF rd_wcnt(8) = '1' then
						rd_substate <= RD_ST_IDLE;
						rd_wcnt     <= (others=>'0');
					else
						rd_substate <= RD_ST_VSYNCA;
						rd_wcnt     <= rd_wcnt + 1;
					end if;

             when RD_ST_IDLE =>
                    rd_req   <= '0';
                    -- rd_trans_dur    <= '0';
                    rd_is_2_burst       <= '0';
                    rd_wcnt     <= (others=>'0');
                   if (rrc_cmdfifo_empty = '0') and (rrd_wfifo_is_enough = '1') then
                        rrc_cmdfifo_rden <= '1';
                        rd_substate      <= RD_ST_CMDWAIT;
                   else
                        rrc_cmdfifo_rden <= '0';
                        rd_substate      <= RD_ST_IDLE;
                   end if;

            when RD_ST_CMDWAIT =>
                   -- rd_trans_dur    <= '0';
                   rrc_cmdfifo_rden <= '0';

                        if rd_wcnt(1 ) = '1'  then
                               rd_wcnt             <= (others=>'0');
                               rd_substate         <= RD_ST_WAITACK;
                               rd_req              <= '1';
                               rd_start_burstaddr  <= rrc_cmdfifo_q(DDRA_W-1 downto 0 ); --start  addres ,unit is burst
                               rd_burstlen         <= rrc_cmdfifo_q(34 downto 28); --burst length (unit is burst)
                               rd_is_2_burst       <= '0'; ---rrc_cmdfifo_q( 29 );
                            --rd_id               <= rrc_cmdfifo_q()
                        --    rd_start_boff       <= rrc_cmdfifo_q_d1(36 downto 30); --start mask , 512bit = 64bytes
                       --     rd_end_boff         <= rrc_cmdfifo_q_d1(43 downto 37); --end mask
                        else
                                rd_wcnt  <= rd_wcnt + 1 ;
                                rd_req   <= '0';
                                rd_substate <= RD_ST_CMDWAIT;
                        end if;
            when RD_ST_WAITACK =>
                    rrc_cmdfifo_rden <= '0';
                     rd_wcnt         <= (others=>'0');
                    IF rd_ack = '1' then
                        rd_req  <= '0';
                        -- rd_trans_dur    <= '1';
                        rd_substate <= RD_ST_WAITDONE ;
                    else
                        rd_substate <= RD_ST_WAITACK ;
                        rd_req <= '1';
                        -- rd_trans_dur    <= '0';
                    end if;
            when RD_ST_WAITDONE =>
                    rrc_cmdfifo_rden <= '0';
                    rd_req <= '0';
                    rd_wcnt             <= (others=>'0');
                    -- if op_timeout(OP_MSB) = '1' THEN
					    rd_substate	    <= RD_ST_IDLE;
                        -- rd_trans_dur    <= '0';
                    -- elsif rd_trans_done = '1' then
                        -- rd_is_2_burst <= '0';
                        -- rd_substate     <= RD_ST_IDLE;

                        -- rd_trans_dur    <= '0';
                    -- else
                        -- rd_substate <= RD_ST_WAITDONE ;
                        -- rd_trans_dur    <= '1';
                    -- end if;


            WHEN OTHERS=>
                    rd_req      <= '0';
                    rrc_cmdfifo_rden <= '0';
                    rd_wcnt     <= (others=>'0');
                    -- rd_trans_dur    <= '0';
                    rd_substate <= RD_ST_IDLE;

          end case;
	  end if;
    end if;
end process;

----------------------------------------------------------------------
----------------------------------------------------------------------
rd_start_addr <= rd_start_burstaddr; ----&"000"; --unit is 64bit;
wr_start_addr <= wr_start_burstaddr; ---&"000"; --unit is 64bit;

----main pstate ------------------------------------------------------------------
ddr3_write_done <= ddr3_data_last and ddr3_datain_rdy;
ddr3_read_done  <= ddr3_data_last and ddr3_read_data_valid ;

ddr3_datain_rdy      <= ddr_write_0 and amm_ready_0 ;
ddr3_read_data_valid <= amm_readdatavalid_0; ----ddr_read_0  and amm_ready_0;

process(pstate,ddr3_is_read)
begin
	case(pstate) is
		when ddr3_wait_ack=>
				---if ddr3_is_read ='1' then
					pstate_is_read <= '1';
				---else
				--	pstate_is_read <= '0';
				--end if;
		when wait_ddr3_read =>
				pstate_is_read <= '1';
		when others=>
				pstate_is_read <= '0' ;
    end case;
end process;

   process(pstate,frame_rst,wr_req,rd_req,op_ddr_dur_ddr)
   --to make wr_subste and pstate transfer at the same time
   --to avoid
   begin
       if pstate = main_idle then
            wr_ack <= '0';
             if READ_HIGH_PRIO ='0' then  --WRITE priority higher
								if (DDRB_RSTALL_EN = '1' OR READ_RST_ONLY='1') AND frame_rst = '1' and  op_ddr_dur_ddr(3) ='0' then
									 wr_ack <= '0';
                                elsif wr_req = '1' then
                                     wr_ack <= '1';
                                else
                                     wr_ack <= '0';
                                end if;
            else
                        if(DDRB_RSTALL_EN = '1' OR READ_RST_ONLY='1') AND frame_rst = '1' and op_ddr_dur_ddr(3) ='0' then
                             wr_ack <= '0';
                        elsif rd_req = '1' then
                             wr_ack <= '0';
                        elsif wr_req = '1' then
                             wr_ack <= '1';
                        else
                             wr_ack <= '0';
                        end if;
            end if;
       else
            wr_ack <= '0';
       end if;
   end process;


   process(ddr3_nRST, ddr3_clk)
   begin
        if ddr3_nRST = '0' then
                pstate         <= ddr3_init;
                ddr3_data_last <= '0';
              ---2019  wr_ack         <= '0';
                rd_ack         <= '0';

                amm_address_0_buf      <= (others=>'0');
                ddr3_burst_len     <= (others=>'0');
                ddr3_256b_cnt      <= (others=>'0');  --256bit count
                amm_burstcount_0_buf   <= (others=>'0');  --256bit count
                frame_ack          <= '0';
				op_timeout         <= (others=>'0');

                ddr_read_0 <= '0';
                ddr_write_0 <= '0';

        elsif rising_edge(ddr3_clk) then

               case(pstate) is
                    when ddr3_init =>
						 op_timeout <= (others=>'0');
                         -- if ddr3_init_done_sel = '1' then
                         if ddr3_init_done_level = '1' then
                                pstate <= main_idle ;
                         else
                                pstate <= ddr3_init;
                         end if;
                         ddr3_data_last <= '0';
                      ---2019    wr_ack      <= '0';
                         rd_ack      <= '0';
                         ddr_read_0  <= '0';
                         ddr_write_0 <= '0';
                         frame_ack <= '0';

                   when main_idle =>
                     ---2019    wr_ack      <= '0';
                        rd_ack    <= '0';
                        ddr3_data_last <= '0';
						frame_ack <= '0';
						ddr_write_0 <= '0';
						ddr_read_0  <= '0';
						op_timeout <= (others=>'0');
                        if READ_HIGH_PRIO ='0' then  --WRITE priority higher
								if (DDRB_RSTALL_EN = '1' OR READ_RST_ONLY='1') AND frame_rst = '1' and  op_ddr_dur_ddr(3) ='0' then
                                    frame_ack <= '1';
                                    pstate    <= ddr3_init;
                                elsif wr_req = '1' then
                                    pstate              <= wait_ddr3_write;
                                    amm_address_0_buf       <= wr_start_addr;
                                    ddr3_burst_len      <= wr_burstlen;
                                    ddr3_256b_cnt       <= wr_burstlen;
                                    amm_burstcount_0_buf    <= wr_burstlen ;
                                    ddr_write_0         <= '1';
                                    ddr3_is_read        <= '0';
                                    if (wr_burstlen = 1) then
                                        ddr3_data_last <= '1';
                                    else
                                        ddr3_data_last <= '0';
                                    end if;

                                elsif rd_req = '1' then
                                    pstate              <= ddr3_wait_ack;
                                    rd_ack              <= '1';
                                    amm_address_0_buf       <= rd_start_addr;
                                    ddr3_burst_len      <= rd_burstlen;
                                    ddr3_256b_cnt       <= rd_burstlen;
                                    amm_burstcount_0_buf      <= rd_burstlen;
                                    ddr_read_0          <= '1';
                                    ddr3_is_read        <= '1';

                                    if (rd_burstlen = 1) then
                                        ddr3_data_last <= '1';
                                    else
                                        ddr3_data_last <= '0';
                                    end if;
                                else
                                    pstate         <= main_idle ;
                                    ddr3_is_read   <= '0';
                                    ddr_read_0     <= '0';
                                    ddr_write_0    <= '0';
                                end if;
                     else  --read higher priority
								if(DDRB_RSTALL_EN = '1' OR READ_RST_ONLY='1') AND frame_rst = '1' and op_ddr_dur_ddr(3) ='0' then
									 frame_ack <= '1';
									 pstate    <= ddr3_init;
                                elsif rd_req = '1' then
                                    pstate              <= ddr3_wait_ack;
                                    rd_ack              <= '1';
                                    amm_address_0_buf       <= rd_start_addr;
                                    ddr3_burst_len      <= rd_burstlen   ;  ----ddr3 burst len (at most 32 )
                                    ddr3_256b_cnt       <= rd_burstlen; ---5 downto 0) &'0'     ;  ----ddr3 burst len (at most 32 )
                                  ---  ddr3_firstmask      <= serdout_firstmask ;
                                  ---  ddr3_lastmask       <= serdout_lastmask  ;
                                    amm_burstcount_0_buf      <= rd_burstlen ; ---(5 downto 0) ;
                                --    ddr3_start_boff     <= rd_start_boff(5 downto 0);
                                --    ddr3_end_boff       <= rd_end_boff(5 downto 0);
                                    ddr_read_0          <= '1';
                                    ddr3_is_read        <= '1';
                                    if (rd_burstlen = 1) then
                                        ddr3_data_last <= '1';
                                    else
                                        ddr3_data_last <= '0';
                                    end if;

                              elsif wr_req = '1' then
                                    pstate              <= wait_ddr3_write;
                                  ---2019   wr_ack              <= '1';
                                    amm_address_0_buf         <= wr_start_addr;
                                    ddr3_burst_len            <= wr_burstlen ;
                                    ddr3_256b_cnt             <= wr_burstlen  ;  --6bit
                                    amm_burstcount_0_buf      <= wr_burstlen ;
                                --    ddr3_start_boff     <= wr_start_boff(5 downto 0);
                               --     ddr3_end_boff       <= wr_end_boff(5 downto 0);
                                ---    ddr3_firstmask      <= vidin_firstmask;
                                ---    ddr3_lastmask       <= vidin_lastmask ; ---
                                    ddr_write_0         <= '1';
                                    ddr3_is_read        <= '0';
                                    if (wr_burstlen = 1) then
                                        ddr3_data_last <= '1';
                                    else
                                        ddr3_data_last <= '0';
                                    end if;
                                else
                                     pstate         <= main_idle ;
                                     ddr3_is_read   <= '0';
                                     ddr_write_0    <= '0';
                                     ddr_read_0     <= '0';
                                end if;

                     end if;

                  when ddr3_wait_ack => ---issue the ddr3 read command  only
                        frame_ack <= '0';
                      ---2019   wr_ack    <= '0';
                        rd_ack  <= '0';
                        ddr_write_0    <= '0';
                        ----ddr3_data_last <= '0';
						if op_timeout(OP_MSB) = '0' THEN
							op_timeout  <= op_timeout + 1 ;
						END IF;
						if op_timeout(OP_MSB) = '1' THEN
						    pstate <= main_idle ;
                            ddr_read_0  <= '0';
                        elsif ddr_read_0  = '1' and amm_ready_0 = '1' then --command accepted
                             ddr_read_0   <= '0';
                            -- if ddr3_is_read = '1' then
                                pstate <= wait_ddr3_read ;
                            -- else
                                -- pstate <= wait_ddr3_write ;
                            -- end if;
                        else
                            pstate <= ddr3_wait_ack ;
                        end if;


                when wait_ddr3_read => --wait response only
						if op_timeout(OP_MSB) = '0' THEN
							op_timeout  <= op_timeout + 1 ;
						END IF;
                   ---2019     wr_ack    <= '0';
                       frame_ack <= '0';
                       rd_ack  <= '0';
                       ddr_read_0 <= '0';
                       ddr_write_0 <= '0';
                       if ddr3_read_data_valid = '1' then
                           ddr3_256b_cnt <= ddr3_256b_cnt - 1;
                           if ddr3_256b_cnt = 2 then
                                ddr3_data_last <= '1';
                           else
                                ddr3_data_last <= '0';
                           end if;

                     else
                        ----
                     end if;
					 if op_timeout(OP_MSB) = '1' THEN
						    pstate <= main_idle ;
                     elsif ddr3_read_done = '1' then ---read out -----
                            pstate <= main_idle ;
                     else
                            pstate <= wait_ddr3_read;
                     end if;


                when wait_ddr3_write => --write data into ddr3
					   if op_timeout(OP_MSB) = '0' THEN
							op_timeout  <= op_timeout + 1 ;
					   END IF;
                    ---2019    wr_ack    <= '0';
                       rd_ack  <= '0';
                       frame_ack <= '0';
                       ddr_read_0  <= '0';

                       if ddr3_datain_rdy = '1' then
                            ddr3_256b_cnt <= ddr3_256b_cnt - 1;
                            if ddr3_256b_cnt = 2 then
                                ddr3_data_last <= '1';
                            else
                                ddr3_data_last <= '0';
                            end if;
                       else
                            ----no more action
                       end if;
                       if op_timeout(OP_MSB) = '1' THEN
						    pstate <= main_idle ;
                             ddr_write_0 <= '0';
                       elsif ddr3_write_done = '1' then
                            pstate <= main_idle;
                            ddr_write_0 <= '0';
                       else
                            pstate <= wait_ddr3_write ;
                            ddr_write_0 <= '1';
                       end if;
         when others => pstate  <= main_idle;
                        op_timeout <= (others=>'0');
                        ddr_read_0 <= '0';
                        ddr_write_0 <= '0';
               end case;
          ---- end if; ----
        end if;
   end process;


   rrd_wdata <= amm_readdata_0 ;
   rrd_wren  <= ddr3_read_data_valid and rd_trans_dur;



-- process(ddr3_clk)
-- begin
        -- if rising_edge(ddr3_clk) then
            -- ddr3_s0_mask <= ddr3_start_mask(31 downto 0); --LSB first ..
            -- ddr3_s1_mask <= ddr3_start_mask(63 downto 32);--LSB first ..
            -- ddr3_e0_mask <= ddr3_end_mask(31 downto 0);   --LSB first ..
            -- ddr3_e1_mask <= ddr3_end_mask(63 downto 32);  --LSB first ..
       -- end if;
-- end process;

---first arrived pixel is placed at the LSB of 256bytes
 -- process( ddr3_start_boff)
 -- begin
        -- for i in 0 to 63 loop
              -- if (ddr3_start_boff <= i) then  --LSB first .
                   -- ddr3_start_mask( i) <= '0'; ---NO MASK at all;
              -- else
                   -- ddr3_start_mask( i) <= '1';
              -- end if;
        -- end loop;
 -- end process;

 -- process(ddr3_end_boff)
 -- begin
    -- for i in 0 to 63 loop
        -- if ddr3_end_boff = 0 then
            -- ddr3_end_mask( i ) <= '0';  --no mask at all ....
        -- elsif ( i < ddr3_end_boff ) then  --LSB first .(how many bytes left in the last 512bits)
            -- ddr3_end_mask( i) <=  '0';
        -- else
            -- ddr3_end_mask( i ) <= '1'; ---NO MASK at all;
        -- end if;
    -- end loop;
 -- end process;



   -- process(ddr3_nRST,  ddr3_clk)
   -- begin
        -- if ddr3_nRST = '0' then
            -- wrd_sync_data_mask <= (others=>'0');  -- '0' :  write through , '1': mask out
        -- elsif rising_edge(ddr3_clk) begin
            -- ddr3_256b_cnt_d1 <= ddr3_256b_cnt ;
            -- if ddr3_is_read = '1' then
               -- wrd_sync_data_mask <= (others=>'0');
           -- else

                -- --wrdy delay two cycles
                -- if ddr3_256b_cnt_d1 = 0 then
                       -- wrd_sync_data_mask  <= ddr3_s0_mask;
                -- elsif ddr3_256b_cnt_d1 = 1 then
                       -- wrd_sync_data_mask  <= ddr3_s1_mask;
                -- elsif ddr3_256b_cnt_d1 = (ddr3_burst_len &'0')-2 then
                       -- wrd_sync_data_mask  <= ddr3_e0_mask ;  --first
                -- elsif ddr3_256b_cnt_d1 = ( ddr3_burst_len &'0') -1 then
                       -- wrd_sync_data_mask <= ddr3_e1_mask ;
                -- else
                       -- wrd_sync_data_mask  <= (others=>'0');
                -- end if;

            -- end if;
        -- end if;
  -- end process;


 ---  process(wrd_async_mask_map, wrd_sync_data_mask)
 ---  begin
 ---     ---  if ASYNC_MODE = '1' THEN
 ---             ddr3_data_mask <= wrd_async_mask_map ;  --async mode mask
 ---       -- else
 ---             -- ddr3_data_mask <= wrd_sync_data_mask;
 ---       -- end if;
 ---  end process;
 ---
 ---
 ---  --note : we must maker sure the picture width is larger than 16 pixels
 ---  --       otherwise , the following logic may behavior badly
 ---  process(wrd_rmask)
 ---  begin
 ---       if wrd_rmask(6) = '0' then   ---start mask
 ---           for i in 0 to 31 loop
 ---               if (wrd_rmask(5 downto 0) <= i) then  --LSB first .
 ---                  wrd_async_mask_map( i) <= '0'; ---NO MASK at all;
 ---               else ---if wrd_rmask = 32 , then all data are mask out
 ---                  wrd_async_mask_map( i) <= '1';
 ---               end if;
 ---           end loop;
 ---       else  --end mask
 ---              for i in 0 to 31 loop
 ---                   if wrd_rmask(5) = '1' then ---- downto 0)  = 0 then
 ---                       wrd_async_mask_map( i ) <= '0';  --no mask at all ....
 ---                   elsif ( i < wrd_rmask(5 downto 0)  ) then  --LSB first .(how many bytes left in the last 512bits)
 ---                       wrd_async_mask_map( i) <=  '0';
 ---                   else -- if wrd_rmask = 32 , then all data are masked out .....
 ---                       wrd_async_mask_map( i ) <= '1'; ---NO MASK at all;
 ---                   end if;
 ---           end loop;
 ---       end if;
 ---  end process;

  -- ddr3_data_mask <= wrd_rmask ; ---directly from outside  ......
end beha ;