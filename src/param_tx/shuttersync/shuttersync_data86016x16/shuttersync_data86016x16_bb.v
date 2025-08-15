module shuttersync_data86016x16 (
		input  wire [15:0] data,      //      data.datain
		output wire [15:0] q,         //         q.dataout
		input  wire [16:0] wraddress, // wraddress.wraddress
		input  wire [16:0] rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        clock      //     clock.clk
	);
endmodule

