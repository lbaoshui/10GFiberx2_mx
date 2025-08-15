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


entity  read_cmd_gen is 
generic (
   SIM      : std_logic  :=  '0';
   INDEX    : integer    :=  0   ;
   H_W      : integer    :=  15 ; --hight in pixel
   W_W      : integer    :=  16 ; --with  in pxiel
   STRIDE_W : integer    :=  14 ; --with  in pxiel
   BURST_W  : integer    :=  7  ; --with  in pxiel
   D_W      : integer    :=  320 ;
   DETECT_PARAM_RDY_EDGE : INTEGER:= 1 ; --- 1 : USE THE PICparam_rdy signal 0: not use it ...
   -- A_W      : integer    :=  26  ; ---word in 64bit 
   A_W      : integer    :=  23  ; ---word in 320bit 
   TAGW     : integer    :=  4   ;
   CREQ_W   : integer    :=  35  ;
   CRSP_W   : integer    :=  30 
);

port 
(
    color_depth            : in   std_logic_vector(2 downto 0); ---"000" RGB 8bit, "001": RGB 10bit, "010" RGB 12bit
    sys_nRST               : in std_logic ;
    sysclk                 : in std_logic ; 
    startx                 : in std_logic_vector(W_W-1 downto 0)  ; --pixel 
    starty                 : in std_logic_vector(H_W-1 downto 0)  ; -- in pixel
    pic_width              : in std_logic_vector(W_W-1 downto 0)  ;  -- in pixel
    pic_height             : in std_logic_vector(H_W-1 downto 0)  ;  -- in pixel 
    rd_baseaddr320         : in std_logic_vector(A_W-1 downto 0); -- in word 320bit 
   ---- rd_discard             : in std_logic ; -- '1' : discard  , '0': no discard 
    total_depthrow320_sys  : in std_logic_vector(STRIDE_W -1 downto 0) ; --unit is 320bit  
    vsync_neg_sys          : in std_logic ;
    rd_ddr_rd_en_f_i       : in std_logic ;
    ----------------------------------------------
    -------------------------------------------------------
    onepic_done        : out std_logic ;   ---one pulse only 
    picparam_rdy       : in  std_logic ;  --level , last for most ime ;
    pic_next_en        : in  std_logic ;  --one pulse only 
    start_calc_en_o    :out  std_logic ;
   
    ----------------------------------------------
    
    
    rd_req                 : out std_logic;
    rd_ack                 : in  std_logic ;
    rd_reqcmd              : out std_logic_vector(CREQ_W-1 downto 0);
  ---  rd_reqtag              : out std_logic_vector(TAGW-1 downto 0);
    rd_respcmd             : out std_logic_vector(CRSP_W-1 downto 0);
   --- rd_abort               : out std_logic ;
    
    rd_rsp_dvld             : in std_logic ;
    rd_rsp_data             : in std_logic_vector(D_W -1 downto 0);
    rd_rsp_retcmd           : in std_logic_vector(CRSP_W-1 downto 0);
    rd_rsp_lastw            : in std_logic;  --last word --last word in the seg
    rd_rsp_firstw           : in std_logic ; --first word --first word in the seg
    rd_rsp_prefirstw        : in std_logic ; --just before first word --first word in the seg
    
    --should be zero for 320 bit
	discard_unused_en        : in std_logic ; --discard the first and last 256bit if not needed 
	startoff                 : in std_logic_vector(3 downto 0);	--in pixel
	endoffset                : in std_logic_vector(3 downto 0); --in pixel
	
    outfifo_aclr              : out std_logic ;
    outfifo_wren              : out std_logic ;
    outfifo_wrusedw           : in  std_logic_vector(12 downto 0);
    outfifo_wdata             : out std_logic_vector(D_W-1 downto 0);
    outfifo_full              : in  std_logic
 );
 
 end read_cmd_gen ;
 
architecture beha of read_cmd_gen is 
    
COMPONENT ddr_addr_calc is 
generic 
( 
  W_W       : integer := 16;
  H_W       : integer := 16 ;
  STRIDE_W  : integer := 15;  --stride width`
  DDRA_W    : integer := 23 ; ---DDR , 320bit =40bytes +6
  DDRD_W    : integer := 320;  ---40 bytes = 8*5 ;
  BURST_BITS: integer := 6   ---stride /DDR3 64 burst at most for every operation (boundary)
);
port 
(
   clr_i       : in   std_logic ;
   nRST        : in   std_logic ;
   clk_i       : in   std_logic ;   
   color_depth : in   std_logic_vector(1 downto 0); ---"000" RGB 8bit, "001": RGB 10bit, "010" RGB 12bit
   stride_320  : in   std_logic_vector(STRIDE_W-1 downto 0); --unit is 320bit, be multiple of 128 words
   ---stride_byte_d64 = (stride_320/64)*40 , stride in 320bit must be multiple of 64  
   --stride_byte_d64 : in   std_logic_vector(STRIDE_W-1 downto 0); --unit is 320bit, be multiple of 128 words
   startx_px   : in   std_logic_vector(W_W-1 downto 0);
   cury_px     : in   std_logic_vector(H_W-1 downto 0);
   width_px    : in   std_logic_vector(W_W-1 downto 0);
   height_px   : in   std_logic_vector(H_W-1 downto 0);
   endx_in_px   : in   std_logic_vector(W_W-1 downto 0);
   calc_en     : in   std_logic ;
   --how many byte are skipped in the first words
   start_off_o     : out  std_logic_vector(5 downto 0);
   start_be_o      : out  std_logic_vector((DDRD_W/8)-1 downto 0);
   burst_st_addr   : out std_logic_vector(DDRA_W-1 downto 0);  --in 320bit
   burst_end_addr  : out std_logic_vector(DDRA_W-1 downto 0);  --in 320bit 
   total_num_320bit: out std_logic_vector(15-1 downto 0);  --in 320bit
   --how many bytes valid in the last word
   end_be_o         : out std_logic_vector((DDRD_W/8)-1 downto 0);     
   end_off_o        : out std_logic_vector(5 downto 0)
); 
end  COMPONENT;

 signal start_addr_cal_en    :    std_logic ; 
 signal  ddr_start_off       :    std_logic_vector(5 downto 0);
 signal  ddr_start_be        :    std_logic_vector((D_W/8)-1 downto 0);
 signal  ddr_st_burst_addr   :    std_logic_vector(A_W-1 downto 0);  --in 320bit
 signal  ddr_end_burst_addr  :    std_logic_vector(A_W-1 downto 0);  --in 320bit 
    --how many bytes valid in the last word
 signal  ddr_end_be         :    std_logic_vector((D_W/8)-1 downto 0);     
 signal  ddr_end_off        :    std_logic_vector(5 downto 0) ;


---signal pic_width_512bit : std_logic_vector(12 downto 0) ; 
--signal    row_s0_mask            : std_logic_vector( 31 downto 0); --First 256bit DDR3 MASK for first burst
--signal    row_s1_mask            : std_logic_vector( 31 downto 0); --SECOND 256BIT DDR3 MASK`for first burst;
--signal    row_e0_mask            : std_logic_vector( 31 downto 0); --FIRST 256BIT DDR3 MASK  FOR LAST BURST
--signal    row_e1_mask            : std_logic_vector( 31 downto 0);-- SECOND 256BIT DDR3 MASK FOR LAST BURST
--signal    row0_start_addr        : std_logic_vector( 25 downto 0); --unit is 64bit, the starting address in DDR for the first line 
--signal    row0_end_addr0          : std_logic_vector( 25 downto 0); --unit is 64bit,the  ending   address in DDR for the first line
---signal    pic_width_512bit       : std_logic_vector( 12 downto 0);  --unit is 512bit,-- how many 512bit for the picture , including the prefix and postfix ...
 signal    head_pre_bytenum       : std_logic_vector( 5 downto 0); --unit is bytes, how many bytes at the first 512bit are useless ,from LSB
 signal    tail_append_bytenum    : std_logic_vector( 5 downto 0) ; --unit is bytes, how many bytes at the last 512bit are VALID, from LSB . 
signal     num256_cnt              : std_logic_vector(14 downto 0);

signal cur_tagid       : std_logic_vector(TAGW-1 downto 0);
signal is_firstburst   : std_logic := '0';
signal is_lastburstcmd : std_logic  ;

-- signal rd_rsplen      : std_logic_vector(5 downto 0);
signal rd_rsplen      : std_logic_vector(6 downto 0);
signal rd_rsptagid     : std_logic_vector(TAGW-1 downto 0);
signal rd_rspfirstcmd  : std_logic;
signal rd_rsplastcmd   : std_logic ;
signal rd_rspstart_boff : std_logic_vector(5 downto 0); --40 bytes, 
signal rd_rspend_boff   : std_logic_vector(5 downto 0); --40 bytes
signal rd_rspindex      : std_logic_vector(3 downto 0);  ---index ....

constant OUTFIFO_DEPTH_256 : integer := 512 ; -----

signal rdfifo_is_enough         : std_logic ;
signal rd_accept                : std_logic ;
signal wait_cnt                 : std_logic_vector(8 downto 0) := (others=>'0');
signal cur_waitdata_len256      : std_logic_vector(8 downto 0) := (others=>'0');
signal cur_op_len320            : std_logic_vector(8 downto 0) := (others=>'0');
signal suspend_256              : std_logic_vector(9 downto 0) := (others=>'0');
signal outfifo_pre_usedw        : std_logic_vector(12 downto 0) :=(others=>'0');
signal is_lastburstmcd          : std_logic ;
signal rd_req_int               : std_logic := '0' ;
signal oneline_done             : std_logic := '0' ;
signal row_end_addr             : std_logic_vector(A_W-1 downto 0);
signal line_start_addr          : std_logic_vector(A_W-1 downto 0);
signal ddr3_cur_addr            : std_logic_vector(A_W-1 downto 0);
signal line_cnt                 : std_logic_vector(H_W-1 downto 0) := (others=>'0');
-- signal depth_row_total_o        : std_logic_vector(15 downto 0) := (others=>'0');
signal pic_width_320bit         : std_logic_vector(14 downto 0) := (others=>'0');
signal allline_done             : std_logic :='0';

signal bad_param              : std_logic := '1';
signal bad_param1             : std_logic := '1';
signal bad_param2             : std_logic := '1';
signal vsync_neg_sys_d1       : std_logic_vector(8 downto 0) := (others=>'0');
signal vsync_neg_sys_d2       : std_logic := '0';
signal vsync_neg_sys_cmb_d2   : std_logic := '0';
    
type defstate is (ST_CALCBURSTLEN,ST_CHECKFIFO,ST_IDLE, ST_NEXTCMD, ST_NEXTLINE, ST_WAITACK,ST_WAITVSYNC);
signal pstate : defstate := ST_WAITVSYNC;
        
 signal combine_vsync    : std_logic := '0';
 signal picparam_dly_rdy : std_logic := '0';
 
 begin
 
     process(pstate,pic_next_en, vsync_neg_sys)
     begin 
            ---if pstate = ST_WAITVSYNC then 
                    combine_vsync <=  vsync_neg_sys or (pic_next_en);
           --- else
            ---        combine_vsync <= vsync_neg_sys ;
           --- end if;
     end process; 
     
     
    --returned from arbitor ------
      rd_rsplen        <=   rd_rsp_retcmd(TAGW+24)&rd_rsp_retcmd(5 DOWNTO 0 )  ;
      rd_rspindex      <=   rd_rsp_retcmd(9 downto 6)   ; ---4 bit only
      rd_rspfirstcmd   <=   rd_rsp_retcmd(10  )    ; 
      rd_rsplastcmd    <=   rd_rsp_retcmd(11  )   ;
      rd_rspstart_boff <=   rd_rsp_retcmd(17 downto 12 ) ;
      rd_rspend_boff   <=   rd_rsp_retcmd(23 downto 18)         ; -- --end byte offset 
      rd_rsptagid      <=   rd_rsp_retcmd(TAGW+24-1 downto 24) ; 
 
        process(sys_nRST,sysclk)
        begin
            if sys_nRST = '0' then 
                cur_tagid <= (others =>'0');
            elsif rising_edge(sysclk) then 
                 -- if vsync_neg_sys = '1' then --only one pulse )
                 if combine_vsync = '1' then --only one pulse )
                      cur_tagid <= cur_tagid + 1; 
                 end if;
            end if;
        end process;
        
        is_lastburstmcd <= oneline_done;
        rd_accept       <= rd_req_int and rd_ack ;
        rd_req          <= rd_req_int ;
        -------------------------------------------------------------
        process(sys_nRST,SYSCLK)
        begin
            if sys_nRST = '0' then 
                outfifo_wren <= '0';
            elsif rising_edge(sysclk) then 
                  -- if vsync_neg_sys = '1' or pstate = ST_IDLE then 
                  if combine_vsync = '1' or pstate = ST_IDLE then  
                         outfifo_wren <= '0';
                  elsif cur_tagid = rd_rsptagid then
				      if rd_rsp_firstw = '1' and discard_unused_en = '1' and startoff(3)= '1' then 
						  outfifo_wren <= '0'; --discard the first one 
					  elsif rd_rsp_lastw = '1' and discard_unused_en ='1' and endoffset/=0 and endoffset(3)='0' then 
						  outfifo_wren <= '0'; ---discard the last one 
					  else
                          outfifo_wren <= rd_rsp_dvld ;
					  end if;
				  else
						outfifo_wren <= '0'; ----20170523 
                  end if;
                  outfifo_wdata <= rd_rsp_data;
            end if;
        end process;
        
        -------------------------------------------------------------
        process(sys_nRST,sysclk)
        begin
            if sys_nRST = '0' then 
                suspend_256         <= (others=>'0');
                outfifo_pre_usedw   <= (others=>'0');
            elsif rising_edge(sysclk) then 
                -- if vsync_neg_sys = '1' or pstate = ST_IDLE then 
                -- if vsync_neg_sys = '1' or pstate = ST_IDLE then 
                if combine_vsync = '1' or pstate = ST_IDLE then 
                    suspend_256         <= (others=>'0');
                    outfifo_pre_usedw   <= (others=>'0');
                else 
                    outfifo_pre_usedw   <= outfifo_wrusedw + suspend_256 ;
                    
                    -----------------------------how many word are suspend there ....
                    -- here we donot consider the two bursts in one command .....
                    --
                    if rd_accept = '1'  and (rd_rsp_dvld = '1' and  cur_tagid = rd_rsptagid) then 
                        suspend_256 <= suspend_256 + cur_waitdata_len256 -1  ;
                    elsif rd_accept = '1' then 
                        suspend_256 <= suspend_256 + cur_waitdata_len256 ;
                    elsif (rd_rsp_dvld = '1' and cur_tagid = rd_rsptagid) then 
                        suspend_256 <= suspend_256 - 1;
                    end if;
                end if;
            end if;        
        end process;
        
        
        process(sys_nRST,sysclk)
        begin
            if sys_nRST = '0' then 
                    bad_param1 <= '0';
                    bad_param2 <= '0';
                    bad_param  <= '0';
            elsif rising_edge(sysclk) then
                if pic_width = 0 or pic_width > (total_depthrow320_sys(STRIDE_W-1 downto 0)&"0000") or total_depthrow320_sys = 0 then 
                        bad_param1 <= '1';
                else
                        bad_param1 <= '0';
                end if;
                
                if startx > (total_depthrow320_sys(STRIDE_W-1 downto 0)&"0000") or pic_height = 0 then 
                        bad_param2<= '1';
                else
                        bad_param2<= '0';
                end if;
                bad_param <= bad_param1 or bad_param2 ;
            end if;
        end process;
        
        
        
        
        
        process(sys_nRST,SYSCLK)
        begin
            if sys_nRST = '0' then 
                outfifo_aclr <= '1';
            elsif rising_edge(sysclk) then 
                -- if vsync_neg_sys = '1' then 
                   if combine_vsync= '1' then ------
                    outfifo_aclr <= '1';
                elsif pstate = ST_IDLE then 
                    if wait_cnt< 2 then 
                        outfifo_aclr <= '1';
                    else
                        outfifo_aclr <= '0';
                    end if;
                else --add 20170522 
                    outfifo_aclr <= '0';
                end if;
            end if;        
        end process;
        
     
        
        process(sys_nRST, sysclk)
        begin
                if sys_nRST = '0' then 
                    pstate          <= ST_WAITVSYNC;
                    wait_cnt          <= (others=>'0');
                    rd_req_int        <= '0';
                    rdfifo_is_enough <= '0';
                    oneline_done    <= '0';
                    is_firstburst    <= '0';
                    allline_done     <= '0';
                    line_cnt         <= (others=>'0');
                    is_lastburstcmd <= '0';
                     num256_cnt      <= (others=>'0');
                      ddr3_cur_addr    <= (others=>'0');
                elsif rising_edge(sysclk) then 
                    -- if vsync_neg_sys = '1' then 
                    if combine_vsync = '1' then -----
                        wait_cnt         <= (others=>'0');
                        oneline_done     <= '0';
                        is_firstburst    <= '0';
                        rd_req_int       <= '0';
                        rdfifo_is_enough <= '0';
                        pstate           <= ST_IDLE ;
                        allline_done     <= '0';
                        line_cnt         <= (others=>'0');
                        is_lastburstcmd <= '0';
                        num256_cnt      <= (others=>'0');
                         ddr3_cur_addr    <= (others=>'0');
                    else
                        case(pstate ) is 
                            WHEN ST_WAITVSYNC => 
                                    wait_cnt         <= (others=>'0');
                                    oneline_done     <= '0';
                                    is_firstburst    <= '0';
                                    rd_req_int       <= '0';
                                    if pic_next_en = '1' then ---next trigger 
                                        pstate           <= ST_IDLE ;
                                    else
                                        pstate           <= ST_WAITVSYNC;
                                    end if;
                                    rdfifo_is_enough <= '0';
                                    allline_done     <= '0';
                                    line_cnt         <= (others=>'0');
                                    is_lastburstcmd  <= '0';
                                     num256_cnt      <= (others=>'0');
                            when ST_IDLE =>
                                    rd_req_int         <= '0' ;
                                    oneline_done     <= '0';
                                    rdfifo_is_enough <= '0';
                                    is_firstburst    <= '1';
                                    if wait_cnt(8) = '0' then --a window for fifo stable  and the calculation is done ...
                                        wait_cnt <= wait_cnt + 1 ;
                                    elsif picparam_rdy = '0' then 
                                        pstate <= ST_IDLE ;
                                    else 
                                        if bad_param = '1' then 
                                            pstate     <= ST_WAITVSYNC;
                                        else 
                                            pstate     <= ST_CALCBURSTLEN;
                                        end if;
                                        wait_cnt <=(others=>'0');
                                       -- row0_cur_addr64  <= row0_start_addr;
                                        ddr3_cur_addr    <= ddr_st_burst_addr ; 
                                        row_end_addr     <= ddr_end_burst_addr  ;			 ---
                                        line_start_addr  <= ddr_st_burst_addr + total_depthrow320_sys;  --next line start address 
                                        num256_cnt       <= pic_width_320bit; 
                                        line_cnt         <= pic_height ;
                                        allline_done     <= '0'; 
                                    end if;
                                    
                            when ST_CALCBURSTLEN=> 
                                   
                                    rd_req_int      <= '0'; 
                                    oneline_done    <= '0'; 
                                    if num256_cnt <= cur_waitdata_len256 then 
                                            is_lastburstcmd <= '1';
                                    else
                                            is_lastburstcmd <= '0';
                                    end if;
									if rd_ddr_rd_en_f_i = '0' then --20170804 wangac, disable if so .....
										 pstate <= ST_IDLE ;  ---NOTHING TO DO NOW ......
                                    elsif wait_cnt = 3 then ---(1) = '1' then 
                                        wait_cnt   <= (others=>'0'); 
										if cur_waitdata_len256 /= 0 then 
												pstate     <= ST_CHECKFIFO; 
										else
												pstate     <= ST_WAITVSYNC; --error,just out ....
                                        end if;										
                                        num256_cnt <= num256_cnt - cur_waitdata_len256;
                                    else
                                         wait_cnt <= wait_cnt  + 1 ;
                                         
                                    end if;
                                    --256*8 = 2048
                                    rdfifo_is_enough <= '0';
                                    
                           when ST_CHECKFIFO => --we read at least one line data 
                                    if num256_cnt = 0 then 
                                        oneline_done <= '1';
                                    else
                                        oneline_done <= '0';
                                    end if;
                                    if line_cnt <= 1 then --error-risilent
                                        allline_done <= '1';
                                    end if;
                                    rd_reqcmd <= (OTHERS=>'0');
                                    rd_reqcmd(22 downto 0)         <= ddr3_cur_addr(A_W-1 downto 0 ) + rd_baseaddr320(A_W-1 downto 0); --burst 
                                    rd_reqcmd(34 downto 28)        <= cur_waitdata_len256(6 downto 0)  ; --burst lenght 512
                                    ---rd_reqcmd(29 )                 <= '0'; --is two burst  
                                    ----respond command 
                                    rd_respcmd                        <= (others=>'0');
                                    
                                    rd_respcmd(5   DOWNTO 0 )         <= cur_waitdata_len256(5 downto 0);
                                    rd_respcmd(TAGW+24)               <= cur_waitdata_len256(6);
                                    
                                    rd_respcmd(9 downto  6)           <= conv_std_logic_vector(INDEX, 4); ----
                                    rd_respcmd(10  )                  <= is_firstburst   ;
                                    rd_respcmd(11  )                  <= is_lastburstcmd ;
                                    rd_respcmd(17 downto 12 )         <= head_pre_bytenum; --start byte offset 
                                    rd_respcmd(23 downto 18)          <= tail_append_bytenum; --end byte offset 
                                    rd_respcmd(TAGW+24-1 downto 24)   <= cur_tagid;
                                    
                                    ---rd_reqtag  <=  cur_tagid;
                                    
                                    -- if outfifo_pre_usedw >= cur_waitdata_len256 + 16 then  --16 is the margin
                                    if outfifo_pre_usedw < OUTFIFO_DEPTH_256 - 96 then  --16 is the margin  512-96 = 416
                                        rdfifo_is_enough <= '1';
                                    else
                                        rdfifo_is_enough <= '0';
                                    end if;  
                                    
                                    if rdfifo_is_enough = '1' then 
                                         rd_req_int <= '1';
                                         pstate    <= ST_WAITACK ;
                                        
                                    else 
                                         rd_req_int <= '0';
                                         pstate <= ST_CHECKFIFO;
                                    end if;
                                    
                            when ST_WAITACK =>
                                    is_firstburst    <= '0';
                                    rdfifo_is_enough <= '0';
                                    if rd_ack = '1' then 
                                        rd_req_int <= '0';
                                        if oneline_done = '1' then --the whole line is done ....
                                            pstate <= ST_NEXTLINE;
                                        else 
                                            pstate <= ST_NEXTCMD;
                                        end if;
                                    else
                                        rd_req_int <= '1';
                                    end if;
                                    
                            
                            when ST_NEXTCMD =>
                                   wait_cnt         <= (others=>'0');
                                   rd_req_int         <= '0';
                                   is_firstburst    <= '0';
                                   rdfifo_is_enough <= '0';
                             --      row0_cur_addr64  <= row0_cur_addr64 + cur_op_len64;
                                   ddr3_cur_addr    <= ddr3_cur_addr   + cur_op_len320;
                                   pstate           <= ST_CALCBURSTLEN;
                                 
                            when ST_NEXTLINE =>
                                  is_firstburst    <= '1';
                                  rd_req_int <= '0';
                                  wait_cnt  <= (others=>'0');
                                  line_cnt         <= line_cnt  - 1; 
                                  
                                ---  row0_cur_addr64  <= row0_start_addr;
                                  ddr3_cur_addr    <= line_start_addr; --next line 
                                  line_start_addr  <= line_start_addr + total_depthrow320_sys; --next line 
                                  row_end_addr     <= row_end_addr    + total_depthrow320_sys; --next line 
                                  num256_cnt       <= pic_width_320bit;
                                  if allline_done = '1' then
                                        pstate     <= ST_WAITVSYNC;
                                  else
                                        pstate     <= ST_CALCBURSTLEN;
                                  end if;
                            WHEN OTHERS=>
                                  is_firstburst    <= '1';
                                  rd_req_int <= '0';
                                  wait_cnt  <= (others=>'0');
                                  pstate   <= ST_WAITVSYNC ;
                        
                        end case;
                    end if;
                end if;        
        end process;
        
        
    process(sys_nRST,sysclk)
    begin
            if sys_nRSt = '0' then 
                  onepic_done <= '0';
            elsif rising_edge(sysclk) then 
                 -- if vsync_neg_sys = '1' then 
                 if combine_vsync = '1' then 
                        onepic_done <= '0';
                 elsif pstate = ST_NEXTLINE then 
                        if allline_done = '1' then 
                            onepic_done <= '1';
                        else
                            onepic_done <= '0';
                        end if;
                 else 
                        onepic_done <= '0';
                 end if;
            end if;
    end process;
  process(sys_nRST,sysclk)
    begin
        if sys_nRST ='0' then 
                        picparam_dly_rdy <= '0';
                        vsync_neg_sys_d2 <= '0';
                     ---   hit_vsync_neg    <= '1';
                        vsync_neg_sys_d1 <= (others=>'0');
                   --     cur_op_len64     <= (others=>'0');
                        
        elsif rising_edge(sysclk) then      
            if combine_vsync = '1' then 
                        if vsync_neg_sys = '1' then 
                            vsync_neg_sys_d1 <=conv_std_logic_vector(255,9); --not used ,only used the picparam_rdy signal
                        else
                            vsync_neg_sys_d1 <= conv_std_logic_vector(48,9); --just delay 
                        end if;
                        vsync_neg_sys_d2 <= '0';
                        picparam_dly_rdy <= '0';
                      ----  hit_vsync_neg    <= vsync_neg_sys;
            else
                 picparam_dly_rdy <= picparam_rdy ;
                 if picparam_dly_rdy = '0' and picparam_rdy = '1' and DETECT_PARAM_RDY_EDGE = 1 then --rising_edge
                        vsync_neg_sys_d2 <= '1';  
                        vsync_neg_sys_d1 <= (others=>'0');                        
                elsif vsync_neg_sys_d1 /= 0 then 
                        vsync_neg_sys_d1 <= vsync_neg_sys_d1 - 1; 
                        if vsync_neg_sys_d1 = 1 then 
                            vsync_neg_sys_d2 <= '1';
                        else
                            vsync_neg_sys_d2 <= '0';
                        end if;
                else 
                     vsync_neg_sys_d2 <= '0';
                end if;
            end if;  --end if combine_vsync
           --- vsync_neg_sys_d1 <=vsync_neg_sys_d1(7 downto 0)& (combine_vsync);
            
          ----  vsync_neg_sys_d2 <= vsync_neg_sys_d1(8) ;
	end if;
   end process;
   
   
   
    cur_waitdata_len256  <= cur_op_len320(8 downto 0); ----
    process(sysclk)
    begin
        if rising_edge(sysclk) then  
				--20190307 wangac
          ---  vsync_neg_sys_d1 <=vsync_neg_sys_d1(7 downto 0)& vsync_neg_sys ;
          ---  vsync_neg_sys_d2 <= vsync_neg_sys_d1(8) ;
            
            -- if row0_cur_addr64(A_W-1 downto 8)& "11111111" < row0_end_addr then 
            if ddr3_cur_addr >= row_end_addr then 
                   cur_op_len320 <= conv_std_logic_vector(1,9);  --to protect the in
                   ---at most 64 ,and 64-aligned here
            elsif ddr3_cur_addr(A_W-1 downto 6)& "111111" < row_end_addr then 
                    cur_op_len320 <= conv_std_logic_vector(64,9) - ddr3_cur_addr(5 downto 0); --32 burst , 32*8 cycles=256*64it
            else
                    cur_op_len320 <= row_end_addr(8 downto 0) - ddr3_cur_addr(8 downto 0);
            end if;
            
        end if;   
    end process;
   
    vsync_neg_sys_cmb_d2 <= vsync_neg_sys_d2 ; ----or pic_next_en ;
    start_calc_en_o      <= vsync_neg_sys_cmb_d2;
   
   start_addr_cal_en <= '1';
        row_addr_cal :     ddr_addr_calc   
        generic MAP
        ( 
        W_W        => W_W       ,
        H_W        => H_W       ,
        STRIDE_W   => STRIDE_W  , --stride width`
        DDRA_W     => A_W    , ---DDR , 320bit =40bytes +6
        DDRD_W     => D_W    ,  ---40 bytes = 8*5 ;
        BURST_BITS => BURST_W     ---stride /DDR3 64 burst at most for every operation (boundary)
        ) 
    port MAP
    (
   clr_i       => vsync_neg_sys_d2      ,
   nRST        => sys_nRST          ,
   clk_i       => sysclk            , 
   color_depth => color_depth(1 downto 0)       , ---"000" RGB 8bit, "001": RGB 10bit, "010" RGB 12bit
   stride_320  => total_depthrow320_sys,  --unit is 320bit, be multiple of 128 words
   ---stride_byte_d64 = (stride_320/64)*40 , stride in 320bit must be multiple of 64  
   --stride_byte_d64 : in   std_logic_vector(STRIDE_W-1 downto 0); --unit is 320bit, be multiple of 128 words
   startx_px    => startx ,
   cury_px      => starty  ,
   endx_in_px   => (others=>'0'),
   width_px     => pic_width ,
   height_px    => pic_height ,
   calc_en      => start_addr_cal_en,
   --how many byte are skipped in the first words
   start_off_o     => ddr_start_off ,
   start_be_o      => ddr_start_be ,
   burst_st_addr   => ddr_st_burst_addr,  --in 320bit
   burst_end_addr  => ddr_end_burst_addr ,  --in 320bit 
   total_num_320bit=> pic_width_320bit ,  --in 320bit 
   --how many bytes valid in the last word
   end_off_o      => ddr_end_off ,     
   end_be_o       => ddr_end_be  
); 

head_pre_bytenum <= ddr_start_off;
tail_append_bytenum <= ddr_end_off;
        
      
 
 end beha;
    
    
    