// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  div10_lpm_divide_181_wr7wgzi  (
	clock,
	denom,
	numer,
	quotient,
	remain);

	input	  clock;
	input	[3:0]  denom;
	input	[15:0]  numer;
	output	[15:0]  quotient;
	output	[3:0]  remain;

	wire [15:0] sub_wire0;
	wire [3:0] sub_wire1;
	wire [15:0] quotient = sub_wire0[15:0];
	wire [3:0] remain = sub_wire1[3:0];

	lpm_divide  LPM_DIVIDE_component (
				.clock (clock),
				.denom (denom),
				.numer (numer),
				.quotient (sub_wire0),
				.remain (sub_wire1),
				.aclr (1'b0),
				.clken (1'b1));
	defparam
		LPM_DIVIDE_component.lpm_drepresentation  = "UNSIGNED",
		LPM_DIVIDE_component.lpm_hint  = "LPM_REMAINDERPOSITIVE=TRUE",
		LPM_DIVIDE_component.lpm_nrepresentation  = "UNSIGNED",
		LPM_DIVIDE_component.lpm_pipeline  = 10,
		LPM_DIVIDE_component.lpm_type  = "LPM_DIVIDE",
		LPM_DIVIDE_component.lpm_widthd  = 4,
		LPM_DIVIDE_component.lpm_widthn  = 16;


endmodule
