module Up08_conv_dpram (
		input  wire [7:0]  data,      //      data.datain
		output wire [15:0] q,         //         q.dataout
		input  wire [10:0] wraddress, // wraddress.wraddress
		input  wire [9:0]  rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        wrclock,   //   wrclock.clk
		input  wire        rdclock    //   rdclock.clk
	);
endmodule

