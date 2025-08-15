library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity para_serdes_top is
generic
(
	PARA_HSSI_NUM			: integer		:= 1
);
port
(
	nRST_sys				: in std_logic;
	sysclk					: in std_logic;
	
    xgm_rstn	         	: in std_logic;
    xgmclk	             	: in std_logic;
    xgm_rx_data			   	: in std_logic_vector(PARA_HSSI_NUM*64-1 downto 0);
    xgm_rx_k	         	: in std_logic_vector(PARA_HSSI_NUM*8 -1 downto 0);
	
	frame_ss				: out std_logic;                    
    rx_data_vld				: out std_logic;                    
    rx_data					: out std_logic_vector(7 downto 0);
	
	clr_serdesinfo_sys		: in std_logic;
	serdes_pck_cnt_sys		: out std_logic_vector(32-1 downto 0);
	serdes_fe_cnt_sys		: out std_logic_vector(16-1 downto 0);
	serdes_crc_err_sys		: out std_logic_vector(16-1 downto 0)

);

end entity;


architecture behav of para_serdes_top is

type state is
(
	idle,
	rcv_para_frm,
	wr_cmdfifo,
	clear
);
signal pstate				: state		:= idle;


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


component xgmii_dataalign is
port
(
    rx_clk                  : in std_logic;
    rx_parallel_data        : in std_logic_vector(63 downto 0);                     -- rx_parallel_data
    rx_control              : in std_logic_vector(7 downto 0);                      -- rx_datak

    data_c_align            : out std_logic_vector(7 downto 0);
    data_align              : out std_logic_vector(63 downto 0)

);
end component;


signal xgmii_data_c_align       : std_logic_vector(1* 8-1 downto 0);
signal xgmii_data_align         : std_logic_vector(1*64-1 downto 0);


component dpram_16bx2048 is
	port (
		data      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- datain
		q         : out std_logic_vector(7 downto 0);                     -- dataout
		wraddress : in  std_logic_vector(10 downto 0) := (others => 'X'); -- wraddress
		rdaddress : in  std_logic_vector(11 downto 0) := (others => 'X'); -- rdaddress
		wren      : in  std_logic                     := 'X';             -- wren
		wrclock   : in  std_logic                     := 'X';             -- clk
		rdclock   : in  std_logic                     := 'X'              -- clk
	);
end component;


component cmdfifo is
	port (
		data    : in  std_logic_vector(49 downto 0) := (others => 'X'); -- datain
		wrreq   : in  std_logic                     := 'X';             -- wrreq
		rdreq   : in  std_logic                     := 'X';             -- rdreq
		wrclk   : in  std_logic                     := 'X';             -- wrclk
		rdclk   : in  std_logic                     := 'X';             -- rdclk
		aclr    : in  std_logic                     := 'X';             -- aclr
		q       : out std_logic_vector(49 downto 0);                    -- dataout
		rdusedw : out std_logic_vector(3 downto 0);                     -- rdusedw
		rdempty : out std_logic;                                        -- rdempty
		wrfull  : out std_logic                                         -- wrfull
	);
end component;


component frm_reconstruct is
port(
    output_clk_nrst			: in std_logic;
    output_clk				: in std_logic;

    dpram_rdaddr			: out std_logic_vector(11  downto 0);      
    dpram_rddata			: in std_logic_vector(7   downto 0);                    

    fifo_rden				: out std_logic;
    fifo_rddata				: in std_logic_vector(49 downto 0);  
    rx_cmd_fifo_empty		: in std_logic;
	
	frame_ss               : out  std_logic;                    
    rx_data_vld            : out  std_logic;                    
    rx_data                : out  std_logic_vector(7 downto 0);
	
	clr_serdesinfo			: in std_logic;
    err_crc_num_out			: out std_logic_vector(15 downto 0)
);

end component;

signal dpram_wr_en			: std_logic							:='0';
signal dpram_wr_addr		: std_logic_vector(10 downto 0)		:=(others => '0');
signal dpram_wr_data		: std_logic_vector(15 downto 0)		:=(others => '0');
signal dpram_rdaddr			: std_logic_vector(11 downto 0)		:=(others => '0');
signal dpram_rddata			: std_logic_vector(7  downto 0)		:=(others => '0');

signal fifo_wren			: std_logic							:='0';
signal fifo_wren_buf		: std_logic							:='0';
signal fifo_wrdata			: std_logic_vector(49 downto 0)		:=(others => '0');
signal fifo_full			: std_logic							:='0';
signal fifo_rddata			: std_logic_vector(49 downto 0)		:=(others =>'0');
signal fifo_rden			: std_logic							:='0';
signal fifo_rden_buf		: std_logic							:='0';
signal fifo_empty			: std_logic							:='0';
signal fifo_rdusedw			: std_logic_vector(3 downto 0)		:=(others => '0');
signal fifo_aclr			: std_logic							:='0';

signal rx_pck_cnt_xmg		: std_logic_vector(31 downto 0)		:=(others => '0');
signal err_fe_cnt_xmg		: std_logic_vector(15 downto 0)		:=(others => '0');

signal clr_serdesinfo_xmg	: std_logic							:='0';
signal clr_serdes_xmg_buf	: std_logic_vector(3 downto 0)		:=(others => '0');

signal cnt					: std_logic_vector(11 downto 0)		:=(others => '0');
signal wait_cnt				: std_logic_vector(10 downto 0)		:=(others => '0');
signal wr_point				: std_logic_vector(1 downto 0)		:=(others => '0');
signal wr_cnt				: std_logic_vector(9 downto 0)		:=(others => '0');
signal CRC_result			: std_logic_vector(31 downto 0)		:=(others => '0');
signal frm_len				: std_logic_vector(15 downto 0)		:=(others => '0');

---------------------------------------------------------------
begin

dataalign_inst : xgmii_dataalign
port map
(
    rx_clk                  => xgmclk,
    rx_parallel_data        => xgm_rx_data,
    rx_control              => xgm_rx_k,

    data_c_align            => xgmii_data_c_align,
    data_align              => xgmii_data_align

);



-- statis pck and err
process(xgm_rstn, xgmclk)
begin
	if xgm_rstn = '0' then
		rx_pck_cnt_xmg <= (others => '0');
		err_fe_cnt_xmg <= (others => '0');
		clr_serdes_xmg_buf <= (others => '0');
		
	elsif rising_edge(xgmclk) then
		clr_serdes_xmg_buf <= clr_serdes_xmg_buf(2 downto 0) & clr_serdesinfo_sys;
		clr_serdesinfo_xmg <= clr_serdes_xmg_buf(3);
		
		if clr_serdesinfo_xmg = '1' then
			rx_pck_cnt_xmg <= (others => '0');
		elsif xgmii_data_c_align(7 downto 0) = X"01" and xgmii_data_align(7 downto 0) = X"FB" then
			rx_pck_cnt_xmg <= rx_pck_cnt_xmg + '1';
		end if;
		
		if clr_serdesinfo_xmg = '1' then
			err_fe_cnt_xmg <= (others => '0');
		elsif xgmii_data_c_align(7 downto 0) /= X"00" and xgmii_data_align(7 downto 0) = X"FE" then
			err_fe_cnt_xmg <= err_fe_cnt_xmg + '1';
		end if;
		
	end if;

end process;


process(xgm_rstn, xgmclk)
begin
	if xgm_rstn = '0' then
		pstate <= idle;
		wr_point <= (others => '0');
		wr_cnt <= (others => '0');
		dpram_wr_en <= '0';
		frm_len <= (others => '0');
		fifo_wren <= '0';
		fifo_wrdata <= (others => '0');
		wait_cnt <= (others => '0');
		
	elsif rising_edge(xgmclk) then
		
		if wait_cnt(10) = '0' then
			wait_cnt <= wait_cnt + '1';
		end if;
		
		if wait_cnt(10) = '0' then
			pstate <= clear;
			dpram_wr_en <= '0';
			dpram_wr_data <= (others => '0');
			wr_point <= (others => '0');
			wr_cnt <= (others => '0');
			frm_len <= (others => '0');
			fifo_wren <= '0';
			fifo_wrdata <= (others => '0');
		else
		
			case pstate is
			
				when idle =>
					if xgmii_data_c_align(7 downto 0) = X"01" and xgmii_data_align(7 downto 0) = X"FB" then
						pstate <= rcv_para_frm;
						frm_len <= xgmii_data_align(23 downto 8);			-- include 16 bytes of frm head
					else
						pstate <= idle;
					end if;
				
					wr_cnt <= (others => '0');
					dpram_wr_en <= '0';
					dpram_wr_data <= (others => '0');
					fifo_wren <= '0';
					fifo_wrdata <= (others => '0');
				
				when rcv_para_frm =>
				
					fifo_wren <= '0';
					if xgmii_data_c_align(7 downto 0) = X"80" and xgmii_data_align(63 downto 56) = X"FD" then
						pstate <= wr_cmdfifo;
						wr_cnt <= (others => '0');
						dpram_wr_en <= '0';
						CRC_result <= xgmii_data_align(31 downto 0);
						
					elsif xgmii_data_c_align(7 downto 0) /= X"00" then
						pstate <= idle;
					else
						pstate <= rcv_para_frm;
						wr_cnt <= wr_cnt + '1';
						dpram_wr_en <= '1';
						dpram_wr_addr(10 downto 0) <= wr_point(0) & wr_cnt(9 downto 0);
						dpram_wr_data <= xgmii_data_align(15 downto 0);

					end if;
				
				when wr_cmdfifo =>
					pstate <= idle;
					dpram_wr_en <= '0';
					dpram_wr_data <= (others => '0');
					fifo_wren <= '1';
					fifo_wrdata(49 downto 48) <= wr_point  ;
					fifo_wrdata(47 downto 32) <= frm_len   ;
					fifo_wrdata(31 downto 0 ) <= CRC_result;
					
					if wr_point >= 1 then
						wr_point <= (others => '0');
					else
						wr_point <= wr_point + '1';
					end if;
				
				when clear =>
					wr_cnt <= (others => '0');
					wr_point <= (others => '0');
					dpram_wr_en <= '0';
					dpram_wr_data <= (others => '0');
					fifo_wren <= '0';
					
                    if cnt(7) = '0' then         
                        cnt <= cnt + '1';        
                        pstate <= clear;         
                    else                         
                        cnt <= (others => '0');  
                        pstate <= idle;          
                    end if;
					
				when others =>
					pstate <= clear;
					
			end case;
			
		end if;	
	
	end if;

end process;


Reconstruct_dpram_inst : dpram_16bx2048
port map
(
	data      => dpram_wr_data,      --      data.datain
	q         => dpram_rddata,         --         q.dataout
	wraddress => dpram_wr_addr, -- wraddress.wraddress
	rdaddress => dpram_rdaddr, -- rdaddress.rdaddress
	wren      => dpram_wr_en,      --      wren.wren
	wrclock   => xgmclk,   --   wrclock.clk
	rdclock   => sysclk    --   rdclock.clk
);

fifo_aclr <= not xgm_rstn;
fifo_wren_buf <= fifo_wren when fifo_full = '0' else '0';
fifo_rden_buf <= fifo_rden when fifo_empty = '0' else '0';

Reconstruct_fifo_inst : cmdfifo
port map
(
	data    => fifo_wrdata,    --  fifo_input.datain
	wrreq   => fifo_wren_buf,   --            .wrreq
	rdreq   => fifo_rden_buf,   --            .rdreq
	wrclk   => xgmclk,   --            .wrclk
	rdclk   => sysclk,   --            .rdclk
	aclr    => fifo_aclr,    --            .aclr
	q       => fifo_rddata,       -- fifo_output.dataout
	rdusedw => fifo_rdusedw, --            .rdusedw
	rdempty => fifo_empty, --            .rdempty
	wrfull  => fifo_full   --            .wrfull
);

frm_reconstruct_inst : frm_reconstruct                
port map (  

    dpram_rdaddr        =>  dpram_rdaddr,
    dpram_rddata        =>  dpram_rddata,

    fifo_rden           =>  fifo_rden   ,
    fifo_rddata         =>  fifo_rddata ,
    rx_cmd_fifo_empty   =>  fifo_empty,
	
    output_clk_nrst     =>  nRST_sys        ,
    output_clk          =>  sysclk          ,
	frame_ss            =>  frame_ss        ,
    rx_data_vld         =>  rx_data_vld     ,
    rx_data             =>  rx_data         ,
	
	clr_serdesinfo      =>  clr_serdesinfo_sys  ,

    err_crc_num_out     =>  serdes_crc_err_sys    
);

serdes_pck_cross : cross_domain   --3                           
generic map(                                                             
    DATA_WIDTH => 32                                             
)                                                                        
port map(  

    clk0      		=> xgmclk,                         
    nRst0     		=> xgm_rstn,                       
    datain    		=> rx_pck_cnt_xmg,      
    datain_req		=> '1',                            

    clk1			=> sysclk,                         
    nRst1			=> nRST_sys,                           
    data_out		=> serdes_pck_cnt_sys,          
    dataout_valid	=> open                            
);  

serdes_fe_cross : cross_domain   --3                           
generic map(                                                             
    DATA_WIDTH => 16                                             
)                                                                        
port map(  

    clk0      		=> xgmclk,                         
    nRst0     		=> xgm_rstn,                       
    datain    		=> err_fe_cnt_xmg,      
    datain_req		=> '1',                            

    clk1			=> sysclk,                         
    nRst1			=> nRST_sys,                           
    data_out		=> serdes_fe_cnt_sys,          
    dataout_valid	=> open                            
);  

end behav;