module txParam_dram (
		input  wire [72:0] data,      //      data.datain
		output wire [72:0] q,         //         q.dataout
		input  wire [8:0]  wraddress, // wraddress.wraddress
		input  wire [8:0]  rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        wrclock,   //   wrclock.clk
		input  wire        rdclock    //   rdclock.clk
	);
endmodule

