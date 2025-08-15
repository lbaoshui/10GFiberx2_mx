	component div10 is
		port (
			numer    : in  std_logic_vector(15 downto 0) := (others => 'X'); -- numer
			denom    : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- denom
			clock    : in  std_logic                     := 'X';             -- clock
			quotient : out std_logic_vector(15 downto 0);                    -- quotient
			remain   : out std_logic_vector(3 downto 0)                      -- remain
		);
	end component div10;

	u0 : component div10
		port map (
			numer    => CONNECTED_TO_numer,    --  lpm_divide_input.numer
			denom    => CONNECTED_TO_denom,    --                  .denom
			clock    => CONNECTED_TO_clock,    --                  .clock
			quotient => CONNECTED_TO_quotient, -- lpm_divide_output.quotient
			remain   => CONNECTED_TO_remain    --                  .remain
		);

