/*
brief: hard coded tetris shapes so RTL can update the "incoming shape" section of the screen
saves CPU clocks cycles
*/

module tetris_sprites(
    input [2:0] next_tetris_block,
    input [2:0] rownum,
    output reg [7:0] pixels
);

always @(*)
  case ({next_tetris_block, rownum}) // Concatanation; char selects which character, rownum selects the row of that character to give back
    // I-Block
    8'b000000: pixels = 8'b00000000;
    8'b000001: pixels = 8'b00000000;
    8'b000010: pixels = 8'b00000000;
    8'b000011: pixels = 8'b00000000;
    8'b000100: pixels = 8'b11111111;
    8'b000101: pixels = 8'b11111111;
    8'b000110: pixels = 8'b00000000;
    8'b000111: pixels = 8'b00000000;

    // J-Block
    8'b010000: pixels = 8'b00000000;
    8'b010001: pixels = 8'b00000000;
    8'b010010: pixels = 8'b00000000;
    8'b010011: pixels = 8'b00000000;
    8'b010100: pixels = 8'b11111111;
    8'b010101: pixels = 8'b11111111;
    8'b010110: pixels = 8'b00000011;
    8'b010111: pixels = 8'b00000011;

    // L-Block
    8'b001000: pixels = 8'b00000000;
    8'b001001: pixels = 8'b00000000;
    8'b001010: pixels = 8'b00000000;
    8'b001011: pixels = 8'b00000000;
    8'b001100: pixels = 8'b11111111;
    8'b001101: pixels = 8'b11111111;
    8'b001110: pixels = 8'b11000000;
    8'b001111: pixels = 8'b11000000;

    // O-Block
    8'b011000: pixels = 8'b00000000;
    8'b011001: pixels = 8'b00000000;
    8'b011010: pixels = 8'b00111100;
    8'b011011: pixels = 8'b00111100;
    8'b011100: pixels = 8'b00111100;
    8'b011101: pixels = 8'b00111100;
    8'b011110: pixels = 8'b00000000;
    8'b011111: pixels = 8'b00000000;

    // S-Block
    8'b100000: pixels = 8'b00000000;
    8'b100001: pixels = 8'b00000000;
    8'b100010: pixels = 8'b00111100;
    8'b100011: pixels = 8'b00111100;
    8'b100100: pixels = 8'b11110000;
    8'b100101: pixels = 8'b11110000;
    8'b100110: pixels = 8'b00000000;
    8'b100111: pixels = 8'b00000000;

    // T-Block
    8'b101000: pixels = 8'b00000000;
    8'b101001: pixels = 8'b00000000;
    8'b101010: pixels = 8'b11111100;
    8'b101011: pixels = 8'b11111100;
    8'b101100: pixels = 8'b00110000;
    8'b101101: pixels = 8'b00110000;
    8'b101110: pixels = 8'b00000000;
    8'b101111: pixels = 8'b00000000;

    // Z-Block
    8'b110000: pixels = 8'b00000000;
    8'b110001: pixels = 8'b00000000;
    8'b110010: pixels = 8'b11110000;
    8'b110011: pixels = 8'b11110000;
    8'b110100: pixels = 8'b00111100;
    8'b110101: pixels = 8'b00111100;
    8'b110110: pixels = 8'b00000000;
    8'b110111: pixels = 8'b00000000;

    default: pixels = 8'b0;

  endcase
endmodule