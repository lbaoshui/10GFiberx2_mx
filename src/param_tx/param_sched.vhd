library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;
--  if ETH_PER_UNIT = 1 then --5G port 
--  elsif ETH_PER_UNIT = 2 THEN  --10G -->2*5G
--  elsif ETH_PER_UNIT = 4 then ---10g -->4*2.5G
--  elsif ETH_PER_UNIT = 10 then --10G fiber 10*1G
--  else 
--  end if;
---to filter the downlink parameter 
-- and sched CC to tx 

--only sched the 0x7 frame 
--
entity param_sched is 
generic ( 
UNIT_NUM : INTEGER := 4 ; --for fiber 2 or 4, for 5G 4 ;
ETH_PER_UNIT: INTEGER:=1 ;--EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
IS_5G      : std_logic := '1'

);
port 
(  nRST : in  std_logic ;
   clk  : in  std_logic ;
   
   vsync_i                : in std_logic ; -----
   rt_tx_done             : in std_logic_vector(UNIT_NUM-1 DOWNTO 0) ; --one pulse only to notify ,use to sched shutter sync here 
    --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    cur_slot_num          : in std_logic_vector(15 downto 0);    
    ----
    quick08_wren         :  out std_logic  ;
    quick08_waddr        :  out std_logic_vector(10 downto 0);
    quick08_wdata        :  out std_logic_vector( 7 downto 0);
    quick08_flg          :  out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;
    quick08_filter_en    :  out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;--up 08 filtered or not -----
    quick08_addr_len     :  out std_logic_vector(7 downto 0);    
    --dispatch to downparam_tx 
    p_Frame_en_o         : out std_logic_vector(UNIT_NUM-1 DOWNTO 0) ;
    p_Wren_o             : out std_logic_vector(UNIT_NUM-1 downto 0) ;
    p_Data_o             : out std_logic_vector(7 downto 0);
    p_Addr_o             : out std_logic_vector(10 downto 0);   
   ---------------------------------------------------------------------    
    unit_connected       : in  std_logic_vector(UNIT_NUM-1 DOWNTO 0); --the unit is connected ;
    eth_connected        : in  std_logic_vector(UNIT_NUM*ETH_PER_UNIT-1 downto 0);    ------
    -------------------------------------------------------------
    tx07_cc_req     :  out std_logic_vector(UNIT_NUM-1 downto 0); --tx one 0x7 packet ;if the unit has many eth port ,then notify 
    tx07_cc_idx     :  out std_logic_vector(3 downto 0);  ----internal index in one unit  at most 10 eth port ,which port to 
    tx07_cc_ack     :  in  std_logic_vector(UNIT_NUM-1 downto 0);
    tx07_cc_txdone  :  in  std_logic_vector(UNIT_NUM-1 downto 0); --when data is tx out to FIBER or 5G port 
    tx07_cc_end     :  out std_logic_vector(UNIT_NUM-1 downto 0) ; ----open
    up08_start_timer:  out std_logic_vector(UNIT_NUM-1 DOWNTO 0);  --NOTIFY ,turn signal ,0to1 or  1to0    
    Up08_net_rel_idx:  out std_logic_vector(7 downto 0);     
    up08_timeout    :  in  std_logic_vector(UNIT_NUM-1 downto 0);  --every unit up one 

	real_eth_num_conv             : in  std_logic_vector(3 downto 0)
  );   
    

end param_sched;


architecture beha of param_sched is 


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

SIGNAL frameCC_en         : STD_logic := '0'; 
signal frameCC_quick07_en      : std_logic := '0';  
signal filter08_en        : std_logic := '1'; ---default is filtered 
signal net_st_port        : std_logic_vector(7  downto 0);
signal net_num_m1         : std_logic_vector(7  downto 0);
signal data_len           : std_logic_vector(11 downto 0); -- in bytes 
signal rcv_frmType        : std_logic_vector(7  downto 0); -- in bytes 
signal quick_addr_num     : std_logic_vector(7  downto 0); -- in bytes 
-- signal frmCC_arriv_notify : std_logic ;
signal frameCC_ack        : std_logic ;
signal frameCC_req        : std_logic := '0';
signal div_is_brdcast    : std_logic := '0';
signal div_left          : std_logic_vector(5 downto 0):=(others=>'0'); 
signal div_idx           : std_logic_vector(2 downto 0):=(others=>'0'); --at most 8 
signal unit_is_broadc     : std_logic := '0';
signal unit_left          : std_logic_vector(5 downto 0):=(others=>'0'); 
signal unit_idx           : std_logic_vector(2 downto 0):=(others=>'0'); --at most 8 
signal eth_max_m1         : std_logic_vector(7 downto 0); --at most 

constant DPRAM_LATENCY : INTEGER := 2;
component rcvparam_store is 
generic(
	DET_RCV_MAN_EN  : integer 

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
       ---shut_sched_raddr      : in  std_logic_vector(10 downto 0);
    ---shut_sched_q          : out std_logic_vector(15 downto 0);
    ---shut_map_raddr        : in  std_logic_vector(10 downto 0);
    ---shut_map_q            : out std_logic_vector(15 downto 0);
    rd_done               : in   std_logic ; --need one cycle for the status to switch 
    rd_addr               : in   std_logic_vector(10 downto 0);
    rd_q                  : out  std_logic_vector(7  downto 0);
    rd_len                : out  std_logic_vector(10 downto 0);
    rd_empty              : out  std_logic ;
	abort_detect_rcv      : out  std_logic;
	abort_07_flag         : out  std_logic
);
end component ;
signal 	abort_detect_rcv      :   std_logic;



component param_filter07 is 
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
    quick08_wren          :  out std_logic  ;
    quick08_waddr         :  out std_logic_vector(10 downto 0);
    quick08_wdata         :  out std_logic_vector( 7 downto 0);
    -- quick08_filter_en     :  out std_logic_vector(UNIT_NUM-1 downto 0)  ;  --up 08 filtered or not -----
    -- quick08_flag          :  out std_logic_vector(UNIT_NUM-1 downto 0)  ;  
    quick08_addr_len      :  out std_logic_vector(7 downto 0)  
  ); 
 end component ; 

signal   rd_done               :    std_logic ; --need one cycle for the status to switch 
signal   rd_len                :    std_logic_vector(10 downto 0);
signal   rd_addr               :    std_logic_vector(10 downto 0);
signal   rd_cnt                :    std_logic_vector(10 downto 0);
signal   rd_q                  :    std_logic_vector(7 downto 0);
signal   rd_empty              :    std_logic ; 
 
signal    sel_rden             :  std_logic ;
signal    sel_rdaddr           :  std_logic_vector(10 downto 0);
signal    frame07_rden             :  std_logic ;
signal    frame07_rdaddr           :  std_logic_vector(10 downto 0);

signal    pack_len             :  std_logic_vector(10 downto 0);
signal    dly_txe              :  std_logic_vector(2 downto 0);

signal    d0_rdaddr            :  std_logic_vector(10 downto 0);
signal    d1_rdaddr            :  std_logic_vector(10 downto 0);
signal    d2_rdaddr            :  std_logic_vector(10 downto 0);
constant   FLOW_W              : integer:= 11;        
signal    tx_en             :  std_logic := '0' ;
signal    unit_cal_en       :  std_logic := '0';

signal    flow_cnt          :  std_logic_vector(FLOW_W downto 0);
signal    tx_frm_type       :  std_logic_vector(7 downto 0);
signal    frame8A_en        :  std_logic := '0';
signal    frame44_en        :  std_logic := '0';
signal    frame4B_en        :  std_logic := '0';
signal    frame_others      :  std_logic := '0'; 
type ST_DEF_S IS (ST_IDLE, ST_PREPARE , ST_WAIT_CRC ,
ST_WAIT_TXBEGIN, ST_PUT_REQ, ST_READ_HEADER,ST_WAIT_08DONE, ST_SCHED, ST_TURN,    ST_TX_DATA, ST_WAIT_DONE, ST_WAIT_TXDONE);
signal pstate : ST_DEF_S:= ST_IDLE; 

signal tx07_cc_ack_lock     : std_logic_vector(UNIT_NUM-1 downto 0);
signal tx07_cc_txdone_lock  : std_logic_vector(UNIT_NUM-1 downto 0);
signal clr_ack_lock         : std_logic;
signal clr_txdone_lock      : std_logic;
signal quick08_filt_disable : std_logic ;

CONSTANT ALL_1  : std_logic_vector(UNIT_NUM-1 downto 0):=(others=>'1');

component cross_domain is 
	generic (
	   DATA_WIDTH: integer:=8 
	);
	port 
	(   clk0      : in std_logic;
		nRst0     : in std_logic;		
		datain    : in std_logic_vector(DATA_WIDTH-1 downto 0);
		datain_req: in std_logic;
		
		clk1: in std_logic;
		nRst1: in std_logic;
		data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
		dataout_valid:out std_logic  ---just pulse only
	);
end component;


signal start_timer_notify : std_logic_vector(UNIT_NUM-1 DOWNTO 0):=(others=>'0'); 


component det_rcv_sched is 
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
end component ;


signal    up08_start_idx_buf        :   std_logic_vector(3 DOWNTO 0);    
signal    Up08_net_rel_idx_buf      :   std_logic_vector(7 downto 0);  	
signal    frame07_req               :   std_logic ;
signal    frame07_ack               :   std_logic ;
signal    frame07_unit_idx          :   std_logic_vector(2 downto 0);
signal    frame07_unit_left         :   std_logic_vector(5 downto 0);
signal    frame07_len               :   std_logic_vector(10 downto 0);
signal    frame07_q                 :   std_logic_vector(7  downto 0);
signal    abort_frame_dur           :   std_logic ;

begin 


  
  rcv_filt:rcvparam_store   
  generic map(
	DET_RCV_MAN_EN  => 0

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
        rd_done          =>  rd_done   ,
        rd_addr          =>  rd_addr   ,
        rd_q             =>  rd_q      ,
        rd_empty         =>  rd_empty  ,
		abort_detect_rcv =>  open,
		abort_07_flag        => open
    );
    
 
 
 quick_gen: param_filter07  
generic map( 
	UNIT_NUM     => UNIT_NUM        --for fiber 2 or 4, for 5G 4 ;


)
 port map( 
   nRST                   =>  nRST     ,
   clk                    =>  clk      ,
    
    --pbus 
    p_Frame_en_i          => frame07_rden ,
    p_Wren_i              => frame07_rden ,
    p_Data_i              => frame07_q     ,
    p_Addr_i              => frame07_rdaddr ,
	unit_idx              => unit_idx,
    ---- 
    quick08_wren         =>  quick08_wren       ,
    quick08_waddr        =>  quick08_waddr      ,
    quick08_wdata        =>  quick08_wdata      , 

    quick08_addr_len     =>  quick08_addr_len   
  ); 
     

process(nRST,clk)
begin 
	if nRST = '0' then
		tx07_cc_ack_lock <= (others=>'0');
		tx07_cc_txdone_lock <= (others=>'0');
	
	elsif rising_edge(clk) then
		for i in 0 to UNIT_NUM-1 loop
			if clr_ack_lock = '1' then
				tx07_cc_ack_lock(i)<='0';
			elsif tx07_cc_ack(i) = '1' then
				tx07_cc_ack_lock(i)<='1';
			end if;
			
			if clr_txdone_lock = '1' then
				tx07_cc_txdone_lock(i)<='0';
			elsif tx07_cc_txdone(i) = '1' then
				tx07_cc_txdone_lock(i)<='1';
			end if;			
		end loop;
	end if;
end process;
	
up08_start_timer <= start_timer_notify;
		
    process(nRST,clk)
    begin 
        if nRST ='0' then 
			tx_en <= '0';
			unit_cal_en <= '0';
			rd_done     <= '0';
			quick08_filt_disable <= '0';
			start_timer_notify <= (others=>'0'); 
        elsif rising_edge(clk) then 

            tx_en            <= '0';
            unit_cal_en      <= '0';
            rd_done          <= '0';
            tx07_cc_req      <= (others=>'0');    
		    clr_txdone_lock  <= '0';		  
		    clr_ack_lock     <= '0';	

			frame07_ack      <= '0';
			       
            case(pstate) is
                when ST_IDLE =>
					rd_addr          <= (others=>'0');
                    rd_cnt           <= (others=>'0');
                    tx07_cc_req      <= (others=>'0');
                    flow_cnt         <= (others=>'0');
					
                    if rd_empty = '0' then 
                        pstate             <= ST_READ_HEADER;
                        pack_len           <= rd_len ;
						frameCC_quick07_en <= '0';
					elsif frame07_req = '1' then
						pstate             <= ST_TX_DATA ;
						frameCC_quick07_en <= '1';
						frameCC_en         <= '1';
						frame07_ack        <= '1';
						
						Up08_net_rel_idx   <= Up08_net_rel_idx_buf;
						pack_len           <= frame07_len;
						
						unit_is_broadc     <= '0';
						unit_idx           <= frame07_unit_idx;
						unit_left          <= frame07_unit_left;
						eth_max_m1         <=  conv_std_logic_vector(0,8); 
						

                    else
                        pstate <= ST_IDLE ;
						frameCC_quick07_en <= '0';
                    end if;

                 
                when ST_READ_HEADER =>  --CC & Real param 
                         
					if rd_addr = DPRAM_LATENCY + 14 then 
						rd_addr <= (others=>'0');
						pstate  <= ST_PREPARE;
					else 
						rd_addr <= rd_addr + 1;
					end if;
                 
					if rd_addr = DPRAM_LATENCY THEN 
						tx_frm_type <= rd_q;
                        frameCC_en <= '0';

                        if rd_q = FT_FORWARD_PARAM then   
							frameCC_en   <= '1';                               
                        end if;
                    end if;
                
                    if    rd_addr = DPRAM_LATENCY + 1 then  net_st_port           <= rd_q(7 downto 0);  --at most 20 here (maybe 40 for )         
					elsif rd_addr = DPRAM_LATENCY + 4 then  net_num_m1            <= rd_q(7 downto 0);  unit_cal_en <= '1';--minus 1 ,0 is one 
								  															 
                    end if; 
              
            
            when ST_PREPARE =>
                    tx_en <= '0';
                    rd_addr <= (others=>'0'); 
                    unit_idx   <= div_idx;
                    unit_left  <= div_left;
                    unit_is_broadc <= div_is_brdcast;
									
                    if net_st_port = X"FF" then --broad
                        eth_max_m1 <=  X"0"&(real_eth_num_conv-1); --parallel for others                     
                    else 
                        eth_max_m1 <= net_num_m1;
                    end if;
               

                    pstate <= ST_TX_DATA;
      
                   
            WHEN ST_TX_DATA => --push out 
                rd_addr <= rd_addr + 1;
                tx_en   <= '1';
                IF pack_len <= 1 then --TX ONE 
                   pstate    <= ST_WAIT_CRC;
                   pack_len  <= conv_std_logic_vector(10,11); --waiting CRC calculation and crc appending here 
                else 
                   pstate   <= ST_TX_DATA;
                   pack_len <= pack_len - 1;
                end if;
               
            WHEN ST_WAIT_CRC => --WAIT CRC DONE ----
				tx_en  <= '0';
				rd_addr          <= (others=>'0');
                tx07_cc_req      <= (others=>'0');
                if pack_len <= 1 then    --waiting the data to arrive at downparam_tx          
                   pstate <= ST_WAIT_TXBEGIN;
                else 
                   pack_len <= pack_len - 1;
                end if;

                 
            when ST_WAIT_TXBEGIN => --- require to CC to tx 
                tx_en            <= '0';
                rd_addr          <= (others=>'0');
                tx07_cc_req      <= (others=>'0');
                tx07_cc_idx      <= unit_left(3 downto 0) ;

				if unit_is_broadc = '0' then
					if tx07_cc_ack(conv_integer(unit_idx)) = '1' then --only wait one feedback  
						tx07_cc_req(conv_integer(unit_idx)) <= '0'; 
						pstate <= ST_WAIT_TXDONE;
						clr_ack_lock  <= '1';                      
					else 
						tx07_cc_req(conv_integer(unit_idx)) <= '1';  
						pstate <= ST_WAIT_TXBEGIN;
					end if;
				else
					if tx07_cc_ack_lock = ALL_1 then --only wait one feedback  
						pstate <= ST_WAIT_TXDONE; 
						clr_ack_lock  <= '1';
					else  
						pstate <= ST_WAIT_TXBEGIN;
					end if;		
					for i in 0 to UNIT_NUM-1 loop	
						if tx07_cc_ack_lock(i)='1'then
							tx07_cc_req(i) <='0';
						else
							tx07_cc_req(i) <='1';
						end if;
					end loop;
                end if;
				
            when ST_WAIT_TXDONE => 
                tx_en   <= '0';
                rd_addr <=(others=>'0');
                rd_done   <= '0';
                       
                if frameCC_quick07_en = '1' then  
                    if tx07_cc_txdone(conv_integer(unit_idx))  = '1' then 
                        pstate          <= ST_SCHED;   
						clr_txdone_lock <= '1';						 
                    else 
                        pstate    <= ST_WAIT_TXDONE;
                    end if;
					
					if tx07_cc_txdone(conv_integer(unit_idx))  = '1' and abort_frame_dur = '0' then 
						start_timer_notify(conv_integer(unit_idx)) <= not start_timer_notify(conv_integer(unit_idx));
					end if;
					
                else 
					if unit_is_broadc ='0' then
						if tx07_cc_txdone(conv_integer(unit_idx))  = '1' then --get response here 
							pstate <= ST_SCHED ;
							clr_txdone_lock <= '1';
						else 
							pstate <= ST_WAIT_TXDONE;
						end if;
					else
						if tx07_cc_txdone_lock = ALL_1 then
							pstate <= ST_SCHED ;
							clr_txdone_lock <= '1';
						else
							pstate <= ST_WAIT_TXDONE;
						end if;
					end if;
                end if;
                

                
            when ST_SCHED  =>                
               
                if unit_left = real_eth_num_conv-1 THEN 
                    unit_left <= (others=>'0');
                    unit_idx  <= unit_idx + 1;
                else 
                    unit_left <= unit_left + 1;
                end if; 
                rd_addr <=(others=>'0');
                eth_max_m1  <= eth_max_m1 -1;
                
                if eth_max_m1 = 0 then 
                    pstate        <= ST_TURN ; 
                    pack_len      <= rd_len ;
                    rd_done       <= frameCC_en; ------frameCC_quick07_en; --only 07 do this                
										
                else 
                    pstate       <= ST_TX_DATA; 
                    pack_len     <= rd_len ;                     
                end if;

                
            when ST_TURN =>  --for serveral cycles  for  rdempty status change

                flow_cnt        <= flow_cnt + 1; 
                rd_addr         <= rd_addr+ 1;
				if flow_cnt(0)='1'then
					pstate <= ST_IDLE ;   
                end if;
           
           when others=> 
                 pstate <= ST_IDLE ;           
          end case;
      end if;  
  end process;
  
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
   
  
  sel_rdaddr       <= d1_rdaddr;
  sel_rden         <= dly_txe(0);

  
  process(nRST,clk) 
  begin 
     if nRST ='0' then 
        dly_txe <= (others=>'0');
     elsif rising_edge(clk) then      
        dly_txe            <=  dly_txe(1 downto 0) &tx_en;
        d0_rdaddr          <=  rd_addr;
        d1_rdaddr          <=  d0_rdaddr;
        d2_rdaddr          <=  d1_rdaddr;
		
		frame07_rden       <= dly_txe(0);
        frame07_rdaddr     <= d1_rdaddr;
       
        p_Frame_en_o <= (others=>'0');
        p_Wren_o     <= (others=>'0');
        if frameCC_quick07_en  = '1' then ---tx_frm_type = FT_FORWARD_PARAM then 
               if frame07_rden = '1' THEN 
                   p_Frame_en_o(conv_integer(unit_idx))  <= '1';
                   p_Wren_o    (conv_integer(unit_idx))  <= '1'; 
               end if;
                 
               p_Addr_o     <= frame07_rdaddr ;
               if    frame07_rdaddr = 0 then p_Data_o <= frame07_q ;
               elsif frame07_rdaddr = 1 then p_Data_o <= "00"&unit_left ; ------internal idx of the fiber port  
               elsif frame07_rdaddr = 2 then p_Data_o <= frame07_q ;
               elsif frame07_rdaddr = 3 then p_Data_o <= (others=>'0');  --only one (one by one for 
               else                      p_Data_o <= frame07_q;
               end if;             
        

        else   --           
                  p_Addr_o     <= sel_rdaddr ;
                 if sel_rden = '1' then 
                       if unit_is_broadc = '1' then  --broadcast again
                              p_Frame_en_o <= (others=>'1');
                              p_Wren_o     <= (others=>'1');
                       else                     
                           p_Frame_en_o(conv_integer(unit_idx))  <= '1';
                           p_Wren_o    (conv_integer(unit_idx))  <= '1';
                       end if;                         
                 end if;
                 --internal idx of the fiber port                 
                 if    sel_rdaddr = 0 then   p_Data_o  <= rd_q;
                 elsif sel_rdaddr = 1 then     p_Data_o <= "00"&unit_left ;  
                 else                          p_Data_o  <= rd_q;
                 end if;
         end if;
     end if;
  end process; 
   
detect_rcv_inst: det_rcv_sched 
generic map(

	UNIT_NUM      => UNIT_NUM      ,
	ETH_PER_UNIT  => ETH_PER_UNIT  ,
	IS_5G         => IS_5G        
	
)
port map
(
    nRST                  => nRST   ,         
    clk                   => clk    ,         
    --pbus                   --pbus          
    p_Frame_en_i          => p_Frame_en_i ,   
    p_Wren_i              => p_Wren_i  ,      
    p_Data_i              => p_Data_i  ,      
    p_Addr_i              => p_Addr_i  ,      
    cur_slot_num          => cur_slot_num   , 
                                             
	                                         
    frame_done          => rd_done ,   
    frame_rd_addr       => rd_addr ,
    frame_q             => frame07_q   ,    
    frame_len           => frame07_len    , 
	abort_frame_dur_o       => abort_frame_dur ,
                         
	                      
    frame07_req           => frame07_req,
    frame07_ack           => frame07_ack,
	                     
	frame07_unit_idx      => frame07_unit_idx  ,
	frame07_unit_left     => frame07_unit_left ,
	                     
    quick08_filter_en     => quick08_filter_en, 
    quick08_flg           => quick08_flg,        
    up08_timeout          => up08_timeout,         
    Up08_net_rel_idx      => Up08_net_rel_idx_buf  ,
	real_eth_num_conv     => real_eth_num_conv

);

   


end beha ;