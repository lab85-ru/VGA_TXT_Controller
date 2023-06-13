//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.10
//Part Number: GW1NZ-LV1FN32C6/I5
//Device: GW1NZ-1
//Created Time: Fri May 26 19:05:23 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    rom your_instance_name(
        .dout(dout_o), //output [7:0] dout
        .clk(clk_i), //input clk
        .oce(oce_i), //input oce
        .ce(ce_i), //input ce
        .reset(reset_i), //input reset
        .ad(ad_i) //input [11:0] ad
    );

//--------Copy end-------------------
