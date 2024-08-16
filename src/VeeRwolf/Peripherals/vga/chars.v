//////////////////////////////////////////////////////////////////////////////////
// 
// Character generator holding 8x8 character images.
// Input char is a 6-bit character number representing:
// 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C... Y, Z... <blank>
// Input rownum is the desired row of the pixel image
// Output pixels is the 8 pixel row, pixels[7] is leftmost.
// Original font from https://github.com/dhepper/font8x8/blob/master/font8x8_basic.h
// Original module from https://github.com/shirriff/vga-fpga-fizzbuzz/blob/master/src/chars.v

module chars(
    input [3:0] char,
    input [2:0] rownum,
    output reg [7:0] pixels
);

always @(*)
  case ({char, rownum}) // Concatanation; char selects which character, rownum selects the row of that character to give back
    7'b0000000: pixels = 8'b01111100; //  XXXXX  
    7'b0000001: pixels = 8'b11000110; // XX   XX 
    7'b0000010: pixels = 8'b11001110; // XX  XXX
    7'b0000011: pixels = 8'b11011110; // XX XXXX
    7'b0000100: pixels = 8'b11110110; // XXXX XX
    7'b0000101: pixels = 8'b11100110; // XXX  XX
    7'b0000110: pixels = 8'b01111100; //  XXXXX
    7'b0000111: pixels = 8'b00000000; //

    7'b0001000: pixels = 8'b00110000; //   XX
    7'b0001001: pixels = 8'b01110000; //  XXX
    7'b0001010: pixels = 8'b00110000; //   XX
    7'b0001011: pixels = 8'b00110000; //   XX
    7'b0001100: pixels = 8'b00110000; //   XX
    7'b0001101: pixels = 8'b00110000; //   XX
    7'b0001110: pixels = 8'b11111100; // XXXXXX
    7'b0001111: pixels = 8'b00000000; //

    7'b0010000: pixels = 8'b01111000; //  XXXX
    7'b0010001: pixels = 8'b11001100; // XX  XX
    7'b0010010: pixels = 8'b00001100; //     XX
    7'b0010011: pixels = 8'b00111000; //   XXX
    7'b0010100: pixels = 8'b01100000; //  XX
    7'b0010101: pixels = 8'b11001100; // XX  XX
    7'b0010110: pixels = 8'b11111100; // XXXXXX
    7'b0010111: pixels = 8'b00000000; //

    7'b0011000: pixels = 8'b01111000; //  XXXX
    7'b0011001: pixels = 8'b11001100; // XX  XX
    7'b0011010: pixels = 8'b00001100; //     XX
    7'b0011011: pixels = 8'b00111000; //   XXX
    7'b0011100: pixels = 8'b00001100; //     XX
    7'b0011101: pixels = 8'b11001100; // XX  XX
    7'b0011110: pixels = 8'b01111000; //  XXXX
    7'b0011111: pixels = 8'b00000000; //

    7'b0100000: pixels = 8'b00011100; //    XXX
    7'b0100001: pixels = 8'b00111100; //   XXXX
    7'b0100010: pixels = 8'b01101100; //  XX XX
    7'b0100011: pixels = 8'b11001100; // XX  XX
    7'b0100100: pixels = 8'b11111110; // XXXXXXX
    7'b0100101: pixels = 8'b00001100; //     XX
    7'b0100110: pixels = 8'b00011110; //    XXXX
    7'b0100111: pixels = 8'b00000000; //

    7'b0101000: pixels = 8'b11111100; // XXXXXX
    7'b0101001: pixels = 8'b11000000; // XX
    7'b0101010: pixels = 8'b11111000; // XXXXX
    7'b0101011: pixels = 8'b00001100; //     XX
    7'b0101100: pixels = 8'b00001100; //     XX
    7'b0101101: pixels = 8'b11001100; // XX  XX
    7'b0101110: pixels = 8'b01111000; //  XXXX
    7'b0101111: pixels = 8'b00000000; //

    7'b0110000: pixels = 8'b00111000; //   XXX
    7'b0110001: pixels = 8'b01100000; //  XX
    7'b0110010: pixels = 8'b11000000; // XX
    7'b0110011: pixels = 8'b11111000; // XXXXX
    7'b0110100: pixels = 8'b11001100; // XX  XX
    7'b0110101: pixels = 8'b11001100; // XX  XX
    7'b0110110: pixels = 8'b01111000; //  XXXX
    7'b0110111: pixels = 8'b00000000; //

    7'b0111000: pixels = 8'b11111100; // XXXXXX
    7'b0111001: pixels = 8'b11001100; // XX  XX
    7'b0111010: pixels = 8'b00001100; //     XX
    7'b0111011: pixels = 8'b00011000; //    XX
    7'b0111100: pixels = 8'b00110000; //   XX
    7'b0111101: pixels = 8'b00110000; //   XX
    7'b0111110: pixels = 8'b00110000; //   XX
    7'b0111111: pixels = 8'b00000000; //

    7'b1000000: pixels = 8'b01111000; //  XXXX
    7'b1000001: pixels = 8'b11001100; // XX  XX
    7'b1000010: pixels = 8'b11001100; // XX  XX
    7'b1000011: pixels = 8'b01111000; //  XXXX
    7'b1000100: pixels = 8'b11001100; // XX  XX
    7'b1000101: pixels = 8'b11001100; // XX  XX
    7'b1000110: pixels = 8'b01111000; //  XXXX
    7'b1000111: pixels = 8'b00000000; //

    7'b1001000: pixels = 8'b01111000; //  XXXX
    7'b1001001: pixels = 8'b11001100; // XX  XX
    7'b1001010: pixels = 8'b11001100; // XX  XX
    7'b1001011: pixels = 8'b01111100; //  XXXXX
    7'b1001100: pixels = 8'b00001100; //     XX
    7'b1001101: pixels = 8'b00011000; //    XX
    7'b1001110: pixels = 8'b01110000; //  XXX
    7'b1001111: pixels = 8'b00000000; //

    7'b1010000: pixels = 8'b00110000; //   XX
    7'b1010001: pixels = 8'b01111000; //  XXXX
    7'b1010010: pixels = 8'b11001100; // XX  XX
    7'b1010011: pixels = 8'b11001100; // XX  XX
    7'b1010100: pixels = 8'b11111100; // XXXXXX
    7'b1010101: pixels = 8'b11001100; // XX  XX
    7'b1010110: pixels = 8'b11001100; // XX  XX
    7'b1010111: pixels = 8'b00000000; //

    7'b1011000: pixels = 8'b11111100; // XXXXXX
    7'b1011001: pixels = 8'b01100110; //  XX  XX
    7'b1011010: pixels = 8'b01100110; //  XX  XX
    7'b1011011: pixels = 8'b01111100; //  XXXXX
    7'b1011100: pixels = 8'b01100110; //  XX  XX
    7'b1011101: pixels = 8'b01100110; //  XX  XX
    7'b1011110: pixels = 8'b11111100; // XXXXXX
    7'b1011111: pixels = 8'b00000000; //

    7'b1100000: pixels = 8'b00111100; //   XXXX
    7'b1100001: pixels = 8'b01100110; //  XX  XX
    7'b1100010: pixels = 8'b11000000; // XX
    7'b1100011: pixels = 8'b11000000; // XX
    7'b1100100: pixels = 8'b11000000; // XX
    7'b1100101: pixels = 8'b01100110; //  XX  XX
    7'b1100110: pixels = 8'b00111100; //   XXXX
    7'b1100111: pixels = 8'b00000000; //

    7'b1101000: pixels = 8'b11111000; // XXXXX
    7'b1101001: pixels = 8'b01101100; //  XX XX
    7'b1101010: pixels = 8'b01100110; //  XX  XX
    7'b1101011: pixels = 8'b01100110; //  XX  XX
    7'b1101100: pixels = 8'b01100110; //  XX  XX
    7'b1101101: pixels = 8'b01101100; //  XX XX
    7'b1101110: pixels = 8'b11111000; // XXXXX
    7'b1101111: pixels = 8'b00000000; //

    7'b1110000: pixels = 8'b11111110; // XXXXXXX
    7'b1110001: pixels = 8'b01100010; //  XX   X
    7'b1110010: pixels = 8'b01101000; //  XX X
    7'b1110011: pixels = 8'b01111000; //  XXXX
    7'b1110100: pixels = 8'b01101000; //  XX X
    7'b1110101: pixels = 8'b01100010; //  XX   X
    7'b1110110: pixels = 8'b11111110; // XXXXXXX
    7'b1110111: pixels = 8'b00000000; //

    7'b1111000: pixels = 8'b11111110; // XXXXXXX
    7'b1111001: pixels = 8'b01100010; //  XX   X
    7'b1111010: pixels = 8'b01101000; //  XX X
    7'b1111011: pixels = 8'b01111000; //  XXXX
    7'b1111100: pixels = 8'b01101000; //  XX X
    7'b1111101: pixels = 8'b01100000; //  XX
    7'b1111110: pixels = 8'b11110000; // XXXX
    7'b1111111: pixels = 8'b00000000; //

    8'b10000000: pixels = 8'b00111100; //   XXXX
    8'b10000001: pixels = 8'b01100110; //  XX  XX
    8'b10000010: pixels = 8'b11000000; // XX
    8'b10000011: pixels = 8'b11000000; // XX
    8'b10000100: pixels = 8'b11001110; // XX  XXX 
    8'b10000101: pixels = 8'b01100110; //  XX  XX
    8'b10000110: pixels = 8'b00111110; //   XXXXX
    8'b10000111: pixels = 8'b00000000; //

    8'b10001000: pixels = 8'b11001100; // XX  XX
    8'b10001001: pixels = 8'b11001100; // XX  XX
    8'b10001010: pixels = 8'b11001100; // XX  XX
    8'b10001011: pixels = 8'b11111100; // XXXXXX
    8'b10001100: pixels = 8'b11001100; // XX  XX
    8'b10001101: pixels = 8'b11001100; // XX  XX
    8'b10001110: pixels = 8'b11001100; // XX  XX
    8'b10001111: pixels = 8'b00000000; //

    8'b10010000: pixels = 8'b01111000; //  XXXX
    8'b10010001: pixels = 8'b00110000; //   XX
    8'b10010010: pixels = 8'b00110000; //   XX
    8'b10010011: pixels = 8'b00110000; //   XX
    8'b10010100: pixels = 8'b00110000; //   XX
    8'b10010101: pixels = 8'b00110000; //   XX
    8'b10010110: pixels = 8'b01111000; //  XXXX
    8'b10010111: pixels = 8'b00000000; //

    8'b10011000: pixels = 8'b00011110; //    XXXX
    8'b10011001: pixels = 8'b00001100; //     XX
    8'b10011010: pixels = 8'b00001100; //     XX
    8'b10011011: pixels = 8'b00001100; //     XX
    8'b10011100: pixels = 8'b11001100; // XX  XX
    8'b10011101: pixels = 8'b11001100; // XX  XX
    8'b10011110: pixels = 8'b01111000; //  XXXX
    8'b10011111: pixels = 8'b00000000; //

    8'b10100000: pixels = 8'b11100110; // XXX  XX
    8'b10100001: pixels = 8'b01100110; //  XX  XX
    8'b10100010: pixels = 8'b01101100; //  XX XX
    8'b10100011: pixels = 8'b01111000; //  XXXX
    8'b10100100: pixels = 8'b01101100; //  XX XX
    8'b10100101: pixels = 8'b01100110; //  XX  XX
    8'b10100110: pixels = 8'b11100110; // XXX  XX
    8'b10100111: pixels = 8'b00000000; //

    8'b10101000: pixels = 8'b11110000; // XXXX
    8'b10101001: pixels = 8'b01100000; //  XX
    8'b10101010: pixels = 8'b01100000; //  XX
    8'b10101011: pixels = 8'b01100000; //  XX
    8'b10101100: pixels = 8'b01100010; //  XX   X
    8'b10101101: pixels = 8'b01100110; //  XX  XX
    8'b10101110: pixels = 8'b11111110; // XXXXXXX
    8'b10101111: pixels = 8'b00000000; //

    8'b10110000: pixels = 8'b11000110; // XX   XX
    8'b10110001: pixels = 8'b11101110; // XXX XXX
    8'b10110010: pixels = 8'b11111110; // XXXXXXX
    8'b10110011: pixels = 8'b11111110; // XXXXXXX
    8'b10110100: pixels = 8'b11010110; // XX X XX
    8'b10110101: pixels = 8'b11000110; // XX   XX
    8'b10110110: pixels = 8'b11000110; // XX   XX
    8'b10110111: pixels = 8'b00000000; //

    8'b10111000: pixels = 8'b11000110; // XX   XX
    8'b10111001: pixels = 8'b11100110; // XXX  XX
    8'b10111010: pixels = 8'b11110110; // XXXX XX
    8'b10111011: pixels = 8'b11011110; // XX XXXX
    8'b10111100: pixels = 8'b11001110; // XX  XXX
    8'b10111101: pixels = 8'b11000110; // XX   XX
    8'b10111110: pixels = 8'b11000110; // XX   XX 
    8'b10111111: pixels = 8'b00000000; //

    8'b11000000: pixels = 8'b00111000; //   XXX
    8'b11000001: pixels = 8'b01101100; //  XX XX
    8'b11000010: pixels = 8'b11000110; // XX   XX
    8'b11000011: pixels = 8'b11000110; // XX   XX
    8'b11000100: pixels = 8'b11000110; // XX   XX
    8'b11000101: pixels = 8'b01101100; //  XX XX
    8'b11000110: pixels = 8'b00111000; //   XXX
    8'b11000111: pixels = 8'b00000000; //

    8'b11001000: pixels = 8'b11111100; // XXXXXX
    8'b11001001: pixels = 8'b01100110; //  XX  XX
    8'b11001010: pixels = 8'b01100110; //  XX  XX
    8'b11001011: pixels = 8'b01111100; //  XXXXX
    8'b11001100: pixels = 8'b01100000; //  XX
    8'b11001101: pixels = 8'b01100000; //  XX
    8'b11001110: pixels = 8'b11110000; // XXXX
    8'b11001111: pixels = 8'b00000000; //

    8'b11010000: pixels = 8'b01111000; //  XXXX
    8'b11010001: pixels = 8'b11001100; // XX  XX
    8'b11010010: pixels = 8'b11001100; // XX  XX
    8'b11010011: pixels = 8'b11001100; // XX  XX
    8'b11010100: pixels = 8'b11011100; // XX XXX
    8'b11010101: pixels = 8'b01111000; //  XXXX
    8'b11010110: pixels = 8'b00011100; //    XXX
    8'b11010111: pixels = 8'b00000000; //

    8'b11011000: pixels = 8'b11111100; // XXXXXX
    8'b11011001: pixels = 8'b01100110; //  XX  XX
    8'b11011010: pixels = 8'b01100110; //  XX  XX 
    8'b11011011: pixels = 8'b01111100; //  XXXXX
    8'b11011100: pixels = 8'b01101100; //  XX XX
    8'b11011101: pixels = 8'b01100110; //  XX  XX
    8'b11011110: pixels = 8'b11100110; // XXX  XX
    8'b11011111: pixels = 8'b00000000; //

    8'b11100000: pixels = 8'b01111000; //  XXXX
    8'b11100001: pixels = 8'b11001100; // XX  XX
    8'b11100010: pixels = 8'b11100000; // XXX
    8'b11100011: pixels = 8'b01110000; //  XXX
    8'b11100100: pixels = 8'b00011100; //    XXX
    8'b11100101: pixels = 8'b11001100; // XX  XX
    8'b11100110: pixels = 8'b01111000; //  XXXX
    8'b11100111: pixels = 8'b00000000; //

    8'b11101000: pixels = 8'b11111100; // XXXXXX
    8'b11101001: pixels = 8'b10110100; // X XX X
    8'b11101010: pixels = 8'b00110000; //   XX
    8'b11101011: pixels = 8'b00110000; //   XX
    8'b11101100: pixels = 8'b00110000; //   XX
    8'b11101101: pixels = 8'b00110000; //   XX
    8'b11101110: pixels = 8'b01111000; //  XXXX
    8'b11101111: pixels = 8'b00000000; //

    8'b11110000: pixels = 8'b11001100; // XX  XX
    8'b11110001: pixels = 8'b11001100; // XX  XX
    8'b11110010: pixels = 8'b11001100; // XX  XX
    8'b11110011: pixels = 8'b11001100; // XX  XX
    8'b11110100: pixels = 8'b11001100; // XX  XX
    8'b11110101: pixels = 8'b11001100; // XX  XX
    8'b11110110: pixels = 8'b11111100; // XXXXXX
    8'b11110111: pixels = 8'b00000000; //

    8'b11111000: pixels = 8'b11001100; // XX  XX
    8'b11111001: pixels = 8'b11001100; // XX  XX
    8'b11111010: pixels = 8'b11001100; // XX  XX
    8'b11111011: pixels = 8'b11001100; // XX  XX
    8'b11111100: pixels = 8'b11001100; // XX  XX
    8'b11111101: pixels = 8'b01111000; //  XXXX   
    8'b11111110: pixels = 8'b00110000; //   XX
    8'b11111111: pixels = 8'b00000000; //

    9'b100000000: pixels = 8'b11000110; // XX   XX
    9'b100000001: pixels = 8'b11000110; // XX   XX
    9'b100000010: pixels = 8'b11000110; // XX   XX
    9'b100000011: pixels = 8'b11010110; // XX X XX
    9'b100000100: pixels = 8'b11111110; // XXXXXXX
    9'b100000101: pixels = 8'b11101110; // XXX XXX
    9'b100000110: pixels = 8'b11000110; // XX   XX
    9'b100000111: pixels = 8'b00000000; //

    9'b100001000: pixels = 8'b11000110; // XX   XX
    9'b100001001: pixels = 8'b11000110; // XX   XX
    9'b100001010: pixels = 8'b01101100; //  XX XX
    9'b100001011: pixels = 8'b00111000; //   XXX
    9'b100001100: pixels = 8'b00111000; //   XXX
    9'b100001101: pixels = 8'b01101100; //  XX XX
    9'b100001110: pixels = 8'b11000110; // XX   XX
    9'b100001111: pixels = 8'b00000000; //

    9'b100010000: pixels = 8'b11001100; // XX  XX
    9'b100010001: pixels = 8'b11001100; // XX  XX
    9'b100010010: pixels = 8'b11001100; // XX  XX
    9'b100010011: pixels = 8'b01111000; //  XXXX
    9'b100010100: pixels = 8'b00110000; //   XX
    9'b100010101: pixels = 8'b00110000; //   XX
    9'b100010110: pixels = 8'b01111000; //  XXXX
    9'b100010111: pixels = 8'b00000000; //
    
    9'b100011000: pixels = 8'b11111110; // XXXXXXX
    9'b100011001: pixels = 8'b11000110; // XX   XX
    9'b100011010: pixels = 8'b10001100; // X   XX
    9'b100011011: pixels = 8'b00011000; //    XX
    9'b100011100: pixels = 8'b00110010; //   XX  X
    9'b100011101: pixels = 8'b01100110; //  XX  XX
    9'b100011110: pixels = 8'b11111110; // XXXXXXX
    9'b100011111: pixels = 8'b00000000; //

    9'b100100000: pixels = 8'b00000000; // 
    9'b100100001: pixels = 8'b00000000; // 
    9'b100100010: pixels = 8'b00000000; // 
    9'b100100011: pixels = 8'b00000000; //
    9'b100100100: pixels = 8'b00000000; // 
    9'b100100101: pixels = 8'b00000000; // 
    9'b100100110: pixels = 8'b00000000; // 
    9'b100100111: pixels = 8'b00000000; //

    default: pixels = 8'b00000000;
  endcase
endmodule