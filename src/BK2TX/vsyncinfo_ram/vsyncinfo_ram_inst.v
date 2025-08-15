	vsyncinfo_ram u0 (
		.data      (_connected_to_data_),      //   input,  width = 64,      data.datain
		.q         (_connected_to_q_),         //  output,  width = 64,         q.dataout
		.wraddress (_connected_to_wraddress_), //   input,   width = 5, wraddress.wraddress
		.rdaddress (_connected_to_rdaddress_), //   input,   width = 5, rdaddress.rdaddress
		.wren      (_connected_to_wren_),      //   input,   width = 1,      wren.wren
		.wrclock   (_connected_to_wrclock_),   //   input,   width = 1,   wrclock.clk
		.rdclock   (_connected_to_rdclock_)    //   input,   width = 1,   rdclock.clk
	);

