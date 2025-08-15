module dpram_16bx2048 (
		input  wire [15:0] data,      //      data.datain
		output wire [7:0]  q,         //         q.dataout
		input  wire [10:0] wraddress, // wraddress.wraddress
		input  wire [11:0] rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        wrclock,   //   wrclock.clk
		input  wire        rdclock    //   rdclock.clk
	);
endmodule

