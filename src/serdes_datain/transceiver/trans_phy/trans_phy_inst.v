	trans_phy u0 (
		.rx_analogreset          (_connected_to_rx_analogreset_),          //   input,    width = 5,          rx_analogreset.rx_analogreset
		.rx_digitalreset         (_connected_to_rx_digitalreset_),         //   input,    width = 5,         rx_digitalreset.rx_digitalreset
		.rx_cal_busy             (_connected_to_rx_cal_busy_),             //  output,    width = 5,             rx_cal_busy.rx_cal_busy
		.rx_cdr_refclk0          (_connected_to_rx_cdr_refclk0_),          //   input,    width = 1,          rx_cdr_refclk0.clk
		.rx_serial_data          (_connected_to_rx_serial_data_),          //   input,    width = 5,          rx_serial_data.rx_serial_data
		.rx_is_lockedtoref       (_connected_to_rx_is_lockedtoref_),       //  output,    width = 5,       rx_is_lockedtoref.rx_is_lockedtoref
		.rx_is_lockedtodata      (_connected_to_rx_is_lockedtodata_),      //  output,    width = 5,      rx_is_lockedtodata.rx_is_lockedtodata
		.rx_coreclkin            (_connected_to_rx_coreclkin_),            //   input,    width = 5,            rx_coreclkin.clk
		.rx_clkout               (_connected_to_rx_clkout_),               //  output,    width = 5,               rx_clkout.clk
		.rx_pma_div_clkout       (_connected_to_rx_pma_div_clkout_),       //  output,    width = 5,       rx_pma_div_clkout.clk
		.rx_parallel_data        (_connected_to_rx_parallel_data_),        //  output,  width = 320,        rx_parallel_data.rx_parallel_data
		.rx_control              (_connected_to_rx_control_),              //  output,   width = 40,              rx_control.rx_control
		.unused_rx_parallel_data (_connected_to_unused_rx_parallel_data_), //  output,  width = 320, unused_rx_parallel_data.unused_rx_parallel_data
		.unused_rx_control       (_connected_to_unused_rx_control_),       //  output,   width = 60,       unused_rx_control.unused_rx_control
		.rx_enh_data_valid       (_connected_to_rx_enh_data_valid_),       //  output,    width = 5,       rx_enh_data_valid.rx_enh_data_valid
		.rx_enh_fifo_full        (_connected_to_rx_enh_fifo_full_),        //  output,    width = 5,        rx_enh_fifo_full.rx_enh_fifo_full
		.rx_enh_fifo_empty       (_connected_to_rx_enh_fifo_empty_),       //  output,    width = 5,       rx_enh_fifo_empty.rx_enh_fifo_empty
		.rx_enh_fifo_del         (_connected_to_rx_enh_fifo_del_),         //  output,    width = 5,         rx_enh_fifo_del.rx_enh_fifo_del
		.rx_enh_fifo_insert      (_connected_to_rx_enh_fifo_insert_),      //  output,    width = 5,      rx_enh_fifo_insert.rx_enh_fifo_insert
		.rx_enh_highber          (_connected_to_rx_enh_highber_),          //  output,    width = 5,          rx_enh_highber.rx_enh_highber
		.rx_enh_blk_lock         (_connected_to_rx_enh_blk_lock_)          //  output,    width = 5,         rx_enh_blk_lock.rx_enh_blk_lock
	);

