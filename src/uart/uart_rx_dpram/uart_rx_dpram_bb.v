module uart_rx_dpram (
		input  wire [7:0]  data,      //      data.datain
		output wire [7:0]  q,         //         q.dataout
		input  wire [10:0] wraddress, // wraddress.wraddress
		input  wire [10:0] rdaddress, // rdaddress.rdaddress
		input  wire        wren,      //      wren.wren
		input  wire        clock      //     clock.clk
	);
endmodule

