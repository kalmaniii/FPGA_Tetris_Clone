/*
@file: game_ram.v
@author: Eddy
@date: 3/4/24
@version: 2

@brief:
RAM that holds the 160x144 pixel screen of the Tetris game
*/

`default_nettype wire
`include "game_defines.svh"

module game_ram(
    input wire vga_clk,
    input wire wb_clk_i,
    input wire wb_rst_i,
    input reg  [9:0]  cpu_row_position,
    input reg  [9:0]  cpu_col_position,
    input reg  [11:0] cpu_rgb_value,
    input reg  [11:0] vga_row_position,
    input reg  [11:0] vga_col_position,
    input reg vga_on_screen,
    input reg vga_on_game_screen,
    output reg [11:0] current_pixel_color
);

// Define memory depth and width
localparam MEM_DEPTH = `RAM_WIDTH * `RAM_HEIGHT; 
localparam MEM_WIDTH = 12; // rgb color value; r = [11:8], g = [7:4], b = [3:0]

// ram object
reg [MEM_WIDTH-1:0] ram [MEM_DEPTH-1:0];

// write to RAM
always @(posedge wb_clk_i) begin
    if (cpu_row_position < `RAM_HEIGHT && cpu_col_position < `RAM_WIDTH)
        ram[cpu_row_position*`RAM_WIDTH + cpu_col_position] <= cpu_rgb_value;
    else
        cpu_rgb_value <= cpu_rgb_value;
end

// read data from buffer for display
always @(posedge vga_clk) begin
    if (vga_on_screen && vga_on_game_screen)
        current_pixel_color <= ram[
            ((vga_row_position - `GAME_COORDINATE_ROW) / `NEW_PIXEL_SIZE)*`RAM_WIDTH + 
            ((vga_col_position - `GAME_COORDINATE_COL) / `NEW_PIXEL_SIZE)
        ];
    else
        current_pixel_color <= 12'h000;
end

endmodule
