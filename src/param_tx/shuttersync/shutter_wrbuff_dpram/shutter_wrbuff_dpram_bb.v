module shutter_wrbuff_dpram (
		input  wire [63:0] data,      //      data.datain
		output wire [63:0] q,         //         q.dataout
		input  wire [8:0]  wraddress, // wraddress.wraddress
		input  wire [8:0]  rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        clock      //     clock.clk
	);
endmodule

