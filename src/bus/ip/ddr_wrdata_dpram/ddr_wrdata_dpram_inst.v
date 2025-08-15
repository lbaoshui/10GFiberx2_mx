	ddr_wrdata_dpram u0 (
		.data            (_connected_to_data_),            //   input,  width = 320,            data.datain
		.q               (_connected_to_q_),               //  output,  width = 320,               q.dataout
		.wraddress       (_connected_to_wraddress_),       //   input,    width = 9,       wraddress.wraddress
		.rdaddress       (_connected_to_rdaddress_),       //   input,    width = 9,       rdaddress.rdaddress
		.wren            (_connected_to_wren_),            //   input,    width = 1,            wren.wren
		.wrclock         (_connected_to_wrclock_),         //   input,    width = 1,         wrclock.clk
		.rdclock         (_connected_to_rdclock_),         //   input,    width = 1,         rdclock.clk
		.rden            (_connected_to_rden_),            //   input,    width = 1,            rden.rden
		.rd_addressstall (_connected_to_rd_addressstall_), //   input,    width = 1, rd_addressstall.rd_addressstall
		.rdinclocken     (_connected_to_rdinclocken_),     //   input,    width = 1,     rdinclocken.rdinclocken
		.rdoutclocken    (_connected_to_rdoutclocken_)     //   input,    width = 1,    rdoutclocken.rdoutclocken
	);

