
namespace eval generic_spi_flash {
  proc get_design_libraries {} {
    set libraries [dict create]
    dict set libraries intel_generic_serial_flash_interface_csr_181     1
    dict set libraries altera_avalon_sc_fifo_181                        1
    dict set libraries intel_generic_serial_flash_interface_xip_181     1
    dict set libraries intel_generic_serial_flash_interface_addr_181    1
    dict set libraries altera_merlin_demultiplexer_181                  1
    dict set libraries altera_merlin_multiplexer_181                    1
    dict set libraries intel_generic_serial_flash_interface_cmd_181     1
    dict set libraries intel_generic_serial_flash_interface_if_ctrl_181 1
    dict set libraries altera_reset_controller_181                      1
    dict set libraries intel_generic_serial_flash_interface_top_181     1
    dict set libraries generic_spi_flash                                1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR} {
    set memory_files [list]
    return $memory_files
  }
  
  proc get_common_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [dict create]
    return $design_files
  }
  
  proc get_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [list]
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_csr_181/sim/intel_generic_serial_flash_interface_csr.sv"]\"  -work intel_generic_serial_flash_interface_csr_181"                                          
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_avalon_sc_fifo_181/sim/generic_spi_flash_altera_avalon_sc_fifo_181_hseo73i.v"]\"  -work altera_avalon_sc_fifo_181"                                                                 
    lappend design_files "vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_xip_181/sim/avst_fifo.vhd"]\"  -work intel_generic_serial_flash_interface_xip_181"                                                                            
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_xip_181/sim/generic_spi_flash_intel_generic_serial_flash_interface_xip_181_mdszy4q.sv"]\"  -work intel_generic_serial_flash_interface_xip_181"            
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_addr_181/sim/intel_generic_serial_flash_interface_addr.sv"]\"  -work intel_generic_serial_flash_interface_addr_181"                                       
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_181/sim/generic_spi_flash_altera_merlin_demultiplexer_181_hnib7fa.sv"]\"  -work altera_merlin_demultiplexer_181"                                                   
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_181/sim/generic_spi_flash_altera_merlin_multiplexer_181_x7wtypi.sv"]\"  -work altera_merlin_multiplexer_181"                                                         
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_181/sim/altera_merlin_arbitrator.sv"]\"  -work altera_merlin_multiplexer_181"                                                                                        
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_cmd_181/sim/intel_generic_serial_flash_interface_cmd.sv"]\"  -work intel_generic_serial_flash_interface_cmd_181"                                          
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_181/sim/generic_spi_flash_altera_merlin_multiplexer_181_bacy55i.sv"]\"  -work altera_merlin_multiplexer_181"                                                         
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_181/sim/altera_merlin_arbitrator.sv"]\"  -work altera_merlin_multiplexer_181"                                                                                        
    lappend design_files "vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_if_ctrl_181/sim/qspi_inf_mux.vhd"]\"  -work intel_generic_serial_flash_interface_if_ctrl_181"                                                                 
    lappend design_files "vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_if_ctrl_181/sim/inf_sc_fifo_ser_data.vhd"]\"  -work intel_generic_serial_flash_interface_if_ctrl_181"                                                         
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_if_ctrl_181/sim/intel_generic_serial_flash_interface_asmiblock.sv"]\"  -work intel_generic_serial_flash_interface_if_ctrl_181"                       
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_if_ctrl_181/sim/generic_spi_flash_intel_generic_serial_flash_interface_if_ctrl_181_kygc6zi.sv"]\"  -work intel_generic_serial_flash_interface_if_ctrl_181"
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_181/sim/aldec/altera_reset_controller.v"]\"  -work altera_reset_controller_181"                                                                                   
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_181/sim/aldec/altera_reset_synchronizer.v"]\"  -work altera_reset_controller_181"                                                                                 
    lappend design_files "vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../intel_generic_serial_flash_interface_top_181/sim/generic_spi_flash_intel_generic_serial_flash_interface_top_181_zqmrk7a.vhd"]\"  -work intel_generic_serial_flash_interface_top_181"               
    lappend design_files "vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/generic_spi_flash.vhd"]\"  -work generic_spi_flash"                                                                                                                                                   
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
