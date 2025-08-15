	component fifo320 is
		port (
			data  : in  std_logic_vector(319 downto 0) := (others => 'X'); -- datain
			wrreq : in  std_logic                      := 'X';             -- wrreq
			rdreq : in  std_logic                      := 'X';             -- rdreq
			clock : in  std_logic                      := 'X';             -- clk
			aclr  : in  std_logic                      := 'X';             -- aclr
			q     : out std_logic_vector(319 downto 0);                    -- dataout
			full  : out std_logic;                                         -- full
			empty : out std_logic                                          -- empty
		);
	end component fifo320;

	u0 : component fifo320
		port map (
			data  => CONNECTED_TO_data,  --  fifo_input.datain
			wrreq => CONNECTED_TO_wrreq, --            .wrreq
			rdreq => CONNECTED_TO_rdreq, --            .rdreq
			clock => CONNECTED_TO_clock, --            .clk
			aclr  => CONNECTED_TO_aclr,  --            .aclr
			q     => CONNECTED_TO_q,     -- fifo_output.dataout
			full  => CONNECTED_TO_full,  --            .full
			empty => CONNECTED_TO_empty  --            .empty
		);

