library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ddr_bus_top is
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
  --- op_ddr_dur_SYS     : in std_logic ;  --20171103 wangac
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
	
	check_amm_readdatavalid_0 : in   std_logic       ;
	check_amm_readdata_0      : in   std_logic_vector(DDRD_W-1 downto 0);
   --ddr3_init_done_i          : in  std_logic;  --from ddr3 control, pulse only
   ---ddr3_init_done_level_o : out  std_logic := '0';  ---level output ------

    sys_nRST  : in std_logic ;
    sysclk1   : in std_logic ;
    sysclk2   : in std_logic ;
     --ddr3
	op_ddr_dur				: in  std_logic;	--prohibit other ddr op
	--quick upgrade
	op_ddr_req				: in  std_logic;
	op_ddr_ack				: out std_logic;
	op_ddr_end				: out std_logic;   --indicatet read is ending ......
	op_ddr_cmd				: in  std_logic;	--0:wr ,1:rd
	op_sys2ddr_addr			: in  std_logic_vector(25 downto 0);
	op_sys2ddr_rden			: out std_logic; ---DDR write
	op_sys2ddr_q			: in  std_logic_vector(255 downto 0);
	op_ddr2sys_wren			: out std_logic; ---DDR READ
	op_ddr2sys_data			: out std_logic_vector(255 downto 0);

    ------------read port -----------------------------------
    -- rd_nRST                :  in  std_logic ;
    -- rd_clk                 :  in  std_logic ;4
    rd_vsync_neg_sys        :  in  std_logic_vector(RPORT_NUM-1 downto 0) ;
     rd_req                 :  in  std_logic_vector(RPORT_NUM-1 downto 0);
     rd_ack                 :  out std_logic_vector(RPORT_NUM-1 downto 0);
     rd_reqcmd              :  in  std_logic_vector(RRC_W*RPORT_NUM-1 downto 0);
     rd_respcmd             :  in  std_logic_vector(RRSP_W*RPORT_NUM-1 downto 0);
    --- rd_abort               : out std_logic ;

    rd_rsp_dvld             : out  std_logic_vector(RPORT_NUM-1 downto 0);
    rd_rsp_data             : out  std_logic_vector(DDRD_W-1 downto 0);
    rd_rsp_retcmd           : out  std_logic_vector(RRSP_W-1 downto 0);
    rd_rsp_lastw            : out  std_logic := '0'; ---_vector(RPORT_NUM-1 downto 0);   --last word
    rd_rsp_firstw           : out  std_logic := '0' ; ---_vector(RPORT_NUM-1 downto

    ---write port -----------------------------------------
    --wr_nRST                :  in  std_logic ;
    ---wr_clk                 :  in  std_logic ;
    wr_vsync_neg_sys    : in   std_logic_vector(WPORT_NUM-1    downto 0 );
  --data from outside ----------data moved to ddr
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
end ddr_bus_top;

architecture beha_bus_top of ddr_bus_top is
component write_cmd_arb  is
generic
(
   DDRB_RSTALL_EN  :  std_logic := '0';  -- if '1', all vsync are same -----
   READ_RST_ONLY   :   STD_LOGIC ;
   SIM       : std_logic := '0' ;
   WPORT_NUM : integer   := 2   ;
   D_W       : integer   := 256 ;
   A_W       : integer   := 26  ;
   C_W       : integer   := 43
);
port
(
  ddrb_vsync_neg_ddr : in std_logic ;  --20171103 wangac
  -------------------------------------------------------------
  ddrc_rdy_sys :in std_logic ;
  sys_nRST : in std_logic ;
  sysclk   : in std_logic ;


  wr_vsync_sys      : in   std_logic_vector(WPORT_NUM-1    downto 0 );
  --data from outside ----------data moved to ddr
     wr_req             : IN    std_logic_vector(WPORT_NUM-1 downto 0) ;
     wr_ack             : OUT   std_logic_vector(WPORT_NUM-1 downto 0) ;

     wr_cmd             : IN   std_logic_vector(WPORT_NUM*C_W-1 downto 0);
     wr_abort           : IN   std_logic_vector(WPORT_NUM-1 downto 0) ;
     wr_lastw           : IN   std_logic_vector(WPORT_NUM-1 downto 0) ;
     wr_data            : IN   std_logic_vector(WPORT_NUM*D_W-1 downto 0);
     wr_wren            : IN   std_logic_vector(WPORT_NUM-1 downto 0) ;
     wr_mask            : IN   std_logic_vector( WPORT_NUM*(D_W/8)-1 downto 0) ;

   --ddr3
	op_ddr_dur				: in  std_logic;	--prohibit other ddr op
	--quick upgrade
	op_ddr_req				: in  std_logic;
	op_ddr_ack				: out std_logic;
	op_ddr_end				: out std_logic;   --indicatet read is ending ......
	op_ddr_cmd				: in  std_logic;	--0:wr ,1:rd
	op_sys2ddr_addr			: in  std_logic_vector(25 downto 0);
	op_sys2ddr_rden			: out std_logic;
	op_sys2ddr_q			: in  std_logic_vector(255 downto 0);


   ---write queue interface
   ddr3_nRST            : in     std_logic ;
   ddr3_clk             : in     std_logic ;
   -- ddrc_rdy_in          : in     std_logic ;   ---DDR controller is ready now ......
   --write command fifo -----
   wrc_cmdfifo_empty    : out    std_logic ;
   wrc_cmdfifo_rden     : in     std_logic ;
   wrc_cmdfifo_q        : out    std_logic_vector(C_W-1 downto 0);
   --data dpram and mask dpram to DDR
   wrd_raddr            : in     std_logic_vector(8 downto 0);
   wrd_rdata            : out    std_logic_vector(D_W-1 downto 0);
   wrd_be               : out    std_logic_vector((D_W/8)-1 downto 0);  --mask fifo (, bit6: start or last, others , offset)
   wrd_rden             : in     std_logic  ;
   wrd_rdaddr_stall     : in     std_logic ;
   wrd_rdoutclk_en      : in     std_logic ;
   wrd_rdinclk_en       : in     std_logic
);
end component;


component read_cmd_arb is
generic (
   DDRB_RSTALL_EN  :  std_logic := '0';
   READ_RST_ONLY   :   STD_LOGIC ;
   SIM       : std_logic := '0';
   RPORT_NUM : integer := 4;
   D_W       : integer := 256 ;
   A_W       : integer := 26 ;
   TAGW      : integer := 4  ;
   CREQ_W    : integer := 30 ;
   CRSP_W    : integer := 29
);

port
(
    ddrb_vsync_neg_ddr : in std_logic ;  --20171103 wangac
    -------------------------------------------------------------
    sys_nRST        : in std_logic ;
    sysclk          : in std_logic ;
    ddrc_rdy_sys    : in std_logic ;
    global_reset_n  : in std_logic; ---whichi clock domain....
    vsync_neg_sys   : in  std_logic_vector(RPORT_NUM-1 downto 0) ;


      --ddr3
	op_ddr_dur				: in  std_logic;	--prohibit other ddr op
	--quick upgrade
	op_ddr_req				: in  std_logic;
	op_ddr_ack				: out std_logic;
	op_ddr_end				: out std_logic;   --indicatet read is ending ......
	op_ddr_cmd				: in  std_logic;	--0:wr ,1:rd
	op_sys2ddr_addr			: in  std_logic_vector(25 downto 0);
	op_ddr2sys_wren			: out std_logic;
    --only use the 256bit
	op_ddr2sys_data			: out std_logic_vector(255 downto 0);

  --read queue interface
    ddr3_nRST            : in     std_logic ;
    ddr3_clk             : in     std_logic ;
    rrc_cmdfifo_empty    : out    std_logic  ; --at most
    rrc_cmdfifo_rdusedw  : out    std_logic_vector(4 downto 0) ; --at most
    rrc_cmdfifo_rden     : in    std_logic ;
    rrc_cmdfifo_q        : out     std_logic_vector(CREQ_W-1 downto 0);
    rrd_wdata            : in     std_logic_vector(D_W-1     downto 0);
    rrd_wren             : in     std_logic ;
    rrd_wrusedw          : out    std_logic_vector(12 downto 0) ;
   -------data fifo to ouside
   ----  ddrc_rdy_in             : in  std_logic ; --ddr3 clock domain only

     rd_req                 :  in  std_logic_vector(RPORT_NUM-1 downto 0);
     rd_ack                 :  out std_logic_vector(RPORT_NUM-1 downto 0);
     rd_reqcmd              :  in  std_logic_vector(CREQ_W*RPORT_NUM-1 downto 0);
     rd_respcmd             :  in  std_logic_vector(CRSP_W*RPORT_NUM-1 downto 0);
    --- rd_abort               : out std_logic ;

    rd_rsp_dvld             : out  std_logic_vector(RPORT_NUM-1 downto 0);
    rd_rsp_data             : out  std_logic_vector(D_W-1 downto 0);
    rd_rsp_retcmd           : out  std_logic_vector(CRSP_W-1 downto 0);
    rd_rsp_lastw            : out  std_logic := '0'; ---_vector(RPORT_NUM-1 downto 0);   --last word
    rd_rsp_firstw           : out  std_logic := '0'  ---_vector(RPORT_NUM-1 downto
 );
 end component ;


component scheduler_b is
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
        --ddr3_init_done_i          : in  std_logic;  --from ddr3 control, pulse only
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
end component ;

signal ddr3_init_done_level_ddr: std_logic;
---write queue interface
signal   wrc_cmdfifo_empty    :     std_logic ;
signal   wrc_cmdfifo_rden     :     std_logic :='0';
signal   wrc_cmdfifo_q        :     std_logic_vector(WRC_W-1 downto 0);

signal   wrd_raddr            :     std_logic_vector(8 downto 0);
signal   wrd_rdata            :     std_logic_vector(DDRD_W-1 downto 0);
signal   wrd_rden_o           :     std_logic ;
signal   wrd_raddr_stall      :     std_logic ; --rdaddr stall
signal   wrd_rdoutclk_en      :     std_logic ; --q out clk en
signal   wrd_rdinclk_en       :     std_logic ; --rdclken
signal   wrd_byteen           :     std_logic_vector((DDRD_W/8)-1 downto 0);  --mask fifo (, bit6: start or last, others , offset)
    ---wrd_rden             : out   std_logic :='0';

    --read queue interface
signal   rrc_cmdfifo_empty  :    std_logic  ; --at most
signal   rrc_cmdfifo_rdusedw:    std_logic_vector(4 downto 0);
signal   rrc_cmdfifo_rden   :    std_logic :='0';
signal   rrc_cmdfifo_q      :    std_logic_vector(RRC_W-1 downto 0);

signal   rrd_wdata          :     std_logic_vector(DDRD_W-1 downto 0);
signal   rrd_wren           :     std_logic := '0';
signal   rrd_wrusedw        :     std_logic_vector(12 downto 0);

  component altera_std_synchronizer is  
  port   
     (
				    clk : in std_logic ;
				reset_n : in std_logic ; 
				din     : in std_logic ;
				dout    : out std_logic
				);  
 end component; 


signal ddrc1_rdy_d : std_logic_vector(3 downto 0) := (others=>'0');
signal ddrc2_rdy_d : std_logic_vector(3 downto 0) := (others=>'0');
signal op_ddr_req_buf			: std_logic:= '0';
signal op_ddr_rd_end			: std_logic:= '0';
signal op_ddr_wr_end			: std_logic:= '0';
signal op_ddr_ack_rd_buf			: std_logic:= '0';
signal op_ddr_ack_wr_buf			: std_logic:= '0';
signal op_sys2ddr_addr_buf		: std_logic_vector(25 downto 0);
signal ddrc_rdy_sys1             : std_logic ;  --2021 
signal ddrc_rdy_sys2             : std_logic ;--2021 

attribute syn_keep : boolean;
attribute syn_srlstyle : string;
---20170816 wangac
attribute syn_keep of ddrc1_rdy_d: signal is true;
attribute syn_keep of ddrc2_rdy_d: signal is true;


--2021
attribute altera_attribute : string;
attribute altera_attribute of ddrc1_rdy_d : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;
attribute altera_attribute of ddrc2_rdy_d : signal is "-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON" ;

begin

 --   process(sys_nRST,sysclk)
 --   begin
 --       if sys_nRST = '0' then
 --           op_ddr_req_buf <= '0';

 --       elsif rising_edge(sysclk) then
	--		if op_ddr_ack_rd_buf = '1' or op_ddr_ack_wr_buf = '1'  then
	--			op_ddr_req_buf <= '0';
	--		elsif op_ddr_req = '1'  then
	--			op_ddr_req_buf <= '1';
	--		end if;

	--	end if;
	--end process;
	op_ddr_ack <= op_ddr_ack_rd_buf or op_ddr_ack_wr_buf ;
    op_ddr_end <= op_ddr_rd_end     or op_ddr_wr_end ;
    op_sys2ddr_addr_buf <= op_sys2ddr_addr;

    
      rdy_i: altera_std_synchronizer    
  port map 
     (
				clk => sysclk1 , 
				reset_n => sys_nRST, 
				din     => ddr3_init_done_level_ddr,
				dout    => ddrc1_rdy_d(0)
				); 

   -- ddrc_rdy_sys1 <= ddrc1_rdy_d(3);
    process(sys_nRST,sysclk1)
   begin
        if sys_nRST = '0' then
            -- ddrc1_rdy_d <= (others=>'0');
			ddrc_rdy_sys1 <= '0';
        elsif rising_edge(sysclk1) then
            -- ddrc1_rdy_d <= ddrc1_rdy_d(2 downto 0)&ddr3_init_done_level_ddr;
			ddrc_rdy_sys1 <= ddrc1_rdy_d(0);
        end if;
    end process;
	
	ddrc_rdy_sys2 <= ddrc2_rdy_d(3);  --2021 
	    process(sys_nRST,sysclk2)
   begin
        if sys_nRST = '0' then
            ddrc2_rdy_d <= (others=>'0');
        elsif rising_edge(sysclk2) then
            ddrc2_rdy_d <= ddrc2_rdy_d(2 downto 0)&ddr3_init_done_level_ddr;
        end if;
    end process;


 wr_arb_i: write_cmd_arb
generic map
(
   DDRB_RSTALL_EN  => DDRB_RSTALL_EN,  -- if '1', all vsync are same -----
   READ_RST_ONLY   => READ_RST_ONLY ,
   SIM        => SIM      ,
   WPORT_NUM  => WPORT_NUM,
   D_W        => DDRD_W ,
   A_W        => DDRA_W ,
   C_W        => WRC_W
)
port MAP
(
  ddrb_vsync_neg_ddr => ddrb_vsync_neg_ddr,  --20171103 wangac
  -------------------------------------------------------------
  ddrc_rdy_sys  => ddrc_rdy_sys1, ---2021
  sys_nRST      => sys_nRST,
  sysclk        => sysclk1  ,


  wr_vsync_sys      => wr_vsync_neg_sys      , ---to 0 );
  --data from outsid=> --data from outsid, ---
  wr_req            => wr_req            , ---
  wr_ack            => wr_ack            , ---

  wr_cmd            => wr_cmd            , ---
  wr_abort          => wr_abort          , ---
  wr_lastw          => wr_lastw          , ---
  wr_data           => wr_data           , ---
  wr_wren           => wr_wren           , ---
  wr_mask           => wr_mask           , ---

   --ddr3
	 --ddr3
  op_ddr_dur				=> op_ddr_dur,	--prohibit other ddr op
  --quick upgrade
  op_ddr_req				=> op_ddr_req_buf     ,
  op_ddr_ack				=> op_ddr_ack_wr_buf     ,
  op_ddr_end				=> op_ddr_wr_end         , --indicatet read is ending ......
  op_ddr_cmd				=> op_ddr_cmd         ,	--0:wr ,1:rd
  op_sys2ddr_addr			=> op_sys2ddr_addr_buf,
  op_sys2ddr_rden			=> op_sys2ddr_rden    ,
  op_sys2ddr_q		        => op_sys2ddr_q       ,


   ---write queue interface
   ddr3_nRST            => emif_usr_reset_n ,
   ddr3_clk             => emif_usr_clk     ,
   ---ddrc_rdy_in          => ,  ---DDR controller is ready now ......
   --write command fifo -----
   wrc_cmdfifo_empty    => wrc_cmdfifo_empty ,
   wrc_cmdfifo_rden     => wrc_cmdfifo_rden  ,
   wrc_cmdfifo_q        => wrc_cmdfifo_q     ,
   --data dpram and mask dpram to DDR
   wrd_raddr            => wrd_raddr  , ---: in     std_logic_vector(8 downto 0);
   wrd_rdata            => wrd_rdata  ,
   wrd_be               =>  wrd_byteen ,  --mask fifo (, bit6: start or last, others , offset)
   wrd_rden             =>  wrd_rden_o ,
   wrd_rdaddr_stall     =>  wrd_raddr_stall ,
   wrd_rdoutclk_en      =>  wrd_rdoutclk_en ,
   wrd_rdinclk_en       =>  wrd_rdinclk_en
);


 rd_arb_i:    read_cmd_arb
generic map (
   DDRB_RSTALL_EN   => DDRB_RSTALL_EN,
   READ_RST_ONLY    => READ_RST_ONLY,
   SIM              => SIM,
   RPORT_NUM        => RPORT_NUM ,
   D_W              => DDRD_W ,
   A_W              => DDRA_W ,
   TAGW             => TAGW ,
   CREQ_W           => RRC_W ,
   CRSP_W           => RRSP_W
)

port MAP
(
    ddrb_vsync_neg_ddr => ddrb_vsync_neg_ddr,  --20171103 wangac
    -------------------------------------------------------------
    sys_nRST        => sys_nRST ,
    sysclk          => sysclk2   ,
    ddrc_rdy_sys    => ddrc_rdy_sys2   ,  --2021
    global_reset_n  => global_reset_n , ---whichi clock domain....
    vsync_neg_sys   => rd_vsync_neg_sys ,


      --ddr3
		op_ddr_dur				=> op_ddr_dur ,	--prohibit other ddr op
	--quick upgrade
	op_ddr_req				 => op_ddr_req_buf     ,
	op_ddr_ack				 => op_ddr_ack_rd_buf     ,
	op_ddr_end				 => op_ddr_rd_end         , --indicatet read is ending ......
	op_ddr_cmd				 => op_ddr_cmd         ,	--0:wr ,1:rd
	op_sys2ddr_addr			 => op_sys2ddr_addr_buf,
	op_ddr2sys_wren			 => op_ddr2sys_wren ,
	op_ddr2sys_data			 => op_ddr2sys_data ,

  --read queue interface
    ddr3_nRST            => emif_usr_reset_n ,
    ddr3_clk             => emif_usr_clk    ,
    rrc_cmdfifo_empty    =>  rrc_cmdfifo_empty   ,
    rrc_cmdfifo_rdusedw  =>  rrc_cmdfifo_rdusedw ,
    rrc_cmdfifo_rden     =>  rrc_cmdfifo_rden    ,
    rrc_cmdfifo_q        =>  rrc_cmdfifo_q       ,
    rrd_wdata            =>  rrd_wdata           ,
    rrd_wren             =>  rrd_wren            ,
    rrd_wrusedw          =>  rrd_wrusedw         ,
   -------data fifo to ouside
   ----  ddrc_rdy_in             : in  std_logic ; --ddr3 clock domain only

     rd_req                 => rd_req    ,
     rd_ack                 => rd_ack    ,
     rd_reqcmd              => rd_reqcmd ,
     rd_respcmd             => rd_respcmd,
    --- rd_abort               : out std_logic ;

    rd_rsp_dvld             => rd_rsp_dvld    ,
    rd_rsp_data             => rd_rsp_data    ,
    rd_rsp_retcmd           => rd_rsp_retcmd  ,
    rd_rsp_lastw            => rd_rsp_lastw   ,   --last word
    rd_rsp_firstw           => rd_rsp_firstw
 );


  ddr_avalon_brg :scheduler_b
generic map
(
  DDRB_RSTALL_EN  => DDRB_RSTALL_EN, ----
  READ_RST_ONLY   => READ_RST_ONLY , ----
  ASYNC_MODE      => ASYNC_MODE    , ---- --DDR3 IS async mode or not , '1': async ,'0: sync
  READ_HIGH_PRIO  => READ_HIGH_PRIO, ----
  WRC_W           => WRC_W         , ----Rite command FIFO width
  RRC_W           => RRC_W         , -----READ command  FIFO width  ;
  DDRA_W          => DDRA_W        , ----
  DDRD_W          => DDRD_W        , ----
  BURST_W         => BURST_W       , ----
  RD_TWO_BURST_SUPPROT=> '0'   ---NOT SUPPROTED YET
)
port map
(
   ddrb_vsync_neg_ddr    =>ddrb_vsync_neg_ddr   ,  --20171103 wangac
   op_ddr_dur_SYS        =>op_ddr_dur         ,  --20171103 wangac
   ------------------------------------------
   
    sys_ddr_core_nrst  => sys_ddr_core_nrst,
	ddr_verify_end     => ddr_verify_end,
	ddr_verify_success => ddr_verify_success,
	
         global_reset_n      => global_reset_n      , --------reset the ddr control & recalib 
         ddr3_pll_locked     => ddr3_pll_locked     , -----
         local_cal_success   => local_cal_success   , -----; ----,   //           status.local_cal_success, When high, indicates that PHY calibration was successful
         local_cal_fail      => local_cal_fail      , -----; ----,      //                 .local_cal_fail,    When high, indicates that PHY calibration failed
         emif_usr_reset_n    => emif_usr_reset_n    , -----; ----,    // emif_usr_reset_n.reset_n,           Reset for the user clock domain. Asynchronous assertion and synchronous deassertion
         emif_usr_clk        => emif_usr_clk        , -----; ----,        //     emif_usr_clk.clk,               User clock domain
         amm_ready_0         => amm_ready_0         , -----; ---- '1' : ready, '0': not ready,         //       ctrl_amm_0.waitrequest_n,     Wait-request is asserted when controller is busy
         amm_read_0          => amm_read_0          , -----          ; ---- active high ,          //                 .read,              Read request signal
         amm_write_0         => amm_write_0         , -----          ; ---- active high,         //                 .write,             Write request signal
         amm_address_0       => amm_address_0       , -----_vector(DDRA_W-1 downto 0); --[22:0]    ; ----   ,       //                 .address,           Address for the read/write request
         amm_readdata_0      => amm_readdata_0      , -----_vector(DDRD_W-1 downto 0); --[319:0]   ; ----   ,      //                 .readdata,          Read data
         amm_writedata_0     => amm_writedata_0     , -----_vector(DDRD_W-1 downto 0); -- [319:0]  ; ----   ,     //                 .writedata,         Write data
         amm_burstcount_0    => amm_burstcount_0    , -----_vector(BURST_W-1 DOWNTO 0); -- [6:0]    ; ----       ,    //                 .burstcount,        Number of transfers in each read/write burst
         amm_byteenable_0    => amm_byteenable_0    , -----_vector((DDRD_W/8)-1 Downto 0); -- [39:0]   ; ----       ,    //                 .byteenable,        Byte-enable for write data
         amm_readdatavalid_0 => amm_readdatavalid_0 , -----       ;
        --ddr3_init_done_i          : in  std_logic;  --from ddr3 control, pulse only
        ddr3_init_done_level_o    => ddr3_init_done_level_ddr ,  ---level output ------
		check_amm_readdatavalid_0 => check_amm_readdatavalid_0,
	    check_amm_readdata_0      => check_amm_readdata_0,


   ---write queue interface
   wrc_cmdfifo_empty    => wrc_cmdfifo_empty ,
   wrc_cmdfifo_rden     => wrc_cmdfifo_rden  ,
   wrc_cmdfifo_q        => wrc_cmdfifo_q     ,

   wrd_raddr            => wrd_raddr         ,
   wrd_rdata            => wrd_rdata         ,
   wrd_rden_o           => wrd_rden_o        ,
   wrd_raddr_stall      => wrd_raddr_stall   ,
   wrd_rdoutclk_en      => wrd_rdoutclk_en   ,
   wrd_rdinclk_en       => wrd_rdinclk_en    ,
   wrd_byteen           => wrd_byteen        ,   --mask fifo (, bit6: start or last, others , offset)
   ---wrd_rden          => ---wrd_rden       ,

   --read queue interface
   rrc_cmdfifo_empty   => rrc_cmdfifo_empty  ,
   rrc_cmdfifo_rdusedw => rrc_cmdfifo_rdusedw,
   rrc_cmdfifo_rden    => rrc_cmdfifo_rden   ,
   rrc_cmdfifo_q       => rrc_cmdfifo_q      ,

   rrd_wdata           => rrd_wdata          ,
   rrd_wren            => rrd_wren           ,
   rrd_wrusedw         => rrd_wrusedw        ,


   bad_read_flag      => bad_read_flag ,
   bad_write_flag     => bad_write_flag
);


end beha_bus_top ;