library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Z8_boardout is
generic
(
    HSSI_NUM : integer := 2
);
port 
(
    CLKUSR                      : in std_logic;
    clkin_156M                  : in std_logic;
    
    rx_serial_data              : in std_logic_vector(HSSI_NUM-1 downto 0)  := (others => 'X');
    
    tx_serial_sfpdata           : out std_logic_vector(HSSI_NUM-1 downto 0);                      
    rx_serial_sfpdata           : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X')
    
);
end Z8_boardout;

architecture behaviour of Z8_boardout is

component main_pll is
port (
	rst      : in  std_logic := 'X'; -- reset
	refclk   : in  std_logic := 'X'; -- clk
	locked   : out std_logic;        -- export
	outclk_0 : out std_logic         -- clk
);
end component main_pll;

signal RST              : std_logic;
signal rst_cnt          : std_logic_vector(9 downto 0) := (others=>'0');
signal main_pll_locked  : std_logic;
signal sysclk           : std_logic := '0';

component resetmodule is
generic 
( 
    HSSI_NUM : integer
);
port
(
    sysclk              : in std_logic;
    tx_clk              : in std_logic;
    rx_clk              : in std_logic_vector(HSSI_NUM-1 downto 0);
    pll_lock            : in std_logic;

    nRST_sys            : out std_logic;
    RST_sys             : out std_logic;
    nRST_rxclk          : out std_logic_vector(HSSI_NUM-1 downto 0);
    nRST_txclk          : out std_logic
);
end component;

signal nRST_sys            : std_logic;
signal RST_sys             : std_logic;
signal nRST_rxclk          : std_logic_vector(HSSI_NUM-1 downto 0);
signal nRST_sfptxclk       : std_logic;

constant CLK_NUM : integer:=10;

component multi_measure is 
generic 
(  
    CLK_NUM : integer := 10 
);
port 
(
    sysclk     : in  std_logic ;  --125M 
    nRST_sys   : in  std_logic ;
    clk_set    : in  std_logic_vector(CLK_NUM-1 downto 0);
    mask_out   : out std_logic := '0';
    clk_cnt    : out std_logic_vector(CLK_NUM*32-1 downto 0) 
 
);
end component;

signal clk_set          : std_logic_vector(CLK_NUM-1 downto 0);

component serdes_datain is
generic
(
    HSSI_NUM : integer := 2
);
port 
(
    reconfclk                   : in std_logic;
    refclk                      : in std_logic;
    rx_serial_data              : in std_logic_vector(HSSI_NUM-1 downto 0)  := (others => 'X');
    
    rx_clk                      : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_parallel_data            : out std_logic_vector(HSSI_NUM*64-1 downto 0);
    rx_control                  : out std_logic_vector(HSSI_NUM*8-1 downto 0);
    
    rx_enh_data_valid           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_full            : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_empty           : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_del             : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_fifo_insert          : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_highber              : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_enh_blk_lock             : out std_logic_vector(HSSI_NUM-1 downto 0);       
    
    phy_reset                   : in std_logic  
);
end component;

signal rx_clk                  :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_parallel_data        :   std_logic_vector(HSSI_NUM*64-1 downto 0);
signal rx_control              :   std_logic_vector(HSSI_NUM*8-1 downto 0);

signal rx_enh_data_valid       :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_full        :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_empty       :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_del         :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_insert      :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_highber          :   std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_blk_lock         :   std_logic_vector(HSSI_NUM-1 downto 0);      

component serdes_dataout is
generic
(
    HSSI_NUM : integer := 2
);
port 
(
    reconfclk                   : in std_logic;
    refclk                      : in std_logic;  
    tx_serial_sfpdata           : out std_logic_vector(HSSI_NUM-1 downto 0);                      
    rx_serial_sfpdata          : in std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');

    sfp_txclk                   : out std_logic_vector(HSSI_NUM-1 downto 0);
    xgmii_tx_data               : in std_logic_vector(HSSI_NUM*64-1 downto 0)  := (others => 'X');
    xgmii_tx_ctrl               : in std_logic_vector(HSSI_NUM*8-1 downto 0)   := (others => 'X');

    sfp_rxclk                   : out std_logic_vector(HSSI_NUM-1 downto 0);
    xgmii_rx_data               : out std_logic_vector(HSSI_NUM*64-1 downto 0);                    
    xgmii_rx_ctrl               : out std_logic_vector(HSSI_NUM*8-1 downto 0);                     
    
    tx_enh_data_valid           : in std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');
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
end component;

signal sfp_txclk                   : std_logic_vector(HSSI_NUM-1 downto 0);
signal xgmii_tx_data               : std_logic_vector(HSSI_NUM*64-1 downto 0);
signal xgmii_tx_ctrl               : std_logic_vector(HSSI_NUM*8-1 downto 0);
signal sfp_rxclk                   : std_logic_vector(HSSI_NUM-1 downto 0);
signal xgmii_rx_data               : std_logic_vector(HSSI_NUM*64-1 downto 0);                    
signal xgmii_rx_ctrl               : std_logic_vector(HSSI_NUM*8-1 downto 0);                     

signal tx_enh_data_valid_sfp       : std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X');
signal tx_enh_fifo_full_sfp        : std_logic_vector(HSSI_NUM-1 downto 0);
signal tx_enh_fifo_pfull_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal tx_enh_fifo_empty_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal tx_enh_fifo_pempty_sfp      : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_data_valid_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_full_sfp        : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_empty_sfp       : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_del_sfp         : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_fifo_insert_sfp      : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_highber_sfp          : std_logic_vector(HSSI_NUM-1 downto 0);
signal rx_enh_blk_lock_sfp         : std_logic_vector(HSSI_NUM-1 downto 0);

component convto_xgmii_sfp is
port 
(
    nRST_rxclk                      : in std_logic; 
    rx_clk                          : in std_logic;
    rx_parallel_data                : in std_logic_vector(63 downto 0);
    rx_control                      : in std_logic_vector(7 downto 0);
    
    nRST_txclk                      : in std_logic;
    tx_clk                          : in std_logic;
    xgmii_tx_data                   : out std_logic_vector(63 downto 0);
    xgmii_tx_ctrl                   : out std_logic_vector(7 downto 0)
);
end component;

component test_harness is
generic
(
	HSSI_NUM    : integer:= 24
);
port(
	reset					: in  std_logic;
    
    tx_clk_156m				: in  std_logic_vector(HSSI_NUM-1 downto 0);
	xgmii_tx_d 				: out std_logic_vector(64*HSSI_NUM-1 downto 0);
	xgmii_tx_c				: out std_logic_vector(8*HSSI_NUM-1 downto 0);

    tx_enh_data_valid       : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
    tx_enh_fifo_full        : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_full
    tx_enh_fifo_pfull       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pfull
    tx_enh_fifo_empty       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_empty
    tx_enh_fifo_pempty      : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_enh_fifo_pempty
    rx_enh_data_valid       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_data_valid
    rx_enh_fifo_full        : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_full
    rx_enh_fifo_empty       : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_empty
    rx_enh_fifo_del         : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_del
    rx_enh_fifo_insert      : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_fifo_insert
    rx_enh_highber          : in  std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_enh_highber
    rx_enh_blk_lock         : in  std_logic_vector(HSSI_NUM-1 downto 0);     
    
    rx_clk_156m			    : in  std_logic_vector(HSSI_NUM-1 downto 0);	
    xgmii_rx_d 				: in  std_logic_vector(64*HSSI_NUM-1 downto 0);
	xgmii_rx_c				: in  std_logic_vector(8*HSSI_NUM-1 downto 0);

	led						: out std_logic;					--status
	status					: out std_logic_vector(HSSI_NUM-1 downto 0)
);
end component;

begin

process(clkin_156M)
begin
    if rising_edge(clkin_156M) then
        if rst_cnt(9) = '0' then
            rst_cnt <= rst_cnt + '1';
        end if;      
    end if;              
end process;
RST <= not rst_cnt(9);

main_pll_inst : main_pll
port map
(
	rst      => RST,        -- reset
	refclk   => clkin_156M,        -- clk
	locked   => main_pll_locked,        -- export
	outclk_0 => sysclk        -- clk
);

resetmodule_inst : resetmodule
generic map 
( 
    HSSI_NUM => HSSI_NUM
)
port map
(
    sysclk              => sysclk,
    tx_clk              => sfp_txclk(0),
    rx_clk              => rx_clk,
    pll_lock            => main_pll_locked,

    nRST_sys            => nRST_sys,     
    RST_sys             => RST_sys,      
    nRST_rxclk          => nRST_rxclk,   
    nRST_txclk          => nRST_sfptxclk
);

clk_set <= sysclk&clkin_156M&rx_clk(0)&rx_clk(1)&sfp_txclk(0)&sfp_rxclk(0)&sfp_rxclk(0)&CLKUSR&CLKUSR&CLKUSR;

multi_measure_inst : multi_measure 
generic map 
(  
    CLK_NUM => CLK_NUM
)
port map
(
    sysclk     => sysclk,
    nRST_sys   => nRST_sys,
    clk_set    => clk_set,
    mask_out   => open,
    clk_cnt    => open 
 
);

-- serdes_datain_inst : serdes_datain
-- generic map
-- (
    -- HSSI_NUM => HSSI_NUM
-- )
-- port map
-- (
    -- reconfclk                   => sysclk,
    -- refclk                      => clkin_156M,
    -- rx_serial_data              => rx_serial_data,

    -- rx_clk                      => rx_clk,          
    -- rx_parallel_data            => rx_parallel_data,
    -- rx_control                  => rx_control,      

    -- rx_enh_data_valid           => rx_enh_data_valid, 
    -- rx_enh_fifo_full            => rx_enh_fifo_full,  
    -- rx_enh_fifo_empty           => rx_enh_fifo_empty, 
    -- rx_enh_fifo_del             => rx_enh_fifo_del,   
    -- rx_enh_fifo_insert          => rx_enh_fifo_insert,
    -- rx_enh_highber              => rx_enh_highber,    
    -- rx_enh_blk_lock             => rx_enh_blk_lock,   

    -- phy_reset                   => RST_sys
-- );

serdes_dataout_inst : serdes_dataout
generic map
(
    HSSI_NUM => HSSI_NUM
)
port map
(
    reconfclk                   => sysclk,
    refclk                      => clkin_156M,
    tx_serial_sfpdata           => tx_serial_sfpdata,
    rx_serial_sfpdata           => rx_serial_sfpdata,

    sfp_txclk                  => sfp_txclk,
    xgmii_tx_data               => xgmii_tx_data,
    xgmii_tx_ctrl               => xgmii_tx_ctrl,

    sfp_rxclk                  => sfp_rxclk,   
    xgmii_rx_data               => xgmii_rx_data,
    xgmii_rx_ctrl               => xgmii_rx_ctrl,

    tx_enh_data_valid           => tx_enh_data_valid_sfp, 
    tx_enh_fifo_full            => tx_enh_fifo_full_sfp,  
    tx_enh_fifo_pfull           => tx_enh_fifo_pfull_sfp, 
    tx_enh_fifo_empty           => tx_enh_fifo_empty_sfp, 
    tx_enh_fifo_pempty          => tx_enh_fifo_pempty_sfp,
    rx_enh_data_valid           => rx_enh_data_valid_sfp, 
    rx_enh_fifo_full            => rx_enh_fifo_full_sfp, 
    rx_enh_fifo_empty           => rx_enh_fifo_empty_sfp, 
    rx_enh_fifo_del             => rx_enh_fifo_del_sfp,   
    rx_enh_fifo_insert          => rx_enh_fifo_insert_sfp,
    rx_enh_highber              => rx_enh_highber_sfp,    
    rx_enh_blk_lock             => rx_enh_blk_lock_sfp,   

    phy_reset                   => RST_sys
);

-- convto_xgmii_sfp_generate : for i in  0 to HSSI_NUM-1 generate
-- convto_xgmii_sfp_inst : convto_xgmii_sfp
-- port map
-- (
    -- nRST_rxclk                      => nRST_rxclk(i),
    -- rx_clk                          => rx_clk(i),
    -- rx_parallel_data                => rx_parallel_data(64*i+63 downto 64*i),
    -- rx_control                      => rx_control(8*i+7 downto 8*i),

    -- nRST_txclk                      => nRST_sfptxclk,
    -- tx_clk                          => sfp_txclk(0),
    -- xgmii_tx_data                   => xgmii_tx_data(64*i+63 downto 64*i),
    -- xgmii_tx_ctrl                   => xgmii_tx_ctrl(8*i+7 downto 8*i)
-- );
-- end generate convto_xgmii_sfp_generate;

test_harness_inst : test_harness
generic map
(
	HSSI_NUM    => HSSI_NUM
)
port map
(
	reset					=> RST,

    tx_clk_156m				=> sfp_txclk,
	xgmii_tx_d 				=> xgmii_tx_data,
	xgmii_tx_c				=> xgmii_tx_ctrl,

    tx_enh_data_valid       => tx_enh_data_valid_sfp,       -- tx_enh_fifo_full
    tx_enh_fifo_full        => tx_enh_fifo_full_sfp,        -- tx_enh_fifo_full
    tx_enh_fifo_pfull       => tx_enh_fifo_pfull_sfp,       -- tx_enh_fifo_pfull
    tx_enh_fifo_empty       => tx_enh_fifo_empty_sfp,       -- tx_enh_fifo_empty
    tx_enh_fifo_pempty      => tx_enh_fifo_pempty_sfp,      -- tx_enh_fifo_pempty
    rx_enh_data_valid       => rx_enh_data_valid_sfp,       -- rx_enh_data_valid
    rx_enh_fifo_full        => rx_enh_fifo_full_sfp,       -- rx_enh_fifo_full
    rx_enh_fifo_empty       => rx_enh_fifo_empty_sfp,       -- rx_enh_fifo_empty
    rx_enh_fifo_del         => rx_enh_fifo_del_sfp,         -- rx_enh_fifo_del
    rx_enh_fifo_insert      => rx_enh_fifo_insert_sfp,      -- rx_enh_fifo_insert
    rx_enh_highber          => rx_enh_highber_sfp,          -- rx_enh_highber
    rx_enh_blk_lock         => rx_enh_blk_lock_sfp,        

    rx_clk_156m			    => sfp_rxclk,
    xgmii_rx_d 				=> xgmii_rx_data,
	xgmii_rx_c				=> xgmii_rx_ctrl,

	led						=> open,
	status					=> open

);

end;
