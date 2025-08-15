module cmdfifo (
		input  wire [49:0] data,    //  fifo_input.datain
		input  wire        wrreq,   //            .wrreq
		input  wire        rdreq,   //            .rdreq
		input  wire        wrclk,   //            .wrclk
		input  wire        rdclk,   //            .rdclk
		input  wire        aclr,    //            .aclr
		output wire [49:0] q,       // fifo_output.dataout
		output wire [3:0]  rdusedw, //            .rdusedw
		output wire        rdempty, //            .rdempty
		output wire        wrfull   //            .wrfull
	);
endmodule

