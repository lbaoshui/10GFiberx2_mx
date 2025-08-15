
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_CRC32_D8.all;

entity rt_param_store is
generic
(  sim     : std_logic := '0';
   IS_5G    : std_logic ;
   P_W     : INTEGER   := 4  ; ---Depend on IS_BACK AND eth_num
   ETH_IDX : INTEGER   := 0  ; ---STARTING INDEX ------
   ETH_NUM : INTEGER   := 10 ;
   REALTIME_PARAM_EN   : std_logic:= '1'
);
port
(
    nRST            : in std_logic ;
    clk_i           : in std_logic ;
    p_Frame_en_i    : in std_logic ;
    p_Wren_i        : in std_logic ;
    p_Data_i        : in std_logic_vector(7 downto 0);
    p_Addr_i        : in std_logic_vector(10 downto 0);
 
	
	tx_rt_rdaddr    : in  std_logic_vector(11 downto 0);
    rt_rdata        : out std_logic_vector(72*(ETH_NUM/2)-1 downto 0);
	
    rt_area_brdcast          : out std_logic := '0';
    rt_gamut_brdcast         : out std_logic := '0';
    rt_bright_brdcast        : out std_logic := '0';
	
    rt_area_word_length      : out std_logic_vector(8 downto 0);
    rt_g1_word_length        : out std_logic_vector(8 downto 0);
    rt_g2_word_length        : out std_logic_vector(8 downto 0);
    rt_bright_word_length    : out std_logic_vector(8 downto 0);
	
	rt_area_eth_arrived      : out std_logic_vector(ETH_NUM-1 downto 0);
	rt_gamut1_eth_arrived	 : out std_logic_vector(ETH_NUM-1 downto 0);
	rt_gamut2_eth_arrived	 : out std_logic_vector(ETH_NUM-1 downto 0);
	rt_bright_eth_arrived	 : out std_logic_vector(ETH_NUM-1 downto 0);
		
    rt_area_para_en          : out std_logic := '0';
    rt_bright_para_en        : out std_logic := '0';
    rt_gamut_para_en         : out std_logic := '0';
	frm8a_rd_point           : in  std_logic_vector(9 downto 0);
	frm8a_man_en             : in  std_logic	;
	frm8a_wr_point_o         : out std_logic_vector(9 downto 0);
	
	real_eth_num_conv        : in std_logic_vector(3 downto 0)


   );
end rt_param_store;

architecture beha of rt_param_store is

constant SEL_P : integer := 1;
constant A_W   : integer := 8; ---

---recv 0xcc frame
-- recv RT PARAM FRAME HERE
--crc8

constant FT_RT_PARAM      : std_logic_vector(7 downto 0):= X"8A" ;
constant FT_RT_BRIGHT     : std_logic_vector(7 downto 0):= X"44" ;
constant FT_RT_GAMUT      : std_logic_vector(7 downto 0):= X"4B" ;
constant OFF_SUBBOARD     :  INTEGER := 1 ;

signal down_wrnum       :  std_logic_vector(10 downto 0); --64bit
signal down_wrcnt       :  integer range 0 to 7 ; --64bit
signal down_lastw       :  std_logic := '0';

signal downp_wdata       : std_logic_vector(71 downto 0) := (others=>'0');
signal p_downlink_length : std_logic_vector(11 downto 0) := (others=>'0');
signal p_downlink_done   : std_logic := '0';
signal down_wren          : std_logic := '0';
signal rt_wren_all        : std_logic_vector((ETH_NUM/2)-1 DOWNTO 0):=(OTHERS=>'0');
signal rt_area_wren_all   : std_logic_vector((ETH_NUM/2)-1 DOWNTO 0):=(OTHERS=>'0');
signal rg1_wren_all       : std_logic_vector((ETH_NUM/2)-1 DOWNTO 0):=(OTHERS=>'0');
signal rg2_wren_all       : std_logic_vector((ETH_NUM/2)-1 DOWNTO 0):=(OTHERS=>'0');
signal rbrg_wren_all      : std_logic_vector((ETH_NUM/2)-1 DOWNTO 0):=(OTHERS=>'0');
signal rt_wren_patt      : std_logic_vector((ETH_NUM/2)-1 DOWNTO 0):=(OTHERS=>'0');
signal p_downlink_waddr  : std_logic_vector(A_W downto 0) := (others=>'0');
signal rt_param_portnum  : std_logic_vector(7 downto 0) := (others=>'0');
signal rt_subfrm_type    : std_logic_vector(7 downto 0) := (others=>'0');

signal downlink_done_d1 : std_logic := '0';

signal down_append_en : std_logic := '0';

component paramBlkRam2560x72 is
        port (
            data      : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
            q         : out std_logic_vector(71 downto 0);                    -- dataout
            wraddress : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- wraddress
            rdaddress : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- rdaddress
            wren      : in  std_logic                     := 'X';             -- wren
            clock     : in  std_logic                     := 'X'              -- clk
        );
end component paramBlkRam2560x72;



    signal cur_eth_sel    : integer range 0 to 20 -1 := 0;

    signal dly_eth_index  : std_logic_vector(P_W*(SEL_P+1)-1 DOWNTO 0);
    signal dly_pushen     : std_logic_vector(1*SEL_P  DOWNTO 0);
    signal dly_push_1st   : std_logic_vector(1*SEL_P  DOWNTO 0);
    signal dly_is_rt      : std_logic_vector(1*SEL_P  DOWNTO 0);
    signal dly_is_brdcast : std_logic_vector(1*SEL_P  DOWNTO 0);



    SIGNAL port_cnt        : std_logic_vector(P_W-1 downto 0)  ;
    --after 12 BYTE MAC
    constant CRC_MAC_INIT  : std_logic_vector(31 downto 0):=X"746110FC";
    signal  crc_data       : std_logic_vector( 7 downto 0) ;
    signal  crc_buf        : std_logic_vector(31 downto 0) ;
    signal  crc_res        : std_logic_vector(31 downto 0):=(others=>'1');
    signal crc_load_en     : std_logic:='0';
    signal crc_push_en     : std_logic:='0';
    signal rt_p_frm_en     : std_logic := '0';
    signal rt_p_is_brdcast          : std_logic := '0';
    signal rt_p_sched_brdcast       : std_logic := '0';

     
    signal rt_downdata_en           : std_logic := '0';


    signal tx_is_brdcast            : std_logic := '0';
    signal hit_eth                  : std_logic := '0';
	signal cur_eth_num              : std_logic_vector(P_W-1 downto 0):=(others=>'0');
	signal cur_eth_num_buf          : std_logic_vector(7 downto 0):=(others=>'0');
	signal rt_frm_type              : std_logic_vector(7 downto 0):=(others=>'0');
	
    ---shuttr sync or bright or gamut frame 
   signal   rt_area_frm_en    : std_logic := '0';
   signal   rt_bright_frm_en  : std_logic := '0';
   signal   rt_shutter_frm_en : std_logic := '0';
   signal   rt_gamut_frm_en   : std_logic := '0';
   signal   rcv_frmtype       : std_logic_vector(7 downto 0); ---rcv card frame type 
   signal   tsubfrm_idx        : std_logic_vector(7 downto 0); 

    signal down_rt_waddr   : std_logic_vector(11 downto 0);
    signal downw_rt_msb    : std_logic_vector(2 downto 0);
	signal frm8a_wr_point  : std_logic_vector(9 downto 0);
	

    
begin 
    process(nRST,clk_i)
    begin
        if nRST = '0' then
            crc_res <= X"FFFFFFFF";
        elsif rising_edge(clk_i) then
            if crc_load_en = '1' then
              crc_res <= CRC_MAC_INIT ;---after 12 BYTE MAC ADDRESS
            elsif crc_push_en = '1' then
              crc_res <= nextCRC32_D8 (crc_data,crc_res);
            end if;
        end if;
    end process;
    process(crc_res)
    begin
        for i in 0 to 3 loop
          for j in 0 to 7 loop
             crc_buf((3-i)*8+ j) <= not crc_res(i*8+7-j);
          end loop;
        end loop;
    end process;



    process(nRST,clk_i)
    begin 
        if nRST = '0' then 
           cur_eth_num_buf <= (others=>'0');
        elsif rising_edge(clk_i) then 

			if rt_p_frm_en = '1' then
				if rt_param_portnum = X"FF" then
					cur_eth_num_buf <= (others=>'0');---FF start from eth 0
				elsif IS_5G ='0' then
                    if ETH_IDX = 0 then
					    cur_eth_num_buf <= rt_param_portnum;
				    else
					    cur_eth_num_buf <= rt_param_portnum-real_eth_num_conv;
                    end if;
                ELSE --5G
                    --SHOULD BE ZERO ------
                     if ETH_IDX = 0 then
					    cur_eth_num_buf <= rt_param_portnum;
				    elsIF ETH_IDX = 1 THEN
                        cur_eth_num_buf <= rt_param_portnum-1;
                    ELSIF ETH_IDX = 2 THEN
                        cur_eth_num_buf <= rt_param_portnum-2;
                    ELSE
                        cur_eth_num_buf <= rt_param_portnum-3;
                    END IF;
				end if;
			end if;
       end if;
    end process;
    
     process(nRST,clk_i)
    begin 
        if nRST = '0' then
            rt_p_is_brdcast        <= '0';
            rt_area_brdcast        <= '0';
            rt_gamut_brdcast       <= '0';
            rt_bright_brdcast      <= '0';
            rt_wren_patt           <= (others=>'0');
			rt_area_eth_arrived    <= (others=>'0') ;
			rt_gamut1_eth_arrived  <= (others=>'0') ;
			rt_gamut2_eth_arrived  <= (others=>'0') ;
			rt_bright_eth_arrived  <= (others=>'0') ;
						
        elsif rising_edge(clk_i) then 

            
            if rt_param_portnum = X"FF" and rt_downdata_en = '1' THEN  
                rt_p_is_brdcast <= '1'; --current is broadcast 
                if (rt_area_frm_en = '1'  )  then  rt_area_brdcast   <= '1' ;  end if;
                if(rt_gamut_frm_en = '1'  )  then  rt_gamut_brdcast  <= '1' ;  end if;
                if(rt_bright_frm_en= '1'  )  then  rt_bright_brdcast <= '1' ;  end if;
            elsif rt_downdata_en = '1' then
                rt_p_is_brdcast <= '0';
                if(rt_area_frm_en   = '1' )  then  rt_area_brdcast   <= '0';    end if;
                if(rt_gamut_frm_en  = '1' )  then  rt_gamut_brdcast  <= '0';    end if;
                if(rt_bright_frm_en = '1' )  then  rt_bright_brdcast <= '0';    end if;
            end if;
           
            if rt_param_portnum = X"FF"  THEN  
                if rt_p_frm_en = '1' and rt_downdata_en = '1' then 
                    rt_wren_patt <= (others=>'1'); 
                else 
                    rt_wren_patt <= (others=>'0');
                end if;
            else  
                rt_wren_patt <= (others=>'0');
                if rt_downdata_en = '1' then               
                   rt_wren_patt(conv_integer(cur_eth_num_buf(P_W-1 downto 1))) <= rt_p_frm_en; 
                end if; 
            end if;
			
            if rt_param_portnum = X"FF" and rt_downdata_en = '1' THEN  
                if(rt_area_frm_en = '1'  )                          then  rt_area_eth_arrived    <= (0=>'1',others=>'0') ;  end if;
                if(rt_gamut_frm_en = '1' and tsubfrm_idx(0)='0'  )  then  rt_gamut1_eth_arrived  <= (0=>'1',others=>'0') ;  end if;
                if(rt_gamut_frm_en = '1' and tsubfrm_idx(0)='1'  )  then  rt_gamut2_eth_arrived  <= (0=>'1',others=>'0') ;  end if;
                if(rt_bright_frm_en= '1'  )  						then  rt_bright_eth_arrived  <= (0=>'1',others=>'0') ;  end if;
            elsif rt_downdata_en = '1' then
                if(rt_area_frm_en   = '1' )                         then  rt_area_eth_arrived(conv_integer(cur_eth_num_buf))    <= '1' ;  end if;
                if(rt_gamut_frm_en = '1' and tsubfrm_idx(0)='0'  )  then  rt_gamut1_eth_arrived(conv_integer(cur_eth_num_buf))  <= '1' ;  end if;
                if(rt_gamut_frm_en = '1' and tsubfrm_idx(0)='1'  )  then  rt_gamut2_eth_arrived(conv_integer(cur_eth_num_buf))  <= '1' ;  end if;
                if(rt_bright_frm_en= '1'  )  						then  rt_bright_eth_arrived(conv_integer(cur_eth_num_buf))  <= '1' ;  end if;
            end if;			
			
			
        end if;
    end process;
    
    process(nRST,clk_i)
    begin 
        if nRST = '0' then
            rt_p_frm_en          <= '0';
            downlink_done_d1     <= '0';
            down_append_en     <= '0';
            crc_load_en          <= '0';
            crc_push_en          <= '0';
          
            down_lastw           <= '0';
            rt_downdata_en       <= '0';
            rt_wren_all          <= (OTHERS=>'0');
            rg1_wren_all          <= (OTHERS=>'0');
            rg2_wren_all          <= (OTHERS=>'0');
            rbrg_wren_all         <= (OTHERS=>'0');
            hit_eth               <= '0';
			
			rt_area_para_en       <= '0';
			rt_bright_para_en     <= '0';
			rt_gamut_para_en      <= '0';
			
			rt_area_word_length   <= (others=>'0');
			rt_bright_word_length <= (others=>'0');
			rt_g1_word_length     <= (others=>'0');
			rt_g2_word_length     <= (others=>'0');
			frm8a_wr_point        <= (others=>'0');
			
			
        elsif rising_edge(clk_i) then 
            crc_data <= p_Data_i;  
            
            if p_Frame_en_i = '1' then  

                down_lastw        <= '0';
                if p_Wren_i = '1' and p_Addr_i = 0 then 
                    rt_p_frm_en       <= '0';
                    rt_area_frm_en    <= '0';
                    rt_bright_frm_en  <= '0';
                    rt_shutter_frm_en <='0';
                    rt_gamut_frm_en   <= '0';

                    if p_Data_i = FT_RT_PARAM and REALTIME_PARAM_EN = '1' then				-- frm_8A
                       rt_p_frm_en     <= '1';
                       rt_area_frm_en  <= '1';
                       rt_frm_type     <= p_Data_i ; --param type                        
                    elsif  p_Data_i = FT_RT_BRIGHT and REALTIME_PARAM_EN = '1' then			-- frm_44
                        rt_bright_frm_en<= '1';
                        rt_p_frm_en     <= '1';
                        rt_frm_type     <= p_Data_i ; --param type   
                    elsif p_Data_i  = FT_RT_GAMUT and REALTIME_PARAM_EN = '1' then			-- frm_4b
                       rt_gamut_frm_en <= '1';
                       rt_p_frm_en     <= '1';
                       rt_frm_type     <= p_Data_i ; --param type   
                    else 
                       rt_frm_type     <= p_Data_i ; --param type
                       rt_p_frm_en     <= '0';
                    end if;                      
                end if; 
                
                if p_Wren_i = '1' and   p_Addr_i = 2+OFF_SUBBOARD then ---real param subframe idx here 
                    tsubfrm_idx <= p_Data_i;
                end if;


                if p_Wren_i = '1' and rt_p_frm_en = '1' then
                    down_wren         <= ('0');
                    crc_push_en       <= '0';
                    crc_load_en       <= '0';
                    downlink_done_d1  <= '0';
                    down_append_en    <= '0';
                    if p_Addr_i = 0+OFF_SUBBOARD then
                        rt_param_portnum <= (p_Data_i);
                        if p_Data_i = X"FF" or ( p_Data_i >= ETH_IDX *conv_integer(real_eth_num_conv) AND p_Data_i < (ETH_IDX+1) *conv_integer(real_eth_num_conv)) then 
                            hit_eth <= '1';
                        else
                            hit_eth <= '0';
                        end if;
						rt_downdata_en <= '0';---must be here 
                    end if;
                    if p_Addr_i = 4+OFF_SUBBOARD and hit_eth = '1' then
                        p_downlink_length(7 downto 0) <= p_Data_i;
                    end if;
                    if p_Addr_i = 5+OFF_SUBBOARD and hit_eth = '1' then
                        p_downlink_length(11 downto 8) <= p_Data_i(3 downto 0);
                    end if;
                    if p_Addr_i = 6+OFF_SUBBOARD  then
                        rt_subfrm_type <= p_Data_i;
                        if p_Data_i = X"01" or hit_eth = '0' THEN
                            rt_downdata_en <= '0';
                        elsif p_Data_i = X"02" THEN
                            rt_downdata_en<= '1';
                        else
                            rt_downdata_en <= '0';
                        end if;
                    end if;
                    if p_Addr_i = 7+OFF_SUBBOARD and hit_eth = '1' then --sub
                        if rt_subfrm_type = x"01"  then
                            case(rt_frm_type) is  
                                when  FT_RT_PARAM => --area                                
									rt_area_para_en   <= p_Data_i(0);
                                when FT_RT_BRIGHT => --Bright 
                                    rt_bright_para_en <= p_Data_i(0);
                                when FT_RT_GAMUT  =>
                                    rt_gamut_para_en  <= p_Data_i(0);
                                when others=> null;
                            end case; 
                        end if;
                    end if;

                    if p_ADdr_i = 4 + OFF_SUBBOARD and hit_eth = '1'  then
                        ---  down_wrcnt <= 7;  --TRIG FOR NEXT CYCLE WRITTING
                    elsif p_ADdr_i = 5 + OFF_SUBBOARD and hit_eth = '1'  then --DOES NOT CARE THE HEADER ,
                        ---downp_wdata <= X"01"&X"D555555555555555FB"; --MUST BE OLD DATA
                        down_wrcnt <= 0;
                        down_wrnum <= (others=>'0'); ------
                    elsif p_ADdr_i = 6 + OFF_SUBBOARD and hit_eth = '1'  then
                         -----------header
                        downp_wdata(71 downto 64)  <= (others=>'0');
                        downp_wdata (31 downto 16) <=  X"00"&cur_eth_num_buf;
                        downp_wdata (15 downto 0)  <=  X"2211";
                        down_wrcnt                 <= 4;
                        crc_load_en                <= '1';
                        crc_push_en                <= '0';

                    elsif hit_eth ='1' and  p_Addr_i >= 7+OFF_SUBBOARD and rt_subfrm_type = x"02" then --
                        downp_wdata(down_wrcnt*8+7 downto down_wrcnt*8) <= p_Data_i;
                        crc_load_en   <= '0';
                        crc_push_en   <= '1';
                        down_wrnum <= down_wrnum + '1';
                        if down_wrcnt = 7 then
                           down_wrcnt <= 0;
                        else
                           down_wrcnt <= down_wrcnt + 1;
                        end if;
                    else
                       crc_load_en <= '0';
                       crc_push_en <= '0';
                    end if;

                    if down_wrcnt = 7 and rt_downdata_en = '1' and hit_eth = '1'  then
                        -- down_wren <= '1';
                        down_wren   <= '1';
                        rt_wren_all <= rt_wren_patt; ---
                    else
                        rt_wren_all <= (others=>'0');
                        down_wren   <= ( '0');
                    end if;
                    if hit_eth = '1' and down_wrnum = (p_downlink_length - 1) and p_Addr_i > 8+OFF_SUBBOARD then
                        p_downlink_done <= '1';
                    end if;
                else
                    down_wren   <='0';
                    rt_wren_all <= (others=>'0');
                    crc_load_en <= '0';
                    crc_push_en <= '0';
                end if;
            else
                   rt_wren_all <= (OTHERS=>'0');
                   crc_push_en <= '0';
                   crc_load_en <= '0';
                   downlink_done_d1 <= p_downlink_done;
                   if downlink_done_d1 = '1'   then
                       down_wren       <= ('1');
                       rt_wren_all     <= rt_wren_patt; ---
                       case (down_wrcnt ) is    --has some data left
                           when 0      => downp_wdata(71 downto  0) <=X"F0"& X"070707FD"&CRC_buf;   down_append_en<='0';down_lastw<='1';
                           when 1      => downp_wdata(71 downto  8) <=X"E0"& X"0707FD"&CRC_buf;     down_append_en<='0';down_lastw<='1';
                           when 2      => downp_wdata(71 downto 16) <=X"C0"& X"07FD"&CRC_buf;       down_append_en<='0';down_lastw<='1';
                           when 3      => downp_wdata(71 downto 24) <=X"80"& X"FD"&CRC_buf;         down_append_en<='0';down_lastw<='1';
                           when 4      => downp_wdata(71 downto 32) <=X"00"&  CRC_buf(31 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when 5      => downp_wdata(71 downto 40) <=X"00"&  CRC_buf(23 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when 6      => downp_wdata(71 downto 48) <=X"00"&  CRC_buf(15 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when 7      => downp_wdata(71 downto 56) <=X"00"&  CRC_buf( 7 DOWNTO 0); down_append_en<='1';down_lastw<='0';
                           when others => downp_wdata(71 downto 32) <=X"00"&  CRC_buf;              down_append_en<='1';down_lastw<='0';
                       end case;
                   elsif  down_append_en = '1' then
                        down_append_en <= '0';
                        down_lastw       <= '1';
                        case (down_wrcnt ) is    --has some data left
                           when 4      => rt_wren_all <= rt_wren_patt; down_wren <= '1';downp_wdata(71 downto 0)  <=X"FF"&  X"07070707070707FD";
                           when 5      => rt_wren_all <= rt_wren_patt; down_wren <= '1';downp_wdata(71 downto 0) <=X"FE"&  X"070707070707FD"&  CRC_buf(31 DOWNTO 24);
                           when 6      => rt_wren_all <= rt_wren_patt; down_wren <= '1';downp_wdata(71 downto 0) <=X"FC"&  X"0707070707FD"&  CRC_buf(31 DOWNTO 16);
                           when 7      => rt_wren_all <= rt_wren_patt; down_wren <= '1';downp_wdata(71 downto 0) <=X"F8"&  X"07070707FD"&  CRC_buf(31 DOWNTO 8);
                           when others => rt_wren_all <= (others=>'0');down_wren <= '0';downp_wdata(71 downto 0) <=X"FF"&  X"0707070707070707";
                       end case;
                   else
                       down_append_en  <= '0';
                       down_lastw      <= '0';
                       down_wren       <= ('0');
                       rt_wren_all     <= (OTHERS=>'0');
                   end if;


                   p_downlink_done <= '0';

              end if;


            if p_Addr_i = 8 + OFF_SUBBOARD and p_Wren_i = '1' and  rt_p_frm_en = '1'  then
                if (rt_p_frm_en = '1' and rt_p_is_brdcast ='1') then
                    p_downlink_waddr <= (others=>'0'); 

                elsif (rt_p_frm_en = '1') then
                    p_downlink_waddr    <= (others=>'0'); 
					if IS_5G = '0' then
						p_downlink_waddr(A_W) <= rt_param_portnum(0); ----
					else
						p_downlink_waddr(A_W) <= '0';
					end if;
                else
                    p_downlink_waddr <= (others=>'0'); ----p_downlink_waddr <= (others => '0');
                end if;

            elsif down_wren = '1' then
                p_downlink_waddr <= p_downlink_waddr + '1';
            end if;

            if down_wren = '1' and down_lastw = '1' then
                if rt_p_frm_en = '1' then 
                    if (rt_area_frm_en = '1') then
                        rt_area_word_length   <= ("0"&p_downlink_waddr(A_W-1 downto 0))+1;
                    elsif (rt_bright_frm_en = '1' ) then 
                        rt_bright_word_length <=  ("0"&p_downlink_waddr(A_W-1 downto 0))+1;
                    elsif (rt_gamut_frm_en ='1'  and tsubfrm_idx(0) ='0') then 
                        rt_g1_word_length    <=  ("0"&p_downlink_waddr(A_W-1 downto 0))+1;
                    elsif (rt_gamut_frm_en = '1'  and tsubfrm_idx(0) ='1') then 
                        rt_g2_word_length    <=  ("0"&p_downlink_waddr(A_W-1 downto 0))+1;
                    else  ---no 
                    end if;
					
					
					if (rt_area_frm_en = '1') then
						frm8a_wr_point(conv_integer(cur_eth_num_buf(P_W-1 downto 0))) <= not frm8a_wr_point(conv_integer(cur_eth_num_buf(P_W-1 downto 0)));
					end if;
				
                end if;  
				

            end if;

        end if;
    end process;
   
    process(clk_i)
    begin
         if rising_edge(clk_i) then  
              if rt_area_frm_en = '1' then 
			    -- if  frm8a_man_en = '0' then 
					-- downw_rt_msb <= "000"; ----wr point
				-- else
					downw_rt_msb <= frm8a_wr_point(conv_integer(cur_eth_num_buf(P_W-1 downto 0)))&"00";
				-- end if;
              elsif rt_gamut_frm_en = '1'   and  tsubfrm_idx(0)='0' then 
                  downw_rt_msb <= "001";
              elsif rt_gamut_frm_en = '1'   and  tsubfrm_idx(0)='1' then 
                  downw_rt_msb <= "010";
              else 
                  downw_rt_msb <= "011";
              end if;
        end if;
    end process; 
    down_rt_waddr <= downw_rt_msb & p_downlink_waddr; ----
	frm8a_wr_point_o <= frm8a_wr_point ;
        
    rt_param_i: for i in 0 to (ETH_NUM/2) -1 generate 

        rt_area_wren_all(i) <= rt_wren_all(i) and rt_area_frm_en   ;
        rg1_wren_all    (i) <= rt_wren_all(i) and rt_gamut_frm_en   when tsubfrm_idx(0)='0' else '0';
        rg2_wren_all    (i) <= rt_wren_all(i) and rt_gamut_frm_en   when tsubfrm_idx(0)='1' else '0';
        rbrg_wren_all   (i) <= rt_wren_all(i) and rt_bright_frm_en ;
     
        rp_dram_i: paramBlkRam2560x72  
        port map(
            data      => downp_wdata , -- datain
            q         => rt_rdata  ( (i+1)*72-1 downto i*72) ,                    -- dataout
            wraddress => down_rt_waddr , -----p_downlink_waddr , -- wraddress
            rdaddress => tx_rt_rdaddr        , ----rt_raddr         , -- rdaddress
            wren      => rt_wren_all(i)  ,            -- wren
            clock     => clk_i     -- clk
        );
    end generate rt_param_i;



end beha;