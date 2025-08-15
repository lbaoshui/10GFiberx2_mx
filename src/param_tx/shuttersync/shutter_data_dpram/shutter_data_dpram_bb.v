module shutter_data_dpram (
		input  wire [71:0] data,      //      data.datain
		output wire [71:0] q,         //         q.dataout
		input  wire [9:0]  wraddress, // wraddress.wraddress
		input  wire [9:0]  rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        clock      //     clock.clk
	);
endmodule

