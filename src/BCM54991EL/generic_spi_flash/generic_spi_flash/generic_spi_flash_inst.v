	generic_spi_flash u0 (
		.avl_csr_address       (_connected_to_avl_csr_address_),       //   input,   width = 6, avl_csr.address
		.avl_csr_read          (_connected_to_avl_csr_read_),          //   input,   width = 1,        .read
		.avl_csr_readdata      (_connected_to_avl_csr_readdata_),      //  output,  width = 32,        .readdata
		.avl_csr_write         (_connected_to_avl_csr_write_),         //   input,   width = 1,        .write
		.avl_csr_writedata     (_connected_to_avl_csr_writedata_),     //   input,  width = 32,        .writedata
		.avl_csr_waitrequest   (_connected_to_avl_csr_waitrequest_),   //  output,   width = 1,        .waitrequest
		.avl_csr_readdatavalid (_connected_to_avl_csr_readdatavalid_), //  output,   width = 1,        .readdatavalid
		.avl_mem_write         (_connected_to_avl_mem_write_),         //   input,   width = 1, avl_mem.write
		.avl_mem_burstcount    (_connected_to_avl_mem_burstcount_),    //   input,   width = 7,        .burstcount
		.avl_mem_waitrequest   (_connected_to_avl_mem_waitrequest_),   //  output,   width = 1,        .waitrequest
		.avl_mem_read          (_connected_to_avl_mem_read_),          //   input,   width = 1,        .read
		.avl_mem_address       (_connected_to_avl_mem_address_),       //   input,  width = 23,        .address
		.avl_mem_writedata     (_connected_to_avl_mem_writedata_),     //   input,  width = 32,        .writedata
		.avl_mem_readdata      (_connected_to_avl_mem_readdata_),      //  output,  width = 32,        .readdata
		.avl_mem_readdatavalid (_connected_to_avl_mem_readdatavalid_), //  output,   width = 1,        .readdatavalid
		.avl_mem_byteenable    (_connected_to_avl_mem_byteenable_),    //   input,   width = 4,        .byteenable
		.clk_clk               (_connected_to_clk_clk_),               //   input,   width = 1,     clk.clk
		.reset_reset           (_connected_to_reset_reset_)            //   input,   width = 1,   reset.reset
	);

