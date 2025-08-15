	component kr_atx_5g is
		port (
			pll_powerdown   : in  std_logic := 'X'; -- pll_powerdown
			pll_refclk0     : in  std_logic := 'X'; -- clk
			tx_serial_clk   : out std_logic;        -- clk
			pll_locked      : out std_logic;        -- pll_locked
			pll_cal_busy    : out std_logic;        -- pll_cal_busy
			mcgb_rst        : in  std_logic := 'X'; -- mcgb_rst
			mcgb_serial_clk : out std_logic         -- clk
		);
	end component kr_atx_5g;

	u0 : component kr_atx_5g
		port map (
			pll_powerdown   => CONNECTED_TO_pll_powerdown,   --   pll_powerdown.pll_powerdown
			pll_refclk0     => CONNECTED_TO_pll_refclk0,     --     pll_refclk0.clk
			tx_serial_clk   => CONNECTED_TO_tx_serial_clk,   --   tx_serial_clk.clk
			pll_locked      => CONNECTED_TO_pll_locked,      --      pll_locked.pll_locked
			pll_cal_busy    => CONNECTED_TO_pll_cal_busy,    --    pll_cal_busy.pll_cal_busy
			mcgb_rst        => CONNECTED_TO_mcgb_rst,        --        mcgb_rst.mcgb_rst
			mcgb_serial_clk => CONNECTED_TO_mcgb_serial_clk  -- mcgb_serial_clk.clk
		);

