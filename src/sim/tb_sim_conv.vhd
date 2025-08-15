library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;

entity tb_sim_conv is 
generic
(  SIM               : std_logic := '1';
   SERDES_5G_EN      : std_logic := '0';
   FIBER_NUM         : integer   := 2 ;
   ETHPORT_NUM       : integer   := 10 ;  -- PER FIBER 
   BKHSSI_NUM        : integer   := 4 ; 
   G12_9BYTE_EN      : STD_LOGIC := '1'   --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS      
);
end tb_sim_conv;

architecture beha of tb_sim_conv is 
component bfm_param_tx is 
   generic 
   (  sim     : std_logic := '0';
      IS_BACK : std_logic := '0'; ---main or backup 
      P_W     : INTEGER   := 4  ; ---Depend on IS_BACK AND eth_num
      ETH_NUM : INTEGER   := 10 
   );
   port 
   (
        nRST            :  in std_logic := '0';
        clk_i           :  in std_logic := '0'; 
        p_Frame_en_o    :  out  std_logic := '0';
        p_Wren_o        :  out  std_logic := '0';
        p_Data_o        :  out  std_logic_vector( 7 downto 0) := (others=>'0');
        p_Addr_o        :  out  std_logic_vector(10 downto 0) := (others=>'0');
        cur_slot_num_o  :  out  std_logic_vector(15 downto 0) := (others=>'0') 
   
   );
end component;

component bk2fiber_conv is
generic
(  SIM               : std_logic := '0';
   SERDES_5G_EN      : std_logic := '0';
   FIBER_NUM         : integer   ;
   ETHPORT_NUM       : integer   := 10 ;  -- PER FIBER 
   BKHSSI_NUM        : integer   ; 
   G12_9BYTE_EN      : STD_LOGIC := '1'   --'1': 9 BYTES 2 PIXELS ; '0': 10BYTES 2 PIXELS      
);
port 
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);
    
    
    nRST_conv           : in  std_logic    ; ---
    convclk_i              : in  std_logic    ; --200M almost    
    p_Frame_en_conv         : in std_logic ;
    p_Wren_conv           : in std_logic ;
    p_Data_conv           : in std_logic_vector(7 downto 0);
    p_Addr_conv           : in std_logic_vector(10 downto 0);
    cur_slot_num         : in std_logic_vector(15 downto 0);
  
    xgmii_txclk          : in  std_logic_vector(FIBER_NUM-1 downto 0) ;
    nRST_xgmii           : in  std_logic_vector(FIBER_NUM-1 downto 0) ;
    xgmii_data           : out std_logic_vector(FIBER_NUM*64-1 downto 0);
    xgmii_control        : out std_logic_vector(FIBER_NUM*8 -1 downto 0)
); 
end component ;

signal    nRST_bk_rxclk         :  std_logic_vector(BKHSSI_NUM-1  downto 0) := (others=>'0');
signal    rx_bk_clk             :  std_logic_vector(BKHSSI_NUM-1  downto 0) := (others=>'0');
signal    rx_bk_parallel_data   :  std_logic_vector(BKHSSI_NUM*64-1 downto 0);
signal    rx_bk_control         :  std_logic_vector(BKHSSI_NUM*8 -1 downto 0);
     
signal    nRST_txclk           :   std_logic    :=( '0'); ---
signal    txclk_i              :   std_logic    :=( '0'); --200M almost 
signal    xgmii_wren           :   std_logic    :=( '0');
--signal    xgmii_data_out       :   std_logic_vector(FIBER_NUM*64-1 downto 0);
--signal    xgmii_control        :   std_logic_vector(FIBER_NUM*8 -1 downto 0);
signal xgmii_txclk          :    std_logic_vector(FIBER_NUM-1 downto 0) := (others=>'0');
signal nRST_xgmii           :    std_logic_vector(FIBER_NUM-1 downto 0) := (others=>'0');
signal xgmii_data           :   std_logic_vector(FIBER_NUM*64-1 downto 0);
signal xgmii_control        :   std_logic_vector(FIBER_NUM*8 -1 downto 0);
     
     
signal    p_Frame_en_conv       :  std_logic := '0';
signal    p_Wren_conv           :  std_logic := '0';
signal    p_Data_conv           :  std_logic_vector(7 downto 0);
signal    p_Addr_conv           :  std_logic_vector(10 downto 0);
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
 type ARRAY_2x16  is array (0 to 3)  of std_logic_vector(15 downto 0);                        
signal xcnt : ARRAY_2x16;                        
signal ycnt : ARRAY_2x16;  

                      
begin 
     xgmii_txclk  <= not xgmii_txclk after 4 ns; 
     nRST_xgmii   <= (others=>'1') after 11 ns; 

     nRST_txclk           <= '1' after 11 ns ; ---
     txclk_i              <= not txclk_i after 3 ns ;--200M almost 

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
   
    bfm_ctrl:bfm_param_tx   
   generic map
   (  sim      => sim    ,
      IS_BACK  => '0', ---main or backup 
      P_W      => 4    , ---Depend on IS_BACK AND eth_num
      ETH_NUM  => ETHPORT_NUM 
   ) 
   port map
  (
     nRST               => nRST_txclk  ,
     clk_i              => txclk_i     ,
     p_Frame_en_o       => p_Frame_en_conv     ,
     p_Wren_o           => p_Wren_conv         ,
     p_Data_o           => p_Data_conv         ,
     p_Addr_o           => p_Addr_conv         ,
     cur_slot_num_o     => cur_slot_num       

);  

  dut: bk2fiber_conv  
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
    
    nRST_conv              => nRST_txclk       ,
    convclk_i              => txclk_i          , 
    
    p_Frame_en_conv       => p_Frame_en_conv    ,
    p_Wren_conv           => p_Wren_conv        ,
    p_Data_conv           => p_Data_conv        ,
    p_Addr_conv           => p_Addr_conv        ,
    cur_slot_num          => cur_slot_num      ,

    xgmii_txclk          =>  xgmii_txclk    ,
    nRST_xgmii           =>  nRST_xgmii     ,
    xgmii_data           =>  xgmii_data     ,
    xgmii_control        =>  xgmii_control  
      
);

 

end beha;