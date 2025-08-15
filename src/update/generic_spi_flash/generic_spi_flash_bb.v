module generic_spi_flash (
		input  wire [5:0]  avl_csr_address,       // avl_csr.address
		input  wire        avl_csr_read,          //        .read
		output wire [31:0] avl_csr_readdata,      //        .readdata
		input  wire        avl_csr_write,         //        .write
		input  wire [31:0] avl_csr_writedata,     //        .writedata
		output wire        avl_csr_waitrequest,   //        .waitrequest
		output wire        avl_csr_readdatavalid, //        .readdatavalid
		input  wire        avl_mem_write,         // avl_mem.write
		input  wire [6:0]  avl_mem_burstcount,    //        .burstcount
		output wire        avl_mem_waitrequest,   //        .waitrequest
		input  wire        avl_mem_read,          //        .read
		input  wire [22:0] avl_mem_address,       //        .address
		input  wire [31:0] avl_mem_writedata,     //        .writedata
		output wire [31:0] avl_mem_readdata,      //        .readdata
		output wire        avl_mem_readdatavalid, //        .readdatavalid
		input  wire [3:0]  avl_mem_byteenable,    //        .byteenable
		input  wire        clk_clk,               //     clk.clk
		input  wire        reset_reset            //   reset.reset
	);
endmodule

