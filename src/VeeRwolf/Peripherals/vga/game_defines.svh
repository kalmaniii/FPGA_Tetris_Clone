/**
brief: constants used throughout VGA modules and other RTL files
*/
`define RAM_WIDTH  160
`define RAM_HEIGHT 144

// section of the game board
`define NEW_PIXEL_SIZE 4  // X by X squares are used to map 800x600 vga screen to 160x144 (4x4 pixel) gameboy screen
`define BLOCK_SIZE   32   // 8x8 tetris block (after dividing by NEW_PIXEL_SIZE)
`define GAME_WIDTH   640  // 160 (after dividing by NEW_PIXEL_SIZE)
`define GAME_HEIGHT  576  // 144
`define GAME_COORDINATE_ROW 12  // center screen 
`define GAME_COORDINATE_COL 80  // center screen

`define SCORE_WIDTH  192 // 48
`define SCORE_HEIGHT 32  // 8
`define SCORE_COORDINATE_ROW (320 + `GAME_COORDINATE_ROW) // 80 + 12  <-- top left (x, y) coordinate where score will be drawn 
`define SCORE_COORDINATE_COL (448 + `GAME_COORDINATE_COL) // 112

`define LEVEL_WIDTH  192 // 48
`define LEVEL_HEIGHT 32  // 8
`define LEVEL_COORDINATE_ROW (416 + `GAME_COORDINATE_ROW) // 104
`define LEVEL_COORDINATE_COL (448 + `GAME_COORDINATE_COL) // 112

`define LINES_WIDTH  192 // 48
`define LINES_HEIGHT 32  // 8
`define LINES_COORDINATE_ROW (512 + `GAME_COORDINATE_ROW) // 128
`define LINES_COORDINATE_COL (448 + `GAME_COORDINATE_COL) // 112

`define NEXT_BLOCK_WIDTH  128 // 32
`define NEXT_BLOCK_HEIGHT 128 // 32
`define NEXT_BLOCK_COORDINATE_ROW (96 + `GAME_COORDINATE_ROW) // 24
`define NEXT_BLOCK_COORDINATE_COL (480 + `GAME_COORDINATE_COL) // 120

`define TRUE  1
`define FALSE 0

`define I_BLOCK 0
`define J_BLOCK 1
`define L_BLOCK 2
`define O_BLOCK 3
`define S_BLOCK 4
`define T_BLOCK 5
`define Z_BLOCK 6

`define CYAN    12'h0FF
`define BLUE    12'h00F
`define ORANGE  12'hF72
`define YELLOW  12'hFF0
`define GREEN   12'h0F4
`define PURPLE  12'h90F
`define RED     12'hF00
`define BLACK   '0
`define WHITE   '1

