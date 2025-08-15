	bfm_slave_avalon #(
		.AV_ADDRESS_W               (INTEGER_VALUE_FOR_AV_ADDRESS_W),
		.AV_SYMBOL_W                (INTEGER_VALUE_FOR_AV_SYMBOL_W),
		.AV_NUMSYMBOLS              (INTEGER_VALUE_FOR_AV_NUMSYMBOLS),
		.AV_BURSTCOUNT_W            (INTEGER_VALUE_FOR_AV_BURSTCOUNT_W),
		.AV_READRESPONSE_W          (INTEGER_VALUE_FOR_AV_READRESPONSE_W),
		.AV_WRITERESPONSE_W         (INTEGER_VALUE_FOR_AV_WRITERESPONSE_W),
		.USE_READ                   (INTEGER_VALUE_FOR_USE_READ),
		.USE_WRITE                  (INTEGER_VALUE_FOR_USE_WRITE),
		.USE_ADDRESS                (INTEGER_VALUE_FOR_USE_ADDRESS),
		.USE_BYTE_ENABLE            (INTEGER_VALUE_FOR_USE_BYTE_ENABLE),
		.USE_BURSTCOUNT             (INTEGER_VALUE_FOR_USE_BURSTCOUNT),
		.USE_READ_DATA              (INTEGER_VALUE_FOR_USE_READ_DATA),
		.USE_READ_DATA_VALID        (INTEGER_VALUE_FOR_USE_READ_DATA_VALID),
		.USE_WRITE_DATA             (INTEGER_VALUE_FOR_USE_WRITE_DATA),
		.USE_BEGIN_TRANSFER         (INTEGER_VALUE_FOR_USE_BEGIN_TRANSFER),
		.USE_BEGIN_BURST_TRANSFER   (INTEGER_VALUE_FOR_USE_BEGIN_BURST_TRANSFER),
		.USE_WAIT_REQUEST           (INTEGER_VALUE_FOR_USE_WAIT_REQUEST),
		.USE_TRANSACTIONID          (INTEGER_VALUE_FOR_USE_TRANSACTIONID),
		.USE_WRITERESPONSE          (INTEGER_VALUE_FOR_USE_WRITERESPONSE),
		.USE_READRESPONSE           (INTEGER_VALUE_FOR_USE_READRESPONSE),
		.USE_CLKEN                  (INTEGER_VALUE_FOR_USE_CLKEN),
		.AV_BURST_LINEWRAP          (INTEGER_VALUE_FOR_AV_BURST_LINEWRAP),
		.AV_BURST_BNDR_ONLY         (INTEGER_VALUE_FOR_AV_BURST_BNDR_ONLY),
		.AV_MAX_PENDING_READS       (INTEGER_VALUE_FOR_AV_MAX_PENDING_READS),
		.AV_MAX_PENDING_WRITES      (INTEGER_VALUE_FOR_AV_MAX_PENDING_WRITES),
		.AV_FIX_READ_LATENCY        (INTEGER_VALUE_FOR_AV_FIX_READ_LATENCY),
		.AV_READ_WAIT_TIME          (INTEGER_VALUE_FOR_AV_READ_WAIT_TIME),
		.AV_WRITE_WAIT_TIME         (INTEGER_VALUE_FOR_AV_WRITE_WAIT_TIME),
		.AV_WAITREQUEST_ALLOWANCE   (INTEGER_VALUE_FOR_AV_WAITREQUEST_ALLOWANCE),
		.REGISTER_WAITREQUEST       (INTEGER_VALUE_FOR_REGISTER_WAITREQUEST),
		.AV_REGISTERINCOMINGSIGNALS (INTEGER_VALUE_FOR_AV_REGISTERINCOMINGSIGNALS),
		.VHDL_ID                    (INTEGER_VALUE_FOR_VHDL_ID)
	) u0 (
		.clk               (_connected_to_clk_),               //   input,    width = 1,       clk.clk
		.reset             (_connected_to_reset_),             //   input,    width = 1, clk_reset.reset
		.avs_writedata     (_connected_to_avs_writedata_),     //   input,  width = 512,        s0.writedata
		.avs_burstcount    (_connected_to_avs_burstcount_),    //   input,    width = 7,          .burstcount
		.avs_readdata      (_connected_to_avs_readdata_),      //  output,  width = 512,          .readdata
		.avs_address       (_connected_to_avs_address_),       //   input,   width = 23,          .address
		.avs_waitrequest   (_connected_to_avs_waitrequest_),   //  output,    width = 1,          .waitrequest
		.avs_write         (_connected_to_avs_write_),         //   input,    width = 1,          .write
		.avs_read          (_connected_to_avs_read_),          //   input,    width = 1,          .read
		.avs_byteenable    (_connected_to_avs_byteenable_),    //   input,   width = 64,          .byteenable
		.avs_readdatavalid (_connected_to_avs_readdatavalid_)  //  output,    width = 1,          .readdatavalid
	);

