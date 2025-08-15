	component trans_phy is
		port (
			rx_analogreset          : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- rx_analogreset
			rx_digitalreset         : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- rx_digitalreset
			rx_cal_busy             : out std_logic_vector(4 downto 0);                      -- rx_cal_busy
			rx_cdr_refclk0          : in  std_logic                      := 'X';             -- clk
			rx_serial_data          : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- rx_serial_data
			rx_is_lockedtoref       : out std_logic_vector(4 downto 0);                      -- rx_is_lockedtoref
			rx_is_lockedtodata      : out std_logic_vector(4 downto 0);                      -- rx_is_lockedtodata
			rx_coreclkin            : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- clk
			rx_clkout               : out std_logic_vector(4 downto 0);                      -- clk
			rx_pma_div_clkout       : out std_logic_vector(4 downto 0);                      -- clk
			rx_parallel_data        : out std_logic_vector(319 downto 0);                    -- rx_parallel_data
			rx_control              : out std_logic_vector(39 downto 0);                     -- rx_control
			unused_rx_parallel_data : out std_logic_vector(319 downto 0);                    -- unused_rx_parallel_data
			unused_rx_control       : out std_logic_vector(59 downto 0);                     -- unused_rx_control
			rx_enh_data_valid       : out std_logic_vector(4 downto 0);                      -- rx_enh_data_valid
			rx_enh_fifo_full        : out std_logic_vector(4 downto 0);                      -- rx_enh_fifo_full
			rx_enh_fifo_empty       : out std_logic_vector(4 downto 0);                      -- rx_enh_fifo_empty
			rx_enh_fifo_del         : out std_logic_vector(4 downto 0);                      -- rx_enh_fifo_del
			rx_enh_fifo_insert      : out std_logic_vector(4 downto 0);                      -- rx_enh_fifo_insert
			rx_enh_highber          : out std_logic_vector(4 downto 0);                      -- rx_enh_highber
			rx_enh_blk_lock         : out std_logic_vector(4 downto 0)                       -- rx_enh_blk_lock
		);
	end component trans_phy;

	u0 : component trans_phy
		port map (
			rx_analogreset          => CONNECTED_TO_rx_analogreset,          --          rx_analogreset.rx_analogreset
			rx_digitalreset         => CONNECTED_TO_rx_digitalreset,         --         rx_digitalreset.rx_digitalreset
			rx_cal_busy             => CONNECTED_TO_rx_cal_busy,             --             rx_cal_busy.rx_cal_busy
			rx_cdr_refclk0          => CONNECTED_TO_rx_cdr_refclk0,          --          rx_cdr_refclk0.clk
			rx_serial_data          => CONNECTED_TO_rx_serial_data,          --          rx_serial_data.rx_serial_data
			rx_is_lockedtoref       => CONNECTED_TO_rx_is_lockedtoref,       --       rx_is_lockedtoref.rx_is_lockedtoref
			rx_is_lockedtodata      => CONNECTED_TO_rx_is_lockedtodata,      --      rx_is_lockedtodata.rx_is_lockedtodata
			rx_coreclkin            => CONNECTED_TO_rx_coreclkin,            --            rx_coreclkin.clk
			rx_clkout               => CONNECTED_TO_rx_clkout,               --               rx_clkout.clk
			rx_pma_div_clkout       => CONNECTED_TO_rx_pma_div_clkout,       --       rx_pma_div_clkout.clk
			rx_parallel_data        => CONNECTED_TO_rx_parallel_data,        --        rx_parallel_data.rx_parallel_data
			rx_control              => CONNECTED_TO_rx_control,              --              rx_control.rx_control
			unused_rx_parallel_data => CONNECTED_TO_unused_rx_parallel_data, -- unused_rx_parallel_data.unused_rx_parallel_data
			unused_rx_control       => CONNECTED_TO_unused_rx_control,       --       unused_rx_control.unused_rx_control
			rx_enh_data_valid       => CONNECTED_TO_rx_enh_data_valid,       --       rx_enh_data_valid.rx_enh_data_valid
			rx_enh_fifo_full        => CONNECTED_TO_rx_enh_fifo_full,        --        rx_enh_fifo_full.rx_enh_fifo_full
			rx_enh_fifo_empty       => CONNECTED_TO_rx_enh_fifo_empty,       --       rx_enh_fifo_empty.rx_enh_fifo_empty
			rx_enh_fifo_del         => CONNECTED_TO_rx_enh_fifo_del,         --         rx_enh_fifo_del.rx_enh_fifo_del
			rx_enh_fifo_insert      => CONNECTED_TO_rx_enh_fifo_insert,      --      rx_enh_fifo_insert.rx_enh_fifo_insert
			rx_enh_highber          => CONNECTED_TO_rx_enh_highber,          --          rx_enh_highber.rx_enh_highber
			rx_enh_blk_lock         => CONNECTED_TO_rx_enh_blk_lock          --         rx_enh_blk_lock.rx_enh_blk_lock
		);

