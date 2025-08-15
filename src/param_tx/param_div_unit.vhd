library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity param_div_unit is 
generic ( 
UNIT_NUM    : INTEGER := 4 ; --for fiber 2 or 4, for 5G 4 ;
ETH_PER_UNIT: INTEGER := 1 ; --EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
P_W         : INTEGER := 6 
);
port 
(
   nRST : in   std_logic ;
   clk  : in   std_logic ;
   
   start_cal_en  : in std_logic ;
   net_st_port   : in std_logic_vector(P_W-1  downto 0); 
   div_int       : out std_logic_vector(2     downto 0); --
   div_resid     : out std_logic_vector(P_W-1 downto 0);
   div_is_brdcast: out std_logic;
   real_eth_num_conv  : in std_logic_vector(3 downto 0)
);
end param_div_unit;


architecture beha of param_div_unit is 

signal calc_cnt           : std_logic_vector(3 downto 0):=(others=>'1'); 
signal div_left           : std_logic_vector(P_W-1 downto 0):=(others=>'0'); 
signal div_idx            : std_logic_vector(2 downto 0):=(others=>'0'); --at most 8 
CONSTANT ALL_1            : std_logic_vector(P_W-1  downto 0) :=(others=>'1'); 

begin 
   div_int    <= div_idx  ;
   div_resid  <= div_left ;

 process(nRST,clk) ---net_st_port) --nert port 
   begin 
      if nRST = '0' then 
            calc_cnt       <= (others=>'1');
            div_idx        <= (others=>'0');   ---division 
            div_left       <= (others=>'0');   --division
            div_is_brdcast <= '0';
      elsif rising_edge(clk) then 
           if start_cal_en  = '1'   then  ---only handle 0x07 frame  
                calc_cnt <= (others=>'0');
           elsif calc_cnt(3) = '0' then  
                calc_cnt <= calc_cnt + 1;
           end if;
           
          if net_st_port = ALL_1    then  --other frame (not 0x07) may interrupt here .......
               div_idx        <= (others=>'0');
               div_left       <= (others=>'0');
               div_is_brdcast <= '1';
          else  
              div_is_brdcast <= '0';
              if real_eth_num_conv = 1 then 
                  div_idx        <= net_st_port(2 downto 0) ;
                  div_left       <= (others=>'0'); 
              elsif real_eth_num_conv = 2 then 
                  div_idx        <= net_st_port(3 downto 1);
                  div_left       <= (others=>'0'); 
                  div_left(0)    <=  net_st_port(0);
              elsif real_eth_num_conv = 4 then 
                  div_idx              <= net_st_port(4 downto 2);
                  div_left             <= (others=>'0'); 
                  div_left(1 downto 0) <= net_st_port(1 downto 0);
              elsif real_eth_num_conv = 8 then 
                  div_idx              <= net_st_port(5 downto 3);
                  div_left             <= (others=>'0'); 
                  div_left(2 downto 0) <= net_st_port(2 downto 0);
              else  
                  if    calc_cnt = 0 then  
                             div_idx <= (others=>'0'); 
                             div_left <= net_st_port;
                  elsif calc_cnt >= 1 and calc_cnt <= 4  then --at most 4   
                       if div_left >= real_eth_num_conv then 
                              div_idx     <= div_idx + 1; 
                              div_left    <= div_left - real_eth_num_conv ;
                       end if;  
                  elsif calc_cnt = 6 then
                       ----                  
                  end if;
              end if;
         end if;
      end if;          
                    
   end process;

end beha;
