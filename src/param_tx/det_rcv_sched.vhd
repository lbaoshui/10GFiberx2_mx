
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;

----only for downparam_tx module 
entity det_rcv_sched is 
generic(

	UNIT_NUM     : INTEGER  := 4 ; --for fiber 2 or 4, for 5G 4 ;
	ETH_PER_UNIT : INTEGER  :=1 ;--EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
	IS_5G        : std_logic:= '1'
	
);
port  
(
    nRST : in  std_logic ;
    clk  : in  std_logic ;
    --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    cur_slot_num          : in std_logic_vector(15 downto 0);  

	
    frame_done          : in   std_logic ; --need one cycle for the status to switch 
    frame_rd_addr       : in   std_logic_vector(10 downto 0);
    frame_q             : out  std_logic_vector(7  downto 0);
    frame_len           : out  std_logic_vector(10 downto 0);
	abort_frame_dur_o     : out  std_logic ;

	
    frame07_req           : out  std_logic ;
    frame07_ack           : in   std_logic ;
	
	frame07_unit_idx      : out  std_logic_vector(2 downto 0);
	frame07_unit_left     : out  std_logic_vector(5 downto 0);
	
    quick08_filter_en     :  out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;--up 08 filtered or not -----
    quick08_flg           :  out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;
    up08_timeout          :  in  std_logic_vector(UNIT_NUM-1 downto 0) 	;
    Up08_net_rel_idx      :  out std_logic_vector(7 downto 0)  ;

	real_eth_num_conv     :  in  std_logic_vector(3 downto 0)	

);
end det_rcv_sched ;


architecture beha of det_rcv_sched is

type ST_DEF_S IS (ST_IDLE, ST_PREPARE, ST_PUT_REQ, ST_READ_HEADER,ST_WAIT_08DONE, ST_SCHED,ST_ABORT_DETRCV,ST_TURN,ST_WAIT_TX_DONE);
signal pstate : ST_DEF_S:= ST_IDLE; 

signal frame07_all_done   : std_logic :='0';

component rcvparam_store is 
generic(
	DET_RCV_MAN_EN  : integer 

);
port  
(
    nRST : in  std_logic ;
    clk  : in  std_logic ;
    --pbus 
    p_Frame_en_i          : in   std_logic ;
    p_Wren_i              : in   std_logic ;
    p_Data_i              : in   std_logic_vector(7 downto 0);
    p_Addr_i              : in   std_logic_vector(10 downto 0);  
    cur_slot_num          : in   std_logic_vector(15 downto 0); 

    rd_done               : in   std_logic ; --need one cycle for the status to switch 
    rd_addr               : in   std_logic_vector(10 downto 0);
    rd_q                  : out  std_logic_vector(7  downto 0);
    rd_len                : out  std_logic_vector(10 downto 0);
	rd_empty              : out  std_logic ;
	

	abort_detect_rcv      : out  std_logic;
	abort_07_flag         : out  std_logic

	
);
end component ;
signal rd_empty : std_logic;
signal rd_addr               :  std_logic_vector(10 downto 0);
signal rd_q                  :  std_logic_vector(7  downto 0);
signal rd_len                :  std_logic_vector(10 downto 0);
signal abort_detect_rcv      :  std_logic;
signal unit_cal_en           :  std_logic;
signal    pack_len             :  std_logic_vector(10 downto 0);
signal abort_07_flag         :  std_logic;

component param_div_unit is 
generic ( 
UNIT_NUM    : INTEGER := 4 ; --for fiber 2 or 4, for 5G 4 ;
ETH_PER_UNIT: INTEGER := 1   --EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g; 
);
port 
(
   nRST          : in   std_logic ;
   clk           : in   std_logic ;   
   start_cal_en  : in   std_logic ;
   net_st_port   : in   std_logic_vector(5 downto 0); 
   div_int       : out  std_logic_vector(2 downto 0);
   div_resid     : out  std_logic_vector(5 downto 0);
   div_is_brdcast: out  std_logic;
   real_eth_num_conv  : in std_logic_vector(3 downto 0)
);
end component;
signal net_st_port        : std_logic_vector(7  downto 0);
signal net_num_m1         : std_logic_vector(7  downto 0);
signal div_left           : std_logic_vector(5 downto 0):=(others=>'0'); 
signal div_idx            : std_logic_vector(2 downto 0):=(others=>'0'); --at most 8 
signal div_is_brdcast     : std_logic := '0';
signal unit_is_broadc     : std_logic := '0';
signal unit_left          : std_logic_vector(5 downto 0):=(others=>'0'); 
signal unit_idx           : std_logic_vector(2 downto 0):=(others=>'0'); --at most 8 
signal eth_max_m1         : std_logic_vector(7 downto 0); --at most 
constant DPRAM_LATENCY : INTEGER := 2;
signal quick08_filt_disable : std_logic ;
signal rcv_frmType        : std_logic_vector(7  downto 0); -- in bytes 
signal frameCC_quick07_en      : std_logic := '0'; 
signal up08_timeout_d1         : std_logic_vector(UNIT_NUM-1 downto 0);
signal abort_detect_rcv_req    : std_logic;
signal abort_detect_rcv_ack    : std_logic;
signal abort_data              : std_logic_vector(7 downto 0);
signal abort_data_d1		   : std_logic_vector(7 downto 0);
signal wait_cnt                : std_logic_vector(1 downto 0);
signal abort_frame_dur         : std_logic;
signal abort_frm_len           : std_logic_vector(10 downto 0);

signal det_rcv_timeout_cnt : std_logic_vector(9 downto 0);
signal time_ms_en          : std_logic;
signal time_cnt            : std_logic_vector(17 downto 0);



CONSTANT FR_DETRCV_ABORT        :  std_logic_vector(7 downto 0) := X"2C";
CONSTANT FR_DETRCV_ABORT_LEGNTH :  std_logic_vector(15 downto 0) := X"0036";



begin



   
process(nRST,clk)
begin
	if nRST = '0' then
		quick08_flg <= (others=>'0');
	
	elsif rising_edge(clk) then 
  
  
		if (up08_timeout(conv_integer(unit_idx))) /= (up08_timeout_d1(conv_integer(unit_idx))) then 
			quick08_flg <= (others=>'0');
		elsif frameCC_quick07_en = '0' then  ---slow detect rcv card
			quick08_flg <= (others=>'0');
 		elsif frame07_ack = '1' and abort_frame_dur = '0' then
			quick08_flg <= (others=>'0');
			quick08_flg(conv_integer(unit_idx)) <= '1';
		end if; 
  
	end if;
end process;
 
 
process(nRST,clk)
begin 
	if nRST = '0' then
		abort_detect_rcv_req <= '0';	
	elsif rising_edge(clk) then
	
		if abort_detect_rcv_ack = '1' then
			abort_detect_rcv_req <= '0';
		elsif abort_detect_rcv = '1' then
			abort_detect_rcv_req <= '1';
		end if;
	end if;
end process; 

 
process(nRST,clk)
begin
	if nRST = '0' then
	
		unit_cal_en      <= '0';
		frame07_all_done <= '0';
		quick08_filt_disable <= '0';
		quick08_filter_en    <= (others=>'0');
		pstate <= ST_IDLE;
		rd_addr <= (others=>'0');
		wait_cnt <= (others=>'0');
		det_rcv_timeout_cnt   <=(others=>'0');
	elsif rising_edge(clk) then
		
		frame07_all_done <= '0';
		unit_cal_en      <= '0';
		abort_detect_rcv_ack <= '0';
		
		up08_timeout_d1  <= up08_timeout;
	
		case (pstate) is
		
			when ST_IDLE  =>
                if rd_empty = '0' then
					if abort_07_flag = '1' then
						pstate <= ST_TURN;
						frame07_all_done <= '1';
						abort_detect_rcv_ack <= abort_detect_rcv_req;
					else
						pstate <= ST_READ_HEADER;
					end if;
				else
					pstate <= ST_IDLE;
				end if;
				rd_addr <= (others=>'0');
				abort_frame_dur  <= '0';
				wait_cnt <= (others=>'0');
			
			when ST_READ_HEADER =>
				
				if rd_addr = DPRAM_LATENCY + 14 then 
					rd_addr <= (others=>'0');
					pstate  <= ST_PREPARE;
				else 
					rd_addr <= rd_addr + 1;
				end if;
                 
                if    rd_addr = DPRAM_LATENCY + 1 then  net_st_port           <= rd_q(7 downto 0);  --at most 20 here (maybe 40 for )         
                elsif rd_addr = DPRAM_LATENCY + 3 then  quick08_filt_disable  <= rd_q(1);
				elsif rd_addr = DPRAM_LATENCY + 4 then  net_num_m1            <= rd_q(7 downto 0);  unit_cal_en <= '1';--minus 1 ,0 is one 
                -- elsif rd_addr = DPRAM_LATENCY + 5 then  data_len( 7 downto 0) <= rd_q;
                -- elsif rd_addr = DPRAM_LATENCY + 6 then  data_len(11 downto 8) <= rd_q(3 downto 0);
                elsif rd_addr = DPRAM_LATENCY + 7 then  rcv_frmType           <= rd_q ;   
				elsif rd_addr = DPRAM_LATENCY + 13 then 
					if rcv_frmType = RFT_DETECT_RCV and rd_q(0)= '1' then 
                        frameCC_quick07_en <= '1'; 	
						for i in 0 to UNIT_NUM-1 loop
							quick08_filter_en(i) <= not quick08_filt_disable;
						end loop;
                    else  ----slow detectrcv ,or others
                        frameCC_quick07_en <= '0';
						quick08_filter_en  <= (others=>'0');
                    end if; 					  										 
                end if; 	
				
			when ST_PREPARE =>

                rd_addr <= (others=>'0'); 
                unit_idx   <= div_idx;
                unit_left  <= div_left;
                unit_is_broadc <= div_is_brdcast;					
				
                if net_st_port = X"FF" then --broad
                    if frameCC_quick07_en = '1' then --sequential for 0x07 frame here                       
                       -- eth_max_m1  <=  conv_std_logic_vector(UNIT_NUM*ETH_PER_UNIT-1,8 ); --at most
                       eth_max_m1  <=  conv_std_logic_vector(UNIT_NUM*(conv_integer(real_eth_num_conv))-1,8 ); --at most

                    else  ----wrong conditon 
                       eth_max_m1 <=  (others=>'0');                   
                    end if;
                else 
                    eth_max_m1 <= net_num_m1;
                end if;          

                pstate <= ST_PUT_REQ;

			when ST_PUT_REQ => 
				if frame07_ack = '1' then
					frame07_req <= '0';
					if abort_frame_dur = '0' then
						pstate      <= ST_WAIT_TX_DONE;---ST_WAIT_08DONE ;
					else
						pstate      <= ST_WAIT_TX_DONE;
					end if;
				else
					frame07_req <= '1';
					pstate      <= ST_PUT_REQ;
				end if;
				if IS_5G = '0' then				
					Up08_net_rel_idx <=("00"&unit_left) ; 
				else
					Up08_net_rel_idx <= ("00000"&unit_idx) ;
				end if;
				rd_addr          <= frame_rd_addr;
				frame07_unit_idx <= unit_idx;
				frame07_unit_left<= unit_left;
				det_rcv_timeout_cnt   <=(others=>'0');
				
			when ST_WAIT_08DONE =>
			    
				
				if abort_detect_rcv_req = '1' then
					pstate <= ST_PUT_REQ;
					abort_detect_rcv_ack <= abort_detect_rcv_req;
					abort_frame_dur  <= '1';
					frame07_all_done <= '1';
                elsif ((up08_timeout(conv_integer(unit_idx))) /= (up08_timeout_d1(conv_integer(unit_idx)))) or det_rcv_timeout_cnt(9)='1' then 
                    pstate <= ST_SCHED;
				
                else 
                    pstate <= ST_WAIT_08DONE;  --UP TIMEINOUT OR DONE 
                end if;				
				rd_addr <=  frame_rd_addr;
				
				if time_ms_en = '1' then ---timeout 512 Ms, 3ms*128 card + 8 ms   +  margin
					det_rcv_timeout_cnt <= det_rcv_timeout_cnt+ 1;
				end if;
				
				
			when ST_SCHED =>
                if unit_left = real_eth_num_conv-1 THEN 
                    unit_left <= (others=>'0');
					if unit_idx = UNIT_NUM-1 then
						unit_idx <= (others=>'0');
					else
						unit_idx  <= unit_idx + 1;
					end if;
                else 
                    unit_left <= unit_left + 1;
                end if; 
                rd_addr <=(others=>'0');
				wait_cnt<=(others=>'0');
				det_rcv_timeout_cnt   <=(others=>'0');
                eth_max_m1  <= eth_max_m1 -1;
                
                if eth_max_m1 = 0 then 
                    pstate        <= ST_TURN ; 
                    pack_len      <= rd_len ;
                    frame07_all_done       <= '1'; ------frameCC_quick07_en; --only 07 do this 
                    
                elsif  frameCC_quick07_en = '1' then  
					pack_len                <= rd_len ;
					abort_detect_rcv_ack	<= abort_detect_rcv_req;
					if abort_detect_rcv_req = '0' then
						pstate                 <= ST_PUT_REQ;
										
					else
						pstate                 <= ST_TURN;
						frame07_all_done       <= '1'; 
					end if ;
				else------ 
					pstate        <= ST_IDLE ;
										                  
                end if;	
			
				
			when  ST_TURN  =>    --for serveral cycles  for  rdempty status change
				wait_cnt <= wait_cnt +1 ;
				if wait_cnt(0)='1' then
					pstate <= ST_IDLE;
				else
					pstate <= ST_TURN;
				end if;
				
			when ST_WAIT_TX_DONE =>
				if frame_done = '1' then
					if abort_frame_dur = '1' then						
						pstate           <= ST_IDLE;
						abort_frame_dur  <= '0';
					elsif frameCC_quick07_en = '0' then ---slow detect
						pstate           <= ST_SCHED;
					else
						pstate <= ST_WAIT_08DONE;
					end if;
					
				else
					pstate <= ST_WAIT_TX_DONE;
				end if;
				rd_addr               <= frame_rd_addr;
				det_rcv_timeout_cnt   <=(others=>'0');
				
							

			when others => pstate <= ST_IDLE;
		end case;
	end if;
end process;


frame_q <= rd_q when abort_frame_dur = '0' else abort_data_d1;
frame_len <= rd_len when abort_frame_dur = '0' else abort_frm_len;
abort_frame_dur_o <= abort_frame_dur;


----abort frame
process(nRST,clk)
begin
	if nRST = '0' then
	
		abort_data <= (others=>'0');
	elsif rising_edge(clk) then
		abort_frm_len <= FR_DETRCV_ABORT_LEGNTH(10 downto 0)+7;
	
		abort_data_d1 <= abort_data;
	
		if rd_addr = 0 then
			abort_data <= X"CC";
		elsif rd_addr = 1 then
			abort_data <= "00"&unit_left;
		elsif rd_addr = 2 then
			abort_data <= (others=>'0');----reserved
		elsif rd_addr = 3 then
			abort_data <= (others=>'0');
		elsif rd_addr = 4 then
			abort_data <= (others=>'0'); --eth num
		elsif rd_addr = 5 then
			abort_data <= FR_DETRCV_ABORT_LEGNTH(7 downto 0);	
		elsif rd_addr = 6 then
			abort_data <= FR_DETRCV_ABORT_LEGNTH(15 downto 8);	
		
		elsif rd_addr = 7 then
			abort_data <= FR_DETRCV_ABORT;	
		elsif rd_addr = 10 then
			abort_data <= X"FF";---target board
		elsif rd_addr = 11 then
			abort_data <= X"FF";---target board	

		elsif rd_addr = 12 then
			abort_data <= X"01";----abort detect rcv card
		else
			abort_data <= (others=>'0');
		end if;
		
	end if;
end process;

				
process(nRST,clk)
begin
	if nRST = '0' then
		time_cnt <= (others=>'0');
		time_ms_en <= '0';
	elsif rising_edge(clk) then
		if time_cnt = 200000 then  ---200M
			time_ms_en <= '1';
			time_cnt   <= (others=>'0');
		else
			time_cnt   <= time_cnt + 1;
			time_ms_en <= '0';
		end if;
	end if;
end process;

 
 
frame07_man:rcvparam_store  
generic map(
	DET_RCV_MAN_EN   => 1

)  
    port  map
    (
        nRST       => nRST     ,
        clk        => clk      ,
        --pbus 
        p_Frame_en_i     =>  p_Frame_en_i  ,
        p_Wren_i         =>  p_Wren_i      ,
        p_Data_i         =>  p_Data_i      ,
        p_Addr_i         =>  p_Addr_i      , 
        cur_slot_num     =>  cur_slot_num  ,
        
        rd_len           =>  rd_len   ,
        rd_done          =>  frame07_all_done   ,
        rd_addr          =>  rd_addr   ,
        rd_q             =>  rd_q      ,
        rd_empty         =>  rd_empty  ,
		abort_detect_rcv =>  abort_detect_rcv,
		abort_07_flag    =>  abort_07_flag
    );
	
 cal_unit_i: param_div_unit 
      generic map( 
        UNIT_NUM     =>  UNIT_NUM    , --for fiber 2 or 4, for 5G 4 ;
        ETH_PER_UNIT =>  ETH_PER_UNIT  --EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g; 
        )
        port map 
        (
           nRST          =>  nRST         ,
           clk           =>  clk          , 
           start_cal_en  =>  unit_cal_en  ,
           net_st_port   =>  net_st_port(5 downto 0)  ,
           div_int       =>  div_idx      ,
           div_resid     =>  div_left        ,
           div_is_brdcast=>  div_is_brdcast ,
		   real_eth_num_conv  => real_eth_num_conv
        );
    

end beha;