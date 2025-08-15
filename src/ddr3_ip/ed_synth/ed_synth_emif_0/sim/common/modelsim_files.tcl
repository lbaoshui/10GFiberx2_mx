
namespace eval ed_synth_emif_0 {
  proc get_design_libraries {} {
    set libraries [dict create]
    dict set libraries altera_emif_arch_nf_191             1
    dict set libraries altera_avalon_mm_bridge_2001        1
    dict set libraries altera_avalon_onchip_memory2_1931   1
    dict set libraries altera_merlin_master_translator_191 1
    dict set libraries altera_merlin_slave_translator_191  1
    dict set libraries altera_mm_interconnect_1920         1
    dict set libraries altera_reset_controller_1921        1
    dict set libraries altera_emif_cal_slave_nf_191        1
    dict set libraries altera_emif_1920                    1
    dict set libraries ed_synth_emif_0                     1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR} {
    set memory_files [list]
    lappend memory_files "[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/ed_synth_emif_0_altera_emif_arch_nf_191_3kbv6gq_seq_params_sim.hex"]"
    lappend memory_files "[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/ed_synth_emif_0_altera_emif_arch_nf_191_3kbv6gq_seq_params_synth.hex"]"
    lappend memory_files "[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/ed_synth_emif_0_altera_emif_arch_nf_191_3kbv6gq_seq_cal.hex"]"
    lappend memory_files "[normalize_path "$QSYS_SIMDIR/../altera_avalon_onchip_memory2_1931/sim/seq_cal_soft_m20k.hex"]"
    return $memory_files
  }
  
  proc get_common_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [dict create]
    return $design_files
  }
  
  proc get_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [list]
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/ed_synth_emif_0_altera_emif_arch_nf_191_3kbv6gq_top.sv"]\"  -work altera_emif_arch_nf_191"                                
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/ed_synth_emif_0_altera_emif_arch_nf_191_3kbv6gq_io_aux.sv"]\"  -work altera_emif_arch_nf_191"                             
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_oct.sv"]\"  -work altera_emif_arch_nf_191"                                                            
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_udir_df_o.sv"]\"  -work altera_emif_arch_nf_191"                                                  
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_bdir_df.sv"]\"  -work altera_emif_arch_nf_191"                                                    
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_bdir_se.sv"]\"  -work altera_emif_arch_nf_191"                                                    
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_udir_cp_i.sv"]\"  -work altera_emif_arch_nf_191"                                                  
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_udir_df_i.sv"]\"  -work altera_emif_arch_nf_191"                                                  
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_udir_se_i.sv"]\"  -work altera_emif_arch_nf_191"                                                  
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_udir_se_o.sv"]\"  -work altera_emif_arch_nf_191"                                                  
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_core_clks_rsts.sv"]\"  -work altera_emif_arch_nf_191"                                                 
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_io_tiles.sv"]\"  -work altera_emif_arch_nf_191"                                                       
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_io_tiles_abphy.sv"]\"  -work altera_emif_arch_nf_191"                                                 
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_pll.sv"]\"  -work altera_emif_arch_nf_191"                                                            
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/twentynm_io_12_lane_abphy.sv"]\"  -work altera_emif_arch_nf_191"                                                          
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/twentynm_io_12_lane_encrypted_abphy.sv"]\"  -work altera_emif_arch_nf_191"                                                
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/twentynm_io_12_lane_nf5es_encrypted_abphy.sv"]\"  -work altera_emif_arch_nf_191"                                          
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_bufs.sv"]\"  -work altera_emif_arch_nf_191"                                                           
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_buf_unused.sv"]\"  -work altera_emif_arch_nf_191"                                                     
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_cal_counter.sv"]\"  -work altera_emif_arch_nf_191"                                                    
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_pll_fast_sim.sv"]\"  -work altera_emif_arch_nf_191"                                                   
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_pll_extra_clks.sv"]\"  -work altera_emif_arch_nf_191"                                                 
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_hps_clks_rsts.sv"]\"  -work altera_emif_arch_nf_191"                                                  
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_io_tiles_wrap.sv"]\"  -work altera_emif_arch_nf_191"                                                  
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_abphy_mux.sv"]\"  -work altera_emif_arch_nf_191"                                                      
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_hmc_avl_if.sv"]\"  -work altera_emif_arch_nf_191"                                                     
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_hmc_sideband_if.sv"]\"  -work altera_emif_arch_nf_191"                                                
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_hmc_mmr_if.sv"]\"  -work altera_emif_arch_nf_191"                                                     
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_hmc_amm_data_if.sv"]\"  -work altera_emif_arch_nf_191"                                                
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_hmc_ast_data_if.sv"]\"  -work altera_emif_arch_nf_191"                                                
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_afi_if.sv"]\"  -work altera_emif_arch_nf_191"                                                         
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_seq_if.sv"]\"  -work altera_emif_arch_nf_191"                                                         
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_emif_arch_nf_regs.sv"]\"  -work altera_emif_arch_nf_191"                                                           
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_oct.sv"]\"  -work altera_emif_arch_nf_191"                                                                         
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_oct_um_fsm.sv"]\"  -work altera_emif_arch_nf_191"                                                                  
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/altera_std_synchronizer_nocut.v"]\"  -work altera_emif_arch_nf_191"                                                           
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/mem_array_abphy.sv"]\"  -work altera_emif_arch_nf_191"                                                                    
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/io_12_lane_bcm__nf5es_abphy.sv"]\"  -work altera_emif_arch_nf_191"                                                        
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/io_12_lane__nf5es_abphy.sv"]\"  -work altera_emif_arch_nf_191"                                                            
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_arch_nf_191/sim/ed_synth_emif_0_altera_emif_arch_nf_191_3kbv6gq.sv"]\"  -work altera_emif_arch_nf_191"                                    
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_avalon_mm_bridge_2001/sim/ed_synth_emif_0_altera_avalon_mm_bridge_2001_k2bg7dq.v"]\"  -work altera_avalon_mm_bridge_2001"                          
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_avalon_onchip_memory2_1931/sim/ed_synth_emif_0_altera_avalon_onchip_memory2_1931_puxlqdi.v"]\"  -work altera_avalon_onchip_memory2_1931"           
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_master_translator_191/sim/ed_synth_emif_0_altera_merlin_master_translator_191_g7h47bq.sv"]\"  -work altera_merlin_master_translator_191"
    lappend design_files "vlog -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_slave_translator_191/sim/ed_synth_emif_0_altera_merlin_slave_translator_191_x56fcki.sv"]\"  -work altera_merlin_slave_translator_191"   
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_mm_interconnect_1920/sim/ed_synth_emif_0_altera_mm_interconnect_1920_trcm3ta.v"]\"  -work altera_mm_interconnect_1920"                             
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_1921/sim/altera_reset_controller.v"]\"  -work altera_reset_controller_1921"                                                       
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_1921/sim/altera_reset_synchronizer.v"]\"  -work altera_reset_controller_1921"                                                     
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_cal_slave_nf_191/sim/ed_synth_emif_0_altera_emif_cal_slave_nf_191_rmzieji.v"]\"  -work altera_emif_cal_slave_nf_191"                          
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_emif_1920/sim/ed_synth_emif_0_altera_emif_1920_ytt7v2a.v"]\"  -work altera_emif_1920"                                                              
    lappend design_files "vlog $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/ed_synth_emif_0.v"]\"  -work ed_synth_emif_0"                                                                                                                
    return $design_files
  }
  
  proc get_elab_options {SIMULATOR_TOOL_BITNESS} {
    set ELAB_OPTIONS ""
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ELAB_OPTIONS
  }
  
  
  proc get_sim_options {SIMULATOR_TOOL_BITNESS} {
    set SIM_OPTIONS ""
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $SIM_OPTIONS
  }
  
  
  proc get_env_variables {SIMULATOR_TOOL_BITNESS} {
    set ENV_VARIABLES [dict create]
    set LD_LIBRARY_PATH [dict create]
    dict set ENV_VARIABLES "LD_LIBRARY_PATH" $LD_LIBRARY_PATH
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ENV_VARIABLES
  }
  
  
  proc normalize_path {FILEPATH} {
      if {[catch { package require fileutil } err]} { 
          return $FILEPATH 
      } 
      set path [fileutil::lexnormalize [file join [pwd] $FILEPATH]]  
      if {[file pathtype $FILEPATH] eq "relative"} { 
          set path [fileutil::relative [pwd] $path] 
      } 
      return $path 
  } 
}
