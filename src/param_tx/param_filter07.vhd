library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;

entity param_filter07 is 
generic ( 
	UNIT_NUM : INTEGER := 4  --for fiber 2 or 4, for 5G 4 ;


);
 port ( 
   nRST                   : in  std_logic ;
   clk                    : in  std_logic ;   
    --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
	
	unit_idx              : in std_logic_vector(2 downto 0);
    ----
    -- frmCC_07_en           :  in  std_logic  ; --current frame is 07 
    quick08_wren          :  out std_logic  ;
    quick08_waddr         :  out std_logic_vector(10 downto 0);
    quick08_wdata         :  out std_logic_vector( 7 downto 0); 
    -- quick08_filter_en     :  out std_logic_vector(UNIT_NUM-1 downto 0)  ;  --up 08 filtered or not -----
    -- quick08_flag          :  out std_logic_vector(UNIT_NUM-1 downto 0)  ; 
    quick08_addr_len      :  out std_logic_vector(7 downto 0)  
  ); 
 end param_filter07;
  
  architecture beha of param_filter07 is   
  constant QUICK_ADDR_START      : integer := 11 ;
  signal   quick08_filt_disable  : std_logic ;
  signal   filter08_en           : std_logic := '0';
  signal   data_len              : std_logic_vector(11 downto 0);
  signal   rcv_frmType           : std_logic_vector(7 downto 0);
  signal   net_st_port           : std_logic_vector(7 downto 0);
  signal   net_num_m1            : std_logic_vector(7 downto 0);
  signal   quick_addr_num        : std_logic_vector(7 downto 0);
  signal   frmCC_07_en           : std_logic := '0';    
  signal   hit_CC                : std_logic := '0';
  signal   quick_detect_en       : std_logic := '0';
  
  begin 
  
  
    --whether to filter 
  
  quick08_addr_len  <= quick_addr_num;
   
  process(nRST ,clk)
   begin 
        if nRST = '0' then
             quick08_filt_disable   <= '0'; --default is to filtered   
             quick08_wren           <= '0';
             -- quick08_filter_en      <= (others=>'0'); 
             frmCC_07_en            <= '0';
			 quick_detect_en        <= '0';
        elsif rising_edge(clk) then   
             quick08_waddr      <= p_Addr_i -   QUICK_ADDR_START;
             quick08_wdata      <= p_Data_i;
            
             -------------------------------------- 
            -- quick08_flag                           <= (others=>'0');
            -- quick08_flag (conv_integer(unit_idx))  <= quick_detect_en;  
            -- if frmCC_07_en = '1' then 
				-- quick08_filter_en  <= (others=>'0'); 
                -- quick08_filter_en(conv_integer(unit_idx))  <= not quick08_filt_disable ;   --may cross clock domain ,therefore ,dont outside  
            -- else 
                -- quick08_filter_en  <= (others=>'0'); 
            -- end if;
             
             if p_Frame_en_i = '1'  and p_Wren_i = '1' and p_Addr_i = 0 then
                      if p_Data_i = FT_FORWARD_PARAM then   
                            hit_CC <= '1';
                      else 
                            hit_CC <= '0';
                      end if;
             end if; 
             
             quick08_wren       <= '0';
             if p_Frame_en_i = '1' then 
                   -- if frmCC_07_en = '0' then 
                         -- quick08_filt_disable  <= '0'; --disable , '0': filtered , '1' : donot filter  
                   -- else  
                         if hit_CC = '1' and p_Wren_i = '1' then --only CC can change it ....
                                 if    p_Addr_i = 1 then  net_st_port           <= p_Data_i(7 downto 0);  --at most 20 here (maybe 40 for )                                
                                 elsif p_Addr_i = 3 then  quick08_filt_disable  <= p_Data_i(1); --bit 1 
								 elsif p_Addr_i = 4 then  net_num_m1            <= p_Data_i(7 downto 0); --minus 1 ,0 is one 
                                 elsif p_Addr_i = 5 then  data_len( 7 downto 0) <= p_Data_i;
                                 elsif p_Addr_i = 6 then  data_len(11 downto 8) <= p_Data_i(3 downto 0);
                                 elsif p_Addr_i = 7 then  rcv_frmType           <= p_Data_i ; 
                                                          if p_Data_i = RFT_DETECT_RCV then 
                                                              frmCC_07_en <= '1' ;
                                                          else 
                                                              frmCC_07_en <= '0'; 
                                                          end if; 
														  quick_detect_en <= '0';
                                 end if;
								 
								if frmCC_07_en = '1'and p_Addr_i = 13 then
									quick_detect_en <= p_Data_i(0);
								end if;
								 
								 
                                 if frmCC_07_en = '1' and  p_Addr_i = 14 then 
                                      quick_addr_num        <= p_Data_i ; 
                                 end if;
                                
                                 
                                 if p_Addr_i >= QUICK_ADDR_START and frmCC_07_en = '1' then ----rcv_frmType = RFT_DETECT_RCV  then ---quick ram 
                                        quick08_wren <= '1';
                                 else 
                                        quick08_wren <= '0';
                                 end if;
                         else 
                                quick08_wren <= '0';
                         end if;      
                  -- end if; 
             end if;
                                   
        end if;
   end process;
  
  end beha;
    