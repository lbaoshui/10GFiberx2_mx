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
module  fifo320_fifo_181_hlc74wy  (
    aclr,
    clock,
    data,
    rdreq,
    wrreq,
    empty,
    full,
    q);

    input    aclr;
    input    clock;
    input  [319:0]  data;
    input    rdreq;
    input    wrreq;
    output   empty;
    output   full;
    output [319:0]  q;

    wire  sub_wire0;
    wire  sub_wire1;
    wire [319:0] sub_wire2;
    wire  empty = sub_wire0;
    wire  full = sub_wire1;
    wire [319:0] q = sub_wire2[319:0];

    scfifo  scfifo_component (
                .aclr (aclr),
                .clock (clock),
                .data (data),
                .rdreq (rdreq),
                .wrreq (wrreq),
                .empty (sub_wire0),
                .full (sub_wire1),
                .q (sub_wire2),
                .almost_empty (),
                .almost_full (),
                .eccstatus (),
                .sclr (),
                .usedw ());
    defparam
        scfifo_component.add_ram_output_register  = "ON",
        scfifo_component.enable_ecc  = "FALSE",
        scfifo_component.intended_device_family  = "Arria 10",
        scfifo_component.lpm_numwords  = 128,
        scfifo_component.lpm_showahead  = "ON",
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_width  = 320,
        scfifo_component.lpm_widthu  = 7,
        scfifo_component.overflow_checking  = "ON",
        scfifo_component.underflow_checking  = "ON",
        scfifo_component.use_eab  = "ON";


endmodule


