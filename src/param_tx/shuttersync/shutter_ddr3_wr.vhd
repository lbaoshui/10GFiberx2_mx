library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;
use work.PCK_param_sched.all;

entity shutter_ddr3_wr is 
generic 
(  
	WRC_W       :  integer := 43;
	DDRD_W      :  integer := 320;
	DDR_AW      :  integer := 23
	
);
port  
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;
	
	pframe_en             :  in  std_logic;
	pwren                 :  in  std_logic;
	paddr                 :  in  std_logic_vector(10 downto 0);
	pdata                 :  in  std_logic_vector(7 downto 0);
	
    wr_req                :  out  std_logic;
    wr_ack                :  in   std_logic;
                          
    wr_cmd                :  out  std_logic_vector(WRC_W-1 downto 0);
    wr_abort              :  out  std_logic;
    wr_lastw              :  out  std_logic;
    wr_data               :  out  std_logic_vector(DDRD_W-1 downto 0);
    wr_wren               :  out  std_logic;
    wr_mask               :  out  std_logic_vector((DDRD_W/8)-1 downto 0) ;
	
	real_eth_num_conv       :  in  std_logic_vector(3 downto 0)
	
				
);
end shutter_ddr3_wr ;

architecture beha of shutter_ddr3_wr is 

component shutter_wrbuff_dpram is
	port (
		data      : in  std_logic_vector(63 downto 0) := (others => '0'); --      data.datain
		q         : out std_logic_vector(63 downto 0);                    --         q.dataout
		wraddress : in  std_logic_vector(8 downto 0)  := (others => '0'); -- wraddress.wraddress
		rdaddress : in  std_logic_vector(8 downto 0)  := (others => '0'); -- rdaddress.rdaddress
		wren      : in  std_logic                     := '0';             --      wren.wren
		clock     : in  std_logic                     := '0'              --     clock.clk
	);
end component ;	


component shutter_sync_rcv is 
generic 
(  
	GRP_INDEX     : integer := 2;
	GRP_SIZE      : integer := 10;
	
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
	
	tab_wren              : out  std_logic_vector(GRP_SIZE/2-1 downto 0);
    tab_data              : out  std_logic_vector(TAB_DW-1 downto 0);
    tab_waddr             : out  std_logic_vector(TAB_AW-1 downto 0);
	
	d_wren                : out   std_logic;
    d_waddr               : out   std_logic_vector( D_AW-1  downto 0);
    d_data                : out   std_logic_vector( D_DW-1  downto 0) ;
	d_byte_offset         : out   std_logic_vector(31 downto 0);
	d_byte_length         : out   std_logic_vector(15 downto 0);
	d_rcv_end             : out   std_logic;
	real_eth_num_conv     :  in  std_logic_vector(3 downto 0)
	
);
end component ;

signal	d_rcv_end             :    std_logic;



signal rdaddr                    : std_logic_vector(8 downto 0):=(others=>'0');
signal data_byte_length          : std_logic_vector(15 downto 0):=(others=>'0');

type state is (ST_IDLE,ST_PUT_REQ,ST_PUSH_DATA);
signal pstate : state := ST_IDLE;

signal ddr3_cur_addr : std_logic_vector(DDR_AW-1 downto 0);
signal wr_baseaddr   : std_logic_vector(DDR_AW-1 downto 0);
signal burst_num_cnt : std_logic_vector(7 downto 0);
signal burst_length  : std_logic_vector(6 downto 0);
signal cmd_en        : std_logic:='1';
signal rd_en         : std_logic:='0';
signal shutter_q     : std_logic_vector(63 downto 0);
signal sub_payload_length : std_logic_vector(15 downto 0);
signal data_byte_offset   : std_logic_vector(31 downto 0);
signal wr_addr            : std_logic_vector(8 downto 0);
signal data_buf           : std_logic_vector(64-1  downto 0) ;
signal data_wren          : std_logic;

  
begin 


		
data_byte_length <= sub_payload_length ;	
		

wr_mask     <= (others=>'1');
wr_baseaddr <= (others=>'0');
wr_abort    <= '0';
wr_lastw    <= '0';---nonsense 

process(nRST,clk)
begin
	if nRST = '0' then
		pstate        <= ST_IDLE;
		rdaddr        <= (others=>'0');	
		ddr3_cur_addr <= (others=>'0');	
		rd_en         <= '0';
		wr_req        <= '0';
	elsif rising_edge(clk) then
		
		case(pstate)is
		
			when ST_IDLE =>
				if d_rcv_end = '1' then
					pstate <= ST_PUT_REQ ;
				else
					pstate <= ST_IDLE;
				end if;
				
				rdaddr        <= (others=>'0');	
				ddr3_cur_addr <= data_byte_offset(25 downto 3); 
				if data_byte_length(2 downto 0)=0 then
					burst_num_cnt <= data_byte_length(10 downto 3);
				else
					burst_num_cnt <= data_byte_length(10 downto 3)+1;
				end if;
				wr_cmd                  <= (others=> '0');
				cmd_en <= '1';
				wr_req <= '0';
				
			when ST_PUT_REQ =>
				cmd_en <= '0';
				
				if cmd_en = '1' then
					if burst_num_cnt >= 64 then					
						wr_cmd(34 downto 28)    <= conv_std_logic_vector(64,7);
						burst_num_cnt           <= burst_num_cnt -64;
						ddr3_cur_addr           <= ddr3_cur_addr + 64;
						burst_length            <= conv_std_logic_vector(64,7);
					else
						wr_cmd(34 downto 28)    <= burst_num_cnt(6 downto 0);
						burst_num_cnt           <= (others=>'0');
						burst_length            <= burst_num_cnt(6 downto 0);
					end if;
					wr_cmd(DDR_AW-1 downto 0)   <= wr_baseaddr+ddr3_cur_addr;
					
				end if;
				
				if wr_ack = '1' then
					pstate <= ST_PUSH_DATA;
					wr_req <= '0';
				else
					wr_req <= '1';
					pstate <= ST_PUT_REQ;
				end if;
				
			when ST_PUSH_DATA =>
				cmd_en <= '1';
				if burst_length = 0 then
					if burst_num_cnt = 0 then
						pstate <= ST_IDLE;
					else
						pstate <= ST_PUT_REQ;
					end if;
				else
					burst_length <= burst_length -1;
				end if;
				
				if burst_length >0 then
					rdaddr <= rdaddr+1;
					rd_en  <= '1';
				else
					rd_en  <= '0';
				end if;
				
			when others => pstate <= ST_IDLE;
		end case;

		wr_wren <= rd_en;		
		
	end if;
end process;

wr_data(DDRD_W-1 downto 64) <= (others=>'0');
wr_data(63 downto 0) <= shutter_q;



shutter_wrbuff: shutter_wrbuff_dpram 
	port map (
		data        => data_buf,
		q           => shutter_q,
		wraddress   => wr_addr,
		rdaddress   => rdaddr,
		wren        => data_wren,
		clock       => clk
	);
	
shutterdata_rcv: shutter_sync_rcv  
generic map
(  
	GRP_INDEX    => 0,
	GRP_SIZE     => 2

	
)
port map 
(
    nRST                  =>	nRST,
    clk                   =>	clk,
                         
   --pbus                
    p_Frame_en_i          =>	pframe_en,
    p_Wren_i              =>	pwren,
    p_Data_i              =>	pdata,
    p_Addr_i              =>	paddr,
                         
    shutter_enabe_o       =>	open,
    sched_SEGNUM_o        =>	open,
	                      
	pos_wren              =>	open,
    pos_waddr             =>    open,
    pos_data              =>    open,
	                     
	tab_wren              =>	open,
    tab_data              =>    open,
    tab_waddr             =>    open,
	                      
	d_wren                =>	data_wren,
    d_waddr               =>	wr_addr,
    d_data                =>	data_buf,
	d_byte_offset         =>	data_byte_offset,
	d_byte_length         =>	sub_payload_length,
	d_rcv_end             =>    d_rcv_end,
	
	real_eth_num_conv     =>    real_eth_num_conv
	
);                       


				
end beha ;