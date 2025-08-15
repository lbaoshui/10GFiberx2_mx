library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;
use work.PCK_CRC32_D8.all;

entity bfm_param_tx is 
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
     cur_slot_num_o    :  out  std_logic_vector(15 downto 0) := (others=>'0') 

);
end bfm_param_tx;

architecture beha of bfm_param_tx is 

 


signal   vsync_neg_i     :   std_logic ;
    ---------------------------------------------------
 

 type ARRAY_2x16  is array (0 to 1)  of std_logic_vector(15 downto 0);                        
signal xcnt : std_logic_vector(15 downto 0);                        
signal ycnt : std_logic_vector(15 downto 0); 

signal MAC_I: std_logic_vector(32*8-1 downto 0);
signal crc_c : std_logic_vector(31 downto 0);
signal data_c: std_logic_vector(7 downto 0);

constant FT_FORWARD_PARAM : std_logic_vector(7 downto 0):= X"CC" ;
constant FT_RT_PARAM      : std_logic_vector(7 downto 0):= X"8A" ; 
signal   eth_port         : std_logic_vector(7  downto 0)   := X"FF" ; 
signal   rt_subfrm_type1  : std_logic_vector(7  downto 0)   := X"02" ; 
signal   rt_subfrm_type2  : std_logic_vector(7  downto 0)   := X"01" ; 
signal   data_len      : std_logic_vector(15 downto 0)       ; 

signal    p_Frame_en_i    :   std_logic := '0';
signal    p_Wren_i        :   std_logic := '0';
signal    p_Data_i        :   std_logic_vector( 7 downto 0) := (others=>'0');
signal    p_Addr_i        :   std_logic_vector(10 downto 0) := (others=>'0');
signal    cur_slot_num    :   std_logic_vector(15 downto 0) := (others=>'0');



begin 
     p_Frame_en_o   <=  p_Frame_en_i  ;
     p_Wren_o       <=  p_Wren_i      ;
     p_Data_o       <=  p_Data_i      ;
     p_Addr_o       <=  p_Addr_i      ;
     cur_slot_num_o <=  cur_slot_num  ;
   ---  nRST            <= '1' after 11 ns;
   ---  clk_i           <= not clk_i after 4 ns;
     
     
    MAC_I(12*8-1 DOWNTO 0) <= X"665544332222665544332211";
    data_c <= MAC_I( conv_integer( xcnt(3 downto 0))*8+7 downto conv_integer( xcnt(3 downto 0))*8);
    process(nRST,clk_i)
    begin 
        if nRST = '0' then 
            xcnt <= (others=>'0');
            ycnt <= (others=>'0');
            crc_c <= (others=>'1');
        elsif rising_edge(clk_i) then 
            if ycnt = 1 then 
              if xcnt < 12 then 
                 crc_c <= nextCRC32_D8(data_c,crc_c);
              elsif xcnt = 1024 then 
                 crc_c <= (others=>'1');
              end if;
            end if;              
                            
              
        
            if xcnt = 1024 then 
               xcnt <= (others=>'0');
               if ycnt = 256 then 
                  ycnt <= (others=>'0');
               else 
                  ycnt <= ycnt +1 ;
               end if;
            else 
               xcnt <= xcnt  + 1 ;
            end if;
        end if;
    end process;
    
    vsync_neg_i <= '1' when ycnt = 1 and xcnt = 1 else '0';
    
    data_len  <= conv_std_logic_vector(31 ,16);
    p_Frame_en_i <= p_Wren_i;
    process(nRST,clk_i)
    begin 
        if nRST = '0' then 
           p_Wren_i <= '0';
        elsif rising_edge(clk_i) then 
            p_Addr_i <= xcnt(10 downto 0);
            p_Wren_i <= '0';
            if ycnt = 2 then 
                IF XCNT < data_len+7 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_FORWARD_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= X"07";
                else 
                  p_Data_i <= xcnt(7 downto 0); 
                end if; 
                
                
            elsif ycnt = 3 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"00";--- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if;    
            elsif ycnt = 4 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"01"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if; 
            elsif ycnt = 5 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"02"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if;  
            elsif ycnt = 6 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"03"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if;   

            elsif ycnt = 7 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"04"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if;  
            elsif ycnt = 8 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"05"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if; 
            elsif ycnt = 9 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"06"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if;  
            elsif ycnt = 10 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"07"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if;   

            elsif ycnt = 11 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"08"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if;
            elsif ycnt = 12 then
                IF XCNT < data_len+ 8 THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <= x"09"; --- eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type1; --DATA 
                elsif xcnt = 8 then 
                  p_Data_i <= x"02"; --02 frame 
                else 
                  p_Data_i <= ycnt(7 downto 0); 
                end if; 
                          
            elsif ycnt = 28 then 
                IF XCNT < data_len+ 8  THEN 
                     p_Wren_i <= '1';
                end if;
                if xcnt = 0 then 
                  p_Data_i <= FT_RT_PARAM;
                elsif xcnt = 1 then 
                  p_Data_i <=   eth_port;
                elsif xcnt = 5 then 
                  p_Data_i <= data_len(7 downto 0);
                elsif xcnt = 6 then 
                  p_Data_i <= data_len(15 downto 8);
                elsif xcnt = 7 then 
                  p_Data_i <= rt_subfrm_type2;
                elsif xcnt = 8 then 
                  p_DAta_i <= X"01";--ENALBE rt 
                else 
                  p_Data_i <= xcnt(7 downto 0); 
                end if;             
            elsif ycnt = 5 then 
            elsif ycnt = 6 then 
            elsif ycnt = 7 then 
            elsif ycnt = 8 then 
            elsif ycnt = 9 then 
            elsif ycnt = 10 then 
            else 
                p_Wren_i <= '0';
            end if;
        end if;
    end process;

  



end beha;