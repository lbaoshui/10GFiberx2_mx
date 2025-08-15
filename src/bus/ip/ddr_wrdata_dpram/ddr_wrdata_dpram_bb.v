module ddr_wrdata_dpram (
		input  wire [319:0] data,            //            data.datain
		output wire [319:0] q,               //               q.dataout
		input  wire [8:0]   wraddress,       //       wraddress.wraddress
		input  wire [8:0]   rdaddress,       //       rdaddress.rdaddress
		input  wire         wren,            //            wren.wren
		input  wire         wrclock,         //         wrclock.clk
		input  wire         rdclock,         //         rdclock.clk
		input  wire         rden,            //            rden.rden
		input  wire         rd_addressstall, // rd_addressstall.rd_addressstall
		input  wire         rdinclocken,     //     rdinclocken.rdinclocken
		input  wire         rdoutclocken     //    rdoutclocken.rdoutclocken
	);
endmodule

