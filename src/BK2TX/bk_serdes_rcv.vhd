library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.PCK_bk_serdes.all;

entity bk_serdes_rcv is 
generic 
(  
   SIM : std_logic := '0' ;
   P_W : integer := 11 ;
   V_W : integer := 5  ;
  F_AW : integer := 10 
);
port 
( 
  nRST_rxc              : in  std_logic ;
  rx_bk_clk             : in  std_logic ;
  rx_bk_parallel_data   : in std_logic_vector(  64-1 downto 0);
  rx_bk_control         : in std_logic_vector(  8 -1 downto 0);  
  vsync_notify_rxc      : out std_logic ; --rxc
  
  nRST_txc              : in   std_logic ;
  txclk_i               : in   std_logic ;
  vsync_txc_o           : out  std_logic ;
  vsync_neg_txc         : out  std_logic ;
  rd_done_notify_txc    : in   std_logic ;
  vid_rdreq_txc         : in   std_logic   ; -- rdaddress
  vid_rdata_txc         : out  std_logic_vector(71 downto 0);
  vid_rdempty_txc       : out  std_logic;
  vid_rdusedw_txc       : out  std_logic_vector(9 downto 0); 
  vid_pck_empty_txc     : out  std_logic     ;
  vid_pckcnt_txc        : out  std_logic_vector(P_W-1   DOWNTO 0)    ;
  --------
  vinfo_raddr           : in   std_logic_vector( V_W -1 downto 0  )  ; -- rdaddress
  vinfo_rdata           : OUT  std_logic_vector( 64-1   downto 0  );

  clr_serdesinfo_convclk        : in  std_logic;	
  subbrdin_packet_cnt_rxbkclk      : out std_logic_vector(32-1 downto 0);	
  error_fe_num_rxbkclk          : out std_logic_vector(16-1 downto 0);
  error_check_num_rxbkclk       : out std_logic_vector(16-1 downto 0)
); 
end bk_serdes_rcv;

architecture beha of bk_serdes_rcv is 
-- constant FRM_VID             : std_logic_vector(   8-1 downto 0) := X"00"; 
-- constant FRM_VSYNC           : std_logic_vector(   8-1 downto 0) := X"01"; 
-- constant FRM_AUD             : std_logic_vector(   8-1 downto 0) := X"02";  
-- constant FRM_RTPARA          : std_logic_vector(   8-1 downto 0) := X"03";  
-- constant V_W : integer  := 5 ;
constant DLY_W: integer := 17;
signal dly_cnt           : std_logic_vector(DLY_W-1 downto 0):=(others=>'0');
 
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

component trans_fifo_in is
		port (
			data    : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
			wrreq   : in  std_logic                     := 'X';             -- wrreq
			rdreq   : in  std_logic                     := 'X';             -- rdreq
			wrclk   : in  std_logic                     := 'X';             -- wrclk
			rdclk   : in  std_logic                     := 'X';             -- rdclk
			aclr    : in  std_logic                     := 'X';             -- aclr
			q       : out std_logic_vector(71 downto 0);                    -- dataout
			rdusedw : out std_logic_vector(9 downto 0);                     -- rdusedw
			wrusedw : out std_logic_vector(9 downto 0);                     -- wrusedw
			rdempty : out std_logic;                                        -- rdempty
			wrfull  : out std_logic                                         -- wrfull
		);
	end component trans_fifo_in;
    
signal is_vid_frm          : std_logic  := ( '0');  
signal is_vsync_frm        : std_logic  := ( '0');  
signal vinfo_wdata     : std_logic_vector( 64-1 downto 0*64) := (others=>'0'); -- datain
-- signal vinfo_rdata     : std_logic_vector( 32-1 downto 0*32) := (others=>'0');                  -- dataout
signal vinfo_waddr_buf : std_logic_vector( V_W -1 downto 0  ) := (others=>'0'); -- wraddress
signal vinfo_waddr     : std_logic_vector( V_W -1 downto 0  ) := (others=>'0'); -- wraddress
signal vinfo_waddr_max : std_logic_vector( V_W -1 downto 0  ) := (others=>'1'); -- wraddress
-- signal vinfo_raddr     : std_logic_vector( V_W -1 downto 0  ) := (others=>'0'); -- rdaddress
signal vinfo_wren      : std_logic  := ( '0');     

---store 0x1 frame info
component vsyncinfo_ram is
        port (
            data      : in  std_logic_vector(63 downto 0) := (others => 'X'); -- datain
            q         : out std_logic_vector(63 downto 0);                    -- dataout
            wraddress : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- wraddress
            rdaddress : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- rdaddress
            wren      : in  std_logic                     := 'X';             -- wren
            wrclock   : in  std_logic                     := 'X';             -- clk
            rdclock   : in  std_logic                     := 'X'              -- clk
        );
    end component vsyncinfo_ram;
    
signal trans_rdusedw       : std_logic_vector(F_AW-1 downto 0);
signal trans_wrusedw       : std_logic_vector(F_AW-1 downto 0);
signal trans_fifo_wrfull    : std_logic ;
signal trans_fifo_rdempty    : std_logic ;
signal trans_fifo_rdreq      : std_logic ;
signal trans_fifo_wrreq      : std_logic ;
signal trans_fifo_wrreq_buf: std_logic ;
signal trans_fifo_wdata    : std_logic_vector(  72-1 downto 0);
signal d_frm_dur    : std_logic := '0';
signal d_fifo_wdata    : std_logic_vector(  72-1 downto 0);
signal trans_fifo_q        : std_logic_vector(  72-1 downto 0);
signal trans_aclr          : std_logic  := ( '0');  
signal vsync_notify        : std_logic  := ( '0');  
signal trans_wren_txclk    : std_logic  := ( '0');  

signal dly_wren_txclk      : std_logic  := ( '0'); 
signal wren_neg_edge       : std_logic  := ( '0');  
signal frame_head_en       : std_logic  := ( '0');  

signal vid_pckcnt   : std_logic_vector(   P_W-1 downto 0 ) := (others=>'0'); -- datain
signal vsync_txclk : std_logic := '0';
--signal vsync_neg_txc : std_logic := '0';
signal dly_vsync_txc : std_logic := '0';
signal vid_pck_empty : std_logic := '0';
signal max_cnt       : std_logic_vector(8 downto 0);
signal check_sum_get : std_logic_vector(7 downto 0) :=(others=>'0');
signal check_sum_buf : std_logic_vector(63 downto 0):=(others=>'0');
signal check_sum_lock: std_logic_vector(7 downto 0) :=(others=>'0');

signal clr_serdesinfo_buf : std_logic_vector(2 downto 0):=(others=>'0');

      
component vsync_cross is
generic (DLY_CY : integer := 3);
port 
(
  vsync_async : in std_logic ; 
  nRST        : in std_logic ;
  clk         : in std_logic ; 
  vsync_synced: out std_logic 
);
end component;

signal error_packet_cnt_rxbkclk_buf : std_logic_vector(15 downto 0):=(others=>'0');
signal subbrdin_packet_cnt          : std_logic_vector(31 downto 0):=(others=>'0'); 
signal error_fe_num_cnt             : std_logic_vector(15 downto 0):=(others=>'0'); 
signal err : std_logic:='0';

begin 


 BK_dataalign_inst : xgmii_dataalign
    port map
    (
        rx_clk                  => rx_bk_clk ,
        rx_parallel_data        => rx_bk_parallel_data ,                     -- rx_parallel_data
        rx_control              => rx_bk_control       ,                     -- rx_datak
    
        data_c_align            => xgmii_data_c_align  ,
        data_align              => xgmii_data_align    
    
    );    
    
    trans_fifo_in_inst : trans_fifo_in
           port map
           (
            data    => trans_fifo_wdata      ,
            wrreq   => trans_fifo_wrreq_buf  ,
            rdreq   => trans_fifo_rdreq      ,
            wrclk   => rx_bk_clk             ,
            rdclk   => txclk_i               ,
            aclr    => trans_aclr            , --synced to read ,not sync to write 
            q       => trans_fifo_q          ,
            rdusedw => trans_rdusedw        ,-- rdusedw
            wrusedw => trans_wrusedw        ,                     -- wrusedw
            wrfull  => trans_fifo_wrfull     ,
            rdempty => trans_fifo_rdempty 
           );

   trans_fifo_wrreq_buf  <= trans_fifo_wrreq  when trans_fifo_wrfull  ='0' else '0';
   trans_fifo_rdreq      <= '0'        when (trans_fifo_rdempty = '1')     else vid_rdreq_txc ;
   trans_aclr            <= vsync_notify; --use the arriving data ...
   vsync_notify_rxc      <= vsync_notify;
   vid_rdata_txc         <= trans_fifo_q;
   vid_rdempty_txc       <= trans_fifo_rdempty;
   vid_rdusedw_txc       <= trans_rdusedw;
   
   vinfo_waddr_max <=(others=>'1');
   
 error_check_num_rxbkclk <= error_packet_cnt_rxbkclk_buf; 
 subbrdin_packet_cnt_rxbkclk <= subbrdin_packet_cnt ;
process(nRST_rxc  ,rx_bk_clk)
begin
	if nRST_rxc = '0' then
		error_packet_cnt_rxbkclk_buf   <=(others=>'0');
		error_fe_num_cnt  <= (others=>'0');
		subbrdin_packet_cnt <= (others=>'0');
	elsif rising_edge (rx_bk_clk ) then
	    clr_serdesinfo_buf <= clr_serdesinfo_buf(1 downto 0)& clr_serdesinfo_convclk;
		if clr_serdesinfo_buf(2) = '1' then
			error_packet_cnt_rxbkclk_buf <= (others=>'0');
		elsif err = '1' then
			error_packet_cnt_rxbkclk_buf <= error_packet_cnt_rxbkclk_buf +1;
		end if;	
		
		if clr_serdesinfo_buf(2) = '1' then
			subbrdin_packet_cnt <= (others=>'0');
		elsif xgmii_data_c_align = X"01" and xgmii_data_align(7 downto 0) =X"FB" then
			subbrdin_packet_cnt <= subbrdin_packet_cnt +1;
		end if;
	
	    if clr_serdesinfo_buf(2) = '1' then
			error_fe_num_cnt  <= (others=>'0');
		elsif xgmii_data_c_align /=0 and xgmii_data_align(7 downto 0) =X"FE" then
			error_fe_num_cnt  <= error_fe_num_cnt +1;
		end if;
	
	end if;
end process;


 
   process(nRST_rxc  ,rx_bk_clk)
   begin
    if nRST_rxc = '0' then
        trans_fifo_wrreq   <= '0';
        frame_head_en      <= '0'; 
        vsync_notify       <= '0';
        is_vid_frm         <= '0';        
        is_vsync_frm       <= '0';        
        vinfo_wren         <= '0'; 
        d_frm_dur          <= '0';        
        dly_cnt            <=(others=>'0');
		check_sum_buf      <=(others=>'0');
		check_sum_get      <=(others=>'0');
		check_sum_lock     <=(others=>'0');
		
    elsif rising_edge (rx_bk_clk ) then
        IF SIM = '1' THEN 
           dly_cnt <= (OTHERS=>'1');
        ELSif dly_cnt(DLY_W -1) = '0' then  --wait for stable  
            dly_cnt  <= dly_cnt   + 1;
        end if;
        
        ---if SERDES_5G_EN = '0' then
            if dly_cnt(DLY_W-1) = '0' then 
                  trans_fifo_wrreq   <= '0';
                  vsync_notify       <= '0';
                  is_vid_frm         <= '0';
                  is_vsync_frm       <= '0';
                  vinfo_wren         <= '0';
                  d_frm_dur          <= '0';
                  vinfo_waddr_buf    <= (others=>'0');
                  max_cnt            <= (others=>'0');
				  err <= '0';
            elsif xgmii_data_c_align(  8-1 downto 0) = X"01" and 
                  xgmii_data_align( 7 downto  0  ) = X"FB" then ---need to fixed 
                  max_cnt       <= (others=>'0');
				  check_sum_get <= xgmii_data_align(23 downto 16);
				  check_sum_buf <= check_sum_buf + xgmii_data_align;
                  if xgmii_data_align( 15 downto  8) = FRM_VSYNC then 
                      vsync_notify       <= '1'; 
                      is_vid_frm         <= '0';
                      is_vsync_frm       <= '1';
                      trans_fifo_wrreq   <= '0';
                      d_frm_dur          <= '1';
                      vinfo_wren         <= '0'; 
                      vinfo_waddr_buf    <= (others=>'0');
                  elsif xgmii_data_align( 15 downto  8) = FRM_VID then 
                      trans_fifo_wrreq  <= '0'; 
                      d_frm_dur         <= '1';
                      vsync_notify      <= '0';
                      is_vsync_frm      <= '0';
                      is_vid_frm        <= '1';
                      vinfo_wren        <= '0';
                  else 
                      d_frm_dur         <= '0';
                      trans_fifo_wrreq  <= '0'; 
                      vsync_notify      <= '0';
                      is_vsync_frm      <= '0';
                      is_vid_frm        <= '0';
                      vinfo_wren        <= '0';
                  end if;
				  
				    if check_sum_lock /= xgmii_data_align(23 downto 16) then					
						err <= '1';

				    end if;
                 
            -- elsif ( d_frm_dur  = '1' and d_fifo_wdata(71) /= '0')  then  
            elsif (xgmii_data_c_align(  8-1 downto 0) = X"FF" and 
                  xgmii_data_align( 7 downto  0  ) = X"FD" )  then  
                  d_frm_dur         <= '1'; 
                  trans_fifo_wrreq  <= '0';
                  vsync_notify      <= '0';
                  vinfo_wren        <= '0';
                  is_vsync_frm      <= '0';
                  is_vid_frm        <= '0';
				  check_sum_lock    <= check_sum_buf(7 downto 0);
				  check_sum_buf     <= (others=>'0');
				  err <= '0';

            
            else 
                if max_cnt(8) = '0' then 
                     max_cnt <= max_cnt + 1;
                end if;
				err <= '0';
                
                if max_cnt(8) = '1' then 
                    vsync_notify     <= '0'; ---bad ,discard it ....
                    d_frm_dur        <= '0'; ---bad ,discard it ....
                    trans_fifo_wrreq <= '0'; ---bad ,discard it ....
                    vinfo_wren       <= '0'; ---bad ,discard it ....
                    is_vid_frm       <= '0'; ---bad ,discard it ....
                    is_vsync_frm     <= '0'; ---bad ,discard it ....
                else 
                    trans_fifo_wrreq <= is_vid_frm;
                    if max_cnt <   vinfo_waddr_max then 
                       vinfo_wren  <= is_vsync_frm;
                    else 
                       vinfo_wren  <= '0'; ---put it clear it to avoid overflow 
                    end if;
                end if;
                
                if vinfo_wren = '1' then  
                    vinfo_waddr_buf   <= vinfo_waddr_buf  + 1 ; 
                end if;
				
				if is_vid_frm = '1' or is_vsync_frm = '1' then
					check_sum_buf <= check_sum_buf + xgmii_data_align;
				end if;
						
				
				
            end if; 
            
            vinfo_wdata                  <= xgmii_data_align(63 downto 0);            
            d_fifo_wdata( 71 downto  16) <= xgmii_data_c_align( 7 downto  0)&xgmii_data_align( 63 downto 16);
            d_fifo_wdata( 7  downto  0)  <= xgmii_data_align( 7 downto  0);
            d_fifo_wdata( 15 downto  8)  <= xgmii_data_align( 15 downto  8);
           
    end if;
   end process;
   
   trans_fifo_wdata <= d_fifo_wdata;
   
   --vsync_notify is amost 64 cycles 
   --it is enough to clear the fifo
   --
   
    vinfo_waddr   <=  vinfo_waddr_buf ; 
    vs_bright_data: vsyncinfo_ram 
        port map (
            data       => vinfo_wdata  , -- datain
            q          => vinfo_rdata  ,                  -- dataout
            wraddress  => vinfo_waddr  , -- wraddress
            rdaddress  => vinfo_raddr  , -- rdaddress
            wren       => vinfo_wren   ,             -- wren
            wrclock    => rx_bk_clk ,                     -- clk
            rdclock    => txclk_i                       -- clk
       );
       
       
    vcrs1_i: vsync_cross  
    generic map(DLY_CY =>5 )
    port map
    (
      vsync_async  => trans_fifo_wrreq ,
      nRST         => nRST_txc,
      clk          => txclk_i,
      vsync_synced => trans_wren_txclk 
    ); 
    
    wren_neg_edge  <= '1' when dly_wren_txclk  = '1' and trans_wren_txclk  = '0' else '0';
    vcrs2_i: vsync_cross  
    generic map(DLY_CY =>5 )
    port map
    (
      vsync_async  => vsync_notify ,
      nRST         => nRST_txc,
      clk          => txclk_i,
      vsync_synced => vsync_txclk
    ); 
   -----------------------------------------------------
      
   process(txclk_i,nRST_txc)
   begin 
        if nRST_txc = '0' then 
               dly_vsync_txc <= '0';
        elsif rising_edge(txclk_i) then 
               dly_vsync_txc <= vsync_txclk;
               if dly_vsync_txc ='1' and vsync_txclk = '0'  then --falling edge 
                   vsync_neg_txc <= '1';
               else 
                   vsync_neg_txc <= '0';
               end if; 
        end if;
    end process;

    
   process(txclk_i,nRST_txc)
   begin 
        if nRST_txc = '0' then 
                vid_pckcnt <= (others=>'0');
                vid_pck_empty  <= (  '1');
                dly_wren_txclk <= (  '0');
        elsif rising_edge(txclk_i) then 
                dly_wren_txclk <= trans_wren_txclk;
                
                if vsync_txclk = '1' then --clear and suppress it here 
                     vid_pckcnt      <= (others=>'0');
                     vid_pck_empty   <= (  '1');
                elsif wren_neg_edge  = '1' and rd_done_notify_txc = '1' then 
                     vid_pckcnt  <= vid_pckcnt   ;
                elsif wren_neg_edge   = '1'  then 
                     vid_pckcnt  <= vid_pckcnt + 1;
                     vid_pck_empty   <= '0';
                elsif rd_done_notify_txc   ='1' then 
                     vid_pckcnt  <= vid_pckcnt  - 1;
                     if vid_pckcnt <= 1 then 
                         vid_pck_empty <= '1';
                     end if;
                end if; 
        end if;
    end process;
    vid_pck_empty_txc <= vid_pck_empty;
    vid_pckcnt_txc  <= vid_pckcnt;
    vsync_txc_o     <= vsync_txclk; 

end beha;