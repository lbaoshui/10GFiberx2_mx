

module fpll_recalib 
(

  input  wire clk,                        // The same clock driving the reconfig controllers
  input  wire reset,                      // The same reset driving the reconfig controllers

  
   // TX PLL reconfig controller interface
  output wire [9:0] txpll_mgmt_address,
  output wire [31:0] txpll_mgmt_writedata,
  input  wire [31:0] txpll_mgmt_readdata,
  output wire txpll_mgmt_write,
  output wire txpll_mgmt_read,
  input  wire txpll_mgmt_waitrequest,
  
  
  input  wire tx_pll_cal_busy

);

// main FSM states
localparam  FSM_CNF_TXPLL1              = 6'd0,
            FSM_CNF_TXPLL2              = 6'd1,
            FSM_CAL_TXPLL1              = 6'd2,
            FSM_CAL_TXPLL2              = 6'd3,
            FSM_CAL_TXPLL3              = 6'd4,
            FSM_CAL_TXPLL4              = 6'd5,
            FSM_MEM_TXPLL1              = 6'd6,
            FSM_MEM_TXPLL2              = 6'd7,
            FSM_CNF_RXGXB1              = 6'd8,
            FSM_CNF_RXGXB2              = 6'd9,
            FSM_CNF_RXGXB3              = 6'd10,
            FSM_CNF_RXGXB_NEXTLANE      = 6'd11,
            FSM_CAL_RXGXB1              = 6'd12,
            FSM_CAL_RXGXB2              = 6'd13,
            FSM_CAL_RXGXB3              = 6'd14,
            FSM_CAL_RXGXB4              = 6'd15,
            FSM_CAL_RXGXB5              = 6'd16,
            FSM_MEM_RXGXB               = 6'd17,
            FSM_CAL_RXGXB_NEXTLANE      = 6'd18,
            FSM_IDLE                    = 6'd19,
            FSM_START_RX_LINKRATE       = 6'd20,
            FSM_START_RX_ANALOG         = 6'd21,
            FSM_START_TX_LINKRATE       = 6'd22,
            FSM_START_TX_ANALOG         = 6'd23,
            FSM_FEAT_RECONFIG           = 6'd24,
            FSM_WAIT_FOR_BUSY_LOW       = 6'd25,
            FSM_NEXT_RX_LRATE_FEATURE   = 6'd26,
            FSM_NEXT_RX_ANALOG_FEATURE  = 6'd27,
            FSM_NEXT_TX_LRATE_FEATURE   = 6'd28,
            FSM_NEXT_TX_ANALOG_FEATURE  = 6'd29,
            FSM_END_RECONFIG            = 6'd30,
            FSM_NEXT_LANE               = 6'd31,
            FSM_END                     = 6'd32;

// Feature index
localparam  FEAT_RX_GAIN1   = 5'd0,
            FEAT_RX_GAIN2   = 5'd1,
            FEAT_RX_GAIN3   = 5'd2,
            FEAT_RX_GAIN4   = 5'd3,
            FEAT_RX_REFCLK1 = 5'd4,
            FEAT_RX_REFCLK2 = 5'd5,
            FEAT_RX_REFCLK3 = 5'd6,
            FEAT_RX_REFCLK4 = 5'd7,
            FEAT_RX_REFCLK5 = 5'd8,
            FEAT_TX_VOD     = 5'd9,
            FEAT_TX_EMP1    = 5'd10,
            FEAT_TX_EMP2    = 5'd11,
            FEAT_TX_EMP3    = 5'd12,
            FEAT_TX_EMP4    = 5'd13,
            FEAT_TX_REFCLK1 = 5'd14,
            FEAT_TX_REFCLK2 = 5'd15,
            FEAT_TX_REFCLK3 = 5'd16;

// XCVR Reconfiguration controller register addresses
localparam  ADDR_CALIB                                  = 10'h100,
            ADDR_PRE_EMP_SWITCHING_CTRL_1ST_POST_TAP    = 10'h105,
            ADDR_PRE_EMP_SWITCHING_CTRL_2ND_POST_TAP    = 10'h106,
            ADDR_PRE_EMP_SWITCHING_CTRL_PRE_TAP_1T      = 10'h107,
            ADDR_PRE_EMP_SWITCHING_CTRL_PRE_TAP_2T      = 10'h108,
            ADDR_VOD_OUTPUT_SWING_CTRL                  = 10'h109,
            ADDR_DCGAIN1                                = 10'h11A,
            ADDR_DCGAIN2                                = 10'h11C,
            ADDR_L_PFD_COUNTER                          = 10'h13a,
            ADDR_L_PD_COUNTER                           = 10'h13a,
            ADDR_M_COUNTER                              = 10'h13b,
            ADDR_PPM_SEL                                = 10'h00e,
            ADDR_VGA                                    = 10'h160,
            ADDR_CP_CALIB                               = 10'h166,
            ADDR_ACGAIN                                 = 10'h167;

// XCVR Reconfiguration controller register masks
localparam  MASK_CALIB                                  = 32'h0000_0006,
            MASK_PRE_EMP_SWITCHING_CTRL_1ST_POST_TAP    = 32'h0000_005f,
            MASK_PRE_EMP_SWITCHING_CTRL_2ND_POST_TAP    = 32'h0000_002f,
            MASK_PRE_EMP_SWITCHING_CTRL_PRE_TAP_1T      = 32'h0000_003f,
            MASK_PRE_EMP_SWITCHING_CTRL_PRE_TAP_2T      = 32'h0000_0017,
            MASK_VOD_OUTPUT_SWING_CTRL                  = 32'h0000_001f,
            MASK_DCGAIN1                                = 32'h0000_00ff,
            MASK_DCGAIN2                                = 32'h0000_000f,
            MASK_L_PFD_COUNTER                          = 32'h0000_0007,
            MASK_L_PD_COUNTER                           = 32'h0000_0038,
            MASK_M_COUNTER                              = 32'h0000_00ff,
            MASK_PPM_SEL                                = 32'h0000_00fc,
            MASK_VGA                                    = 10'h0000_000e,
            MASK_CP_CALIB                               = 32'h0000_0080,
            MASK_ACGAIN                                 = 32'h0000_003e;

// TXPLL Reconfiguration controller register addresses
localparam  ADDR_TXPLL_CALIB                           = 10'h100,  
            ADDR_TXPLL_M_CNT                           = 10'h12b,
            ADDR_TXPLL_L_CNT                           = 10'h12c;

// TXPLL Reconfiguration controller register masks
localparam  MASK_TXPLL_CALIB                           = 32'h0000_0002,
            MASK_TXPLL_M_CNT                           = 32'h0000_00ff,
            MASK_TXPLL_L_CNT                           = 32'h0000_0006;
            
wire tx_cal_busy ;

assign tx_cal_busy = tx_pll_cal_busy;



always @ (posedge clk or posedge reset) 
begin
  if(reset) 
  begin
    fsm_state <= FSM_CNF_TXPLL1;
    tx_vod_mem <= 0;
    tx_emp_mem <= 0;
    rx_gains_mem <= 0;
    tx_link_rate_mem <= 3'h0;
    rx_link_rate_mem <= 3'h0;
    
    rcnf_req_cbus <= 1'b0;
    rcnf_rel_cbus <= 1'b0;
    rcnf_wcalib <= 1'b0;
    rcnf_scalib <= 1'b0;
    rcnf_lcalib <= 1'b0;
    rcnf_reconfig <= 1'b0;
    rcnf_address <= 10'h0;
    rcnf_data <= 32'h0;
    rcnf_mask <= 32'h0;

    feature_idx <= FEAT_RX_REFCLK1;
    write_cnt <= 3'h0;
    lane_idx <= 2'h0;
    rx_lrate_busy <= 1'b0;
    tx_lrate_busy <= 1'b0;
    tx_analog_busy <= 1'b0;
    rx_analog_busy <= 1'b0;
  end
  else
  begin
  
    rcnf_req_cbus <= 1'b0;
    rcnf_rel_cbus <= 1'b0;
    rcnf_wcalib <= 1'b0;
    rcnf_scalib <= 1'b0;
    rcnf_lcalib <= 1'b0;
    rcnf_reconfig <= 1'b0;

    case(fsm_state)
    
      FSM_CNF_TXPLL1: // Set the TXPLL to tx_link_rate_mem link rate
        if(tx_link_rate_mem < TX_RATES_NUM)
        begin
          if(~rx_cal_busy & ~tx_cal_busy)
          begin
            tx_lrate_busy <= 1'b1;
            rcnf_address <= ADDR_TXPLL_M_CNT;
            rcnf_mask <= MASK_TXPLL_M_CNT;
            rcnf_data <= {24'd0,M_COUNTER_FPLL[tx_link_rate_mem]};
            rcnf_reconfig <= 1'b1;
            fsm_state <= FSM_CNF_TXPLL2;
          end
        end
        else
        begin
          tx_lrate_busy <= 1'b0;
          fsm_state <= FSM_CNF_RXGXB1;
        end
      
      FSM_CNF_TXPLL2: // Set the TXPLL to tx_link_rate_mem link rate
        if(!rcnf_busy) 
        begin
          rcnf_address <= ADDR_TXPLL_L_CNT;
          rcnf_mask <= MASK_TXPLL_L_CNT;
          rcnf_data <= {29'd0,L_COUNTER_FPLL[tx_link_rate_mem],1'b0};
          rcnf_reconfig <= 1'b1;
          fsm_state <= FSM_CAL_TXPLL1;
        end

      FSM_CAL_TXPLL1: // Get access to TXPLL config bus
        if(!rcnf_busy) 
        begin
          rcnf_req_cbus <= 1'b1;
          fsm_state <= FSM_CAL_TXPLL2;
        end

      FSM_CAL_TXPLL2: // Calibrate TXPLL
        if(!rcnf_busy) 
        begin
          rcnf_address <= ADDR_TXPLL_CALIB;
          rcnf_mask <= MASK_TXPLL_CALIB;
          rcnf_data <= 32'h2;
          rcnf_reconfig <= 1'b1;
          fsm_state <= FSM_CAL_TXPLL3;
        end

      FSM_CAL_TXPLL3: // Release TXPLL config bus
        if(!rcnf_busy) 
        begin
          rcnf_rel_cbus <= 1'b1;
          fsm_state <= FSM_CAL_TXPLL4;
        end

      FSM_CAL_TXPLL4: // Wait for TXPLL calibration end
        if(!rcnf_busy) 
        begin
          rcnf_wcalib <= 1'b1;
          fsm_state <= FSM_MEM_TXPLL1;
        end

      FSM_MEM_TXPLL1: // Store TXPLL link rate related calibration results
        if(!rcnf_busy) 
        begin
          rcnf_scalib <= 1'b1;
          fsm_state <= FSM_MEM_TXPLL2;
        end

      FSM_MEM_TXPLL2: // Goto next link rate
        if(!rcnf_busy) 
        begin
          tx_link_rate_mem <= tx_link_rate_mem + 1'd1;
          fsm_state <= FSM_CNF_TXPLL1;
        end
   

endmodule 