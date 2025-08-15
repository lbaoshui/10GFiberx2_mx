module fifo320 (
		input  wire [319:0] data,  //  fifo_input.datain
		input  wire         wrreq, //            .wrreq
		input  wire         rdreq, //            .rdreq
		input  wire         clock, //            .clk
		input  wire         aclr,  //            .aclr
		output wire [319:0] q,     // fifo_output.dataout
		output wire         full,  //            .full
		output wire         empty  //            .empty
	);
endmodule

