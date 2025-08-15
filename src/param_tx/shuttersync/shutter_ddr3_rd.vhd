library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_param_sched.all;
use work.PCK_param_sched.all;

entity shutter_ddr3_rd is 
generic 
(  
	WRC_W       :  integer := 43;
	DDRD_W      :  integer := 320;
	DDR_AW      :  integer := 23;
	CREQ_W      :  integer := 35;
	CRSP_W      :  integer := 44;
	TAGW        : integer    :=  4   ;
	GRP_NUM     :  integer := 2;
	GRP_SIZE    :  integer := 10;
	FAULT_TOLERENT_EN : integer := 0
);
port  
(
    nRST                  :  in  std_logic ;
    clk                   :  in  std_logic ;
	
	pframe_en             :  in  std_logic;
	pwren                 :  in  std_logic;
	paddr                 :  in  std_logic_vector(10 downto 0);
	pdata                 :  in  std_logic_vector(7 downto 0);
	
	
	shutter_rd_req        :  in  std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_ack        :  out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_frm_index  :  in  std_logic_vector(GRP_NUM*15-1 downto 0);
	shutter_rd_eth_index  :  in  std_logic_vector(GRP_NUM*4-1 downto 0);
	shutter_rsp_data      :  out std_logic_vector(71 downto 0);
	shutter_rsp_dvld      :  out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_end        :  out std_logic_vector(GRP_NUM-1 downto 0);
	shutter_rd_frmvld     :  out std_logic_vector(GRP_NUM-1 downto 0);
	
	
    rd_req                 : out std_logic;
    rd_ack                 : in  std_logic ;
    rd_reqcmd              : out std_logic_vector(CREQ_W-1 downto 0);
    rd_respcmd             : out std_logic_vector(CRSP_W-1 downto 0);  ---extra 5bits are needed to convey the line_end and netport index ;

    rd_rsp_dvld             : in std_logic ;
    rd_rsp_data             : in std_logic_vector(DDRD_W -1 downto 0);
    rd_rsp_retcmd           : in std_logic_vector(CRSP_W-1 downto 0);
    rd_rsp_lastw            : in std_logic;  --last word --last word in the seg
    rd_rsp_firstw           : in std_logic ; --first word --first word in the seg
    rd_rsp_prefirstw        : in std_logic ; --just before first word --first word in the seg
	
	real_eth_num_conv       :  in  std_logic_vector(3 downto 0)
				
);
end shutter_ddr3_rd ;

architecture beha of shutter_ddr3_rd is 


component shutter_buff_dpram is
	port (
		data      : in  std_logic_vector(63 downto 0) := (others => '0'); --      data.datain
		q         : out std_logic_vector(63 downto 0);                    --         q.dataout
		wraddress : in  std_logic_vector(9 downto 0)  := (others => '0'); -- wraddress.wraddress
		rdaddress : in  std_logic_vector(9 downto 0)  := (others => '0'); -- rdaddress.rdaddress
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
	POS_AW      : INTEGER := 10 ;
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
    d_waddr               : out   std_logic_vector(D_AW-1  downto 0);
    d_data                : out   std_logic_vector(D_DW-1  downto 0) ;
	d_byte_offset         : out   std_logic_vector(31 downto 0);
	d_byte_length         : out   std_logic_vector(15 downto 0);
	d_rcv_end             : out   std_logic;
	real_eth_num_conv     :  in  std_logic_vector(3 downto 0)
);
end component ;
signal     shutter_enabe       :  std_logic ;

component crc64_top is
generic
(

 B_W : integer := 4 ; --at most 8 bytes
 D_W : integer := 64;
 D_LSB_F: integer := 1; ---'1': data is lsb BYTE first, '0': data is msb first (first out)
 CRC_W: integer:= 32 ;
 INV_BYTE_BIT: integer:=1   -- 1 : bit7 bit0 swap FOR NEW,  '0': no swap for OLD (2003 VERSION)
);
port
(
   nRST       : in  std_logic;
   clr_i      : in  std_logic ;
   clk_i      : in  std_logic ;
   frm_en_i   : in  std_logic ;
   ctrl_i     : in  std_logic_vector((D_W/8)-1 DOWNTO 0);
   data_i     : in  std_logic_vector(D_W-1 downto 0);
   bnum_i     : in  std_logic_vector(B_W-1 downto 0);
   din_en_i   : in  std_logic ;
   last_en_i  : in  std_logic ;
   first_en_i : in  std_logic ;

   --delayed one-clock version of the inputs
   den_o      : out  std_logic ;
   laste_o    : out  std_logic ;
   frm_en_o   : out  std_logic ;
   ctrl_o     : out  std_logic_vector((D_W/8)-1 DOWNTO 0);

   firsten_o  : out std_logic ;
   bnum_o     : out std_logic_vector(B_W-1   downto 0);
   total_bnum : out std_logic_vector(14 downto 0);
   data_o     : out std_logic_vector(D_W-1   downto 0);
   crc_o      : out std_logic_vector(CRC_W-1 downto 0)
);
end component ;

signal rd_baseaddr     : std_logic_vector(22 downto 0):=(others=>'0');

type state is (ST_IDLE,ST_GET_INFO,ST_PUT_REQ,ST_GET_DATA,ST_TRUN);
signal pstate : state := ST_IDLE;

signal loop_cnt        : integer range 0 to GRP_NUM-1;
signal grp_sel         : integer range 0 to GRP_NUM-1;
signal grp_sel_lock    : integer range 0 to GRP_NUM-1;
signal pos_rdaddr      : std_logic_vector(10-1 downto 0);
signal eth_index       : std_logic_vector(3 downto 0);

signal wait_cnt        : std_logic_vector(1 downto 0);
signal ddr3_cur_addr   : std_logic_vector(DDR_AW-1 downto 0);
signal frm_byte_length : std_logic_vector(15 downto 0);
signal frm_byte_length_cnt : std_logic_vector(15 downto 0);
signal burst_cnt       : std_logic_vector(7 downto 0);
signal burst_len_lock       : std_logic_vector(6 downto 0);
signal push_mac_en     : std_logic;

signal cmd_en          : std_logic;
signal push_first_en   : std_logic;

signal crc_clr_i           : std_logic;
signal crc_firstw          : std_logic;
signal crc_lastw           : std_logic;
signal crc_append_en       : std_logic;
signal crc_wren_in         : std_logic;
signal crc_bnum            : std_logic_vector(3 downto 0);
signal crc_wdata           : std_logic_vector(63 downto 0);
signal push_wdata_d1           : std_logic_vector(63 downto 0);
signal push_wdata_d2           : std_logic_vector(63 downto 0);

signal rd_rsp_data_h32        : std_logic_vector(31 downto 0);
signal first_data_en          : std_logic;
signal shutter_frm_wren       : std_logic;
signal data_append_en         : std_logic;


signal crc_firsten_o          : std_logic;
signal crc_wren_out           : std_logic;
signal crc_laste_o            : std_logic;
signal crc_bn_out             : std_logic_vector(3 downto 0);
signal wr_cnt                 : std_logic_vector(8 downto 0);
signal rd_cnt                 : std_logic_vector(8 downto 0);
-- signal shutter_wr_addr                 : std_logic_vector(8 downto 0);
signal shutter_frm_data                : std_logic_vector(71 downto 0);
signal shutter_frm_q                   : std_logic_vector(71 downto 0);
signal shutter_rd_addr                 : std_logic_vector(8 downto 0);

signal last_en          : std_logic;
signal push_data_end_buf    : std_logic_vector(4 downto 0);
signal push_data_end    : std_logic;
signal push_data_en     : std_logic;
signal push_data_en_d1  : std_logic;
signal frm_length       : std_logic_vector(8 downto 0);
signal crc_o            : std_logic_vector(32-1 downto 0);
signal crc_buf            : std_logic_vector(32-1 downto 0);

signal pos_q            : std_logic_vector(63 downto 0);
signal pos_wren         : std_logic;
signal pos_waddr        : std_logic_vector(10-1 downto 0);
signal pos_data         : std_logic_vector(64-1 downto 0);

signal frm_byte_offset  : std_logic_vector(31 downto 0);
signal rd_abort         : std_logic;

  
begin 



rd_baseaddr <= (others=>'0');

-- rsp_burst_length <= rd_rsp_retcmd(TAGW+24)&rd_rsp_retcmd(5 downto 0);

process(nRST,clk)
begin
	if nRST = '0' then
		pstate   <= ST_IDLE;
		loop_cnt <= 0;
		wait_cnt <= (others=>'0');
		burst_cnt <= (others=>'0');
		ddr3_cur_addr <= (others=>'0');
		cmd_en <= '0';
		rd_reqcmd  <= (others=>'0');
		rd_respcmd <= (others=>'0');
		rd_abort   <= '0';
	
	elsif rising_edge(clk)then
		
		shutter_rd_ack <= (others=>'0');	
		rd_abort       <= '0';
		
		case(pstate)is
		
			when ST_IDLE =>
				if shutter_enabe = '0' then
					pstate <= ST_IDLE;
				elsif shutter_rd_req(loop_cnt)='1' then
					pos_rdaddr <= shutter_rd_frm_index(loop_cnt*15+10-1 downto loop_cnt*15);
					eth_index  <= shutter_rd_eth_index(loop_cnt*15+4-1 downto loop_cnt*15);
					shutter_rd_ack(loop_cnt) <= '1';
					pstate     <= ST_GET_INFO;
					
				else
					if loop_cnt = GRP_NUM-1 then
						loop_cnt <= 0;
					else
						loop_cnt <= loop_cnt+1;
					end if;
					pstate <= ST_IDLE;
				end if;
				wait_cnt   <= (others=>'0');
				rd_reqcmd  <= (others=>'0');
				rd_respcmd <= (others=>'0');
				push_first_en <= '0';
				
			when ST_GET_INFO =>
				
				if wait_cnt(1)='1' then
					ddr3_cur_addr <= frm_byte_offset(25 downto 3);
					if frm_byte_length(2 downto 0)= 0 then
						burst_cnt          <= frm_byte_length(10 downto 3);
					else
						burst_cnt          <= frm_byte_length(10 downto 3)+1;
					end if;
					wait_cnt <= (others=>'0');
					
					if frm_byte_length = 0 then ----false 
						pstate      <= ST_TRUN;
						push_mac_en <= '0';
						rd_abort    <= '1';
					else
						pstate      <= ST_PUT_REQ;					
						push_mac_en <= '1';
						rd_abort    <= '0';
					end if;
				else
					wait_cnt <= wait_cnt +1;
					pstate   <= ST_GET_INFO;
					push_mac_en <= '0';
				end if;
				cmd_en <= '1';
				push_first_en <= '1';
			
			when ST_PUT_REQ =>
				
				cmd_en <= '0';

				if cmd_en = '1' then
					rd_reqcmd(22 downto 0)       <= rd_baseaddr+ddr3_cur_addr;
					if burst_cnt >= 64 then
						rd_reqcmd(34 downto 28)  <= conv_std_logic_vector(64,7);
						burst_cnt                <= burst_cnt -64;
						ddr3_cur_addr            <= ddr3_cur_addr+64;
						rd_respcmd(TAGW+24)      <= '1';---burst_rd_num(6);
						rd_respcmd(5 DOWNTO 0 )  <= (others=>'0');
						burst_len_lock           <= conv_std_logic_vector(64,7);
					else
						rd_reqcmd(34 downto 28)  <= burst_cnt(6 downto 0);	
						burst_cnt                <= (others=>'0');
						rd_respcmd(TAGW+24)      <= '0';---burst_rd_num(6);
						rd_respcmd(5 DOWNTO 0 )  <= burst_cnt(5 downto 0);
						burst_len_lock           <= burst_cnt(6 downto 0);
					end if;
				end if;	
				rd_respcmd(9 downto 6)          <= (others=>'0');---index_cnt(3 downto 0); ----
				rd_respcmd(43)                  <= '0';---index_cnt(4);				

				if rd_ack = '1' then
					rd_req <= '0';
					pstate <= ST_GET_DATA;
					
				else
					rd_req <= '1';
					pstate <= ST_PUT_REQ;
					
				end if;
				push_mac_en <= '0';
				
				
			when ST_GET_DATA =>
				
				push_mac_en <= '0';
				if rd_rsp_dvld = '1' then
					burst_len_lock <= burst_len_lock-1;					
				end if;
				cmd_en <= '1';
				
				if burst_len_lock = 0 then
					if burst_cnt = 0 then
						pstate   <= ST_TRUN;---ST_IDLE;						
					else
						pstate   <= ST_PUT_REQ;
					end if;
				end if;
				
				if rd_rsp_dvld = '1' then
					push_first_en <= '0';
				end if;
				
			when ST_TRUN => ----for wait crc end
				
				if wait_cnt(1 downto 0)="11" then
					pstate <= ST_IDLE;
					if loop_cnt = GRP_NUM-1 then
						loop_cnt <= 0;
					else
						loop_cnt <= loop_cnt+1;
					end if;
				else
					pstate <= ST_TRUN;
				end if;
				wait_cnt <= wait_cnt+1;
				
				
			when others => pstate <= ST_IDLE;
		end case;
		
	end if;
end process;
				
				

process(nRST,clk)
begin
	if nRST = '0' then	
		crc_clr_i  <= '0';
		crc_firstw <= '0';
		crc_lastw  <= '0';
		crc_append_en <= '0';
		frm_byte_length_cnt <= (others=>'0');
		crc_bnum <= (others=>'0');
	elsif rising_edge(clk) then
		if rd_rsp_dvld = '1' then
			rd_rsp_data_h32 <= rd_rsp_data(63 downto 32);
		end if;
		
		if pstate = ST_GET_INFO then
			crc_clr_i  <= '1';
			crc_firstw <= '0';
			crc_lastw  <= '0';
			crc_wren_in <= '0';
			frm_byte_length_cnt <= frm_byte_length;
			if frm_byte_length(2 downto 0) <5 then
				crc_append_en <= '0';
			else
				crc_append_en <= '1';
			end if;
			grp_sel <= loop_cnt;
		else
			crc_clr_i <= '0';
			if push_mac_en = '1' then
				crc_firstw <= '1';
				crc_wren_in <= '1';
				crc_bnum   <= conv_std_logic_vector(8,4);
				crc_wdata  <= X"2222665544332211";
			elsif rd_rsp_dvld = '1' then
				crc_wren_in <= '1';
				crc_firstw  <= '0';
				if push_first_en = '1' then
					crc_wdata  <= rd_rsp_data(31 downto 0)&X"66554433";
					frm_byte_length_cnt <= frm_byte_length_cnt-4;
				else
					crc_wdata  <= rd_rsp_data(31 downto 0)&rd_rsp_data_h32;
					if frm_byte_length_cnt >=8 then
						frm_byte_length_cnt <= frm_byte_length_cnt-8;
					end if;
				end if;
				
				if 	frm_byte_length_cnt >= 8 then
					crc_bnum   <= conv_std_logic_vector(8,4);
				else
					crc_bnum   <= frm_byte_length_cnt(3 downto 0);
				end if;
				
				if crc_append_en = '0' then
					if frm_byte_length_cnt <= 8 then
						crc_lastw  <= '1';
					else
						crc_lastw <= '0';
					end if;
				else
					crc_lastw <= '0';
				end if;
			elsif crc_append_en = '1' and frm_byte_length_cnt <8 then
				crc_lastw   <= '1';
				crc_wren_in <= '1';
				crc_firstw  <= '0';
				crc_wdata   <= rd_rsp_data(31 downto 0)&rd_rsp_data_h32;
				crc_bnum    <= frm_byte_length_cnt(3 downto 0);
				crc_append_en  <= '0';
			else
				crc_firstw <= '0';
				crc_lastw  <= '0';
				crc_wren_in <= '0';

			end if;
		end if;
	end if;
end process;
		
		
process(nRST,clk)
begin
	if nRST = '0' then
		first_data_en    <= '1';
		shutter_frm_wren <= '0';
		data_append_en   <= '0';
	elsif rising_edge(clk) then
		push_wdata_d1 <= crc_wdata;
		push_wdata_d2 <= push_wdata_d1;

		
		if crc_firsten_o ='1' then
			first_data_en <= '1';
			shutter_frm_wren <= '0';
			wr_cnt <= (others=>'0');
			
		elsif crc_wren_out = '1' then
			first_data_en <= '0';
			shutter_frm_wren <= '1';
			if first_data_en = '1' then
				shutter_frm_data <= X"00"&push_wdata_d2(63 downto 32)&X"00"&X"0"&eth_index&X"2211";
			elsif crc_laste_o = '1' then
				case(conv_integer(crc_bn_out)) is
					when 1 => data_append_en <= '0';last_en <= '1';shutter_frm_data <= X"E0"&X"0707"&X"FD"&crc_buf&push_wdata_d2(7 downto 0);
					when 2 => data_append_en <= '0';last_en <= '1';shutter_frm_data <= X"C0"&X"07"&X"FD"&crc_buf&push_wdata_d2(15 downto 0);
					when 3 => data_append_en <= '0';last_en <= '1';shutter_frm_data <= X"80"&X"FD"&crc_buf&push_wdata_d2(23 downto 0);
					when 4 => data_append_en <= '1';last_en <= '0';shutter_frm_data <= X"00"&crc_buf&push_wdata_d2(31 downto 0);
					when 5 => data_append_en <= '1';last_en <= '0';shutter_frm_data <= X"00"&crc_buf(23 downto 0)&push_wdata_d2(39 downto 0);
					when 6 => data_append_en <= '1';last_en <= '0';shutter_frm_data <= X"00"&crc_buf(15 downto 0)&push_wdata_d2(47 downto 0);
					when 7 => data_append_en <= '1';last_en <= '0';shutter_frm_data <= X"00"&crc_buf(7 downto 0)&push_wdata_d2(55 downto 0);
					when others => data_append_en <= '1';shutter_frm_data <= X"00"&push_wdata_d2(63 downto 0);
				end case;
			else
				shutter_frm_data <= X"00"&push_wdata_d2;
			end if;
			wr_cnt <= wr_cnt+1;
		elsif data_append_en = '1' then	
			data_append_en <= '0';
			shutter_frm_wren <= '1';
			last_en <= '1';
			case(conv_integer(crc_bn_out)) is

				when 4 => shutter_frm_data <= X"FF"&X"07070707070707FD";
				when 5 => shutter_frm_data <= X"FE"&X"070707070707FD"&crc_buf(31 downto 24);
				when 6 => shutter_frm_data <= X"FC"&X"0707070707FD"&crc_buf(31 downto 16);
				when 7 => shutter_frm_data <= X"F8"&X"07070707FD"&crc_buf(31 downto 8);
				when others => shutter_frm_data <= X"F0"&X"070707FD"&crc_buf(31 downto 0);
			end case;	
			wr_cnt <= wr_cnt+1;
		else
			shutter_frm_wren <= '0';
			last_en <= '0';
			data_append_en <= '0';
		end if;
		
	end if;
end process;	
		


	
process(nRST,clk)
begin
	if nRST = '0' then
		shutter_rd_end     <= (others=>'0');
		shutter_rd_frmvld  <= (others=>'0');
		shutter_rsp_dvld   <= (others=>'0');
	elsif rising_edge(clk) then
	
		shutter_rsp_dvld   <= (others=>'0');
		shutter_rsp_dvld(grp_sel) <= shutter_frm_wren;
		shutter_rsp_data   <= shutter_frm_data;
	
		shutter_rd_end    <= (others=>'0');
		shutter_rd_frmvld <= (others=>'0');
		
		if rd_abort = '1' and FAULT_TOLERENT_EN = 1  then
			shutter_rd_end(grp_sel)    <= '1';
			shutter_rd_frmvld(grp_sel) <= '0';       
		elsif last_en='1' then
			shutter_rd_end(grp_sel)    <= '1';
			shutter_rd_frmvld(grp_sel) <= '1';    			
		end if;
	end if;
end process;
		

		
calc_crc: crc64_top
    generic map
    (
        B_W    => 4 , --at most 8 bytes
        D_W    => 64 ,
        D_LSB_F=> 1 , ---'1': data is lsb BYTE first, '0': data is msb first (first out)
        CRC_W  => 32 ,
        INV_BYTE_BIT => 1    -- 1 : bit7 bit0 swap FOR NEW,  '0': no swap for OLD (2003 VERSION)
       )
    port map
       (
        nRST       => nRST,
        clr_i      => crc_clr_i ,
        clk_i      => clk ,
        frm_en_i   => '0' ,
        ctrl_i     => (others=>'0'),
        data_i     => crc_wdata(63 downto 0),
        bnum_i     => crc_bnum ,
        din_en_i   => crc_wren_in,
        last_en_i  => crc_lastw,
        first_en_i => crc_firstw,

        --delayed one-clock version of the inputs
        den_o      => crc_wren_out,
        laste_o    => crc_laste_o,
        frm_en_o   => open ,
        ctrl_o     => open ,

        firsten_o  => crc_firsten_o ,
        bnum_o     => crc_bn_out,
        total_bnum => open ,
        data_o     => open ,
        crc_o      => crc_o
       );

	process(crc_o)
    begin
         for i in 0 to 31 loop
            crc_buf(i) <= not crc_o(31-i);
         end loop;
    end process;   

frm_byte_offset <= pos_q(31 downto 0);
frm_byte_length <= pos_q(47 downto 32);

shutter_pos_dpram: shutter_buff_dpram 
	port map (
		data      => pos_data,
		q         => pos_q,
		wraddress => pos_waddr,
		rdaddress => pos_rdaddr,
		wren      => pos_wren,
		clock     => clk
	);
	
	

shutter_pos: shutter_sync_rcv 
generic map
(  
	GRP_INDEX   => 0,
	GRP_SIZE    => 2

)
port map  
(
    nRST                  => nRST,
    clk                   => clk,
                          
   --pbus                 
    p_Frame_en_i          => pframe_en,
    p_Wren_i              => pwren,
    p_Data_i              => pdata,
    p_Addr_i              => paddr,
                          
    shutter_enabe_o       => shutter_enabe,
    sched_SEGNUM_o        => open,
	                     
	pos_wren              => pos_wren ,  
    pos_waddr             => pos_waddr , 
    pos_data              => pos_data  , 
	                     
	tab_wren              => open,
    tab_data              => open,
    tab_waddr             => open,
	                     
	d_wren                => open,
    d_waddr               => open,
    d_data                => open,
	d_byte_offset         => open,
	d_byte_length         => open,
	d_rcv_end             => open,
	
	real_eth_num_conv     => real_eth_num_conv
);
				
end beha ;