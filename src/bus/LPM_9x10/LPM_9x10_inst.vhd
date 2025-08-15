	component LPM_9x10 is
		port (
			dataa  : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- dataa
			result : out std_logic_vector(18 downto 0);                    -- result
			datab  : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- datab
			clock  : in  std_logic                     := 'X'              -- clk
		);
	end component LPM_9x10;

	u0 : component LPM_9x10
		port map (
			dataa  => CONNECTED_TO_dataa,  --  dataa.dataa
			result => CONNECTED_TO_result, -- result.result
			datab  => CONNECTED_TO_datab,  --  datab.datab
			clock  => CONNECTED_TO_clock   --  clock.clk
		);

