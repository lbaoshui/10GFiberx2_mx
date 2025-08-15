	component param_ram4096x8_buf is
		port (
			data      : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- datain
			q         : out std_logic_vector(7 downto 0);                     -- dataout
			wraddress : in  std_logic_vector(11 downto 0) := (others => 'X'); -- wraddress
			rdaddress : in  std_logic_vector(11 downto 0) := (others => 'X'); -- rdaddress
			wren      : in  std_logic                     := 'X';             -- wren
			clock     : in  std_logic                     := 'X'              -- clk
		);
	end component param_ram4096x8_buf;

	u0 : component param_ram4096x8_buf
		port map (
			data      => CONNECTED_TO_data,      --      data.datain
			q         => CONNECTED_TO_q,         --         q.dataout
			wraddress => CONNECTED_TO_wraddress, -- wraddress.wraddress
			rdaddress => CONNECTED_TO_rdaddress, -- rdaddress.rdaddress
			wren      => CONNECTED_TO_wren,      --      wren.wren
			clock     => CONNECTED_TO_clock      --     clock.clk
		);

