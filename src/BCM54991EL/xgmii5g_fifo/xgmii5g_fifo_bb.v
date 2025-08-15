module xgmii5g_fifo (
		input  wire [71:0] data,    //  fifo_input.datain
		input  wire        wrreq,   //            .wrreq
		input  wire        rdreq,   //            .rdreq
		input  wire        wrclk,   //            .wrclk
		input  wire        rdclk,   //            .rdclk
		output wire [71:0] q,       // fifo_output.dataout
		output wire        rdempty  //            .rdempty
	);
endmodule

