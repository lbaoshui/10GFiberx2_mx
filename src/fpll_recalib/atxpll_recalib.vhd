
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity atxpll_recalib is 
port 
(
   reset                : in std_logic ;
   clk                  : in std_logic ;
   pll_powerdown_i        : in std_logic ;
   tx_pll_cal_busy      : in std_logic ;
      trigger_serdes_fortst  : in std_logic ;
 --// TX PLL reconfig controller interface
   txpll_mgmt_address    :out std_logic_vector(9 downto 0) ;---output wire [9:0] ,
   txpll_mgmt_writedata  :out std_logic_vector(31 downto 0) ;---output wire [31:0],
   txpll_mgmt_readdata   :in  std_logic_vector(31 downto 0) ;---input  wire [31:0],
   txpll_mgmt_write      :out std_logic  ;---output wire       ,
   txpll_mgmt_read       :out std_logic  ;---output wire       ,
   txpll_mgmt_waitrequest: in std_logic  ;----input  wire       
   cali_done_o           : out std_logic ;
   begin_en              : in std_logic 
  );
end atxpll_recalib;

architecture beha of atxpll_recalib is 


type st_def is (ST_IDLE,ST_WAITPD,ST_STEP0_b,ST_REL_RESET,ST_turnIDLE, ST_CALIDONE,ST_STEP0, ST_WAITDONE0, ST_STEP1,ST_STEP2,ST_STEP3, ST_WAITDONE1,ST_WAITDONE2,ST_WAITDONE3);
signal pstate : st_def := ST_IDLE ;

signal nRST  : std_logic ;

---// TXPLL Reconfiguration controller register addresses
constant  ADDR_TXPLL_CALIB    : std_logic_vector(9 downto 0) := "01"&x"00"; ----10'h100,  
constant  ADDR_TXPLL_M_CNT    : std_logic_vector(9 downto 0) := "01"&x"2b"; ----10'h12b,
constant  ADDR_TXPLL_L_CNT    : std_logic_vector(9 downto 0) := "01"&x"2c"; ----10'h12c;
constant  ADDR_TXPLL_BUS_ARB  : std_logic_vector(9 downto 0) :=  (others=>'0'); ----10'h000

--// TXPLL Reconfiguration controller register masks
constant MASK_ATXPLL_CALIB    :std_logic_vector(31 downto 0)    :=  x"00000001";---= 32'h0000_0002,
-- constant MASK_TXPLL_M_CNT    :std_logic_vector(31 downto 0)    :=  x"000000ff";---= 32'h0000_00ff,
-- constant MASK_TXPLL_L_CNT    :std_logic_vector(31 downto 0)    :=  x"00000006";---= 32'h0000_0006;

-- type r_defst is (R_IDLE,R_READ, R_SUBW, R_TURND, R_TURNW, R_WAITIDLE);
-- signal r_state : r_defst := R_IDLE;
signal cfg_done   : std_logic := '0';
signal cfg_req    : std_logic := '0';
signal cfg_ack    : std_logic := '0';
signal cfg_is_read : std_logic := '0'; 
-- signal is_do_read : std_logic := '0'; 
signal calib_done : std_logic := '0';
signal clr_i      : std_logic := '0';
signal cnt        : std_logic_vector( 15 downto 0);
signal cfg_addr   : std_logic_vector( 9 downto 0);
signal cfg_wdata  : std_logic_vector(31 downto 0);
signal cfg_rdata  : std_logic_vector(31 downto 0);
signal cfg_mask   : std_logic_vector(31 downto 0);
signal pll_powerdown    : std_logic := '0';
signal clr_ten    : std_logic := '0';
signal time_s_en : std_logic;
signal timeout    : std_logic_vector(22 downto 0);

signal ms_cnt                   : std_logic_vector(23 downto 0);
signal time_s_cnt               : std_logic_vector(15 downto 0);
signal ms_en                    : std_logic;
signal cnt_4s_msb               : std_logic;
signal pll_cal_start            : std_logic;

component recalib_avmm is 
generic (A_W : integer:= 10 ;
         D_W : integer:= 32
);
port

(
  reset                : in std_logic ;
   clk                  : in std_logic ;
   clr_i       : in    std_logic ;
   cfg_done    : out   std_logic := '0';
   cfg_req     : in    std_logic := '0';
   cfg_ack     : out   std_logic := '0';
   cfg_is_read : in    std_logic := '0'; 
   cfg_addr    : in    std_logic_vector(A_W-1 downto 0);
   cfg_wdata   : in    std_logic_vector(D_W-1 downto 0);
   cfg_rdata   : out   std_logic_vector(D_W-1 downto 0);
   cfg_mask    : in    std_logic_vector(D_W-1 downto 0);
    
  --  -// TX PLL reconfig controller interface
   txpll_mgmt_address     :out std_logic_vector(A_W-1 downto 0) ;---output wire [9:0] ,
   txpll_mgmt_writedata   :out std_logic_vector(D_W-1 downto 0) ;---output wire [31:0],
   txpll_mgmt_readdata    :in  std_logic_vector(D_W-1 downto 0) ;---input  wire [31:0],
   txpll_mgmt_write       :out std_logic  ;---output wire       ,
   txpll_mgmt_read        :out std_logic  ;---output wire       ,
   txpll_mgmt_waitrequest : in std_logic   ----input  wire     
); 
end component ;
begin 

   clr_i <= reset;---pll_powerdown_i;
   cali_done_o <= calib_done;
   nRST <= not reset ;
   
process(nRST,clk)
begin
    if nRST = '0' then           
        ms_cnt <= (others => '0');    
        ms_en <= '0';
          
    elsif rising_edge(clk) then
        if ms_cnt >= 100000 then
            ms_cnt <= (others => '0');
            ms_en <= '1';
        else
            ms_cnt <= ms_cnt + '1';
            ms_en <= '0';
        end if;
		
		if time_s_cnt = 1000 then
			time_s_cnt <= (others=>'0');
			time_s_en <= '1';
		elsif ms_en = '1' then
			time_s_cnt <= time_s_cnt +1;
			time_s_en <= '0';
		else
			time_s_en <= '0';
		end if;
	end if;
end process;
			
        

   process(nRST,clk)
   begin 
      if nRST = '0' then 
            timeout <= (others=>'0');
      elsif rising_edge(clk) then 
            if clr_ten = '1' then 
                timeout <= (others=>'0');
            elsif timeout(15) = '0' then 
                timeout <= timeout + 1 ;
            end if;
      end if;
   end process;

   process(nRST,clk)
   begin 
      if nRST = '0' then 
           pstate     <= ST_IDLE ;
           calib_done <= '0';
           cnt        <= (others=>'0');
           cfg_req    <= '0';
           cfg_addr   <= (others=>'0');
           pll_powerdown<= '1';
      elsif rising_edge(clk) then 
          IF  clr_i = '1' or begin_en ='0' or trigger_serdes_fortst = '1' then 
                    pstate         <= ST_WAITPD;
                    cfg_req        <= '0';
                    cnt            <= (others=>'0');
                    pll_powerdown  <= '1';
					calib_done <='0';
          else
               case pstate is 
                    when ST_IDLE =>
                         cfg_req    <= '0';
                        cnt         <= (others=>'0');
                        pll_powerdown <= '0';

                        if calib_done = '0' and tx_pll_cal_busy = '0' then 
                              pstate <= ST_STEP0_b;
                        else 
                              pstate <= ST_IDLE;
                        end if;
                        
                    when ST_WAITPD  =>
						     
                        -- if cnt = 16384 THEN 
						if cnt = 4 then
                           pstate <= ST_IDLE;
                        elsif time_s_en = '1' then
                            cnt <= cnt + 1 ;
                        end if;
                        
                   WHEN ST_STEP0_b =>
                        if cnt = 4096 then 
                             cnt <= (others=>'0');
                             pstate <= ST_STEP0;
                        else 
                             cnt <= cnt + 1 ;
                        end if;
                    WHEN ST_STEP0 =>  --request preSICE write 0x2 to addr 0x0
                       cfg_req     <= '1';
                       cfg_is_read <= '0';
                       cfg_addr    <=  ADDR_TXPLL_BUS_ARB; ---- "00";
                       cfg_mask    <=  (others=>'1'); 
                     ---  cfg_mask(7 downto 0) <= (others=>'1');
                       cfg_wdata    <= (others=>'0'); ---request  preSICE;write  2 to address #0
                       cfg_wdata(1) <= '1';  --start cali 
                       pstate       <= ST_WAITDONE0;
                       
                    when ST_WAITDONE0 =>
                       if cfg_ack = '1' or cfg_done = '1'  then 
                          cfg_req <= '0';
                       end if;
                       if cfg_done = '1' then 
                           pstate <= ST_STEP1; 
                       end if;   
                       
                       
                    WHEN ST_STEP1 => --wrote 0x1 to start cali  OF ATXPLL 
                       cfg_req     <= '1';
                       cfg_is_read <= '0';
                       cfg_addr    <=  ADDR_TXPLL_CALIB; -----"01"&X"00";
                       cfg_mask    <=  MASK_ATXPLL_CALIB; 
                       cfg_wdata   <= conv_std_logic_vector(1, 32);
                      
                       pstate    <= ST_WAITDONE1;
                       
                    when ST_WAITDONE1 =>
                       if cfg_ack = '1' or cfg_done = '1'  then 
                          cfg_req <= '0';
                       end if;
                       if cfg_done = '1' then 
                           pstate <= ST_STEP2; 
                       end if;
                       
                    when ST_STEP2 =>  ---Release preSICE  0x1 to  addr #0
                         cfg_req     <= '1';
                         cfg_is_read <= '0';
                         cfg_addr    <=  ADDR_TXPLL_BUS_ARB; -----"01"&X"00";
                         cfg_mask    <=  (others=>'1'); -----"01"&X"00";
                    ---     cfg_mask(7 downto 0)    <=  (others=>'1'); 
                         cfg_wdata   <= (others=>'0');  ---write 1 to release the preSICE ;
                         cfg_wdata(0) <= '1';  --    
                         pstate    <= ST_WAITDONE2;
                         
                    when ST_WAITDONE2 =>
                         if cfg_ack = '1' or cfg_done = '1'  then 
                          cfg_req <= '0';
                       end if;
                       if cfg_done = '1' then 
                           pstate <= ST_STEP3; 
                       end if;    
                    
                    WHEN ST_STEP3 =>  ---wait until 
                         -- cfg_req     <= '1';
                         cfg_req     <= '0';
                         -- cfg_is_read <= '1';
                         -- cfg_addr    <=  "10"&X"80"; ----- 0X280;
                         -- cfg_mask    <=  (others=>'1'); 
                         -- cfg_wdata   <= (others=>'0');
                         -- cfg_wdata(0) <= '1';  --start  
                         pstate    <= ST_WAITDONE3;
                         
                    when ST_WAITDONE3 =>
                        if tx_pll_cal_busy = '0' then 
                             pstate     <= ST_CALIDONE;
                             calib_done <= '1';
                        else 
                             pstate <= ST_WAITDONE3;
                        end if;
                       -- if cfg_ack = '1' or cfg_done = '1'  then 
                          -- cfg_req <= '0';
                       -- end if;
                       -- if cfg_done = '1' then 
                           -- pstate <= ST_STEP3; 
                           -- if cfg_rdata(1) = '0' then 
                               -- calib_done <= '1';
                               -- pstate <= ST_CALIDONE;
                           -- else 
                               -- pstate <= ST_STEP3;
                           -- end if;
                       -- end if; 
                    when ST_CALIDONE =>
                          cfg_req <= '0';
                         
                          if cnt = 2048 then 
                              pstate <= ST_REL_RESET;
                              pll_powerdown  <= '1';
                        ---      calib_done <= '0';
                              cnt        <=(others=>'0');
                          else 
                              cnt <= cnt  + 1 ;
                          end if;
                    when ST_REL_RESET =>
                         if cnt = 7000 then 
                            pll_powerdown  <= '0';
                             cnt <= (others=>'0');
                             pstate <= ST_turnIDLE;
                          ELSE 
                            CNT <= CNT + 1 ;
                         END IF;
                    when ST_turnIDLE      =>
                            if cnt = 60000 then 
                                cnt <= (others=>'0');
                                pstate <= ST_IDLE;
                            else 
                                cnt  <= cnt + 1 ;
                            END IF;
                            
                    WHEN OTHERS=>
                          pstate <= ST_IDLE ;                
                           
               end case;
          end if;
      end if;
   end process;
   
   
   -----------------config one reg tractioin
   recali_intf: recalib_avmm  
    port map
    (               
       reset       =>reset       ,
       clk         =>clk         ,
       clr_i       =>clr_i       ,
       cfg_done    =>cfg_done    ,
       cfg_req     =>cfg_req     ,
       cfg_ack     =>cfg_ack     ,
       cfg_is_read =>cfg_is_read ,
       cfg_addr    =>cfg_addr    ,
       cfg_wdata   =>cfg_wdata   ,
       cfg_rdata   =>cfg_rdata   ,
       cfg_mask    =>cfg_mask    ,
        
      --  -// TX PLL reconfig controller interface
       txpll_mgmt_address     =>txpll_mgmt_address     ,
       txpll_mgmt_writedata   =>txpll_mgmt_writedata   ,
       txpll_mgmt_readdata    =>txpll_mgmt_readdata    ,
       txpll_mgmt_write       =>txpll_mgmt_write       ,
       txpll_mgmt_read        =>txpll_mgmt_read        ,
       txpll_mgmt_waitrequest =>txpll_mgmt_waitrequest 
    ); 
  
   -- process(nRST,clk)
   -- begin 
        -- if nRST = '0' then 
            -- r_state <= R_IDLE; 
            -- txpll_mgmt_read  <= '0';
            -- txpll_mgmt_write <= '0';
            -- txpll_mgmt_address  <= (others=>'0');
            -- txpll_mgmt_writedata <= (others=>'0');
            -- cfg_ack   <= '0';
            -- is_do_read   <= '0';
            -- cfg_done         <= '0';
        -- elsif rising_edge(clk) then 
            -- case(r_state) is 
                 -- WHEN R_IDLE =>
                     -- txpll_mgmt_address  <= "01"&X"00"; ---0x126
                     -- txpll_mgmt_write <= '0';
                     -- txpll_mgmt_read  <= '0';
                     -- cfg_ack          <= '0';
                     -- cfg_done         <= '0';
                     -- txpll_mgmt_writedata <= (others=>'0');
                     -- if cfg_req = '1' then --accept it .....
                         -- cfg_ack <= '1';
                         -- txpll_mgmt_address  <= cfg_addr;
                         -- is_do_read       <= cfg_is_read ;
                        -- if cfg_is_read = '1' then 
                            -- txpll_mgmt_read  <= '1';
                            -- txpll_mgmt_write <= '0';
                        -- else --first readback, then write back
                            -- txpll_mgmt_read <= '1';
                            -- txpll_mgmt_write <= '0'; 
                          -- ---  txpll_mgmt_writedata <= cfg_wdata ;
                        -- end if;
                        -- r_state <= R_READ ;
                       
                    -- else 
                        -- r_state <= R_IDLE; 
                    -- end if;
                    
                -- WHEN R_READ=>
                       -- cfg_done <= '0';
                       -- cfg_ack  <= '0'; 
                       -- if txpll_mgmt_waitrequest = '0' then 
                            -- cfg_rdata <= txpll_mgmt_readdata;
                            -- txpll_mgmt_read <= '0';
                            -- if is_do_read = '1' then 
                                -- r_state <= R_TURND ;  ----done 
                            -- else 
                                -- r_state <= R_TURNW; --go on  read 
                            -- end if;
                       -- end if;
                       
                -- when R_TURND =>
                     -- r_state   <= R_IDLE ;
                     -- cfg_done  <= '1';
                     -- cfg_ack   <= '0';
                     -- txpll_mgmt_read <= '0';
                     -- txpll_mgmt_write <= '0';
                       
                -- when R_TURNW=>
                      -- cfg_ack  <= '0';
                      -- cfg_done <= '0';
                     -- --- r_state  <= R_WAITIDLE;
                      -- txpll_mgmt_read <= '0';
                      -- txpll_mgmt_write <= '0';
                      -- r_state <= R_SUBW;
                      
                -- when R_SUBW =>
                      -- cfg_done        <= '0';
                      -- txpll_mgmt_write <= '1';
                      -- txpll_mgmt_read  <= '0';
                      -- txpll_mgmt_writedata <= (cfg_wdata and cfg_mask) or ( ( not cfg_mask) and cfg_rdata);
                      -- r_state   <= R_WAITIDLE;
                      
                      
                -- when R_WAITIDLE =>
                     -- cfg_done <= '0';
                     -- cfg_ack <= '0';
                     -- if txpll_mgmt_waitrequest = '0' then 
                        -- txpll_mgmt_read <= '0';
                        -- txpll_mgmt_write <= '0'; 
                        -- r_state   <= R_TURND; 
                     -- else 
                        -- r_state   <= R_WAITIDLE;
                     -- end if;
                     
                -- when others=>
                    -- r_state <= R_IDLE;
                    -- txpll_mgmt_read <= '0';
                    -- txpll_mgmt_write <= '0';
              -- end case;
        -- end if;
  -- end process;


end beha ;