library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity serdes_dataout is
generic
(
    HSSI_NUM : integer := 2
);
port
(
    reconfclk                   : in std_logic;
    refclk                      : in std_logic;
    tx_serial_sfpdata           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_serial_sfpdata           : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');

    sfp_txclk                  : out std_logic;
    xgmii_tx_data               : in  std_logic_vector(HSSI_NUM*64-1 downto 0)  := (others => 'X');
    xgmii_tx_ctrl               : in  std_logic_vector(HSSI_NUM*8-1 downto 0)   := (others => 'X');

    sfp_rxclk                  : out std_logic_vector(HSSI_NUM-1 downto 0);
    xgmii_rx_data               : out std_logic_vector(HSSI_NUM*64-1 downto 0);
    xgmii_rx_ctrl               : out std_logic_vector(HSSI_NUM*8-1 downto 0);

    tx_enh_data_valid           : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');
    tx_enh_fifo_full            : out std_logic_vector(HSSI_NUM-1 downto 0);
    tx_enh_fifo_pfull           : out std_logic_vector(HSSI_NUM-1 downto 0);
    tx_enh_fifo_empty           : out std_logic_vector(HSSI_NUM-1 downto 0);
    tx_enh_fifo_pempty          : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_data_valid           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_full            : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_empty           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_del             : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_insert          : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_highber              : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_blk_lock             : out std_logic_vector(HSSI_NUM-1 downto 0);

    phy_reset                   : in std_logic
);
end serdes_dataout;

architecture behaviour of serdes_dataout is

component serdes_atx is
port (
	pll_powerdown   : in  std_logic := 'X'; -- pll_powerdown
	pll_refclk0     : in  std_logic := 'X'; -- clk
	tx_serial_clk   : out std_logic;        -- clk
	pll_locked      : out std_logic;        -- pll_locked
	pll_cal_busy    : out std_logic   ;     -- pll_cal_busy
	reconfig_clk0     : in std_logic;           
	reconfig_reset0   : in std_logic;           
	reconfig_write0   : in std_logic;           
	reconfig_read0    : in std_logic;           
	reconfig_address0 : in std_logic_vector(9 downto 0);          
	reconfig_writedata0  : in std_logic_vector(31 downto 0);       
	reconfig_readdata0   : out std_logic_vector(31 downto 0);     
	reconfig_waitrequest0: out std_logic 
	-- mcgb_rst        : in  std_logic := 'X'; -- mcgb_rst
	-- mcgb_serial_clk : out std_logic         -- clk
);
end component serdes_atx;



signal tx_serial_clk : std_logic;

component serdes_ip is
port (
	tx_analogreset          : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- tx_analogreset
	tx_digitalreset         : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- tx_digitalreset
	rx_analogreset          : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_analogreset
	rx_digitalreset         : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_digitalreset
	tx_cal_busy             : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_cal_busy
	rx_cal_busy             : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_cal_busy
	tx_serial_clk0          : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
	rx_cdr_refclk0          : in  std_logic                      := 'X';             -- clk
	tx_serial_data          : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_serial_data
	rx_serial_data          : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_serial_data
	rx_is_lockedtoref       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_is_lockedtoref
	rx_is_lockedtodata      : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_is_lockedtodata
	tx_coreclkin            : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
	rx_coreclkin            : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
	tx_clkout               : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
	rx_clkout               : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
	tx_pma_div_clkout       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
	rx_pma_div_clkout       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
	tx_parallel_data        : in  std_logic_vector(HSSI_NUM*64-1 downto 0) := (others => 'X'); -- tx_parallel_data
	tx_control              : in  std_logic_vector(HSSI_NUM*8-1 downto 0)  := (others => 'X'); -- tx_control
	tx_err_ins              : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- tx_err_ins
	unused_tx_parallel_data : in  std_logic_vector(127 downto 0) := (others => 'X'); -- unused_tx_parallel_data
	unused_tx_control       : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- unused_tx_control
	rx_parallel_data        : out std_logic_vector(HSSI_NUM*64-1 downto 0);                    -- rx_parallel_data
	rx_control              : out std_logic_vector(HSSI_NUM*8-1 downto 0);                     -- rx_control
	unused_rx_parallel_data : out std_logic_vector(127 downto 0);                    -- unused_rx_parallel_data
	unused_rx_control       : out std_logic_vector(23 downto 0);                     -- unused_rx_control
	tx_enh_data_valid       : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- tx_enh_data_valid
	tx_enh_fifo_full        : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
	tx_enh_fifo_pfull       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pfull
	tx_enh_fifo_empty       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_empty
	tx_enh_fifo_pempty      : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pempty
	rx_enh_data_valid       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_data_valid
	rx_enh_fifo_full        : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_full
	rx_enh_fifo_empty       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_empty
	rx_enh_fifo_del         : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_del
	rx_enh_fifo_insert      : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_insert
	rx_enh_highber          : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_highber
	rx_enh_blk_lock         : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_blk_lock
	reconfig_clk            : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
	reconfig_reset          : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- reset
	reconfig_write          : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- write
	reconfig_read           : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- read
	reconfig_address        : in  std_logic_vector(10 downto 0)  := (others => 'X'); -- address
	reconfig_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
	reconfig_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
	reconfig_waitrequest    : out std_logic_vector(0 downto 0)                       -- waitrequest
);
end component serdes_ip;

signal tx_coreclkin            : std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
signal rx_coreclkin            : std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
signal tx_clkout               : std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
signal rx_clkout               : std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
signal rx_is_lockedtoref       : std_logic_vector(HSSI_NUM-1 downto 0);
signal tx_err_ins              : std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');
signal tx_pma_clkout           : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_pma_clkout           : std_logic_vector(HSSI_NUM-1 downto 0);

signal reconfig_clk            :   std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
signal reconfig_reset          :   std_logic_vector(0 downto 0)   := (others => 'X'); -- reset
signal reconfig_write          :   std_logic_vector(0 downto 0)   := (others => 'X'); -- write
signal reconfig_read           :   std_logic_vector(0 downto 0)   := (others => 'X'); -- read
signal reconfig_address        :   std_logic_vector(10 downto 0)  := (others => 'X'); -- address
signal reconfig_writedata      :   std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
signal reconfig_readdata       :   std_logic_vector(31 downto 0);                     -- readdata
signal reconfig_waitrequest    :   std_logic_vector(0 downto 0);

component serdes_reset is
port (
	clock              : in  std_logic                    := 'X';             -- clk
	reset              : in  std_logic                    := 'X';             -- reset
	pll_powerdown      : out std_logic_vector(0 downto 0);                    -- pll_powerdown
	tx_analogreset     : out std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_analogreset
	tx_digitalreset    : out std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_digitalreset
	tx_ready           : out std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_ready
	pll_locked         : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_locked
	pll_select         : in  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- pll_select
	tx_cal_busy        : in  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- tx_cal_busy
	pll_cal_busy       : in  std_logic_vector(0 downto 0) := (others => 'X'); -- pll_cal_busy
	rx_analogreset     : out std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_analogreset
	rx_digitalreset    : out std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_digitalreset
	rx_ready           : out std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_ready
	rx_is_lockedtodata : in  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- rx_is_lockedtodata
	rx_cal_busy        : in  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X')  -- rx_cal_busy
);
end component serdes_reset;

signal 	pll_powerdown       : std_logic_vector(0 downto 0);
signal 	pll_cal_busy        : std_logic_vector(0 downto 0);
signal 	pll_locked          : std_logic_vector(0 downto 0);
signal 	pll_select          : std_logic_vector(HSSI_NUM-1 downto 0);

signal tx_analogreset       : std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_analogreset
signal tx_digitalreset      : std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_digitalreset
signal tx_ready             : std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_ready
signal tx_cal_busy          : std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- tx_cal_busy
signal rx_analogreset       : std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_analogreset
signal rx_digitalreset      : std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_digitalreset
signal rx_ready             : std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_ready
signal rx_is_lockedtodata   : std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- rx_is_lockedtodata
signal rx_cal_busy          : std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X') ; -- rx_cal_busy
signal tx_serial_clk0       : std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- clk


component pma2_recalib is 
generic (
         CH_NUMMAX : integer:= 4 ;
         CH_W      : integer:= 2 ;
         A_W : integer := 12;
         D_W : integer := 32
    );
port 
(
   reset                : in std_logic ;
   clk                  : in std_logic ;
   pll_powerdown_i        : in std_logic ;
   tx_cal_busy      : in std_logic_vector(CH_NUMMAX-1 downto 0) ;
   rx_cal_busy      : in std_logic_vector(CH_NUMMAX-1 downto 0) ;
 --// TX PLL reconfig controller interface
   mgmt_address      :out std_logic_vector(A_W-1 downto 0) ;---output wire [9:0] ,
   mgmt_writedata    :out std_logic_vector(D_W-1 downto 0) ;---output wire [31:0],
   mgmt_readdata     :in  std_logic_vector(D_W -1 downto 0) ;---input  wire [31:0],
   mgmt_write        :out std_logic  ;---output wire       ,
   mgmt_read         :out std_logic  ;---output wire       ,
   mgmt_waitrequest  : in std_logic  ; ----_vector(CH_NUMMAX-1 downto 0)  ;----input  wire       
   cali_done_o       : out std_logic ;
   begin_en          : in std_logic 


  );
end component ;

signal pma_reconfig_clk            :   std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
signal pma_reconfig_reset          :   std_logic_vector(0 downto 0)   := (others => 'X'); -- reset
signal pma_reconfig_write          :   std_logic_vector(0 downto 0)   := (others => 'X'); -- write
signal pma_reconfig_read           :   std_logic_vector(0 downto 0)   := (others => 'X'); -- read
signal pma_reconfig_address        :   std_logic_vector(10 downto 0)  := (others => 'X'); -- address
signal pma_reconfig_writedata      :   std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
signal pma_reconfig_readdata       :   std_logic_vector(31 downto 0);                     -- readdata
signal pma_reconfig_waitrequest    :   std_logic_vector(0 downto 0)  ;

component atxpll_recalib is 
port 
(
   reset                 : in std_logic ;
   clk                  : in std_logic ;
   begin_en                  : in std_logic ;

   tx_pll_cal_busy      : in std_logic ;
   ---pll_powerdown        : in std_logic ;
   pll_powerdown_i        : in std_logic ;
      trigger_serdes_fortst  : in std_logic ;
 --// TX PLL reconfig controller interface
   txpll_mgmt_address    :out std_logic_vector(9 downto 0) ;---output wire [9:0] ,
   txpll_mgmt_writedata  :out std_logic_vector(31 downto 0) ;---output wire [31:0],
   txpll_mgmt_readdata   :in  std_logic_vector(31 downto 0) ;---input  wire [31:0],
   txpll_mgmt_write       :out std_logic  ;---output wire mt_write      :out std_logic  ;---output wire       ,
   txpll_mgmt_read       :out std_logic  ;---output wire       ,
   txpll_mgmt_waitrequest: in std_logic  ; ----input  wire       
   cali_done_o           :out std_logic   ---output wire 
  );
end  component ;

signal   tx_pll_powerdown        :   std_logic ;
 --// TX PLL reconfig controller interface
signal   tx_pll_mgmt_address    :  std_logic_vector(9 downto 0) ;---output wire [9:0] ,
signal   tx_pll_mgmt_writedata  :  std_logic_vector(31 downto 0) ;---output wire [31:0],
signal   tx_pll_mgmt_readdata   :  std_logic_vector(31 downto 0) ;---input  wire [31:0],
signal   tx_pll_mgmt_write      :   std_logic  ;---output wire mt_write      :out std_logic  ;---output wire       ,
signal   tx_pll_mgmt_read       :  std_logic  ;---output wire       ,
signal   tx_pll_mgmt_waitrequest:  std_logic  ; ----input  wire       
signal   tx_pll_cali_done       :  std_logic  ; ---output wire 
signal   tx_pll_cal_busy        :  std_logic ;
signal   serdes_phy_reset       :  std_logic ;
signal   pma_cali_done : std_logic ;
signal   pma_cali_done_buf : std_logic_vector(3 downto 0):=(others=>'0');
signal   reset : std_logic:='0';
signal pma_powerdown : std_logic:='0';

begin

pll_select <= (others=>'0');
tx_err_ins <= (others=>'0');

serdes_atx_inst : serdes_atx
port map
(
	pll_powerdown   => pll_powerdown(0),        -- pll_powerdown
	pll_refclk0     => refclk,        -- clk
	tx_serial_clk   => tx_serial_clk,        -- clk
	pll_locked      => pll_locked(0),        -- pll_locked
	pll_cal_busy    => pll_cal_busy(0) ,       -- pll_cal_busy
	reconfig_clk0            => reconfclk,
	reconfig_reset0          => phy_reset,
	reconfig_write0          => tx_pll_mgmt_write,
	reconfig_read0           => tx_pll_mgmt_read,
	reconfig_address0        => tx_pll_mgmt_address,  
	reconfig_writedata0      => tx_pll_mgmt_writedata,
	reconfig_readdata0       => tx_pll_mgmt_readdata,
	reconfig_waitrequest0    => tx_pll_mgmt_waitrequest

);
tx_pll_powerdown <= pll_powerdown(0);
tx_pll_cal_busy  <= pll_cal_busy(0) ;

atxpll_recon: atxpll_recalib 
port map
(
   reset                    => phy_reset,
   clk                      => reconfclk,
   begin_en                 => '1',
                            
   tx_pll_cal_busy          => tx_pll_cal_busy,
   
   pll_powerdown_i          => tx_pll_powerdown,
 --// TX PLL reconfig contro=> 
   txpll_mgmt_address       =>  tx_pll_mgmt_address       ,
   txpll_mgmt_writedata     =>  tx_pll_mgmt_writedata     ,
   txpll_mgmt_readdata      =>  tx_pll_mgmt_readdata      ,
   txpll_mgmt_write         =>  tx_pll_mgmt_write         ,
   txpll_mgmt_read          =>  tx_pll_mgmt_read          ,
   txpll_mgmt_waitrequest   =>  tx_pll_mgmt_waitrequest   ,
   cali_done_o              =>  tx_pll_cali_done           ,
   	trigger_serdes_fortst   => '0'----trigger_serdes_fortst 
  );

serdes_phy_reset <= phy_reset or reset ;
  
serdes_reset_inst : serdes_reset
port map
(
	clock              => reconfclk,        -- clk
	reset              => serdes_phy_reset,        -- reset
	pll_powerdown      => pll_powerdown,             -- pll_powerdown
	tx_analogreset     => tx_analogreset,            -- tx_analogreset
	tx_digitalreset    => tx_digitalreset,           -- tx_digitalreset
	tx_ready           => tx_ready,                  -- tx_ready
	pll_locked         => pll_locked,                -- pll_locked
	pll_select         => pll_select,                -- pll_select
	tx_cal_busy        => tx_cal_busy,               -- tx_cal_busy
	pll_cal_busy       => pll_cal_busy,              -- pll_cal_busy
	rx_analogreset     => rx_analogreset,            -- rx_analogreset
	rx_digitalreset    => rx_digitalreset,           -- rx_digitalreset
	rx_ready           => rx_ready,                  -- rx_ready
	rx_is_lockedtodata => rx_is_lockedtodata,        -- rx_is_lockedtodata
	rx_cal_busy        => rx_cal_busy               -- rx_cal_busy
);

sfp_txclk <= tx_coreclkin(0);
process(tx_pma_clkout(0))begin
    for i in 0 to HSSI_NUM-1 LOOP
        tx_coreclkin(i) <= tx_pma_clkout(0);
    END LOOP;
end process;

sfp_rxclk <= rx_coreclkin;
rx_coreclkin <= rx_pma_clkout;

process(tx_serial_clk)begin
    for i in 0 to HSSI_NUM-1 LOOP
        tx_serial_clk0(i)<= tx_serial_clk;
    END LOOP;
end process;

pma_powerdown <= pll_powerdown(0);
    pma_recali_i: pma2_recalib   
    generic map(
             CH_NUMMAX => HSSI_NUM ,
             CH_W      => 1 , --- 4 channel
             A_W       => 11 ,
             D_W       => 32 
        )
    port  map
    (
       reset               => phy_reset ,
       clk                 => reconfclk   ,
       pll_powerdown_i     => pma_powerdown ,
       tx_cal_busy         => tx_cal_busy ,
       rx_cal_busy         => rx_cal_busy,---(OTHERS=>'0') ,
     --// TX PLL reconfig controller interface
       mgmt_address      => pma_reconfig_address,--output wire [9:0] ,
       mgmt_writedata    => pma_reconfig_writedata ,--output wire [31:0],
       mgmt_readdata     => pma_reconfig_readdata,---input  wire [31:0],
       mgmt_write        => pma_reconfig_write(0) ,
       mgmt_read         => pma_reconfig_read(0) , ---output wire       ,
       mgmt_waitrequest  => pma_reconfig_waitrequest(0) , ----_vector(CH_NUMMAX-1 downto 0)  ;----input  wire       
       cali_done_o       => pma_cali_done ,
       begin_en          => tx_pll_cali_done
      );	
process(reconfclk)
begin
	if rising_edge(reconfclk) then
	    pma_cali_done_buf <= pma_cali_done_buf(2 downto 0)&pma_cali_done;
		if pma_cali_done_buf="0001" or pma_cali_done_buf ="0011"or pma_cali_done_buf ="0111" then
			reset <= '1';
		else
			reset <= '0';
		end if;
	end if;
end process;	  
	  

serdes_ip_inst : serdes_ip
port map
(
	tx_analogreset          => tx_analogreset,                  -- tx_analogreset
	tx_digitalreset         => tx_digitalreset,                 -- tx_digitalreset
	rx_analogreset          => rx_analogreset,                  -- rx_analogreset
	rx_digitalreset         => rx_digitalreset,                 -- rx_digitalreset
	tx_cal_busy             => tx_cal_busy,                     -- tx_cal_busy
	rx_cal_busy             => rx_cal_busy,                     -- rx_cal_busy
	tx_serial_clk0          => tx_serial_clk0,                  -- clk
	rx_cdr_refclk0          => refclk,                  -- clk
	tx_serial_data          => tx_serial_sfpdata,                  -- tx_serial_data
	rx_serial_data          => rx_serial_sfpdata,                  -- rx_serial_data
	rx_is_lockedtoref       => rx_is_lockedtoref,               -- rx_is_lockedtoref
	rx_is_lockedtodata      => rx_is_lockedtodata,              -- rx_is_lockedtodata
	tx_coreclkin            => tx_coreclkin,                    -- clk
	rx_coreclkin            => rx_coreclkin,                    -- clk
	tx_clkout               => tx_clkout,                       -- clk
	rx_clkout               => rx_clkout,                       -- clk
	tx_pma_div_clkout       => tx_pma_clkout,               -- clk
	rx_pma_div_clkout       => rx_pma_clkout,               -- clk
	tx_parallel_data        => xgmii_tx_data,                -- tx_parallel_data
	tx_control              => xgmii_tx_ctrl,                      -- tx_control
	tx_err_ins              => tx_err_ins,                      -- tx_err_ins
	unused_tx_parallel_data => (others => '0'),         -- unused_tx_parallel_data
	unused_tx_control       => (others => '0'),               -- unused_tx_control
	rx_parallel_data        => xgmii_rx_data,                -- rx_parallel_data
	rx_control              => xgmii_rx_ctrl,                      -- rx_control
	unused_rx_parallel_data => open,         -- unused_rx_parallel_data
	unused_rx_control       => open,               -- unused_rx_control

    tx_enh_data_valid       => tx_enh_data_valid,          -- tx_enh_data_valid
	tx_enh_fifo_full        => tx_enh_fifo_full,           -- tx_enh_fifo_full
	tx_enh_fifo_pfull       => tx_enh_fifo_pfull,          -- tx_enh_fifo_pfull
	tx_enh_fifo_empty       => tx_enh_fifo_empty,          -- tx_enh_fifo_empty
	tx_enh_fifo_pempty      => tx_enh_fifo_pempty,         -- tx_enh_fifo_pempty
	rx_enh_data_valid       => rx_enh_data_valid,          -- rx_enh_data_valid
	rx_enh_fifo_full        => rx_enh_fifo_full,           -- rx_enh_fifo_full
	rx_enh_fifo_empty       => rx_enh_fifo_empty,          -- rx_enh_fifo_empty
	rx_enh_fifo_del         => rx_enh_fifo_del,            -- rx_enh_fifo_del
	rx_enh_fifo_insert      => rx_enh_fifo_insert,         -- rx_enh_fifo_insert
	rx_enh_highber          => rx_enh_highber,             -- rx_enh_highber
	rx_enh_blk_lock         => rx_enh_blk_lock,            -- rx_enh_blk_lock

    reconfig_clk            => reconfig_clk,         -- clk
	reconfig_reset          => reconfig_reset,         -- reset
	reconfig_write          => pma_reconfig_write,         -- write
	reconfig_read           => pma_reconfig_read,         -- read
	reconfig_address        => pma_reconfig_address,             -- address
	reconfig_writedata      => pma_reconfig_writedata,           -- writedata
	reconfig_readdata       => pma_reconfig_readdata,            -- readdata
	reconfig_waitrequest    => pma_reconfig_waitrequest         -- waitrequest
);

reconfig_clk(0) <= reconfclk;
reconfig_reset(0) <= phy_reset;

end;