module xgmiirx_cmd_fifo (
		input  wire [28:0] data,    //  fifo_input.datain
		input  wire        wrreq,   //            .wrreq
		input  wire        rdreq,   //            .rdreq
		input  wire        wrclk,   //            .wrclk
		input  wire        rdclk,   //            .rdclk
		input  wire        aclr,    //            .aclr
		output wire [28:0] q,       // fifo_output.dataout
		output wire        rdempty, //            .rdempty
		output wire        wrfull   //            .wrfull
	);
endmodule

