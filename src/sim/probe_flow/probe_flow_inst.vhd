	component probe_flow is
		port (
			source : out std_logic_vector(31 downto 0);                    -- source
			probe  : in  std_logic_vector(0 downto 0)  := (others => 'X')  -- probe
		);
	end component probe_flow;

	u0 : component probe_flow
		port map (
			source => CONNECTED_TO_source, -- sources.source
			probe  => CONNECTED_TO_probe   --  probes.probe
		);

