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




`timescale 1 ns / 1 ns
module intel_generic_serial_flash_interface_asmiblock #(
    parameter DEVICE_FAMILY = "Arria 10",
    parameter NCS_LENGTH    = 3,
    parameter DATA_LENGTH   = 4
) (
    input                           atom_ports_dclk,
    input [NCS_LENGTH-1:0]          atom_ports_ncs,
    input                           atom_ports_oe,
    input [DATA_LENGTH-1:0]         atom_ports_dataout,
    input [DATA_LENGTH-1:0]         atom_ports_dataoe,
        
    output wire [DATA_LENGTH-1:0]  atom_ports_datain
);

    wire                   qspi_pins_dclk;
    wire [NCS_LENGTH-1:0]  qspi_pins_ncs;
    wire [DATA_LENGTH-1:0] qspi_pins_data;
    
    wire [DATA_LENGTH-1:0] data_buf;

    assign qspi_pins_data[0] = (atom_ports_oe === 1'b0) ?  data_buf[0] : 1'bz;
    assign data_buf[0] = (atom_ports_dataoe[0] === 1'b1) ? atom_ports_dataout[0] : 1'bz;
    assign atom_ports_datain[0] = qspi_pins_data[0];
    
    assign qspi_pins_data[1] = (atom_ports_oe === 1'b0) ?  data_buf[1] : 1'bz;
    assign data_buf[1] = (atom_ports_dataoe[1] === 1'b1) ? atom_ports_dataout[1] : 1'bz;
    assign atom_ports_datain[1] = qspi_pins_data[1];
    
    assign qspi_pins_data[2] = (atom_ports_oe === 1'b0) ?  data_buf[2] : 1'bz;
    assign data_buf[2] = (atom_ports_dataoe[2] === 1'b1) ? atom_ports_dataout[2] : 1'bz;
    assign atom_ports_datain[2] = qspi_pins_data[2];
    
    assign qspi_pins_data[3] = (atom_ports_oe === 1'b0) ?  data_buf[3] : 1'bz;
    assign data_buf[3] = (atom_ports_dataoe[3] === 1'b1) ? atom_ports_dataout[3] : 1'bz;
    assign atom_ports_datain[3] = qspi_pins_data[3];
    
    assign qspi_pins_dclk = (atom_ports_oe === 1'b0) ? atom_ports_dclk : 1'bz;
    assign qspi_pins_ncs = (atom_ports_oe === 1'b0) ? atom_ports_ncs : 1'bz;   
    
    // Temporary Flash Module - N25Q256A13E
    N25Qxxx     memory0 (.S(qspi_pins_ncs[0]), .C(qspi_pins_dclk), .HOLD_DQ3(qspi_pins_data[3]), .DQ0(qspi_pins_data[0]), .DQ1(qspi_pins_data[1]), .Vcc('d3300), .Vpp_W_DQ2(qspi_pins_data[2]));
    
    generate
        if (NCS_LENGTH == 3) begin
            N25Qxxx     memory1 (.S(qspi_pins_ncs[1]), .C(qspi_pins_dclk), .HOLD_DQ3(qspi_pins_data[3]), .DQ0(qspi_pins_data[0]), .DQ1(qspi_pins_data[1]), .Vcc('d3300), .Vpp_W_DQ2(qspi_pins_data[2]));
            N25Qxxx     memory2 (.S(qspi_pins_ncs[2]), .C(qspi_pins_dclk), .HOLD_DQ3(qspi_pins_data[3]), .DQ0(qspi_pins_data[0]), .DQ1(qspi_pins_data[1]), .Vcc('d3300), .Vpp_W_DQ2(qspi_pins_data[2]));
        end
    endgenerate
endmodule 








// ***************************************************************************************************************************************************************************************************
//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                           ADDED DTR       /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.1 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


`timescale 1ns / 1ps

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TOP LEVEL MODULE                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.1 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
// ************************************ 
//
// User Data definition file :
//
//      here are defined all parameters
//      that the user can change
//
// ************************************ 

`define N25Q256A13E

`define FILENAME_mem "mem_Q256.vmf" // Memory File Name 
`define FILENAME_sfdp "sfdp.vmf" // SFDP File Name 
`define NVCR_DEFAULT_VALUE 'h8FFF

module paramConfig();
//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif






//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]

endmodule


//***********************************************************************
//***********************************************************************
//    N25Q device as stand alone
//***********************************************************************
//***********************************************************************


`ifdef HOLD_pin
  module N25Qxxx (S, C, HOLD_DQ3, DQ0, DQ1, Vcc, Vpp_W_DQ2);
`else 
  module N25Qxxx (S, C, RESET_DQ3, DQ0, DQ1, Vcc, Vpp_W_DQ2);
`endif

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif






//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]

 parameter [1:0] rdeasystacken = 0;
 parameter [15:0] NVConfigReg_default = `NVCR_DEFAULT_VALUE;

input S;
input C;
input [`VoltageRange] Vcc;

inout DQ0; 
inout DQ1;

`ifdef HOLD_pin
  inout HOLD_DQ3; //input HOLD, inout DQ3
`endif

`ifdef RESET_pin
  inout RESET_DQ3; //input RESET, inout DQ3
`endif

inout Vpp_W_DQ2; //input Vpp_W, inout DQ2 (VPPH not implemented)


// parameter [40*8:1] memory_file = "mem_Q256.vmf";
parameter [40*8:1] memory_file = `FILENAME_mem;

// parameter [2048*8:1] fdp_file = "sfdp.vmf";
parameter [2048*8:1] fdp_file = `FILENAME_sfdp;


reg PollingAccessOn = 0;
reg ReadAccessOn = 0;
wire WriteAccessOn; 

// indicate type of data that will be latched by the model:
//  C=command, A=address, I= address on two pins; E= address on four pins; D=data, N=none, Y=dummy, F=dual_input(F=fast),Q=Quad_io 
reg [8:1] latchingMode = "N";

reg [8*8:1] protocol="extended";

reg [cmdDim-1:0] cmd='h0;
`ifdef byte_4
  reg [addrDimLatch4-1:0] addrLatch='h0;
`else
  reg [addrDimLatch-1:0] addrLatch='h0;
`endif
reg [addrDim-1:0] addr='h0;
reg [dataDim-1:0] data='h0;
reg [dummyDim-1:0] dummy='h0;
reg [dataDim-1:0] LSdata='h0;
reg [dataDim-1:0] dataOut='h0;

integer dummyDimEff;

reg [40*8:1] cmdRecName;

reg quadMode ='h0;

reg die_active = 'h1;  // Indicates that this die is active
                      // Used for stacked die


//----------------------
// HOLD signal
//----------------------
//dovrebbe essere abilitato attraverso il bit 4 del VECR o anche attraverso il bit 4 del NVECR
reg NVCR_HoldResetEnable;

`ifdef HOLD_pin

    reg intHOLD=1;

//aggiunta verificare
   //latchingMode=="E"                                                                                                                                                                 
    assign HOLD = (read.enable_quad || quadMode == 1 || latchingMode=="Q"  || latchingMode=="E" || protocol=="quad" || VolatileEnhReg.VECR[4]==0 || NVCR_HoldResetEnable==0)  ? 1 : HOLD_DQ3; //serve per disabilitare la funzione di hold nel caso di quad read


    always @(HOLD) if (S==0 && C==0) 
        intHOLD = HOLD;
    
    always @(negedge C) if(S==0 && intHOLD!=HOLD) 
        intHOLD = HOLD;

    always @(posedge HOLD , posedge S) if(S==1)
        intHOLD = 1;
    
    always @intHOLD if (Vcc>=Vcc_min) begin
        if(intHOLD==0)
            $display("[%0t ns] ==INFO== Hold condition enabled: communication with the device has been paused.", $time);
        else if(intHOLD==1)
            $display("[%0t ns] ==INFO== Hold condition disabled: communication with the device has been activated.", $time);  
   end
`endif



//-------------------------
// Internal signals
//-------------------------

reg busy=0;

reg [2:0] ck_count = 0; //clock counter (modulo 8) 

reg reset_by_powerOn = 1; //reset_by_powerOn is updated in "Power Up & Voltage check" section

`ifdef RESET_pin

  assign RESET = (read.enable_quad || latchingMode=="Q" || quadMode == 1 ||
  cmdRecName=="Quad Output Read" || cmdRecName=="Quad I/O Fast Read" ||
  latchingMode=="E" || protocol=="quad" || VolatileEnhReg.VECR[4]==0 ||
  NVCR_HoldResetEnable==0 || cmdRecName=="Extended command DOFRDTR" || 
  cmdRecName=="Extended command DIOFRDTR" || cmdRecName=="Extended command QOFRDTR" ||
  cmdRecName=="Extended command QIOFRDTR" || cmdRecName=="Quad Command Fast Read" ||
  cmdRecName=="Quad Output Read" || cmdRecName=="Quad I/O Fast Read" )  ? 1 : RESET_DQ3;  //|| cmdRecName=="Quad I/O Fast Read")  ? 1 : RESET_DQ3; //serve per disabilitare la funzione di reset nel caso di quad read



 
 assign int_reset = (RESET===0 || RESET===1 && protocol!="quad") ? !RESET || reset_by_powerOn : reset_by_powerOn;
`else
  assign int_reset = reset_by_powerOn;
`endif  

`ifdef HOLD_pin
  assign logicOn = !int_reset && !S && intHOLD; 
`else
  assign logicOn = !int_reset && !S;
`endif  



reg deep_power_down = 0; //updated in "Deep power down" processes



reg XIP=0; //XIP mode status (XIP=0 XIP mode not selected, XIP=1 XIP mode selected)



reg DoubleTransferRate = 0;
wire read_enable = read.enable || read.enable_dual || read.enable_quad || read.enable_fast || VolatileReg.enable_VCR_read || VolatileEnhReg.enable_VECR_read;

//---------------------------------------
//  Vpp_W signal : write protect feature
//---------------------------------------

assign W_int = Vpp_W_DQ2;

//----------------------------
// CUI decoders istantiation
//----------------------------
//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                           ADDED DTR       /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              





/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           CUI DECODERS ISTANTIATIONS                  --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//
// Here are istantiated CUIdecoders
// for commands recognition
//  (this file must be included in "Core.v"
//   file)
//


CUIdecoder   

    #(.cmdName("Write Enable"), .cmdCode('h06), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_writeEnable (!busy && !deep_power_down && WriteAccessOn);


CUIdecoder   

    #(.cmdName("Write Disable"), .cmdCode('h04), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_writeDisable (!busy  && !deep_power_down  && WriteAccessOn);


CUIdecoder   

    #(.cmdName("Read ID"), .cmdCode('h9F), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_read_ID_1 (!busy && !deep_power_down  && ReadAccessOn && protocol=="extended");


CUIdecoder   

    #(.cmdName("Multiple I/O Read ID"), .cmdCode('hAF), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_multipleIO_read_ID (!busy && !deep_power_down   && ReadAccessOn && protocol!="extended");

CUIdecoder   

    #(.cmdName("Read ID"), .cmdCode('h9E), .withAddr(0), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_read_ID_2 (!busy && !deep_power_down  && ReadAccessOn && protocol=="extended");

CUIdecoder   

    #(.cmdName("Read SR"), .cmdCode('h05), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_read_SR (PollingAccessOn && !deep_power_down);

CUIdecoder   

    #(.cmdName("Write SR"), .cmdCode('h01), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_write_SR (!busy && WriteAccessOn && !deep_power_down);

CUIdecoder   

    #(.cmdName("Read Flag SR"), .cmdCode('h70), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_read_FSR (PollingAccessOn && !deep_power_down);

CUIdecoder   

    #(.cmdName("Clear Flag SR"), .cmdCode('h50), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_clear_FSR (!busy && WriteAccessOn && !deep_power_down);

//extended protocol
CUIdecoder   

    #(.cmdName("Write Lock Reg"), .cmdCode('hE5), .withAddr(1), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_writeLockReg (!busy && WriteAccessOn && protocol=="extended" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Read Lock Reg"), .cmdCode('hE8), .withAddr(1), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_readLockReg (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);


//dual protocol

CUIdecoder   

    #(.cmdName("Write Lock Reg"), .cmdCode('hE5), .withAddr(0), .with2Addr(1), .with4Addr(0))
    
    CUIDEC_writeLockRegDual (!busy && WriteAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Read Lock Reg"), .cmdCode('hE8), .withAddr(0), .with2Addr(1), .with4Addr(0))
  
    CUIDEC_readLockRegDual (!busy && ReadAccessOn && protocol=="dual" && !deep_power_down);

 CUIdecoder   

      #(.cmdName("Write Protection Management Reg"), .cmdCode('h68), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
      CUIDEC_writePMReg (!busy && WriteAccessOn && protocol=="extended" && !deep_power_down);

  CUIdecoder   

      #(.cmdName("Read Protection Management Reg"), .cmdCode('h2B), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
      CUIDEC_readPMReg (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);

CUIdecoder   

      #(.cmdName("Write Protection Management Reg"), .cmdCode('h68), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
      CUIDEC_writePMRegDual (!busy && WriteAccessOn && protocol=="dual" && !deep_power_down);

  CUIdecoder   

      #(.cmdName("Read Protection Management Reg"), .cmdCode('h2B), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
      CUIDEC_readPMRegDual (!busy && ReadAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder   

      #(.cmdName("Write Protection Management Reg"), .cmdCode('h68), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
      CUIDEC_writePMRegQuad (!busy && WriteAccessOn && protocol=="quad" && !deep_power_down);

  CUIdecoder   

      #(.cmdName("Read Protection Management Reg"), .cmdCode('h2B), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
      CUIDEC_readPMRegQuad (!busy && ReadAccessOn && protocol=="quad" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Write NV Configuration Reg"), .cmdCode('hB1), .withAddr(0), .with2Addr(0), .with4Addr(0))
   
    CUIDEC_writeNVReg (!busy && WriteAccessOn && !deep_power_down);

CUIdecoder   

    #(.cmdName("Read NV Configuration Reg"), .cmdCode('hB5), .withAddr(0), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_readNVReg (!busy && ReadAccessOn && !deep_power_down);

CUIdecoder   

    #(.cmdName("Write Volatile Configuration Reg"), .cmdCode('h81), .withAddr(0), .with2Addr(0), .with4Addr(0))
   
    CUIDEC_writeVCReg (!busy && WriteAccessOn && !deep_power_down);

CUIdecoder   

    #(.cmdName("Read Volatile Configuration Reg"), .cmdCode('h85), .withAddr(0), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_readVCReg (!busy && ReadAccessOn && !deep_power_down);


CUIdecoder   

    #(.cmdName("Write VE Configuration Reg"), .cmdCode('h61), .withAddr(0), .with2Addr(0), .with4Addr(0))
   
    CUIDEC_writeVEReg (!busy && WriteAccessOn && !deep_power_down);


CUIdecoder   

    #(.cmdName("Read VE Configuration Reg"), .cmdCode('h65), .withAddr(0), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_readVEReg (!busy && ReadAccessOn && !deep_power_down);


`ifdef byte_4

CUIdecoder   

    #(.cmdName("Read EAR"), .cmdCode('hC8), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_readEAR (!busy && ReadAccessOn && !deep_power_down);


CUIdecoder   

    #(.cmdName("Write EAR"), .cmdCode('hC5), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_writeEAR (!busy && WriteAccessOn && !deep_power_down);
      
`endif
//



CUIdecoder   

    #(.cmdName("Read"), .cmdCode('h03), .withAddr(1), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_read (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);


CUIdecoder   

    #(.cmdName("Read Fast"), .cmdCode('h0B), .withAddr(1), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_readFast (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);


CUIdecoder   

    #(.cmdName("Dual Command Fast Read"), .cmdCode('h0B), .withAddr(0), .with2Addr(1), .with4Addr(0))
    
    CUIDEC_readFastdual (!busy && ReadAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Quad Command Fast Read"), .cmdCode('h0B), .withAddr(0), .with2Addr(0), .with4Addr(1))
    
    CUIDEC_readFastquad (!busy && ReadAccessOn && protocol=="quad" && !deep_power_down);


CUIdecoder   

    #(.cmdName("Read Serial Flash Discovery Parameter"), .cmdCode('h5A), .withAddr(1), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_readSFDP (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);


CUIdecoder   

    #(.cmdName("Read Serial Flash Discovery Parameter"), .cmdCode('h5A), .withAddr(0), .with2Addr(1), .with4Addr(0))
    
    CUIDEC_readSFDPdual (!busy && ReadAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Read Serial Flash Discovery Parameter"), .cmdCode('h5A), .withAddr(0), .with2Addr(0), .with4Addr(1))
    
    CUIDEC_readSFDPquad (!busy && ReadAccessOn && protocol=="quad" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Page Program"), .cmdCode('h02), .withAddr(1), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_pageProgram (!busy && WriteAccessOn && protocol=="extended" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Dual Command Page Program"), .cmdCode('h02), .withAddr(0), .with2Addr(1), .with4Addr(0))
    
    CUIDEC_pageProgramdual (!busy && WriteAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder   

    #(.cmdName("Quad Command Page Program"), .cmdCode('h02), .withAddr(0), .with2Addr(0), .with4Addr(1))
    
    CUIDEC_pageProgramquad (!busy && WriteAccessOn && protocol=="quad" && !deep_power_down);



`ifdef SubSect

CUIdecoder   

    #(.cmdName("Subsector Erase"), .cmdCode('h20), .withAddr(1), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_subsectorErase (!busy && WriteAccessOn && !deep_power_down);    

`endif



CUIdecoder   

    #(.cmdName("Sector Erase"), .cmdCode('hD8), .withAddr(1), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_sectorErase (!busy && WriteAccessOn && !deep_power_down);


CUIdecoder   

    #(.cmdName("Bulk Erase"), .cmdCode('hC7), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_bulkErase (!busy && WriteAccessOn && !deep_power_down);


`ifdef PowDown

CUIdecoder   

    #(.cmdName("Deep Power Down"), .cmdCode('hB9), .withAddr(0), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_deepPowerDown (!busy && !deep_power_down && ReadAccessOn);  

CUIdecoder   

    #(.cmdName("Release Deep Power Down"), .cmdCode('hAB), .withAddr(0), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_releaseDeepPowerDown (!busy && ReadAccessOn);    

`endif


`ifdef RESET_software 

CUIdecoder 

    #(.cmdName("Reset Enable"), .cmdCode('h66), .withAddr(0), .with2Addr(0), .with4Addr(0))
   
    CUIDEC_resetEnable(!XIP && WriteAccessOn);


 CUIdecoder    

    #(.cmdName("Reset"), .cmdCode('h99), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_reset (!XIP && WriteAccessOn);

`endif
    


CUIdecoder   

    #(.cmdName("Read OTP"), .cmdCode('h4B), .withAddr(1), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_read_OTP (!busy && ReadAccessOn && protocol=="extended" );

CUIdecoder   

    #(.cmdName("Program OTP"), .cmdCode('h42), .withAddr(1), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_prog_OTP (!busy && WriteAccessOn && protocol=="extended");   

CUIdecoder   

    #(.cmdName("Read OTP"), .cmdCode('h4B), .withAddr(0), .with2Addr(1), .with4Addr(0))
   
    CUIDEC_read_OTPDual (!busy && ReadAccessOn && protocol=="dual" );

CUIdecoder   

    #(.cmdName("Program OTP"), .cmdCode('h42), .withAddr(0), .with2Addr(1), .with4Addr(0))
  
    CUIDEC_prog_OTPDual (!busy && WriteAccessOn && protocol=="dual");   

CUIdecoder   

    #(.cmdName("Read OTP"), .cmdCode('h4B), .withAddr(0), .with2Addr(0), .with4Addr(1))
   
    CUIDEC_read_OTPQuad (!busy && ReadAccessOn && protocol=="quad" );

CUIdecoder   

    #(.cmdName("Program OTP"), .cmdCode('h42), .withAddr(0), .with2Addr(0), .with4Addr(1))
  
    CUIDEC_prog_OTPQuad (!busy && WriteAccessOn && protocol=="quad");   




CUIdecoder   

    #(.cmdName("Dual Output Fast Read"), .cmdCode('h3B), .withAddr(1), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_readDual (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder   

    #(.cmdName("Dual Command Fast Read"), .cmdCode('h3B), .withAddr(0), .with2Addr(2), .with4Addr(0))
   
    CUIDEC_readDualDual (!busy && ReadAccessOn && protocol=="dual");


CUIdecoder   

    #(.cmdName("Dual Program"), .cmdCode('hA2), .withAddr(1), .with2Addr(0), .with4Addr(0))
  
    CUIDEC_programDual (!busy && WriteAccessOn && protocol=="extended");

CUIdecoder   

    #(.cmdName("Dual Command Page Program"), .cmdCode('hA2), .withAddr(0), .with2Addr(1), .with4Addr(0))
    
    CUIDEC_programDualDual (!busy && WriteAccessOn && protocol=="dual");


    


CUIdecoder   

    #(.cmdName("Dual I/O Fast Read"), .cmdCode('hBB), .withAddr(0), .with2Addr(1), .with4Addr(0))
  
    CUIDEC_readDualIo (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder   

    #(.cmdName("Dual Command Fast Read"), .cmdCode('hBB), .withAddr(0), .with2Addr(1), .with4Addr(0))
    
    CUIDEC_readDualIoDual (!busy && ReadAccessOn && protocol=="dual");


CUIdecoder   

    #(.cmdName("Dual Extended Program"), .cmdCode('hD2), .withAddr(0), .with2Addr(1), .with4Addr(0))
  
    CUIDEC_programDualExtended (!busy && WriteAccessOn  && protocol=="extended");

CUIdecoder   

    #(.cmdName("Dual Command Page Program"), .cmdCode('hD2), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_programDualExtendedDual (!busy && WriteAccessOn  && protocol=="dual");

 


CUIdecoder   

    #(.cmdName("Quad Output Read"), .cmdCode('h6B), .withAddr(1), .with2Addr(0), .with4Addr(0))
        
    CUIDEC_readQuad (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder   

    #(.cmdName("Quad Command Fast Read"), .cmdCode('h6B), .withAddr(0), .with2Addr(0), .with4Addr(1))
          
    CUIDEC_readQuadQuad (!busy && ReadAccessOn && protocol=="quad");


CUIdecoder   

    #(.cmdName("Quad I/O Fast Read"), .cmdCode('hEB), .withAddr(0), .with2Addr(0), .with4Addr(1))
                
    CUIDEC_readQuadIo (!busy && ReadAccessOn && protocol=="extended");
                                

CUIdecoder   

    #(.cmdName("Quad Command Fast Read"), .cmdCode('hEB), .withAddr(0), .with2Addr(0), .with4Addr(1))
          
    CUIDEC_readQuadIoQuad (!busy && ReadAccessOn && protocol=="quad");



CUIdecoder   

    #(.cmdName("Quad Program"), .cmdCode('h32), .withAddr(1), .with2Addr(0), .with4Addr(0))
                      
    CUIDEC_programQuad (!busy && WriteAccessOn && protocol=="extended");

CUIdecoder   

    #(.cmdName("Quad Command Page Program"), .cmdCode('h32), .withAddr(0), .with2Addr(0), .with4Addr(1))
                      
    CUIDEC_programQuadQuad (!busy && WriteAccessOn && protocol=="quad");


CUIdecoder   

    #(.cmdName("Quad Extended Program"), .cmdCode('h12), .withAddr(0), .with2Addr(0), .with4Addr(1))
                      
    CUIDEC_programQuadExtended (!busy && WriteAccessOn && protocol=="extended");

CUIdecoder   

    #(.cmdName("Quad Command Page Program"), .cmdCode('h12), .withAddr(0), .with2Addr(0), .with4Addr(1))
                       
    CUIDEC_programQuadExtendedQuad (!busy && WriteAccessOn && protocol=="quad");


CUIdecoder   

    #(.cmdName("Program Erase Resume"), .cmdCode('h7A), .withAddr(0), .with2Addr(0), .with4Addr(0))
                              
    CUIDEC_programEraseResume (WriteAccessOn);
                                        


CUIdecoder   

    #(.cmdName("Program Erase Suspend"), .cmdCode('h75), .withAddr(0), .with2Addr(0), .with4Addr(0))
                                        
    CUIDEC_programEraseSuspend (WriteAccessOn);
                                                                                         
                                                                                         
                                                  
`ifdef byte_4

CUIdecoder   

    #(.cmdName("Enable 4 Byte Address"), .cmdCode('hB7), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_enable4 (!busy && ReadAccessOn && !deep_power_down);


CUIdecoder   

    #(.cmdName("Exit 4 Byte Address"), .cmdCode('hE9), .withAddr(0), .with2Addr(0), .with4Addr(0))
    
    CUIDEC_exit4 (!busy && WriteAccessOn && !deep_power_down);

`endif

// DTR commands
CUIdecoder

    #(.cmdName("Read Fast DTR"), .cmdCode('h0D), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readFastDTR (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);

CUIdecoder

    #(.cmdName("Dual Command Fast Read DTR"), .cmdCode('h0D), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readFastdualDTR (!busy && ReadAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder

    #(.cmdName("Quad Command Fast Read DTR"), .cmdCode('h0D), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readFastquadDTR (!busy && ReadAccessOn && protocol=="quad" && !deep_power_down);


CUIdecoder

    #(.cmdName("Extended command DOFRDTR"), .cmdCode('h3D), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readDualDTR (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Dual Command DOFRDTR"), .cmdCode('h3D), .withAddr(0), .with2Addr(2), .with4Addr(0))

    CUIDEC_readDualDualDTR (!busy && ReadAccessOn && protocol=="dual");


CUIdecoder

    #(.cmdName("Extended command DIOFRDTR"), .cmdCode('hBD), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readDualIoDTR (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Dual Command DIOFRDTR"), .cmdCode('hBD), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readDualIoDualDTR (!busy && ReadAccessOn && protocol=="dual");


CUIdecoder

    #(.cmdName("Extended command QOFRDTR"), .cmdCode('h6D), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readQuadDTR (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Quad Command QOFRDTR"), .cmdCode('h6D), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadQuadDTR (!busy && ReadAccessOn && protocol=="quad");

CUIdecoder

    #(.cmdName("Extended command QIOFRDTR"), .cmdCode('hED), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadIoDTR (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Quad Command QIOFRDTR"), .cmdCode('hED), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadIoQuadDTR (!busy && ReadAccessOn && protocol=="quad");

// 4BYTE commands
CUIdecoder   

    #(.cmdName("Read"), .cmdCode('h13), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_read4addr (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);


CUIdecoder   

    #(.cmdName("Read Fast"), .cmdCode('h0C), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readFast4addr (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);

CUIdecoder

    #(.cmdName("Dual Command Fast Read"), .cmdCode('h0C), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readFastdual4addr (!busy && ReadAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder

    #(.cmdName("Quad Command Fast Read"), .cmdCode('h0C), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readFastquad4addr (!busy && ReadAccessOn && protocol=="quad" && !deep_power_down);


CUIdecoder

    #(.cmdName("Dual Output Fast Read"), .cmdCode('h3C), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readDual4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Dual Command Fast Read"), .cmdCode('h3C), .withAddr(0), .with2Addr(2), .with4Addr(0))

    CUIDEC_readDualDual4addr (!busy && ReadAccessOn && protocol=="dual");


CUIdecoder

    #(.cmdName("Dual I/O Fast Read"), .cmdCode('hBC), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readDualIo4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Dual Command Fast Read"), .cmdCode('hBC), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readDualIoDual4addr (!busy && ReadAccessOn && protocol=="dual");

CUIdecoder

    #(.cmdName("Quad Output Read"), .cmdCode('h6C), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readQuad4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Quad Command Fast Read"), .cmdCode('h6C), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadQuad4addr (!busy && ReadAccessOn && protocol=="quad");


CUIdecoder

    #(.cmdName("Quad I/O Fast Read"), .cmdCode('hEC), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadIo4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Quad Command Fast Read"), .cmdCode('hEC), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadIoQuad4addr (!busy && ReadAccessOn && protocol=="quad");

CUIdecoder

    #(.cmdName("Read Fast DTR"), .cmdCode('h0E), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readFastDTR4addr (!busy && ReadAccessOn && protocol=="extended" && !deep_power_down);

CUIdecoder

    #(.cmdName("Dual Command Fast Read DTR"), .cmdCode('h0E), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readFastdualDTR4addr (!busy && ReadAccessOn && protocol=="dual" && !deep_power_down);

CUIdecoder

    #(.cmdName("Quad Command Fast Read DTR"), .cmdCode('h0E), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readFastquadDTR4addr (!busy && ReadAccessOn && protocol=="quad" && !deep_power_down);

// CUIdecoder
// 
//     #(.cmdName("Extended command DOFRDTR"), .cmdCode('h3E), .withAddr(1), .with2Addr(0), .with4Addr(0))
// 
//     CUIDEC_readDualDTR4addr (!busy && ReadAccessOn && protocol=="extended");
// 
// CUIdecoder
// 
//     #(.cmdName("Dual Command DOFRDTR"), .cmdCode('h3E), .withAddr(0), .with2Addr(2), .with4Addr(0))
// 
//     CUIDEC_readDualDualDTR4addr (!busy && ReadAccessOn && protocol=="dual");

CUIdecoder

    #(.cmdName("Extended command DOFRDTR"), .cmdCode('h39), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readDualDTR4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Dual Command DOFRDTR"), .cmdCode('h39), .withAddr(0), .with2Addr(2), .with4Addr(0))

    CUIDEC_readDualDualDTR4addr (!busy && ReadAccessOn && protocol=="dual");

CUIdecoder

    #(.cmdName("Extended command DIOFRDTR"), .cmdCode('hBE), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readDualIoDTR4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Dual Command DIOFRDTR"), .cmdCode('hBE), .withAddr(0), .with2Addr(1), .with4Addr(0))

    CUIDEC_readDualIoDualDTR4addr (!busy && ReadAccessOn && protocol=="dual");

// CUIdecoder
// 
//     #(.cmdName("Extended command QOFRDTR"), .cmdCode('h6E), .withAddr(1), .with2Addr(0), .with4Addr(0))
// 
//     CUIDEC_readQuadDTR4addr (!busy && ReadAccessOn && protocol=="extended");
// 
// CUIdecoder
// 
//     #(.cmdName("Quad Command QOFRDTR"), .cmdCode('h6E), .withAddr(0), .with2Addr(0), .with4Addr(1))
// 
//     CUIDEC_readQuadQuadDTR4addr (!busy && ReadAccessOn && protocol=="quad");

CUIdecoder

    #(.cmdName("Extended command QOFRDTR"), .cmdCode('h3A), .withAddr(1), .with2Addr(0), .with4Addr(0))

    CUIDEC_readQuadDTR4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Quad Command QOFRDTR"), .cmdCode('h3A), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadQuadDTR4addr (!busy && ReadAccessOn && protocol=="quad");

CUIdecoder

    #(.cmdName("Extended command QIOFRDTR"), .cmdCode('hEE), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadIoDTR4addr (!busy && ReadAccessOn && protocol=="extended");

CUIdecoder

    #(.cmdName("Quad Command QIOFRDTR"), .cmdCode('hEE), .withAddr(0), .with2Addr(0), .with4Addr(1))

    CUIDEC_readQuadIoQuadDTR4addr (!busy && ReadAccessOn && protocol=="quad");

`ifdef Stack512Mb
  CUIdecoder   
  
      #(.cmdName("Die Erase"), .cmdCode('hC4), .withAddr(0), .with2Addr(0), .with4Addr(0))
                                          
      CUIDEC_dieErase (WriteAccessOn);
`endif

// CUIdecoder   
// 
//     #(.cmdName("Page Program"), .cmdCode('h14), .withAddr(1), .with2Addr(0), .with4Addr(0))
//     
//     CUIDEC_pageProgram4addr (!busy && WriteAccessOn && protocol=="extended" && !deep_power_down);
// 
// CUIdecoder   
// 
//     #(.cmdName("Dual Command Page Program"), .cmdCode('h14), .withAddr(0), .with2Addr(1), .with4Addr(0))
//     
//     CUIDEC_pageProgramdual4addr (!busy && WriteAccessOn && protocol=="dual" && !deep_power_down);
// 
// CUIdecoder   
// 
//     #(.cmdName("Quad Command Page Program"), .cmdCode('h14), .withAddr(0), .with2Addr(0), .with4Addr(1))
//     
//     CUIDEC_pageProgramquad4addr (!busy && WriteAccessOn && protocol=="quad" && !deep_power_down);
// 
// CUIdecoder   
// 
//     #(.cmdName("Dual Program"), .cmdCode('hA3), .withAddr(1), .with2Addr(0), .with4Addr(0))
//   
//     CUIDEC_programDual4addr (!busy && WriteAccessOn && protocol=="extended");
// 
// CUIdecoder   
// 
//     #(.cmdName("Dual Command Page Program"), .cmdCode('hA3), .withAddr(0), .with2Addr(1), .with4Addr(0))
//     
//     CUIDEC_programDualDual4addr (!busy && WriteAccessOn && protocol=="dual");
// 
// CUIdecoder   
// 
//     #(.cmdName("Dual Extended Program"), .cmdCode('hD3), .withAddr(0), .with2Addr(1), .with4Addr(0))
//   
//     CUIDEC_programDualExtended4addr (!busy && WriteAccessOn  && protocol=="extended");
// 
// CUIdecoder   
// 
//     #(.cmdName("Dual Command Page Program"), .cmdCode('hD3), .withAddr(0), .with2Addr(1), .with4Addr(0))
// 
//     CUIDEC_programDualExtendedDual4addr (!busy && WriteAccessOn  && protocol=="dual");
// 




//---------------------------
// Modules istantiations
//---------------------------

Memory          mem (memory_file);

UtilFunctions   f ();

Program         prog ();

StatusRegister  stat ();

FlagStatusRegister flag ();

NonVolatileConfigurationRegister  NonVolatileReg (NVConfigReg_default);

VolatileEnhancedConfigurationRegister VolatileEnhReg ();

VolatileConfigurationRegister VolatileReg ();

`ifdef byte_4

ExtendedAddressRegister ExtAddReg ();

`endif

FlashDiscoveryParameter FlashDiscPar (fdp_file);

Read            read ();        

LockManager     lock ();

ProtectionManagementRegister PMReg(); // instantiated the protection management register -- 

`ifdef timingChecks
 
 `ifdef N25Q256A33E 
  TimingCheck     timeCheck (S, C, DQ0, DQ1, W_int, RESET);
  `elsif  N25Q256A31E 
  TimingCheck     timeCheck (S, C, DQ0, DQ1, W_int, RESET);
  `elsif  N25Q256A31E
  TimingCheck     timeCheck (S, C, DQ0, DQ1, W_int, HOLD_DQ3);
  `elsif  N25Q256A11E
  TimingCheck     timeCheck (S, C, DQ0, DQ1, W_int, HOLD_DQ3);
  `elsif  N25Q032A13E
  TimingCheck     timeCheck (S, C, DQ0, DQ1, W_int, HOLD_DQ3);
  `elsif N25Q032A11E
  TimingCheck     timeCheck (S, C, DQ0, DQ1, W_int, HOLD_DQ3);
  `elsif  N25Q256A13E
  TimingCheck     timeCheck (S, C, DQ0, DQ1, W_int, HOLD_DQ3);
 `endif

`endif  

`ifdef HOLD_pin

 DualQuadOps     dualQuad (S, C, ck_count,DoubleTransferRate, DQ0, DQ1, Vpp_W_DQ2, HOLD_DQ3); 

 `elsif RESET_pin
 
 DualQuadOps     dualQuad (S, C, ck_count,DoubleTransferRate, DQ0, DQ1, Vpp_W_DQ2, RESET_DQ3); 
 
 `endif

  OTP_memory      OTP (); 






//----------------------------------
//  Signals for latching control
//----------------------------------

integer iCmd, iAddr, iData, iDummy;
reg dtr_dout_started; // it is set after negedge C where 1st bit was outputted (used to prevent DUT from starting data output on posedge C)

always @(negedge S) begin : CP_latchInit

    if (!XIP) latchingMode = "C";  
    
    ck_count = 0;
    iCmd = cmdDim - 1;
    `ifdef byte_4
    if (prog.enable_4Byte_address) iAddr = addrDimLatch4 - 1;
    else iAddr = addrDimLatch - 1;
    `else
     iAddr = addrDimLatch - 1; 
    `endif
    iData = dataDim - 1;

    iDummy = dummyDimEff - 1;
    dtr_dout_started = 0;   //DTR
end


always @(posedge C) if(logicOn) begin
    ck_count = ck_count + 1;

end

always @(posedge read_enable) begin
  ck_count = 0;
end


//-------------------------
// Latching commands
//-------------------------


event cmdLatched;


always @(C) if(logicOn && latchingMode=="C" && protocol=="extended") begin : CP_latchCmd
  if (C==1) begin  
  // if (((C==0) && (VolatileEnhReg.VECR[5] == 0) && (iCmd != 7)) || (C == 1)) begin 

    cmd[iCmd] = DQ0;

    if (iCmd>0)
        iCmd = iCmd - 1;
    else if(iCmd==0) begin
        latchingMode = "N";
        -> cmdLatched;
    end    
 end        
end

always @(C) if(logicOn && latchingMode=="C" && protocol=="dual") begin : CP_latchCmdDual
  if (C==1) begin  
  // if (((C==0) && (VolatileEnhReg.VECR[5] == 0) && (iCmd != 7)) || (C == 1)) begin 


    cmd[iCmd] = DQ1;
    cmd[iCmd-1] = DQ0;

    if (iCmd>=3)
        iCmd = iCmd - 2;
    else if(iCmd==1) begin
        latchingMode = "N";
        -> cmdLatched;
    end    
  end       
end


`ifdef HOLD_pin
always @(C) if(logicOn && latchingMode=="C" && protocol=="quad") begin : CP_latchCmdQuad
  if (C==1) begin  
  // if (((C==0) && (VolatileEnhReg.VECR[5] == 0) && (iCmd != 7)) || (C == 1)) begin 

    cmd[iCmd] = HOLD_DQ3;
    cmd[iCmd-1] = Vpp_W_DQ2;
    cmd[iCmd-2] = DQ1;
    cmd[iCmd-3] = DQ0;

    if (iCmd>=7)
        iCmd = iCmd - 4;
    else if(iCmd==3) begin
        latchingMode = "N";
        -> cmdLatched;
    end    
  end      
end

`elsif RESET_pin

always @(C) if(logicOn && latchingMode=="C" && protocol=="quad") begin : CP_latchCmdQuad
  if (C==1) begin 
  // if (((C==0) && (VolatileEnhReg.VECR[5] == 0) && (iCmd != 7)) || (C == 1)) begin 

    cmd[iCmd] = RESET_DQ3;
    cmd[iCmd-1] = Vpp_W_DQ2;
    cmd[iCmd-2] = DQ1;
    cmd[iCmd-3] = DQ0;

    if (iCmd>=7)
        iCmd = iCmd - 4;
    else if(iCmd==3) begin
        latchingMode = "N";
        -> cmdLatched;
    end    
  end        
end

`endif
//-------------------------
// Latching address
//-------------------------


event addrLatched;


always @(C) if (logicOn && latchingMode=="A") begin : CP_latchAddr
  if (C==1 || DoubleTransferRate==1 || 
    (C==0 && (cmd=='h0D || cmd=='h3D || cmd=='hBD || cmd=='h6D || cmd=='hED || cmd=='h0E || cmd=='h39 || cmd=='hBE || cmd=='h3A || cmd=='hEE)
    // (C==0 && (cmd=='h0D || cmd=='h3D || cmd=='hBD || cmd=='h6D || cmd=='hED || cmd=='h0E || cmd=='h3E || cmd=='hBE || cmd=='h6E || cmd=='hEE)
    && iAddr!=23 && iAddr!=31)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode, except for negedge C immediately following negedge S in XIP mode and also in negedge of DTR mode and when the command is (address and data in DTR mode ('h0D,'h3D,'h6D) 

    addrLatch[iAddr] = DQ0;
    if (iAddr>0)
        iAddr = iAddr - 1;
    else if(iAddr==0) begin
        latchingMode = "N";
        `ifdef byte_4
        if ((!prog.enable_4Byte_address) && (cmd != 'h13) && (cmd != 'h0C) && (cmd != 'h3C) && (cmd != 'h6C) && (cmd != 'h6C))
              addr = {ExtAddReg.EAR[EARvalidDim-1:0],addrLatch[addrDimLatch-1:0]};
          else 
              addr = addrLatch[addrDim-1:0];
        `else
        addr = addrLatch[addrDim-1:0];
        `endif
        -> addrLatched;
    end
  end
end



always @(C) if (logicOn && latchingMode=="I") begin : CP_latchAddrDual
  if (C==1 ||DoubleTransferRate==1 || (C==0 && (cmd=='h0D || cmd=='h3D ||
    cmd=='hBD || cmd=='h0E || cmd=='h39 || cmd=='hBE) && iAddr!=23 && iAddr!=31)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode, except for negedge C immediately follwing negedge S in XIP mode and also in negedge of DTR mode and when the command is (address and data in DTR mode ('hBD) 
    // cmd=='hBD || cmd=='h0E || cmd=='h3E || cmd=='hBE) && iAddr!=23 && iAddr!=31)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode, except for negedge C immediately follwing negedge S in XIP mode and also in negedge of DTR mode and when the command is (address and data in DTR mode ('hBD) 

    addrLatch[iAddr] = DQ1;
    addrLatch[iAddr-1]= DQ0;
    if (iAddr>=3)
        iAddr = iAddr - 2;
    else if(iAddr==1) begin
        latchingMode = "N";
        `ifdef byte_4
        if (!prog.enable_4Byte_address && (cmd != 'hBC)) addr = {ExtAddReg.EAR[EARvalidDim-1:0],addrLatch[addrDimLatch-1:0]};
           else addr = addrLatch[addrDim-1:0];
        `else
        addr = addrLatch[addrDim-1:0];
        `endif

        -> addrLatched;

    end
  end
end

`ifdef HOLD_pin
always @(C) if (logicOn && latchingMode=="E") begin : CP_latchAddrQuad
  if (C==1 ||DoubleTransferRate==1 || (C==0 && (cmd=='h0D || cmd=='h6D
    ||cmd=='hED || cmd=='h0E || cmd=='h3A ||cmd=='hEE) && iAddr!=23 && iAddr!=31)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode, except for negedge C immediately following negedge S in XIP mode and also in negedge of DTR mode and when the command is (address and data in DTR mode ('hED)
    // ||cmd=='hED || cmd=='h0E || cmd=='h6E ||cmd=='hEE) && iAddr!=23 && iAddr!=31)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode, except for negedge C immediately following negedge S in XIP mode and also in negedge of DTR mode and when the command is (address and data in DTR mode ('hED)

    addrLatch[iAddr] = HOLD_DQ3;
    addrLatch[iAddr-1]= Vpp_W_DQ2;
    addrLatch[iAddr-2]= DQ1;
    addrLatch[iAddr-3]= DQ0;
   
    if (iAddr>=7)
        iAddr = iAddr - 4;

    else if(iAddr==3) begin
        latchingMode = "N";
        `ifdef byte_4
        if (!prog.enable_4Byte_address && (cmd != 'hEC)) addr = {ExtAddReg.EAR[EARvalidDim-1:0],addrLatch[addrDimLatch-1:0]};
          else addr = addrLatch[addrDim-1:0];
        `else
        addr = addrLatch[addrDim-1:0];
        `endif


        -> addrLatched;
    end
  end
end

`elsif RESET_pin
always @(C) if (logicOn && latchingMode=="E") begin : CP_latchAddrQuad
  if (C==1 ||DoubleTransferRate==1 || (C==0 && (cmd=='h0D || cmd=='h6D ||cmd=='hED || cmd=='h0E || cmd=='h6E ||cmd=='hEE) && iAddr!=23 && iAddr!=31)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode, except for negedge C immediately following negedge S in XIP mode

    addrLatch[iAddr] = RESET_DQ3;
    addrLatch[iAddr-1]= Vpp_W_DQ2;
    addrLatch[iAddr-2]= DQ1;
    addrLatch[iAddr-3]= DQ0;
   
    if (iAddr>=7)
        iAddr = iAddr - 4;

    else if(iAddr==3) begin
        latchingMode = "N";
        `ifdef byte_4
        if (!prog.enable_4Byte_address && (cmd != 'hEC)) addr = {ExtAddReg.EAR[EARvalidDim-1:0],addrLatch[addrDimLatch-1:0]};
        else  addr = addrLatch[addrDim-1:0];
        `else
        addr = addrLatch[addrDim-1:0];
        `endif

        -> addrLatched;
    end
  end
end

`endif
//-----------------
// Latching data
//-----------------


event dataLatched;

always @(C) if (logicOn && latchingMode=="D") begin : CP_latchData
  if (C==1) begin // ENABLE if posedge C in all modes 
  // if (((C==0) && (VolatileEnhReg.VECR[5] == 0)) || (C == 1)) begin 


    data[iData] = DQ0;

    if (iData>0)
        iData = iData-1;
    else begin
     if (cmdRecName=="Write NV Configuration Reg" && prog.LSByte) begin
        LSdata=data;
         prog.LSByte=0;
     end   
        -> dataLatched;
        $display("  [%0t ns] Data latched: %h", $time, data);
        iData=dataDim-1;
    end    
  end
end






//-----------------
// Latching dummy
//-----------------


event dummyLatched;

always @(posedge C) if (logicOn && latchingMode=="Y") begin : CP_latchDummy
#0;
    dummy[iDummy] = DQ0;

    //XIP mode setting
`ifdef XIP_basic

    if(iDummy==dummyDimEff-1 &&  dummy[iDummy]==0) begin

        XIP=1;


    end else if (iDummy==dummyDimEff-1 &&  dummy[iDummy]==1) begin

        if (XIP) $display("  [%0t ns] XIP mode exit.", $time);
            XIP=0;

    end

//!    end     

 `elsif XIP_Numonyx
 
    if(iDummy==dummyDimEff-1 &&  dummy[iDummy]==0 && VolatileReg.VCR[3]==0) begin
    
        XIP=1; 
       

    end else if (iDummy==dummyDimEff-1 &&  dummy[iDummy]==1) begin
       
       if (XIP) $display("  [%0t ns] XIP mode exit.", $time);

        XIP=0;
    end    

 `endif  

    if (iDummy>0) begin 
        iDummy = iDummy-1;

        end  
        else begin
        -> dummyLatched;
        $display("  [%0t ns] Dummy clock cycles latched.", $time);
        iDummy=dummyDimEff-1;
        ck_count <= #1 0; // avoid race condition with ck_count auto-incrementer @(posedge C)
    end    

end



 

// check dummy clock cycles 

always @(dummyLatched) begin

    case (dummyDimEff)

        1: begin

            if(((fC>78) && (cmdRecName=="Read Fast" || cmdRecName=="Dual Output Fast Read")) ||
              ((fC>39) && (cmdRecName=="Dual I/O Fast Read" || cmdRecName=="Dual Command Fast Read")) ||
              ((fC>44) && (cmdRecName=="Quad Output Fast Read")) ||
              ((fC>20) && (cmdRecName=="Quad I/O Fast Read" || cmdRecName=="Quad Command Fast Read")))
               $display("  [%0t ns]  ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
        
           end

        2: begin

            if(((fC>98) && (cmdRecName=="Read Fast")) ||
              ((fC>88) && (cmdRecName=="Dual Output Fast Read")) ||
              ((fC>59) && (cmdRecName=="Dual I/O Fast Read" || cmdRecName=="Dual Command Fast Read")) ||
              ((fC>61) && (cmdRecName=="Quad Output Fast Read")) ||
              ((fC>39) && (cmdRecName=="Quad I/O Fast Read" || cmdRecName=="Quad Command Fast Read")))
               $display("  [%0t ns] ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
        
           end

        3: begin
             
              if(((fC>98) && (cmdRecName=="Dual Output Fast Read")) ||
                 ((fC>78) && (cmdRecName=="Dual I/O Fast Read" || cmdRecName=="Dual Command Fast Read" || cmdRecName=="Quad Output Fast Read")) ||
                 ((fC>49) && (cmdRecName=="Quad I/O Fast Read" || cmdRecName=="Quad Command Fast Read")))
               $display("  [%0t ns] ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
           end

        4 : begin
             
              if(((fC>88) && (cmdRecName=="Dual I/O Fast Read" || cmdRecName=="Dual Command Fast Read" || cmdRecName=="Quad Output Fast Read")) ||
                ((fC>59) && (cmdRecName=="Quad I/O Fast Read")))
                  $display("  [%0t ns] ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
           end

        
        5 : begin
             
              if(((fC>98) && (cmdRecName=="Dual I/O Fast Read" || cmdRecName=="Dual Command Fast Read" || cmdRecName=="Quad Output Fast Read")) ||
                ((fC>69) && (cmdRecName=="Quad I/O Fast Read" || cmdRecName=="Quad Command Fast Read")))
                  $display("  [%0t ns] ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
           end
        
        6 : begin
             if  ((fC>78) && (cmdRecName=="Quad I/O Fast Read" || cmdRecName=="Quad Command Fast Read"))
                  $display("  [%0t ns] ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
            end
        
        7 : begin
             if  ((fC>88) && (cmdRecName=="Quad I/O Fast Read" || cmdRecName=="Quad Command Fast Read"))
                  $display("  [%0t ns] ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
            end
        8 : begin
             if  ((fC>98) && (cmdRecName=="Quad I/O Fast Read" || cmdRecName=="Quad Command Fast Read"))
                  $display("  [%0t ns] ==ERROR== Dummy clock number is not sufficient for the operating frequency. The memory reads wrong data",$time);
            end
 
            
        default : begin end
                        
    endcase
 
end

// `ifdef Stack512Mb
// //------------------------------
// // Calculating device select during stacked die
// // die active indicates the die selected
// //------------------------------
// 
// always@(addrLatched) begin
//   if((prog.enable_4Byte_address == 1) || (NonVolatileReg.NVCR[0] == 0)) begin
//     if(rdeasystacken == addr[addrDim +1: addrDim]) begin
//       die_active = 1;
//     end
//     else begin
//       die_active = 0;
//     end
//   end
//   else begin
//     if(rdeasystacken == ExtAddReg.EAR[1:0]) begin
//       die_active = 1;
//     end
//     else begin
//       die_active = 0;
//     end
//   end
// end
// 
// `endif


//------------------------------
// Commands recognition control
//------------------------------


event codeRecognized, seqRecognized, startCUIdec;








always @(cmdLatched) fork : CP_cmdRecControl

    -> startCUIdec; // i CUI decoders si devono attivare solo dopo
                    // che e' partito il presente processo
                    // NB: l'attivazione dell'evento startCUIdec fa partire i CUIdec
                    // immediatamente (nello stesso delta time in cui si attiva l'evento),
                    // e non nel delta time successivo


    begin : ok
        @(codeRecognized or seqRecognized) 
          disable error;
    end

    ///////////////////////////////////////////////////////  
     // adding to fix the 4 byte address problem
     // if the cmd is 4 byte address,the counter for address
     // is reinitialised to 32 bit. // added  
     ///////////////////////////////////////////////////////
 
    begin
         
         if (cmd == 'h13 || cmd  == 'h0C || cmd == 'h3C || cmd == 'hBC || 
           // cmd == 'h6C ||  cmd == 'h0E ||  cmd == 'h3E || cmd == 'hBE || 
           cmd == 'h6C ||  cmd == 'h0E ||  cmd == 'h39 || cmd == 'hBE || 
           // cmd == 'h6E || cmd == 'hEE || cmd == 'hEC || cmd == 'h10 || 
           cmd == 'h3A || cmd == 'hEE || cmd == 'hEC || cmd == 'h10 || 
           cmd == 'h11 || cmd == 'h27 )
           begin
            iAddr = addrDimLatch4 - 1;
           end
          else if(cmd == 'h5A) begin
            iAddr = addrDimLatch - 1;
          end
    end 
     
    ///////////////////////////////////////////////////////    
     

    
    
    begin : error
        #0; 
        #0; //wait until CUI decoders execute recognition process (2 delta time maximum)
            //questo secondo ritardo si puo' anche togliere (perche' il ritardo max e' 1 delta)
        if (busy)   
            $display("[%0t ns] **WARNING** Device is busy. Command not accepted.", $time);
            `ifdef PowDown
         else if (deep_power_down)
            $display("[%0t ns] **WARNING** Deep power down mode. Command not accepted.", $time);
            `endif 
        else if (!ReadAccessOn || !WriteAccessOn || !PollingAccessOn) 
            $display("[%0t ns] **WARNING** Power up is ongoing. Command not accepted.", $time);    
        else if (!busy)  
            $display("[%0t ns] **ERROR** Command Not Recognized.", $time);
        disable ok;
    end    

join



//------------------------------------
// Power Up, Fast POR & Voltage check
//------------------------------------



//--- Reset internal logic (latching disabled when Vcc<Vcc_wi)

assign Vcc_L1 = (Vcc>=Vcc_wi) ?  1 : 0 ;

always @Vcc_L1 
  if (reset_by_powerOn && Vcc_L1)
    reset_by_powerOn = 0;
  else if (!reset_by_powerOn && !Vcc_L1) 
    reset_by_powerOn = 1;
    


assign Vcc_L2 = (Vcc>=Vcc_min) ?  1 : 0 ;



event checkProtocol;

event checkHoldResetEnable;

event checkAddressMode;

event checkAddressSegment;

event checkDummyClockCycle;

//--- Write access

reg WriteAccessCondition = 0;


//----------------------------
// Power Up  
//----------------------------


always @Vcc_L2 if(Vcc_L2 && PollingAccessOn==0 && ReadAccessOn==0 && WriteAccessCondition==0) fork : CP_powUp_FullAccess
    
    begin : p1
      $display("[%0t ns] ==INFO== Power up: polling allowed.",$time );
      PollingAccessOn=1;
      
      #full_access_power_up_delay;
      $display("[%0t ns] ==INFO== Power up: device fully accessible.",$time );
      ReadAccessOn=1;
      WriteAccessCondition=1;
      // starting protocol defined by NVCR
      -> checkProtocol; 
      //checking hold_enable defined by NVCR
      -> checkHoldResetEnable;
      -> checkDummyClockCycle;
      //checking address mode
      `ifdef byte_4
      -> checkAddressMode;
      //checking address segment
      -> checkAddressSegment;
      `endif
            disable p2;
    end 

    begin : p2
      @Vcc_L2 if(!Vcc_L2)
        disable p1;
    end

join    

always @(checkDummyClockCycle) begin
    // if(NonVolatileReg.NVCR[15:12]=='b0000) dummyDimEff=15;
    if(NonVolatileReg.NVCR[15:12]=='b0000) dummyDimEff=8;
    else if(NonVolatileReg.NVCR[15:12]=='b1111) dummyDimEff=8;
    else  dummyDimEff=NonVolatileReg.NVCR[15:12];

end

always @(checkHoldResetEnable) begin

 if (NonVolatileReg.NVCR[4]==1) NVCR_HoldResetEnable=1;
 else NVCR_HoldResetEnable=0;

end

`ifdef byte_4

always @(checkAddressMode) begin

 if (NonVolatileReg.NVCR[0]==0)  begin
 
      prog.enable_4Byte_address=1;
      $display("[%0t ns] ==INFO== 4-byte address mode selected",$time);
 
       
 end else begin 
      
       prog.enable_4Byte_address=0;
       $display("[%0t ns] ==INFO== 3-byte address mode selected",$time);

 end

end

always @(checkAddressSegment) if (prog.enable_4Byte_address==0) begin

 if (NonVolatileReg.NVCR[1]==0) begin
 
    ExtAddReg.EAR[EARvalidDim-1:0]={EARvalidDim{1'b1}};
    if(prog.enable_4Byte_address==0) $display("[%0t ns] ==INFO== Top 128M selected",$time);
 
 end else begin
    
    ExtAddReg.EAR[EARvalidDim-1:0]=0;
    if(prog.enable_4Byte_address==0) $display("[%0t ns] ==INFO== Bottom 128M selected",$time);
    
 end
 
end 

`endif
assign WriteAccessOn =PollingAccessOn && ReadAccessOn && WriteAccessCondition;


always @(checkProtocol) begin
if (NonVolatileReg.NVCR[3]==0) protocol="quad";
      else if (NonVolatileReg.NVCR[2]==0) protocol="dual";
      else if(NonVolatileReg.NVCR[3]==1 && NonVolatileReg.NVCR[2]==1) protocol="extended";
      $display("[%0t ns] ==INFO== Protocol selected is %0s",$time, protocol);
      

 

       case (NonVolatileReg.NVCR[11:9])
       'b000 : begin
                XIP=1;
                protocol="extended";
                cmdRecName="Read Fast";
               end
        
       'b001 : begin 
                 XIP=1;
                 cmdRecName="Dual Output Fast Read"; 
                 protocol="extended";
               end
       'b010 : begin
                 XIP=1;
                 cmdRecName="Dual I/O Fast Read";
                 protocol="dual";
               end
 
       'b011 : begin
                 XIP=1;
                 cmdRecName="Quad Output Read"; 
                 protocol="extended";
               end

       'b100 :  begin
                 XIP=1;
                 cmdRecName="Quad I/O Fast Read"; 
                 protocol="quad";
               end

       'b111: XIP=0;
         default : XIP=0;
       endcase  
       
      // DoubleTransferRate = !NonVolatileReg.NVCR[5];
      $display("[%0t ps] ==INFO== %0s Transfer Rate selected", $time, (DoubleTransferRate ? "Double" : "Single"));
      
end

//---Dummy clock cycle

always @VolatileReg.VCR begin
    if (VolatileReg.VCR[7:4]=='b0000) dummyDimEff=8;
    else if (VolatileReg.VCR[7:4]=='b1111) dummyDimEff=8;
    else dummyDimEff=VolatileReg.VCR[7:4];

end


//--- Voltage drop (power down)

always @Vcc_L1 if (!Vcc_L1 && (PollingAccessOn|| ReadAccessOn || WriteAccessCondition)) begin : CP_powerDown
    $display("[%0t ns] ==INFO== Voltage below the threshold value: device not accessible.", $time);
    ReadAccessOn=0;
    WriteAccessCondition=0;
    PollingAccessOn=0;
    prog.Suspended=0; //the suspended state is reset  
    
end    




//--- Voltage fault (used during program and erase operations)

event voltageFault; //used in Program and erase dynamic check (see also "CP_voltageCheck" process)

assign VccOk = (Vcc>=Vcc_min && Vcc<=Vcc_max) ?  1 : 0 ;

always @VccOk if (!VccOk) ->voltageFault; //check is active when device is not reset
                                          //(this is a dynamic check used during program and erase operations)
        






//---------------------------------
// Vpp (auxiliary voltage) checks
//---------------------------------

//VPP pin Enhanced Supply Voltage feature not implemented



                   

//-----------------
// Read execution
//-----------------


reg [addrDim-1:0] readAddr;
reg bitOut='hZ;
reg [1:0] firstNVCR = 1;

event sendToBus;
event sendToBus_stack;


// values assumed by DQ0 and DQ1, when they are not forced
assign DQ0 = 1'bZ;
assign DQ1 = 1'bZ;


//  DQ1 : release of values assigned with "force statement"
always @(posedge S) begin
        quadMode  = 0; // reset the quadmode on every posedge of S

        #tSHQZ release DQ1; 
        if (protocol=="dual" || read.enable_dual) release Vpp_W_DQ2;
        if (protocol=="quad" || read.enable_quad) begin 
            
                        release Vpp_W_DQ2;
                        `ifdef RESET_pin
                        release RESET_DQ3;
                        `elsif HOLD_pin
                        release HOLD_DQ3;
                        `endif
        end
        if(DoubleTransferRate == 1) release DQ0;

        firstNVCR = 1; // resets to default value

end        
// effect on DQ1 by HOLD signal
`ifdef HOLD_pin
    
    reg temp;
    
    always @(intHOLD) if(intHOLD===0) begin : CP_HOLD_out_effect 
        
        begin : out_effect
            temp = DQ1;
            #tHLQZ;
            disable guardian;
            release DQ1;
            // @(posedge intHOLD) #tHHQX force DQ1=temp;
        end  

        begin : guardian 
            @(posedge intHOLD)
            disable out_effect;
        end
        
    end   

`endif    



// read with DQ1 out bit

always @(negedge C) if(logicOn && protocol=="extended") begin : CP_read
    singleIO_output(ck_count * ((DoubleTransferRate || ((cmd == 'h0D || cmd == 'h0E) ? 1:0))+1)); // 2*ck_count if DTR and cmd is 0D, O.W. 1*ck_count
end

always @(posedge C) if(logicOn) begin
    if ((DoubleTransferRate || ((cmd == 'h0D || cmd == 'h0E) ? 1:0)) && protocol=="extended" && dtr_dout_started) begin
    singleIO_output(2*(ck_count -1) + 1);
    end
    if ((DoubleTransferRate || ((cmd == 'h0D || cmd == 'h0E) ? 1:0)) && !dtr_dout_started && latchingMode == "N") begin
    // Difference is caused by fact that in DTR, last instr/addr/data bit is latched on negedge clk, but last dummy bit is latched on posedge clk
    // So, in read instr that do not need dummy cycles, data output starts on the negedge following this posedge clk -> do not increment counter
    end else begin
    //RK ck_count = ck_count + 1; // combined 2 always blks to avoid race conditions
    end
end
//RK  always @(negedge(C)) if(logicOn && protocol=="extended") begin : CP_read
//RK    singleIO_output(ck_count * (((cmd == 'h0D) ? 1:0)+1)); // 2*ck_count if DTR and cmd is 0D, O.W. 1*ck_count
//RK  end
//RK 
//RK  always @(posedge C) if(logicOn) begin
//RK     if (((cmd == 'h0D) ? 1:0) && protocol=="extended" && dtr_dout_started) begin
//RK    singleIO_output(2*ck_count + 1);
//RK     end
//RK     if (((cmd == 'h0D) ? 1:0) && !dtr_dout_started && latchingMode == "N") begin
//RK    // Difference is caused by fact that in DTR, last instr/addr/data bit is latched on negedge clk, but last dummy bit is latched on posedge clk
//RK    // So, in read instr that do not need dummy cycles, data output starts on the negedge following this posedge clk -> do not increment counter
//RK     end else begin
//RK    ck_count = ck_count + 1; // combined 2 always blks to avoid race conditions
//RK     end
//RK  end



task singleIO_output;
input [2:0] bit_count;
begin
  #1;
    // $display("In singleIO_output: ck_count=%h", bit_count, $time);
    if(read.enable==1 || read.enable_fast==1) begin    
        
        if(bit_count==0) begin
            readAddr = mem.memAddr;
            mem.readData(dataOut); //read data and increments address
            f.out_info(readAddr, dataOut);
        end
        
        #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;
    
    end else if (read.enable_rsfdp==1) begin
       
        if(bit_count==0) begin
                readAddr = FlashDiscPar.fdpAddr;
                FlashDiscPar.readData(dataOut); //read data and increments address
                f.out_info(readAddr, dataOut);
        end
          
         #tCLQX
          bitOut = dataOut[dataDim-1-bit_count];
          -> sendToBus;


    end else if (stat.enable_SR_read==1) begin
        
        if(bit_count==0) begin
            dataOut = stat.SR;
            f.out_info(readAddr, dataOut);
        end    
       
       #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;

     end else if (flag.enable_FSR_read==1) begin
        
        if(bit_count==0) begin

            dataOut = flag.FSR;
            f.out_info(readAddr, dataOut);
        end    
       
       #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;

     end else if (VolatileReg.enable_VCR_read==1) begin
        
       if(bit_count==0) begin

            dataOut = VolatileReg.VCR;
            f.out_info(readAddr, dataOut);
       end    
       
        #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;

    // added   to check for PMR register read
     end else if (PMReg.enable_PMR_read==1) begin
        
        if(bit_count==0) begin
            dataOut = PMReg.PMR;
            f.out_info(readAddr, dataOut);
        end    
        
        #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;

     end else if (flag.enable_FSR_read==1) begin
        
        if(bit_count==0) begin
            dataOut = flag.FSR;
            f.out_info(readAddr, dataOut);
        end    
        
        #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;    
     end else if (VolatileEnhReg.enable_VECR_read==1) begin
        
       if(bit_count==0) begin

            dataOut = VolatileEnhReg.VECR;
            f.out_info(readAddr, dataOut);
        end    
        
        #tCLQX
        // $display("In VECR Read: dataOut=%h, bitOut=%h ", dataOut, bitOut, $time);
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;
    

     end else if (NonVolatileReg.enable_NVCR_read==1) begin
     
 
        if(bit_count==0 && firstNVCR == 1) begin
            
            dataOut = NonVolatileReg.NVCR[7:0];
            f.out_info(readAddr, dataOut);
            firstNVCR=0;
          
        end else if(bit_count==0 && firstNVCR == 0) begin
         
           dataOut = NonVolatileReg.NVCR[15:8];
           f.out_info(readAddr, dataOut);
           firstNVCR=2;
        end
        else if(bit_count==0  && firstNVCR == 2)begin
           dataOut = 0;
           f.out_info(readAddr, dataOut);
        end
       
        #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;

  `ifdef byte_4

  //modificare 
   end else if (ExtAddReg.enable_EAR_read==1) begin
        
        if(ck_count==0) begin
        
            dataOut = ExtAddReg.EAR[7:0];
            f.out_info(readAddr, dataOut);
            
        end
       
        #tCLQX
        bitOut = dataOut[dataDim-1-ck_count];
        -> sendToBus;

   `endif   
   end else if (lock.enable_lockReg_read==1) begin

          if(bit_count==0) begin 
              readAddr = f.sec(addr);
              f.out_info(readAddr, dataOut);
          end
          
          #tCLQX
          bitOut = dataOut[dataDim-1-bit_count];
          -> sendToBus;
    

    
   end else if (read.enable_OTP==1) begin 

          if(bit_count==0) begin
              readAddr = 'h0;
              readAddr = OTP.addr;
              OTP.readData(dataOut); //read data and increments address
              f.out_info(readAddr, dataOut);
          end
          
          #tCLQX
          bitOut = dataOut[dataDim-1-bit_count];
          -> sendToBus;

   
   
    end else if (read.enable_ID==1) begin // && protocol=="extended") begin 
        // $display("In READ_ID : bit_count=%h , rdaddr=%h ", bit_count, readAddr, $time);

        if(bit_count==0) begin
        
            readAddr = 'h0;
            readAddr = read.ID_index;
            
            if (read.ID_index==0)      dataOut=Manufacturer_ID;
            else if (read.ID_index==1) dataOut=MemoryType_ID;
            else if (read.ID_index==2) dataOut=MemoryCapacity_ID;
            else if (read.ID_index==3) dataOut=UID;
            else if (read.ID_index==4) dataOut=EDID_0;
            else if (read.ID_index==5) dataOut=EDID_1;
            else if (read.ID_index==6) dataOut=CFD_0;
            else if (read.ID_index==7) dataOut=CFD_1;
            else if (read.ID_index==8) dataOut=CFD_2;
            else if (read.ID_index==9) dataOut=CFD_3;
            else if (read.ID_index==10) dataOut=CFD_4;
            else if (read.ID_index==11) dataOut=CFD_5;
            else if (read.ID_index==12) dataOut=CFD_6;
            else if (read.ID_index==13) dataOut=CFD_7;
            else if (read.ID_index==14) dataOut=CFD_8;
            else if (read.ID_index==15) dataOut=CFD_9;
            else if (read.ID_index==16) dataOut=CFD_10;
            else if (read.ID_index==17) dataOut=CFD_11;
            else if (read.ID_index==18) dataOut=CFD_12;
            else if (read.ID_index==19) dataOut=CFD_13;
            
            //RK if (read.ID_index<=18) read.ID_index=read.ID_index+1;
            if (read.ID_index<=19) read.ID_index=read.ID_index+1;
            //RK else read.ID_index=0;


            f.out_info(readAddr, dataOut);
        
        end
       
       #tCLQX
        bitOut = dataOut[dataDim-1-bit_count];
        -> sendToBus;

    end   

end


endtask


always @sendToBus begin
  -> sendToBus_stack;
  #0;
  if(die_active == 1) begin
    fork : CP_sendToBus


      dtr_dout_started = 1'b1;
      force DQ1 = 1'bX;
      if(DoubleTransferRate == 1) force DQ0 = 1'bX;
      if((cmdRecName == "Read Fast") || 
        (cmdRecName == "Dual Command Fast Read") || 
        (cmdRecName == "Quad Command Fast Read") || 
        (cmdRecName == "Dual Output Fast Read") ||
        (cmdRecName == "Dual I/O Fast Read") ||
        (cmdRecName == "Quad I/O Fast Read") 
        ) begin 
      // #(tCLQV - tCLQX) 
        #(tCLQV/2 - tCLQX - 1); 
      end 
      else begin
        #(tCLQV - tCLQX - 1) ;
      end
      // if(DoubleTransferRate == 1) begin
      //   force DQ0 = bitOut;
      // end
      // else begin
        force DQ1 = bitOut;
      // end

    join
  end
end







//-----------------------
//  Reset Signal
//-----------------------
//dovrebbe essere abilitato attraverso il bit 4 del VECR


event resetEvent; //Activated only in devices with RESET pin.

reg resetDuringDecoding=0; //These two boolean variables are used in TimingCheck 
reg resetDuringBusy=0;     //entity to check tRHSL timing constraint

`ifdef RESET_pin   

    always @RESET if (!RESET) begin : CP_reset

        ->resetEvent;
        
        if(S===0 && !busy) 
            resetDuringDecoding=1; 
        else if (busy)
            resetDuringBusy=1; 
        
        release DQ1; //verificare
        ck_count = 0;
        latchingMode = "N";
        cmd='h0;
        addrLatch='h0;
        addr='h0;
        data='h0;
        dataOut='h0;

        iCmd = cmdDim - 1;
        iAddr = addrDimLatch - 1;
        iData = dataDim - 1;
        iDummy = dummyDimEff -1;

        // commands waiting to be executed are disabled internally
        
        // read enabler are resetted internally, in the read processes
        
        // CUIdecoders are internally disabled by reset signal
        
        #0 $display("[%0t ns] ==INFO== Reset Signal has been driven low : internal logic will be reset.", $time);

    end

`endif    

`ifdef RESET_software
//-----------------------
// Software Reset 
//-----------------------

   reg  Reset_enable= 0;
    always @(seqRecognized) if (cmdRecName=="Reset Enable") fork : REN 
        
        begin : exe
          @(posedge N25Qxxx.S); 
          disable reset;
          Reset_enable= 1;
          $display("  [%0t ns] Command execution: Reset Enable.", $time);
        end

        begin : reset
          @N25Qxxx.resetEvent;
          disable exe;
        end
    
    join


 always @(seqRecognized) if (cmdRecName=="Reset") begin : SW_reset
        
    if(Reset_enable==1) begin
        ->resetEvent;
        Reset_enable=0;//verificare se va bene
        if(S===0 && !busy) 
            resetDuringDecoding=1; 
        else if (busy)
            resetDuringBusy=1; 
        
        release DQ1; //verificare
        ck_count = 0;
        latchingMode = "N";
        cmd='h0;
        addrLatch='h0;
        addr='h0;
        data='h0;
        dataOut='h0;

        iCmd = cmdDim - 1;
        iAddr = addrDimLatch - 1;
        iData = dataDim - 1;
        iDummy =dummyDimEff -1;

        // commands waiting to be executed are disabled internally
        
        // read enabler are resetted internally, in the read processes
        
        // CUIdecoders are internally disabled by reset signal
        
        #0 $display("[%0t ns] ==INFO== Software reset : internal logic will be reset.", $time);

     end else $display("  [%0t ns] **WARNING** A reset-enable command is required before the Reset command: operation aborted!", $time);

 end


always @(seqRecognized) if (cmdRecName!="Reset" && Reset_enable==1) begin 
        Reset_enable=0;
end

`endif
//-----------------------
//  Deep power down 
//-----------------------


`ifdef PowDown


    always @seqRecognized if (cmdRecName=="Deep Power Down") fork : CP_deepPowerDown

        begin : exe
          @(posedge S);
          disable reset;
          busy=1;
          $display("  [%0t ns] Device is entering in deep power down mode...",$time);
          #deep_power_down_delay;
          $display("  [%0t ns] ...power down mode activated.",$time);
          busy=0;
          deep_power_down=1;
        end

        begin : reset
          @resetEvent;
          disable exe;
        end

    join


    always @seqRecognized if (cmdRecName=="Release Deep Power Down") fork : CP_releaseDeepPowerDown

        begin : exe
          @(posedge S);
          disable reset;
          busy=1;
          $display("  [%0t ns] Release from deep power down is ongoing...",$time);
          #release_power_down_delay;
          $display("  [%0t ns] ...release from power down mode completed.",$time);
          busy=0;
          deep_power_down=0;
        end 

        begin : reset
          @resetEvent;
          disable exe;
        end

    join


`endif


     
//-----------------
//   XIP mode
//-----------------


//-----------------
// Latching address 
//-----------------


always @(negedge S) if (XIP) begin : XIP_latchInit

    $display("[%0t ns] The device is entered in XIP mode.", $time);

    if (protocol=="extended") begin
       if (cmdRecName=="Dual I/O Fast Read") begin
           latchingMode = "I";
       end else if (cmdRecName=="Quad I/O Fast Read") begin
           latchingMode = "E";
       end else begin
           latchingMode = "A";
       end
       $display("[%0t ns] %0s. Address expected ...", $time,cmdRecName);
            
            fork : XipProc1 

                @(addrLatched) begin
                    
                    $display("  [%0t ns] Address latched: %h (byte %0d of page %0d, sector %0d)", $time, 
                                 addr, f.col(addr), f.pag(addr), f.sec(addr));
                    -> seqRecognized;
                    disable XipProc1;
                end

                @(posedge S) begin
                    $display("  - [%0t ns] S high: command aborted", $time);
                    disable XipProc1;
                end

                @(resetEvent or voltageFault) begin
                    disable XipProc1;
                end
            
            join

    end else  if (protocol=="dual") begin

       latchingMode = "I";
       $display("[%0t ns] %0s. Address expected ...", $time,cmdRecName);
        
              fork : XipProc2 

                @(addrLatched) begin
                     $display("  [%0t ns] Address latched: %h (byte %0d of page %0d, sector %0d)", $time, 
                                 addr, f.col(addr), f.pag(addr), f.sec(addr));
                     -> seqRecognized;
                     disable XipProc2;
                end

                @(posedge S) begin
                    $display("  - [%0t ns] S high: command aborted", $time);
                    disable XipProc2;
                end

                @(resetEvent or voltageFault) begin
                    disable XipProc2;
                end
            
            join

    end else  if (protocol=="quad") begin

       latchingMode = "E";
       $display("[%0t ns]  %0s. Address expected ...", $time,cmdRecName);
        
              fork : XipProc3 

                @(addrLatched) begin
                     $display("  [%0t ns] Address latched: %h (byte %0d of page %0d, sector %0d)", $time, 
                                 addr, f.col(addr), f.pag(addr), f.sec(addr));
                    -> seqRecognized;
                    disable XipProc3;
                end

                @(posedge S) begin
                    $display("  - [%0t ns] S high: command aborted", $time);
                    disable XipProc3;
                end

                @(resetEvent or voltageFault) begin
                    disable XipProc3;
                end
            
            join
    
    end
 
end 



endmodule















/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           CUI DECODER                                 --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

`timescale 1ns / 1ps 

module CUIdecoder (cmdAllowed);

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif






//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]

    input cmdAllowed;

    parameter [40*8:1] cmdName = "Write Enable";
    parameter [cmdDim-1:0] cmdCode = 'h06;
    parameter withAddr = 1'b0; // 1 -> command with address  /  0 -> without address 
    parameter with2Addr = 1'b0; // 1 -> command with address  /  0 -> without address 
    parameter with4Addr = 1'b0; // 1 -> command with address  /  0 -> without address 
     


    always @N25Qxxx.startCUIdec if (cmdAllowed && cmdCode==N25Qxxx.cmd) begin
        $display("[%0t ns] COMMAND DECODED: %0s , withAddr=%h, with2Addr=%h, with4Addr=%h, cmdcode=%h ", $time, cmdName, withAddr, with2Addr, with4Addr, cmdCode);

        if(!withAddr && !with2Addr && !with4Addr) begin
            
            N25Qxxx.cmdRecName = cmdName;
            $display("[%0t ns] COMMAND RECOGNIZED: %0s.", $time, cmdName);
            -> N25Qxxx.seqRecognized; 
        
        end else if (withAddr) begin
            
            N25Qxxx.quadMode = 0;
            N25Qxxx.latchingMode = "A";
            // $display("[%0t ns] 1.COMMAND RECOGNIZED: %0s. Address expected ...", $time, cmdName);
            -> N25Qxxx.codeRecognized;
            
            fork : proc1 

                @(N25Qxxx.addrLatched) begin
                    if (cmdName!="Read OTP" && cmdName!="Program OTP")
                        $display("  [%0t ns] Address latched: %h (byte %0d of page %0d, sector %0d)", $time, 
                                 N25Qxxx.addr, f.col(N25Qxxx.addr), f.pag(N25Qxxx.addr), f.sec(N25Qxxx.addr));
                    else
                        $display("  [%0t ns] Address latched: column %0d", $time, N25Qxxx.addr);
                    N25Qxxx.cmdRecName = cmdName;
                    -> N25Qxxx.seqRecognized;
                    disable proc1;
                end

                @(posedge N25Qxxx.S) begin
                    $display("  - [%0t ns] S high: command aborted", $time);
                    disable proc1;
                end

                @(N25Qxxx.resetEvent or N25Qxxx.voltageFault) begin
                    disable proc1;
                end
            
            join


         end else if (with2Addr) begin
            
            N25Qxxx.quadMode = 0;
            N25Qxxx.latchingMode = "I";
            $display("[%0t ns] 2.COMMAND RECOGNIZED: %0s. Address expected ...", $time, cmdName);
            -> N25Qxxx.codeRecognized;
            
            fork : proc2 

                @(N25Qxxx.addrLatched) begin
                    if (cmdName!="Read OTP" && cmdName!="Program OTP")
                        $display("  [%0t ns] Address latched: %h (byte %0d of page %0d, sector %0d)", $time, 
                                 N25Qxxx.addr, f.col(N25Qxxx.addr), f.pag(N25Qxxx.addr), f.sec(N25Qxxx.addr));
                    else
                    $display("  [%0t ns] Address latched: column %0d cmdName %s", $time, N25Qxxx.addr, cmdName);
                    $display("  [%0t ns] Address latched: column %0d cmdName %s", $time, N25Qxxx.addr, cmdName);
                    N25Qxxx.cmdRecName = cmdName;
                    -> N25Qxxx.seqRecognized;
                    disable proc2;
                end

                @(posedge N25Qxxx.S) begin
                    $display("  - [%0t ns] S high: command aborted", $time);
                    disable proc2;
                end

                @(N25Qxxx.resetEvent or N25Qxxx.voltageFault) begin
                    disable proc2;
                end
            
            join


        end  else if (with4Addr) begin
                    
                                N25Qxxx.quadMode = 1;
                                N25Qxxx.latchingMode = "E";
                                $display("[%0t ns] 4.COMMAND RECOGNIZED: %0s. Address expected ...", $time, cmdName);
                                -> N25Qxxx.codeRecognized;
                                            
                                fork : proc3 
                                   
                                   @(N25Qxxx.addrLatched) begin
                                    if (cmdName!="Read OTP" && cmdName!="Program OTP")
                        $display("  [%0t ns] Address latched: %h (byte %0d of page %0d, sector %0d)", $time, 
                                 N25Qxxx.addr, f.col(N25Qxxx.addr), f.pag(N25Qxxx.addr), f.sec(N25Qxxx.addr));
                    else
                                       $display("  [%0t ns] Address latched: column %0d", $time, N25Qxxx.addr);
                                       N25Qxxx.cmdRecName = cmdName;
                                       -> N25Qxxx.seqRecognized;
                                       disable proc3;
                                   end

                                   @(posedge N25Qxxx.S) begin
                                       $display("  - [%0t ns] S high: command aborted", $time);
                                       disable proc3;
                                   end

                                   @(N25Qxxx.resetEvent or N25Qxxx.voltageFault) begin
                                       disable proc3;
                                   end
                                                                                                                                                                                                                                                                                                                                        
                                join

      end    

                                                                                                                                                                                                                                                                                                                                                            
    end



    


endmodule    













/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           MEMORY MODULE                               --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

`timescale 1ns / 1ps

module Memory(mem_file);

    
//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif






//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]


    input [40*8:1] mem_file;

    //-----------------------------
    // data structures definition
    //-----------------------------

    reg [dataDim-1:0] memory [0:memDim-1];
    reg [dataDim-1:0] page [0:pageDim];




    //------------------------------
    // Memory management variables
    //------------------------------

    reg [addrDim-1:0] memAddr;
    reg [addrDim-1:0] pageStartAddr;
    reg [colAddrDim-1:0] pageIndex = 'h0;
    reg [colAddrDim-1:0] zeroIndex = 'h0;

    integer i;




    //-----------
    //  Init
    //-----------

    initial begin 

        for (i=0; i<=memDim-1; i=i+1) 
            memory[i] = data_NP;
        #1;
        
        // if ( `FILENAME_mem!="" && `FILENAME_mem!=" ") begin
        //     $readmemh(`FILENAME_mem, memory);
        //     $display("[%0t ns] ==INFO== Load memory content from file: \"%0s\".", $time, `FILENAME_mem);
        // end    
    
        if ( mem_file!="" && mem_file!=" ") begin
          $readmemh(mem_file, memory);
          $display("[%0t ns] ==INFO== 1. Load memory content from file: \"%0s\".", $time, mem_file);
        end    
    end



    // always @(N25Qxxx.Vcc_L2) if((N25Qxxx.Vcc_L2) && ( `FILENAME_mem!="" && `FILENAME_mem!=" ")) begin
    always @(N25Qxxx.Vcc_L2) if(N25Qxxx.Vcc_L2) begin
         
         $readmemh(mem_file, memory);
         $display("[%0t ns] ==INFO== 2. Load memory content from file: \"%0s\".", $time, mem_file);
                     

   end      


    //-----------------------------------------
    //  Task used in program & read operations  
    //-----------------------------------------
    

    
    // set start address & page index
    // (for program and read operations)
    
    task setAddr;

    input [addrDim-1:0] addr;

    begin

        memAddr = addr;
        pageStartAddr = {addr[addrDim-1:pageAddr_inf], zeroIndex};
        pageIndex = addr[colAddrDim-1:0];
    
    end
    
    endtask



    
    // reset page with FF data

    task resetPage;

    for (i=0; i<=pageDim-1; i=i+1) 
        page[i] = data_NP;

    endtask    


    

    // in program operations data latched 
    // are written in page buffer

    task writeDataToPage;

    input [dataDim-1:0] data;

    begin

        page[pageIndex] = data;
        pageIndex = pageIndex + 1; 

    end

    endtask



    // page buffer is written to the memory

    task programPageToMemory; //logic and between old_data and new_data

    for (i=0; i<=pageDim-1; i=i+1)
        memory[pageStartAddr+i] = memory[pageStartAddr+i] & page[i];
        // before page program the page should be reset
    endtask





    // in read operations data are readed directly from the memory

    task readData;

    output [dataDim-1:0] data;
    begin
        data = memory[memAddr];
        if (memAddr < memDim-1)
            memAddr = memAddr + 1;
        else begin
            memAddr=0;
            $display("  [%0t ns] **WARNING** Highest address reached. Next read will be at the beginning of the memory!", $time);
        end
            //aggiunta
        if (VolatileReg.VCR[1:0]!=2'd3) begin //implements the read data output wrap
               
             case (VolatileReg.VCR[1:0])
                    2'd0 : memAddr = {N25Qxxx.addr[addrDim-1: 4], memAddr[3:0]}; 
                    2'd1 : memAddr = {N25Qxxx.addr[addrDim-1: 5], memAddr[4:0]}; 
                    2'd2 : memAddr = {N25Qxxx.addr[addrDim-1: 6], memAddr[5:0]};
             endcase
                
        end      
            

    end

    endtask




    //---------------------------------------
    //  Tasks used for Page Write operation
    //---------------------------------------


    // page is written into the memory (old_data are over_written)
    
    task writePageToMemory; 

    for (i=0; i<=pageDim-1; i=i+1)
        memory[pageStartAddr+i] = page[i];
        // before page program the page should be reset
    endtask


    // pageMemory is loaded into the pageBuffer
    
    task loadPageBuffer; 

    for (i=0; i<=pageDim-1; i=i+1)
        page[i] = memory[pageStartAddr+i];
        // before page program the page should be reset
    endtask





    //-----------------------------
    //  Tasks for erase operations
    //-----------------------------

    task eraseSector;
    input [addrDim-1:0] A;
    reg [sectorAddrDim-1:0] sect;
    reg [sectorAddr_inf-1:0] zeros;
    reg [addrDim-1:0] mAddr;
    begin
        sect = f.sec(A);
        zeros = 'h0;
        mAddr = {sect, zeros};
        for(i=mAddr; i<=(mAddr+sectorSize-1); i=i+1)
            memory[i] = data_NP;
    
    end
    endtask



    `ifdef SubSect 
    
     task eraseSubsector;
     input [addrDim-1:0] A;
     reg [subsecAddrDim-1:0] subsect;
     reg [subsecAddr_inf-1:0] zeros;
     reg [addrDim-1:0] mAddr;
     begin
    
         subsect = f.sub(A);
         zeros = 'h0;
         mAddr = {subsect, zeros};
         for(i=mAddr; i<=(mAddr+subsecSize-1); i=i+1)
             memory[i] = data_NP;
    
     end
     endtask

    `endif



    `ifndef Stack512Mb 
    task eraseBulk;
      begin
        for (i=0; i<=memDim-1; i=i+1) 
            memory[i] = data_NP;
      end
    endtask
    `endif 


    `ifdef Stack512Mb
    task eraseDie;
      begin
        for (i=0; i<=memDim-1; i=i+1) 
            memory[i] = data_NP;
      end
    endtask
    `endif


    task erasePage;
    input [addrDim-1:0] A;
    reg [pageAddrDim-1:0] page;
    reg [pageAddr_inf-1:0] zeros;
    reg [addrDim-1:0] mAddr;
      begin
        `ifndef Stack512Mb 
      
          page = f.pag(A);
          zeros = 'h0;
          mAddr = {page, zeros}; 
          for(i=mAddr; i<=(mAddr+pageDim-1); i=i+1)
              memory[i] = data_NP;
      
        `endif 
      end
    endtask






    

endmodule













/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           UTILITY FUNCTIONS                           --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

`timescale 1ns / 1ps 

module UtilFunctions;
//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif





//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]

    integer i;

    
    //----------------------------------
    // Utility functions for addresses 
    //----------------------------------


    function [sectorAddrDim-1:0] sec;
    input [addrDim-1:0] A;
        sec = A[sectorAddr_sup:sectorAddr_inf];
    endfunction   

    `ifdef SubSect
      function [subsecAddrDim-1:0] sub;
      input [addrDim-1:0] A;
          sub = A[subsecAddr_sup:subsecAddr_inf];
      endfunction
    `endif

    function [pageAddrDim-1:0] pag;
    input [addrDim-1:0] A;
        pag = A[pageAddr_sup:pageAddr_inf];
    endfunction

    function [pageAddrDim-1:0] col;
    input [addrDim-1:0] A;
        col = A[colAddr_sup:0];
    endfunction
    
    
    
    
    
    //----------------------------------
    // Console messages 
    //----------------------------------

    task clock_error;

        $display("  [%0t ns] **WARNING** Number of clock pulse isn't multiple of eight: operation aborted!", $time);

    endtask



    task WEL_error;

        $display("  [%0t ns] **WARNING** WEL bit not set: operation aborted!", $time);

    endtask



    task out_info;
    
        input [addrDim-1:0] A;
        input [dataDim-1:0] D;


          if (stat.enable_SR_read)          
         $display("  [%0t ns] Data are going to be output: %b. [Read Status Register]",
                  $time, D);
         else if (NonVolatileReg.enable_NVCR_read)
         $display("  [%0t ns] Data are going to be output: %b. [Read Non Volatile Register]",
                  $time, D);
         else if (VolatileReg.enable_VCR_read)
         $display("  [%0t ns] Data are going to be output: %b. [Read Volatile Register]",
                  $time, D);
                  
         else if (VolatileEnhReg.enable_VECR_read)
         $display("  [%0t ns] Data are going to be output: %b. [Read Enhanced Volatile Register]",
                  $time, D);
         `ifdef byte_4         
         else if (ExtAddReg.enable_EAR_read)
         $display("  [%0t ns] Data are going to be output: %b. [Extended Address Register]",
                  $time, D);
         `endif         
         else if (flag.enable_FSR_read)
         $display("  [%0t ns] Data are going to be output: %b. [Read Flag Status Register]",
                  $time, D);

          else if (lock.enable_lockReg_read)
          $display("  [%0t ns] Data are going to be output: %h. [Read Lock Register of sector %0d]",
                    $time, D, A);

          else if (PMReg.enable_PMR_read)
          $display("  [%0t ps] Data are going to be output: %h. [Read Protection Management Register]",
                    $time, D);


          else if (read.enable_ID)
            $display("  [%0t ns] Data are going to be output: %h. [Read ID, byte %0d]", $time, D, A);
        
          else if (read.enable_OTP) begin
              if (A!=OTP_dim-1)
                  $display("  [%0t ns] Data are going to be output: %h. [Read OTP memory, column %0d]", $time, D, A);
              else  
                  $display("  [%0t ns] Data are going to be output: %b. [Read OTP memory, column %0d (control byte)]", $time, D, A);
          end

        else        
          
          if (read.enable || read.enable_fast)
          $display("  [%0t ns] Data are going to be output: %h. [Read Memory. Address %h (byte %0d of page %0d, subsector %0d of sector %0d)] ",
                  $time, D, A, col(A), pag(A), sub(A), sec(A)); 
        
          else if (read.enable_dual)
          $display("  [%0t ns] Data are going to be output: %h. [Read Memory. Address %h (byte %0d of page %0d, subsector %0d  sector %0d)] ",
                    $time, D, A, col(A), pag(A), sub(A), sec(A));

          else if (read.enable_quad)
          $display("  [%0t ns] Data are going to be output: %h. [Read Memory. Address %h (byte %0d of page %0d, subsector %0d sector %0d)] ",
                    $time, D, A, col(A), pag(A),  sub(A),sec(A));
         else if (read.enable_rsfdp)
         $display("  [%0t ns] Data are going to be output: %h. [Read Serial Flash Discovery Parameter. Address %h]", $time, D, A);
        

    endtask





    //----------------------------------------------------
    // Special tasks used for testing and debug the model
    //----------------------------------------------------
    

    //
    // erase the whole memory, and resets pageBuffer and cacheBuffer
    //
    
    task fullErase;
    begin
    
        for (i=0; i<=memDim-1; i=i+1) 
            mem.memory[i] = data_NP; 
        
        $display("[%0t ns] ==INFO== The whole memory has been erased.", $time);

    end
    endtask




    //
    // unlock all sectors of the memory
    //
    
    task unlockAll;
    begin

        for (i=0; i<=nSector-1; i=i+1) begin
            `ifdef LockReg
              lock.LockReg_WL[i] = 0;
              lock.LockReg_LD[i] = 0;
            `endif
            lock.lock_by_SR[i] = 0;
        end

        $display("[%0t ns] ==INFO== The whole memory has been unlocked.", $time);

    end
    endtask




    //
    // load memory file
    //

    task load_memory_file;

    input [40*8:1] memory_file;

    begin
    
        for (i=0; i<=memDim-1; i=i+1) 
            mem.memory[i] = data_NP;
        
        $readmemh(memory_file, mem.memory);
        $display("[%0t ns] ==INFO== Load memory content from file: \"%0s\".", $time, `FILENAME_mem);
    
    end
    endtask





endmodule












/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PROGRAM MODULE                              --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

`timescale 1ns / 1ps

module Program;

    //          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------


//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif




//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]

    

    
    event errorCheck, error, noError;
    
    reg [40*8:1] operation; //get the value of the command currently decoded by CUI decoders
    reg [40*8:1] oldOperation; // tiene traccia di quale operazione e' stata sospesa
    reg [40*8:1] holdOperation;// tiene traccia nel caso di suspend innestati della prima operazione sospesa

    time delay,delay_resume,startTime,latencyTime;                 
                                 
//variabili aggiunte per gestire il prog/erase suspend
    reg [pageAddrDim-1:0] page_susp; //pagina sospesa
 

    reg [sectorAddrDim-1:0] sec_susp;
    reg [subsecAddrDim-1:0] subsec_susp;
    reg Suspended = 0; //variabile che indica se un'operazione di suspend e' attiva
    reg doubleSuspend = 0; //variabile che indica se ci sono due suspend innestati
    reg prog_susp = 0;//indica che l'operazione sospesa e' un program
    reg sec_erase_susp =0; //indica che l'operazione sospesa e' un sector erase
    reg subsec_erase_susp =0; //indica che l'operazione sospesa e' un subsector erase



    //--------------------------------------------
    //  Page Program  Dual Program & Quad Program
    //--------------------------------------------


    reg writePage_en=0;
    reg [addrDim-1:0] destAddr;



    always @N25Qxxx.seqRecognized 
    if((N25Qxxx.cmdRecName==="Page Program" || N25Qxxx.cmdRecName==="Dual Program" || N25Qxxx.cmdRecName==="Quad Program" ||
       N25Qxxx.cmdRecName==="Dual Extended Program" ||  N25Qxxx.cmdRecName==="Quad Extended Program" || 
       N25Qxxx.cmdRecName==="Dual Command Page Program" ||
       N25Qxxx.cmdRecName==="Quad Command Page Program" ) && (N25Qxxx.die_active == 1))

       if(flag.FSR[4]) begin
                $display(" [%0t ns] **WARNING** It's not allowed to perform a program instruction. Program Status bit is high!",$time); 
                disable program_ops;
       end else if(operation=="Program Erase Suspend" && prog_susp) begin
                $display(" [%0t ns] **WARNING** It's not allowed to perform a program instruction after a program suspend",$time); 
                disable program_ops;
                
       `ifdef Subsect    
       end else if(operation=="Program Erase Suspend" && subsec_erase_susp) begin
           
                $display(" [%0t ns] **WARNING** It's not allowed to perform a program instruction after a subsector erase suspend",$time); 
                disable program_ops;
       `endif
       end else if(operation=="Program Erase Suspend" && sec_erase_susp && sec_susp==f.sec(N25Qxxx.addr)) begin
           
                $display(" [%0t ns] **WARNING** It's not allowed to perform a program instruction in the sector whose erase cycle is suspend",$time); 
                disable program_ops;

       end else

       
    fork : program_ops

           begin

            operation = N25Qxxx.cmdRecName;
            mem.resetPage;
            destAddr = N25Qxxx.addr;
            mem.setAddr(destAddr);
            
            if(operation=="Page Program")
                N25Qxxx.latchingMode="D";
            else if(operation=="Dual Program" || operation=="Dual Extended Program" || operation=="Dual Command Page Program") begin
                N25Qxxx.latchingMode="F";
                release N25Qxxx.DQ1;
            end else if(operation=="Quad Program" || operation=="Quad Extended Program" || operation=="Quad Command Page Program") begin
                N25Qxxx.latchingMode="Q";
                release N25Qxxx.DQ1;
                release N25Qxxx.Vpp_W_DQ2;
                `ifdef HOLD_pin
                release N25Qxxx.HOLD_DQ3;
                `endif
                `ifdef RESET_pin
                release N25Qxxx.RESET_DQ3;
                `endif

            end
  
            
            writePage_en = 1;

          end   
        
                                                                                                                                                                             

        begin : exe
            
           @(posedge N25Qxxx.S);
            
            disable reset;
            writePage_en=0;
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy=1;
            startTime = $time;
            $display("  [%0t ns] Command execution begins: %0s.", $time, operation);
            
                delay=program_delay;

                -> errorCheck;

                @(noError) begin
                   mem.programPageToMemory;
                    $display("  [%0t ns] Command execution completed: %0s.", $time, operation);
                end
           
        end 


        begin : reset
        
          @N25Qxxx.resetEvent;
            writePage_en=0;
            operation = "None";
            disable exe;    
        
        end

    join





    always @N25Qxxx.dataLatched if(writePage_en) begin

        mem.writeDataToPage(N25Qxxx.data);
    
    end








    //------------------------
    //  Write Status register
    //------------------------


    reg [dataDim-1:0] SR_data;


    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write SR") begin : write_SR_ops

       //prova
       if (N25Qxxx.protocol=="dual") N25Qxxx.latchingMode="F";
       else if (N25Qxxx.protocol=="quad") N25Qxxx.latchingMode="Q";
       else
              N25Qxxx.latchingMode="D";
        
        @(posedge N25Qxxx.S) begin
            operation=N25Qxxx.cmdRecName;
            SR_data=N25Qxxx.data;
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy=1;
            //aggiunta verificare
            startTime = $time;
            $display("  [%0t ns] Command execution begins: Write SR.",$time);
            delay=write_SR_delay;
            -> errorCheck;

            @(noError) begin
                
                `SRWD = SR_data[7];  
                `BP3  = SR_data[6];  
                `TB   = SR_data[5]; 
                `BP2  = SR_data[4]; 
                `BP1  = SR_data[3]; 
                `BP0  = SR_data[2]; 
 
               #0 $display("  [%0t ns] Command execution completed: Write SR. SR=%h, (SRWD,BP3,TB,BP2,BP1,BP0)=%b",
                           $time, stat.SR, {`SRWD,`BP3,`TB,`BP2,`BP1,`BP0} );
            
            end
                
        end
    
    end

    //----------------------------------------
    //  Write Volatile Configuration register
    //----------------------------------------


    reg [dataDim-1:0] VCR_data;


    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write Volatile Configuration Reg") begin : write_VCR_ops

         if (N25Qxxx.protocol=="dual") N25Qxxx.latchingMode="F";
       else if (N25Qxxx.protocol=="quad") N25Qxxx.latchingMode="Q";
       else
              N25Qxxx.latchingMode="D";
        
        @(posedge N25Qxxx.S) begin
            operation=N25Qxxx.cmdRecName;
            VCR_data=N25Qxxx.data;
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy=1;
            startTime = $time;
            $display("  [%0t ns] Command execution begins: Write Volatile Configuration Reg",$time);
            delay=write_VCR_delay;
            -> errorCheck;

            @(noError) begin
                
                VolatileReg.VCR=VCR_data;
                $display("  [%0t ns] Command execution completed: Write Volatile Configuration Reg. VCR=%h", 
                           $time, VolatileReg.VCR);
            
            end
                
        end
    
    end



    //--------------------------------------------------
    //  Write Volatile Enhanced Configuration register
    //--------------------------------------------------


    reg [dataDim-1:0] VECR_data;


    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write VE Configuration Reg") begin : write_VECR_ops

         if (N25Qxxx.protocol=="dual") N25Qxxx.latchingMode="F";
       else if (N25Qxxx.protocol=="quad") N25Qxxx.latchingMode="Q";
       else
              N25Qxxx.latchingMode="D";
        
        @(posedge N25Qxxx.S) begin
            operation=N25Qxxx.cmdRecName;
            VECR_data=N25Qxxx.data;
            VECR_data[5] = 0;  // DTR is disabled by default
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy=1;
            startTime = $time;
            $display("  [%0t ns] Command execution begins: Write Volatile Enhanced Configuration Reg",$time);
            delay=write_VECR_delay;
            -> errorCheck;

            @(noError) begin
                
                VolatileEnhReg.VECR=VECR_data;
                $display("  [%0t ns] Command execution completed: Write Volatile Enhanced Configuration Reg. VECR=%h", 
                           $time, VolatileEnhReg.VECR);
            
            end
                
        end
    
    end

    //---------------------------------------------
    //  Write Non Volatile Configuration register
    //--------------------------------------------


    reg [dataDim-1:0] NVCR_LSByte;
    
    reg [dataDim-1:0] NVCR_MSByte;

    reg LSByte;


    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write NV Configuration Reg") begin : write_NVCR_ops

         if (N25Qxxx.protocol=="dual") N25Qxxx.latchingMode="F";
       else if (N25Qxxx.protocol=="quad") N25Qxxx.latchingMode="Q";
       else
              N25Qxxx.latchingMode="D";
        LSByte=1;
        // added the check to abort writing in NVCR register if locked by PMR --  
         if (PMReg.PMR[7] == 0) begin
                $display(" [%0t ps] **WARNING** Cant write to NVCR reg.PMR bit 7 set is 0.Register locked!",$time); 
                flag.FSR[1] = 1;
                disable NVCR_ops;
                
        end     
        else begin
          @(posedge N25Qxxx.S) begin: NVCR_ops
              operation=N25Qxxx.cmdRecName;
              NVCR_LSByte=N25Qxxx.LSdata;
              NVCR_MSByte=N25Qxxx.data;
              NVCR_LSByte[5] = 0; // Reserved for DTR
              N25Qxxx.latchingMode="N";
              N25Qxxx.busy=1;
              startTime = $time;
              $display("  [%0t ns] Command execution begins: Write Non Volatile Configuration Register.",$time);
              delay=write_NVCR_delay;
              -> errorCheck;

              @(noError) begin
                  
                  NonVolatileReg.NVCR={NVCR_MSByte,NVCR_LSByte}; 
                  
                  $display("  [%0t ns] Command execution completed: Write Non Volatile Configuration Register. NVCR=%h (%b)",
                             $time, NonVolatileReg.NVCR,NonVolatileReg.NVCR);
              
              end
                  
          end
        end
    
    end
   
         // always  @(posedge N25Qxxx.Vcc_L3) begin
         //      if (N25Qxxx.cmdRecName == "Write NV Configuration Reg") 
         //         N25Qxxx.rescue_seq_flag = 1;
         //      else
         //         N25Qxxx.rescue_seq_flag = 0;
         // end
    
    
    
// write protection management register

    reg [dataDim-1:0] PMR_Byte;
    

    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write Protection Management Reg") begin : write_PMR_ops

         if (N25Qxxx.protocol=="dual") N25Qxxx.latchingMode="F";
       else if (N25Qxxx.protocol=="quad") N25Qxxx.latchingMode="Q";
       else
              N25Qxxx.latchingMode="D";

        if (PMReg.PMR[2] == 0) begin
          //added    
                $display(" [%0t ps] **WARNING** Cant write to PMR reg.PMR bit 2 set is 0.Register locked!",$time); 
             flag.FSR[1] = 1;
             flag.FSR[4] = 1;
                disable pmr_ops;

        end else begin

        
        @(posedge N25Qxxx.S) begin : pmr_ops
         //   -> stat.WEL_reset;
             $display("[%0t ps] WEL.%b",$time,`WEL);
            if(`WEL == 0)
            N25Qxxx.f.WEL_error;
            operation=N25Qxxx.cmdRecName;
            PMR_Byte=N25Qxxx.data;
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy=1;
            startTime = $time;
            $display("  [%0t ps] Command execution begins: Write PMR Configuration Register.",$time);
             delay=write_PMR_delay;
            -> errorCheck;

            @(noError) begin
                
                PMReg.PMR=PMR_Byte; 
                
                $display("  [%0t ps] Command execution completed: Write PMR Configuration Register. PMR=%h (%b)",
                           $time, PMReg.PMR,PMReg.PMR);
            

            end
        end
      end
    end


`ifdef byte_4

    //--------------------------------------------------
    //  Write Extended Address register
    //--------------------------------------------------


    reg [dataDim-1:0] WEAR_data;


    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write EAR") begin : write_EAR_ops

         if (N25Qxxx.protocol=="dual") N25Qxxx.latchingMode="F";
       else if (N25Qxxx.protocol=="quad") N25Qxxx.latchingMode="Q";
       else
              N25Qxxx.latchingMode="D";
        
        @(posedge N25Qxxx.S) begin
            operation=N25Qxxx.cmdRecName;
            WEAR_data=N25Qxxx.data;
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy=1;
            startTime = $time;
            $display("  [%0t ns] Command execution begins: Write Extended Address Register",$time);
            delay=write_EAR_delay; //immagino ci sia!!!!
            -> errorCheck;

            @(noError) begin

              if(addrDim > 24) begin
                 
                ExtAddReg.EAR[addrDim - 25 :0] =WEAR_data[addrDim - 25 :0];
                $display("  [%0t ns] Command execution completed: Write Extended Address Register. EAR=%h", 
                           $time, ExtAddReg.EAR);
                         if(ExtAddReg.EAR[EARvalidDim-1:0]==0) $display("[%0t ns] ==INFO== Bottom 128M selected",$time);
                         else $display("[%0t ns] ==INFO== Top 128M selected",$time);

              end
            end
                
        end
    
    end


`endif

    //--------------
    // Erase
    //--------------

    always @N25Qxxx.seqRecognized 
    
    if ((N25Qxxx.cmdRecName==="Sector Erase" || N25Qxxx.cmdRecName==="Subsector Erase" ||
        N25Qxxx.cmdRecName==="Bulk Erase" || N25Qxxx.cmdRecName==="Die Erase") && (N25Qxxx.die_active == 1))
    
        if(flag.FSR[5]) begin
                $display(" [%0t ns] **WARNING** It's not allowed to perform an erase instruction. Erase Status bit is high!",$time); 
                disable erase_ops;
                
        end else if(operation=="Program Erase Suspend" && prog_susp) begin
           
                 $display(" [%0t ns] **WARNING** It's not allowed to perform an erase instruction after a program suspend",$time); 
                 disable erase_ops;

        end else  if(operation=="Program Erase Suspend" && sec_erase_susp) begin
        
                 $display(" [%0t ns] **WARNING** It's not allowed to perform an erase instruction after a sector erase suspend",$time); 
                 disable erase_ops;
        `ifdef Subsect
        end else  if(operation=="Program Erase Suspend" && subsec_erase_susp) begin
                 
                 $display(" [%0t ns] **WARNING** It's not allowed to perform an erase instruction after a subsector erase suspend",$time); 
                 disable erase_ops;
        `endif      
        end else      
        fork : erase_ops

        begin : exe
        
           @(posedge N25Qxxx.S);

            disable reset;
             

            operation = N25Qxxx.cmdRecName;
            destAddr = N25Qxxx.addr;
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy = 1;
            startTime = $time;
            $display("  [%0t ns] Command execution begins: %0s.", $time, operation);
            if (operation=="Sector Erase") delay=erase_delay;
            `ifdef Stack512Mb
              else if (operation=="Die Erase") delay=erase_die_delay;
            `else
              else if (operation=="Bulk Erase") delay=erase_bulk_delay;
            `endif
            `ifdef SubSect
              else if (operation=="Subsector Erase")  delay=erase_ss_delay; 
            `endif  
            
            -> errorCheck;

            @(noError) begin
                if (operation=="Sector Erase")          mem.eraseSector(destAddr);
                `ifdef Stack512Mb
                  else if (operation=="Die Erase")       mem.eraseDie;
                `else
                  else if (operation=="Bulk Erase")       mem.eraseBulk;
                `endif
                `ifdef SubSect
                  else if (operation=="Subsector Erase")  mem.eraseSubsector(destAddr); 
                `endif
                $display("  [%0t ns] Command execution completed: %0s.", $time, operation);
             end
        end


        begin : reset
        
          @N25Qxxx.resetEvent;
            operation = "None";
            disable exe;    
        
        end

            
    join


//------------------------
// Program Erase Suspend
//-------------------------


 always @N25Qxxx.seqRecognized 
    
    if ((N25Qxxx.cmdRecName==="Program Erase Suspend") && (N25Qxxx.die_active == 1)) begin
    
        if (operation=="Bulk Erase" || operation=="Die Erase" || operation=="Program OTP") $display("[%0t ns] %0s can't be suspended", $time, operation);

        else fork : progerasesusp_ops

        
        begin : exe
        
           @(posedge N25Qxxx.S);

            disable reset;
            if (Suspended) begin 
                holdOperation=oldOperation;
                doubleSuspend=1;
            end   
            if(operation != "Program Erase Resume") begin
              oldOperation = operation; //operazione sospesa
            end
            operation = N25Qxxx.cmdRecName;
            N25Qxxx.latchingMode="N";
            if(oldOperation == "Subsector Erase" || oldOperation == "Sector Erase")
              #eraseSusp_latencyTime; // (non definito ancora)
            else
              #progSusp_latencyTime; // (non definito ancora)
            N25Qxxx.busy = 0; //WIP =0; FSR[2]=1
            -> stat.WEL_reset;
            Suspended = 1;
            
            if (oldOperation=="Sector Erase") begin
                latencyTime = erase_latency;
                delay_resume=erase_delay-($time - startTime);
                sec_erase_susp = 1;
                sec_susp= f.sec(destAddr);
                  flag.FSR[6] = 1;
                disable erase_ops;
                disable errorCheck_ops;
            end
            `ifdef SubSect
              else if (oldOperation=="Subsector Erase") begin
                    latencyTime = erase_ss_latency;
                    delay_resume=erase_ss_delay-($time - startTime);
                    subsec_erase_susp = 1;
                    sec_susp= f.sec(destAddr);
                      flag.FSR[6] = 1;
                    disable erase_ops;
                    disable errorCheck_ops;
              end  
            `endif  
              else if (oldOperation=="Page Program" || oldOperation=="Dual Program" || oldOperation=="Quad Program" ||
                       oldOperation=="Dual Extended Program" || oldOperation=="Quad Extended Program" || 
                       oldOperation=="Dual Command Page Program" || oldOperation=="Quad Command Page Program") begin
                       latencyTime = program_latency;
                       delay_resume=program_delay-($time - startTime);
                       prog_susp = 1;
                         flag.FSR[2] = 1;
                       page_susp = f.pag(destAddr);
                       disable program_ops;
                       disable errorCheck_ops;
              end


        end


        begin : reset
        
          @N25Qxxx.resetEvent;
            operation = "None";
            disable exe;    
        
        end

            
    join

  end


 //------------------------
 // Program Erase Resume
 //-------------------------

always @N25Qxxx.seqRecognized 
  begin
    #1;
    // $display("RESUME: Entered in program erase resume %s " ,N25Qxxx.cmdRecName, $time);
    
    if ((N25Qxxx.cmdRecName==="Program Erase Resume") && (N25Qxxx.die_active == 1)) fork :resume_ops


        begin : exe
            
           @(posedge N25Qxxx.S);
            
            disable reset;
            operation = N25Qxxx.cmdRecName;
            N25Qxxx.latchingMode="N";
            delay=delay_resume;
            
            if (doubleSuspend==1) begin 
                Suspended=1;
            end 
            else Suspended=0;
            N25Qxxx.busy=1;
            
            -> errorCheck;
            fork 

                 begin : susp1
                    @(noError);
                    if (oldOperation=="Sector Erase")  begin
                        mem.eraseSector(destAddr);
                        sec_erase_susp = 0;
                    end    
                    `ifdef SubSect
                    else if (oldOperation=="Subsector Erase") begin
                        mem.eraseSubsector(destAddr); 
                        subsec_erase_susp = 0;
                    end    
                        
                    `endif
                    else begin
                        mem.writePageToMemory;
                        prog_susp = 0;
                    end 
                    
                    $display(" [%0t ns] Command execution completed: %0s.", $time, oldOperation);
                    if (doubleSuspend==1) begin 
                       doubleSuspend=0;
                       oldOperation=holdOperation;
                   end    
                   disable susp2;
                end

                begin : susp2
                  @(posedge Suspended);
                  disable susp1;
                end
            join
                
        end 


        begin : reset
        
          @N25Qxxx.resetEvent;
            writePage_en=0;
            operation = "None";
            disable exe;    
        
        end

    join

  end


    //---------------------------
    //  Program OTP 
    //---------------------------

    
        reg write_OTP_buffer_en=0;
     
         `define OTP_lockBit N25Qxxx.OTP.mem[OTP_dim-1][0]

        always @N25Qxxx.seqRecognized if((N25Qxxx.cmdRecName=="Program OTP") && (N25Qxxx.die_active == 1))

           if(flag.FSR[4] || !PMReg.PMR[3]) begin
                $display(" [%0t ns] **WARNING** It's not allowed to perform a program instruction. Program Status bit is high!",$time); 
                disable OTP_prog_ops;
           end else

        fork : OTP_prog_ops

            begin
                OTP.resetBuffer;
                OTP.setAddr(N25Qxxx.addr);
                N25Qxxx.latchingMode="D";
                write_OTP_buffer_en = 1;
            end

            begin : exe
               @(posedge N25Qxxx.S);
                disable reset;
                operation=N25Qxxx.cmdRecName;
                write_OTP_buffer_en=0;
                N25Qxxx.latchingMode="N";
                N25Qxxx.busy=1;
                startTime = $time;
                $display("  [%0t ns] Command execution begins: OTP Program.",$time);
                delay=program_delay;
                -> errorCheck;

                @(noError) begin
                    OTP.writeBufferToMemory;
                    $display("  [%0t ns] Command execution completed: OTP Program.",$time);
                end
            end  

            begin : reset
               @N25Qxxx.resetEvent;
                write_OTP_buffer_en=0;
                operation = "None";
                disable exe;    
            end
        
        join



        always @N25Qxxx.dataLatched if(write_OTP_buffer_en) begin

            OTP.writeDataToBuffer(N25Qxxx.data);
        
        end

`ifdef byte_4
//-----------------------
// 4-byte address
//-------------------------
reg enable_4Byte_address;// enable_4Byte_address =1 the device accept 4 bytes of address 

 always @N25Qxxx.seqRecognized if (N25Qxxx.cmdRecName=="Enable 4 Byte Address") fork : CP_enable4ByteAddress
 
       begin : exe
           @(posedge N25Qxxx.S);
           disable reset;
           if(`WEL == 1) begin
           // N25Qxxx.busy=1;
           startTime = $time;
           $display("  [%0t ns] Command execution begins: Enable 4 Byte Address.",$time);
           delay=enable4_address_delay;
           // ->errorCheck;
           
           // @(noError) begin
                    enable_4Byte_address=1;
                    $display("  [%0t ns] Command execution completed: Enable 4 Byte Address.",$time);
                end

       end

        begin : reset
          @N25Qxxx.resetEvent;
          disable exe;
        end

    join

always @N25Qxxx.seqRecognized if (N25Qxxx.cmdRecName=="Exit 4 Byte Address") fork : CP_exit4ByteAddress
 
       begin : exe
           @(posedge N25Qxxx.S);
           disable reset;
           if(`WEL == 1) begin
            // N25Qxxx.busy=1;
             startTime = $time;
           $display("  [%0t ns] Command execution begins: Exit 4 Byte Address.",$time);
           delay=exit4_address_delay;
           // ->errorCheck;
           
           // @(noError) begin
                    enable_4Byte_address=0;
                    $display("  [%0t ns] Command execution completed: Exit 4 Byte Address.",$time);
          end
        
      end
        begin : reset
          @N25Qxxx.resetEvent;
          disable exe;
        end

    join



`endif



    //------------------------
    //  Error check
    //------------------------
    // This process also models  
    // the operation delays
    

    always @(errorCheck) fork : errorCheck_ops
    
    
        begin : static_check

            if((operation=="Dual Extended Program" || N25Qxxx.protocol=="dual") && N25Qxxx.ck_count!=4 && N25Qxxx.ck_count!=0) begin
                N25Qxxx.f.clock_error;
                -> error;
            end else if ((operation=="Quad Extended Program"|| N25Qxxx.protocol=="quad") && N25Qxxx.ck_count!=0 && N25Qxxx.ck_count!=2 && 
                         N25Qxxx.ck_count!=4 && N25Qxxx.ck_count!=6) begin 
                        N25Qxxx.f.clock_error;
                        -> error;
            end else if(operation!="Dual Extended Program" && operation!="Quad Program" && operation!="Quad Extended Program" && operation!="Dual Command Page Program" && N25Qxxx.protocol=="extended" && N25Qxxx.ck_count!=0) begin 
                N25Qxxx.f.clock_error;
                -> error;
                            
            end else if(`WEL==0) begin
               
                N25Qxxx.f.WEL_error;
                -> error;
            
            end else if ( (operation=="Page Program" || operation=="Dual Program" || operation=="Dual Extended Program" || 
                           operation=="Quad Extended Program" || operation=="Quad Program" || operation=="Dual Command Page Program" || 
                           operation=="Sector Erase" ||  operation=="Subsector Erase")

                                                        &&
                          (lock.isProtected_by_SR(destAddr)!==0 || lock.isProtected_by_lockReg(destAddr)!==0) ) begin
           
                -> error;

                if (lock.isProtected_by_SR(destAddr)!==0 && lock.isProtected_by_lockReg(destAddr)!==0)
                $display("  [%0t ns] **WARNING** Sector locked by Status Register and by Lock Register: operation aborted.", $time);
            
                else if (lock.isProtected_by_SR(destAddr)!==0)
                $display("  [%0t ns] **WARNING** Sector locked by Status Register: operation aborted.", $time);
            
                else if (lock.isProtected_by_lockReg(destAddr)!==0) 
                $display("  [%0t ns] **WARNING** Sector locked by Lock Register: operation aborted.", $time);
            
            end else if (operation=="Bulk Erase" && lock.isAnySectorProtected(0)) begin
                
                $display("  [%0t ns] **WARNING** Some sectors are locked: bulk erase aborted.", $time);
                -> error;
            
            end else if (operation=="Die Erase" && lock.isAnySectorProtected(0)) begin
                
                $display("  [%0t ns] **WARNING** Some sectors are locked: die erase aborted.", $time);
                -> error;
            
            end 
            else if (operation=="Bulk Erase" && N25Qxxx.Vpp_W_DQ2==0) begin
                 $display("  [%0t ns] **WARNING** Vpp_W=0 : bulk erase aborted.", $time);
                 -> error;
            
            end 
            else if (operation=="Die Erase" && N25Qxxx.Vpp_W_DQ2==0) begin
                 $display("  [%0t ns] **WARNING** Vpp_W=0 : bulk erase aborted.", $time);
                 -> error;
            
            end 
            
              else if(operation=="Write SR" && `SRWD==1 && N25Qxxx.W_int===0) begin
                  $display("  [%0t ns] **WARNING** SRWD bit set to 1, and W=0: write SR isn't allowed!", $time);
                  -> error;
              end
              else if(operation=="Write SR" && PMReg.PMR[4] == 0  ) begin
                  $display("  [%0t ns] **WARNING** PMR[4] bit set to 1, and write SR isn't allowed!", $time);
                  -> error;
              end
               else if(operation=="Write NV Configuration Reg" && PMReg.PMR[7] == 0 ) begin
                  $display("  [%0t ps] **WARNING** PMR bit set to 0 write to NVCR not allowed!", $time);
                  -> error;
              end

             else if(operation=="Write Protection Management Reg" && PMReg.PMR[2] == 0 ) begin
                  $display("  [%0t ps] **WARNING** PMR bit set to 0 write to PMR not allowed!", $time);
                  -> error;
              end

              // added the additional check for PMR bit 3 set to 0 which means the array locked  
                    else if ((operation=="Program OTP" && `OTP_lockBit==0)|| (operation == "Program_OTP" && PMReg.PMR[3] == 0)) begin 
                    $display("  [%0t ps] **WARNING** OTP is read only, because lock bit has been programmed to 0: operation aborted.", $time);
                    -> error;    
                    end
            
        end

        fork : dynamicCheck

            @(N25Qxxx.voltageFault) begin
                $display("  [%0t ns] **WARNING** Operation Fault because of Vcc Out of Range!", $time);
                -> error;
            end
            
            `ifdef RESET_pin
              if (operation!="Write SR") @(N25Qxxx.resetEvent) begin
                $display("  [%0t ns] **WARNING** Operation Fault because of Device Reset!", $time);
                -> error;
              end
            `endif  
            // #delay begin 
            begin 
              $display("1. Before de-asserting BUSY ",delay, $time);
              #delay;
              $display("2. Before de-asserting BUSY ", $time);
            N25Qxxx.busy=0;
                if(!Suspended) -> stat.WEL_reset;
                -> noError;
                disable dynamicCheck;
                disable errorCheck_ops;
            end
        join

        
    join




    always @(error) begin

        N25Qxxx.busy = 0;
        // -> stat.WEL_reset;
        disable errorCheck_ops;
        if (operation=="Page Program" || operation=="Dual Program" || operation=="Quad Program" || operation=="Dual Command Page Program" 
             || operation=="Dual Extended Program" || operation=="Quad Extended Program") disable program_ops;
        else if (operation=="Sector Erase" || operation=="Subsector Erase" || operation=="Bulk Erase" || operation=="Die Erase") disable erase_ops;
        else if (operation=="Write SR") disable write_SR_ops;
        else if (operation=="Write Protection Management Reg") disable write_PMR_ops; // added to error check
        else if (operation=="Write NV Configuration Reg") disable write_NVCR_ops;  // added to error check 
        else if (operation=="Program OTP") disable OTP_prog_ops;

    end






endmodule












/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           STATUS REGISTER MODULE                      --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module StatusRegister;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif




//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]


    // status register
    reg [7:0] SR;
    




    //--------------
    // Init
    //--------------


    initial begin
        
        //see alias in DevParam.h
        
        SR[2] = 0; // BP0 - block protect bit 0 
        SR[3] = 0; // BP1 - block protect bit 1
        SR[4] = 0; // BP2 - block protect bit 2
        SR[5] = 0; // TB (block protect top/bottom) 
        SR[6] = 0; // BP3 - block protect bit 3
        SR[7] = 0; // SRWD

    end


    always @(N25Qxxx.PollingAccessOn) if(N25Qxxx.PollingAccessOn) begin
        
        SR[0] = 1; // WIP - write in progress
        SR[1] = 0; // WEL - write enable latch

    end

    always @(N25Qxxx.checkProtocol) begin
        
        SR[0] = 0; // WIP - write in progress
        SR[1] = 0; // WEL - write enable latch

    end

    always @(N25Qxxx.ReadAccessOn) if(N25Qxxx.ReadAccessOn) begin
        
        SR[0] = 0; // WIP - write in progress
       // SR[1] = 0; // WEL - write enable latch

    end



        


     


    //----------
    // WIP bit
    //----------
    
    always @(N25Qxxx.busy)
        `WIP = N25Qxxx.busy;

   
    //----------
    // WEL bit 
    //----------
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write Enable") fork : WREN 
        
        begin : exe
          @(posedge N25Qxxx.S); 
          disable reset;
          `WEL = 1;
          $display("  [%0t ns] Command execution: WEL bit set.", $time);
        end

        begin : reset
          @N25Qxxx.resetEvent;
          disable exe;
        end
    
    join


    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write Disable") fork : WRDI 
        
        begin : exe
          @(posedge N25Qxxx.S);
          disable reset;
          `WEL = 0;
          $display("  [%0t ns] Command execution: WEL bit reset.", $time);
        end
        
        begin : reset
          @N25Qxxx.resetEvent;
          disable exe;
        end
        
    join


    event WEL_reset;
    always @(WEL_reset)
        `WEL = 0;


    

    //------------------------
    // write status register
    //------------------------

    // see "Program" module



    //----------------------
    // read status register
    //----------------------
    // NB : "Read SR" operation is also modelled in N25Qxxx.module

    reg enable_SR_read;
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read SR") fork 
        
        enable_SR_read=1;

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_SR_read=0;
        
    join    

    


    



endmodule   














/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           STATUS REGISTER MODULE                      --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module FlagStatusRegister;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif




//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]




    // status register
    reg [7:0] FSR;
    




    //--------------
    // Init
    //--------------


    initial begin
        FSR[0] = 0; // Reserved (N25Q032),4th address mode enabled(N25Q256)
        FSR[1] = 0; // Protection Status bit 
        FSR[2] = 0; // Program Suspend Status bit 
        FSR[3] = 0; // VPP status bit not implemented
        FSR[4] = 0; // Program Status bit
        FSR[5] = 0; // Erase Status bit 
        FSR[6] = 0; // Erase Suspend status bit 
        FSR[7] = 1; // P/E Controller bit(!WIP)


    end



    //-----------------------
    // P/E Controller bit
    //-----------------------
      always @(`WIP)
              FSR[7]=!(`WIP);

`ifdef byte_4
    //-----------------------
    // 4th address mode enabled bit
    //-----------------------

    always @(N25Qxxx.prog.enable_4Byte_address) 
    
        FSR[0]=N25Qxxx.prog.enable_4Byte_address;

`endif

    //------------------------------
    // Erase and Program Suspend bit 
    //------------------------------
    
    always @(N25Qxxx.seqRecognized) if ((N25Qxxx.cmdRecName=="Program Erase Suspend" && FSR[7]==1 && (N25Qxxx.die_active == 1))) begin  
        if (prog.oldOperation=="Sector Erase" || prog.oldOperation=="Subsector Erase")  FSR[6]=1;
        else FSR[2]=1;  
    end

    always @(N25Qxxx.seqRecognized) if ((N25Qxxx.cmdRecName=="Program Erase Resume") && (N25Qxxx.die_active == 1)) begin
       if (prog.oldOperation=="Sector Erase" || prog.oldOperation=="Subsector Erase")  FSR[6]=0;
       else FSR[2]=0;
        end
        


//------------------------------------------
// Erase Status bit and Program Status bit 
//------------------------------------------

     always @ prog.error if(`WEL == 1) begin

       if (prog.operation=="Sector Erase" || prog.operation=="Subsector Erase" || prog.operation=="Bulk Erase" || prog.operation=="Die Erase" )  FSR[5]=1;
        else if (prog.operation=="Program OTP" || prog.operation=="Page Program" || prog.operation=="Dual Program" ||
                 prog.operation=="Quad Program" || prog.operation=="Dual Extended Program" || prog.operation=="Quad Extended Program") 
             FSR[4]=1;  

     end

//-------------------
// Vpp Status bit 
//-------------------

//not implemented 


 `define OTP_lockBit N25Qxxx.OTP.mem[OTP_dim-1][0]
//------------------------
// Protection Status bit 
//------------------------

always @ prog.error  if (((prog.operation=="Page Program" || prog.operation=="Dual Program" ||
                           prog.operation=="Dual Extended Program" || prog.operation=="Quad Extended Program" ||
                           prog.operation=="Quad Program" || prog.operation=="Sector Erase" || 
                           prog.operation=="Subsector Erase")
                                                        &&
                          (lock.isProtected_by_SR(prog.destAddr)!==0 || lock.isProtected_by_lockReg(prog.destAddr)!==0))
                                                           ||
                           (prog.operation=="Bulk Erase" && lock.isAnySectorProtected(0)) 
                                                           ||
                           (prog.operation=="Die Erase" && lock.isAnySectorProtected(0)) 
                                                           ||
                           (prog.operation=="Write SR" && `SRWD==1 && N25Qxxx.W_int===0)
                                                           ||
                            (prog.operation=="Program OTP" && `OTP_lockBit==0))  
                               
                          
                    begin
           
                         FSR[1]=1;

                    end




 //---------------------------
 // read flag status register
 //---------------------------
    // NB : "Read FSR" operation is also modelled in N25Qxxx.module

    reg enable_FSR_read;
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read Flag SR") fork 
        
        enable_FSR_read=1;

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_FSR_read=0;
        
    join  

//---------------------------
// clear flag status register
//---------------------------
     always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Clear Flag SR") begin  
        
         @(posedge N25Qxxx.S) begin
         
            N25Qxxx.latchingMode="N";
            N25Qxxx.busy=1;
            $display("  [%0t ns] Command execution begins:Clear Flag Status Register.",$time);
            
            #(clear_FSR_delay);
            
            N25Qxxx.busy=0;
            
            #0;
            FSR[1] = 0; // Protection Status bit 
            FSR[3] = 0; // VPP status bit
            FSR[4] = 0; // Program Status bit
            FSR[5] = 0; // Erase Status bit 
            $display("  [%0t ns] Command execution completed: Clear Flag Status Register. FSR=%b",
                         $time, FSR);
                        
         end

     end    

       
endmodule   



// adding the new register Protection management register for read

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--   PRTOTECTION MANAGEMENT REGISTER MODULE              --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module ProtectionManagementRegister;
//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif






//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]



    parameter [7:0] ProcManReg_default = 'b11111111;
   
    // non volatile configuration register

    reg [7:0] PMR;

     
    //--------------
    // Init
    //--------------


    initial begin
        
        PMR[7:0] = ProcManReg_default;

    end


    //------------------------------------------
    // write Non Volatile Configuration Register
    //------------------------------------------

    // see "Program" module



    //-----------------------------------------
    // Read Non Volatile Configuration register
    //-----------------------------------------
    // NB : "Read Non Volatile Configuration register" operation is also modelled in N25Qxxx.module

    reg enable_PMR_read = 0;
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read Protection Management Reg") fork 
        
        enable_PMR_read=1;

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_PMR_read=0;
        
    join    

 endmodule    





/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--   NON VOLATILE CONFIGURATION REGISTER MODULE          --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module NonVolatileConfigurationRegister(NVConfigReg);

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif



//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]


    // parameter [15:0] NVConfigReg_default = 'b1111111111111110;
    // parameter [15:0] NVConfigReg_default = 'b1111111111111111;
    // parameter [15:0] NVConfigReg_default = NVCR_DEFAULT_VALUE;
    input [15:0] NVConfigReg;
   
    // non volatile configuration register

    reg [15:0] NVCR = 'h8FFF;

     
    //--------------
    // Init
    //--------------


    initial begin
        #1;
        // $display("In NVCR : nvcr default value is %h  and nvcr=%h",NVConfigReg ,NVCR, $time);
        
        NVCR[15:0] = NVConfigReg;
        // NVCR[15:0] = NVConfigReg_default;
                                            // NVCR[15:12] = 'b1111; //dummy clock cycles number (default)
                                            // NVCR[11:9] = 'b111; // XIP disabled (default)
                                            // NVCR[8:6] = 'b111; //Output driver strength (default)
                                            // NVCR[5] = 'b1; //Double Transfer Rate disabled(default)
                                            // NVCR[4] = 'b1; // Reset/Hold enabled(default)
                                            // NVCR[3] = 'b1; //Quad Input Command disabled (default)
                                            // NVCR[2] = 'b1; //Dual Input Command disabled (default)
                                            // NVCR[1] = 'b1; //reserved default 1(N25Q032),128MB segment enabled for 3bytes operations (default)(N25Q256)
                                            // NVCR[0] = 'b1; //reserved default 1(N25Q032), Address mode selection(default)(N25Q256)
                                            
        
    end


    //------------------------------------------
    // write Non Volatile Configuration Register
    //------------------------------------------

    // see "Program" module



    //-----------------------------------------
    // Read Non Volatile Configuration register
    //-----------------------------------------
    // NB : "Read Non Volatile Configuration register" operation is also modelled in N25Qxxx.module

    reg enable_NVCR_read;
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read NV Configuration Reg") fork 
        
        enable_NVCR_read=1;

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_NVCR_read=0;
        
    join    

    


    



endmodule   














/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--   NON VOLATILE CONFIGURATION REGISTER MODULE          --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module VolatileConfigurationRegister;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif



//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]

    parameter [7:0] VConfigReg_default = 'b10001011;
   
    // volatile configuration register

    reg [7:0] VCR;

     
    //--------------
    // Init
    //--------------


    initial begin
        
        VCR[7:0] = VConfigReg_default;
                                            // VCR[7:4] = 'b1111; //dummy clock cycles number (default)
                                            // VCR[3] = 'b1; // XIP disabled (default)
                                            // VCR[2] = 'b0; //reserved
                                            //VCR[1:0]='b11 // wrap. Continous reading (Default): All bytes are read sequentially
        
    end


    //------------------------------------------
    // write Volatile Configuration Register
    //------------------------------------------

    // see "Program" module



    //-----------------------------------------
    // Read Volatile Configuration register
    //-----------------------------------------
    // NB : "Read Volatile Configuration register" operation is also modelled in N25Qxxx.module

    reg enable_VCR_read;
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read Volatile Configuration Reg") fork 
        
        enable_VCR_read=1;

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_VCR_read=0;
        
    join    

    


    



endmodule   














/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--   NON VOLATILE CONFIGURATION REGISTER MODULE          --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module VolatileEnhancedConfigurationRegister;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif




//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]


    parameter [7:0] VEConfigReg_default = 'b11011111;
   
    // non volatile configuration register

    reg [7:0] VECR;

     
    //--------------
    // Init
    //--------------


    initial begin
        
        VECR[7:0] = VEConfigReg_default;
                                            // VECR[7] = 'b1; //quad input command disable (default)
                                            // VECR[6] = 'b1; // dual input command disable (default)
                                            // VECR[5] = 'b1; //DTR disable (default 1 = off)
                                            // VECR[4] = 'b1; // Reset/Hold disable(default)
                                            // VECR[3] = 'b1; //Accelerator pin enable in Quad SPI protocol(default) //not implemented
                                            //VECR[2:0] ='b111; // Output driver strength
        
    end

always @VECR if (N25Qxxx.Vcc_L2) begin

if (VECR[7]==0) N25Qxxx.protocol="quad";
else if (VECR[6]==0) N25Qxxx.protocol="dual";
else if (VECR[7]==1 && VECR[6]==1) N25Qxxx.protocol="extended";
 $display("[%0t ns] ==INFO== Protocol selected is %0s",$time,N25Qxxx.protocol);

// if (VECR[5] == N25Qxxx.DoubleTransferRate) begin // this is true if host is changing DTR mode
//     N25Qxxx.DoubleTransferRate = !VECR[5];
//     $display("[%0t ps] ==INFO== %0s Transfer Rate selected", $time, (N25Qxxx.DoubleTransferRate ? "Double" : "Single"));
// end

end


    //------------------------------------------
    // write Volatile Enhanced Configuration Register
    //------------------------------------------

    // see "Program" module



    //-----------------------------------------
    // Read Volatile Enhanced Configuration register
    //-----------------------------------------
    // NB : "Read Volatile Enhanced Configuration register" operation is also modelled in N25Qxxx.module

    reg enable_VECR_read;
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read VE Configuration Reg") fork 
        
        enable_VECR_read=1;

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_VECR_read=0;
        
    join    

    


    



endmodule   














/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           READ MODULE                                 --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module Read;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif





//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]    
   
   
    reg enable, enable_fast, enable_rsfdp = 0;




    //--------------
    //  Read
    //--------------
    // NB : "Read" operation is also modelled in N25Qxxx.module
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read") fork 
        
        begin
           
            if(prog.prog_susp && prog.page_susp==f.pag(N25Qxxx.addr)) 
                $display("  [%0t ns] **WARNING** It's not allowed to read the page whose program cycle is suspended",$time); 
            else begin    
                enable = 1;
                mem.setAddr(N25Qxxx.addr);
            end    
        end
        
        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault) 
            enable=0;
        
    join




    //--------------
    //  Read Fast
    //--------------

    always @(N25Qxxx.seqRecognized) if ((N25Qxxx.cmdRecName=="Read Fast") || 
                                        (N25Qxxx.cmdRecName=="Read Fast DTR") 
                                        ) fork

        begin
             if(prog.prog_susp && prog.page_susp==f.pag(N25Qxxx.addr)) 
                $display("  [%0t ns] **WARNING** It's not allowed to read the page whose program cycle is suspended",$time); 
            else begin 
            
            mem.setAddr(N25Qxxx.addr);
            $display("  [%0t ns] Dummy byte expected ...",$time);
            N25Qxxx.latchingMode="Y"; //Y=dummy
            @N25Qxxx.dummyLatched;
            enable_fast = 1;
            N25Qxxx.latchingMode="N";

            end
        end

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_fast=0;
    
    join


   //-----------------------------
   //  Read Flash Discovery Table
   //-----------------------------

    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read Serial Flash Discovery Parameter") fork

        begin
            
            FlashDiscPar.setAddr(N25Qxxx.addr);
            $display("  [%0t ns] Dummy byte expected ...",$time);
            N25Qxxx.latchingMode="Y"; //Y=dummy
            @N25Qxxx.dummyLatched;
            enable_rsfdp = 1;
            N25Qxxx.latchingMode="N";

        end

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_rsfdp=0;
    
    join





    //-----------------
    //  Read ID
    //-----------------

    reg enable_ID;
    reg [4:0] ID_index;

    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read ID") fork 
        
        begin
            enable_ID = 1;
            ID_index=0;
        end
        
        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_ID=0;
        
    join


    //--------------------------
    // Multiple I/O Read ID
    //--------------------------


    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Multiple I/O Read ID") fork 
        
        begin
            enable_ID = 1;
            ID_index=0;
        end
        
        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_ID=0;
        
    join


    //-------------
    //  Dual Read  
    //-------------

    reg enable_dual=0;
    
    
      always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Dual Output Fast Read" ||
                                          N25Qxxx.cmdRecName=="Dual I/O Fast Read" ||
                                          N25Qxxx.cmdRecName=="Dual Command Fast Read" ||
                                          N25Qxxx.cmdRecName=="Dual Command Fast Read DTR" ||
                                          N25Qxxx.cmdRecName=="Dual Command DOFRDTR" ||
                                          N25Qxxx.cmdRecName=="Dual Command DIOFRDTR" ||
                                          N25Qxxx.cmdRecName=="Extended command DOFRDTR" ||
                                          N25Qxxx.cmdRecName=="Extended command DIOFRDTR"
                                          ) fork

          begin

           if(prog.prog_susp && prog.page_susp==f.pag(N25Qxxx.addr)) 
                $display("  [%0t ns] **WARNING** It's not allowed to read the page whose program cycle is suspended",$time); 
            else begin
            
              mem.setAddr(N25Qxxx.addr);
              $display("  [%0t ns] Dummy byte expected ...",$time);
              
              N25Qxxx.latchingMode="Y"; //Y=dummy
              @N25Qxxx.dummyLatched;
              enable_dual = 1;
              N25Qxxx.latchingMode="N";

             end 
          end 

          @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
              enable_dual=0;
    
      join



  //-------------------------
  //  Quad Read  
  //-------------------------

    reg enable_quad=0;
    
    
      always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Quad Output Read" ||
                                          N25Qxxx.cmdRecName=="Quad I/O Fast Read" ||
                                          N25Qxxx.cmdRecName=="Quad Command Fast Read" || 
                                          N25Qxxx.cmdRecName=="Quad Command Fast Read DTR" || 
                                          N25Qxxx.cmdRecName=="Quad Command QOFRDTR" || 
                                          N25Qxxx.cmdRecName=="Quad Command QIOFRDTR" || 
                                          N25Qxxx.cmdRecName=="Extended command QOFRDTR" ||
                                          N25Qxxx.cmdRecName=="Extended command QIOFRDTR" 
                                          ) fork

          begin

           if(prog.prog_susp && prog.page_susp==f.pag(N25Qxxx.addr)) 
                $display("  [%0t ns] **WARNING** It's not allowed to read the page whose program cycle is suspended",$time); 
                
            else if(prog.sec_erase_susp && prog.sec_susp==f.sec(N25Qxxx.addr)) 
                 $display("  [%0t ns] **WARNING** It's not allowed to read the sector whose erase cycle is suspended",$time);

            else if (prog.subsec_erase_susp && prog.sec_susp==f.sec(N25Qxxx.addr))
                 $display("  [%0t ns] **WARNING** It's not allowed to read the sector cointaining the subsector whose erase cycle is suspended",$time);


            else begin
            
              mem.setAddr(N25Qxxx.addr);
              $display("  [%0t ns] Dummy clock cycles expected ...",$time);
              N25Qxxx.latchingMode="Y"; //Y=dummy
              N25Qxxx.quadMode = 1;
              @N25Qxxx.dummyLatched;
              enable_quad = 1;
              N25Qxxx.latchingMode="N";

            end
            
          end 

          @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
              enable_quad=0;
    
      join




    //-------------
    //  Read OTP 
    //-------------
    // NB : "Read OTP" operation is also modelled in N25Qxxx.module

    reg enable_OTP=0;
    
    
      always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read OTP") fork 
        
          begin
              $display("  [%0t ns] Dummy byte expected ...",$time);
              N25Qxxx.latchingMode="Y"; //Y=dummy
              @N25Qxxx.dummyLatched;

              enable_OTP = 1;
              N25Qxxx.latchingMode="N";
              OTP.setAddr(N25Qxxx.addr);
          end
        
          @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
              enable_OTP=0;
        
      join
    
    


    


endmodule


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           LASH DISCOVERY PARAMETER MODULE             --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

`timescale 1ns / 1ns

module FlashDiscoveryParameter(sfdp_file);

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif




//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]



  input [2048*8:1] sfdp_file ;
//-----------------------------
// data structures definition
//-----------------------------

 reg [dataDim-1:0] FDP [0:FDP_dim-1];


  //------------------------------
  // Memory management variables
  //------------------------------


    reg [23:0] fdpAddr;

    integer i;

 //-----------
 //  Init
 //-----------

    initial begin 

        for (i=0; i<=FDP_dim-1; i=i+1) 
            FDP[i] = data_NP;
        #1;
         
         // if ( `FILENAME_sfdp!="" && `FILENAME_sfdp!=" ") begin
         if ( sfdp_file!="" && sfdp_file!=" ") begin

            $readmemb(sfdp_file, FDP);
            $display("[%0t ns] ==INFO== Load flash discovery paramater table content from file: \"%0s\".", $time, sfdp_file);
    
         end
    end


//read data from the fdp file    
task readData;

    output [dataDim-1:0] data;
    begin
        
        if (fdpAddr[FDP_addrDim -1 :0] < FDP_dim-1) begin

            data = FDP[fdpAddr[FDP_addrDim -1 :0]];

            fdpAddr[FDP_addrDim -1 :0] = fdpAddr[FDP_addrDim -1 :0] + 1;
            $display("In SFDP READ: fdpAddr=%h , data=%h ", fdpAddr[FDP_addrDim -1 :0], data , $time);

            
        end else 
            
            $display("  [%0t ns] **WARNING** Highest address reached", $time);
    end

endtask
 // set start address & page index
    // (for program and read operations)
    
    task setAddr;

    input [addrDim-1:0] addr;

    begin

        fdpAddr[FDP_addrDim -1 :0] = addr[FDP_addrDim -1 :0];
    
    end
    
    endtask

endmodule
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           LOCK MANAGER MODULE                         --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

`timescale 1ns / 1ps 

module LockManager;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif





//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]




//---------------------------------------------------
// Data structures for protection status modelling
//---------------------------------------------------


// array of sectors lock status (status determinated by Block Protect Status Register bits)
reg [nSector-1:0] lock_by_SR; //(1=locked)

  // Lock Registers (there is a pair of Lock Registers for each sector)
  reg [nSector-1:0] LockReg_WL ;   // Lock Register Write Lock bit (1=lock enabled)
  reg [nSector-1:0] LockReg_LD ;   // Lock Register Lock Down bit (1=lock down enabled)

integer i;






//----------------------------
// Initial protection status
//----------------------------

initial
    for (i=0; i<=nSector-1; i=i+1)
        lock_by_SR[i] = 0;
        //LockReg_WL & LockReg_LD are initialized by powerUp  
    


//------------------------
// Reset signal effects
//------------------------

  
  always @N25Qxxx.resetEvent 
      for (i=0; i<=nSector-1; i=i+1) begin
        if(PMReg.PMR[5] == 0) begin
          LockReg_WL[i] = 1;
        end
        else begin
          LockReg_WL[i] = 0;
        end
        LockReg_LD[i] = 0;
      end    





//----------------------------------
// Power up : reset lock registers
//----------------------------------


  always @(N25Qxxx.ReadAccessOn) if(N25Qxxx.ReadAccessOn) 
      for (i=0; i<=nSector-1; i=i+1) begin
          LockReg_WL[i] = 0;
          LockReg_LD[i] = 0;
      end







//------------------------------------------------
// Protection managed by BP status register bits
//------------------------------------------------

integer nLockedSector;
integer temp;


  
  always @(`TB or `BP3 or `BP2 or `BP1 or `BP0) 
  begin

      for (i=0; i<=nSector-1; i=i+1) //reset lock status of all sectors
          lock_by_SR[i] = 0;
    
      temp = {`BP3, `BP2, `BP1, `BP0};
      nLockedSector = 2**(temp-1); 

      if (nLockedSector>0 && `TB==0) // upper sectors protected
          for ( i=nSector-1 ; i>=nSector-nLockedSector ; i=i-1 )
          begin
              lock_by_SR[i] = 1;
              $display("  [%0t ns] ==INFO== Sector %0d locked", $time, i);
          end
    
      else if (nLockedSector>0 && `TB==1) // lower sectors protected 
          for ( i = 0 ; i <= nLockedSector-1 ; i = i+1 ) 
          begin
              lock_by_SR[i] = 1;
              $display("  [%0t ns] ==INFO== Sector %0d locked", $time, i);
          end

  end


//--------------------------------------
// Protection managed by Lock Register
//--------------------------------------

reg enable_lockReg_read=0;




    reg [sectorAddrDim-1:0] sect;
    reg [dataDim-1:0] sectLockReg;



    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Write Lock Reg")
      // if (!PMReg.PMR[5]) begin
      //     $display("  [%0t ps] **WARNING** PMR bit is set. Write lock register is not allowed!", $time);
      //     disable WRLR;
      //  end else 
       fork : WRLR
        begin : exe1
            sect = f.sec(N25Qxxx.addr);
            N25Qxxx.latchingMode = "D";
            @(N25Qxxx.dataLatched) sectLockReg = N25Qxxx.data;
        end

        begin : exe2
            @(posedge N25Qxxx.S);
            disable exe1;
            disable reset;
            -> stat.WEL_reset;
            if(`WEL==0)
                N25Qxxx.f.WEL_error;
            else if (LockReg_LD[sect]==1)
                $display("  [%0t ns] **WARNING** Lock Down bit is set. Write lock register is not allowed!", $time);
            else begin
                LockReg_LD[sect]=sectLockReg[1];
                LockReg_WL[sect]=sectLockReg[0];
                $display("  [%0t ns] Command execution: lock register of sector %0d set to (%b,%b)", 
                          $time, sect, LockReg_LD[sect], LockReg_WL[sect] );
            end    
        end

        begin : reset
            @N25Qxxx.resetEvent;
            disable exe1;
            disable exe2;
        end
        
    join




    // Read lock register

    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read Lock Reg") fork

        begin
          sect = f.sec(N25Qxxx.addr); 
          N25Qxxx.dataOut = {4'b0, LockReg_LD[sect], LockReg_WL[sect]};
          enable_lockReg_read=1;
        end   
        
        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_lockReg_read=0;
        
    join







//-------------------------------------------
// Function to test sector protection status
//-------------------------------------------

function isProtected_by_SR;
input [addrDim-1:0] byteAddr;
reg [sectorAddrDim-1:0] sectAddr;
begin

    sectAddr = f.sec(byteAddr);
    isProtected_by_SR = lock_by_SR[sectAddr]; 

end
endfunction





function isProtected_by_lockReg;
input [addrDim-1:0] byteAddr;
reg [sectorAddrDim-1:0] sectAddr;
begin

      sectAddr = f.sec(byteAddr);
      isProtected_by_lockReg = LockReg_WL[sectAddr];
      $display("  [%0t ns] isProtected_by_lockReg: %h sectAddr: %h", $time,isProtected_by_lockReg, sectAddr);

end
endfunction





function isAnySectorProtected;
input required;
begin

    i=0;   
    isAnySectorProtected=0;
    while(isAnySectorProtected==0 && i<=nSector-1) begin 
          isAnySectorProtected=lock_by_SR[i] || LockReg_WL[i];
        i=i+1;
    end    

end
endfunction







endmodule













/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           DUAL OPS MODULE                             --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
// In this module are modeled 
// "Dual Input Fast Program"
// and "Dual Output Fast program"
// commands

`timescale 1ns / 1ps

`ifdef HOLD_pin
  module DualQuadOps (S, C, ck_count, DoubleTransferRate, DQ0, DQ1, Vpp_W_DQ2, HOLD_DQ3);
`else
  module DualQuadOps (S, C, ck_count, DoubleTransferRate, DQ0, DQ1, Vpp_W_DQ2, RESET_DQ3);
`endif

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif






//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]

    input S;
    input C;
    input [2:0] ck_count;
    input DoubleTransferRate;

    output DQ0, DQ1, Vpp_W_DQ2;
    
   `ifdef HOLD_pin
    output HOLD_DQ3;
   `endif
 
     `ifdef RESET_pin
        output RESET_DQ3; 
    `endif



    

    //----------------------------
    // Latching data (dual input)
    //----------------------------

    always @(C) if (N25Qxxx.logicOn && N25Qxxx.latchingMode=="F") begin : CP_latchData_fast //fast=dual
      //if (C==1) begin // ENABLE if posedge C in all modes 
      if (C==1 || (C==0 && DoubleTransferRate)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode

        N25Qxxx.data[N25Qxxx.iData] = DQ1;
        N25Qxxx.data[N25Qxxx.iData-1] = DQ0;

        if (N25Qxxx.iData>=3)
            N25Qxxx.iData = N25Qxxx.iData-2;
        else begin
        if (N25Qxxx.cmdRecName=="Write NV Configuration Reg" && prog.LSByte) begin
            N25Qxxx.LSdata=N25Qxxx.data;
             prog.LSByte=0;
        end 
            -> N25Qxxx.dataLatched;
            $display("  [%0t ns] Data latched: %h", $time,N25Qxxx.data);
            N25Qxxx.iData=N25Qxxx.dataDim-1;
        end    
      end
    end


    //----------------------------
    // Latching data (quad input)
    //----------------------------

    always @(C) if (N25Qxxx.logicOn && N25Qxxx.latchingMode=="Q") begin : CP_latchData_quad //quad
      // if (C==1) begin // ENABLE if posedge C in all modes 
      if (C==1 || (C==0 && DoubleTransferRate)) begin // ENABLE if posedge C in all modes or negedge C in DTR mode
        `ifdef HOLD_pin
        N25Qxxx.data[N25Qxxx.iData] = HOLD_DQ3;
        `endif
       
       `ifdef RESET_pin
        N25Qxxx.data[N25Qxxx.iData] = RESET_DQ3;
        `endif
        
        N25Qxxx.data[N25Qxxx.iData-1] = Vpp_W_DQ2;
        N25Qxxx.data[N25Qxxx.iData-2] = DQ1;
        N25Qxxx.data[N25Qxxx.iData-3] = DQ0;
        if (N25Qxxx.iData==7)
            N25Qxxx.iData = N25Qxxx.iData-4;
        else begin
            if (N25Qxxx.cmdRecName=="Write NV Configuration Reg" && prog.LSByte) begin
            N25Qxxx.LSdata=N25Qxxx.data;
             prog.LSByte=0;
        end
            -> N25Qxxx.dataLatched;
            $display("  [%0t ns] Data latched: %h", $time,N25Qxxx.data);
            N25Qxxx.iData=N25Qxxx.dataDim-1;
        end    
      end
    end





    //----------------------------------
    // dual read (DQ1 and DQ0 out bit)
    //----------------------------------


    reg bitOut='hZ, bitOut_extra='hZ;
    
    reg [addrDim-1:0] readAddr;
    reg [dataDim-1:0] dataOut;

    event sendToBus_dual; 
    
    
    // read with DQ1 and DQ0 out bit (For dual output fast read: DOFR/DIOFR in ext-SPI and DIO-SPI modes)
    always @(negedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_dual==1) begin
    doubleIO_memread_output(ck_count * ((DoubleTransferRate || (((N25Qxxx.cmd
  == 'h3D) || (N25Qxxx.cmd == 'hBD) ||(N25Qxxx.cmd == 'h0D) || (N25Qxxx.cmd == 'h39) || (N25Qxxx.cmd == 'hBE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0))  +1)); // 2*ck_count if DTR and when the command is 'hBD or 'h3D, O.W. 1*ck_count
  // == 'h3D) || (N25Qxxx.cmd == 'hBD) ||(N25Qxxx.cmd == 'h0D) || (N25Qxxx.cmd == 'h3E) || (N25Qxxx.cmd == 'hBE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0))  +1)); // 2*ck_count if DTR and when the command is 'hBD or 'h3D, O.W. 1*ck_count
    end  

    always @(posedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_dual==1
    && (DoubleTransferRate || (((N25Qxxx.cmd == 'h3D) || (N25Qxxx.cmd ==
    'hBD)|| (N25Qxxx.cmd == 'h0D) ||  (N25Qxxx.cmd == 'h39) || (N25Qxxx.cmd == 'hBE)|| (N25Qxxx.cmd == 'h0E)) ? 1 : 0)) && N25Qxxx.dtr_dout_started) begin
    // 'hBD)|| (N25Qxxx.cmd == 'h0D) ||  (N25Qxxx.cmd == 'h3E) || (N25Qxxx.cmd == 'hBE)|| (N25Qxxx.cmd == 'h0E)) ? 1 : 0)) && N25Qxxx.dtr_dout_started) begin
    doubleIO_memread_output(2*ck_count + 1);
    end  

   //RK  always @(negedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_dual==1) begin
   //RK    doubleIO_memread_output(ck_count * ((((N25Qxxx.cmd == 'h3D) || 
   //RK        (N25Qxxx.cmd == 'hBD)) ? 1 : 0)  +1)); // 2*ck_count if DTR and when the command is 'hBD or 'h3D, O.W. 1*ck_count
   //RK   end  

   //RK  always @(posedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_dual==1 &&  
   //RK        (((N25Qxxx.cmd == 'h3D) || (N25Qxxx.cmd == 'hBD)) ? 1 : 0) && N25Qxxx.dtr_dout_started) begin
     //RK doubleIO_memread_output(2*ck_count + 1);
   //RK   end  

    task doubleIO_memread_output;
      input [2:0] bit_count;
      begin

            if(bit_count==0 || bit_count==4)
            begin
                readAddr = mem.memAddr;
                mem.readData(dataOut); //read data and increments address
                f.out_info(readAddr, dataOut);
                N25Qxxx.dataOut=dataOut; //N25Qxxx.dataOut is accessed by Transactions  
            end
           
           #tCLQX
            bitOut = dataOut[ dataDim-1 - (2*(bit_count%4)) ]; //%=modulo operator
            bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
            
            -> sendToBus_dual;
      end
    endtask  

// read with DQ1 and DQ0 out bit
    always @(negedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="dual") begin : CP_read_dual
        doubleIO_IDreg_output(ck_count * ((DoubleTransferRate ||
        (((N25Qxxx.cmd == 'h3D) || (N25Qxxx.cmd == 'hBD) || (N25Qxxx.cmd ==
        'h0D) || (N25Qxxx.cmd == 'h39) || (N25Qxxx.cmd == 'hBE) || (N25Qxxx.cmd == 'h0E)) ? 1 : 0))+1)); // 2*ck_count if DTR, nd when the command is 'hBD or 'h3D,O.W. 1*ck_count
        // 'h0D) || (N25Qxxx.cmd == 'h3E) || (N25Qxxx.cmd == 'hBE) || (N25Qxxx.cmd == 'h0E)) ? 1 : 0))+1)); // 2*ck_count if DTR, nd when the command is 'hBD or 'h3D,O.W. 1*ck_count
    end

  //RK always @(negedge(C)) if(N25Qxxx.logicOn && N25Qxxx.protocol=="dual") begin : CP_read_dual
  //RK   doubleIO_IDreg_output(ck_count * ((((N25Qxxx.cmd == 'h3D) || 
  //RK      (N25Qxxx.cmd == 'hBD)) ? 1 : 0)  +1)); // 2*ck_count if DTR, nd when the command is 'hBD or 'h3D,O.W. 1*ck_count
  //RK end

  // always @(posedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="dual" && (DoubleTransferRate || (((N25Qxxx.cmd == 'h3D) || (N25Qxxx.cmd == 'hBD)|| (N25Qxxx.cmd == 'h0D) || (N25Qxxx.cmd == 'h3E) || (N25Qxxx.cmd == 'hBE) || (N25Qxxx.cmd == 'h0E) ) ? 1 : 0)) && N25Qxxx.dtr_dout_started) begin
  always @(posedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="dual" && (DoubleTransferRate || (((N25Qxxx.cmd == 'h3D) || (N25Qxxx.cmd == 'hBD)|| (N25Qxxx.cmd == 'h0D) || (N25Qxxx.cmd == 'h39) || (N25Qxxx.cmd == 'hBE) || (N25Qxxx.cmd == 'h0E) ) ? 1 : 0)) && N25Qxxx.dtr_dout_started) begin
      doubleIO_IDreg_output(2*ck_count + 1);
  end

  //RK always @(posedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="dual" &&  
  //RK      (((N25Qxxx.cmd == 'h3D) || (N25Qxxx.cmd == 'hBD)) ? 1 : 0) && N25Qxxx.dtr_dout_started) begin
  //RK   doubleIO_IDreg_output(2*ck_count + 1);
  //RK end


  task doubleIO_IDreg_output;
    input [2:0] bit_count;
    begin
     #1; 
     if (read.enable_rsfdp==1) begin
  
       if(bit_count==0 || bit_count==4)
       begin
           readAddr = FlashDiscPar.fdpAddr;
           mem.readData(dataOut); //read data and increments address
           f.out_info(readAddr, dataOut);
        end
        
        #tCLQX
        bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
        bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;
  
     end else if (stat.enable_SR_read==1) begin
        
        if(bit_count==0 || bit_count==4) begin 
            dataOut = stat.SR;
            f.out_info(readAddr, dataOut);
        end    
        
        #tCLQX
        bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
        bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;

     end else if (flag.enable_FSR_read==1) begin
        
        if(bit_count==0 || bit_count==4) begin

            dataOut = flag.FSR;
            f.out_info(readAddr, dataOut);
        end    
        
        #tCLQX
         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;

     end else if (VolatileReg.enable_VCR_read==1) begin
        
       if(bit_count==0 || bit_count==4) begin
 
            dataOut = VolatileReg.VCR;
            f.out_info(readAddr, dataOut);
       end    
       
        #tCLQX
         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;

    //added   
     end else if (PMReg.enable_PMR_read==1) begin
        
       if(bit_count==0 || bit_count==4) begin
 
            dataOut = PMReg.PMR;
            f.out_info(readAddr, dataOut);
       end    
        
        #tCLQX

         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;
   
     end else if (VolatileEnhReg.enable_VECR_read==1) begin
        
        if(bit_count==0 || bit_count==4) begin

            dataOut = VolatileEnhReg.VECR;
            f.out_info(readAddr, dataOut);
        end    
        
        #tCLQX
         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;
    

     end else if (NonVolatileReg.enable_NVCR_read==1) begin
     
        if((bit_count==0 || bit_count==4) && N25Qxxx.firstNVCR == 1) begin
 
            dataOut = NonVolatileReg.NVCR[7:0];
            f.out_info(readAddr, dataOut);
            N25Qxxx.firstNVCR=0;
          
        end else if((bit_count==0 || bit_count==4) && N25Qxxx.firstNVCR == 0) begin
           dataOut = NonVolatileReg.NVCR[15:8];
           f.out_info(readAddr, dataOut);
           N25Qxxx.firstNVCR=1;
                                   
        end
        

         #tCLQX
         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4))]; 
        -> sendToBus_dual;

`ifdef byte_4

   end else if (ExtAddReg.enable_EAR_read==1) begin
        
        if(bit_count==0 || bit_count==4)  begin
            
            dataOut = ExtAddReg.EAR[7:0];
            f.out_info(readAddr, dataOut);
        end
        
        #tCLQX
         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;

 `endif     
      end else if (lock.enable_lockReg_read==1) begin

          if(bit_count==0 || bit_count==4)  begin

              readAddr = f.sec(N25Qxxx.addr);
              f.out_info(readAddr, dataOut);
          end
          // dataOut is set in LockManager module
       
          #tCLQX
         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
        -> sendToBus_dual;


    
      end else if (read.enable_OTP==1) begin 

          if(bit_count==0 || bit_count==4)  begin

              readAddr = 'h0;
              readAddr = OTP.addr;
              OTP.readData(dataOut); //read data and increments address
              f.out_info(readAddr, dataOut);
          end
          
           #tCLQX
          bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
          bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
          -> sendToBus_dual;

   
   
    end else if (read.enable_ID==1) begin 

        if(bit_count==0 || bit_count==4)  begin

            readAddr = 'h0;
            readAddr = read.ID_index;
            
            if (read.ID_index==0)      dataOut=Manufacturer_ID;
            else if (read.ID_index==1) dataOut=MemoryType_ID;
            else if (read.ID_index==2) dataOut=MemoryCapacity_ID;
            
            if (read.ID_index<=1) read.ID_index=read.ID_index+1;
            //RK else read.ID_index=0;


            f.out_info(readAddr, dataOut);
        
        end
         
         #tCLQX

         bitOut = dataOut[dataDim-1- (2*(bit_count%4))];
         bitOut_extra = dataOut[ dataDim-2 - (2*(bit_count%4)) ]; 
         -> sendToBus_dual;
    end

    
   
end
endtask


    always @sendToBus_dual begin
      -> N25Qxxx.sendToBus_stack;
      #0;
      if(N25Qxxx.die_active == 1) begin
        fork

            N25Qxxx.dtr_dout_started = 1'b1;
            begin
                force DQ1 = 1'bX;
                force DQ0 = 1'bX; 
            end
           begin 
              if((N25Qxxx.cmdRecName == "Read Fast") || 
                (N25Qxxx.cmdRecName == "Dual Command Fast Read") || 
                (N25Qxxx.cmdRecName == "Quad Command Fast Read") || 
                (N25Qxxx.cmdRecName == "Dual Output Fast Read") ||
                (N25Qxxx.cmdRecName == "Dual I/O Fast Read") ||
                (N25Qxxx.cmdRecName == "Quad I/O Fast Read") 
                ) begin 
          //     #(tCLQV - tCLQX) 
                #(tCLQV/2 - tCLQX - 1); 
              end 
              else begin
                #(tCLQV - tCLQX - 1) ;
              end
              // #(tCLQV -tCLQX) begin
                force DQ1 = bitOut;
                force DQ0 = bitOut_extra;
              // end        
            end

        join
      end
  end



    always @(negedge(C)) if(N25Qxxx.logicOn && (read.enable_dual==1 || N25Qxxx.protocol=="dual")) 
        @(posedge S) begin 
           #tSHQZ 
            release DQ0;
            release DQ1;
        end    
   
    //--------------------------------------------------------------
    // Quad read (RESET_DQ3/HOLD_DQ3 Vpp_W_DQ2 DQ1 and DQ0 out bit)
    //--------------------------------------------------------------


    reg bitOut0='hZ, bitOut1='hZ, bitOut2='hZ, bitOut3='hZ;
    

    event sendToBus_quad; 
    
    always @(negedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_quad==1) begin
    quadIO_memread_output(ck_count * ((DoubleTransferRate || (((N25Qxxx.cmd
  == 'h6D) || (N25Qxxx.cmd == 'hED) ||(N25Qxxx.cmd == 'h0D)|| (N25Qxxx.cmd == 'h3A) || (N25Qxxx.cmd == 'hEE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0)) +1)); // 2*ck_count if DTR and when the command is 'hED, O.W. 1*ck_count
  // == 'h6D) || (N25Qxxx.cmd == 'hED) ||(N25Qxxx.cmd == 'h0D)|| (N25Qxxx.cmd == 'h6E) || (N25Qxxx.cmd == 'hEE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0)) +1)); // 2*ck_count if DTR and when the command is 'hED, O.W. 1*ck_count
    end   

//RK     always @(negedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_quad==1) begin
//RK 
//RK    quadIO_memread_output(ck_count * ((((N25Qxxx.cmd == 'h6D) || 
//RK            (N25Qxxx.cmd == 'hED)) ? 1 : 0) +1)); // 2*ck_count if DTR and when the command is 'hED, O.W. 1*ck_count
//RK      end  

    // always @(posedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_quad==1 && (DoubleTransferRate || (((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED) ||(N25Qxxx.cmd == 'h0D)|| (N25Qxxx.cmd == 'h6E) || (N25Qxxx.cmd == 'hEE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0)) && N25Qxxx.dtr_dout_started) begin
    always @(posedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_quad==1 && (DoubleTransferRate || (((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED) ||(N25Qxxx.cmd == 'h0D)|| (N25Qxxx.cmd == 'h3A) || (N25Qxxx.cmd == 'hEE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0)) && N25Qxxx.dtr_dout_started) begin

    //RK always @(posedge(C)) if(N25Qxxx.logicOn && N25Qxxx.read.enable_quad==1 &&  
    //RK       (((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED)) ? 1 : 0) && N25Qxxx.dtr_dout_started) begin
    quadIO_memread_output(2*ck_count + 1);
     end  

    task quadIO_memread_output;
      input [2:0] bit_count;
      begin

            if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)//verificare
            begin
                readAddr = mem.memAddr;
                mem.readData(dataOut); //read data and increments address
                f.out_info(readAddr, dataOut);
                N25Qxxx.dataOut=dataOut; //N25Qxxx.dataOut is accessed by Transactions  
            end
            
            #tCLQX
            bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
            bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
            bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
            bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
            -> sendToBus_quad;
            
    end  
    endtask


// read with RESET_DQ3/HOLD_DQ3 Vpp_W_DQ2 DQ1 and DQ0 out bit

 always @(negedge(C)) if(N25Qxxx.logicOn && N25Qxxx.protocol=="quad") begin : CP_read_quad
  if(DoubleTransferRate == 1) begin
    quadIO_IDreg_output(ck_count * ((((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED)) ? 1 : 0) )); // 2*ck_count if DTR and when the command is 'hED, O.W. 1*ck_count
  end 
  else begin
    quadIO_IDreg_output(ck_count * ((((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED)) ? 1 : 0) +1)); 
  end
 end

 //RK always @(posedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="quad" &&  
 //RK       (((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED)) ? 1 : 0) && N25Qxxx.dtr_dout_started) begin
 // always @(posedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="quad" && (DoubleTransferRate || (((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED) ||(N25Qxxx.cmd == 'h0D)|| (N25Qxxx.cmd == 'h6E) || (N25Qxxx.cmd == 'hEE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0))) begin
 always @(posedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="quad" && (DoubleTransferRate || (((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED) ||(N25Qxxx.cmd == 'h0D)|| (N25Qxxx.cmd == 'h3A) || (N25Qxxx.cmd == 'hEE) ||(N25Qxxx.cmd == 'h0E) ) ? 1 : 0))) begin
 // always @(posedge C) if(N25Qxxx.logicOn && N25Qxxx.protocol=="quad" && (DoubleTransferRate || (((N25Qxxx.cmd == 'h6D) || (N25Qxxx.cmd == 'hED) ||(N25Qxxx.cmd == 'h0D) ) ? 1 : 0)) && N25Qxxx.dtr_dout_started) begin
    quadIO_IDreg_output(2*ck_count + 1);
 end

 task quadIO_IDreg_output;
   input [2:0] bit_count;
   begin   
   #1;
    if (read.enable_rsfdp==1) begin
  
       if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)
       begin
           readAddr = FlashDiscPar.fdpAddr;
           mem.readData(dataOut); //read data and increments address
           f.out_info(readAddr, dataOut);
        end
        
        #tCLQX
        bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
        bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
        bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
        bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;


    end else if (stat.enable_SR_read==1) begin
        
        if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)
        begin
            dataOut = stat.SR;
            f.out_info(readAddr, dataOut);
        end    
       
        #tCLQX
        bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
        bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
        bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
        bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;

     end else if (flag.enable_FSR_read==1) begin
        
        if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)
        begin
                
            dataOut = flag.FSR;
            f.out_info(readAddr, dataOut);
        end    
       
        #tCLQX
        bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
        bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
        bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
        bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;

     end else if (VolatileReg.enable_VCR_read==1) begin
        
       if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)
       begin
                               
            dataOut = VolatileReg.VCR;
            f.out_info(readAddr, dataOut);
       end    
       
        #tCLQX
        bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
        bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
        bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
        bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
        -> sendToBus_quad;
      
     // added   
     end else if (PMReg.enable_PMR_read==1) begin
        
       if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)
       begin
                               
            dataOut = PMReg.PMR;
            f.out_info(readAddr, dataOut);
       end    
        
        #tCLQX
        bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
        bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
        bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
        bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
        -> sendToBus_quad;
    
     end else if (VolatileEnhReg.enable_VECR_read==1) begin
        
        if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)
        begin
            dataOut = VolatileEnhReg.VECR;
            f.out_info(readAddr, dataOut);
        end    
       

        #tCLQX
         bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
         bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
         bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
         bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;
                                              

     end else if (NonVolatileReg.enable_NVCR_read==1) begin
     
      if((bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6) && N25Qxxx.firstNVCR == 1) begin
 
            dataOut = NonVolatileReg.NVCR[7:0];
            f.out_info(readAddr, dataOut);
            N25Qxxx.firstNVCR=0;
          
      end else if((bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6) && N25Qxxx.firstNVCR == 0) begin
           dataOut = NonVolatileReg.NVCR[15:8];
           f.out_info(readAddr, dataOut);
           N25Qxxx.firstNVCR=1;
                                   
       end

       
        #tCLQX

         bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
         bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
         bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
         bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;

`ifdef byte_4

   end else if (ExtAddReg.enable_EAR_read==1) begin
        
        if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)  begin
            
            dataOut = ExtAddReg.EAR[7:0];
            f.out_info(readAddr, dataOut);
        end
        
        #tCLQX

         bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
         bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
         bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
         bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;
`endif      
      end else if (lock.enable_lockReg_read==1) begin

          if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)  begin

              readAddr = f.sec(N25Qxxx.addr);
              f.out_info(readAddr, dataOut);
          end
          // dataOut is set in LockManager module
        #tCLQX

         bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
         bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
         bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
         bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;

    
      end else if (read.enable_OTP==1) begin 

          if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)  begin

              readAddr = 'h0;
              readAddr = OTP.addr;
              OTP.readData(dataOut); //read data and increments address
              f.out_info(readAddr, dataOut);
          end
         #tCLQX

         bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
         bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
         bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
         bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;

   
   
    end else if (read.enable_ID==1) begin 

        if(bit_count==0 || bit_count==2 || bit_count==4 || bit_count==6)  begin

            readAddr = 'h0;
            readAddr = read.ID_index;
            
            if (read.ID_index==0)      dataOut=Manufacturer_ID;
            else if (read.ID_index==1) dataOut=MemoryType_ID;
            else if (read.ID_index==2) dataOut=MemoryCapacity_ID;
            
            if (read.ID_index<=1) read.ID_index=read.ID_index+1;
            //RK else read.ID_index=0;


            f.out_info(readAddr, dataOut);
        
        end
         #tCLQX

         bitOut3 = dataOut[ dataDim-1 - (4*(bit_count%2)) ]; //%=modulo operator
         bitOut2 = dataOut[ dataDim-2 - (4*(bit_count%2)) ]; 
         bitOut1 = dataOut[ dataDim-3 - (4*(bit_count%2)) ]; 
         bitOut0 = dataOut[ dataDim-4 - (4*(bit_count%2)) ]; 
         -> sendToBus_quad;
    end

    
   
end
endtask



    always @sendToBus_quad begin
      -> N25Qxxx.sendToBus_stack;
      #0;
      if(N25Qxxx.die_active == 1) begin
        fork

            N25Qxxx.dtr_dout_started = 1'b1;
            begin
               
               `ifdef HOLD_pin
                force HOLD_DQ3 = 1'bX;
               `endif 
            
               `ifdef RESET_pin
                force RESET_DQ3 = 1'bX;
               `endif 
                force Vpp_W_DQ2 = 1'bX;
                force DQ1 = 1'bX;
                force DQ0 = 1'bX; 
            end
            begin
              if((N25Qxxx.cmdRecName == "Read Fast") || 
                (N25Qxxx.cmdRecName == "Dual Command Fast Read") || 
                (N25Qxxx.cmdRecName == "Quad Command Fast Read") || 
                (N25Qxxx.cmdRecName == "Dual Output Fast Read") ||
                (N25Qxxx.cmdRecName == "Dual I/O Fast Read") ||
                (N25Qxxx.cmdRecName == "Quad I/O Fast Read") || 
                (N25Qxxx.cmdRecName == "Quad Output Read") 
                ) begin 
          //     #(tCLQV - tCLQX) 
                #(tCLQV/2 - tCLQX - 1); 
              end 
              else begin
                #(tCLQV - tCLQX - 1) ;
              end
            
            // #(tCLQV-tCLQX) begin
               
               `ifdef HOLD_pin
                force HOLD_DQ3 = bitOut3;
               `endif
              
               `ifdef RESET_pin
                force RESET_DQ3 = bitOut3;
               `endif 
               
                
                force Vpp_W_DQ2 = bitOut2;
                force DQ1 = bitOut1;
                force DQ0 = bitOut0;
            end        

        join
      end
    end



    always @(negedge(C)) if(N25Qxxx.logicOn && read.enable_quad==1 || N25Qxxx.protocol=="quad") 
    
        @(posedge S) begin 
        
         #tSHQZ          
            release DQ0;
            release DQ1;
            release Vpp_W_DQ2;
            `ifdef HOLD_pin
            release HOLD_DQ3;
            `endif
            
            `ifdef RESET_pin
            release RESET_DQ3;
            `endif 

       end   

    `ifdef RESET_pin 
       
       always @N25Qxxx.resetEvent begin
       
            release DQ0; 
            release Vpp_W_DQ2;
           
            release RESET_DQ3;
       
       end
       
    `endif





endmodule







/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           OTP MEMORY MODULE                           --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module OTP_memory;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif





//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]










    reg [dataDim-1:0] mem [0:OTP_dim-1];
    reg [dataDim-1:0] buffer [0:OTP_dim-1];
      `define OTP_lockBit mem[OTP_dim-1][0]

    reg [OTP_addrDim-1:0] addr;
    reg overflow = 0;

    integer i;



    //-----------
    //  Init
    //-----------

    initial begin
        for (i=0; i<=OTP_dim-2; i=i+1) 
            mem[i] = data_NP;
        mem[OTP_dim-1] = 'bxxxxxxxx;
             `OTP_lockBit = 1;

    end



    //---------------------------
    // Program & Read OTP tasks
    //---------------------------


    // set start address
    // (for program and read operations)
    
    task setAddr;
    input [addrDim-1:0] A;
    begin
        overflow = 0;
        addr = A[OTP_addrDim-1:0];
        if (addr > (OTP_dim-1)) 
        begin
            addr = OTP_dim-1;
            $display(  "  [%0t ns] **WARNING** Address out of OTP memory area. Column %0d will be considered!", $time, addr);
        end    
    end
    endtask


    task resetBuffer;
    for (i=0; i<=OTP_dim-1; i=i+1)
        buffer[i] = data_NP;
    endtask


    task writeDataToBuffer;
    input [dataDim-1:0] data;
    begin
        
        if (!overflow)
            buffer[addr] = data;
        
        if (addr < OTP_dim-1)
            addr = addr + 1;
        else if (overflow==0) 
            overflow = 1;
        else if (overflow==1)
            $display("  [%0t ns] **WARNING** OTP limit reached: data latched will be discarded!", $time);

    end
    endtask



    task writeBufferToMemory;
    begin

        for (i=0; i<=OTP_dim-2; i=i+1)
            mem[i] = mem[i] & buffer[i];
          mem[OTP_dim-1][0] = mem[OTP_dim-1][0] & buffer[OTP_dim-1][0]; 
    end
    endtask  



    task readData;
    output [dataDim-1:0] data;
    begin

        data = mem[addr];
        if (addr < OTP_dim-1)
            addr = addr + 1;

    end
    endtask








endmodule   













/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CHECK                                --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps
`ifdef HOLD_pin
  module TimingCheck (S, C, D, Q, W, H);
`else
  module TimingCheck (S, C, D, Q, W, R);
`endif

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif





//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]


    input S, C, D, Q;
    `ifdef HOLD_pin
      input H; 
    `endif
     input W;
    
    `ifdef RESET_pin
      input R; 
    `endif
    `define W_feature
    

    realtime delta; //used for interval measuring
    
   

    //--------------------------
    //  Task for timing check
    //--------------------------

    task check;
        
        input [8*8:1] name;  //constraint check
        input realtime interval;
        input realtime constr;
        
        begin
        
            if (interval<constr)
                $display("[%0f ns] --TIMING ERROR-- %0s constraint violation. Measured time: %0f ns - Constraint: %0f ns",
                          $realtime, name, interval, constr);
            
        
        end
    
    endtask



    //----------------------------
    // Istants to be measured
    //----------------------------

    parameter initialTime = -1000;

    realtime C_high=initialTime, C_low=initialTime;
    realtime S_low=initialTime, S_high=initialTime;
    realtime D_valid=initialTime;
     
    `ifdef HOLD_pin
        realtime H_low=initialTime, H_high=initialTime; 
    `endif

    `ifdef RESET_pin
        realtime R_low=initialTime, R_high=initialTime; 
    `endif

    `ifdef W_feature
        realtime W_low=initialTime, W_high=initialTime; 
    `endif


    //------------------------
    //  C signal checks
    //------------------------


    always 
    @C if(C===0) //posedge(C)
    @C if(C===1)
    begin
        
        delta = $realtime - C_low; 
          check("tCL", delta, tCL);

        delta = $realtime - S_low; 
            check("tSLCH", delta, tSLCH);

        delta = $realtime - D_valid; 
        if (N25Qxxx.latchingMode!="N") check("tDVCH", delta, tDVCH); // do not check during data output

        delta = $realtime - S_high; 
            check("tSHCH", delta, tSHCH);

        // clock frequency checks
        delta = $realtime - C_high;
    
        if (read.enable && delta<TR)
        $display("[%0f ns] --TIMING ERROR-- Violation of Max clock frequency (%0d MHz) during normal READ operation. T_ck_measured=%0f ns, T_clock_min=%0f ns.",
                      $realtime, fR, delta, TR);
        else if ( (read.enable_fast || read.enable_ID || read.enable_dual || read.enable_quad || read.enable_OTP || 
                   stat.enable_SR_read || lock.enable_lockReg_read )   
                          && 
                        delta<TC  )
        $display("[%0t ns] --TIMING ERROR-- Violation of Max clock frequency during fast READ operation(%0d MHz). T_ck_measured=%0f ns, T_clock_min=%0f ns.",
                      $realtime, fC, delta, TC);

        
        `ifdef HOLD_pin
        
            delta = $realtime - H_low; 
            check("tHLCH", delta, tHLCH);

            delta = $realtime - H_high; 
            check("tHHCH", delta, tHHCH);
        
        `endif
        
        C_high = $realtime;
        
    end



    always 
    @C if(C===1) //negedge(C)
    @C if(C===0)
    begin
        
       delta = $realtime - C_high; 
            check("tCH", delta, tCH);
        
        C_low = $realtime;
        
    end




    //------------------------
    //  S signal checks
    //------------------------


    always 
    @S if(S===1) //negedge(S)
    @S if(S===0)
    begin
        
        delta = $realtime - C_high; 
            check("tCHSL", delta, tCHSL);

        delta = $realtime - S_high; 
        check("tSHSL", delta, tSHSL);

        `ifdef W_feature
          delta = $realtime - W_high; 
          check("tWHSL", delta, tWHSL);
        `endif


        `ifdef RESET_pin
            //check during decoding
            if (N25Qxxx.resetDuringDecoding) begin 
                delta = $realtime - R_high; 
                check("tRHSL", delta, tRHSL_1);
                N25Qxxx.resetDuringDecoding = 0;
            end 
            //check during program-erase operation
            else if (N25Qxxx.resetDuringBusy && (prog.operation=="Page Program" || prog.operation=="Page Write" ||  
                      prog.operation=="Sector Erase" || prog.operation=="Bulk Erase"  || prog.operation=="Die Erase"  ||  prog.operation=="Page Erase") )   
            begin 
                delta = $realtime - R_high; 
                check("tRHSL", delta, tRHSL_2);
                N25Qxxx.resetDuringBusy = 0;
            end
            //check during subsector erase
            else if ( N25Qxxx.resetDuringBusy && prog.operation=="Subsector Erase" ) begin 
                delta = $realtime - R_high; 
                check("tRHSL", delta, tRHSL_3);
                N25Qxxx.resetDuringBusy = 0;
            end
            //check during WRSR
            else if ( N25Qxxx.resetDuringBusy && prog.operation=="Write SR" ) begin 
                delta = $realtime - R_high; 
                check("tRHSL", delta, tRHSL_4);
                N25Qxxx.resetDuringBusy = 0;
            end    
             //check during WNVCR   
            else if ( N25Qxxx.resetDuringBusy && prog.operation=="Write NV Configuration Reg" ) begin 
                delta = $time - R_high; 
                check("tRHSL", delta, tRHSL_5);
                N25Qxxx.resetDuringBusy = 0;
            end
            else begin//verificare 
                delta = $time - R_high; 
                check("tRHSL", delta, tRHSL_6);
                N25Qxxx.resetDuringBusy = 0;

            end
        `endif


        S_low = $realtime;


    end




    always 
    @S if(S===0) //posedge(S)
    @S if(S===1)
    begin
        
        delta = $realtime - C_high; 
            check("tCHSH", delta, tCHSH);
        
        S_high = $realtime;
        
    end



    //----------------------------
    //  D signal (data in) checks
    //----------------------------

    always @D 
    begin

        delta = $realtime - C_high;
        // if (N25Qxxx.latchingMode!="N") check("tCHDX", delta, tCHDX); // do not check during data output
        if (N25Qxxx.latchingMode!="N") begin
          // $display("tCHDX check: delta=%h, tCHDX=%h", delta, tCHDX , $time);
          check("tCHDX", delta, tCHDX); // do not check during data output
        end

        if (isValid(D) && N25Qxxx.latchingMode!="N") D_valid = $realtime;


    end



    //------------------------
    //  Hold signal checks
    //------------------------


    `ifdef HOLD_pin    
    

        always 
        @H if(H===1) //negedge(H)
        @H if(H===0)
        begin
            if(N25Qxxx.intHOLD == 0) begin 
              delta = $realtime - C_high; 
              check("tCHHL", delta, tCHHL);

              H_low = $realtime;
            end
            
        end



        always 
        @H if(H===0) //posedge(H)
        @H if(H===1)
        begin
            if(N25Qxxx.intHOLD == 0) begin 
            
              delta = $realtime - C_high; 
              check("tCHHH", delta, tCHHH);
              
              H_high = $realtime;
            end
            
        end


    `endif




    //------------------------
    //  W signal checks
    //------------------------


    `ifdef W_feature

        always 
        @W if(W===1) //negedge(W)
        @W if(W===0)
        begin
            
            delta = $realtime - S_high; 
            check("tSHWL", delta, tSHWL);

            W_low = $realtime;
            
        end

        always 
        @W if(W===0) //posedge(W)
        @W if(W===1)
            W_high = $realtime;
            
    `endif




    //------------------------
    //  RESET signal checks
    //------------------------


    `ifdef RESET_pin

        always 
        @R if(R===1) //negedge(R)
        @R if(R===0)
            R_low = $realtime;
            
        always 
        @R if(R===0) //posedge(R)
        @R if(R===1)
        begin
            
            delta = $realtime - S_high; 
            check("tSHRH", delta, tSHRH);
            
            delta = $realtime - R_low; 
            check("tRLRH", delta, tRLRH);
            
            R_high = $realtime;
            
        end

    `endif




    //----------------
    // Others tasks
    //----------------

    function isValid;
    input ibit;
      if (ibit!==0 && ibit!==1) isValid=0;
      else isValid=1;
    endfunction




    

endmodule   












/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           EXTENDED ADDRESS REGISTER MODULE            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`timescale 1ns / 1ps

module ExtendedAddressRegister;

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                          ADDED DTR        /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              
  


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           PARAMETERS OF DEVICES                       --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


//-----------------------------
//  Customization Parameters
//-----------------------------

`define timingChecks


//-- Available devices 

 
 // `define N25Q032A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E
//  `define N25Q256A13E // N25Q032A13E , N25Q032A11E ,N25Q256A33E, N25Q256A31E, N25Q256A13E


//----------------------------
// Model configuration
//----------------------------


parameter dataDim = 8;
parameter dummyDim = 15;


`ifdef N25Q256A33E

    parameter [12*8:1] devName = "N25Q256A33E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define VCC_3V 

`elsif N25Q256A13E

    parameter [12*8:1] devName = "N25Q256A13E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define VCC_3V 
    `define RESET_software

`elsif N25Q256A31E
    
    parameter [12*8:1] devName = "N25Q256A31E";

    parameter addrDim = 25; 
    parameter sectorAddrDim = 9;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h19; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define RESET_pin
    `define SubSect
    `define XIP_Numonyx
    `define byte_4
    `define RESET_software
    `define PowDown
    `define VCC_1e8V 

`elsif N25Q032A13E

    parameter [12*8:1] devName = "N25Q032A13E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define VCC_3V

`elsif N25Q032A11E

    parameter [12*8:1] devName = "N25Q032A11E";

    parameter addrDim = 22; 
    parameter sectorAddrDim = 6;
    parameter [dataDim-1:0] MemoryType_ID = 'hBA; 
    parameter [dataDim-1:0] MemoryCapacity_ID = 'h17; 
    parameter [dataDim-1:0] UID = 'h10; 
    parameter [dataDim-1:0] EDID_0 = 'h12; 
    parameter [dataDim-1:0] EDID_1 = 'h00; 
    parameter [dataDim-1:0] CFD_0 = 'h0; 
    parameter [dataDim-1:0] CFD_1 = 'h0; 
    parameter [dataDim-1:0] CFD_2 = 'h0; 
    parameter [dataDim-1:0] CFD_3 = 'h0; 
    parameter [dataDim-1:0] CFD_4 = 'h0; 
    parameter [dataDim-1:0] CFD_5 = 'h0; 
    parameter [dataDim-1:0] CFD_6 = 'h0; 
    parameter [dataDim-1:0] CFD_7 = 'h0; 
    parameter [dataDim-1:0] CFD_8 = 'h0; 
    parameter [dataDim-1:0] CFD_9 = 'h0;
    parameter [dataDim-1:0] CFD_10 = 'h0; 
    parameter [dataDim-1:0] CFD_11 = 'h0; 
    parameter [dataDim-1:0] CFD_12 = 'h0; 
    parameter [dataDim-1:0] CFD_13 = 'h0; 
   
    `define HOLD_pin
    `define SubSect
    `define XIP_Numonyx
    `define PowDown
    `define VCC_1e8V



`endif



//----------------------------
// Include TimingData file 
//----------------------------

//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                        ADDED DTR          /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.2 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           TIMING CONSTANTS                            --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/




    //--------------------------------------
    // Max clock frequency (minimum period)
    //--------------------------------------
    
    parameter fC = 108; //max frequency in Mhz
    parameter time TC = 9; //9ns=111.1Mhz
    parameter fC_dtr = 66;      // max frequency in Mhz in Double Transfer Rate
    parameter TC_dtr = 15;      // 15ns = 66.7Mhz

    
    parameter fR = 54; //max frequency in Mhz during standard Read operation
    parameter time TR = 18; //18ns=55.55Mhz
    parameter fR_dtr = 27;      // max frequency in Mhz during standard Read operation in Double Transfer Rate
    parameter TR_dtr = 37;      // 37ns = 27.03Mhz

    //NB: in special read operations 
    // (fast read, dual output fast read, read SR, 
    // read lock register, read ID, read OTP)
    // max clock frequency is fC 
    
    //---------------------------
    // Input signals constraints
    //---------------------------

    // Clock signal constraints
    parameter time tCH = 0.002; //4;
    parameter time tCL = 0.002; //4;
    parameter time tSLCH = 5; //4;
    parameter time tDVCH = 2;
   parameter time tSHCH = 5; //4;
    parameter time tHLCH = 5; //4;
    parameter time tHHCH = 5; //4;

    parameter tCH_dtr = 6.75;
    parameter tCL_dtr = 6.75;

    // Chip select constraints
     parameter time tCHSL = 5; //4;
    parameter time tCHSH = 5; //4;
      parameter time tSHSL = 100; //20; 
    parameter time tVPPHSL = 200; //not implemented
    parameter time tWHSL = 20;  
    parameter tSLCH_dtr = 6.75;
    parameter tSHCH_dtr = 6.75;
    parameter tCHSL_dtr = 6.75;
    parameter tCHSH_dtr = 6.75;
    parameter tCLSH = 3.375; // DTR only

    
    // Data in constraints
     parameter time tCHDX = 5; //3;


    // W signal constraints
    parameter time tSHWL = 100;  


    // HOLD signal constraints
    parameter time tCHHH = 5;
    parameter time tCHHL = 5;


    // RESET signal constraints
    parameter time tRLRH = 50; // da sistemare
    parameter time tSHRH = 2; 
    parameter time tRHSL_1 = 40; //during decoding
    parameter time tRHSL_2 = 30000; //during program-erase operation (except subsector erase and WRSR)
    parameter time tRHSL_3 = 500e6;  //during subsector erase operation=tSSE
    parameter time tRHSL_4 = 15e6; //during WRSR operation=tW
    parameter time tRHSL_5 = 15e6; //during WRNVCR operation=tWNVCR

    parameter time tRHSL_6 = 40; //when S is high in XIP mode and in standby mode

    //-----------------------
    // Output signal timings
    //-----------------------

    parameter time tSHQZ = 8;
     parameter time tCLQV = 8; //7; // 8 under 30 pF - 6 under 10 pF
    parameter time tCLQX = 0; //1; // min value
    parameter time tHHQX = 8;  
    parameter time tHLQZ = 8;

    parameter tCHQV = 6; // 6 under 30 pF - 5 under 10 pF - DTR only
    parameter tCHQX = 1; // min value- DTR only


    //--------------------
    // Operation delays
    //--------------------
   
   `ifdef PowDown
    parameter time tDP  = 3e0;
    parameter time tRDP = 30e0; 
    `endif

     parameter time tW   = 30e3; //15e9;
    parameter time tPP  = 10e3; //5e6;
    parameter time tSSE = 40e3; //500e6;
    parameter time tSE  = 200e3; //3e9;
    parameter time tBE  = 500e3; //770e9;

    parameter time tDE  = 80e6; // Needs to change 
    //aggiunta
    parameter time tWNVCR   = 15; //15e9;

    parameter time tWVCR  = 40;
    parameter time tWRVECR = 40;
    parameter time tCFSR = 40;
    
    `ifdef byte_4
    parameter time tWREAR = 40; // probable value
    parameter time tEN4AD = 40; // probable value
    parameter time tEX4AD = 40; // probable value
    `endif
    
    parameter tP_latency = 7e0;
    parameter tSE_latency = 15e0;
    parameter tSSE_latency = 15e0;

    parameter write_PMR_delay = 1e5;

    parameter progSusp_latencyTime = 25e3;
    parameter eraseSusp_latencyTime = 25e3;

    // Startup delays
//!    parameter time tPUW = 10e6;
  parameter time tVTR = 0; //100e3;
    parameter time tVTW = 0; //600e3;

//---------------------------------
// Alias of timing constants above
//---------------------------------

parameter time program_delay = tPP;
parameter time program_latency = tP_latency;
parameter time write_SR_delay = tW;
parameter time clear_FSR_delay = tCFSR;
parameter time write_NVCR_delay = tWNVCR;
parameter time write_VCR_delay = tWVCR;
parameter time write_VECR_delay = tWRVECR;

`ifdef byte_4
parameter time write_EAR_delay = tWREAR;
parameter time enable4_address_delay = tEN4AD;
parameter time exit4_address_delay = tEX4AD;
`endif

parameter time erase_delay = tSE;
parameter time erase_latency = tSE_latency;

parameter time erase_bulk_delay = tBE;
parameter time erase_die_delay = tDE;
parameter time full_access_power_up_delay = tVTW;
parameter time read_access_power_up_delay = tVTR;

`ifdef SubSect 
  parameter time erase_ss_delay = tSSE;
  parameter time erase_ss_latency = tSSE_latency;
`endif

`ifdef PowDown 

  parameter time deep_power_down_delay = tDP; 
  parameter time release_power_down_delay = tRDP;
`endif






//----------------------------------------
// Parameters constants for all devices
//----------------------------------------

`define VoltageRange 31:0




//---------------------------
// stimuli clock period
//---------------------------
// for a correct behavior of the stimuli, clock period should
// be multiple of 4

`ifdef N25Q256A33E
  parameter time T = 40;
`elsif N25Q256A31E
  parameter time T = 40;
`elsif N25Q256A13E
  parameter time T = 40;
`elsif N25Q256A11E
  parameter time T = 40;
`elsif N25Q032A13E
  parameter time T = 40;
`elsif N25Q032A11E
  parameter time T = 40;
`else
  parameter time T = 40;
`endif




//-----------------------------------
// Devices Parameters 
//-----------------------------------


// data & address dimensions

parameter cmdDim = 8;
parameter addrDimLatch =24; //da verificare se va bene

`ifdef byte_4
parameter addrDimLatch4 = 32; //da verificare
`endif

// memory organization

parameter memDim = 2 ** addrDim; 

parameter colAddrDim = 8;
parameter colAddr_sup = colAddrDim-1;
parameter pageDim = 2 ** colAddrDim;

`ifdef Stack1024Mb
  parameter nSector = 4 * (2 ** sectorAddrDim);
`elsif Stack512Mb
  parameter nSector = 2 * (2 ** sectorAddrDim);
`else
  parameter nSector = 2 ** sectorAddrDim;
`endif
parameter sectorAddr_inf = addrDim-sectorAddrDim; 
parameter EARvalidDim = 2; // number of valid EAR bits


parameter sectorAddr_sup = addrDim-1;
parameter sectorSize = 2 ** (addrDim-sectorAddrDim);

`ifdef SubSect

 parameter subsecAddrDim = 4+sectorAddrDim;
 parameter subsecAddr_inf = 12;
 parameter subsecAddr_sup = addrDim-1;
 parameter subsecSize = 2 ** (addrDim-subsecAddrDim);
 
`endif

parameter pageAddrDim = addrDim-colAddrDim;
parameter pageAddr_inf = colAddr_sup+1;
parameter pageAddr_sup = addrDim-1;




// OTP section

 parameter OTP_dim = 65;
 parameter OTP_addrDim = 7;

// FDP section

parameter FDP_dim = 16384; //2048 byte
parameter FDP_addrDim = 11; // 2048 address

//  signature 

parameter [dataDim-1:0] Manufacturer_ID = 'h20;



// others constants

parameter [dataDim-1:0] data_NP = 'hFF;


`ifdef VCC_3V
parameter [`VoltageRange] Vcc_wi = 'd2500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd2700;
parameter [`VoltageRange] Vcc_max = 'd3600;

`else

parameter [`VoltageRange] Vcc_wi = 'd1500; //write inhibit 
parameter [`VoltageRange] Vcc_min = 'd1700;
parameter [`VoltageRange] Vcc_max = 'd2000;
`endif
//-------------------------
// Alias used in the code
//-------------------------


// status register code

`define WIP N25Qxxx.stat.SR[0]

`define WEL N25Qxxx.stat.SR[1]

`define BP0 N25Qxxx.stat.SR[2]

`define BP1 N25Qxxx.stat.SR[3]

`define BP2 N25Qxxx.stat.SR[4]

`define TB N25Qxxx.stat.SR[5]

`define BP3 N25Qxxx.stat.SR[6]

`define SRWD N25Qxxx.stat.SR[7]


    parameter [7:0] ExtendAddrReg_default = 'b00000000;


    // status register
    reg [7:0] EAR;
    




    //--------------
    // Init
    //--------------


    initial begin
        
       EAR[7:0] = ExtendAddrReg_default;
    end



    //-----------------------------------
    // write extended address register
    //-----------------------------------

    // see "Program" module


//aggiunta
//-----------------------------------
//    EAR[0]
//-----------------------------------





    //--------------------------------
    // read extended address register
    //--------------------------------
    // NB : "Read EAR" operation is also modelled in N25Qxxx.module

    reg enable_EAR_read;
    
    always @(N25Qxxx.seqRecognized) if (N25Qxxx.cmdRecName=="Read EAR") fork 
        
        enable_EAR_read=1;

        @(posedge(N25Qxxx.S) or N25Qxxx.resetEvent or N25Qxxx.voltageFault)
            enable_EAR_read=0;
        
    join    

    


    



endmodule  // ExtendedAddressRegister 


//***********************************************************************
//***********************************************************************
// Stacked N25Q's
//***********************************************************************
//***********************************************************************

`ifdef Stack512Mb
  `ifdef HOLD_pin
    module N25QxxxTop (S, C, HOLD_DQ3, DQ0, DQ1, Vcc, Vpp_W_DQ2);
  `else 
    module N25QxxxTop (S, C, RESET_DQ3, DQ0, DQ1, Vcc, Vpp_W_DQ2);
  `endif

  //          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________ 
//      _/_/_/_/_/       _/_/_/             /                                           / 
//      _/_/_/_/_/       _/_/_/            /                               N25Q256A13E / 
//      _/_/_/_/_/       _/_/_/           /                           ADDED DTR       /  
//      _/_/_/_/_/_/     _/_/_/          /                                   256Mbit / 
//      _/_/_/_/_/_/     _/_/_/         /                              SERIAL FLASH / 
//      _/_/_/ _/_/_/    _/_/_/        /                                           / 
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model / 
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.1 / 
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2010 Numonyx B.V. / 
//      _/_/_/      _/_/_/_/_/    /___________________________________________/ 
//      _/_/_/       _/_/_/_/      
//      _/_/          _/_/_/  
// 
//     
//             NUMONYX              





/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-----------------------------------------------------------
-----------------------------------------------------------
--                                                       --
--           STACK DECODERS INSTANTIATIONS               --
--                                                       --
-----------------------------------------------------------
-----------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
`ifdef Stack1024Mb
  `define Stack512Mb
  `ifdef HOLD_pin
    N25Qxxx #(.rdeasystacken(2)) N25Q_die2 (S,C,HOLD_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
    N25Qxxx #(.rdeasystacken(3)) N25Q_die3 (S,C,HOLD_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
  `else 
    N25Qxxx #(.rdeasystacken(2)) N25Q_die2 (S,C,RESET_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
    N25Qxxx #(.rdeasystacken(3)) N25Q_die3 (S,C,RESET_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
  `endif
`endif

`ifdef Stack512Mb
  `ifdef HOLD_pin
    N25Qxxx #(.rdeasystacken(0)) N25Q_die0 (S,C,HOLD_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
    N25Qxxx #(.rdeasystacken(1)) N25Q_die1 (S,C,HOLD_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
  `else
    N25Qxxx #(.rdeasystacken(0)) N25Q_die0 (S,C,RESET_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
    N25Qxxx #(.rdeasystacken(1)) N25Q_die1 (S,C,RESET_DQ3,DQ0,DQ1,Vcc,Vpp_W_DQ2);
  `endif
`endif

  
  // parameter [15:0] NVConfigReg_default = 'b1111111111111110;

  input S;
  input C;
  input [`VoltageRange] Vcc;
  
  inout DQ0; 
  inout DQ1;
  
  `ifdef HOLD_pin
    inout HOLD_DQ3; //input HOLD, inout DQ3
  `endif
  
  `ifdef RESET_pin
    inout RESET_DQ3; //input RESET, inout DQ3
  `endif
  
  inout Vpp_W_DQ2; //input Vpp_W, inout DQ2 (VPPH not implemented)

  
  
    reg [1:0] current_die_sel = 0;
    reg all_die_cmd = 'h0;
    reg read_fsr_done = 'h0;
    wire any_die_busy ;
    reg [3:0] current_die ;
    wire [3:0] current_die_busy ;
    wire [3:0] current_die_active ;

    `ifdef Stack1024Mb
      assign any_die_busy = N25Q_die0.busy || N25Q_die1.busy || N25Q_die2.busy || N25Q_die3.busy ;
      assign current_die_busy = {N25Q_die3.busy , N25Q_die2.busy , N25Q_die1.busy , N25Q_die0.busy} ;
      assign current_die_active = {N25Q_die3.die_active , N25Q_die2.die_active , N25Q_die1.die_active , N25Q_die0.die_active} ;
      reg [1:0] stack_counter = 0;
    `else
      assign any_die_busy = N25Q_die0.busy || N25Q_die1.busy  ;
      assign current_die_busy ={ N25Q_die1.busy , N25Q_die0.busy} ;
      assign current_die_active = {N25Q_die1.die_active , N25Q_die0.die_active} ;
      reg   stack_counter = 0;
    `endif

    // All die commands
    always @(N25Q_die0.cmdLatched) begin
      if((any_die_busy == 0 ) && (read_fsr_done == 0)) begin
        if(N25Q_die0.cmd == 'hB1 ||  N25Q_die0.cmd =='h01 || N25Q_die0.cmd =='h68 ) begin
          all_die_cmd = 1;
          stack_counter = 0;
          read_fsr_done = 1;
        end
        // Lower die commands
        else if(N25Q_die0.cmd == 'h9E ||  N25Q_die0.cmd =='h9F ||
          N25Q_die0.cmd == 'h42 || N25Q_die0.cmd == 'h4B ||  N25Q_die0.cmd
          =='h5A ) begin
          all_die_cmd = 0;
          N25Q_die0.die_active = 1; 
          N25Q_die1.die_active = 0;
          `ifdef Stack1024Mb
            N25Q_die2.die_active = 0;N25Q_die3.die_active = 0;
          `endif
        end
        else begin
          all_die_cmd = 0;
        end
      end
      else if(any_die_busy == 1) begin 
        if(N25Q_die0.cmd != 'h70 && N25Q_die0.cmd != 'h75) begin
          $display("[%0t ns] ==ERROR== Only FSR and PES commands are allowed.", $time);
        end
      end
      else begin
        $display("[%0t ns] ==ERROR== Needs to issue FSR commands for synchronization.", $time);
      end
    end

    // Stack counter increments
    always @(N25Q_die0.cmdLatched) begin
      if((all_die_cmd == 1) && (N25Q_die0.cmd == 'h70) && (read_fsr_done == 0) ) begin
        stack_counter = stack_counter + 1;
      end
    end

    // Here the all die commands are checked and round robin FSR is
    // implemented
    always @(N25Q_die0.sendToBus_stack) begin
      if((all_die_cmd == 1) && (N25Q_die0.cmd == 'h70)) begin
        read_fsr_done = 0;
        `ifdef Stack1024Mb
          case (stack_counter) 
            0 : begin N25Q_die0.die_active = 1; N25Q_die1.die_active = 0;N25Q_die2.die_active = 0;N25Q_die3.die_active = 0; end
            1 : begin N25Q_die0.die_active = 0; N25Q_die1.die_active = 1;N25Q_die2.die_active = 0;N25Q_die3.die_active = 0; end
            2 : begin N25Q_die0.die_active = 0; N25Q_die1.die_active = 0;N25Q_die2.die_active = 1;N25Q_die3.die_active = 0; end
            3 : begin N25Q_die0.die_active = 0; N25Q_die1.die_active = 0;N25Q_die2.die_active = 0;N25Q_die3.die_active = 1; end
            default : $display("[%0t ns] ERROR in stack counter value ", $time);
          endcase
        `else
          case (stack_counter) 
            0 : begin N25Q_die0.die_active = 1; N25Q_die1.die_active = 0; end
            1 : begin N25Q_die0.die_active = 0; N25Q_die1.die_active = 1; end
            default : $display("[%0t ns] ERROR in stack counter value ", $time);
          endcase
        `endif
        // stack_counter = stack_counter + 1;
      end
      // Sync the die status
      else if((all_die_cmd == 0) && (N25Q_die0.cmd == 'h70)) begin // busy needs to be included??
        if(current_die_busy != 0) begin
          current_die = current_die_busy;
        end
        else begin
          current_die = current_die_active;
        end
        $display("SYNCING the status : current_die=%h, current_die_active=%h, current_die_busy=%h ", current_die,current_die_active,current_die_busy, $time);
        case (current_die)
          1 : begin
                N25Q_die1.stat.SR[1] = (N25Q_die0.flag.FSR[1] == 0) ?  N25Q_die0.stat.SR[1] : N25Q_die1.stat.SR[1] ;
                N25Q_die1.flag.FSR = N25Q_die0.flag.FSR;
                `ifdef Stack1024Mb
                  N25Q_die2.flag.FSR = N25Q_die0.flag.FSR;
                  N25Q_die3.flag.FSR = N25Q_die0.flag.FSR;
                  N25Q_die2.stat.SR[1] = (N25Q_die0.flag.FSR[1] == 0) ?  N25Q_die0.stat.SR[1] : N25Q_die2.stat.SR[1] ;
                  N25Q_die3.stat.SR[1] = (N25Q_die0.flag.FSR[1] == 0) ?  N25Q_die0.stat.SR[1] : N25Q_die3.stat.SR[1] ;
                `endif
              end
          2 : begin
                N25Q_die0.stat.SR[1] = (N25Q_die1.flag.FSR[1] == 1) ?  N25Q_die1.stat.SR[1] : N25Q_die0.stat.SR[1] ;
                N25Q_die0.flag.FSR = N25Q_die1.flag.FSR;
                `ifdef Stack1024Mb
                  N25Q_die2.flag.FSR = N25Q_die1.flag.FSR;
                  N25Q_die3.flag.FSR = N25Q_die1.flag.FSR;
                  N25Q_die2.stat.SR[1] = (N25Q_die1.flag.FSR[1] == 0) ?  N25Q_die1.stat.SR[1] : N25Q_die2.stat.SR[1] ;
                  N25Q_die3.stat.SR[1] = (N25Q_die1.flag.FSR[1] == 0) ?  N25Q_die1.stat.SR[1] : N25Q_die3.stat.SR[1] ;
                `endif
              end
          `ifdef Stack1024Mb
          4 : begin
                N25Q_die0.flag.FSR = N25Q_die2.flag.FSR;
                N25Q_die1.flag.FSR = N25Q_die2.flag.FSR;
                N25Q_die3.flag.FSR = N25Q_die2.flag.FSR;
                N25Q_die0.stat.SR[1] = (N25Q_die2.flag.FSR[1] == 0) ?  N25Q_die2.stat.SR[1] : N25Q_die0.stat.SR[1] ;
                N25Q_die1.stat.SR[1] = (N25Q_die2.flag.FSR[1] == 0) ?  N25Q_die2.stat.SR[1] : N25Q_die1.stat.SR[1] ;
                N25Q_die3.stat.SR[1] = (N25Q_die2.flag.FSR[1] == 0) ?  N25Q_die2.stat.SR[1] : N25Q_die3.stat.SR[1] ;
              end
          8 : begin
                N25Q_die0.flag.FSR = N25Q_die3.flag.FSR;
                N25Q_die1.flag.FSR = N25Q_die3.flag.FSR;
                N25Q_die2.flag.FSR = N25Q_die3.flag.FSR;
                N25Q_die0.stat.SR[1] = (N25Q_die3.flag.FSR[1] == 0) ?  N25Q_die3.stat.SR[1] : N25Q_die0.stat.SR[1] ;
                N25Q_die1.stat.SR[1] = (N25Q_die3.flag.FSR[1] == 0) ?  N25Q_die3.stat.SR[1] : N25Q_die1.stat.SR[1] ;
                N25Q_die2.stat.SR[1] = (N25Q_die3.flag.FSR[1] == 0) ?  N25Q_die3.stat.SR[1] : N25Q_die2.stat.SR[1] ;
              end
          `endif
          default : $display("[%0t ns] ERROR in current_die_busy decode", $time);
        endcase
      end
      else begin

      end
    end

    //------------------------------
    // Calculating device select during stacked die
    // die active indicates the die selected
    //------------------------------
    
    always@(N25Q_die0.addrLatched) begin
      if((N25Q_die0.prog.enable_4Byte_address == 1) || (N25Q_die0.NonVolatileReg.NVCR[0] == 0)) begin
        stackDieDecode(N25Q_die0.addrLatch[N25Q_die0.addrDim +1: N25Q_die0.addrDim]);
      end
      else begin
        stackDieDecode(N25Q_die0.ExtAddReg.EAR[1:0]);
      end
    end
    
    task stackDieDecode;
      input [1:0] dieaddr ;
        `ifdef Stack1024Mb
        case (dieaddr)
        `else
        case (dieaddr[0])
        `endif
          0 : begin
                N25Q_die0.die_active = 1;
                N25Q_die1.die_active = 0;
                `ifdef Stack1024Mb
                  N25Q_die2.die_active = 0;
                  N25Q_die3.die_active = 0;
                `endif
              end
          1 : begin
                N25Q_die0.die_active = 0;
                N25Q_die1.die_active = 1;
                `ifdef Stack1024Mb
                  N25Q_die2.die_active = 0;
                  N25Q_die3.die_active = 0;
                `endif
              end
          `ifdef Stack1024Mb
          3 : begin
                N25Q_die0.die_active = 0;
                N25Q_die1.die_active = 0;
                N25Q_die2.die_active = 1;
                N25Q_die3.die_active = 0;
              end
          4 : begin
                N25Q_die0.die_active = 0;
                N25Q_die1.die_active = 0;
                N25Q_die2.die_active = 0;
                N25Q_die3.die_active = 1;
              end
          `endif
      endcase
    endtask
    

  endmodule // N25QxxxTop
`endif