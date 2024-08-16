`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Thomas Kappenman
// 
// Create Date: 03/03/2015 09:06:31 PM
// Design Name: 
// Module Name: top
// Project Name: Nexys4DDR Keyboard Demo
// Target Devices: Nexys4DDR
// Tool Versions: 
// Description: This project takes keyboard input from the PS2 port,
//  and outputs the keyboard scan code to the 7 segment display on the board.
//  The scan code is shifted left 2 characters each time a new code is
//  read.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`default_nettype wire
module keyboard_top
#(parameter dw = 32,
  parameter aw = 32)
(	
	//wishbone interface
	input             wb_clk_i,	// Clock
	input             wb_rst_i,	// Reset
	input             wb_cyc_i,	// cycle valid input
	input   [aw-1:0]	wb_adr_i,	// address bus inputs
	input   [dw-1:0]	wb_dat_i,	// input data bus
	input	  [3:0]     wb_sel_i,	// byte select inputs
	input             wb_we_i,	// indicates write transfer
	input             wb_stb_i,	// strobe input
	output     [dw-1:0]  wb_dat_o,	// output data bus
	output           wb_ack_o,	// normal termination
	output            wb_err_o,	// termination w/ error

	//keyboard interface
    input wire CLK100MHZ,
    input wire PS2_CLK,
    input wire PS2_DATA
);
   

	//generate 50 MHZ clock
	reg CLK50MHZ=0;    
	
	//generate key code
	wire [31:0] keycode;
	
	//reduce from 100 MHZ to 50 MHZ
	always @(posedge(CLK100MHZ))begin
		CLK50MHZ<=~CLK50MHZ;
	end

	PS2Receiver keyboard (
		.clk(CLK50MHZ),
		.kclk(PS2_CLK),
		.kdata(PS2_DATA),
		.keycodeout(keycode[31:0]),
	
		//wishbone interface
		.wb_clk_i     (wb_clk_i), 
        .wb_rst_i     (wb_rst_i), 
        .wb_cyc_i     (wb_cyc_i),      
        .wb_adr_i     (wb_adr_i), 
        .wb_dat_i     (wb_dat_i), 
        .wb_sel_i     (wb_sel_i),
        .wb_we_i      (wb_we_i), 
        .wb_stb_i     (wb_stb_i), 
        .wb_dat_o     (wb_dat_o),
        .wb_ack_o     (wb_ack_o), 
        .wb_err_o     (wb_err_o)
	);
	
	
  
endmodule
