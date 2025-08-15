	component xgmii5g_fifo is
		port (
			data    : in  std_logic_vector(71 downto 0) := (others => 'X'); -- datain
			wrreq   : in  std_logic                     := 'X';             -- wrreq
			rdreq   : in  std_logic                     := 'X';             -- rdreq
			wrclk   : in  std_logic                     := 'X';             -- wrclk
			rdclk   : in  std_logic                     := 'X';             -- rdclk
			q       : out std_logic_vector(71 downto 0);                    -- dataout
			rdempty : out std_logic                                         -- rdempty
		);
	end component xgmii5g_fifo;

	u0 : component xgmii5g_fifo
		port map (
			data    => CONNECTED_TO_data,    --  fifo_input.datain
			wrreq   => CONNECTED_TO_wrreq,   --            .wrreq
			rdreq   => CONNECTED_TO_rdreq,   --            .rdreq
			wrclk   => CONNECTED_TO_wrclk,   --            .wrclk
			rdclk   => CONNECTED_TO_rdclk,   --            .rdclk
			q       => CONNECTED_TO_q,       -- fifo_output.dataout
			rdempty => CONNECTED_TO_rdempty  --            .rdempty
		);

