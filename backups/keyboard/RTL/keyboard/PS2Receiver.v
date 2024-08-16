`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Thomas Kappenman
// 
// Create Date: 03/03/2015 09:33:36 PM
// Design Name: 
// Module Name: PS2Receiver
// Project Name: Nexys4DDR Keyboard Demo
// Target Devices: Nexys4DDR
// Tool Versions: 
// Description: PS2 Receiver module used to shift in keycodes from a keyboard plugged into the PS2 port
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PS2Receiver
#(parameter dw = 32,
  parameter aw = 32)
(

    input clk, // 50 mhz
    input kclk, // ps2 clk
    input kdata, // ps2 data
    output [31:0] keycodeout, // keycode
	
	//**********************wishbone interface************************
	input    wire         wb_clk_i,	// Clock
	input   wire          wb_rst_i,	// Reset
	input   wire          wb_cyc_i,	// cycle valid input
	input  wire [aw-1:0]	wb_adr_i,	// address bus inputs
	input  wire [dw-1:0]	wb_dat_i,	// input data bus
	input	wire  [3:0]     wb_sel_i,	// byte select inputs
	input   wire          wb_we_i,	// indicates write transfer
	input   wire          wb_stb_i,	// strobe input
	output  reg  [dw-1:0]  wb_dat_o,	// output data bus
	output  reg          wb_ack_o,	// normal termination
	output   wire         wb_err_o	// termination w/ error
);
    
	// code the was provided by digilent itself	
	wire kclkf, kdataf;
	reg [7:0]datacur;
	reg [7:0]dataprev;
	reg [3:0]cnt;
	reg [31:0]keycode;
	reg flag;
	
	initial begin
		keycode[31:0] = 32'h0;
		cnt<=4'b0000;
		flag<=1'b0;
	end

	// DEBOUNCE THE BUTTONS ON THE KEYBOARD
	debouncer debounce(
		.clk(clk),
		.I0(kclk),
		.I1(kdata),
		.O0(kclkf),
		.O1(kdataf)
	);
		
	always@(negedge(kclkf))begin
		case(cnt)
		0:;//Start bit
		1:datacur[0]<=kdataf;
		2:datacur[1]<=kdataf;
		3:datacur[2]<=kdataf;
		4:datacur[3]<=kdataf;
		5:datacur[4]<=kdataf;
		6:datacur[5]<=kdataf;
		7:datacur[6]<=kdataf;
		8:datacur[7]<=kdataf;
		9:flag<=1'b1;
		10:flag<=1'b0;
		
		endcase
			if(cnt<=9) cnt<=cnt+1;
			else if(cnt==10) cnt<=0;
			
	end

	always @(posedge flag)begin
		if (dataprev!=datacur)begin
			keycode[31:24]<=keycode[23:16];
			keycode[23:16]<=keycode[15:8];
			keycode[15:8]<=dataprev;
			keycode[7:0]<=datacur;
			dataprev<=datacur;
			
		end
	end
		
		
	assign keycodeout = keycode;
	
	
	// **************************now my code starts *************************
   
    always @(posedge wb_clk_i) begin
		if (wb_rst_i) begin
			wb_ack_o <= 1'b0; // Reset acknowledgement signal
		end else if (wb_cyc_i & wb_stb_i & !wb_we_i) begin
			wb_ack_o <= 1'b1; // Assert acknowledgement on a valid read cycle
		end else begin
			wb_ack_o <= 1'b0; // Deassert ack in the next cycle
		end
	end

	// Read data from keycode register
	always @(posedge wb_clk_i) begin
		//if (wb_ack_o) begin
			case(wb_adr_i[5:2])
				4'b0000: wb_dat_o <= keycode; // Output keycode
				default: wb_dat_o <= 32'b0; // Default case
			endcase
		//end
	end
    
endmodule
