library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;
use work.PCK_param_sched.all;

entity shutter_ddr3_op is 
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
	GRP_SIZE    :  integer := 2;
	DDR_RDPORT_NUM  : integer := 1;
	DDR_WRPORT_NUM  : integer := 1

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
	shutter_rd_frmvld       :  out std_logic_vector(GRP_NUM-1 downto 0);

	real_eth_num_conv       :  in  std_logic_vector(3 downto 0);
		
	ddr_verify_end_o        : out std_logic_vector(DDR_NUM-1 downto 0);
	ddr_verify_success_o    : out std_logic_vector(DDR_NUM-1 downto 0)
	
				
);
end shutter_ddr3_op ;

architecture beha of shutter_ddr3_op is 


component shutter_ddr3_wr is 
generic 
(  
	WRC_W       :  integer := 43;
	DDRD_W      :  integer := 320;
	DDR_AW      :  integer := 23
	
);
port  
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;
	
	pframe_en             :  in  std_logic;
	pwren                 :  in  std_logic;
	paddr                 :  in  std_logic_vector(10 downto 0);
	pdata                 :  in  std_logic_vector(7 downto 0);
	
    wr_req                :  out  std_logic;
    wr_ack                :  in   std_logic;
                          
    wr_cmd                :  out  std_logic_vector(WRC_W-1 downto 0);
    wr_abort              :  out  std_logic;
    wr_lastw              :  out  std_logic;
    wr_data               :  out  std_logic_vector(DDRD_W-1 downto 0);
    wr_wren               :  out  std_logic;
    wr_mask               :  out  std_logic_vector((DDRD_W/8)-1 downto 0) ;
	real_eth_num_conv       :  in  std_logic_vector(3 downto 0)
				
);
end component ;

signal    wr_req                :    std_logic;
signal    wr_ack                :    std_logic;
                       
signal    wr_cmd                :    std_logic_vector(WRC_W-1 downto 0);
signal    wr_abort              :    std_logic;
signal    wr_lastw              :    std_logic;
signal    wr_data               :    std_logic_vector(DDRD_W-1 downto 0);
signal    wr_wren               :    std_logic;
signal    wr_mask               :    std_logic_vector((DDRD_W/8)-1 downto 0) ;

component shutter_ddr3_rd is 
generic 
(  
	WRC_W       :  integer := 43;
	DDRD_W      :  integer := 320;
	DDR_AW      :  integer := 23;
	CREQ_W      :  integer := 35;
	CRSP_W      :  integer := 44;
	TAGW        : integer    :=  4   ;
	GRP_NUM     :  integer := 2;
	GRP_SIZE    :  integer := 10
);
port  
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;
	
	pframe_en             :  in  std_logic;
	pwren                 :  in  std_logic;
	paddr                 :  in  std_logic_vector(10 downto 0);
	pdata                 :  in  std_logic_vector(7 downto 0);
	
	
	shutter_rd_req        :  in  std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_ack        :  out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_frm_index  :  in  std_logic_vector(GRP_NUM*15-1 downto 0);
	shutter_rd_eth_index  :  in  std_logic_vector(GRP_NUM*4-1 downto 0);
	shutter_rsp_data      :  out std_logic_vector(71 downto 0);
	shutter_rsp_dvld      :  out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_end        :  out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_frmvld     :  out std_logic_vector(GRP_NUM-1 downto 0);
	
	
    rd_req                 : out std_logic;
    rd_ack                 : in  std_logic ;
    rd_reqcmd              : out std_logic_vector(CREQ_W-1 downto 0);
    rd_respcmd             : out std_logic_vector(CRSP_W-1 downto 0);  ---extra 5bits are needed to convey the line_end and netport index ;

    rd_rsp_dvld             : in std_logic ;
    rd_rsp_data             : in std_logic_vector(DDRD_W -1 downto 0);
    rd_rsp_retcmd           : in std_logic_vector(CRSP_W-1 downto 0);
    rd_rsp_lastw            : in std_logic;  --last word --last word in the seg
    rd_rsp_firstw           : in std_logic ; --first word --first word in the seg
    rd_rsp_prefirstw        : in std_logic ; --just before first word --first word in the seg
	real_eth_num_conv       :  in  std_logic_vector(3 downto 0)
				
);
end component ;

signal    rd_req                 :  std_logic;
signal    rd_ack                 :  std_logic ;
signal    rd_reqcmd              :  std_logic_vector(CREQ_W-1 downto 0);
signal    rd_respcmd             :  std_logic_vector(CRSP_W-1 downto 0);  ---extra 5bits are needed to convey the line_end and netport index ;

signal    rd_rsp_dvld             : std_logic :='0';
signal    rd_rsp_data             : std_logic_vector(DDRD_W -1 downto 0);
signal    rd_rsp_retcmd           : std_logic_vector(CRSP_W-1 downto 0);
signal    rd_rsp_lastw            : std_logic:='0';  --last word --last word in the seg
signal    rd_rsp_firstw           : std_logic:='0' ; --first word --first word in the seg
signal    rd_rsp_prefirstw        : std_logic:='0'; --just before first word --first word in the seg

component ddr_bus_top is
generic
(
  SIM             :  STD_LOGIC := '0';
  DDRB_RSTALL_EN  :  std_logic := '0';
  READ_RST_ONLY   :   STD_LOGIC ;
  ASYNC_MODE      :  STD_LOGIC := '0'; --DDR3 IS async mode or not , '1': async ,'0: sync
  READ_HIGH_PRIO  :  STD_LOGIC := '0';  --'0' : write higher , '1': read higher priority
  WRC_W           : integer := 43+10; --WRite command FIFO width
  RRC_W           : integer := 35 ;  --READ req command  FIFO width  ;
  RRSP_W          : integer := 30 ;  --READ rsp command  FIFO width  ;
  DDRA_W          : INTEGER := 23 ;  --DDR address
  DDRD_W          : INTEGER := 320;  --ddr daa
  TAGW            : INTEGER := 4;
  RPORT_NUM       : INTEGER := 4;
  WPORT_NUM       : INTEGER := 3;
  BURST_W         : INTEGER := 7    ---NOT SUPPROTED YET
);
port
(


   ddrb_vsync_neg_ddr : in std_logic ;  --20171103 wangac

    sys_ddr_core_nrst  : in std_logic;
	ddr_verify_end     : out std_logic;
	ddr_verify_success : out std_logic;
   ------------------------------------------
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
	
	check_amm_readdatavalid_0 : in   std_logic       ;
	check_amm_readdata_0      : in   std_logic_vector(DDRD_W-1 downto 0);

    sys_nRST  : in std_logic ;
    sysclk1   : in std_logic ;
    sysclk2   : in std_logic ;
     --ddr3
    op_ddr_dur              : in  std_logic;    --prohibit others ddr op
    --quick upgrade
    op_ddr_req              : in  std_logic;
    op_ddr_ack              : out std_logic;
    op_ddr_end              : out std_logic;   --indicatet read is ending ......
    op_ddr_cmd              : in  std_logic;    --0:wr ,1:rd
    op_sys2ddr_addr         : in  std_logic_vector(25 downto 0);
    op_sys2ddr_rden         : out std_logic; ---DDR write
    op_sys2ddr_q            : in  std_logic_vector(255 downto 0);
    op_ddr2sys_wren         : out std_logic; ---DDR READ
    op_ddr2sys_data         : out std_logic_vector(255 downto 0);

    ------------read port -----------------------------------

    rd_vsync_neg_sys        :  in  std_logic_vector(RPORT_NUM-1 downto 0) ;
    rd_req                 :  in  std_logic_vector(RPORT_NUM-1 downto 0);
    rd_ack                 :  out std_logic_vector(RPORT_NUM-1 downto 0);
    rd_reqcmd              :  in  std_logic_vector(RRC_W*RPORT_NUM-1 downto 0);
    rd_respcmd             :  in  std_logic_vector(RRSP_W*RPORT_NUM-1 downto 0);

    rd_rsp_dvld             : out  std_logic_vector(RPORT_NUM-1 downto 0);
    rd_rsp_data             : out  std_logic_vector(DDRD_W-1 downto 0);
    rd_rsp_retcmd           : out  std_logic_vector(RRSP_W-1 downto 0);
    rd_rsp_lastw            : out  std_logic := '0'; ---_vector(RPORT_NUM-1 downto 0);   --last word
    rd_rsp_firstw           : out  std_logic := '0' ; ---_vector(RPORT_NUM-1 downto

    ---write port -----------------------------------------
    wr_vsync_neg_sys    : in   std_logic_vector(WPORT_NUM-1    downto 0 );
    wr_req             : IN    std_logic_vector(WPORT_NUM-1 downto 0) ;
    wr_ack             : OUT   std_logic_vector(WPORT_NUM-1 downto 0) ;

    wr_cmd             : IN   std_logic_vector(WPORT_NUM*WRC_W-1 downto 0);
    wr_abort           : IN   std_logic_vector(WPORT_NUM-1 downto 0) ;
    wr_lastw           : IN   std_logic_vector(WPORT_NUM-1 downto 0) ;
    wr_data            : IN   std_logic_vector(WPORT_NUM*DDRD_W-1 downto 0);
    wr_wren            : IN   std_logic_vector(WPORT_NUM-1 downto 0) ;
    wr_mask            : IN   std_logic_vector( WPORT_NUM*(DDRD_W/8)-1 downto 0) ;


    bad_read_flag      : out std_logic ;
    bad_write_flag     : out std_logic

);
end component ;


component ddr_rst_ctrl is
generic(
	DDR_GROUP_NUM						: integer:= 2
);
port(
	nRST								: in  std_logic;
	sysclk								: in  std_logic;
	time_ms_en							: in  std_logic;
	--input	
	ddr_verify_end						: in  std_logic_vector(DDR_GROUP_NUM-1 downto 0);
	ddr_verify_success					: in  std_logic_vector(DDR_GROUP_NUM-1 downto 0);
	--output
	sys_ddr_ip_nrst						: out std_logic;
	sys_ddr_core_nrst					: out std_logic                         
);
end component;

signal delay_cnt      : std_logic_vector(7 downto 0):=(others=>'0');
signal rd_length_cnt      : std_logic_vector(6 downto 0):=(others=>'0');
signal time_ms_en : std_logic;
signal time_cnt   : std_logic_vector(19 downto 0);
signal ddr_verify_end     : std_logic_vector(DDR_NUM-1 downto 0);
signal ddr_verify_success : std_logic_vector(DDR_NUM-1 downto 0);
signal global_ip_reset_n_buf : std_logic_vector(DDR_NUM-1 downto 0);
signal A_sys_ddr_ip_nrst  : std_logic;
signal A_sys_ddr_core_nrst  : std_logic;
signal global_core_reset_n_buf : std_logic_vector(DDR_NUM-1 downto 0);
signal RST                     : std_logic;


signal  ddr_rd_req                 :    std_logic_vector(DDR_NUM-1 downto 0);
signal  ddr_rd_ack                 :    std_logic_vector(DDR_NUM-1 downto 0);
signal  ddr_rd_reqcmd              :    std_logic_vector(DDR_NUM*CREQ_W-1 downto 0);
signal  ddr_rd_respcmd             :    std_logic_vector(DDR_NUM*CRSP_W-1 downto 0);
signal  ddr_rd_rsp_dvld             :   std_logic_vector(DDR_NUM-1 downto 0);
signal  ddr_rd_rsp_data             :   std_logic_vector(DDR_NUM*DDR_DW-1   downto 0);
signal  ddr_rd_rsp_retcmd           :   std_logic_vector(DDR_NUM*CRSP_W-1 downto 0);
signal  ddr_rd_rsp_lastw            :   std_logic_vector(DDR_NUM-1 downto 0):=(others=>'0');
signal  ddr_rd_rsp_firstw           :   std_logic_vector(DDR_NUM-1 downto 0):=(others=>'0');

signal ddr_wr_req             :    std_logic_vector(DDR_NUM-1 downto 0) ;
signal ddr_wr_ack             :    std_logic_vector(DDR_NUM-1 downto 0) ;
signal ddr_wr_cmd             :   std_logic_vector(DDR_NUM*WRC_W-1 downto 0);
signal ddr_wr_abort           :   std_logic_vector(DDR_NUM-1 downto 0) ;
signal ddr_wr_lastw           :   std_logic_vector(DDR_NUM-1 downto 0) ;
signal ddr_wr_data            :   std_logic_vector(DDR_NUM*DDR_DW-1 downto 0);
signal ddr_wr_wren            :   std_logic_vector(DDR_NUM-1 downto 0) ;
signal ddr_wr_mask            :   std_logic_vector(DDR_NUM*(DDR_DW/8)-1 downto 0) ;



begin 

ddr3_wr_inst: shutter_ddr3_wr 
generic map
(  
	WRC_W       => WRC_W  ,
	DDRD_W      => DDRD_W ,
	DDR_AW      => DDR_AW
	
)
port map
(
    nRST                  => nRST      ,    
    clk                   => clk       ,    
	                                      
	pframe_en             => pframe_en ,    
	pwren                 => pwren     ,    
	paddr                 => paddr     ,    
	pdata                 => pdata     ,    
	                                       
    wr_req                => wr_req    ,    
    wr_ack                => wr_ack    ,    
                                           
    wr_cmd                => wr_cmd    ,    
    wr_abort              => wr_abort  ,    
    wr_lastw              => wr_lastw  ,    
    wr_data               => wr_data   ,    
    wr_wren               => wr_wren   ,    
    wr_mask               => wr_mask   ,
	real_eth_num_conv     => real_eth_num_conv
				
);

ddr3_rd_inst: shutter_ddr3_rd 
generic map
(  
	WRC_W       => WRC_W      ,
	DDRD_W      => DDRD_W     ,
	DDR_AW      => DDR_AW     ,
	CREQ_W      => CREQ_W     ,
	CRSP_W      => CRSP_W     ,
	TAGW        => TAGW       ,
	GRP_NUM     => GRP_NUM    ,
	GRP_SIZE    => GRP_SIZE
)
port map
(
    nRST                    => nRST                ,      
    clk                     => clk                 ,  
	                                                 
	pframe_en               => pframe_en           ,  
	pwren                   => pwren               ,  
	paddr                   => paddr               ,  
	pdata                   => pdata               ,  
	                                                 
	                                                 
	shutter_rd_req          => shutter_rd_req      ,  
	shutter_rd_ack          => shutter_rd_ack      ,  
	shutter_rd_frm_index    => shutter_rd_frm_index,  
	shutter_rd_eth_index    => shutter_rd_eth_index,  
	shutter_rsp_data        => shutter_rsp_data    ,  
	shutter_rsp_dvld        => shutter_rsp_dvld    ,  
	shutter_rd_end          => shutter_rd_end,
	shutter_rd_frmvld       => shutter_rd_frmvld,
	                                                
	                                                 
    rd_req                  => rd_req              ,  
    rd_ack                  => rd_ack              ,  
    rd_reqcmd               => rd_reqcmd           ,  
    rd_respcmd              => rd_respcmd          ,  
                                                     
    rd_rsp_dvld             => rd_rsp_dvld         ,  
    rd_rsp_data             => rd_rsp_data         ,  
    rd_rsp_retcmd           => rd_rsp_retcmd       ,  
    rd_rsp_lastw            => rd_rsp_lastw        ,  
    rd_rsp_firstw           => rd_rsp_firstw       ,  
    rd_rsp_prefirstw        => rd_rsp_prefirstw     ,
	real_eth_num_conv       => real_eth_num_conv
				
);

ddr_verify_end_o     <= ddr_verify_end;
ddr_verify_success_o <= ddr_verify_success;

ddr_rst_ctrl_A_inst: ddr_rst_ctrl
generic map(
	DDR_GROUP_NUM						=> 1
)
port map(  
	nRST								=> nRST						,				
	sysclk								=> clk				    ,
	time_ms_en							=> time_ms_en			,

	ddr_verify_end						=> ddr_verify_end(0 downto 0)		,
	ddr_verify_success					=> ddr_verify_success(0 downto 0)	,

	sys_ddr_ip_nrst						=> A_sys_ddr_ip_nrst		,
	sys_ddr_core_nrst					=> A_sys_ddr_core_nrst		
);


global_reset_n             <= global_ip_reset_n_buf;
global_ip_reset_n_buf(0)   <= A_sys_ddr_ip_nrst;
global_core_reset_n_buf(0) <= A_sys_ddr_core_nrst;

RST <= not nRST;
process(nRST,clk)
begin
	if nRST = '0' then
		time_cnt   <= (others=>'0');
		time_ms_en <= '0';
	elsif rising_edge(clk) then
		--if time_cnt = 200000 then--200M
		if time_cnt = 230000 then--230M
		
			time_ms_en <= '1';
			time_cnt   <= (others=>'0');
		else
			time_ms_en <= '0';
			time_cnt   <= time_cnt +1;
		end if;
	end if;
end process;

DDR_GEN: for i in 0 to DDR_NUM-1 generate
DDRb_i: ddr_bus_top
generic map
(
    SIM             => '0' ,
    DDRB_RSTALL_EN  => '0' ,
    READ_RST_ONLY   => '1' ,
    ASYNC_MODE      => '0' , --DDR3 IS async mode or not , '1': async ,'0: sync
    READ_HIGH_PRIO  => '0' ,  --'0' : write higher , '1': read higher priority
    WRC_W           => WRC_W  , --WRite command FIFO width
    RRC_W           => CREQ_W  ,  --READ req command  FIFO width  ;
    RRSP_W          => CRSP_W ,  --READ rsp command  FIFO width  ;
    DDRA_W          => DDR_AW  ,  --DDR address
    DDRD_W          => DDR_DW  ,  --ddr daa
    TAGW            => TAGW ,
    RPORT_NUM       => DDR_RDPORT_NUM ,
    WPORT_NUM       => DDR_WRPORT_NUM ,
    BURST_W         => 7     ---NOT SUPPROTED YET
)
port MAP
(
    ddrb_vsync_neg_ddr => RST, ----ddrB_vsync_neg_ddr ,  --20171103 wangac
    ------------------------------
	sys_ddr_core_nrst  => global_core_reset_n_buf(i),
	ddr_verify_end     => ddr_verify_end(i),
	ddr_verify_success => ddr_verify_success(i),	
    global_reset_n     => global_ip_reset_n_buf(i) , ----  t the ddr control & recalib
    ddr3_pll_locked    => ddr3_pll_locked   (i) , ----
    local_cal_success  => local_cal_success (i) , ----     //           status.local_cal_success, When high, indicates that PHY calibration was successful
    local_cal_fail     => local_cal_fail    (i) , ----        //                 .local_cal_fail,    When high, indicates that PHY calibration failed
    emif_usr_reset_n   => emif_usr_reset_n  (i) , ----      // emif_usr_reset_n.reset_n,           Reset for the user clock domain. Asynchronous assertion and synchronous deassertion
    emif_usr_clk       => emif_usr_clk      (i) , ----          //     emif_usr_clk.clk,               User clock domain
    amm_ready_0        => amm_ready_0       (i) , ----  '1' : ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
    amm_read_0         => amm_read_0        (i) , ----     ; ---- active high ,          //                 .read,              Read request signal
    amm_write_0        => amm_write_0       (i) , ----     ; ---- active high,         //                 .write,             Write request signal
    amm_address_0      => amm_address_0      ((i+1)*DDR_AW -1        downto i*DDR_AW    ) , --[22:0]    ; ----   ,       //                 .address,           Address for the read/write request
    amm_readdata_0     => amm_readdata_0     ((i+1)*DDR_DW-1         downto i*DDR_DW ) , --[319:0]   ; ----   ,      //                 .readdata,          Read data
    amm_writedata_0    => amm_writedata_0    ((i+1)*DDR_DW-1         downto i*DDR_DW ) , -- [319:0]  ; ----   ,     //                 .writedata,         Write data
    amm_burstcount_0   => amm_burstcount_0   ((i+1)*BURST_W-1        DOWNTO i*BURST_W    ) , -- [6:0]    ; ----       ,    //                 .burstcount,        Number of transfers in each read/write burst
    amm_byteenable_0   => amm_byteenable_0   ((i+1)*(DDR_DW/8)-1     Downto i*(DDR_DW/8)) , -- [39:0]   ; ----       ,    //                 .byteenable,        Byte-enable for write data
    amm_readdatavalid_0=> amm_readdatavalid_0(i) ,
	
	check_amm_readdatavalid_0 => amm_readdatavalid_0(i) ,
	check_amm_readdata_0      => amm_readdata_0((i+1)*DDR_DW-1 downto i*DDR_DW ) ,

    sys_nRST    => nRST ,
    sysclk1     => clk ,
    sysclk2     => clk ,
    ---ddr3
    op_ddr_dur              => '0' ,    --prohibit others ddr op
    op_ddr_req              => '0'          , ----
    op_ddr_ack              => OPEN         , ----
    op_ddr_end              => OPEN         , ----s ending ......
    op_ddr_cmd              => '0'          , ----
    op_sys2ddr_addr         => (OTHERS=>'0')        , ----
    op_sys2ddr_rden         => OPEN     , ----
    op_sys2ddr_q            => (OTHERS=>'0')            , ----
    op_ddr2sys_wren         => OPEN     , ----
    op_ddr2sys_data         => OPEN     , ----

   -----read port -----------------------------------

    rd_vsync_neg_sys       => (OTHERS=>'0') ,
    rd_req                 => ddr_rd_req((i+1)*DDR_RDPORT_NUM-1 downto i*DDR_RDPORT_NUM) ,
    rd_ack                 => ddr_rd_ack((i+1)*DDR_RDPORT_NUM-1 downto i*DDR_RDPORT_NUM)       ,
    rd_reqcmd              => ddr_rd_reqcmd((i+1)*CREQ_W*DDR_RDPORT_NUM-1 downto i*CREQ_W*DDR_RDPORT_NUM)     ,
    rd_respcmd             => ddr_rd_respcmd((i+1)*CRSP_W*DDR_RDPORT_NUM-1 downto i*CRSP_W*DDR_RDPORT_NUM)    ,
    rd_rsp_dvld            => ddr_rd_rsp_dvld((i+1)*DDR_RDPORT_NUM-1 downto i*DDR_RDPORT_NUM)  ,
    rd_rsp_data            => ddr_rd_rsp_data((i+1)*DDR_DW-1 downto i*DDR_DW),
    rd_rsp_retcmd          => ddr_rd_rsp_retcmd((i+1)*CRSP_W-1 downto i*CRSP_W),
    rd_rsp_lastw           => ddr_rd_rsp_lastw(i) ,
    rd_rsp_firstw          => ddr_rd_rsp_firstw(i),


    wr_vsync_neg_sys   => (OTHERS=>'0') ,
    wr_req             => ddr_wr_req((i+1)*DDR_WRPORT_NUM-1 downto i*DDR_WRPORT_NUM),
    wr_ack             => ddr_wr_ack((i+1)*DDR_WRPORT_NUM-1 downto i*DDR_WRPORT_NUM),
    wr_cmd             => ddr_wr_cmd((i+1)*DDR_WRPORT_NUM*WRC_W-1 downto i*DDR_WRPORT_NUM*WRC_W),
    wr_abort           => ddr_wr_abort((i+1)*DDR_WRPORT_NUM-1 downto i*DDR_WRPORT_NUM),
    wr_lastw           => ddr_wr_lastw((i+1)*DDR_WRPORT_NUM-1 downto i*DDR_WRPORT_NUM),
    wr_data            => ddr_wr_data((i+1)*DDR_WRPORT_NUM*DDR_DW-1 downto i*DDR_WRPORT_NUM*DDR_DW),
    wr_wren            => ddr_wr_wren((i+1)*DDR_WRPORT_NUM-1 downto i*DDR_WRPORT_NUM),
    wr_mask            => ddr_wr_mask((i+1)*DDR_WRPORT_NUM*(DDR_DW/8)-1 downto i*DDR_WRPORT_NUM*(DDR_DW/8)),


    bad_read_flag     => open,    
    bad_write_flag    => open

);
end generate DDR_GEN;

ddr_rd_req(0)<= rd_req;
ddr_rd_reqcmd(CREQ_W-1 downto 0) <= rd_reqcmd;
ddr_rd_respcmd(CRSP_W-1 downto 0) <= rd_respcmd;
ddr_rd_rsp_lastw(0) <= rd_rsp_lastw;
ddr_rd_rsp_firstw(0) <= rd_rsp_firstw;


rd_ack      <= ddr_rd_ack(0);
rd_rsp_dvld <= ddr_rd_rsp_dvld(0);
rd_rsp_data <= ddr_rd_rsp_data(DDR_DW-1 downto 0);
rd_rsp_retcmd <= ddr_rd_rsp_retcmd(CRSP_W-1 downto 0);

ddr_wr_req(0)  <= wr_req;
ddr_wr_wren(0) <= wr_wren;
ddr_wr_cmd(WRC_W-1 downto 0)<= wr_cmd;
ddr_wr_data(DDR_DW-1 downto 0)<= wr_data;
ddr_wr_mask(DDR_DW/8-1 downto 0)<= wr_mask;
ddr_wr_abort(0) <=wr_abort;
ddr_wr_lastw(0) <=wr_lastw;




wr_ack <= ddr_wr_ack(0);
				
end beha ;