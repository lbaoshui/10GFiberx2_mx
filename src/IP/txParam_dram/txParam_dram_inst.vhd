	component txParam_dram is
		port (
			data      : in  std_logic_vector(72 downto 0) := (others => 'X'); -- datain
			q         : out std_logic_vector(72 downto 0);                    -- dataout
			wraddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- wraddress
			rdaddress : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- rdaddress
			wren      : in  std_logic                     := 'X';             -- wren
			wrclock   : in  std_logic                     := 'X';             -- clk
			rdclock   : in  std_logic                     := 'X'              -- clk
		);
	end component txParam_dram;

	u0 : component txParam_dram
		port map (
			data      => CONNECTED_TO_data,      --      data.datain
			q         => CONNECTED_TO_q,         --         q.dataout
			wraddress => CONNECTED_TO_wraddress, -- wraddress.wraddress
			rdaddress => CONNECTED_TO_rdaddress, -- rdaddress.rdaddress
			wren      => CONNECTED_TO_wren,      --      wren.wren
			wrclock   => CONNECTED_TO_wrclock,   --   wrclock.clk
			rdclock   => CONNECTED_TO_rdclock    --   rdclock.clk
		);

