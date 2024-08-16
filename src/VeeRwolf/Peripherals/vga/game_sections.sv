/*
@file: game_sections.v
@author: Eddy
@date: 3/4/24
@version: 2

@brief:
variables (on_game_scren, on_score_screen, etc) will return TRUE if within the section of the monitor screen
This is used to make the RTL update the "incoming block", "score", "level" etc screens independtly of the CPU

*/

`include "game_defines.svh"

module game_section(
    input wire vga_clk,
    input reg [11:0] vga_row, 
    input reg [11:0] vga_col,
    output reg on_game_screen, 
    output reg on_score_screen,
    output reg on_level_screen,
    output reg on_lines_screen,
    output reg on_next_block_screen
);

// game
always @(posedge vga_clk) begin
    if (
        (`GAME_COORDINATE_ROW <= vga_row && vga_row < `GAME_COORDINATE_ROW + `GAME_HEIGHT) &&
        (`GAME_COORDINATE_COL <= vga_col && vga_col < `GAME_COORDINATE_COL + `GAME_WIDTH)
    )
        on_game_screen <= `TRUE;
    else
        on_game_screen <= `FALSE;
end

// score
always @(posedge vga_clk) begin
    if (
        (`SCORE_COORDINATE_ROW <= vga_row && vga_row < `SCORE_COORDINATE_ROW + `SCORE_HEIGHT) &&
        (`SCORE_COORDINATE_COL <= vga_col && vga_col < `SCORE_COORDINATE_COL + `SCORE_WIDTH)
    )
        on_score_screen <= `TRUE;
    else
        on_score_screen <= `FALSE;
end

// level
always @(posedge vga_clk) begin
    if (
        (`LEVEL_COORDINATE_ROW <= vga_row && vga_row < `LEVEL_COORDINATE_ROW + `LEVEL_HEIGHT) &&
        (`LEVEL_COORDINATE_COL <= vga_col && vga_col < `LEVEL_COORDINATE_COL + `LEVEL_WIDTH)
    )
        on_level_screen <= `TRUE;
    else
        on_level_screen <= `FALSE;
end

// lines
always @(posedge vga_clk) begin
    if (
        (`LINES_COORDINATE_ROW <= vga_row && vga_row < `LINES_COORDINATE_ROW + `LINES_HEIGHT) &&
        (`LINES_COORDINATE_COL <= vga_col && vga_col < `LINES_COORDINATE_COL + `LINES_WIDTH)
    )
        on_lines_screen <= `TRUE;
    else
        on_lines_screen <= `FALSE;
end

// upcoming block
always @(posedge vga_clk) begin
    if (
        (`NEXT_BLOCK_COORDINATE_ROW <= vga_row && vga_row < `NEXT_BLOCK_COORDINATE_ROW + `NEXT_BLOCK_HEIGHT) &&
        (`NEXT_BLOCK_COORDINATE_COL <= vga_col && vga_col < `NEXT_BLOCK_COORDINATE_COL + `NEXT_BLOCK_WIDTH)
    )
        on_next_block_screen <= `TRUE;
    else
        on_next_block_screen <= `FALSE;
end

endmodule