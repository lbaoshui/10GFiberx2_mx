# (C) 2001-2018 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other
# software and tools, and its AMPP partner logic functions, and any output
# files from any of the foregoing (including device programming or simulation
# files), and any associated documentation or information are expressly subject
# to the terms and conditions of the Intel Program License Subscription
# Agreement, Intel FPGA IP License Agreement, or other applicable
# license agreement, including, without limitation, that your use is for the
# sole purpose of programming logic devices manufactured by Intel and sold by
# Intel or its authorized distributors.  Please refer to the applicable
# agreement for further details.


set_time_format -unit ns -decimal_places 3

create_clock -name {clk125M_in}  -period "125Mhz" [get_ports {clkin_125M}]
create_clock -name {clk156M_in}  -period "156.25Mhz" [get_ports {clkin_156M_sfp}]
#create_clock -name {clk156M_in}  -period "156.25Mhz" [get_ports {clkin_156M_5g}]
create_clock -name {clk_100m}     -period "100Mhz" [get_ports {CLKUSR}]
create_clock -name {mem_pll_ref_clk[0]} -period 8.576 -waveform { 0.000 4.288 } [get_ports {mem_pll_ref_clk[0]}]
create_clock -name {mem_dqs[0]_IN} -period 1.071 -waveform { 0.000 0.536 } [get_ports {mem_dqs[0]}]
create_clock -name {mem_dqs[1]_IN} -period 1.071 -waveform { 0.000 0.536 } [get_ports {mem_dqs[1]}]
create_clock -name {mem_dqs[2]_IN} -period 1.071 -waveform { 0.000 0.536 } [get_ports {mem_dqs[2]}]
create_clock -name {mem_dqs[3]_IN} -period 1.071 -waveform { 0.000 0.536 } [get_ports {mem_dqs[3]}]
create_clock -name {mem_dqs[4]_IN} -period 1.071 -waveform { 0.000 0.536 } [get_ports {mem_dqs[4]}]


create_generated_clock -name {\ddr3_inst_gen:0:ddr3_inst|emif_0_core_usr_clk} -source {\ddr3_inst_gen:0:ddr3_inst|emif_0|arch|arch_inst|pll_inst|pll_inst|vcoph[0]} -divide_by 4 -multiply_by 1 -phase 22.5 { \ddr3_inst_gen:0:ddr3_inst|emif_0|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].tile_ctrl_inst|pa_core_clk_out[0] }
create_generated_clock -name flash_clk1 -divide_by 2 -source [get_ports clk125M_in] [get_registers {top_updata_inst|spi_flash_a10_inst|generic_spi_flash_inst|intel_generic_serial_flash_interface_top_0|qspi_inf_inst|flash_clk_reg}]
create_generated_clock -name flash_clk2 -divide_by 2 -source [get_ports clk125M_in] [get_registers {top_updata_inst|spi_flash_a10_inst|generic_spi_flash_inst|intel_generic_serial_flash_interface_top_0|qspi_inf_inst|oe_reg} ]

set_clock_uncertainty -rise_from [get_clocks {clk125M_in}] -rise_to [get_clocks {clk125M_in}]  0.190
set_clock_uncertainty -rise_from [get_clocks {clk125M_in}] -fall_to [get_clocks {clk125M_in}]  0.190
set_clock_uncertainty -fall_from [get_clocks {clk125M_in}] -rise_to [get_clocks {clk125M_in}]  0.190
set_clock_uncertainty -fall_from [get_clocks {clk125M_in}] -fall_to [get_clocks {clk125M_in}]  0.190

set_clock_uncertainty -rise_from [get_clocks {clk156M_in}] -rise_to [get_clocks {clk156M_in}]  0.190
set_clock_uncertainty -rise_from [get_clocks {clk156M_in}] -fall_to [get_clocks {clk156M_in}]  0.190
set_clock_uncertainty -fall_from [get_clocks {clk156M_in}] -rise_to [get_clocks {clk156M_in}]  0.190
set_clock_uncertainty -fall_from [get_clocks {clk156M_in}] -fall_to [get_clocks {clk156M_in}]  0.190


set_clock_uncertainty -rise_from [get_clocks {clk_100m}] -rise_to [get_clocks {clk_100m}]  0.190
set_clock_uncertainty -rise_from [get_clocks {clk_100m}] -fall_to [get_clocks {clk_100m}]  0.190
set_clock_uncertainty -fall_from [get_clocks {clk_100m}] -rise_to [get_clocks {clk_100m}]  0.190
set_clock_uncertainty -fall_from [get_clocks {clk_100m}] -fall_to [get_clocks {clk_100m}]  0.190
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty



# Setting LED outputs as false path, since no timing requirement
set_false_path -from * -to [get_ports led*]
set_false_path -from [get_ports rxd_frmbk]
set_false_path   -to [get_ports txd_info]
set_false_path   -to [get_ports txd_tobk]

 #set_false_path -to [get_ports  PHYAB_RESET ]   
 #set_false_path -to [get_ports  PHYCD_RESET ]   

# set_max_delay -to [get_ports  PHYAB_MDC]  8 
# set_max_delay -to [get_ports  PHYAB_MDIO] 8 
# set_max_delay -to [get_ports  PHYCD_MDC]  8 
# set_max_delay -to [get_ports  PHYCD_MDIO] 8
# 
# set_max_delay -from [get_ports PHYAB_MDIO] 5  
# set_max_delay -from [get_ports PHYCD_MDIO] 5  
#  



# Constraining JTAG interface
# TCK port
create_clock -name altera_reserved_tck -period 100 [get_ports altera_reserved_tck]
# cut all paths to and from tck
set_clock_groups -exclusive -group [get_clocks altera_reserved_tck]
# constrain the TDI port
set_input_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tdi]
# constrain the TMS port
set_input_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tms]
# constrain the TDO port
set_output_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tdo]


set_false_path -from [get_clocks {altera_ts_clk}] -to [get_clocks {clk125M_in}]


   set_max_delay -from [get_clocks {clk125M_in}] -to [get_clocks {serdes_datain_inst|serdes_phy|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}]        6
   #set_max_delay -from [get_clocks {clk125M_in}] -to [get_clocks {serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[0]|tx_pma_div_clk}]   6 
    #set_max_delay -from [get_clocks {clk125M_in}] -to [get_clocks {serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}]   6
   
   
    #set_false_path -from [get_clocks {serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[0]|tx_pma_div_clk}] -to [get_clocks {serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}]
   

   
   # set_max_delay -from [get_clocks {serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[0]|tx_pma_div_clk}] -to [get_clocks {clk125M_in}] 6 
    #set_max_delay -from [get_clocks {serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}] -to [get_clocks {clk125M_in}] 6
   
   
set_false_path -from * -to {p_uart_inst|info_up|temper*}

# set_max_delay -

set_max_delay -from [get_clocks {serdes_datain_inst|serdes_phy|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}] -to [get_clocks {clk125M_in}]  8 


################
set_false_path -from [get_clocks {serdes_datain_inst|serdes_phy|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}] -to [get_clocks {main_pll_inst|iopll_0|outclk0}]
set_false_path -from [get_clocks {clk125M_in}] -to [get_clocks {main_pll_inst|iopll_0|outclk0}]
set_false_path -from [get_clocks {main_pll_inst|iopll_0|outclk0}] -to [get_clocks {clk125M_in}]
 #set_false_path -from [get_clocks {serdes_datain_inst|serdes_phy|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}] -to [get_clocks {serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|tx_pma_div_clk}]

set_false_path -from {resetmodule_inst|nRST_i}


set_false_path -from {bk2fiber|param_inst|clr_serdesinfo_convclk} -to {bk2fiber|\chan_i:*:oneFiber_i|bk_rcv_i|\align_i:*:rcv_bk_i|clr_serdesinfo_buf[0]}
set_false_path -from [get_clocks {\serdes_10g_gene:serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|tx_pma_div_clk}] -to [get_clocks {main_pll_inst|iopll_0|outclk0}]
set_false_path -from {bk2fiber|\chan_i:*:oneFiber_i|bk_rcv_i|\align_i:*:rcv_bk_i|vsync_notify} -to {bk2fiber|\chan_i:*:oneFiber_i|vs_crs|vcrs2_i|vsync_buf_sys[0]}
set_false_path -from [get_clocks {clk125M_in}] -to [get_clocks {\serdes_10g_gene:serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}]
set_false_path -from [get_clocks {\serdes_10g_gene:serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}] -to [get_clocks {clk125M_in}]
set_false_path -from {bk2fiber|param_inst|eth_forbid_en_convclk[*]} -to {bk2fiber|\chan_i:*:oneFiber_i|out_cmb_i|eth_forbid_en_d1[*]}
set_false_path -from [get_clocks {\serdes_10g_gene:serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|tx_pma_div_clk}] -to [get_clocks {clk125M_in}]
set_false_path -from [get_clocks {clk125M_in}] -to [get_clocks {\serdes_10g_gene:serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|tx_pma_div_clk}]

set_false_path -from [get_clocks {\ddr3_inst_gen:0:ddr3_inst|emif_0_core_usr_clk}] -to [get_clocks {main_pll_inst|iopll_0|outclk0}]
set_false_path -from {shutter_ddr3_inst|\DDR_GEN:0:DDRb_i|rd_arb_i|fifo2_rst} 

set_false_path -from [get_clocks {main_pll_inst|iopll_0|outclk0}] -to [get_clocks {\serdes_10g_gene:serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|tx_pma_div_clk}]
set_false_path -from [get_clocks {\serdes_10g_gene:serdes_dataout_inst|serdes_ip_inst|xcvr_native_a10_0|g_xcvr_native_insts[*]|rx_pma_div_clk}] -to [get_clocks {main_pll_inst|iopll_0|outclk0}]