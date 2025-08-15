module ip8b10b_5gbaseR (
		input  wire [3:0]   tx_analogreset,          //          tx_analogreset.tx_analogreset
		input  wire [3:0]   tx_digitalreset,         //         tx_digitalreset.tx_digitalreset
		input  wire [3:0]   rx_analogreset,          //          rx_analogreset.rx_analogreset
		input  wire [3:0]   rx_digitalreset,         //         rx_digitalreset.rx_digitalreset
		output wire [3:0]   tx_cal_busy,             //             tx_cal_busy.tx_cal_busy
		output wire [3:0]   rx_cal_busy,             //             rx_cal_busy.rx_cal_busy
		input  wire [3:0]   tx_serial_clk0,          //          tx_serial_clk0.clk
		input  wire         rx_cdr_refclk0,          //          rx_cdr_refclk0.clk
		output wire [3:0]   tx_serial_data,          //          tx_serial_data.tx_serial_data
		input  wire [3:0]   rx_serial_data,          //          rx_serial_data.rx_serial_data
		output wire [3:0]   rx_is_lockedtoref,       //       rx_is_lockedtoref.rx_is_lockedtoref
		output wire [3:0]   rx_is_lockedtodata,      //      rx_is_lockedtodata.rx_is_lockedtodata
		input  wire [3:0]   tx_coreclkin,            //            tx_coreclkin.clk
		input  wire [3:0]   rx_coreclkin,            //            rx_coreclkin.clk
		output wire [3:0]   tx_clkout,               //               tx_clkout.clk
		output wire [3:0]   rx_clkout,               //               rx_clkout.clk
		output wire [3:0]   tx_pma_div_clkout,       //       tx_pma_div_clkout.clk
		output wire [3:0]   rx_pma_div_clkout,       //       rx_pma_div_clkout.clk
		input  wire [255:0] tx_parallel_data,        //        tx_parallel_data.tx_parallel_data
		input  wire [31:0]  tx_control,              //              tx_control.tx_control
		input  wire [3:0]   tx_err_ins,              //              tx_err_ins.tx_err_ins
		input  wire [255:0] unused_tx_parallel_data, // unused_tx_parallel_data.unused_tx_parallel_data
		input  wire [35:0]  unused_tx_control,       //       unused_tx_control.unused_tx_control
		output wire [255:0] rx_parallel_data,        //        rx_parallel_data.rx_parallel_data
		output wire [31:0]  rx_control,              //              rx_control.rx_control
		output wire [255:0] unused_rx_parallel_data, // unused_rx_parallel_data.unused_rx_parallel_data
		output wire [47:0]  unused_rx_control,       //       unused_rx_control.unused_rx_control
		input  wire [3:0]   tx_enh_data_valid,       //       tx_enh_data_valid.tx_enh_data_valid
		output wire [3:0]   tx_enh_fifo_full,        //        tx_enh_fifo_full.tx_enh_fifo_full
		output wire [3:0]   tx_enh_fifo_pfull,       //       tx_enh_fifo_pfull.tx_enh_fifo_pfull
		output wire [3:0]   tx_enh_fifo_empty,       //       tx_enh_fifo_empty.tx_enh_fifo_empty
		output wire [3:0]   tx_enh_fifo_pempty,      //      tx_enh_fifo_pempty.tx_enh_fifo_pempty
		output wire [3:0]   rx_enh_data_valid,       //       rx_enh_data_valid.rx_enh_data_valid
		output wire [3:0]   rx_enh_fifo_full,        //        rx_enh_fifo_full.rx_enh_fifo_full
		output wire [3:0]   rx_enh_fifo_empty,       //       rx_enh_fifo_empty.rx_enh_fifo_empty
		output wire [3:0]   rx_enh_fifo_del,         //         rx_enh_fifo_del.rx_enh_fifo_del
		output wire [3:0]   rx_enh_fifo_insert,      //      rx_enh_fifo_insert.rx_enh_fifo_insert
		output wire [3:0]   rx_enh_highber,          //          rx_enh_highber.rx_enh_highber
		output wire [3:0]   rx_enh_blk_lock,         //         rx_enh_blk_lock.rx_enh_blk_lock
		input  wire [0:0]   reconfig_clk,            //            reconfig_clk.clk
		input  wire [0:0]   reconfig_reset,          //          reconfig_reset.reset
		input  wire [0:0]   reconfig_write,          //           reconfig_avmm.write
		input  wire [0:0]   reconfig_read,           //                        .read
		input  wire [11:0]  reconfig_address,        //                        .address
		input  wire [31:0]  reconfig_writedata,      //                        .writedata
		output wire [31:0]  reconfig_readdata,       //                        .readdata
		output wire [0:0]   reconfig_waitrequest     //                        .waitrequest
	);
endmodule

