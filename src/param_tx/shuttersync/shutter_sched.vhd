library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;



entity shuttersync_sched is 
generic 
(  
	UNIT_INDEX     : INTEGER  := 2 ; --for fiber 2 or 4, for 5G 4 ;
	ETH_PER_UNIT : INTEGER  := 2 ; --EVERY UNIT CONTAIN 1 ETH PORT FOR 5G ;  every unit contains 10 eth port for 10g;
	D_AW         : INTEGER := 9 ;
	D_DW         : INTEGER := 64;
	TAB_AW       : INTEGER := 10 ;
	TAB_DW       : INTEGER := 16 ;
	POS_AW       : INTEGER := 9 ;
	POS_DW       : INTEGER := 64  ;
	SCHED_NUM_PER_SEG : integer := 4;
	IS_5G         : std_logic := '0' ;
	IS_BACK       : std_logic := '0' 
);
port 
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;
	vsync_neg             :  in  std_logic ;
	

   --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
	
	shutter_enable_o      : out std_logic;
    -----------------------------------------------------------------
    shutter_prefecth_en   : in  std_logic;
	shutter_effective_en  : out std_logic;
	shutter_rd_addr       : in std_logic_vector(9 downto 0);
	shutter_rd_q          : out std_logic_vector(ETH_PER_UNIT*72-1 downto 0);	
	shutter_frm_length    : out std_logic_vector(ETH_PER_UNIT*SCHED_NUM_PER_SEG*8-1 downto 0);
	shutter_frm_valid     : out std_logic_vector(ETH_PER_UNIT*SCHED_NUM_PER_SEG*1-1 downto 0);
	
	shutter_rsp_dvld      : in std_logic;
	shutter_rsp_data      : in std_logic_vector(71 downto 0);
	shutter_rd_eth_index  : out std_logic_vector(3 downto 0);
	shutter_rd_frm_index  : out std_logic_vector(14 downto 0);
	shutter_rd_req        : out std_logic;
	shutter_rd_ack        : in  std_logic;
	shutter_rd_frmvld     : in  std_logic;
	shutter_rd_end        : in  std_logic	;
	
	real_eth_num_conv     : in  std_logic_vector(3 downto 0)
	
		
);


end shuttersync_sched;

architecture beha of shuttersync_sched is 


component shutter_sync_rcv is 
generic 
(  
	GRP_INDEX     : integer := 2;
	GRP_SIZE      : integer := 10;
	IS_5G         : std_logic := '0' ;
	IS_BACK       : std_logic := '0' ;
	
	D_AW        : INTEGER := 9 ;
	D_DW        : INTEGER := 64;
	TAB_AW      : INTEGER := 10 ;
	TAB_DW      : INTEGER := 16 ;
	POS_AW      : INTEGER := 9 ;
	POS_DW      : INTEGER := 64  
);
port  
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;

   --pbus 
    p_Frame_en_i          : in std_logic ;
    p_Wren_i              : in std_logic ;
    p_Data_i              : in std_logic_vector(7 downto 0);
    p_Addr_i              : in std_logic_vector(10 downto 0); 
    
    shutter_enabe_o       : out  std_logic ;
    sched_SEGNUM_o        : out  std_logic_vector(GRP_SIZE*16-1 downto 0);
	
	pos_wren              : out  std_logic;
    pos_waddr             : out  std_logic_vector(POS_AW-1 downto 0);
    pos_data              : out  std_logic_vector(POS_DW-1 downto 0);
	
	tab_wren              : out  std_logic_vector(GRP_SIZE-1 downto 0);
    tab_data              : out  std_logic_vector(TAB_DW-1 downto 0);
    tab_waddr             : out  std_logic_vector(TAB_AW-1 downto 0);
	
	d_wren                : out   std_logic;
    d_waddr               : out   std_logic_vector(D_AW-1  downto 0);
    d_data                : out   std_logic_vector(D_DW-1  downto 0) ;
	d_byte_offset         : out   std_logic_vector(31 downto 0);
	d_byte_length         : out   std_logic_vector(15 downto 0);
	d_rcv_end             : out   std_logic;
	
	real_eth_num_conv     : in    std_logic_vector(3 downto 0)
);
end component ;


component shuttersync_schedtable is
	port (
		data      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- datain
		q         : out std_logic_vector(15 downto 0);                    -- dataout
		wraddress : in  std_logic_vector(9  downto 0)  := (others => 'X'); -- wraddress
		rdaddress : in  std_logic_vector(9  downto 0)  := (others => 'X'); -- rdaddress
		wren      : in  std_logic                     := 'X';             -- wren
		clock     : in  std_logic                     := 'X'              -- clk
	);
end component ;

component shutter_data_dpram is
	port (
		data      : in  std_logic_vector(71 downto 0) := (others => '0'); --      data.datain
		q         : out std_logic_vector(71 downto 0);                    --         q.dataout
		wraddress : in  std_logic_vector(9 downto 0)  := (others => '0'); -- wraddress.wraddress
		rdaddress : in  std_logic_vector(9 downto 0)  := (others => '0'); -- rdaddress.rdaddress
		wren      : in  std_logic                     := '0';             --      wren.wren
		clock     : in  std_logic                     := '0'              --     clock.clk
	);
end component shutter_data_dpram;


signal seg_cnt  : std_logic_vector(8* ETH_PER_UNIT-1 downto 0);
signal seg_clr  : std_logic_vector(1* ETH_PER_UNIT-1 downto 0);
signal seg_inc_en  : std_logic_vector(1* ETH_PER_UNIT-1 downto 0);
signal seg_sel_cnt : std_logic_vector(8-1 downto 0);
signal seg_sel_num : std_logic_vector(8-1 downto 0);
signal pwr_up_en   : std_logic:='1';
type state is (ST_IDLE,ST_GET_SCHED_INFO,ST_PUT_REQ,ST_WAIT_DATA,ST_SCHED);
signal pstate : state := ST_IDLE;

signal frm_cnt  			  : std_logic_vector(1 downto 0):=(others=>'0');
signal sched_end 		      : std_logic;
signal frm_valid	  		  : std_logic_vector(0 downto 0);
signal loop_cnt 			  : integer range 0 to ETH_PER_UNIT-1 ;
signal loop_cnt_vec 			  : std_logic_vector(3 downto 0) ;
signal wait_cnt 			  : std_logic_vector(1 downto 0);

signal shutter_enable  		  : std_logic;
signal wr_cnt                 : std_logic_vector(7 downto 0);
signal shutter_d_wren         : std_logic_vector(ETH_PER_UNIT-1 downto 0);   
signal shutter_d_waddr        : std_logic_vector(9 downto 0);
signal sched_SEGNUM			  : std_logic_vector(16*ETH_PER_UNIT-1 downto 0); 

signal tab_wren               : std_logic_vector(ETH_PER_UNIT-1 downto 0);   
signal tab_data               : std_logic_vector(TAB_DW-1 downto 0);
signal tab_waddr              : std_logic_vector(TAB_AW-1 downto 0);
signal tab_raddr              : std_logic_vector(TAB_AW-1 downto 0);
signal tab_q                  : std_logic_vector((ETH_PER_UNIT)*TAB_DW-1 downto 0);
signal tab_sel_q              : std_logic_vector(TAB_DW-1 downto 0);
signal shutter_d_data         : std_logic_vector(71 downto 0);
signal shutter_d_wren_buf     : std_logic;
signal rd_frm_vld_lock        : std_logic_vector(0 downto 0);

	
begin 





process(nRST,clk)
begin
	if nRST = '0' then
		seg_cnt <= (others=>'0');			
	elsif rising_edge(clk) then
		for i in 0 to ETH_PER_UNIT-1 loop				
			if seg_clr(i)='1'  then
				seg_cnt((i+1)*8-1 downto i*8)<= (others=>'0');
			elsif seg_inc_en(i)='1'then
				seg_cnt((i+1)*8-1 downto i*8)<=seg_cnt((i+1)*8-1 downto i*8)+1;
			end if;
		end loop;
	end if;
end process;
seg_sel_cnt <= seg_cnt((loop_cnt+1)*8-1 downto loop_cnt*8);	

process(nRST,clk)
begin
	if nRST = '0' then
	
		pwr_up_en <= '1';
		pstate    <= ST_IDLE;
		frm_cnt   <= (others=>'0');
		seg_clr   <= (others=>'1');
		seg_inc_en <= (others=>'0');
		sched_end <= '0';
		shutter_effective_en <='0';
		frm_valid <= (others=>'0');
		shutter_rd_req <= '0';
		shutter_frm_length  <= (others=>'0');
		shutter_frm_valid   <= (others=>'0');
		rd_frm_vld_lock     <= (others=>'0');
	elsif rising_edge(clk) then
		shutter_enable_o <= shutter_enable;

		seg_clr    <= (others=>'0');
		seg_inc_en <= (others=>'0');
		

		case(pstate)is
		
			when ST_IDLE =>
				frm_cnt  <= (others=>'0');
				loop_cnt <= 0;
				wait_cnt <= (others=>'0');
				shutter_rd_req <= '0';
				rd_frm_vld_lock <= (others=>'0');
				
				if vsync_neg = '1' then
					sched_end <='0';
				end if;
									
				if shutter_enable = '0' then
					pstate <= ST_IDLE;
					seg_clr<= (others=>'1');
				elsif pwr_up_en = '1' then
					pwr_up_en <= '0';
					pstate    <= ST_GET_SCHED_INFO;
				elsif shutter_prefecth_en = '1' and sched_end = '0' then
					pstate    <= ST_GET_SCHED_INFO;
				end if;
				
			when ST_GET_SCHED_INFO =>
	
				shutter_rd_eth_index <= conv_std_logic_vector(loop_cnt,4);
				shutter_rd_frm_index <= tab_sel_q(14 downto 0);		
				frm_valid(0)         <= tab_sel_q(15);   
				if wait_cnt(1)='1' then					
					if tab_sel_q(15) = '1' then -----frm valid = '1' 
						pstate <= ST_PUT_REQ;
					else
						pstate <= ST_SCHED;
					end if;
					wait_cnt <= (others=>'0');
				else
					wait_cnt <= wait_cnt+1;
				end if;

			
			when ST_PUT_REQ =>
				if shutter_enable = '0' then
					pstate <= ST_IDLE;
				elsif shutter_rd_ack = '1' then
					pstate <= ST_WAIT_DATA;
					shutter_rd_req <= '0';
				else
					shutter_rd_req <= '1';
					pstate <= ST_PUT_REQ;
				end if;
				wr_cnt <= (others=>'0');
				shutter_d_wren_buf <= '0';
				
			when ST_WAIT_DATA =>
				
				if shutter_enable = '0' then
					rd_frm_vld_lock(0) <= '0';
					pstate             <= ST_SCHED	;				
				elsif shutter_rd_end = '1' then
					rd_frm_vld_lock(0) <= shutter_rd_frmvld;
					pstate <= ST_SCHED;
				else
					pstate <= ST_WAIT_DATA;
				end if;
				
				if shutter_rsp_dvld = '1' then
					wr_cnt <= wr_cnt + 1;
				end if;
				
				shutter_d_wren_buf <= shutter_rsp_dvld;
				
			when ST_SCHED =>
				shutter_d_wren_buf <= '0';
				if frm_cnt = SCHED_NUM_PER_SEG-1 then
					if loop_cnt = real_eth_num_conv-1 then
						loop_cnt <= 0;
						pstate   <= ST_IDLE;
						sched_end <= '1';
						shutter_effective_en <='1';
					else
						loop_cnt <= loop_cnt +1 ;
						pstate   <= ST_GET_SCHED_INFO;
						sched_end <= '0';
					end if;
					frm_cnt <= (others=>'0');
					
					if (seg_sel_cnt = seg_sel_num-1) or (seg_sel_num = 0 ) then
						seg_clr(loop_cnt)     <= '1';
						seg_inc_en(loop_cnt)  <= '0';						
					else
						seg_inc_en(loop_cnt)  <= '1';	
						seg_clr(loop_cnt)     <= '0';
					end if;

				else
					frm_cnt  <= frm_cnt+1;
					pstate   <= ST_GET_SCHED_INFO;
				end if;
				
				if frm_cnt = 0 then
					shutter_frm_length(loop_cnt*SCHED_NUM_PER_SEG*8+8*1-1  downto loop_cnt*SCHED_NUM_PER_SEG*8+8*0) <= wr_cnt;
					shutter_frm_valid (loop_cnt*SCHED_NUM_PER_SEG+1-1  downto loop_cnt*SCHED_NUM_PER_SEG+0) <=frm_valid and rd_frm_vld_lock;
				elsif frm_cnt = 1 then
					shutter_frm_length(loop_cnt*SCHED_NUM_PER_SEG*8+8*2-1  downto loop_cnt*SCHED_NUM_PER_SEG*8+8*1) <= wr_cnt;
					shutter_frm_valid (loop_cnt*SCHED_NUM_PER_SEG+2-1  downto loop_cnt*SCHED_NUM_PER_SEG+1) <=frm_valid and rd_frm_vld_lock;
				elsif frm_cnt = 2 then
					shutter_frm_length(loop_cnt*SCHED_NUM_PER_SEG*8+8*3-1  downto loop_cnt*SCHED_NUM_PER_SEG*8+8*2) <= wr_cnt;
					shutter_frm_valid (loop_cnt*SCHED_NUM_PER_SEG+3-1  downto loop_cnt*SCHED_NUM_PER_SEG+2) <=frm_valid and rd_frm_vld_lock;
				else---if frm_cnt = 4 then
					shutter_frm_length(loop_cnt*SCHED_NUM_PER_SEG*8+8*4-1  downto loop_cnt*SCHED_NUM_PER_SEG*8+8*3) <= wr_cnt;
					shutter_frm_valid (loop_cnt*SCHED_NUM_PER_SEG+4-1  downto loop_cnt*SCHED_NUM_PER_SEG+3) <=frm_valid and rd_frm_vld_lock;
				end if;
				
			when others=> pstate <= ST_IDLE;
		end case;

	end if;
end process;



process(shutter_d_wren_buf,loop_cnt)
begin
		shutter_d_wren <= (others=>'0');	
		shutter_d_wren(loop_cnt) <= shutter_d_wren_buf;	
end process;		
	
process(nRST,clk)
begin
	if nRST = '0' then

		
	elsif rising_edge(clk) then

		shutter_d_waddr(9 downto 8)	<= frm_cnt;
		shutter_d_waddr(7 downto 0)	<= wr_cnt;	
		shutter_d_data <= shutter_rsp_data;
	end if;
end process;

		


	
  
shutter_sched: shutter_sync_rcv 
generic map
(  
	GRP_INDEX   => UNIT_INDEX,
	GRP_SIZE    => ETH_PER_UNIT,
	D_AW        => D_AW   ,
	D_DW        => D_DW   ,
	TAB_AW      => TAB_AW ,
	TAB_DW      => TAB_DW ,
	POS_AW      => POS_AW ,
	POS_DW      => POS_DW ,
	IS_5G       => IS_5G,
	IS_BACK     => IS_BACK
)
port map  
(
    nRST                  => nRST,
    clk                   => clk,
                          
   --pbus                 
    p_Frame_en_i          => p_Frame_en_i ,
    p_Wren_i              => p_Wren_i     ,
    p_Data_i              => p_Data_i     ,
    p_Addr_i              => p_Addr_i     ,
                          
    shutter_enabe_o       => shutter_enable,
    sched_SEGNUM_o        => sched_SEGNUM,
	                     
	pos_wren              => open,
    pos_waddr             => open,
    pos_data              => open,
	                     
	tab_wren              => tab_wren  ,
    tab_data              => tab_data  ,
    tab_waddr             => tab_waddr ,
	                     
	d_wren                => open,
    d_waddr               => open,
    d_data                => open,
	d_byte_offset         => open,
	d_byte_length         => open,
	d_rcv_end             => open,
	
	real_eth_num_conv     => real_eth_num_conv 
);

eth_schedtab_inst : for i in 0 to ETH_PER_UNIT-1 generate
sched_tab: shuttersync_schedtable 
	port map(
		data        => tab_data,
		q           => tab_q((i+1)*TAB_DW-1 downto i*TAB_DW),
		wraddress   => tab_waddr,
		rdaddress   => tab_raddr,
		wren        => tab_wren(i),
		clock       => clk
	);
end generate eth_schedtab_inst;


loop_cnt_vec <= conv_std_logic_vector(loop_cnt,4);
tab_raddr    <= seg_sel_cnt&frm_cnt;
tab_sel_q    <= tab_q((loop_cnt+1)*TAB_DW-1 downto (loop_cnt)*TAB_DW);
seg_sel_num  <= sched_SEGNUM(loop_cnt*16+8-1 downto loop_cnt*16);

eth_scheddata_inst:for i in 0 to ETH_PER_UNIT-1 generate
data_inst: shutter_data_dpram
	port map (
		data       => shutter_d_data,
		q          => shutter_rd_q((i+1)*72-1 downto i*72),
		wraddress  => shutter_d_waddr,
		rdaddress  => shutter_rd_addr,
		wren       => shutter_d_wren(i),
		clock      => clk
	);

end generate eth_scheddata_inst;

end beha ;