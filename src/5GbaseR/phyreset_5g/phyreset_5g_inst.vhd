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

	u0 : component phyreset_5g
		port map (
			clock               => CONNECTED_TO_clock,               --               clock.clk
			reset               => CONNECTED_TO_reset,               --               reset.reset
			pll_powerdown0      => CONNECTED_TO_pll_powerdown0,      --      pll_powerdown0.pll_powerdown
			tx_analogreset0     => CONNECTED_TO_tx_analogreset0,     --     tx_analogreset0.tx_analogreset
			tx_analogreset1     => CONNECTED_TO_tx_analogreset1,     --     tx_analogreset1.tx_analogreset
			tx_analogreset2     => CONNECTED_TO_tx_analogreset2,     --     tx_analogreset2.tx_analogreset
			tx_analogreset3     => CONNECTED_TO_tx_analogreset3,     --     tx_analogreset3.tx_analogreset
			tx_digitalreset0    => CONNECTED_TO_tx_digitalreset0,    --    tx_digitalreset0.tx_digitalreset
			tx_digitalreset1    => CONNECTED_TO_tx_digitalreset1,    --    tx_digitalreset1.tx_digitalreset
			tx_digitalreset2    => CONNECTED_TO_tx_digitalreset2,    --    tx_digitalreset2.tx_digitalreset
			tx_digitalreset3    => CONNECTED_TO_tx_digitalreset3,    --    tx_digitalreset3.tx_digitalreset
			tx_ready0           => CONNECTED_TO_tx_ready0,           --           tx_ready0.tx_ready
			tx_ready1           => CONNECTED_TO_tx_ready1,           --           tx_ready1.tx_ready
			tx_ready2           => CONNECTED_TO_tx_ready2,           --           tx_ready2.tx_ready
			tx_ready3           => CONNECTED_TO_tx_ready3,           --           tx_ready3.tx_ready
			pll_locked0         => CONNECTED_TO_pll_locked0,         --         pll_locked0.pll_locked
			pll_select0         => CONNECTED_TO_pll_select0,         --         pll_select0.pll_select
			pll_select1         => CONNECTED_TO_pll_select1,         --         pll_select1.pll_select
			pll_select2         => CONNECTED_TO_pll_select2,         --         pll_select2.pll_select
			pll_select3         => CONNECTED_TO_pll_select3,         --         pll_select3.pll_select
			tx_cal_busy0        => CONNECTED_TO_tx_cal_busy0,        --        tx_cal_busy0.tx_cal_busy
			tx_cal_busy1        => CONNECTED_TO_tx_cal_busy1,        --        tx_cal_busy1.tx_cal_busy
			tx_cal_busy2        => CONNECTED_TO_tx_cal_busy2,        --        tx_cal_busy2.tx_cal_busy
			tx_cal_busy3        => CONNECTED_TO_tx_cal_busy3,        --        tx_cal_busy3.tx_cal_busy
			pll_cal_busy0       => CONNECTED_TO_pll_cal_busy0,       --       pll_cal_busy0.pll_cal_busy
			rx_analogreset0     => CONNECTED_TO_rx_analogreset0,     --     rx_analogreset0.rx_analogreset
			rx_analogreset1     => CONNECTED_TO_rx_analogreset1,     --     rx_analogreset1.rx_analogreset
			rx_analogreset2     => CONNECTED_TO_rx_analogreset2,     --     rx_analogreset2.rx_analogreset
			rx_analogreset3     => CONNECTED_TO_rx_analogreset3,     --     rx_analogreset3.rx_analogreset
			rx_digitalreset0    => CONNECTED_TO_rx_digitalreset0,    --    rx_digitalreset0.rx_digitalreset
			rx_digitalreset1    => CONNECTED_TO_rx_digitalreset1,    --    rx_digitalreset1.rx_digitalreset
			rx_digitalreset2    => CONNECTED_TO_rx_digitalreset2,    --    rx_digitalreset2.rx_digitalreset
			rx_digitalreset3    => CONNECTED_TO_rx_digitalreset3,    --    rx_digitalreset3.rx_digitalreset
			rx_ready0           => CONNECTED_TO_rx_ready0,           --           rx_ready0.rx_ready
			rx_ready1           => CONNECTED_TO_rx_ready1,           --           rx_ready1.rx_ready
			rx_ready2           => CONNECTED_TO_rx_ready2,           --           rx_ready2.rx_ready
			rx_ready3           => CONNECTED_TO_rx_ready3,           --           rx_ready3.rx_ready
			rx_is_lockedtodata0 => CONNECTED_TO_rx_is_lockedtodata0, -- rx_is_lockedtodata0.rx_is_lockedtodata
			rx_is_lockedtodata1 => CONNECTED_TO_rx_is_lockedtodata1, -- rx_is_lockedtodata1.rx_is_lockedtodata
			rx_is_lockedtodata2 => CONNECTED_TO_rx_is_lockedtodata2, -- rx_is_lockedtodata2.rx_is_lockedtodata
			rx_is_lockedtodata3 => CONNECTED_TO_rx_is_lockedtodata3, -- rx_is_lockedtodata3.rx_is_lockedtodata
			rx_cal_busy0        => CONNECTED_TO_rx_cal_busy0,        --        rx_cal_busy0.rx_cal_busy
			rx_cal_busy1        => CONNECTED_TO_rx_cal_busy1,        --        rx_cal_busy1.rx_cal_busy
			rx_cal_busy2        => CONNECTED_TO_rx_cal_busy2,        --        rx_cal_busy2.rx_cal_busy
			rx_cal_busy3        => CONNECTED_TO_rx_cal_busy3         --        rx_cal_busy3.rx_cal_busy
		);

