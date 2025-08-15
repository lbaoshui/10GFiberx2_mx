
--####################################################################### 
--
--  REVISION HISTORY:  
--
--  Revision 0.1  2017/04/26  Description: Initial .
--
--  FUNCTIONAL DESCRIPTION:
--  --note : we must maker sure the picture width is larger than 16 pixels 
   --       otherwise , the following logic may behavior badly
   --       for  the start and end position are overlapped together 
   --       if so, we need to handle it (extend the mask to 32bit directly, the mask is generated outside)......
   --wrd_rmask[6] : '0' start,  '1': end 
   --wrd_rmask[6:0] : byoffset in the 32bytes
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


entity write_cmd_arb  is
generic 
(
   DDRB_RSTALL_EN  :  std_logic := '0';  -- if '1', all vsync are same -----
   READ_RST_ONLY   :   STD_LOGIC ;
   SIM       : std_logic := '0' ;
   WPORT_NUM : integer   := 2   ;
   BURST_W   : integer   := 7 ;
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
  --- ddrc_rdy_in          : in     std_logic ;   ---DDR controller is ready now ......
   --write command fifo -----
   wrc_cmdfifo_empty    : out    std_logic ;
   wrc_cmdfifo_rden     : in     std_logic ;
   wrc_cmdfifo_q        : out    std_logic_vector(C_W-1 downto 0); 
   --data dpram and mask dpram to DDR 
   wrd_raddr            : in     std_logic_vector(8 downto 0);
   wrd_rdata            : out    std_logic_vector(D_W-1 downto 0); 
   wrd_be               : out    std_logic_vector((D_W/8)-1 downto 0);  --mask fifo (, bit6: start or last, others , offset)
   wrd_rden             : in     std_logic ; 
   wrd_rdaddr_stall     : in     std_logic ;
   wrd_rdoutclk_en      : in     std_logic ;
   wrd_rdinclk_en       : in     std_logic  
);

end write_cmd_arb ;

architecture beha of write_cmd_arb is 
signal dpram_rst : std_logic ;
constant DRAM_AW : integer := 9; 

component ddr_wrmask_dpram_pack is  --reg output ,depth=512 words ..
    port (
        WrAddress: in  std_logic_vector(DRAM_AW-1 downto 0); 
        RdAddress: in  std_logic_vector(DRAM_AW-1 downto 0); 
        Data      : in  std_logic_vector((D_W/8)-1 downto 0); 
        WE        : in  std_logic; 
        RdClock   : in  std_logic; 
        RdEn      : in  std_logic; 
        rdaddr_stall     : in     std_logic ;
        rdoutclk_en      : in     std_logic ;
        rdinclk_en       : in     std_logic ;  
        Reset: in  std_logic; 
        WrClock: in  std_logic; 
        WrClockEn: in  std_logic; 
        Q: out  std_logic_vector( (D_W/8)-1 downto 0));
end component ;

component ddr_datadpram_pack is--reg output ,depth=512 words ..
    port (
        WrAddress: in  std_logic_vector(DRAM_AW-1 downto 0); 
        RdAddress: in  std_logic_vector(DRAM_AW-1 downto 0); 
        Data        : in  std_logic_vector(D_W-1 downto 0); 
        WE          : in  std_logic; 
        RdClock     : in  std_logic; 
        RdEn        : in  std_logic;  
        rdaddr_stall     : in     std_logic ;
        rdoutclk_en      : in     std_logic ;
        rdinclk_en       : in     std_logic ; 
        Reset            : in  std_logic; 
        WrClock          : in  std_logic; 
        WrClockEn        : in  std_logic; 
        Q: out  std_logic_vector(D_W-1 downto 0)
);
end component ;
signal wrd_rdaddr_ddr3 : std_logic_vector(DRAM_AW-1 downto 0) := (others=>'0'); 

component ddr_wrreq_cmdfifo_pack is  --,depth=16 words ..
    port (
        Data: in  std_logic_vector(C_W-1 downto 0); 
        WrClock: in  std_logic; 
        RdClock: in  std_logic; 
        WrEn: in  std_logic; 
        RdEn: in  std_logic; 
        Reset: in  std_logic; 
        RPReset: in  std_logic; 
        Q: out  std_logic_vector(C_W-1 downto 0); 
        WCNT: out  std_logic_vector(4 downto 0); 
        RCNT: out  std_logic_vector(4 downto 0); 
        Empty: out  std_logic; 
        Full: out  std_logic);
end component ;

-- signal  startx             :    std_logic_vector(WPORT_NUM*16-1 downto 0)  ; --pixel 
-- signal  starty             :    std_logic_vector(WPORT_NUM*16-1)  ; -- in pixel 
----signal  wr_req             :    std_logic_vector(WPORT_NUM-1 downto 0) ;
----signal  wr_ack             :    std_logic_vector(WPORT_NUM-1 downto 0) ;
----  
----signal  wr_cmd             :   std_logic_vector(WPORT_NUM*C_W-1 downto 0);
----signal  wr_abort           :   std_logic_vector(WPORT_NUM-1 downto 0) ;
----signal  wr_lastw           :   std_logic_vector(WPORT_NUM-1 downto 0) ;
----signal  wr_data            :   std_logic_vector(WPORT_NUM*D_W-1 downto 0);
----signal  wr_wren            :   std_logic_vector(WPORT_NUM-1 downto 0) ;
----signal  wr_mask            :   std_logic_vector( WPORT_NUM*(D_W/8)-1 downto 0) ;


constant W_EXT_NUM  : integer := 16 ;
subtype index_range is INTEGER range 0 to W_EXT_NUM-1;

signal  arb_sel_one : index_range := 0 ;
signal  hit_sel_one : index_range := 0 ;
signal   wr_ext_req : std_logic_vector(W_EXT_NUM-1 downto 0) ;
signal   wr_ext_ack : std_logic_vector(W_EXT_NUM-1 downto 0) ; ---at most 8 input request
signal   wr_ext_cmd : std_logic_vector(W_EXT_NUM*C_W-1 downto 0) ; ---at most 8 input request

signal  wrc_cmdfifo_rdusedw : std_logic_vector(4 downto 0); ---16
signal  wrc_cmdfifo_wrusedw : std_logic_vector(4 downto 0); ---16
signal  wrc_cmdfifo_wren    : std_logic := '0';
signal  wrc_cmdfifo_wdata   : std_logic_vector(C_W-1 downto 0);
signal  wrc_cmdfifo_full    : std_logic ;

signal  wrd_dpram_wren        : std_logic := '0';
signal  wrd_dpram_wren_d1     : std_logic := '0';
signal  wrd_dpram_wdata       : std_logic_vector(D_W-1 downto 0);
signal  wrd_dpram_wdata_d1    : std_logic_vector(D_W-1 downto 0);
signal  wrd_dpram_be          : std_logic_vector((D_W/8)-1 DOWNTO 0);
signal  wrd_dpram_baseaddr    : std_logic_vector(10 downto 0);
signal  wrd_dpram_wroffset    : std_logic_vector(10 downto 0);
signal  wrd_dpram_wraddr      : std_logic_vector(10 downto 0);
signal  wrd_dpram_wraddr_d1   : std_logic_vector(10 downto 0);

type state_def is (ST_IDLE, ST_TRANSDONE, ST_TRANSSEGONE,ST_WRUPGRADE);
signal pstate : state_def := ST_IDLE ;
signal total_word256     : std_logic_vector(BURST_W-1 downto 0);
signal sel_cmdfifo_wdata : std_logic_vector(C_W-1 downto 0);

 -- signal ddrc_rdy_d     : std_logic_vector(3 downto 0) := (others=>'0');
 signal wr_sel_abort   : std_logic ;
 signal wr_sel_wren    : std_logic ;
 signal wrd_sel_wdata  : std_logic_vector(D_W-1 downto 0);
 signal wrd_sel_wmask  : std_logic_vector((D_W/8)-1 downto 0);

 -- signal  total_depthrow_filter     :    std_logic_vector(16*WPORT_NUM -1 downto 0) :=(others=>'0');
 -- signal  total_depthrow_bitnum     :    std_logic_vector(16*WPORT_NUM -1 downto 0) :=(others=>'0');
 
 
 constant op_ddr_valid_max :integer := 32;  --should not more than 64....
 signal  op_ddr_valid_cnt			: std_logic_vector(7 downto 0);
 signal  op_hit_upgrade             : std_logic := '0';
 signal  upgrade_cmd_fifo           : std_logic_vector(C_W-1 downto 0) ;
 signal  t_wait                     : std_logic := '0'; ----_vector(1 downto 0) := (others=>'0');

 signal dpram_cmdfifo_clear_sys : std_logic := '1';
 signal ddrb_fifo_clear_sys     : std_logic := '1';
 signal ddrb_clr_cnt_sys        : std_logic_vector(2 downto 0):=(others=>'0');
 signal w_wait                  : std_logic_vector(8 downto 0):=(others=>'0');

signal ddrb_fifo_clear_ddr     : std_logic := '1';
signal ddrb_clr_cnt_ddr        : std_logic_vector(2 downto 0):=(others=>'0');
 
signal op_ddr_length : std_logic_vector(BURST_W-1 downto 0); ----(op_ddr_valid_max ,7)	 

 begin 

    op_ddr_length <= conv_std_logic_vector(op_ddr_valid_max ,BURST_W);
    
 
    
    process(wr_req,wr_ext_ack,wr_cmd,wr_abort)
    begin  
        wr_ext_cmd <= (OTHERS=>'0');
        wr_ext_cmd(WPORT_NUM*C_W-1 downto 0) <= wr_cmd ;
        -------------------------------------------------
        wr_ext_req <= (others=>'0'); 
        for i in 0 to WPORT_NUM-1 loop
            wr_ext_req(i)<= wr_req(i) and (not wr_abort(i));
        end loop;
        wr_ack  <= (others=>'0' ) ;
        for i in 0 to WPORT_NUM-1 loop
            wr_ack(i) <= wr_ext_ack(i);
        end loop;
    end process;
    
    process(wr_ext_req,wr_ext_cmd)
    begin
                   if   wr_ext_req(0) = '1' then 
                        arb_sel_one        <= 0;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*1 -1 downto C_W*0) ;  
                  elsif wr_ext_req(1) = '1' then 
                        arb_sel_one <= 1;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*2 -1 downto C_W*1) ; 
                  elsif wr_ext_req(2) = '1' then 
                        arb_sel_one <= 2;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*3 -1 downto C_W*2) ;
                  elsif wr_ext_req(3) = '1' then 
                        arb_sel_one <= 3;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*4 -1 downto C_W*3) ;
                  elsif wr_ext_req(4) = '1' then 
                        arb_sel_one <= 4 ;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*5 -1 downto C_W*4) ;
                  elsif wr_ext_req(5) = '1' then 
                        arb_sel_one <= 5;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*6 -1 downto C_W*5) ;
                  elsif wr_ext_req(6) = '1' then ---'1';
                        arb_sel_one <= 6;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*7 -1 downto C_W*6) ;
                  elsif wr_ext_req(7) = '1' then 
                        arb_sel_one <= 7;
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*8 -1 downto C_W*7) ;
        elsif wr_ext_req(8) = '1' then
            arb_sel_one <= 8;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*9 -1 downto C_W*8) ;
        elsif wr_ext_req(9) = '1' then
            arb_sel_one <= 9;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*10 -1 downto C_W*9) ;
        elsif wr_ext_req(10) = '1' then
            arb_sel_one <= 10;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*11 -1 downto C_W*10) ;
        elsif wr_ext_req(11) = '1' then
            arb_sel_one <= 11;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*12 -1 downto C_W*11) ;
        elsif wr_ext_req(12) = '1' then
            arb_sel_one <= 12;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*13 -1 downto C_W*12) ;
        elsif wr_ext_req(13) = '1' then
            arb_sel_one <= 13;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*14 -1 downto C_W*13) ;
        elsif wr_ext_req(14) = '1' then
            arb_sel_one <= 14;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*15 -1 downto C_W*14) ;
        elsif wr_ext_req(15) = '1' then
            arb_sel_one <= 15;
            sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*16 -1 downto C_W*15) ;
                  else
                        sel_cmdfifo_wdata  <= wr_ext_cmd( C_W*1 -1 downto C_W*0) ;
                        arb_sel_one <= 0 ;
                  end if;
    end process;
   
     wr_sel_abort       <= wr_abort( Hit_sel_one )  ;
     wr_sel_wren        <= wr_wren (  Hit_sel_one  ) ;
     wrd_sel_wdata      <= wr_data ( D_W*(1+Hit_sel_one) -1     downto     D_W*(Hit_sel_one) ) ;
     wrd_sel_wmask      <= wr_mask ( (D_W/8)*(1+Hit_sel_one) -1 downto (D_W/8)*(Hit_sel_one) ) ;
     
     
     process(op_sys2ddr_addr,op_ddr_length) ----,op_ddr_valid_max)
     begin
             upgrade_cmd_fifo  <= (others=>'0');
             upgrade_cmd_fifo(22 downto 0)    <=  op_sys2ddr_addr(24 DOWNTO 2) ; ----burst address
             upgrade_cmd_fifo(34 DOWNTO 28  ) <=  op_ddr_length; ----conv_std_logic_vector(op_ddr_valid_max,7);  --burst lenght 512
             --upgrade_cmd_fifo(29 )            <= '0'; --is two burst 
             ---upgrade_cmd_fifo(42 downto 34)   <= (others=>'0') ; --not used at ..., we use the mask fifo there                 
     end process;
     
   process(sys_nRST,sysclk)
   begin
        if sys_nRST = '0' then  
            pstate <= ST_IDLE;
            wrd_dpram_baseaddr <= (others=>'0');
            wrc_cmdfifo_wren   <= '0';
            wrd_dpram_wren     <= '0'; 
            wr_ext_ack          <= (others=>'0'); 
             op_ddr_valid_cnt <= (others=>'0');
             op_ddr_ack       <= '0';
             op_ddr_end       <= '0';
             op_sys2ddr_rden  <= '0';
             op_hit_upgrade   <= '0';
             t_wait           <= '0';
             w_wait           <= (others=>'0');
			 wrd_dpram_wroffset <= (others=>'0');
             
             wrd_dpram_be       <= (others=>'1'); --- 
        elsif rising_edge(sysclk) then 
        
            if op_hit_upgrade = '0' then 
                wrd_dpram_wdata    <= wrd_sel_wdata ; --Select data to writing into fifo
                wrd_dpram_be       <= wrd_sel_wmask ;
            else
                wrd_dpram_wdata <= (OTHERS=>'0');
                wrd_dpram_wdata(255 DOWNTO 0)    <= op_sys2ddr_q; ---
                wrd_dpram_be       <= (others=>'1'); ---upgrade
            end if;
            wrd_dpram_wdata_d1 <= wrd_dpram_wdata;
            wrd_dpram_wren_d1 <= wrd_dpram_wren;
            wrd_dpram_wraddr_d1 <= wrd_dpram_wraddr;
          ---  wrc_cmdfifo_wdata  <= 
            if ddrc_rdy_sys = '0' or (DDRB_RSTALL_EN= '1' AND wr_vsync_sys(0) ='1' and op_ddr_dur = '0' )then --in sysclock domain 
                pstate <= ST_IDLE;
                wrd_dpram_baseaddr <= (others=>'0');
                wrc_cmdfifo_wren   <= '0';
                wrd_dpram_wren     <= '0'; 
                wr_ext_ack          <= (others=>'0'); 
                op_ddr_valid_cnt <= (others=>'0');
                op_ddr_end       <= '0';
                op_sys2ddr_rden  <= '0';
                op_ddr_ack       <= '0'; 
                op_hit_upgrade   <= '0';
				t_wait           <= '0';
				w_wait           <= (others=>'0');
				wrd_dpram_wroffset <= (others=>'0');
            else
                case(pstate) is
                      when ST_IDLE => ---IDLE
                           Hit_sel_one      <= arb_sel_one ;
                           op_ddr_valid_cnt <= (others=>'0');
                           op_ddr_ack       <= '0';
                           op_ddr_end       <= '0';
                           op_sys2ddr_rden  <= '0';
						   t_wait           <= '0';
						   if w_wait (8) = '0' then 
								w_wait <= w_wait + 1; 
						   end if;
                           if op_ddr_dur = '1' then 
                                op_hit_upgrade   <= '1';
                                if op_ddr_req = '1' and op_ddr_cmd = '0' and wrc_cmdfifo_wrusedw < 3 then --write 
                                      pstate <= ST_WRUPGRADE;   
                                      op_ddr_ack          <= '1';
                                else
                                      pstate <= ST_IDLE ;
                                        op_ddr_ack          <= '0';
                                end if;
                                wrd_dpram_wroffset  <= wrd_dpram_baseaddr ;
                                wr_ext_ack          <= (others=>'0'); 
                           elsif w_wait(8) = '0' and DDRB_RSTALL_EN = '1' THEN 
								op_hit_upgrade     <= '0';
                                wr_ext_ack <= (others=>'0');
                                op_ddr_ack       <= '0';
                                pstate     <= ST_IDLE;
                           elsif wr_ext_req /= 0  and wrc_cmdfifo_wrusedw < 3 then  --at most 4+1 commands are buffered
                                op_hit_upgrade     <= '0';
                                pstate             <= ST_TRANSSEGONE ;
                                wrd_dpram_wroffset <= wrd_dpram_baseaddr ;
                                wr_ext_ack          <= (others=>'0'); 
                                wr_ext_ack(arb_sel_one) <= '1';
                                op_ddr_ack       <= '0';
                           else
                                op_hit_upgrade     <= '0';
                                wr_ext_ack <= (others=>'0');
                                op_ddr_ack       <= '0';
                                pstate     <= ST_IDLE;
                           end if; 
                           wrc_cmdfifo_wren   <= '0';
                           wrd_dpram_wren     <= '0'; 
                           if op_ddr_dur = '1' then 
                                wrc_cmdfifo_wdata  <= '0'&wrd_dpram_baseaddr(DRAM_AW-1 downto 0)&upgrade_cmd_fifo(43-1 downto 0) ;
                                total_word256      <= conv_std_logic_vector(op_ddr_valid_max, 7) + 3;
                           else
                                wrc_cmdfifo_wdata  <= '0'&wrd_dpram_baseaddr(DRAM_AW-1 downto 0)&sel_cmdfifo_wdata( 43*1 -1 downto C_W*0) ;
                                --must be same with write_cmd_gen ...
                                total_word256      <= sel_cmdfifo_wdata(34 downto 28) ; ----&'0';  --burst to 256bit conversion
                           end if;
                      when ST_WRUPGRADE  => 
                          op_hit_upgrade     <= '1';
                          op_ddr_ack        <= '0';
                          op_ddr_end        <= '0';
						  t_wait           <= '0';
                         --- wrc_cmdfifo_wdata <= upgrade_cmd_info;
                          
                          op_ddr_valid_cnt <= op_ddr_valid_cnt + 1; 
                          total_word256    <= total_word256 - 1; 
                          if total_word256 = 1 then  ------op_ddr_valid_cnt = op_ddr_valid_max+2 then 
                                pstate <= ST_TRANSDONE;
                          else
                                pstate <= ST_WRUPGRADE;
                          end if;
                          ----------------
                          if op_ddr_valid_cnt < op_ddr_valid_max then ----
                                 op_sys2ddr_rden  <= '1';
                          else
                                 op_sys2ddr_rden  <= '0';
                          end if;
                          if total_word256 = 1 then 
                              ---  wrc_cmdfifo_wren   <= '1';
                                wrc_cmdfifo_wren   <= '1';
                                wrd_dpram_baseaddr <= wrd_dpram_wroffset + 1 ;  --update the baseaddr 
                          else
                                wrc_cmdfifo_wren <= '0';
                          end if; 
                          
                         if op_ddr_valid_cnt >= 3  then ------and op_ddr_valid_cnt <  op_ddr_valid_max+2 then 
                                wrd_dpram_wren <= '1';
                                wrd_dpram_wroffset <= wrd_dpram_wroffset + 1 ;
                                wrd_dpram_wraddr   <= wrd_dpram_wroffset ; 
                          else
                                wrd_dpram_wren <= '0';
                          end if;
                                
                      when ST_TRANSSEGONE =>  --move data to DDR3 FIFO 
                            op_hit_upgrade   <= '0'; 
                            op_ddr_ack       <= '0';
                            op_ddr_end       <= '0';
                            wr_ext_ack <= (others=>'0');
                            t_wait           <= '0'; 
                           if wr_sel_abort = '1' then --QUIT DIRECTLY .....
                                pstate             <= ST_IDLE;
                                total_word256      <= total_word256 - 1; 
                                wrd_dpram_wren     <= '0';
                                wrc_cmdfifo_wren   <= '0';
                           elsif wr_sel_wren = '1' then 
                                total_word256      <= total_word256 - 1; 
                                wrd_dpram_wren     <= '1';
                                wrd_dpram_wroffset <= wrd_dpram_wroffset + 1 ;
                                wrd_dpram_wraddr   <= wrd_dpram_wroffset ; 
                                if total_word256 = 1  then  --last word ,update now ...
                                     pstate             <= ST_TRANSDONE;
                                     wrc_cmdfifo_wren   <= '1';
                                     wrd_dpram_baseaddr <= wrd_dpram_wroffset + 1 ;  --update the baseaddr 
                                else
                                     pstate <= ST_TRANSSEGONE;
                                     wrc_cmdfifo_wren   <= '0';
                                end if;
                           else
                                wrd_dpram_wren     <= '0';
                                wrc_cmdfifo_wren   <= '0';
                           end if;
                           
                     when ST_TRANSDONE => --wait for commnd fifo status upating ....
						  t_wait           <= not t_wait;
						  if t_wait = '0' then 
							op_ddr_end       <= op_hit_upgrade ;
							pstate           <= ST_TRANSDONE ;
						  else
							op_ddr_end     <= '0';
							pstate           <= ST_IDLE ;
						  end if;
                          
                          op_ddr_ack       <= '0';
                          op_ddr_valid_cnt <= (others=>'0');
                          wr_ext_ack       <= (others=>'0');
                          wrc_cmdfifo_wren   <= '0';   
                          wrd_dpram_wren     <= '0';
                end case ;
            end if;
        end if;
   end process;
   
   ------------------------------------------------------------------------------------
   -- process(ddr3_nRSt, ddr3_clk)
   -- begin
        -- if ddr3_nRST = '0' then --dpram read address ....
                -- wrd_rdaddr_ddr3 <= (others=>'0');
        -- elsif rising_edge(ddr3_clk) then 
             -- if ddrc_rdy_in = '0' or (DDRB_RSTALL_EN= '1' AND ddrb_fifo_clear_ddr= '1' and op_ddr_dur = '0' ) then   --not ready ,just go on ....
                -- wrd_rdaddr_ddr3 <= (others=>'0');
             -- elsif wrd_rden = '1' then --address 
                    -- wrd_rdaddr_ddr3 <= wrd_rdaddr_ddr3 + 1; 
             -- end if;
        -- end if;
   -- end process;
   wrd_rdaddr_ddr3 <= wrd_raddr ;
   dpram_rst <= not sys_nRST ;
   
   ---------- dpram   for writing data 
   data_dpram_i :    ddr_datadpram_pack  --reg output 
    port  map(
        WrAddress   => wrd_dpram_wraddr_d1(DRAM_AW-1 downto 0),  --512 elments
        WrClock     => sysclk ,
        WrClockEn   => '1' ,
        Data        => wrd_dpram_wdata_d1 ,
        WE          => wrd_dpram_wren_d1 ,
        
        RdClock     => ddr3_clk ,
        RdAddress   => wrd_rdaddr_ddr3 ,
        
        -- RdClockEn   => '1' ,
        RdEn        => wrd_rden ,
        Reset       => dpram_rst , 
        rdaddr_stall   =>  wrd_rdaddr_stall ,
        rdoutclk_en    =>  wrd_rdoutclk_en  ,
        rdinclk_en     =>  wrd_rdinclk_en   ,
        
        Q           => wrd_rdata 
     );
     
     mask_dpram_i :  ddr_wrmask_dpram_pack --reg output 
     port map 
     (
        WrAddress   => wrd_dpram_wraddr(DRAM_AW-1 downto 0),  --512 elments
        WrClock     => sysclk ,
        WrClockEn   => '1' , 
        Data        => wrd_dpram_be ,    --byte enable 
        WE          => wrd_dpram_wren ,
        
        RdClock     => ddr3_clk ,
        RdAddress   => wrd_rdaddr_ddr3 ,
        
        -- RdClockEn   => '1' ,
        RdEn        => wrd_rden ,
        Reset       => dpram_rst , 
        rdaddr_stall   =>  wrd_rdaddr_stall ,
        rdoutclk_en    =>  wrd_rdoutclk_en  ,
        rdinclk_en     =>  wrd_rdinclk_en   , 
        Q              => wrd_be        --write byte enable
     );
	 
	 process(sys_nRST,sysclk)
	 begin 
		if sys_nRST = '0' then 
			 ddrb_fifo_clear_sys <= '1';
			 ddrb_clr_cnt_sys    <= (others=>'0');
		elsif rising_edge(sysclk) then 
		   --here we dont use op_ddr_dur for DDRB_RSTALL_EN ='1', upgrade is not here
		   if wr_vsync_sys(0) = '1' then 
			  ddrb_clr_cnt_sys    <=(others=>'1');
			  ddrb_fifo_clear_sys <= '1';
		   elsif ddrb_clr_cnt_sys /= 0 then 
			 ddrb_fifo_clear_sys <= '1';
			 ddrb_clr_cnt_sys    <= ddrb_clr_cnt_sys - 1;
		   else
		      ddrb_fifo_clear_sys <= '0';
		   end if;
	   end if;
	 end process;
	 
	 process(ddr3_nRST,ddr3_clk)
	 begin 
		if ddr3_nRST = '0' then 
			 ddrb_fifo_clear_ddr <= '1';
			 ddrb_clr_cnt_ddr    <= (others=>'0');
		elsif rising_edge(ddr3_clk) then 
		   if ddrb_vsync_neg_ddr = '1'  then  --here we dont use op_ddr_dur_ddr for DDRB_RSTALL_EN ='1', upgrade is not here
			  ddrb_clr_cnt_ddr    <=(others=>'1');
			  ddrb_fifo_clear_ddr <= '1';
		   elsif ddrb_clr_cnt_ddr /= 0 then 
			 ddrb_fifo_clear_ddr <= '1';
			 ddrb_clr_cnt_ddr    <= ddrb_clr_cnt_ddr - 1;
		   else
		      ddrb_fifo_clear_ddr <= '0';
		   end if;
	   end if;
	 end process;
	 
	 dpram_cmdfifo_clear_sys <= dpram_rst when DDRB_RSTALL_EN ='0' ELSE ddrb_fifo_clear_sys; ---wr_vsync_sys(0) ;
   
   cmdfifo_i: ddr_wrreq_cmdfifo_pack   --reg ouptut 
    port map(
        WrClock => sysclk ,
        Data    =>  wrc_cmdfifo_wdata , 
        WCNT    => wrc_cmdfifo_wrusedw,
        Full    => wrc_cmdfifo_full   ,
        WrEn    => wrc_cmdfifo_wren   ,
        
        RdClock => ddr3_clk             ,
        RdEn    => wrc_cmdfifo_rden     , 
        Reset   => dpram_cmdfifo_clear_sys            ,
        RPReset => '0'                  ,
        Q       => wrc_cmdfifo_q        ,
        RCNT    => wrc_cmdfifo_rdusedw ,
        Empty   => wrc_cmdfifo_empty     
       );



end beha ;




