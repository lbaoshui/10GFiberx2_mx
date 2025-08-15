

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity uart_param_top is
generic
(
    CONS_VER_HIGH       : std_logic_vector(7  downto 0);
    CONS_VER_LOW        : std_logic_vector(7  downto 0);
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0);
    FIBERPORT_NUM       : integer;
    ETHPORT_NUM         : integer; --PER FIBER 
    SERDES_SPEED_MSB    : integer;
    SERDES_SPEED_LSB    : integer;
    BAUD_DIV            : std_logic_vector(15 downto 0) ;
	DDR_NUM             : integer
   --- HSSI_NUM            : integer:= 2
);
port
(
    nRST            : in std_logic ;
    sysclk          : in std_logic;
	---to reduce the clock domain in HDMI region 
	nRST_cmd        : in std_logic ;
	cmd_clk         : in std_logic;    
	
	serdes_frame_ss		: in std_logic;
	serdes_rx_vld		: in std_logic;
	serdes_rx_data		: in std_logic_vector(7 downto 0);
	
    p_Frame_en_cmd    : out std_logic ;
    p_Wren_cmd        : out std_logic ;
    p_Data_cmd        : out std_logic_vector(7 downto 0);
    p_Addr_cmd        : out std_logic_vector(10 downto 0);
    cur_slot_num_cmd  : out std_logic_vector(15 downto 0);
     
    ---uart: 2 pins of uart
    rxd_top         : in  std_logic ;  --from top pad
    txd_top         : out std_logic ; ---to top pad
    txd_info_top    : out std_logic ; ---to top pad
    txd_autolight   : OUT std_logic   ; --to top pad 

    --info
    crc_info        : in std_logic_vector(7 downto 0);
    err_num         : in std_logic_vector(63 downto 0);
    err_num_fiber   : in std_logic_vector(63 downto 0);
    eth_link        : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    fiber_link      : in std_logic_vector(FIBERPORT_NUM-1 downto 0);
    time_ms_en_sys  : in std_logic ;
    autobright_en   : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    autobright_val  : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM*8-1 downto 0);

    p_Frame_en_o    : out std_logic ;
    p_Wren_o        : out std_logic ;
    p_Data_o        : out std_logic_vector(7 downto 0);
    p_Addr_o        : out std_logic_vector(10 downto 0);
    cur_slot_num    : out std_logic_vector(15 downto 0);
	
	get_curr_temp_phy_sys : in std_logic_vector(FIBERPORT_NUM*16-1 downto 0);

	Up_cmd_fifo_empty_sys  : in std_logic_vector(FIBERPORT_NUM-1 downto 0); 
	Up_cmd_fifo_rden_sys   : out  std_logic_vector(FIBERPORT_NUM-1 downto 0); 
	Up_cmd_fifo_q_sys      : in std_logic_vector(FIBERPORT_NUM*29-1 downto 0);
    Up_ReadAddr_sys        : out  std_logic_vector(11 downto 0);
    Up_ReadData_sys        : in std_logic_vector(FIBERPORT_NUM*8-1 downto 0); 

	backup_flag_sys      : in std_logic_vector(3 downto 0);	
	error_check_num_sys     : in std_logic_vector(4*16-1 downto 0);
	subbrdin_packet_cnt_sys : in std_logic_vector(4*32-1 downto 0);
	error_fe_num_sys        : in std_logic_vector(4*16-1 downto 0);
	serdes_rxlock           : in std_logic_vector(4 downto 0);
	
	real_eth_num_sys		: in std_logic_vector(3 downto 0);
	ddr_verify_end_sys       : in std_logic_vector(DDR_NUM-1 downto 0);
	ddr_verify_success_sys   : in std_logic_vector(DDR_NUM-1 downto 0)

);
end uart_param_top ;

architecture beha of uart_param_top IS
component uart_param is
generic
(
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0);
    BAUD_DIV            : std_logic_vector(15 downto 0):=X"043C";
    HSSI_NUM            : integer:= 2
);
port
(
    nRST            : in std_logic ;
    sysclk          : in std_logic;
	time_ms_en		: in std_logic ;
	---to reduce the clock domain in HDMI region 
	nRST_cmd        : in std_logic ;
	cmd_clk         : in std_logic;    
	
	serdes_frame_ss		: in std_logic;
	serdes_rx_vld		: in std_logic;
	serdes_rx_data		: in std_logic_vector(7 downto 0);
	para_serdes_lock	: in std_logic;
	
    p_Frame_en_cmd    : out std_logic ;
    p_Wren_cmd        : out std_logic ;
    p_Data_cmd        : out std_logic_vector(7 downto 0);
    p_Addr_cmd        : out std_logic_vector(10 downto 0);  
    cur_slot_num_cmd  : out std_logic_vector(15 downto 0);
	------sysclk clock domain ---------------------------------
    ---uart: 2 pins of uart
    rxd_top         : in  std_logic ;  --from top pad
    txd_top         : out std_logic ; ---to top pad

    p_Frame_en_o    : out std_logic ;
    p_Wren_o        : out std_logic ;
    p_Data_o        : out std_logic_vector(7 downto 0);
    p_Addr_o        : out std_logic_vector(10 downto 0);
    cur_slot_num    : out std_logic_vector(15 downto 0);

	Up_cmd_fifo_empty  : in std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_rden   : out  std_logic_vector(HSSI_NUM-1 downto 0); 
	Up_cmd_fifo_q      : in std_logic_vector(HSSI_NUM*29-1 downto 0);
    Up_ReadAddr        : out  std_logic_vector(11 downto 0);
    Up_ReadData        : in std_logic_vector(HSSI_NUM*8-1 downto 0) 
  ---latency is 2 ,after Up_ReadAddr_o;
);
end component ;

component autobright_upload is
generic(   
    ETH_PORT_NUM : integer := 8;
    BAUD		 : std_logic_vector(15 downto 0):= x"0020"    
);
port (
    sys_nRST                : in  std_logic;
    sysclk                  : in  std_logic;
    time_ms_en              : in  std_logic;
    autolight_en            : in  std_logic_vector(ETH_PORT_NUM-1 downto 0);    
    autolight_val           : in  std_logic_vector(8*( ETH_PORT_NUM) -1  downto 0) ;
    autolight_tx            : OUT std_logic   ;
    tx_autolight_val        : out std_logic_vector(8*( ETH_PORT_NUM) -1  downto 0);
    tx_autolight_vld        : out std_logic_vector(  ( ETH_PORT_NUM) -1  downto 0)

);
end component;

SIGNAL tx_autolight_val : STD_LOGIC_VECTOR( FIBERPORT_NUM*ETHPORT_NUM*8-1 downto 0);
SIGNAL tx_autolight_vld : STD_LOGIC_VECTOR( FIBERPORT_NUM*ETHPORT_NUM-1   downto 0);
component uart_info is
generic
(
    CONS_VER_HIGH       : std_logic_vector(7  downto 0);
    CONS_VER_LOW        : std_logic_vector(7  downto 0);
    TXSUBCARD_TYPE      : std_logic_vector(7  downto 0);
    ---PORT_NUM            : integer;
    FIBERPORT_NUM       : integer; --FIBER PORT NUM 
    ETHPORT_NUM         : integer; --ETH PORT PER FIBER  
  
    SERDES_SPEED_MSB    : integer;
    SERDES_SPEED_LSB    : integer;
    BAUD_DIV            : std_logic_vector(15 downto 0);
	DDR_NUM             : integer
);
port
(
    nRST                : in std_logic ;
    sysclk              : in std_logic ;
	time_ms_en_sys      : in std_logic ;
		
    txd_info_top        : out std_logic ; ---to top pad
    eth_link            : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    fiber_link          : in std_logic_vector(FIBERPORT_NUM-1 downto 0);
	
	get_curr_temp_phy_sys : in std_logic_vector(FIBERPORT_NUM*16-1 downto 0);

    autobright_en       : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM-1 downto 0);
    autobright_val      : in std_logic_vector(FIBERPORT_NUM*ETHPORT_NUM*8-1 downto 0);
    
    crc_info            : in std_logic_vector(7 downto 0);
    err_num_fiber       : in std_logic_vector(63 downto 0);
    err_num             : in std_logic_vector(63 downto 0);

	backup_flag_sys      : in std_logic_vector(3 downto 0);		
	error_check_num_sys     : in std_logic_vector(4*16-1 downto 0);
	subbrdin_packet_cnt_sys : in std_logic_vector(4*32-1 downto 0);
	error_fe_num_sys        : in std_logic_vector(4*16-1 downto 0);
	serdes_rxlock           : in std_logic_vector(3 downto 0);
	real_eth_num_sys		: in std_logic_vector(3 downto 0);
	ddr_verify_end_sys       : in std_logic_vector(DDR_NUM-1 downto 0);
	ddr_verify_success_sys   : in std_logic_vector(DDR_NUM-1 downto 0)
);
end component;

begin

uart_param_inst: uart_param
generic map
(
    TXSUBCARD_TYPE  => TXSUBCARD_TYPE,
    BAUD_DIV        => BAUD_DIV,
    HSSI_NUM        => FIBERPORT_NUM
)
port map
(
    nRST              => nRST  ,
    sysclk            => sysclk,
	time_ms_en			=> time_ms_en_sys ,
	---to reduce the clock domain in HDMI region 
	nRST_cmd          => nRST_cmd,
	cmd_clk           => cmd_clk ,

	serdes_frame_ss		=> serdes_frame_ss,
	serdes_rx_vld		=> serdes_rx_vld,
	serdes_rx_data		=> serdes_rx_data,
	para_serdes_lock	=> serdes_rxlock(4),			-- para channel

    p_Frame_en_cmd    => p_Frame_en_cmd ,
    p_Wren_cmd        => p_Wren_cmd     ,
    p_Data_cmd        => p_Data_cmd     ,
    p_Addr_cmd        => p_Addr_cmd     ,    
    cur_slot_num_cmd  => cur_slot_num_cmd ,
	
    ---uart: 2 pins of uart
    rxd_top             => rxd_top,
    txd_top             => txd_top,

    p_Frame_en_o        => p_Frame_en_o,
    p_Wren_o            => p_Wren_o    ,
    p_Data_o            => p_Data_o    ,
    p_Addr_o            => p_Addr_o    ,
    cur_slot_num        => cur_slot_num,

	Up_cmd_fifo_empty  => Up_cmd_fifo_empty_sys ,
	Up_cmd_fifo_rden   => Up_cmd_fifo_rden_sys  ,
	Up_cmd_fifo_q      => Up_cmd_fifo_q_sys     ,
    Up_ReadAddr        => Up_ReadAddr_sys       ,
    Up_ReadData        => Up_ReadData_sys       

);

  --autobright_filter:for i in 0 to FIBERPORT_NUM-1 GENERATE 
      ab_cmb_i: autobright_upload  
       generic MAP(   
           ETH_PORT_NUM  =>ETHPORT_NUM*FIBERPORT_NUM,
           BAUD		     =>BAUD_DIV     
       ) 
       port map(
           sys_nRST                => nRST    , 
           sysclk                  => sysclk , 
           time_ms_en              => time_ms_en_sys ,
           autolight_en            => autobright_en ,----( (i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM),    
           autolight_val           => autobright_val,----( (i+1)*ETHPORT_NUM*8-1 downto i*ETHPORT_NUM*8),    
           autolight_tx            => txd_autolight ,
           tx_autolight_val        =>tx_autolight_val,---( (i+1)*ETHPORT_NUM*8-1 downto i*ETHPORT_NUM*8),
           tx_autolight_vld        =>tx_autolight_vld ---( (i+1)*ETHPORT_NUM-1 downto i*ETHPORT_NUM)
       
       ); 
 --- END generate autobright_filter;

info_up : uart_info
generic map
(
    CONS_VER_HIGH       => CONS_VER_HIGH,
    CONS_VER_LOW        => CONS_VER_LOW,
    TXSUBCARD_TYPE      => TXSUBCARD_TYPE,
    FIBERPORT_NUM       => FIBERPORT_NUM,
    ETHPORT_NUM         => ETHPORT_NUM,
    SERDES_SPEED_MSB    => SERDES_SPEED_MSB,
    SERDES_SPEED_LSB    => SERDES_SPEED_LSB,
    BAUD_DIV            => BAUD_DIV,
	DDR_NUM             => DDR_NUM
)
port map
(
    nRST                => nRST,
    sysclk              => sysclk,
	time_ms_en_sys      => time_ms_en_sys ,
    txd_info_top        => txd_info_top,
    eth_link            => eth_link,
    fiber_link          => fiber_link,
	
	get_curr_temp_phy_sys => get_curr_temp_phy_sys ,
    
    autobright_en       => tx_autolight_vld  ,
    autobright_val      => tx_autolight_val ,
  

    err_num             => err_num,
    err_num_fiber       => err_num_fiber,
    crc_info            => crc_info,
	
	backup_flag_sys      => backup_flag_sys ,
	error_check_num_sys     => error_check_num_sys       ,
	subbrdin_packet_cnt_sys => subbrdin_packet_cnt_sys   ,
	error_fe_num_sys        => error_fe_num_sys          ,
	serdes_rxlock           => serdes_rxlock(3 downto 0)      ,
	real_eth_num_sys		=> real_eth_num_sys,
	ddr_verify_end_sys      => ddr_verify_end_sys,
	ddr_verify_success_sys  => ddr_verify_success_sys
);

end beha;