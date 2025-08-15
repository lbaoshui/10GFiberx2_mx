module trans_phy (
		input  wire [4:0]   rx_analogreset,          //          rx_analogreset.rx_analogreset
		input  wire [4:0]   rx_digitalreset,         //         rx_digitalreset.rx_digitalreset
		output wire [4:0]   rx_cal_busy,             //             rx_cal_busy.rx_cal_busy
		input  wire         rx_cdr_refclk0,          //          rx_cdr_refclk0.clk
		input  wire [4:0]   rx_serial_data,          //          rx_serial_data.rx_serial_data
		output wire [4:0]   rx_is_lockedtoref,       //       rx_is_lockedtoref.rx_is_lockedtoref
		output wire [4:0]   rx_is_lockedtodata,      //      rx_is_lockedtodata.rx_is_lockedtodata
		input  wire [4:0]   rx_coreclkin,            //            rx_coreclkin.clk
		output wire [4:0]   rx_clkout,               //               rx_clkout.clk
		output wire [4:0]   rx_pma_div_clkout,       //       rx_pma_div_clkout.clk
		output wire [319:0] rx_parallel_data,        //        rx_parallel_data.rx_parallel_data
		output wire [39:0]  rx_control,              //              rx_control.rx_control
		output wire [319:0] unused_rx_parallel_data, // unused_rx_parallel_data.unused_rx_parallel_data
		output wire [59:0]  unused_rx_control,       //       unused_rx_control.unused_rx_control
		output wire [4:0]   rx_enh_data_valid,       //       rx_enh_data_valid.rx_enh_data_valid
		output wire [4:0]   rx_enh_fifo_full,        //        rx_enh_fifo_full.rx_enh_fifo_full
		output wire [4:0]   rx_enh_fifo_empty,       //       rx_enh_fifo_empty.rx_enh_fifo_empty
		output wire [4:0]   rx_enh_fifo_del,         //         rx_enh_fifo_del.rx_enh_fifo_del
		output wire [4:0]   rx_enh_fifo_insert,      //      rx_enh_fifo_insert.rx_enh_fifo_insert
		output wire [4:0]   rx_enh_highber,          //          rx_enh_highber.rx_enh_highber
		output wire [4:0]   rx_enh_blk_lock          //         rx_enh_blk_lock.rx_enh_blk_lock
	);
endmodule

