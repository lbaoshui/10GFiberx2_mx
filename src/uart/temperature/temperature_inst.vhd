	component temperature is
		port (
			corectl : in  std_logic                    := 'X'; -- corectl
			reset   : in  std_logic                    := 'X'; -- reset
			tempout : out std_logic_vector(9 downto 0);        -- tempout
			eoc     : out std_logic                            -- eoc
		);
	end component temperature;

	u0 : component temperature
		port map (
			corectl => CONNECTED_TO_corectl, -- corectl.corectl
			reset   => CONNECTED_TO_reset,   --   reset.reset
			tempout => CONNECTED_TO_tempout, -- tempout.tempout
			eoc     => CONNECTED_TO_eoc      --     eoc.eoc
		);

