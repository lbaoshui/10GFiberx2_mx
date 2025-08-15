

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity uart_64to8 is
generic
(
    PORTNUM_EVERY_FIBER    : integer:= 10;
    HSSI_NUM               : integer:= 2;
	TXSUBCARD_TYPE      : std_logic_vector(7  downto 0)
);
port
(
    nRST                : in  std_logic;
    sysclk              : in  std_logic;
    nRST_rxclk          : in  std_logic_vector(HSSI_NUM-1 downto 0);
    rxclk               : in  std_logic_vector(HSSI_NUM-1 downto 0);
    nRST_txclk          : in  std_logic;
    txclk               : in  std_logic;
	nRST_convclk        : in  std_logic;
	convclk_i           : in  std_logic;
    xgmii_tx_data       : in  std_logic_vector(HSSI_NUM*64-1 downto 0);
    xgmii_tx_ctrl       : in  std_logic_vector(HSSI_NUM*8-1 downto 0);
    xgmii_rx_updata     : in  std_logic_vector(HSSI_NUM*64-1 downto 0);
    xgmii_rx_upctrl     : in  std_logic_vector(HSSI_NUM*8-1 downto 0);
    cur_slot_num_sys    : in  std_logic_vector(3 downto 0);

    eth_link_sys            : out std_logic_vector(HSSI_NUM*PORTNUM_EVERY_FIBER-1 downto 0);
    --err_num_fiber_sys       : out std_logic_vector(HSSI_NUM*32-1 downto 0);
    subframe_FB_serdrx      : out std_logic_vector(HSSI_NUM-1 downto 0);
    autolight_outen_sys     : out std_logic_vector(PORTNUM_EVERY_FIBER*HSSI_NUM-1 downto 0);
    autolight_outval_sys    : out std_logic_vector(PORTNUM_EVERY_FIBER*8*HSSI_NUM-1 downto 0);

    Up08_net_rel_idx_conv :  in std_logic_vector(8-1 downto 0) ; 
    up08_timeout_notify  :  out std_logic_vector(HSSI_NUM-1 downto 0) ;---time out now ......
    Up08_startimer       :  in  std_logic_vector(HSSI_NUM-1 downto 0) ; --NOTIFY ,turn signal ,0to1 or  1to0 
    quick08_wren_convclk         :  in  std_logic  ;
    quick08_waddr_convclk        :  in  std_logic_vector(10 downto 0);
    quick08_wdata_convclk        :  in  std_logic_vector( 7 downto 0);
    quick08_flg          :  in  std_logic_vector(HSSI_NUM-1 downto 0); 
    quick08_filter_en    :  in  std_logic_vector(HSSI_NUM-1 downto 0);  --up 08 filtered or not -----
    quick08_addr_len     :  in  std_logic_vector(7 downto 0);    

	Up_cmd_fifo_empty_sys  : out std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_rden_sys   : in  std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_q_sys      : out std_logic_vector(HSSI_NUM*29-1 downto 0);
    Up_ReadAddr_sys        : in  std_logic_vector(11 downto 0);
    Up_ReadData_sys        : out std_logic_vector(HSSI_NUM*8-1 downto 0) ;
	
	real_eth_num_sys       : in  std_logic_vector(3 downto 0)

);
end uart_64to8;

architecture beha of uart_64to8 IS

component xgmii2uart is
generic
(
    ETHPORT_NUM         : integer:= 10 ;
    port_num            : integer:= 0;
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
end component;

signal Up_ReadLength    : std_logic_vector(HSSI_NUM*11-1 downto 0);
signal Up_ReadData      : std_logic_vector(HSSI_NUM*8-1 downto 0);
signal Up_req_buf       : std_logic_vector(HSSI_NUM-1 downto 0);
signal port0_using      : std_logic;

signal xgmii_rx_updata_d1 : std_logic_vector(HSSI_NUM*64-1 downto 0);
signal xgmii_rx_upctrl_d1 : std_logic_vector(HSSI_NUM*8-1 downto 0);
signal xgmii_rx_updata_d2 : std_logic_vector(HSSI_NUM*64-1 downto 0);
signal xgmii_rx_upctrl_d2 : std_logic_vector(HSSI_NUM*8-1 downto 0);
signal xgmii_rx_updata_d3 : std_logic_vector(HSSI_NUM*64-1 downto 0);
signal xgmii_rx_upctrl_d3 : std_logic_vector(HSSI_NUM*8-1 downto 0);
signal upload_en          : std_logic_vector(HSSI_NUM-1 downto 0);

component filter_upstream is
generic(

	PORTNUM_EVERY_FIBER : integer := 10
);
   
port(

   nRST                          : in std_logic;
   ddr3cmd_nRST                  : in std_logic;
   ddr3cmd_clk                   : in std_logic;
    
   serd_rx_clk                   : in  std_logic;
   adjust_rx_k		             : in  std_logic_vector(7 downto 0);  
   adjust_rx_data                : in  std_logic_vector(63 downto 0);


   filt_adjust_rx_k              : out std_logic_vector(7 downto 0);
   filt_adjust_rx_data           : out std_logic_vector(63 downto 0);
   
   eth_status_sys                : out std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
   err_num_fiber_sys             : out std_logic_vector(31 downto 0);
   fiber_status_flag_serdrx      : out std_logic;
   
   autolight_outen_ddr3cmd               : out std_logic_vector(PORTNUM_EVERY_FIBER-1 downto 0);
   autolight_outval_ddr3cmd              : out std_logic_vector(PORTNUM_EVERY_FIBER*8-1 downto 0)

 
);
end component;
signal  filt_adjust_rx_k              :  std_logic_vector(8*HSSI_NUM -1 downto 0);
signal  filt_adjust_rx_data           :  std_logic_vector(64*HSSI_NUM-1 downto 0);

signal  autolight_outen_sys_buf       :  std_logic_vector(PORTNUM_EVERY_FIBER*HSSI_NUM-1 downto 0);
signal  autolight_outval_sys_buf      :  std_logic_vector(PORTNUM_EVERY_FIBER*8*HSSI_NUM-1 downto 0);


begin




process(nRST,sysclk)
begin
	if nRST = '0' then
		autolight_outen_sys <= (others=>'0');
		autolight_outval_sys<= (others=>'0');
	elsif rising_edge(sysclk) then
		if real_eth_num_sys = 4 then
			autolight_outen_sys <= (others=>'0');
			autolight_outen_sys(8-1 downto 0) <= autolight_outen_sys_buf(13 downto 10)&autolight_outen_sys_buf(3 downto 0);
			autolight_outval_sys<= (others=>'0');
			autolight_outval_sys(8*8-1 downto 0)<= autolight_outval_sys_buf(14*8-1 downto 10*8)&autolight_outval_sys_buf(4*8-1 downto 0*8);
		else
			autolight_outen_sys <= autolight_outen_sys_buf;
			autolight_outval_sys<= autolight_outval_sys_buf;
		end if;
	end if;
end process;



xgmii2uart_gen : for i in 0 to HSSI_NUM-1 generate --2 fiber or 4 fiber or 4 5G-eth
   filter_frame_i: filter_upstream 
   generic map(
   
   	PORTNUM_EVERY_FIBER => PORTNUM_EVERY_FIBER
   )
      
   port map(
   
      nRST                          => nRST   ,
      ddr3cmd_clk                   => sysclk ,
      ddr3cmd_nRST                  => nRST   ,
                                    
      serd_rx_clk                   => rxclk(i)      ,
      adjust_rx_k		            => xgmii_rx_upctrl (i*8 +7  downto i*8  ) ,
      adjust_rx_data                => xgmii_rx_updata (i*64+63 downto i*64 ) ,
                                                      
                                     
      filt_adjust_rx_k              => filt_adjust_rx_k   (i*8 +7  downto i*8  )  ,
      filt_adjust_rx_data           => filt_adjust_rx_data(i*64+63 downto i*64 )  ,
                                   
      eth_status_sys                => eth_link_sys( (i+1)*PORTNUM_EVERY_FIBER -1 downto i*PORTNUM_EVERY_FIBER), ---eth_status_serdrx,
      fiber_status_flag_serdrx      => subframe_FB_serdrx(i), ------fiber_status_flag_serdrx,
	  err_num_fiber_sys             => open ,----err_num_fiber_sys(i*32+31 downto i*32),
                                   
      autolight_outen_ddr3cmd        => autolight_outen_sys_buf (PORTNUM_EVERY_FIBER*(i+1)-1 downto i*PORTNUM_EVERY_FIBER),
      autolight_outval_ddr3cmd       => autolight_outval_sys_buf(PORTNUM_EVERY_FIBER*8*(i+1)-1 downto i*PORTNUM_EVERY_FIBER*8)
   
    
   );


xgmii2uart_inst : xgmii2uart
generic map (
    ETHPORT_NUM     => PORTNUM_EVERY_FIBER ,
    port_num        => i,
	TXSUBCARD_TYPE  => TXSUBCARD_TYPE
)
port map (

---------------rxclk ------
    nRST_rxclk             => nRST_rxclk(i),
    rxclk                  => rxclk(i),
    xgmii_rx_updata        => xgmii_rx_updata_d3(i*64+63 downto i*64),
    xgmii_rx_upctrl        => xgmii_rx_upctrl_d3(i*8 + 7 downto i*8 ),
                           
--------------convclk -----
	nRST_convclk		   => nRST_convclk,
	convclk_i              => convclk_i     ,
    up08_timeout_notify    => up08_timeout_notify(i), 
    Up08_startimer         => Up08_startimer    (i),
    Up08_net_rel_idx       => Up08_net_rel_idx_conv , 
    quick08_wren_convclk   => quick08_wren_convclk      ,
    quick08_waddr_convclk  => quick08_waddr_convclk     ,
    quick08_wdata_convclk  => quick08_wdata_convclk     ,
    quick08_flg_conv       => quick08_flg(i)       ,
    quick08_filter_en_conv => quick08_filter_en(i) ,
    quick08_addr_len_conv  => quick08_addr_len  ,
                           
---------------sysclk------
	nRST_sys               => nRST,
    sysclk                 => sysclk,
	cur_slot_num_sys       => cur_slot_num_sys ,
	Up_cmd_fifo_empty_sys  => Up_cmd_fifo_empty_sys(i),
	Up_cmd_fifo_rden_sys   => Up_cmd_fifo_rden_sys(i),
	Up_cmd_fifo_q_sys      => Up_cmd_fifo_q_sys((i+1)*29-1 downto i*29),
    Up_ReadAddr_sys        => Up_ReadAddr_sys,
    Up_ReadData_sys        => Up_ReadData_sys((i+1)*8-1 downto i*8),
	real_eth_num_sys       => real_eth_num_sys

);
process(rxclk(i),nRST_rxclk(i))
begin
    if nRST_rxclk(i) = '0' then
        upload_en(i) <= '0';
    elsif rising_edge(rxclk(i)) then
        -- xgmii_rx_updata_d1(i*64+63 downto i*64) <= xgmii_rx_updata(i*64+63 downto i*64);
        xgmii_rx_updata_d1(i*64+63 downto i*64) <= filt_adjust_rx_data(i*64+63 downto i*64);
        xgmii_rx_updata_d2(i*64+63 downto i*64) <=  xgmii_rx_updata_d1(i*64+63 downto i*64);
        xgmii_rx_updata_d3(i*64+63 downto i*64) <=  xgmii_rx_updata_d2(i*64+63 downto i*64);
        -- xgmii_rx_upctrl_d1(i*8+7 downto i*8) <= xgmii_rx_upctrl(i*8+7 downto i*8);
        xgmii_rx_upctrl_d1(i*8+7 downto i*8)   <= filt_adjust_rx_k  (i*8+7 downto i*8);
        xgmii_rx_upctrl_d2(i*8+7 downto i*8)   <= xgmii_rx_upctrl_d1(i*8+7 downto i*8);
		
		--need to fixed here ....
        if xgmii_rx_upctrl_d1(i*8+7 downto i*8) = X"01" then  --filter here ,frame type here 
            if filt_adjust_rx_data(i*64+39 downto i*64+32) = X"55" or
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"54" or
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"53" or
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"01" or
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"06" or
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"26" or
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"D0" or
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"07" or
               -- xgmii_rx_updata(i*64+39 downto i*64+32) = X"00" then
               filt_adjust_rx_data(i*64+39 downto i*64+32) = X"00" then
                upload_en(i) <= '0';
            else
                upload_en(i) <= '1';
            end if;
        end if;
        
        if upload_en(i) = '1' then
            xgmii_rx_upctrl_d3(i*8+7 downto i*8) <= xgmii_rx_upctrl_d2(i*8+7 downto i*8);
        else
            xgmii_rx_upctrl_d3(i*8+7 downto i*8) <= X"FF";
        end if;
    end if;
end process;
end generate xgmii2uart_gen;

-- Up_req <= Up_req_buf;

-- Up_ReadLength_i <= Up_ReadLength ;------(10 downto 0) when Up_req_buf(0) = '1' else Up_ReadLength(21 downto 11);
-- Up_ReadData_i   <= Up_ReadData   ;-----(7 downto 0)    when port0_using = '1'   else Up_ReadData(15 downto 8);
-- process(sysclk)
-- begin
    -- if rising_edge(sysclk) then
        -- if Up_ack(0) = '1' then
            -- port0_using <= '1';
        -- elsif Up_ack(1) = '1' then
            -- port0_using <= '0';
        -- end if;
    -- end if;
-- end process;

end beha;