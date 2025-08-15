	component ddr_wrmask_dpram is
		port (
			data            : in  std_logic_vector(39 downto 0) := (others => 'X'); -- datain
			q               : out std_logic_vector(39 downto 0);                    -- dataout
			wraddress       : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- wraddress
			rdaddress       : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- rdaddress
			wren            : in  std_logic                     := 'X';             -- wren
			wrclock         : in  std_logic                     := 'X';             -- clk
			rdclock         : in  std_logic                     := 'X';             -- clk
			rden            : in  std_logic                     := 'X';             -- rden
			rd_addressstall : in  std_logic                     := 'X';             -- rd_addressstall
			rdinclocken     : in  std_logic                     := 'X';             -- rdinclocken
			rdoutclocken    : in  std_logic                     := 'X'              -- rdoutclocken
		);
	end component ddr_wrmask_dpram;

	u0 : component ddr_wrmask_dpram
		port map (
			data            => CONNECTED_TO_data,            --            data.datain
			q               => CONNECTED_TO_q,               --               q.dataout
			wraddress       => CONNECTED_TO_wraddress,       --       wraddress.wraddress
			rdaddress       => CONNECTED_TO_rdaddress,       --       rdaddress.rdaddress
			wren            => CONNECTED_TO_wren,            --            wren.wren
			wrclock         => CONNECTED_TO_wrclock,         --         wrclock.clk
			rdclock         => CONNECTED_TO_rdclock,         --         rdclock.clk
			rden            => CONNECTED_TO_rden,            --            rden.rden
			rd_addressstall => CONNECTED_TO_rd_addressstall, -- rd_addressstall.rd_addressstall
			rdinclocken     => CONNECTED_TO_rdinclocken,     --     rdinclocken.rdinclocken
			rdoutclocken    => CONNECTED_TO_rdoutclocken     --    rdoutclocken.rdoutclocken
		);

