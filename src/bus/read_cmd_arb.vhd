--####################################################################### 
--
--  REVISION HISTORY:  
--
--  Revision 0.1  2017/04/26  Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
 
--
--#######################################################################
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity  read_cmd_arb is 
generic (
   DDRB_RSTALL_EN  :  std_logic := '0';
   READ_RST_ONLY   :   STD_LOGIC ;
   SIM       : std_logic := '0';
   RPORT_NUM : integer := 4;
   BURST_W   : integer := 7;
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
	op_ddr2sys_data			: out std_logic_vector(255 downto 0);
    
  --read queue interface 
    ddr3_nRST            : in     std_logic ;
    ddr3_clk             : in     std_logic ;
    rrc_cmdfifo_empty    : out    std_logic  ; --at most 
    rrc_cmdfifo_rdusedw  : out    std_logic_vector(4 downto 0) ; --at most 
    rrc_cmdfifo_rden     : in    std_logic ;
    rrc_cmdfifo_q        : out     std_logic_vector(CREQ_W-1 downto 0);   
    rrd_wdata            : in     std_logic_vector(D_W-1 downto 0);
    rrd_wren             : in     std_logic ;
    rrd_wrusedw          : out    std_logic_vector(12 downto 0) ; 
   -------data fifo to ouside  
   ----  ddrc_rdy_in             : in  std_logic ; --ddr3 clock domain only
    load_pipe_en            :  out std_logic ;  
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
        
 
 end read_cmd_arb ;
 
 architecture beha of read_cmd_arb is 
 
 ---data fifo  
  signal  rrd_rdata          :    std_logic_vector(D_W-1 downto 0);
  signal  rrd_rden           :    std_logic :='0';
  signal  rrd_rdusedw        :    std_logic_vector(9 downto 0) ;
  signal  rrd_empty          :    std_logic  ;
 --req cmd fifo 
 signal rrc_cmdfifo_full     :      std_logic  ; --at most 
 signal rrc_cmdfifo_wrusedw  :      std_logic_vector(4 downto 0) ; --at most 
 signal rrc_cmdfifo_wren     :      std_logic := '0';
 signal rrc_cmdfifo_wdata    :      std_logic_vector(CREQ_W-1 downto 0);  
 
 signal respcmdfifo_wren     : std_logic := '0';
 signal respcmdfifo_wrusedw  : std_logic_vector(4 downto 0);
 signal respcmdfifo_wdata    : std_logic_vector(CRSP_W-1 DOWNTO 0);
 signal respcmdfifo_full     : std_logic;
 signal respcmdfifo_empty    : std_logic;
 signal respcmdfifo_rden     : std_logic := '0';
 signal respcmdfifo_rdata    : std_logic_vector(CRSP_W-1 downto 0);
 signal respcmdfifo_rdusedw  : std_logic_vector(4 downto 0);
 signal susp_reqcmd_cnt      : std_logic_vector(5 downto 0) := (others=>'0');
 
 
  
component ddr_rdreq_cmdfifo_pack is
    port (
        Data: in  std_logic_vector(CREQ_W-1 downto 0); 
        WrClock: in  std_logic; 
        RdClock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        RPReset: in  std_logic; 
        Q: out  std_logic_vector(CREQ_W-1 downto 0); 
        WCNT: out  std_logic_vector(4 downto 0); 
        RCNT: out  std_logic_vector(4 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic);
 end component ;
 
component ddr_rdresp_cmdfifo_pack is
generic 
(
  D_W :integer := 42
);
    port (
        Data: in  std_logic_vector(CRSP_W-1 downto 0); 
        Clock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        Q: out  std_logic_vector(CRSP_W-1 downto 0); 
        WCNT: out  std_logic_vector(4 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic);
 end component ;
 
 component ddr_rddata_fifo_pack is
    port (
        Data: in  std_logic_vector(D_W-1 downto 0); 
        WrClock: in  std_logic; 
        RdClock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        RPReset: in  std_logic; 
        Q: out  std_logic_vector(D_W-1 downto 0); 
        WCNT: out  std_logic_vector(9 downto 0); 
        RCNT: out  std_logic_vector(9 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic);
end component ;
signal rrd_t_wrusedw : std_logic_vector(9 downto 0);
 
 constant W_EXT_NUM  : integer := 16 ;
subtype index_range is INTEGER range 0 to W_EXT_NUM-1;
signal   hit_sel_one     : index_range := 0 ;
signal   arb_sel_one     : index_range := 0 ; 
signal   rd_ext_req      : std_logic_vector(W_EXT_NUM-1 downto 0) ;
signal   rd_ext_ack      : std_logic_vector(W_EXT_NUM-1 downto 0) ; ---at most 8 input request
signal   rd_ext_reqcmd   : std_logic_vector(W_EXT_NUM*CREQ_W-1 downto 0) ; ---at most 8 input request 
signal   rd_ext_rspcmd   : std_logic_vector(W_EXT_NUM*CRSP_W-1 downto 0) ; ---at most 8 input request 

 
 -- signal outfifo_aclr              :   std_logic_vector(RPORT_NUM-1     downto 0) ;
 -- signal outfifo_wren              :   std_logic_vector(RPORT_NUM-1     downto 0) ;
 -- signal outfifo_wrusedw           :   std_logic_vector(13*RPORT_NUM-1  downto 0);
 -- signal outfifo_wdata             :   std_logic_vector(D_W*RPORT_NUM-1 downto 0);
 -- signal outfifo_full              :   std_logic_vector(RPORT_NUM-1     downto 0) ;
    
 -- signal fifo_rst       : std_logic ;
 signal cmd_firstw     : std_logic := '0' ;
 signal cmd_lastw      : std_logic := '0' ;
 signal vld_mask0      : std_logic_vector(W_EXT_NUM-1 downto 0) :=(others=>'0');
 signal vld_mask1      : std_logic_vector(W_EXT_NUM-1 downto 0) :=(others=>'0');
 signal vld_mask2      : std_logic_vector(W_EXT_NUM-1 downto 0) :=(others=>'0');
 signal rd_cnt         : std_logic_vector(1 downto 0) := (others=>'0');
 signal rd_dly_firstw  : std_logic_vector(3 downto 0) := (others=>'0');
 signal rd_dly_lastw   : std_logic_vector(3 downto 0) := (others=>'0');
 signal req_sel_cmd   : std_logic_vector(CREQ_W-1 downto 0) := (others=>'0'); 
 signal rsp_sel_cmd   : std_logic_vector(CRSP_W-1 downto 0) := (others=>'0');
 signal rrc_upgrade_cmd   : std_logic_vector(CREQ_W-1 downto 0) := (others=>'0');
 signal rsp_upgrade_cmd   : std_logic_vector(CRSP_W-1 downto 0) := (others=>'0');
 type stat_def is (ST_IDLE,ST_SUBMIT);
 signal pstate : stat_def := ST_IDLE ;
 
   type rds_state is (RDS_IDLE, RDS_DISPATCH, RDS_DONE, RDS_WAIT, RDS_WAITDATA);
    signal rd_state : rds_state := RDS_IDLE ;
 
     signal expect_len256      : std_logic_vector(BURST_W-1 downto 0) ; --length 
     signal target_index       : std_logic_vector(4 downto 0) ;
     signal is_firstburst      : std_logic ;
     signal is_lastburst       : std_logic ;
     signal head_preboff       : std_logic_vector(5 downto 0) ; --byte off in 512bit
     signal tail_byteoff       : std_logic_vector(5 downto 0) ; --byte off in 512bit
     signal expect_tagid       : std_logic_vector(TAGW-1 downto 0);
     signal first_w_flg        : std_logic ;
     signal rd_rsp_prefirstw   : std_logic_vector(RPORT_NUM-1 downto 0) := (others=>'0');  
     signal fifo1_rst          : std_logic := '1';
     signal fifo2_rst          : std_logic := '1'; 
	 
	 signal  total_depthrow_filter     :    std_logic_vector(16*RPORT_NUM -1 downto 0) :=(others=>'0');
	 signal  total_depthrow_bitnum     :    std_logic_vector(16*RPORT_NUM -1 downto 0) :=(others=>'0');
     signal  vld_upgr0   : std_logic := '0';
     signal  vld_upgr1   : std_logic := '0';
     signal  vld_upgr2   : std_logic := '0';
     
     signal  op_ddr_end0   : std_logic := '0';
     signal  op_ddr_end1   : std_logic := '0';
     signal  op_ddr_end2   : std_logic := '0';
     
     constant op_ddr_valid_max    : integer := 32;
     signal   op_ddr_valid_cnt    : std_logic_vector(7 downto 0) := (others=>'0');
     constant UPGRADE_INDEX       : std_logic_vector(4 downto 0) := (others=>'1');
 
     signal    t_wait  : std_logic_vector(1 downto 0):=(others=>'0');
                                
signal ddrb_fifo_clear_sys     : std_logic := '1';
signal ddrb_clr_cnt_sys        : std_logic_vector(5 downto 0):=(others=>'0');
signal ddrb_fifo_clear_ddr     : std_logic := '1';
signal ddrb_clr_cnt_ddr        : std_logic_vector(5 downto 0):=(others=>'0');
	 
signal rd_wait : std_logic_vector(8 downto 0):= (others=>'0'); 
signal RST_CMB_FLAG : STD_LOGIC ;
signal op_ddr_dur_ddr : std_logic_vector(3 downto 0):= (others=>'0'); 
attribute syn_keep : boolean;
attribute syn_srlstyle : string;
---20170816 wangac
attribute syn_keep of op_ddr_dur_ddr : signal is true;

signal op_ddr_length : std_logic_vector(BURST_W-1 downto 0); ----(op_ddr_valid_max ,7)	 
 begin 

    op_ddr_length <= conv_std_logic_vector(op_ddr_valid_max ,BURST_W);
    
    RST_CMB_FLAG <= '1' WHEN DDRB_RSTALL_EN = '1' OR READ_RST_ONLY ='1' else '0';
    
     process(rd_req, rd_reqcmd,rd_respcmd,rd_ext_ack)
    begin  
        rd_ext_reqcmd <= (OTHERS=>'0');
        rd_ext_reqcmd(RPORT_NUM*CREQ_W-1 downto 0) <= rd_reqcmd ;
        
        rd_ext_rspcmd <= (OTHERS=>'0');
        rd_ext_rspcmd(RPORT_NUM*CRSP_W-1 downto 0) <= rd_respcmd ;
        -------------------------------------------------
        rd_ext_req <= (others=>'0'); 
        for i in 0 to RPORT_NUM-1 loop
            rd_ext_req(i)<= rd_req(i);
        end loop;
        rd_ack  <= (others=>'0' ) ;
        for i in 0 to RPORT_NUM-1 loop
            rd_ack(i) <= rd_ext_ack(i);
        end LOOP;
    end process;
    
process(rd_ext_req)
begin
    if rd_ext_req(0) = '1' then 
        arb_sel_one        <= 0; 
    elsif rd_ext_req(1) = '1' then 
        arb_sel_one <= 1; 
    elsif rd_ext_req(2) = '1' then 
        arb_sel_one <= 2; 
    elsif rd_ext_req(3) = '1' then 
        arb_sel_one <= 3; 
    elsif rd_ext_req(4) = '1' then 
        arb_sel_one <= 4 ; 
    elsif rd_ext_req(5) = '1' then 
        arb_sel_one <= 5; 
    elsif rd_ext_req(6) ='1' THEN
        arb_sel_one <= 6; 
    elsif rd_ext_req(7) = '1' then 
        arb_sel_one <= 7; 
    elsif rd_ext_req(0+8) = '1' then 
        arb_sel_one <= 0+8; 
    elsif rd_ext_req(1+8) = '1' then 
        arb_sel_one <= 1+8; 
    elsif rd_ext_req(2+8) = '1' then 
        arb_sel_one <= 2+8; 
    elsif rd_ext_req(3+8) = '1' then 
        arb_sel_one <= 3+8; 
    elsif rd_ext_req(4+8) = '1' then 
        arb_sel_one <= 4+8 ; 
    elsif rd_ext_req(5+8) = '1' then 
        arb_sel_one <= 5+8; 
    elsif rd_ext_req(6+8) ='1' THEN
        arb_sel_one <= 6+8; 
    elsif rd_ext_req(7+8) = '1' then 
        arb_sel_one <= 7+8; 
    else 
        arb_sel_one <= 0;
    end if;
end process;
    
process(arb_sel_one,rd_ext_reqcmd)
begin
    case arb_sel_one is
        when 0 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(0+1)-1 downto CREQ_W*(0));
        when 1 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(1+1)-1 downto CREQ_W*(1));
        when 2 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(2+1)-1 downto CREQ_W*(2));
        when 3 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(3+1)-1 downto CREQ_W*(3));
        when 4 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(4+1)-1 downto CREQ_W*(4));
        when 5 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(5+1)-1 downto CREQ_W*(5));
        when 6 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(6+1)-1 downto CREQ_W*(6));
        when 7 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(7+1)-1 downto CREQ_W*(7));
        when 8 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(8+1)-1 downto CREQ_W*(8));
        when 9 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(9+1)-1 downto CREQ_W*(9));
        when 10 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(10+1)-1 downto CREQ_W*(10));
        when 11 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(11+1)-1 downto CREQ_W*(11));
        when 12 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(12+1)-1 downto CREQ_W*(12));
        when 13 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(13+1)-1 downto CREQ_W*(13));
        when 14 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(14+1)-1 downto CREQ_W*(14));
        when 15 => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(15+1)-1 downto CREQ_W*(15));
        when others => req_sel_cmd <= rd_ext_reqcmd(CREQ_W*(0+1)-1 downto CREQ_W*(0));
    end case;
end process;
process(arb_sel_one,rd_ext_rspcmd)
begin
    case arb_sel_one is
        when 0 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(0+1)-1 downto CRSP_W*(0));
        when 1 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(1+1)-1 downto CRSP_W*(1));
        when 2 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(2+1)-1 downto CRSP_W*(2));
        when 3 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(3+1)-1 downto CRSP_W*(3));
        when 4 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(4+1)-1 downto CRSP_W*(4));
        when 5 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(5+1)-1 downto CRSP_W*(5));
        when 6 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(6+1)-1 downto CRSP_W*(6));
        when 7 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(7+1)-1 downto CRSP_W*(7));
        when 8 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(8+1)-1 downto CRSP_W*(8));
        when 9 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(9+1)-1 downto CRSP_W*(9));
        when 10 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(10+1)-1 downto CRSP_W*(10));
        when 11 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(11+1)-1 downto CRSP_W*(11));
        when 12 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(12+1)-1 downto CRSP_W*(12));
        when 13 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(13+1)-1 downto CRSP_W*(13));
        when 14 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(14+1)-1 downto CRSP_W*(14));
        when 15 => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(15+1)-1 downto CRSP_W*(15));
        when others => rsp_sel_cmd <= rd_ext_rspcmd(CRSP_W*(0+1)-1 downto CRSP_W*(0));
    end case;
end process;
      process(op_sys2ddr_addr,op_ddr_length) ----,op_ddr_valid_max)
      begin 
        --request fifo to DDR3 
         rrc_upgrade_cmd   <= (others=>'0');
         rrc_upgrade_cmd (A_W-1 downto 0) <= op_sys2ddr_addr(A_W+2-1 downto 2) ; --burst addr 
         -- rrc_upgrade_cmd (28 downto 23)<= conv_std_logic_vector(op_ddr_valid_max/2,6); -----how many burst number ;
         rrc_upgrade_cmd (34 downto 28)<= op_ddr_length  ; -----how many burst number ;
     
        -----resp cmd fifo
         rsp_upgrade_cmd <= (others=>'0');
         rsp_upgrade_cmd(5 DOWNTO 0 )  <= op_ddr_length(BURST_W-2 downto 0); ----,6); -----how many burst number ;
         rsp_upgrade_cmd(TAGW+24)      <= op_ddr_length(BURST_W-1);
         
         rsp_upgrade_cmd(9 downto  6 )   <= UPGRADE_INDEX(3 downto 0) ; ---index 
         rsp_upgrade_cmd(10) <= '1'; --first cmd 
         rsp_upgrade_cmd(11) <= '1'; --last 
         rsp_upgrade_cmd(17 downto 12 )       <= (others=>'0'); --start byte offset 
         rsp_upgrade_cmd(23 downto 18)        <= (others=>'0'); --end byte offset 
         rsp_upgrade_cmd(TAGW+24-1 downto 24)  <= (others=>'0');
         rsp_upgrade_cmd(43) <= UPGRADE_INDEX(4);
     end process;
       
      process(sys_nRST,sysclk)
      begin
            if sys_nRST = '0' then 
                    pstate <= ST_IDLE;
                    rd_ext_ack <= (others=>'0');
                    rrc_cmdfifo_wren         <= '0';
                    respcmdfifo_wren         <= '0';
                    hit_sel_one  <= 0;
                     op_ddr_ack               <= '0';
					 t_wait      <= (others=>'0');
					 rd_wait      <= (others=>'0');
            elsif rising_edge(sysclk) then 
                if ddrc_rdy_sys = '0' or (RST_CMB_FLAG= '1' AND vsync_neg_sys(0) ='1' and op_ddr_dur = '0') then 
                     pstate            <= ST_IDLE ;
                     rd_ext_ack        <= (others=>'0');
                     rrc_cmdfifo_wren  <= '0';
                     respcmdfifo_wren  <= '0';
                     hit_sel_one       <= 0;
                     op_ddr_ack               <= '0';
                     rd_wait           <= (others=>'0');
                     t_wait            <= (others=>'0');
                else
                    case(pstate) is
                        when ST_IDLE =>
                            t_wait      <= (others=>'0');
                            hit_sel_one <= arb_sel_one ;
                            rd_ext_ack <= (others=>'0');
                            --upgrade reading -------------------
                            op_ddr_ack               <= '0';
                            if rd_wait(8) = '0' then 
                                rd_wait <= rd_wait + 1 ;
                            end if;
                            if op_ddr_dur = '1' then 
                                if op_ddr_req = '1' and op_ddr_cmd = '1' and (respcmdfifo_wrusedw < 5 and respcmdfifo_full = '0') then --read 
                                    pstate <= ST_SUBMIT; 
                                    rrc_cmdfifo_wren         <= '1';
                                    respcmdfifo_wren         <= '1';
                                    op_ddr_ack               <= '1';
                                else
                                    pstate <= ST_IDLE ;
                                    op_ddr_ack               <= '0';
                                    rrc_cmdfifo_wren         <= '0';
                                    respcmdfifo_wren         <= '0';
                                end if;
                                --index is the max ok.....
                                rrc_cmdfifo_wdata  <=  rrc_upgrade_cmd;
                                respcmdfifo_wdata  <=  rsp_upgrade_cmd;
                            elsif (RST_CMB_FLAG= '1' and rd_wait(8) = '0') then 
                                pstate <= ST_IDLE ;
                                rrc_cmdfifo_wren         <= '0';
                                respcmdfifo_wren         <= '0';
                                rrc_cmdfifo_wdata  <= (others=>'0');
                                respcmdfifo_wdata  <= (others=>'0'); 
                            elsif rd_req /= 0 and (respcmdfifo_wrusedw < 5 and respcmdfifo_full='0' ) then 
                                pstate                   <= ST_SUBMIT;
                                rd_ext_ack(arb_sel_one ) <= '1';
                                rrc_cmdfifo_wren         <= '1';
                                respcmdfifo_wren         <= '1'; 
                                rrc_cmdfifo_wdata  <= req_sel_cmd;
                                respcmdfifo_wdata  <= rsp_sel_cmd;
                            else 
                                pstate <= ST_IDLE ;
                                rrc_cmdfifo_wren         <= '0';
                                respcmdfifo_wren         <= '0';
                                rrc_cmdfifo_wdata  <= (others=>'0');
                                respcmdfifo_wdata  <= (others=>'0');
                            end if;
                             
                        when ST_SUBMIT => --wait for fifo status updating....
                            rd_ext_ack <= (others=>'0');
                             op_ddr_ack               <= '0';
                            rrc_cmdfifo_wren         <= '0';
                            respcmdfifo_wren         <= '0';
                            t_wait      <=   t_wait + 1 ;
                            if t_wait(0) = '1' then 
                                pstate                   <= ST_IDLE ; 
                            else
                                pstate   <=  ST_SUBMIT;
                            end if;
                        When others=>
                            t_wait      <= (others=>'0');
                            pstate <= ST_IDLE ;
                            rd_ext_ack <= (others=>'0');
                            op_ddr_ack               <= '0';
                            rrc_cmdfifo_wren         <= '0';
                            respcmdfifo_wren         <= '0';
                    end case;
                end if;
            end if;      
      end process;
      

    --we may need to count the actual pending cmd (data) in data fifo 
    -- through submit and done pulse ()
    
       
    process(sys_nRST,sysclk)
    begin
        if sys_nRST = '0' then 
            susp_reqcmd_cnt <= (others=>'0');
            
        elsif rising_edge(sysclk) then 
            if vld_mask1 = 0 then
                rd_rsp_data   <= (others=>'0');
                rd_rsp_retcmd <= (others=>'0');
            else
                rd_rsp_data   <= rrd_rdata ;
                rd_rsp_retcmd <= respcmdfifo_rdata;
            end if;
            
            if ddrc_rdy_sys = '0' or (RST_CMB_FLAG ='1' AND (vsync_neg_sys(0) ='1') and op_ddr_dur ='0' ) then  
                susp_reqcmd_cnt <= (others=>'0');
            else
                if pstate = ST_SUBMIT and (rd_state = RDS_DONE and rrd_rden = '1' ) then 
                    susp_reqcmd_cnt <= susp_reqcmd_cnt;
                elsif pstate =ST_SUBMIT then 
                    susp_reqcmd_cnt <= susp_reqcmd_cnt + 1 ;
                elsif (rd_state = RDS_DONE and rrd_rden = '1' ) then 
                    susp_reqcmd_cnt <= susp_reqcmd_cnt - 1; 
                end if;    
            end if;
        end if;
    end process;
    
  
      
    process(sys_nRST,sysclk)
    begin
         if sys_nRST = '0' then 
                rd_state          <= RDS_IDLE ;
                rd_cnt            <= (others=>'0');
                rrd_rden          <= '0';
                vld_mask0         <= (others=>'0');
                vld_mask1         <= (others=>'0');
                vld_mask2         <= (others=>'0');
                rd_rsp_dvld       <= (others=>'0');
                rd_dly_firstw     <= (others=>'0');  --first word in the seg
                rd_rsp_prefirstw  <= (others=>'0');  --first word in the seg
                rd_dly_lastw      <= (others=>'0');
                --upgrade 
                 vld_upgr0  <= '0';
                 vld_upgr1  <= '0';
                 vld_upgr2  <= '0';
                 
                 op_ddr_end0  <= '0';
                 op_ddr_end1  <= '0';
                 op_ddr_end2  <= '0';
                 op_ddr_end   <= '0';
                  op_ddr2sys_wren <= '0';
                  load_pipe_en <= '0';
         elsif rising_edge(sysclk) then
                rd_dly_firstw <= rd_dly_firstw(2 downto 0) & cmd_firstw ;
                rd_dly_lastw  <= rd_dly_lastw (2 downto 0) & cmd_lastw ;
                
                op_ddr2sys_data <= rrd_rdata(255 DOWNTO 0);
                    
               IF ddrc_rdy_sys = '0'  or (RST_CMB_FLAG='1' AND ddrb_fifo_clear_sys = '1' and op_ddr_dur = '0'  ) then 
                    rd_state  <= RDS_IDLE ;
                    rd_cnt    <= (others=>'0');
                    rrd_rden  <= '0';
                    vld_mask0 <= (others=>'0');
                    vld_mask1 <= (others=>'0');
                    vld_mask2 <= (others=>'0');
                    cmd_firstw <= '0'; --first word in the seg
                    cmd_lastw  <= '0';
                    rd_rsp_dvld <= (others=>'0'); 
                    rd_rsp_prefirstw <= (others=>'0'); 
                  --upgrade 
                      vld_upgr0      <= '0';
                      vld_upgr1      <= '0';
                      vld_upgr2      <= '0';
                      op_ddr_end      <= '0';
                      op_ddr2sys_wren <= '0';
                      
                      op_ddr_end0  <= '0';
                      op_ddr_end1  <= '0';
                      op_ddr_end2  <= '0';
                      load_pipe_en <= '0';
                      respcmdfifo_rden <= '0';
               else
                    vld_mask1   <= vld_mask0;
                    vld_mask2   <= vld_mask1;
                    --upgrade 
                      vld_upgr1  <= vld_upgr0;
                      vld_upgr2  <= vld_upgr1;
                      
                       
                        op_ddr_end1  <= op_ddr_end0;
                        op_ddr_end2  <= op_ddr_end1;
                 
                    
                    rd_rsp_firstw    <= rd_dly_firstw(0); --2019   1);
                    rd_rsp_lastw     <= rd_dly_lastw (0); --; --2019   1);
                    -- rd_rsp_prefirstw <= vld_mask1(RPORT_NUM-1 downto 0) and (not vld_mask2(RPORT_NUM-1 downto 0)); --just before first (rising edge)
                    rd_rsp_prefirstw <= vld_mask0(RPORT_NUM-1 downto 0) and (not vld_mask1(RPORT_NUM-1 downto 0)); --just before first (rising edge)
                    -- rd_rsp_dvld      <= vld_mask2(RPORT_NUM-1 downto 0);
                    rd_rsp_dvld      <= vld_mask1(RPORT_NUM-1 downto 0);  --2019   
                    
                    op_ddr2sys_wren <=   vld_upgr1 ; --2019    2;
                    op_ddr_end      <= op_ddr_end1; --2019   2;
                    
                    
                    --everyting most 32 bursts;
                    case(rd_state) is
                        when RDS_IDLE =>
                            cmd_firstw  <= '0';
                            cmd_lastw   <= '0';
                            rrd_rden <= '0';
                             vld_mask0  <= (others=>'0');
                             --upgrade 
                             vld_upgr0  <= '0'; 
                             op_ddr_end0 <= '0';
                             load_pipe_en <= '0';
                            rd_cnt   <= (others=>'0');					
							if (RST_CMB_FLAG= '1' and rd_wait(8) = '0') then 
								respcmdfifo_rden <= '0';
                                rd_state           <= RDS_IDLE ;
                            elsif(respcmdfifo_empty ='0' ) then 
                                respcmdfifo_rden <= '1';
                                rd_state           <= RDS_WAIT;
                            else
                                respcmdfifo_rden <= '0';
                                rd_state           <= RDS_IDLE ;
                            end if;
                            
                       when RDS_WAIT => 
                            cmd_firstw  <= '0';
                            cmd_lastw   <= '0';
                            rrd_rden <= '0';
                            respcmdfifo_rden <= '0';
                             vld_mask0  <= (others=>'0');
                             --upgrade 
                             vld_upgr0  <= '0';
                             op_ddr_end0               <= '0';
                            if rd_cnt(1) = '1' then 
                                rd_cnt        <= (others=>'0');
                                rd_state      <= RDS_WAITDATA;
                                --must keep same with the read_cmd_gen ----
                                --otherwise failed ...
                                
                            
                                --
                                expect_len256 <= respcmdfifo_rdata(TAGW+24)&respcmdfifo_rdata(5  downto 0) ;----//
                                target_index  <= respcmdfifo_rdata(43)&respcmdfifo_rdata(9 downto 6);----//
                                is_firstburst <= respcmdfifo_rdata(10);
                                is_lastburst  <= respcmdfifo_rdata(11);
                                head_preboff  <= respcmdfifo_rdata(17 downto 12);
                                tail_byteoff  <= respcmdfifo_rdata(23 downto 18);
                                expect_tagid  <= respcmdfifo_rdata(TAGW+24-1 downto 24);
                                load_pipe_en  <= '1';
                             
                            else
                               rd_cnt <= rd_cnt  + 1 ;
                               load_pipe_en <= '0';
                            end if;
                       when RDS_WAITDATA =>
                            cmd_firstw  <= '0';
                            cmd_lastw   <= '0';
                            load_pipe_en <= '0';
                            rrd_rden <= '0';
                            respcmdfifo_rden <= '0';
                            rd_cnt   <= (others=>'0');
                            if target_index = UPGRADE_INDEX then 
                                  vld_mask0 <= (others=>'0');
                                  vld_upgr0  <= '0';
                            else
                                  vld_mask0 <= (others=>'0'); 
                                  vld_mask0(conv_integer(target_index)) <= '0'; 
                                  vld_upgr0  <= '0';
                            end if;
                          
                            if rrd_rdusedw >= expect_len256 then --we may push advance to improve the latency here ....
                                rd_state <= RDS_DISPATCH ;
                            else
                                rd_state <= RDS_WAITDATA;
                            end if;
                            first_w_flg <= '1';
                       when RDS_DISPATCH =>
                            load_pipe_en <= '0';
                            first_w_flg <= '0';
                            respcmdfifo_rden <= '0';
                            cmd_firstw <= first_w_flg;
                             if target_index = UPGRADE_INDEX then 
                                  vld_mask0 <= (others=>'0');
                                  vld_upgr0 <= '1';
                            else
                                  vld_mask0  <= (others=>'0');
                                  vld_mask0(conv_integer(target_index)) <= '1'; 
                                  vld_upgr0  <= '0';
                            end if;
                            rrd_rden   <= '1';
                            rd_cnt     <= (others=>'0');
                            expect_len256 <= expect_len256 - 1;
                            if expect_len256 = 1 then 
                                rd_state  <= RDS_DONE;
                                cmd_lastw <= '1';
                            else
                                rd_state     <= RDS_DISPATCH;
                                cmd_lastw <= '0';
                            end if;
                            
                      WHEN RDS_DONE => 
                             respcmdfifo_rden <= '0';
                             vld_mask0  <= (others=>'0');
                             vld_upgr0  <= '0';
                             cmd_firstw <= '0';
                             cmd_lastw  <= '0';
                             rrd_rden <= '0';
                             load_pipe_en <= '0';
                             if rd_cnt(1) = '0' then --delay two cycles.
                                    rd_state <= RDS_IDLE ;
                                    rd_cnt <= (others=>'0');
                                    if target_index =  UPGRADE_INDEX then 
                                        op_ddr_end0 <= '1';
                                    else
                                        op_ddr_end0 <= '0';
                                    end if;
                             else
                                    rd_cnt <= rd_cnt  + 1 ;
                                    op_ddr_end0 <= '0';
                                    rd_state <= RDS_DONE ;
                             end if;
                      when others=>
                             vld_upgr0  <= '0';
                             op_ddr_end0 <= '0';
                             respcmdfifo_rden <= '0';
                             vld_mask0  <= (others=>'0');
                             cmd_firstw <= '0';
                             cmd_lastw  <= '0';
                             rrd_rden  <= '0';
                             rd_cnt    <= (others=>'0');
                             rd_state  <= RDS_IDLE;
                            
                    end case;
               end if;
         end if;
    end process;
 
     process(sys_nRST,sysclk)
	 begin 
		if sys_nRST = '0' then 
			 ddrb_fifo_clear_sys <= '1';
			  ddrb_clr_cnt_sys    <= (others=>'0');
		elsif rising_edge(sysclk) then 
		    if vsync_neg_sys(0) = '1' and op_ddr_dur = '0' then 
			  ddrb_clr_cnt_sys    <=(others=>'1');
			  ddrb_fifo_clear_sys <= '0';
		    elsif ddrb_clr_cnt_sys /= 0 then 
				if ddrb_clr_cnt_sys>15 and ddrb_clr_cnt_sys < 32 then
					ddrb_fifo_clear_sys <= '1';
				else
					ddrb_fifo_clear_sys <= '0';
				end if;
			    ddrb_clr_cnt_sys    <= ddrb_clr_cnt_sys - 1;
		    else
		        ddrb_fifo_clear_sys <= '0';
		    end if;
			
			if RST_CMB_FLAG = '0' then
				fifo2_rst <= not sys_nRST;
			else
				fifo2_rst <= ddrb_fifo_clear_sys ;
			end if;
	   end if;
	end process; 
	
	process(ddr3_nRST,ddr3_clk)
	 begin 
		if ddr3_nRST = '0' then 
			 ddrb_fifo_clear_ddr <= '1';
			  ddrb_clr_cnt_ddr    <= (others=>'0');
			  op_ddr_dur_ddr    <= (others=>'0');
		elsif rising_edge(ddr3_clk) then 
		   op_ddr_dur_ddr <= op_ddr_dur_ddr(2 downto 0) & op_ddr_dur ;
		   
		   -- if  (DDRB_RSTALL_EN='1' or READ_RST_ONLY = '1' ) and op_ddr_dur_ddr(3) = '1' then 
				 -- ddrb_clr_cnt_ddr    <= (others=>'0');
				 -- ddrb_fifo_clear_ddr <= '0';
		   
		   
		   if ddrb_vsync_neg_ddr = '1' and op_ddr_dur_ddr(3) = '0' then 
			  ddrb_clr_cnt_ddr    <=(others=>'1');
			  ddrb_fifo_clear_ddr <= '0';
		    elsif ddrb_clr_cnt_ddr /= 0 then 
				if ddrb_clr_cnt_ddr>15 and ddrb_clr_cnt_ddr < 32 then
					ddrb_fifo_clear_ddr <= '1';
				else
					ddrb_fifo_clear_ddr <= '0';
				end if;
			    ddrb_clr_cnt_ddr    <= ddrb_clr_cnt_ddr - 1;
		    else
		      ddrb_fifo_clear_ddr <= '0';
		    end if;
		   
		    if RST_CMB_FLAG = '0' then
				fifo1_rst <= not sys_nRST;
			else
				fifo1_rst <= ddrb_fifo_clear_ddr ;
			end if;
		   
		   
	   end if;
	end process; 
	
	
	---dpram_cmdfifo_clear <= dpram_rst when RST_CMB_FLAG ='0' ELSE ddrb_fifo_clear; ---wr_vsync_sys(0) ;
   
    -- fifo1_rst <= not sys_nRST when RST_CMB_FLAG ='0' ELSE ddrb_fifo_clear_ddr;
    -- fifo2_rst <= not sys_nRST when RST_CMB_FLAG ='0' ELSE ddrb_fifo_clear_sys;
    
    rd_datafifo: ddr_rddata_fifo_pack  
    port map(
        Data    =>  rrd_wdata , 
        WrClock =>  ddr3_clk ,   --from ddr3 clock domain
        WCNT    =>  rrd_t_wrusedw ,
        Full    =>  open ,
        WrEn    =>  rrd_wren ,
        
        RdClock =>  sysclk ,
        RdEn    =>  rrd_rden ,
        Reset   => fifo1_rst ,
        RPReset => '0' ,
        Q       => rrd_rdata ,
        RCNT    => rrd_rdusedw ,
        Empty   => rrd_empty  
       );
       rrd_wrusedw <= "000"&rrd_t_wrusedw;
 
 reqcmdfifo_i: ddr_rdreq_cmdfifo_pack  
    port map(
        Data     => rrc_cmdfifo_wdata ,
        WrClock  => sysclk ,
        WrEn     => rrc_cmdfifo_wren , 
        Full     => rrc_cmdfifo_full ,
        WCNT     => rrc_cmdfifo_wrusedw, 
        
        RdClock  => ddr3_clk ,    --to ddr3 clock domain 
        RdEn     => rrc_cmdfifo_rden ,
        Reset    => fifo2_rst ,
        RPReset  => '0' ,
        Q        => rrc_cmdfifo_q , 
        RCNT     => rrc_cmdfifo_rdusedw ,
        Empty    => rrc_cmdfifo_empty 
       );
   
 respcmdfifo_i: ddr_rdresp_cmdfifo_pack  
    generic map (
        D_W => CRSP_W
    )
    port map (
        Data   => respcmdfifo_wdata ,
        Clock  => sysclk ,
        WrEn   => respcmdfifo_wren , 
        RdEn   => respcmdfifo_rden ,
        Reset  => fifo2_rst ,
        Q      => respcmdfifo_rdata ,
        WCNT   => respcmdfifo_wrusedw ,
        Empty  => respcmdfifo_empty ,
        Full   => respcmdfifo_full 
        );    
   respcmdfifo_rdusedw <= respcmdfifo_wrusedw;

   
 
 end beha;
    
    
    
