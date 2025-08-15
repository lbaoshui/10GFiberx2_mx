	component dpram_32bit_64 is
		port (
			data      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datain
			q         : out std_logic_vector(31 downto 0);                    -- dataout
			wraddress : in  std_logic_vector(5 downto 0)  := (others => 'X'); -- wraddress
			rdaddress : in  std_logic_vector(5 downto 0)  := (others => 'X'); -- rdaddress
			wren      : in  std_logic                     := 'X';             -- wren
			wrclock   : in  std_logic                     := 'X';             -- clk
			rdclock   : in  std_logic                     := 'X'              -- clk
		);
	end component dpram_32bit_64;

	u0 : component dpram_32bit_64
		port map (
			data      => CONNECTED_TO_data,      --      data.datain
			q         => CONNECTED_TO_q,         --         q.dataout
			wraddress => CONNECTED_TO_wraddress, -- wraddress.wraddress
			rdaddress => CONNECTED_TO_rdaddress, -- rdaddress.rdaddress
			wren      => CONNECTED_TO_wren,      --      wren.wren
			wrclock   => CONNECTED_TO_wrclock,   --   wrclock.clk
			rdclock   => CONNECTED_TO_rdclock    --   rdclock.clk
		);

