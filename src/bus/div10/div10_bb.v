module div10 (
		input  wire [15:0] numer,    //  lpm_divide_input.numer
		input  wire [3:0]  denom,    //                  .denom
		input  wire        clock,    //                  .clock
		output wire [15:0] quotient, // lpm_divide_output.quotient
		output wire [3:0]  remain    //                  .remain
	);
endmodule

