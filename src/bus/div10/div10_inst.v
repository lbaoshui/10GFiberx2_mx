	div10 u0 (
		.numer    (_connected_to_numer_),    //   input,  width = 16,  lpm_divide_input.numer
		.denom    (_connected_to_denom_),    //   input,   width = 4,                  .denom
		.clock    (_connected_to_clock_),    //   input,   width = 1,                  .clock
		.quotient (_connected_to_quotient_), //  output,  width = 16, lpm_divide_output.quotient
		.remain   (_connected_to_remain_)    //  output,   width = 4,                  .remain
	);

