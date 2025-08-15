	shutter_wrbuff_dpram u0 (
		.data      (_connected_to_data_),      //   input,  width = 64,      data.datain
		.q         (_connected_to_q_),         //  output,  width = 64,         q.dataout
		.wraddress (_connected_to_wraddress_), //   input,   width = 9, wraddress.wraddress
		.rdaddress (_connected_to_rdaddress_), //   input,   width = 9, rdaddress.rdaddress
		.wren      (_connected_to_wren_),      //   input,   width = 1,      wren.wren
		.clock     (_connected_to_clock_)      //   input,   width = 1,     clock.clk
	);

