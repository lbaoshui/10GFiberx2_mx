	dpram_32bit_64 u0 (
		.data      (_connected_to_data_),      //   input,  width = 32,      data.datain
		.q         (_connected_to_q_),         //  output,  width = 32,         q.dataout
		.wraddress (_connected_to_wraddress_), //   input,   width = 6, wraddress.wraddress
		.rdaddress (_connected_to_rdaddress_), //   input,   width = 6, rdaddress.rdaddress
		.wren      (_connected_to_wren_),      //   input,   width = 1,      wren.wren
		.wrclock   (_connected_to_wrclock_),   //   input,   width = 1,   wrclock.clk
		.rdclock   (_connected_to_rdclock_)    //   input,   width = 1,   rdclock.clk
	);

