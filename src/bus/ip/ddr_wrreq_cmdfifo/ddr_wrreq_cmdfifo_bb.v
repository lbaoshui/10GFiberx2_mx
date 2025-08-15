module ddr_wrreq_cmdfifo (
		input  wire [52:0] data,    //  fifo_input.datain
		input  wire        wrreq,   //            .wrreq
		input  wire        rdreq,   //            .rdreq
		input  wire        wrclk,   //            .wrclk
		input  wire        rdclk,   //            .rdclk
		input  wire        aclr,    //            .aclr
		output wire [52:0] q,       // fifo_output.dataout
		output wire [4:0]  rdusedw, //            .rdusedw
		output wire [4:0]  wrusedw, //            .wrusedw
		output wire        rdempty, //            .rdempty
		output wire        wrfull   //            .wrfull
	);
endmodule

