	fifo320 u0 (
		.data  (_connected_to_data_),  //   input,  width = 320,  fifo_input.datain
		.wrreq (_connected_to_wrreq_), //   input,    width = 1,            .wrreq
		.rdreq (_connected_to_rdreq_), //   input,    width = 1,            .rdreq
		.clock (_connected_to_clock_), //   input,    width = 1,            .clk
		.aclr  (_connected_to_aclr_),  //   input,    width = 1,            .aclr
		.q     (_connected_to_q_),     //  output,  width = 320, fifo_output.dataout
		.full  (_connected_to_full_),  //  output,    width = 1,            .full
		.empty (_connected_to_empty_)  //  output,    width = 1,            .empty
	);

