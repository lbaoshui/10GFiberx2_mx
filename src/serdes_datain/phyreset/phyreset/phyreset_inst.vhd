	component phyreset is
		port (
			clock              : in  std_logic                    := 'X';             -- clk
			reset              : in  std_logic                    := 'X';             -- reset
			rx_analogreset     : out std_logic_vector(4 downto 0);                    -- rx_analogreset
			rx_digitalreset    : out std_logic_vector(4 downto 0);                    -- rx_digitalreset
			rx_ready           : out std_logic_vector(4 downto 0);                    -- rx_ready
			rx_is_lockedtodata : in  std_logic_vector(4 downto 0) := (others => 'X'); -- rx_is_lockedtodata
			rx_cal_busy        : in  std_logic_vector(4 downto 0) := (others => 'X')  -- rx_cal_busy
		);
	end component phyreset;

	u0 : component phyreset
		port map (
			clock              => CONNECTED_TO_clock,              --              clock.clk
			reset              => CONNECTED_TO_reset,              --              reset.reset
			rx_analogreset     => CONNECTED_TO_rx_analogreset,     --     rx_analogreset.rx_analogreset
			rx_digitalreset    => CONNECTED_TO_rx_digitalreset,    --    rx_digitalreset.rx_digitalreset
			rx_ready           => CONNECTED_TO_rx_ready,           --           rx_ready.rx_ready
			rx_is_lockedtodata => CONNECTED_TO_rx_is_lockedtodata, -- rx_is_lockedtodata.rx_is_lockedtodata
			rx_cal_busy        => CONNECTED_TO_rx_cal_busy         --        rx_cal_busy.rx_cal_busy
		);

