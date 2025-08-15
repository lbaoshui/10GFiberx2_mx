

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity xgmii2uart is
generic
(
    ETHPORT_NUM         : integer:= 10 ; ----PER FIBER 
    port_num            : integer:= 0 ; --FIBER PORT INDEX 
	TXSUBCARD_TYPE      : std_logic_vector(7  downto 0)
);
port
(

---------------rxclk -------------			
    nRST_rxclk             : in  std_logic;
    rxclk                  : in  std_logic;
    xgmii_rx_updata        : in  std_logic_vector(63 downto 0);
    xgmii_rx_upctrl        : in  std_logic_vector(7 downto 0);

--------------convclk -----------	
	nRST_convclk		   :  in  std_logic; 
	convclk_i              :  in  std_logic; 
    up08_timeout_notify    :  out std_logic ; ---time out now ......
    Up08_startimer         :  in  std_logic ; --NOTIFY ,turn signal ,0to1 or  1to0 
    Up08_net_rel_idx       :  in  std_logic_vector(7 downto 0);
    quick08_wren_convclk   :  in  std_logic  ;
    quick08_waddr_convclk  :  in  std_logic_vector(10 downto 0);
    quick08_wdata_convclk  :  in  std_logic_vector( 7 downto 0);
    quick08_flg_conv       :  in  std_logic  ;---'1' quick detect, '0' slow detect
    quick08_filter_en_conv :  in  std_logic  ;  --up 08 filtered or not -----
    quick08_addr_len_conv  :  in  std_logic_vector(7 downto 0);    

---------------sysclk--------------	
	nRST_sys               : in  std_logic;
    sysclk                 : in  std_logic;
	cur_slot_num_sys       : in  std_logic_vector(3 downto 0);	
	Up_cmd_fifo_empty_sys  : out std_logic;
	Up_cmd_fifo_rden_sys   : in  std_logic;
	Up_cmd_fifo_q_sys      : out std_logic_vector(28 downto 0);
    Up_ReadAddr_sys        : in  std_logic_vector(11 downto 0);
    Up_ReadData_sys        : out std_logic_vector(7 downto 0) ; ---latency is 2 ,after Up_ReadAddr_o;
	real_eth_num_sys       : in  std_logic_vector(3 downto 0)
	                       
	

);
end xgmii2uart;

architecture beha of xgmii2uart IS


component xgmii_rx is
generic
(
    ETHPORT_NUM         : integer:= 10 ; ----PER FIBER 
    port_num            : integer:= 0 ; --FIBER PORT INDEX 
	TXSUBCARD_TYPE      : std_logic_vector(7  downto 0)
);
port
(

---------------rxclk -------------			
    nRST_rxclk             : in  std_logic;
    rxclk                  : in  std_logic;
    xgmii_rx_updata        : in  std_logic_vector(63 downto 0);
    xgmii_rx_upctrl        : in  std_logic_vector(7 downto 0);
	real_eth_num           : in  std_logic_vector(3 downto 0);

--------------convclk -----------	
	nRST_convclk           :  in  std_logic; 
	convclk_i              :  in  std_logic; 
	cmd_fifo_empty_conv    :  out std_logic;
	cmd_fifo_rden_conv     :  in  std_logic;
	cmd_fifo_q_conv        :  out std_logic_vector(28 downto 0);
	
	rx_data_conv           :  out std_logic_vector(7 downto 0);
	rx_data_raddr_conv     :  in  std_logic_vector(11 downto 0)

	          
);
end component;
signal 	real_eth_num         :   std_logic_vector(3 downto 0);
signal	rx_cmd_fifo_empty    :   std_logic;
signal	rx_cmd_fifo_rden     :   std_logic;
signal	rx_cmd_fifo_q        :   std_logic_vector(28 downto 0);
signal	rx_cmd               :   std_logic_vector(28 downto 0);
	
signal	rx_q           :   std_logic_vector(7 downto 0);
signal	rx_data_raddr     :   std_logic_vector(11 downto 0);

component up_data_dpram_8x4096 is
    port (
        data_a    : in  std_logic_vector(7 downto 0) := (others => 'X'); -- datain_a
        q_a       : out std_logic_vector(7 downto 0);                    -- dataout_a
        data_b    : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain_b
        q_b       : out std_logic_vector(7 downto 0);                     -- dataout_b
        address_a : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- address_a
        address_b : in  std_logic_vector(11 downto 0) := (others => 'X'); -- address_b
        wren_a    : in  std_logic                     := 'X';             -- wren_a
        wren_b    : in  std_logic                     := 'X';             -- wren_b
        clock_a   : in  std_logic                     := 'X';             -- clk
        clock_b   : in  std_logic                     := 'X'              -- clk
    );
end component up_data_dpram_8x4096;



component Up08_conv_dpram is
		port (
			data      : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
			q         : out std_logic_vector(15 downto 0);                     -- dataout
			wraddress : in  std_logic_vector(10 downto 0) := (others => 'X'); -- wraddress
			rdaddress : in  std_logic_vector(9 downto 0) := (others => 'X'); -- rdaddress
			wren      : in  std_logic                     := 'X';             -- wren
			wrclock     : in  std_logic                     := 'X'  ;            -- clkd
			rdclock     : in  std_logic                     := 'X'              -- clkd
		);
end component Up08_conv_dpram;


constant TIMEO_W : integer := 20;
signal time_ms_cnt   : std_logic_vector(TIMEO_W-1 downto 0);
signal time_ms_en    : std_logic;
signal timeout_ms_cnt : std_logic_vector(3 downto 0);
component xgmiirx_cmd_fifo is
port(
	data       : in std_logic_vector(28 downto 0);
	wrreq      : in std_logic;
	rdreq      : in std_logic;
	wrclk      : in std_logic;
	rdclk      : in std_logic;
	aclr       : in std_logic;
	q		   : out std_logic_vector(28 downto 0);
	rdempty    : out std_logic;
	wrfull     : out std_logic
);
end component;

signal fifo_aclr   : std_logic:='0';
 
 
type state is (ST_IDLE,ST_WR_HEAD,ST_WR_DATA,ST_WR_EXTRACT_FRM08);
signal pstate : state:= ST_IDLE;

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
end component ;

signal cur_slot_num_conv  : std_logic_vector(3 downto 0);
CONSTANT   DETECT_TIMEOUT_LENGTH : std_logic_vector(10 downto 0) := "000"&X"40";

signal rxcmdfifo_req      : std_logic:='0';
signal rxcmdfifo_ack      : std_logic:='0';
signal rx_cmd_fifo_busy   : std_logic:='0';
signal rx_cnt             : std_logic_vector(1 downto 0);
signal rx_point           : std_logic;
signal frm08_en           : std_logic;
signal updpram_wr_point   : std_logic;
signal upfrm_valid        : std_logic; 
signal up_bytes_cnt       : std_logic_vector(10 downto 0);
signal frm08_timeout_ack  : std_logic;
signal frm08_timeout_req  : std_logic;
signal up_cmd_wren        : std_logic;
signal up_dpram_wren        : std_logic;
signal frm08_extract_en        : std_logic;
signal rx_data_raddr_buf    : std_logic_vector(10 downto 0);
signal  cnt                 : std_logic_vector(11 downto 0);
signal  up_dpram_waddr      : std_logic_vector(11 downto 0);
signal  up_dpram_waddr_buf      : std_logic_vector(10 downto 0);
signal  frmee_length      : std_logic_vector(10 downto 0);
signal  rx_eth_num        : std_logic_vector(7 downto 0);
signal  q_detect_rdaddr        : std_logic_vector(9 downto 0);
signal  frm_head_data          : std_logic_vector(7 downto 0);
signal  source_mac             : std_logic_vector(47 downto 0);
signal  target_mac             : std_logic_vector(47 downto 0);
signal  detect_sign            : std_logic_vector(1 downto 0);
signal  Up08_startimer_d1      : std_logic;
signal  timeout_ms_cnt_d1      : std_logic;
signal  up08_timeout_notify_buf: std_logic;
signal   up_dpram_wdata        : std_logic_vector(7 downto 0);
signal   q_detect_q            : std_logic_vector(15 downto 0);
signal   up_cmd_fifo_data      : std_logic_vector(28 downto 0);

signal   real_eth_num_rxclk    : std_logic_vector(3 downto 0);
signal   real_eth_num_conv     : std_logic_vector(3 downto 0);

begin

process(nRST_convclk,convclk_i)
begin
	if nRST_convclk = '0' then
		rxcmdfifo_req    <= '0';
		rx_cmd_fifo_rden <= '0';
		rx_cnt <= (others=>'0');
		rx_cmd_fifo_busy <= '0';
	
	elsif rising_edge(convclk_i) then
		if rx_cmd_fifo_busy = '1' then
			rx_cmd_fifo_rden <= '0';
			if rx_cnt(1)='1' then
				rx_cnt <= (others=>'0');
				rx_cmd_fifo_busy <= '0';
				rxcmdfifo_req <= '1';
				rx_cmd <= rx_cmd_fifo_q;
				rx_point <= rx_cmd_fifo_q(8);
				frm08_en <= rx_cmd_fifo_q(28);
			else
				rx_cnt <= rx_cnt+1;
			end if;
		elsif rxcmdfifo_req = '1' then
			if rxcmdfifo_ack = '1' then
				rxcmdfifo_req <= '0';
				frm08_en      <= '0';
			end if;
			rx_cnt <= (others=>'0');
			rx_cmd_fifo_rden <= '0';
		elsif rx_cmd_fifo_empty = '0' then
			rxcmdfifo_req    <= '0';
			rx_cmd_fifo_rden <= '1';
			rx_cmd_fifo_busy <= '1';
			rx_cnt <= (others=>'0');
		else
			rxcmdfifo_req    <= '0';
			rx_cmd_fifo_rden <= '0';
		end if;
	end if;
end process;


up08_timeout_notify <= up08_timeout_notify_buf;

rx_data_raddr  <= rx_point&rx_data_raddr_buf;
process(nRST_convclk,convclk_i)
begin
	if nRST_convclk = '0' then
		updpram_wr_point  <= '0';
		upfrm_valid       <= '0';
		up_bytes_cnt      <= (others=>'0');
		rxcmdfifo_ack     <= '0';
		frm08_timeout_ack <= '0';
		up_cmd_wren       <= '0';
		up_dpram_wren     <= '0';
		rx_data_raddr_buf <= (others=>'0');
		cnt               <= (others =>'0');
		up08_timeout_notify_buf <= '0';
		up_dpram_waddr_buf  <= (others=>'0');
		frm08_extract_en    <= '0';
	
	elsif rising_edge(convclk_i) then
		up_dpram_waddr <= updpram_wr_point&up_dpram_waddr_buf;

	
		case (pstate) is
			when ST_IDLE =>
				if rxcmdfifo_req = '1' then
					rxcmdfifo_ack   <= '1';
					if frm08_en = '1' and quick08_filter_en_conv = '1' then
						up_bytes_cnt <= conv_std_logic_vector(64+15,11);--64
					else
						up_bytes_cnt <= rx_cmd(27 downto 17)+conv_std_logic_vector(15+8+9,11);
					end if;
					if frm08_en = '1' and quick08_filter_en_conv = '1' then
						frmee_length <= conv_std_logic_vector(64,11);
					else
						frmee_length <= rx_cmd(27 downto 17)+conv_std_logic_vector(8+9,11);
					end if;
					rx_eth_num   <= rx_cmd(16 downto 9);
					pstate       <= ST_WR_HEAD;
					upfrm_valid  <= '1';
					frm08_extract_en   <= frm08_en and quick08_filter_en_conv;
					
					
				elsif frm08_timeout_req = '1' then
					pstate <= ST_WR_HEAD;
					frm08_timeout_ack <= '1';
					frmee_length <= DETECT_TIMEOUT_LENGTH;
					up_bytes_cnt <= conv_std_logic_vector(64+15,11);
					upfrm_valid  <= '0';
					-- up08_timeout_notify_buf <= not up08_timeout_notify_buf;
					frm08_extract_en    <= '0';
					if port_num = 0 then
						rx_eth_num   <= Up08_net_rel_idx;
					else
						-- rx_eth_num   <= Up08_net_rel_idx + conv_std_logic_vector(ETHPORT_NUM,8);
						rx_eth_num   <= Up08_net_rel_idx + real_eth_num_conv;
					end if;
					
				else
					pstate            <= ST_IDLE;
					up_bytes_cnt      <= (others=>'0');
					rxcmdfifo_ack     <= '0';
					frm08_timeout_ack <= '0';
					upfrm_valid       <= '1';
				end if;
				cnt <= (others=>'0');
				rx_data_raddr_buf <= (others=>'0');
				up_cmd_wren       <= '0';
				up_dpram_wren     <= '0';
				q_detect_rdaddr   <= conv_std_logic_vector(2,10);
				up_dpram_waddr_buf <= (others=>'0');
			
			when ST_WR_HEAD =>
				
				rxcmdfifo_ack  <='0';
				frm08_timeout_ack <= '0';
				up_dpram_wdata <= frm_head_data;
					
				if cnt = 25 then 
					cnt <= (others =>'0');
					if frm08_extract_en = '0' then
						pstate <= ST_WR_DATA;
					else
						pstate <= ST_WR_EXTRACT_FRM08;
					end if;
				else
					cnt <= cnt+1;
					pstate <= ST_WR_HEAD;
				end if;
				
				if cnt >0 and cnt <25 then	
					up_dpram_wren <= '1';
					up_dpram_waddr_buf <= up_dpram_waddr_buf +1;
				else
					up_dpram_wren <= '0';
				end if;
					
				if cnt < 3 then ----for mac addr
					rx_data_raddr_buf <= rx_data_raddr_buf+1;

				end if;
				
				if up_dpram_wren = '1' then
					up_bytes_cnt      <= up_bytes_cnt -1;
				end if;
				
				if 	cnt = 2 then ----source mac addr
					if upfrm_valid = '0' then ---timeout frm08_en
						source_mac <= X"FFFFFFFFFFFF";
					elsif rx_q = X"FF" then
						source_mac <= X"FFFFFFFFFFFF";
					elsif rx_q = X"22" then
						source_mac <= X"665544332222";
					else
						source_mac <= X"665544332211";	
					end if;
				elsif cnt = 3 then  -----target mac addr 
					if upfrm_valid = '0'  then
						target_mac <= X"665544332211";
					elsif rx_q = X"FF" then
						target_mac <= X"FFFFFFFFFFFF";
					elsif rx_q = X"22" then
						target_mac <= X"665544332222";
					else
						target_mac <= X"665544332211";
					end if;
				end if;
				
				if cnt >23 then
					q_detect_rdaddr <= q_detect_rdaddr +1;
				end if;
			when ST_WR_DATA =>
				cnt <= cnt +1;

				if cnt = 0 then
					up_dpram_wdata <= source_mac(7 downto 0);
				elsif cnt = 1 then
					up_dpram_wdata <= source_mac(15 downto 8);
				elsif cnt = 2 then
					up_dpram_wdata <= source_mac(23 downto 16);
				elsif cnt = 3 then
					up_dpram_wdata <= source_mac(31 downto 24);
				elsif cnt = 4 then
					up_dpram_wdata <= source_mac(39 downto 32);
				elsif cnt = 5 then
					up_dpram_wdata <= source_mac(47 downto 40);
				elsif cnt = 6 then
					up_dpram_wdata <= target_mac(7 downto 0);
				elsif cnt = 7 then
					up_dpram_wdata <= target_mac(15 downto 8);
				elsif cnt = 8 then
					up_dpram_wdata <= target_mac(23 downto 16);
				elsif cnt = 9 then
					up_dpram_wdata <= target_mac(31 downto 24);
				elsif cnt = 10 then
					up_dpram_wdata <= target_mac(39 downto 32);
				elsif cnt = 11 then
					up_dpram_wdata <= target_mac(47 downto 40);
				elsif cnt = 12 then---frame type
					if upfrm_valid = '0' then
						up_dpram_wdata <= X"08";
					else
						up_dpram_wdata <= rx_q;
					end if;
				else
					if upfrm_valid = '0' then
						up_dpram_wdata <= (others=>'0');
					else
						up_dpram_wdata <= rx_q;
					end if;
				end if;

				
				
				if  cnt>8 then
					rx_data_raddr_buf <= rx_data_raddr_buf+1;
				end if;	

				if up_dpram_wren = '1' then
					up_bytes_cnt      <= up_bytes_cnt -1;
				end if;
				
				
				if up_bytes_cnt = 1 and up_dpram_wren = '1'  then
					pstate <= ST_IDLE;
					up_dpram_wren    <= '0';
					updpram_wr_point <= not updpram_wr_point;
					up_cmd_wren      <= '1';
					up_cmd_fifo_data(28 downto 12) <= (others=>'0');
					up_cmd_fifo_data(11) <= updpram_wr_point;
					up_cmd_fifo_data(10 downto 0) <= frmee_length+conv_std_logic_vector(15,11);
					if upfrm_valid = '0' then
						up08_timeout_notify_buf <= not up08_timeout_notify_buf;
					end if;
				
				else
					up_dpram_wren <= '1';
					up_dpram_waddr_buf <= up_dpram_waddr_buf +1;
					up_cmd_wren   <= '0';
				end if;
				
			when ST_WR_EXTRACT_FRM08 =>
			
				cnt <= cnt +1;
				rx_data_raddr_buf <= q_detect_q(10 downto 0) + X"5";	
				q_detect_rdaddr   <= q_detect_rdaddr +1;
				-- if cnt >3 then
				if up_dpram_wren = '1' then
					up_bytes_cnt      <= up_bytes_cnt -1;
				end if;
				up_dpram_wdata        <= rx_q;
				
				if up_bytes_cnt = 1 and up_dpram_wren ='1' then
					pstate <= ST_IDLE;
					up_dpram_wren    <= '0';
					updpram_wr_point <= not updpram_wr_point;
					up_cmd_wren      <= '1';
					up_cmd_fifo_data(28 downto 12) <= (others=>'0');
					up_cmd_fifo_data(11)           <= updpram_wr_point;
					up_cmd_fifo_data(10 downto 0)  <= frmee_length+conv_std_logic_vector(15,11);
				
				else
					if cnt >2 then
						up_dpram_wren <= '1';
						up_dpram_waddr_buf <= up_dpram_waddr_buf +1;
					end if;					
					up_cmd_wren   <= '0';
				end if;				
				
			when others => pstate <= ST_IDLE;
		end case;
	end if;
end process;
			
					
					
process(nRST_convclk,convclk_i)
begin
	if nRST_convclk = '0' then
		frm_head_data <= (others=>'0');
	elsif rising_edge(convclk_i) then
		case(conv_integer(cnt)) is
			when 0  => frm_head_data <= X"1"&cur_slot_num_conv;
			when 1  => frm_head_data <= (others=>'0');
			when 5  => frm_head_data <= TXSUBCARD_TYPE;
			when 13 => frm_head_data <= frmee_length(7 downto 0);
			when 14 => frm_head_data <= "00000"&frmee_length(10 downto 8);
			when 15 => frm_head_data <= X"EE";
			when 18 => frm_head_data <= frmee_length(7 downto 0);
			when 19 => frm_head_data <= "00000"&frmee_length(10 downto 8);
			when 20 => frm_head_data <= rx_eth_num;
			
			when 22 => 
					    frm_head_data <= (others=>'0');
			            frm_head_data(2 downto 1) <= detect_sign;
						frm_head_data(0) <= upfrm_valid;
			when 23 =>
					frm_head_data <= quick08_addr_len_conv;
		    when others => frm_head_data <= (others=>'0');
		end case;
	end if;
end process;


process(nRST_convclk,convclk_i)
begin
	if nRST_convclk = '0' then
	
		detect_sign <= "00";
		timeout_ms_cnt<=(others=>'1');
		time_ms_en <= '0';
		time_ms_cnt<=(others=>'0');
		frm08_timeout_req <= '0';
		timeout_ms_cnt_d1 <='0';
	elsif rising_edge(convclk_i) then
			
		Up08_startimer_d1 <= Up08_startimer ;
		if quick08_flg_conv = '0' then  --slow detect
			detect_sign <= "00";
		elsif quick08_filter_en_conv = '0' then
			detect_sign <= "10";
		else
			detect_sign <= "01";
		end if;	

		
		if time_ms_cnt = 230000 then
			time_ms_en <= '1';
			time_ms_cnt<= (others=>'0');
		else
			time_ms_en <= '0';
			time_ms_cnt<= time_ms_cnt +1;
		end if;
		
		if ((Up08_startimer/= Up08_startimer_d1) or frm08_en = '1')  and quick08_flg_conv = '1' then
			timeout_ms_cnt <= conv_std_logic_vector(0,4);
		elsif timeout_ms_cnt(3)='0' then
			if time_ms_en = '1' then
				timeout_ms_cnt <= timeout_ms_cnt +1;
			end if;
		end if;
		
		timeout_ms_cnt_d1 <= timeout_ms_cnt(3);		
		
		if frm08_timeout_ack = '1' then
			frm08_timeout_req <= '0';
		elsif timeout_ms_cnt_d1='0' and timeout_ms_cnt(3)='1' then
			frm08_timeout_req <= '1';
		end if;
	end if;
end process;	

		
		


updata_dpram_inst: up_data_dpram_8x4096 
    port map (
        data_a      => up_dpram_wdata ,
        q_a         => open,
        data_b      => (others=>'0'),
        q_b         => Up_ReadData_sys,
        address_a   => up_dpram_waddr,
        address_b   => Up_ReadAddr_sys,
        wren_a      => up_dpram_wren,
        wren_b      => '0',
        clock_a     => convclk_i,
        clock_b     => sysclk
    );

up_cmd_fifo_inst: xgmiirx_cmd_fifo 
port map(
	data        => up_cmd_fifo_data, 
	wrreq       => up_cmd_wren,
	rdreq       => Up_cmd_fifo_rden_sys,
	wrclk       => convclk_i,
	rdclk       => sysclk,
	aclr        => fifo_aclr,
	q		    => up_cmd_fifo_q_sys,
	rdempty     => Up_cmd_fifo_empty_sys,
	wrfull      => open
);
fifo_aclr <= not nRST_convclk;

xgmii_rx_inst :  xgmii_rx 
generic map
(
    ETHPORT_NUM         => ETHPORT_NUM,
    port_num            => port_num,
	TXSUBCARD_TYPE      => TXSUBCARD_TYPE
)
port map
(

---------------rxclk ------ 
    nRST_rxclk             => nRST_rxclk        ,
    rxclk                  => rxclk             ,
    xgmii_rx_updata        => xgmii_rx_updata   ,
    xgmii_rx_upctrl        => xgmii_rx_upctrl   ,
	real_eth_num           => real_eth_num_rxclk      ,
                           
--------------convclk ---- 
	nRST_convclk           => nRST_convclk        ,
	convclk_i              => convclk_i           ,
	cmd_fifo_empty_conv    => rx_cmd_fifo_empty ,
	cmd_fifo_rden_conv     => rx_cmd_fifo_rden  ,
	cmd_fifo_q_conv        => rx_cmd_fifo_q     ,
	                       
	rx_data_conv           => rx_q,     
	rx_data_raddr_conv     => rx_data_raddr
	          
);

slotnum_crs: cross_domain   
	generic map(
	   DATA_WIDTH => 4  
	) 
	port map
	(   clk0       => sysclk ,----txclk      ,
		nRst0      => nRST_sys   , 	
		datain     => cur_slot_num_sys ,
		datain_req => '1' ,
		
		clk1      =>  convclk_i       ,
		nRst1     =>  nRST_convclk  , 
		data_out  =>  cur_slot_num_conv ,
		dataout_valid => open  ---just pulse only
	);	
	
	ethnum_crs: cross_domain   
	generic map(
	   DATA_WIDTH => 4  
	) 
	port map
	(   clk0       => sysclk ,----txclk      ,
		nRst0      => nRST_sys   , 	
		datain     => real_eth_num_sys ,
		datain_req => '1' ,
		
		clk1      =>  rxclk       ,
		nRst1     =>  nRST_rxclk  , 
		data_out  =>  real_eth_num_rxclk ,
		dataout_valid => open  ---just pulse only
	);	
	
	ethnum_crs2: cross_domain   
	generic map(
	   DATA_WIDTH => 4  
	) 
	port map
	(   clk0       => sysclk ,----txclk      ,
		nRst0      => nRST_sys   , 	
		datain     => real_eth_num_sys ,
		datain_req => '1' ,
		
		clk1      =>  convclk_i       ,
		nRst1     =>  nRST_convclk  , 
		data_out  =>  real_eth_num_conv ,
		dataout_valid => open  ---just pulse only
	);	
   q_det_dpram_inst:Up08_conv_dpram
     port map 
     (
            data      => quick08_wdata_convclk       ,      --      data.datain
			q         => q_detect_q            ,         --         q.dataout
			wraddress => quick08_waddr_convclk       , -- wraddress.wraddress
			rdaddress => q_detect_rdaddr       , -- rdaddress.rdaddress
			wren      => quick08_wren_convclk        ,      --      wren.wren
			wrclock   => convclk_i    ,         --     clock.clk
			rdclock   => convclk_i             --     clock.clk
      );

end beha;