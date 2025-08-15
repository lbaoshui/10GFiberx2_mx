module fpll_5g (
		input  wire  pll_refclk0,   //   pll_refclk0.clk
		input  wire  pll_powerdown, // pll_powerdown.pll_powerdown
		output wire  pll_locked,    //    pll_locked.pll_locked
		output wire  tx_serial_clk, // tx_serial_clk.clk
		output wire  pll_cal_busy   //  pll_cal_busy.pll_cal_busy
	);
endmodule

