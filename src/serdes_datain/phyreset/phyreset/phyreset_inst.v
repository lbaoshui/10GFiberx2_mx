	phyreset u0 (
		.clock              (_connected_to_clock_),              //   input,  width = 1,              clock.clk
		.reset              (_connected_to_reset_),              //   input,  width = 1,              reset.reset
		.rx_analogreset     (_connected_to_rx_analogreset_),     //  output,  width = 5,     rx_analogreset.rx_analogreset
		.rx_digitalreset    (_connected_to_rx_digitalreset_),    //  output,  width = 5,    rx_digitalreset.rx_digitalreset
		.rx_ready           (_connected_to_rx_ready_),           //  output,  width = 5,           rx_ready.rx_ready
		.rx_is_lockedtodata (_connected_to_rx_is_lockedtodata_), //   input,  width = 5, rx_is_lockedtodata.rx_is_lockedtodata
		.rx_cal_busy        (_connected_to_rx_cal_busy_)         //   input,  width = 5,        rx_cal_busy.rx_cal_busy
	);

