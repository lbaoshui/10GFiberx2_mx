module vsyncinfo_ram (
		input  wire [63:0] data,      //      data.datain
		output wire [63:0] q,         //         q.dataout
		input  wire [4:0]  wraddress, // wraddress.wraddress
		input  wire [4:0]  rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        wrclock,   //   wrclock.clk
		input  wire        rdclock    //   rdclock.clk
	);
endmodule

