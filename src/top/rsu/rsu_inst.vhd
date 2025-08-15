	component rsu is
		port (
			clock       : in  std_logic                     := 'X';             -- clk
			reset       : in  std_logic                     := 'X';             -- reset
			read_param  : in  std_logic                     := 'X';             -- read_param
			param       : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- param
			reconfig    : in  std_logic                     := 'X';             -- reconfig
			reset_timer : in  std_logic                     := 'X';             -- reset_timer
			busy        : out std_logic;                                        -- busy
			data_out    : out std_logic_vector(31 downto 0);                    -- data_out
			ctl_nupdt   : in  std_logic                     := 'X'              -- ctl_nupdt
		);
	end component rsu;

	u0 : component rsu
		port map (
			clock       => CONNECTED_TO_clock,       --       clock.clk
			reset       => CONNECTED_TO_reset,       --       reset.reset
			read_param  => CONNECTED_TO_read_param,  --  read_param.read_param
			param       => CONNECTED_TO_param,       --       param.param
			reconfig    => CONNECTED_TO_reconfig,    --    reconfig.reconfig
			reset_timer => CONNECTED_TO_reset_timer, -- reset_timer.reset_timer
			busy        => CONNECTED_TO_busy,        --        busy.busy
			data_out    => CONNECTED_TO_data_out,    --    data_out.data_out
			ctl_nupdt   => CONNECTED_TO_ctl_nupdt    --   ctl_nupdt.ctl_nupdt
		);

