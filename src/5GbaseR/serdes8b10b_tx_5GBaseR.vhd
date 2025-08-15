
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity serdes8b10b_tx_5GBaseR is
generic
(
    HSSI_NUM : integer := 4
);
port
(
    reconfclk                 : in std_logic;
    refclk_125              : in std_logic ;
    tx_serial_data          : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- tx_serial_data
    rx_serial_data          : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- rx_serial_data

    tx_parallel_data        : in  std_logic_vector(8*8*HSSI_NUM-1 downto 0)  := (others => 'X'); -- tx_parallel_data
    tx_control              : in  std_logic_vector(8*HSSI_NUM-1 downto 0)   := (others => 'X');
    tx_clk                  : out std_logic;

    rx_clk                  : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_parallel_data        : out std_logic_vector(HSSI_NUM*8*8-1 downto 0);                     -- rx_parallel_data
    rx_control              : out std_logic_vector(HSSI_NUM*8-1 downto 0);                      -- rx_datak

    rx_errdetect            : out std_logic_vector(HSSI_NUM-1 downto 0);
    rx_disperr              : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_disperr
    rx_runningdisp          : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_runningdisp
    rx_patterndetect        : out std_logic_vector(HSSI_NUM-1 downto 0);                      -- rx_patterndetect
    rx_rmfifostatus         : out std_logic_vector(2*HSSI_NUM-1 downto 0);                     -- rx_rmfifostatus
    tx_enh_data_valid       : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');
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
    rx_enh_blk_lock         : out std_logic_vector(HSSI_NUM-1 downto 0);

    phy_reset  : in std_logic

);
end serdes8b10b_tx_5GBaseR;

architecture beha of serdes8b10b_tx_5GBaseR is

component phyreset_5g is
port (
    clock               : in  std_logic := 'X'; -- clk
	reset               : in  std_logic := 'X'; -- reset
	pll_powerdown0      : out std_logic;        -- pll_powerdown
	tx_analogreset0     : out std_logic;        -- tx_analogreset
	tx_analogreset1     : out std_logic;        -- tx_analogreset
	tx_analogreset2     : out std_logic;        -- tx_analogreset
	tx_analogreset3     : out std_logic;        -- tx_analogreset
	tx_digitalreset0    : out std_logic;        -- tx_digitalreset
	tx_digitalreset1    : out std_logic;        -- tx_digitalreset
	tx_digitalreset2    : out std_logic;        -- tx_digitalreset
	tx_digitalreset3    : out std_logic;        -- tx_digitalreset
	tx_ready0           : out std_logic;        -- tx_ready
	tx_ready1           : out std_logic;        -- tx_ready
	tx_ready2           : out std_logic;        -- tx_ready
	tx_ready3           : out std_logic;        -- tx_ready
	pll_locked0         : in  std_logic := 'X'; -- pll_locked
	pll_select0         : in  std_logic := 'X'; -- pll_select
	pll_select1         : in  std_logic := 'X'; -- pll_select
	pll_select2         : in  std_logic := 'X'; -- pll_select
	pll_select3         : in  std_logic := 'X'; -- pll_select
	tx_cal_busy0        : in  std_logic := 'X'; -- tx_cal_busy
	tx_cal_busy1        : in  std_logic := 'X'; -- tx_cal_busy
	tx_cal_busy2        : in  std_logic := 'X'; -- tx_cal_busy
	tx_cal_busy3        : in  std_logic := 'X'; -- tx_cal_busy
	pll_cal_busy0       : in  std_logic := 'X'; -- pll_cal_busy
	rx_analogreset0     : out std_logic;        -- rx_analogreset
	rx_analogreset1     : out std_logic;        -- rx_analogreset
	rx_analogreset2     : out std_logic;        -- rx_analogreset
	rx_analogreset3     : out std_logic;        -- rx_analogreset
	rx_digitalreset0    : out std_logic;        -- rx_digitalreset
	rx_digitalreset1    : out std_logic;        -- rx_digitalreset
	rx_digitalreset2    : out std_logic;        -- rx_digitalreset
	rx_digitalreset3    : out std_logic;        -- rx_digitalreset
	rx_ready0           : out std_logic;        -- rx_ready
	rx_ready1           : out std_logic;        -- rx_ready
	rx_ready2           : out std_logic;        -- rx_ready
	rx_ready3           : out std_logic;        -- rx_ready
	rx_is_lockedtodata0 : in  std_logic := 'X'; -- rx_is_lockedtodata
	rx_is_lockedtodata1 : in  std_logic := 'X'; -- rx_is_lockedtodata
	rx_is_lockedtodata2 : in  std_logic := 'X'; -- rx_is_lockedtodata
	rx_is_lockedtodata3 : in  std_logic := 'X'; -- rx_is_lockedtodata
	rx_cal_busy0        : in  std_logic := 'X'; -- rx_cal_busy
	rx_cal_busy1        : in  std_logic := 'X'; -- rx_cal_busy
	rx_cal_busy2        : in  std_logic := 'X'; -- rx_cal_busy
	rx_cal_busy3        : in  std_logic := 'X'  -- rx_cal_busy
);
end component phyreset_5g;


signal 	pll_powerdown   :   std_logic_vector(0 downto 0);
signal 	pll_cal_busy    :   std_logic_vector(0 downto 0);
signal 	pll_locked      :   std_logic_vector(0 downto 0);
signal 	pll_select      :   std_logic_vector(HSSI_NUM-1 downto 0);

signal tx_analogreset     :  std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_analogreset
signal tx_digitalreset    :  std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_digitalreset
signal tx_ready           :  std_logic_vector(HSSI_NUM-1 downto 0);                    -- tx_ready
signal tx_cal_busy        :  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- tx_cal_busy
signal rx_analogreset     :  std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_analogreset
signal rx_digitalreset    :  std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_digitalreset
signal rx_ready           :  std_logic_vector(HSSI_NUM-1 downto 0);                    -- rx_ready
signal rx_is_lockedtodata :  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- rx_is_lockedtodata
signal rx_cal_busy        :  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X') ; -- rx_cal_busy
signal	tx_serial_clk0    :  std_logic_vector(HSSI_NUM-1 downto 0) := (others => 'X'); -- clk

component ip8b10b_5gbaseR is
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
	tx_parallel_data        : in  std_logic_vector(64*HSSI_NUM-1 downto 0) := (others => 'X'); -- tx_parallel_data
	tx_control              : in  std_logic_vector(8*HSSI_NUM-1 downto 0)  := (others => 'X'); -- tx_control
	tx_err_ins              : in  std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- tx_err_ins
	unused_tx_parallel_data : in  std_logic_vector(64*HSSI_NUM-1 downto 0) := (others => 'X'); -- unused_tx_parallel_data
	unused_tx_control       : in  std_logic_vector(9*HSSI_NUM-1 downto 0)  := (others => 'X'); -- unused_tx_control
	rx_parallel_data        : out std_logic_vector(64*HSSI_NUM-1 downto 0);                    -- rx_parallel_data
	rx_control              : out std_logic_vector(8*HSSI_NUM-1 downto 0);                     -- rx_control
	unused_rx_parallel_data : out std_logic_vector(64*HSSI_NUM-1 downto 0);                    -- unused_rx_parallel_data
	unused_rx_control       : out std_logic_vector(47 downto 0);                     -- unused_rx_control
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
	reconfig_address        : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- address
	reconfig_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
	reconfig_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
	reconfig_waitrequest    : out std_logic_vector(0 downto 0)
);
end component ip8b10b_5gbaseR;


signal reconfig_clk            :   std_logic_vector(0 downto 0)   := (others => 'X'); -- clk
signal reconfig_reset          :   std_logic_vector(0 downto 0)   := (others => 'X'); -- reset
signal reconfig_write          :   std_logic_vector(0 downto 0)   := (others => 'X'); -- write
signal reconfig_read           :   std_logic_vector(0 downto 0)   := (others => 'X'); -- read
signal reconfig_address        :   std_logic_vector(11 downto 0)  := (others => 'X'); -- address
signal reconfig_writedata      :   std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
signal reconfig_readdata       :   std_logic_vector(31 downto 0);                     -- readdata
signal reconfig_waitrequest    :   std_logic_vector(0 downto 0)  ;


signal tx_serial_clk: std_logic ;

signal tx_coreclkin            :    std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
signal rx_coreclkin            :    std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X'); -- clk
signal tx_clkout               :    std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
signal rx_clkout               :    std_logic_vector(HSSI_NUM-1 downto 0);                      -- clk
signal rx_is_lockedtoref       :    std_logic_vector(HSSI_NUM-1 downto 0);

signal tx_err_ins              :    std_logic_vector(HSSI_NUM-1 downto 0)   := (others => 'X');
signal tx_pma_clkout           :    std_logic_vector(HSSI_NUM-1 downto 0) ;
signal rx_pma_clkout           :    std_logic_vector(HSSI_NUM-1 downto 0) ;

signal pll_powerdown_buf  : std_logic ;

component kr_atx_5g is
port (
    pll_powerdown 	 : in  std_logic := 'X'; -- pll_powerdown
    pll_refclk0  	 : in  std_logic := 'X'; -- clk
    tx_serial_clk	 : out std_logic;        -- clk
    pll_locked   	 : out std_logic;        -- pll_locked
    pll_cal_busy     : out std_logic;        --    pll_cal_busy.pll_cal_busy
    mcgb_rst         : in  std_logic := '0'; --        mcgb_rst.mcgb_rst
    mcgb_serial_clk  : out std_logic         -- mcgb_serial_clk.clk
);
end component kr_atx_5g;

component fpll_5g is
    port (
        pll_refclk0   : in  std_logic := 'X'; -- clk
        pll_powerdown : in  std_logic := 'X'; -- pll_powerdown
        pll_locked    : out std_logic;        -- pll_locked
        tx_serial_clk : out std_logic;        -- clk
        pll_cal_busy  : out std_logic         -- pll_cal_busy
    );
end component fpll_5g;

begin
pll_powerdown_buf <= '0' when pll_powerdown = 0 else '1';
pll_select<=(others=>'0');
tx_err_ins<=(others=>'0');

kr_atx_inst: kr_atx_5g
port map (
    pll_powerdown	 => pll_powerdown(0), -- pll_powerdown.pll_powerdown
    pll_refclk0  	 => refclk_125      ,   --   pll_refclk0.clk
    tx_serial_clk	 => open,
    pll_locked   	 => pll_locked(0),    --    pll_locked.pll_locked
    pll_cal_busy 	 => pll_cal_busy(0),   --  pll_cal_busy.pll_cal_busy
    mcgb_rst     	 => pll_powerdown(0),
    mcgb_serial_clk  => tx_serial_clk       -- mcgb_serial_clk.clk for X6
);

--fpll_5g_inst : component fpll_5g
--    port map (
--        pll_refclk0   => refclk_125,   --   pll_refclk0.clk
--        pll_powerdown => pll_powerdown(0), -- pll_powerdown.pll_powerdown
--        pll_locked    => pll_locked(0),    --    pll_locked.pll_locked
--        tx_serial_clk => tx_serial_clk, -- tx_serial_clk.clk
--        pll_cal_busy  => pll_cal_busy(0)   --  pll_cal_busy.pll_cal_busy
--    );

serd_rst_i: phyreset_5g
port map
(
    clock               => reconfclk,               --               clock.clk
    reset               => phy_reset,               --               reset.reset
    pll_powerdown0      => pll_powerdown(0),      --      pll_powerdown0.pll_powerdown
    tx_analogreset0     => tx_analogreset(0),     --     tx_analogreset0.tx_analogreset
    tx_analogreset1     => tx_analogreset(1),     --     tx_analogreset1.tx_analogreset
    tx_analogreset2     => tx_analogreset(2),     --     tx_analogreset2.tx_analogreset
    tx_analogreset3     => tx_analogreset(3),     --     tx_analogreset3.tx_analogreset

    tx_digitalreset0     => tx_digitalreset(0),
    tx_digitalreset1     => tx_digitalreset(1),
    tx_digitalreset2     => tx_digitalreset(2),
    tx_digitalreset3     => tx_digitalreset(3),

    tx_ready0           => tx_ready(0),           --           tx_ready0.tx_ready
    tx_ready1           => tx_ready(1),           --           tx_ready1.tx_ready
    tx_ready2           => tx_ready(2),           --           tx_ready2.tx_ready
    tx_ready3           => tx_ready(3),           --           tx_ready3.tx_ready

    pll_locked0         => pll_locked(0),         --         pll_locked0.pll_locked
    pll_select0         => pll_select(0),         --         pll_select0.pll_select
    pll_select1         => pll_select(1),         --         pll_select1.pll_select
    pll_select2         => pll_select(2),         --         pll_select2.pll_select
    pll_select3         => pll_select(3),         --         pll_select3.pll_select

    tx_cal_busy0        => tx_cal_busy(0),        --        tx_cal_busy0.tx_cal_busy
    tx_cal_busy1        => tx_cal_busy(1),        --        tx_cal_busy1.tx_cal_busy
    tx_cal_busy2        => tx_cal_busy(2),        --        tx_cal_busy2.tx_cal_busy
    tx_cal_busy3        => tx_cal_busy(3),        --        tx_cal_busy3.tx_cal_busy

    pll_cal_busy0       => pll_cal_busy(0),       --       pll_cal_busy0.pll_cal_busy
    rx_analogreset0     => rx_analogreset(0),     --     rx_analogreset0.rx_analogreset
    rx_analogreset1     => rx_analogreset(1),     --     rx_analogreset1.rx_analogreset
    rx_analogreset2     => rx_analogreset(2),     --     rx_analogreset2.rx_analogreset
    rx_analogreset3     => rx_analogreset(3),     --     rx_analogreset3.rx_analogreset

    rx_digitalreset0    => rx_digitalreset(0),    --    rx_digitalreset0.rx_digitalreset
    rx_digitalreset1    => rx_digitalreset(1),    --    rx_digitalreset1.rx_digitalreset
    rx_digitalreset2    => rx_digitalreset(2),    --    rx_digitalreset2.rx_digitalreset
    rx_digitalreset3    => rx_digitalreset(3),    --    rx_digitalreset3.rx_digitalreset

    rx_ready0           => rx_ready(0),           --           rx_ready0.rx_ready
    rx_ready1           => rx_ready(1),           --           rx_ready1.rx_ready
    rx_ready2           => rx_ready(2),           --           rx_ready2.rx_ready
    rx_ready3           => rx_ready(3),           --           rx_ready3.rx_ready

    rx_is_lockedtodata0 => rx_is_lockedtodata(0), -- rx_is_lockedtodata0.rx_is_lockedtodata
    rx_is_lockedtodata1 => rx_is_lockedtodata(1), -- rx_is_lockedtodata1.rx_is_lockedtodata
    rx_is_lockedtodata2 => rx_is_lockedtodata(2), -- rx_is_lockedtodata2.rx_is_lockedtodata
    rx_is_lockedtodata3 => rx_is_lockedtodata(3), -- rx_is_lockedtodata3.rx_is_lockedtodata

    rx_cal_busy0            => rx_cal_busy(0),        --        rx_cal_busy0.rx_cal_busy
    rx_cal_busy1            => rx_cal_busy(1),        --        rx_cal_busy1.rx_cal_busy
    rx_cal_busy2            => rx_cal_busy(2),        --        rx_cal_busy2.rx_cal_busy
    rx_cal_busy3            => rx_cal_busy(3)         --        rx_cal_busy3.rx_cal_busy
);
tx_clk <= tx_coreclkin(0); ----tx_clkout;
rx_clk <= rx_coreclkin; ----rx_clkout;

tx_coreclkin <= tx_pma_clkout(0)&tx_pma_clkout(0)&tx_pma_clkout(0)&tx_pma_clkout(0);
rx_coreclkin <= rx_pma_clkout;


process(tx_serial_clk)begin
    for i in 0 to HSSI_NUM-1 LOOP
        tx_serial_clk0(I)<= tx_serial_clk;
    END LOOP;
END PROCESS;

serdes_i: ip8b10b_5gbaseR
port map(
    tx_analogreset         => tx_analogreset    , -- tx_analogreset
    tx_digitalreset        => tx_digitalreset   , -- tx_digitalreset
    rx_analogreset         => rx_analogreset    , -- rx_analogreset
    rx_digitalreset        => rx_digitalreset   , -- rx_digitalreset
    tx_cal_busy            => tx_cal_busy      , -- tx_cal_busy
    rx_cal_busy            => rx_cal_busy      , -- rx_cal_busy
    tx_serial_clk0         => tx_serial_clk0   , -- clk
    rx_cdr_refclk0         => refclk_125 , -- clk
    tx_serial_data         => tx_serial_data, -- tx_serial_data
    rx_serial_data         => rx_serial_data, -- rx_serial_data
    rx_is_lockedtoref      => rx_is_lockedtoref ,                     -- rx_is_lockedtoref
    rx_is_lockedtodata     => rx_is_lockedtodata,                     -- rx_is_lockedtodata
    tx_coreclkin           => tx_coreclkin, ---:= (others => 'X'); -- clk
    rx_coreclkin           => rx_coreclkin, ---:= (others => 'X'); -- clk
    tx_clkout              => tx_clkout,    ---                    -- clk
    rx_clkout              => rx_clkout,    ---                    -- clk
    tx_pma_div_clkout      => tx_pma_clkout,                     -- clk
    rx_pma_div_clkout      => rx_pma_clkout,                     -- clk
    tx_parallel_data       => tx_parallel_data      , -- tx_parallel_data
    tx_control             => tx_control            , -- tx_control
    tx_err_ins             => tx_err_ins            , -- tx_err_ins
    unused_tx_parallel_data  =>(others => '0'), -- unused_tx_parallel_data
    unused_tx_control        =>(others => '0'), -- unused_tx_control
    rx_parallel_data         => rx_parallel_data     ,                    -- rx_parallel_data
    rx_control               => rx_control           ,                    -- rx_control
    unused_rx_parallel_data  => open ,                   -- unused_rx_parallel_data
    unused_rx_control        => open ,                   -- unused_rx_control

    tx_enh_data_valid        => tx_enh_data_valid  ,
    tx_enh_fifo_full         => tx_enh_fifo_full    ,                      -- tx_enh_fifo_full
    tx_enh_fifo_pfull        => tx_enh_fifo_pfull   ,                      -- tx_enh_fifo_pfull
    tx_enh_fifo_empty        => tx_enh_fifo_empty   ,                      -- tx_enh_fifo_empty
    tx_enh_fifo_pempty       => tx_enh_fifo_pempty  ,                      -- tx_enh_fifo_pempty
    rx_enh_data_valid        => rx_enh_data_valid ,                      -- rx_enh_data_valid
    rx_enh_fifo_full         =>rx_enh_fifo_full ,                      -- rx_enh_fifo_full
    rx_enh_fifo_empty        =>rx_enh_fifo_empty,                      -- rx_enh_fifo_empty
    rx_enh_fifo_del          =>rx_enh_fifo_del     ,                      -- rx_enh_fifo_del
    rx_enh_fifo_insert       =>rx_enh_fifo_insert  ,                      -- rx_enh_fifo_insert
    rx_enh_highber           =>rx_enh_highber      ,                      -- rx_enh_highber
    rx_enh_blk_lock          =>rx_enh_blk_lock      ,

    reconfig_clk             => reconfig_clk            ,
    reconfig_reset           => reconfig_reset             ,
    reconfig_write           => (others=>'0')          ,
    reconfig_read            => (others=>'0')           ,
    reconfig_address         => reconfig_address        ,
    reconfig_writedata       => reconfig_writedata      ,
    reconfig_readdata        => reconfig_readdata       ,
    reconfig_waitrequest     => reconfig_waitrequest
);

reconfig_clk(0)<=reconfclk;
reconfig_reset(0)<=phy_reset;


end beha;
