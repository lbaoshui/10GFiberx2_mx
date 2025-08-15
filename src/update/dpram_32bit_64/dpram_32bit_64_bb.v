module dpram_32bit_64 (
		input  wire [31:0] data,      //      data.datain
		output wire [31:0] q,         //         q.dataout
		input  wire [5:0]  wraddress, // wraddress.wraddress
		input  wire [5:0]  rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        wrclock,   //   wrclock.clk
		input  wire        rdclock    //   rdclock.clk
	);
endmodule

