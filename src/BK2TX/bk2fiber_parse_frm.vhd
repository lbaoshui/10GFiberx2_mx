library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bk2fiber_parse_frm is
generic
(  SERDES_5G_EN      : std_logic;
   ETHPORT_NUM       : integer ; --how many eth port 
   FIBER_NUM         : integer ;
   BKHSSI_NUM        : integer  
);
port 
(
    nRST_bk_rxclk         : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_clk             : in std_logic_vector(BKHSSI_NUM-1  downto 0);
    rx_bk_parallel_data   : in std_logic_vector(BKHSSI_NUM*64-1 downto 0);
    rx_bk_control         : in std_logic_vector(BKHSSI_NUM*8 -1 downto 0);
    
    nRST_fiber_clk       : in  std_logic    ; ---
    fiber_txclk          : in  std_logic    ; --200M almost 
    fiber_parallel_data  : out std_logic_vector(FIBER_NUM*64-1 downto 0);
    fiber_control        : out std_logic_vector(FIBER_NUM*8 -1 downto 0)
);

end bk2fiber_chan;

architecture beha of bk2fiber_chan is 
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

signal xgmii_data_c_align       : std_logic_vector(BKHSSI_NUM* 8-1 downto 0);
signal xgmii_data_align         : std_logic_vector(BKHSSI_NUM*64-1 downto 0);

constant F_AW : integer := 11;
constant DLY_W: integer := 17;

-----synced to read ,not sync to write 
component trans_fifo_in is
   port (
            data    : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
            wrreq   : in  std_logic                     := 'X';             -- wrreq
            rdreq   : in  std_logic                     := 'X';             -- rdreq
            wrclk   : in  std_logic                     := 'X';             -- wrclk
            rdclk   : in  std_logic                     := 'X';             -- rdclk
            aclr    : in  std_logic                     := 'X';    
            q       : out std_logic_vector(71 downto 0);                    -- dataout
            rdusedw : out std_logic_vector(F_AW-1 downto 0);                     -- rdusedw
            wrusedw : out std_logic_vector(F_AW-1 downto 0);                     -- wrusedw
            rdempty : out std_logic;                                        -- rdempty
            wrfull  : out std_logic                                         -- wrfull
        );
   
end component trans_fifo_in;

signal trans_rdusedw       : std_logic_vector(F_AW*BKHSSI_NUM-1 downto 0);
signal trans_wrusedw       : std_logic_vector(F_AW*BKHSSI_NUM-1 downto 0);
signal trans_fifo_wrreq    : std_logic_vector(   1*BKHSSI_NUM-1 downto 0);
signal trans_fifo_wrreq_buf: std_logic_vector(   1*BKHSSI_NUM-1 downto 0);
signal trans_fifo_data     : std_logic_vector(  72*BKHSSI_NUM-1 downto 0);
signal trans_fifo_q        : std_logic_vector(  72*BKHSSI_NUM-1 downto 0);
signal delay_cnt           : std_logic_vector(DLY_W*BKHSSI_NUM-1 downto 0):=(others=>'0');
signal trans_aclr          : std_logic_vector(   1*BKHSSI_NUM-1 downto 0) := (others=>'0');  
signal vsync_notify        : std_logic_vector(   1*BKHSSI_NUM-1 downto 0) := (others=>'0');  
signal trans_wren_txclk    : std_logic_vector(   1*BKHSSI_NUM-1 downto 0) := (others=>'0');  
constant FRM_VID             : std_logic_vector(   8-1 downto 0) := X"00"; 
constant FRM_VSYNC           : std_logic_vector(   8-1 downto 0) := X"01"; 
constant FRM_AUD             : std_logic_vector(   8-1 downto 0) := X"02";  
constant FRM_AUD             : std_logic_vector(   8-1 downto 0) := X"03";  

constant V_W : integer := 5 ;
constant P_W : integer := 5 ;
signal vid_pckcnt   : std_logic_vector( BKHSSI_NUM*P_W-1 downto 0*P_W) := (others=>'0'); -- datain
signal vinfo_wdata     : std_logic_vector( BKHSSI_NUM*32-1 downto 0*32) := (others=>'0'); -- datain
signal vinfo_rdata     : std_logic_vector( BKHSSI_NUM*32-1 downto 0*32) := (others=>'0');                  -- dataout
signal vinfo_waddr_buf : std_logic_vector( BKHSSI_NUM*V_W -1 downto 0*V_W ) := (others=>'0'); -- wraddress
signal vinfo_waddr     : std_logic_vector( BKHSSI_NUM*V_W -1 downto 0*V_W ) := (others=>'0'); -- wraddress
signal vinfo_raddr     : std_logic_vector( BKHSSI_NUM*V_W -1 downto 0*V_W ) := (others=>'0'); -- rdaddress
signal vinfo_wren      : std_logic_vector( BKHSSI_NUM*1 -1   downto 0*1 ) := (others=>'0');           -
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

signal vsync_txclk : std_logic := '0';
signal vsync_neg_txc : std_logic := '0';
signal dly_vsync_txc : std_logic := '0';

    component vsyncinfo_ram is
        port (
            data      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datain
            q         : out std_logic_vector(31 downto 0);                    -- dataout
            wraddress : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- wraddress
            rdaddress : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- rdaddress
            wren      : in  std_logic                     := 'X';             -- wren
            wrclock   : in  std_logic                     := 'X';             -- clk
            rdclock   : in  std_logic                     := 'X'              -- clk
        );
    end component vsyncinfo_ram;
    

begin 


align_i: for i in 0 to BKHSSI_NUM-1 GENERATE 
    BK_dataalign_inst : xgmii_dataalign
    port map
    (
        rx_clk                  => rx_bk_clk (i),
        rx_parallel_data        => rx_bk_parallel_data( (I+1)*64-1 downto I*64),                     -- rx_parallel_data
        rx_control              => rx_bk_control      ( (I+1)* 8-1 downto I* 8),                     -- rx_datak
    
        data_c_align            => xgmii_data_c_align( (I+1)* 8-1 downto I* 8),
        data_align              => xgmii_data_align  ( (I+1)*64-1 downto I*64)
    
    );
    
    trans_fifo_in_inst : trans_fifo_in
           port map
           (
            data    => trans_fifo_data     ( (i+1)*72-1 downto i*72),
            wrreq   => trans_fifo_wrreq_buf(i) ,
            rdreq   => trans_fifo_rdreq    (i),
            wrclk   => rx_bk_clk(i),
            rdclk   => fiber_txclk,
            aclr    => trans_aclr(i), --synced to read ,not sync to write 
            q       => trans_fifo_q ( (i+1)*72-1 downto i*72),
            rdusedw  => trans_rdusedw( (i+1)*F_AW-1 downto i*F_AW) ,-- rdusedw
            wrusedw  => trans_wrusedw( (i+1)*F_AW-1 downto i*F_AW) ,                     -- wrusedw
            wrfull  => trans_fifo_wrfull (i),
            rdempty => trans_fifo_rdempty(i)
           );
           trans_fifo_wrreq_buf(i) <=     trans_fifo_wrreq(i) when trans_fifo_wrfull(i) ='0' else '0';
           trans_fifo_rdreq     <= '0' when (trans_fifo_rdempty = '1' or (rdreq_en_d1 = '1' and trans_fifo_q(71) /= '0')) else rdreq_en;


process(nRST_bk_rxclk (i),rx_bk_clk(i))
begin
    if nRST_bk_rxclk(i) = '0' then
        trans_fifo_wrreq(i)  <= '0';
        frame_head_en(i)     <= '0'; 
        vsync_notify(i)      <= '0';
		vi_wren     (i)      <= '0';		
        dly_cnt(DLY_W*(i+1)-1 downto DLY_W*i ) <=(others=>'0');
    elsif rising_edge (rx_bk_clk(i) ) then
        if dly_cnt(DLY_W*(i+1)-1) = '0' then 
            dly_cnt(DLY_W*(i+1)-1 downto DLY_W*i ) <= dly_cnt(DLY_W*(i+1)-1 downto DLY_W*i )  + 1;
        end if;
        
        ---if SERDES_5G_EN = '0' then
            if dly_cnt(DLY_W*(i+1)-1) = '0' then 
                  trans_fifo_wrreq (i) <= '0';
                  vsync_notify(i)      <= '0';
				  vinfo_wren     (i)      <= '0';
				  vinfo_waddr_buf ((i+1)*V_W-1 downto i*V_W) <= (others=>'0');
            elsif xgmii_data_c_align((i+1)*8-1 downto i*8) = X"01" and 
                  xgmii_data_align(i*64+7 downto i*64+0  ) = X"FB" then ---need to fixed 
                  if xgmii_data_align(i*64+15 downto i*64+8) = FRM_VSYNC then 
                      vsync_notify(i)     <= '1'; 
					  trans_fifo_wrreq(i) <= '0';
					  vinfo_wren     (i)     <= '1'; 
					  vinfo_waddr_buf ((i+1)*V_W-1 downto i*V_W) <= (others=>'0');
                  elsif xgmii_data_align(i*64+15 downto i*64+8) = FRM_VID then 
                      trans_fifo_wrreq(i) <= '1'; 
                      vsync_notify(i)     <= '0';
					  vinfo_wren     (i)      <= '0';
                  else 
                      trans_fifo_wrreq(i) <= '0'; 
                      vsync_notify(i)     <= '0';
					  vinfo_wren     (i)     <= '0';
                  end if;
            elsif trans_fifo_wrreq(i) = '1' and trans_fifo_data(i*64+71) /= '0' then
                  trans_fifo_wrreq(i) <= '0';
                  vsync_notify(i)     <= '0';
				  vinfo_wren     (i)      <= '0';
			else 
			    if vinfo_wren(i) = '1' then 
				   vinfo_waddr_buf ((i+1)*V_W-1 downto i*V_W) <= vinfo_waddr_buf ((i+1)*V_W-1 downto i*V_W) + 1 ;
				end if;
            end if; 
            
			vinfo_wdata ( (i+1)*32-1 downto i*32) <= xgmii_data_align(i*64+31 downto i*64+0);
			
            trans_fifo_data(i*64+71 downto i*64+16) <= xgmii_data_c_align(i*8+7 downto i*8+0)&xgmii_data_align(i*64+63 downto i*64+16);
            trans_fifo_data(i*64+7  downto i*64+0)    <= xgmii_data_align(i*64+7 downto i*64+0);
            if dly_cnt(DLY_W*(i+1)-1) = '1' and xgmii_data_c_align(i*8+7 downto i*8+0) = X"01" then
                trans_fifo_data(i*64+15 downto i*64+8) <= check_sum_tx;
            else
                trans_fifo_data(i*64+15 downto i*64+8) <= xgmii_data_align(i*64+15 downto i*64+8);
            end if;
        -- else
            -- if dly_cnt(DLY_W) = '0' then 
                 -- frame_head_en <= '0';
            -- elsif xgmii_data_c_align = X"01" and xgmii_data_align(i*64+7 downto i*64+0) = X"FB" then
                 -- frame_head_en <= '1';
            -- else
                 -- frame_head_en <= '0';
            -- end if;
            
            -- if dly_cnt(DLY_W) = '0' then 
                  -- trans_fifo_wrreq <= '0';
            -- elsif frame_head_en = '1' and xgmii_data_align(i*64+19 downto i*64+16) = port_sel then
                -- trans_fifo_wrreq <= '1';
            -- elsif trans_fifo_wrreq = '1' and trans_fifo_data(71) /= '0' then
                -- trans_fifo_wrreq <= '0';
            -- end if;
            -- if frame_head_en = '1' then
                -- trans_fifo_data_b1(i*64+19 downto i*64+16) <= (others => '0');
            -- else
                -- trans_fifo_data_b1(i*64+19 downto i*64+16) <= xgmii_data_align(i*64+19 downto 16);
            -- end if;
            -- trans_fifo_data_b1(71 downto 20) <= xgmii_data_c_align&xgmii_data_align(63 downto 20);
            -- trans_fifo_data_b1(15 downto 0) <= xgmii_data_align(15 downto 0);
            -- trans_fifo_data(71 downto 16) <= trans_fifo_data_b1(71 downto 16);
            -- trans_fifo_data(7 downto 0) <= trans_fifo_data_b1(7 downto 0);
            -- if trans_fifo_data_b1(71 downto 64) = X"01" then
                -- trans_fifo_data(15 downto 8) <= check_sum_tx;
            -- else
                -- trans_fifo_data(15 downto 8) <= trans_fifo_data_b1(15 downto 8);
            -- end if;
        -- end if;
    end if;
   end process;
   
   
   vcrs_i: vsync_cross  
    generic map(DLY_CY =>5 )
    port map
    (
      vsync_async  => trans_fifo_wrreq(i),
      nRST         => nRST_fiber_clk,
      clk          => fiber_txclk,
      vsync_synced => trans_wren_txclk(i)
    ); 
	
	wren_neg_edge(i) <= '1' when dly_wren_txclk(i) = '1' and trans_wren_txclk(i) = '0' else '0';
	
    dly_wr_i: process(fiber_txclk,nRST_fiber_clk)
    begin 
        if nRST_fiber_clk = '0' then  
			 dly_wren_txclk(i) <= (others=>'0');
        elsif rising_edge(fiber_txclk) then 
		     dly_wren_txclk(i)  <= trans_wren_txclk(i) ;
		end if;
	end process;

END GENERATE align_i;

   
  


  vi_waddr   <=  vi_waddr_buf ; 
  vs_bright_data: vsyncinfo_ram 
        port map (
            data       => vinfo_wdata ( (0+1)*32-1 downto 0*32), -- datain
            q          => vinfo_rdata ( (0+1)*32-1 downto 0*32),                  -- dataout
            wraddress  => vinfo_waddr ( (0+1)*5 -1 downto 0*5 ), -- wraddress
            rdaddress  => vinfo_raddr ( (0+1)*5 -1 downto 0*5 ), -- rdaddress
            wren       => vinfo_wren  (i),             -- wren
            wrclock    => rx_bk_clk(i),                     -- clk
            rdclock    => fiber_txclk                       -- clk
       );
	   
	   
   -----------------------------------------------------
   vcrs_i: vsync_cross  
    generic map(DLY_CY =>5 )
    port map
    (
      vsync_async  => vsync_notify(0),
      nRST         => nRST_fiber_clk,
      clk          => fiber_txclk,
      vsync_synced => vsync_txclk
    );
  
     
	wren_neg_edge <= '1' when dly_wren_txclk(i) = '1' and trans_wren_txclk(i) = '0' else '0';
	
    process(fiber_txclk,nRST_fiber_clk)
   begin 
        if nRST_fiber_clk = '0' then 
                vid_pckcnt <= (others=>'0');
				dly_wren_txclk <= (others=>'0');
        elsif rising_edge(fiber_txclk) then 
		     dly_wren_txclk <= trans_wren_txclk;
		     for i in 0 to BKHSSI_NUM-1 loop
			     if vsync_txclk = '1' then --clear and suppress it here 
				     vid_pckcnt( (i+1)*P_W-1 DOWNTO I*P_W) <= (others=>'0');
				 elsif wren_neg_edge(i) = '1' and rd_done_edge = '1' then 
				     vid_pckcnt( (i+1)*P_W-1 DOWNTO I*P_W) <= vid_pckcnt( (i+1)*P_W-1 DOWNTO I*P_W)  ;
				 elsif wren_neg_edge(i)  = '1'  then 
				     vid_pckcnt( (i+1)*P_W-1 DOWNTO I*P_W) <= vid_pckcnt( (i+1)*P_W-1 DOWNTO I*P_W) + 1;
				 elsif rd_done_edge   ='1' then 
				     vid_pckcnt( (i+1)*P_W-1 DOWNTO I*P_W) <= vid_pckcnt( (i+1)*P_W-1 DOWNTO I*P_W) - 1;
				 end if;
			 end loop;
		end if;
	end process;
   -----------------------------------------------------

   
   process(fiber_txclk,nRST_fiber_clk)
   begin 
        if nRST_fiber_clk = '0' then 
               dly_vsync_txc <= '0';
        elsif rising_edge(fiber_txclk) then 
               dly_vsync_txc <= vsync_txclk;
			   if dly_vsync_txc ='1' and vsync_txclk = '0'  then --falling edge 
			       vsync_neg_txc <= '1';
			   else 
			       vsync_neg_txc <= '0';
			   end if;
        end if;
    end process;
	
	
	process(iber_txclk,nRST_fiber_clk)
    begin 
        if nRST_fiber_clk = '0' then
		    vsync_arrived_txc<= '0';
		elsif  rising_edge(fiber_txclk) then 
	         if vsync_neg_txc = '1' then 
                vsync_arrived_txc<= '1';  
             elsif vsync_arrived_ack = '1' then 
                vsync_arrived_txc<= '0';
             end if;
        end if;
    end process;		
	
	process(iber_txclk,nRST_fiber_clk)
   begin 
        if nRST_fiber_clk = '0' then 
              pstate   <= wait_st;
			  wait_cnt <= (others=>'0');
			  loop_cnt <= (others=>'0');
			  tx_cnt   <= (others=>'0');
			  vsync_arrived_ack <= '0';
        elsif rising_edge(fiber_txclk) then 
	--------------------------------------------------------	         
                 case(pstate) is 
					 if 
              else 
					when wait_st =>
					    if wait_cnt(WAIT_W) = '1' THEN 
						   pstate <= txsync_st;
						else 
						   pstate <= wait_st;
						   wait_cnt <= wait_cnt + 1;
						end if;
						loop_cnt <= (others=>'0');
						
					when txsync_st =>  --we should consider the flowctnr  
					    vsync_arrived_ack <= '0';
					    if tx_cnt = 2000 then 
						   tx_cnt <= (others=>'0');
						   if loop_cnt = ETHPORT_NUM-1 then 
						      loop_cnt <= (others=>'0');
						      if rt_param_tx_en = '1' then 
							      pstate <= tx_rtparam_st;
							  else 
						          pstate <= idle_st;
							  end if;
						   else 
						      loop_cnt <= loop_cnt + 1;
						   end if;
						else 
						    tx_cnt <= tx_cnt + 1;
					    end if;
                    when tx_rtparam_st=>
						if tx_cnt = 2000 then
                           tx_cnt <= (others=>'0');	
                           pstate <= idle_st;						   
						else 
						    tx_cnt <= tx_cnt + 1; 
						end if;
					
					when idle_st => 
					       wait_cnt <= (others=>'0');
				           loop_cnt <= (others=>'0');
				           tx_cnt   <= (others=>'0');
					       if vsync_arrived_txc = '1' then 
			                    pstate <= wait_st;
				           else 
					            pstate <= idle;
						   end if;
				 end case;
              end if;
        end if;			  
    end process;




end bk2fiber_chan;

