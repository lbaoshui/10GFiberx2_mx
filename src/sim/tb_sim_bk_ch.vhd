library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;

entity tb_sim_bk_ch is 
generic
(  SIM               : std_logic := '1';
   SERDES_5G_EN      : std_logic := '0';
   ETHPORT_NUM       : integer := 10 ; --how many eth port 
   FIBER_NUM         : integer := 1;
   BKHSSI_NUM        : integer := 2 
);
end tb_sim_bk_ch;

architecture beha of tb_sim_bk_ch is 
component bk2fiber_chan is
generic
(  SIM               : std_logic := '0' ;
   SERDES_5G_EN      : std_logic;
   ETHPORT_NUM       : integer ; --how many eth port 
   FIBER_NUM         : integer ;
   BKHSSI_NUM        : integer  
);
port 
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);
    
    nRST_txclk           : in  std_logic    ; ---
    txclk_i              : in  std_logic    ; --200M almost 
    xgmii_wren           : out std_logic    ;
    xgmii_data_out       : out std_logic_vector(FIBER_NUM*64-1 downto 0);
    xgmii_control        : out std_logic_vector(FIBER_NUM*8 -1 downto 0);
    
    
    p_Frame_en_txc       : in std_logic ;
    p_Wren_txc           : in std_logic ;
    p_Data_txc           : in std_logic_vector(7 downto 0);
    p_Addr_txc           : in std_logic_vector(10 downto 0);
    cur_slot_num         : in std_logic_vector(15 downto 0);

    
     secret_data          :in  std_logic_vector(47 downto 0):= (others => '0');
      
     hdr_enable           :in  std_logic:= '0';
     hdr_type             :in  std_logic_vector(7 downto 0):= (others => '0');
     hdr_rr               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_rg               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_rb               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_gr               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_gg               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_gb               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_br               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_bg               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_bb               :in  std_logic_vector(15 downto 0):= (others => '0');
     hdr_coef             :in  std_logic_vector(5 downto 0):= (others => '0');
     hlg_type             :in  std_logic_vector(7 downto 0):= (others => '0') 
);

end component ;

signal    nRST_bk_rxclk         :  std_logic_vector(BKHSSI_NUM-1  downto 0) := (others=>'0');
signal    rx_bk_clk             :  std_logic_vector(BKHSSI_NUM-1  downto 0) := (others=>'0');
signal    rx_bk_parallel_data   :  std_logic_vector(BKHSSI_NUM*64-1 downto 0);
signal    rx_bk_control         :  std_logic_vector(BKHSSI_NUM*8 -1 downto 0);
     
signal    nRST_txclk           :   std_logic    :=( '0'); ---
signal    txclk_i              :   std_logic    :=( '0'); --200M almost 
signal    xgmii_wren           :   std_logic    :=( '0');
signal    xgmii_data_out       :   std_logic_vector(FIBER_NUM*64-1 downto 0);
signal    xgmii_control        :   std_logic_vector(FIBER_NUM*8 -1 downto 0);
     
     
signal    p_Frame_en_txc       :  std_logic := '0';
signal    p_Wren_txc           :  std_logic := '0';
signal    p_Data_txc           :  std_logic_vector(7 downto 0);
signal    p_Addr_txc           :  std_logic_vector(10 downto 0);
signal    cur_slot_num         :  std_logic_vector(15 downto 0);
 
     
signal     secret_data          :   std_logic_vector(47 downto 0):= (others => '0');
       
signal     hdr_enable           :   std_logic:= '0';
signal     hdr_type             :   std_logic_vector(7 downto 0):= (others => '0');
signal     hdr_rr               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_rg               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_rb               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_gr               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_gg               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_gb               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_br               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_bg               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_bb               :   std_logic_vector(15 downto 0):= (others => '0');
signal     hdr_coef             :   std_logic_vector(5 downto 0):= (others => '0');
signal     hlg_type             :   std_logic_vector(7 downto 0):= (others => '0') ;


signal     pck_type:   std_logic_vector(7 downto 0):= (others => '0') ;
signal     pck_len_128:   std_logic_vector(15 downto 0):= (others => '0') ;
signal     pixel_num:   std_logic_vector(15 downto 0):= (others => '0') ;
signal     col_start:   std_logic_vector(15 downto 0):= (others => '0') ; 
signal     row_cur:   std_logic_vector(15 downto 0):= (others => '0') ;
                            --rx_bk_parallel_data( i*64+15-1 downto i*64+8  )<= pck_type;
signal   color_depth  :std_logic_vector(1 downto 0):= (others => '0') ;
signal   eth_port     :std_logic_vector(3 downto 0):= (others => '0') ;
 type ARRAY_2x16  is array (0 to 1)  of std_logic_vector(15 downto 0);                        
signal xcnt : ARRAY_2x16;                        
signal ycnt : ARRAY_2x16;  

                      
begin 
     nRST_txclk           <= '1' after 11 ns ; ---
     txclk_i              <= not txclk_i after 4 ns ;--200M almost 

       nRST_bk_rxclk      <= (others=>'1') after 11 ns;
       rx_bk_clk          <= not rx_bk_clk after 5 ns;
       
      pck_type        <= (others=>'0'); 
      pixel_num       <= conv_std_logic_vector( 31*4, 16);  
      pck_len_128     <= conv_std_logic_vector( 31  , 16);  
      col_start       <= (others => '0') ; 
      ---row_cur         <= ;---
      
      row_cur  <= ycnt(1) - 3;
      
     bfm_g:for i in 0 to BKHSSI_NUM-1 GENERATE 
       BFM_INST: process(nRST_bk_rxclk(i),rx_bk_clk(i))
       begin
           if nRST_bk_rxclk(i) = '0' then 
               xcnt(i) <= (others=>'0');
               ycnt(i) <= (others=>'0');
           elsif rising_edge(rx_bk_clk(i)) then 
              if xcnt(i) = 512 then 
                 xcnt(i)  <= (others=>'0');
                 if ycnt(i)  = 1024 then 
                    ycnt(i)  <= (others=>'0');
                 else 
                    ycnt(i)  <= ycnt(i)  +1;
                 end if;
              else 
                 xcnt(i)  <= xcnt(i)  + 1;
              end if;
              
              if ycnt(i)  = 0 then 
                  rx_bk_control ( (i+1)*8-1 downto i*8) <= X"FF";
                  rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"07070707"&X"07070707";
              elsif ycnt(i)  = 1 then 
                  if xcnt(i) = 0 then 
                       rx_bk_control ( (i+1)*8-1 downto i*8) <= X"01";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"D5555555"&X"5555"&X"01"&XGMII_SCP;
                  ELSIF XCNT(i)  = 1 THEN 
                       rx_bk_control ( (i+1)*8-1 downto i*8)        <= X"00";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= ycnt(i)&xcnt(i)&ycnt(i)&xcnt(i);
                  ELSIF XCNT(i)  = 2 THEN 
                       rx_bk_control ( (i+1)*8-1 downto i*8) <= X"00";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= ycnt(i)&xcnt(i)&ycnt(i)&xcnt(i) ;
                  ELSIF XCNT(i)  = 3 THEN 
                       rx_bk_control ( (i+1)*8-1 downto i*8) <= X"00";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= ycnt(i)&xcnt(i)&ycnt(i)&xcnt(i) ;
                 
                  ELSIF XCNT(i)  <= 31 THEN 
                       rx_bk_control ( (i+1)*8-1 downto i*8) <= X"00";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<=  ycnt(i)&xcnt(i)&ycnt(i)&xcnt(i);
                  ELSIF XCNT(i)  = 32 THEN 
                     rx_bk_control ( (i+1)*8-1 downto i*8) <= X"ff";
                     rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"07070707"&X"070707"&X"FD";
                  ELSE 
                     rx_bk_control ( (i+1)*8-1 downto i*8) <= X"ff";
                     rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"07070707"&X"070707"&X"07";
                  END IF;
              ELSIF YCNT(i)   = 2  THEN 
                     rx_bk_control ( (i+1)*8-1 downto i*8) <= X"ff";
                     rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"07070707"&X"070707"&X"07";
              elsif ycnt(i)  >= 3 and  ycnt(i)  < 240 then 
                   
                   case(conv_integer( xcnt(i) )) is 
                     when 0 =>
                       rx_bk_control ( (i+1)*8-1 downto i*8) <= X"01";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"D5555555"&X"5555"&X"00"&XGMII_SCP;
                     when  1 =>  
                        rx_bk_control ( (i+1)*8-1 downto i*8)        <= X"00"; 
                        if i =  0 then 
                            ---pck_type   <= trans_fifo_q(15 downto 8 );
                            ---pck_len_128<= trans_fifo_q(31 downto 16); --128bit how many  
                            ---pixel_num  <= trans_fifo_q(47 downto 32); 
                            ---col_start  <= trans_fifo_q(63 downto 48);
                           
                            rx_bk_parallel_data( i*64+8 -1 downto i*64+0  )<= (others=>'0');
                            rx_bk_parallel_data( i*64+16-1 downto i*64+8  )<= pck_type;
                            rx_bk_parallel_data( i*64+32-1 downto i*64+16 )<= pck_len_128;
                            rx_bk_parallel_data( i*64+48-1 downto i*64+32 )<= pixel_num;
                            rx_bk_parallel_data( i*64+64-1 downto i*64+48 )<= col_start; 
                       else 
                           
                            rx_bk_parallel_data( i*64+16 -1 downto i*64+0  )<= row_cur;
                            --rx_bk_parallel_data( i*64+15-1 downto i*64+8  )<= pck_type;
                            rx_bk_parallel_data( i*64+24-1 downto i*64+16 )<= "000000"&color_depth;
                            rx_bk_parallel_data( i*64+32-1 downto i*64+24 )<= "0000"&eth_port;
                            rx_bk_parallel_data( i*64+64-1 downto i*64+32 )<= (others=>'0'); 
                    
                       end if;
                     when 2 => 
                       rx_bk_control ( (i+1)*8-1 downto i*8) <= X"00";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= ycnt(i)&xcnt(i)&ycnt(i)&xcnt(i);
                     when 3 =>
                       rx_bk_control ( (i+1)*8-1 downto i*8) <= X"00";
                       rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= ycnt(i)&xcnt(i)&ycnt(i)&xcnt(i);
                     when others=>
                        IF XCNT(i) <= 31 THEN 
                          rx_bk_control ( (i+1)*8-1 downto i*8) <= X"00";
                          rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"D5555555"&X"5555"&xcnt(i);
                        ELSIF XCNT(i)  = 32 THEN 
                          rx_bk_control ( (i+1)*8-1 downto i*8) <= X"ff";
                          rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"07070707"&X"070707"&X"FD";
                        ELSE 
                          rx_bk_control ( (i+1)*8-1 downto i*8) <= X"ff";
                          rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"07070707"&X"070707"&X"07";
                        END IF;
                   end case;                        
               else 
                    rx_bk_control ( (i+1)*8-1 downto i*8) <= X"ff";
                    rx_bk_parallel_data( (i+1)*64-1 downto i*64 )<= X"07070707"&X"070707"&X"07";
                    
               end if;
           end if;    
       END PROCESS;
    END GENERATE bfm_g;
   
      

  dut: bk2fiber_chan  
generic map
(  
   SIM               => SIM , ---;
   SERDES_5G_EN      => SERDES_5G_EN , ---;
   ETHPORT_NUM       => ETHPORT_NUM  , --- --how many eth port 
   FIBER_NUM         => FIBER_NUM    , ---
   BKHSSI_NUM        => BKHSSI_NUM     ---
) 
port map
(
  
    nRST_bk_rxclk         => nRST_bk_rxclk        ,
    rx_bk_clk             => rx_bk_clk            ,
    rx_bk_parallel_data   => rx_bk_parallel_data  , 
    rx_bk_control         => rx_bk_control        , 
    
    nRST_txclk           => nRST_txclk       ,
    txclk_i              => txclk_i          ,
    xgmii_wren           => xgmii_wren       ,
    xgmii_data_out       => xgmii_data_out   ,
    xgmii_control        => xgmii_control    ,
    
    
    p_Frame_en_txc       => p_Frame_en_txc    ,
    p_Wren_txc           => p_Wren_txc        ,
    p_Data_txc           => p_Data_txc        ,
    p_Addr_txc           => p_Addr_txc        ,
    cur_slot_num         => cur_slot_num      ,

    
     secret_data          =>  secret_data      ,
                          
     hdr_enable           =>  hdr_enable       ,
     hdr_type             =>  hdr_type         ,
     hdr_rr               =>  hdr_rr           ,
     hdr_rg               =>  hdr_rg           ,
     hdr_rb               =>  hdr_rb           ,
     hdr_gr               =>  hdr_gr           ,
     hdr_gg               =>  hdr_gg           ,
     hdr_gb               =>  hdr_gb           ,
     hdr_br               =>  hdr_br           ,
     hdr_bg               =>  hdr_bg           ,
     hdr_bb               =>  hdr_bb           ,
     hdr_coef             =>  hdr_coef         ,
     hlg_type             =>  hlg_type      
);

 

end beha;