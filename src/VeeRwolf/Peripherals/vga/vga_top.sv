/*
@file: vga_top.v
@author: Gene Hu & Eduardo Sanchez Simancas
@date: 2/23/24
@version: 1

@brief:
This module connects the h_sync, v_sync, and red, green, and blue wires from the onboard VGA on the Nexys board
to the RISC-v VeerWolf-EL2 Core via the wishbone bus. The DTG module uses the 40MHz VGA clk to move through a 
800x640 pixel screen and reads a DUALPORT BRAM block that contains the content of the game that will be displayed on monitor


@credit: 
The dtg module was written by Roy Kravits
The Chars module came FizzBuzz article from here: https://github.com/shirriff/vga-fpga-fizzbuzz/blob/master/src/chars.v
*/
`include "game_defines.svh"
`default_nettype wire

module vga_top(
    input wire  vga_clk,
    input wb_clk_i,	        // Clock
    input wb_rst_i,	        // Reset
    input wb_cyc_i,	        // cycle valid input
    input [7:0]  wb_adr_i,	// address bus inputs
    input [31:0] wb_dat_i,	// input data bus
    input wb_we_i,	        // indicates write transfer
    input wb_stb_i,	        // strobe input
    output [31:0] wb_dat_o,	// output data bus
    output wb_ack_o,	    // normal termination 
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b,
    output wire h_sync,
    output wire v_sync
);

// returned values from DTG module
reg on_screen;
reg [11:0] vga_row_position;
reg [11:0] vga_col_position;
reg [31:0] screen_vectorization;
reg [2:0] row_offset, col_offset, digit_index;

// returned values from RAM module
reg [11:0] current_pixel_color;

// returned values from game sections module
reg on_game_screen; 
reg on_score_screen;
reg on_level_screen;
reg on_lines_screen;
reg on_next_block_screen;

// returned values from chars module
reg [7:0] score_number_layer;
reg [7:0] level_number_layer;
reg [7:0] lines_number_layer;
reg [31:0] next_block_layer;

/**** application register interface ****/
reg wb_ack_ff;
reg [31:0] screen_position_register;
reg [31:0] rgb_value_register;
reg [9:0]  cpu_row_position, cpu_col_position;
reg [11:0] cpu_rgb_value;
reg [31:0] next_tetris_block;
reg [31:0] score_register;
reg [31:0] level_register;
reg [31:0] lines_register;

reg [11:0] tetris_block_color;

// initial position and pixel color
initial begin
    screen_position_register <= '0;
    rgb_value_register <= '0;
    next_tetris_block <= '0;
    score_register <= '0;
    level_register <= '0;
    lines_register <= '0;
    timer <= '0;
    counter <= '0;
end

// get register values from RISC-V core
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if (wb_rst_i) begin
        screen_position_register <= '0;
        rgb_value_register <= '0;
        wb_ack_ff <= '0;
    end
    else begin
        case (wb_adr_i[5:2])
            0: 
            begin 
                screen_position_register = wb_ack_ff && wb_we_i ? wb_dat_i : screen_position_register;
                cpu_row_position = screen_position_register[19:10];
                cpu_col_position = screen_position_register[9:0];
            end
            1: 
            begin
                rgb_value_register = wb_ack_ff && wb_we_i ? wb_dat_i : rgb_value_register;
                cpu_rgb_value = rgb_value_register[11:0];
            end
            2:
            begin
                next_tetris_block = wb_ack_ff && wb_we_i ? wb_dat_i : next_tetris_block;
            end
            3:
            begin
                score_register = wb_ack_ff && wb_we_i ? wb_dat_i : score_register;
            end
            4:
            begin
                level_register = wb_ack_ff && wb_we_i ? wb_dat_i : level_register;
            end
            5:
            begin
                lines_register = wb_ack_ff && wb_we_i ? wb_dat_i : lines_register;
            end
        endcase
        wb_ack_ff <= !wb_ack_ff && wb_stb_i && wb_cyc_i;
    end
end

// drive wishbone bus 
assign wb_ack_o = wb_ack_ff;
assign wb_dat_o = (
    (wb_adr_i[5:2] == 0) ? screen_position_register : 
    ((wb_adr_i[5:2] == 1) ? rgb_value_register :
    ((wb_adr_i[5:2] == 2) ? next_tetris_block :
    ((wb_adr_i[5:2] == 3) ? score_register :
    ((wb_adr_i[5:2] == 4) ? level_register : lines_register))))
);

// dtg is used for horizontal & Vertical Display Timing & Sync generator for VESA timing
dtg dtg_inst(
    .clock        (vga_clk),
    .rst          (wb_rst_i),
    .video_on     (on_screen),
    .horiz_sync   (h_sync),
    .vert_sync    (v_sync),
    .pixel_row    (vga_row_position),
    .pixel_column (vga_col_position),
    .pix_num      (screen_vectorization)
);

// get current game screen
game_ram get_game_frame(
    .vga_clk             (vga_clk),
    .wb_clk_i            (wb_clk_i),
    .wb_rst_i            (wb_rst_i),
    .cpu_row_position    (cpu_row_position),
    .cpu_col_position    (cpu_col_position),
    .cpu_rgb_value       (cpu_rgb_value),
    .vga_row_position    (vga_row_position),
    .vga_col_position    (vga_col_position),
    .vga_on_screen       (on_screen),
    .vga_on_game_screen  (on_game_screen),
    .current_pixel_color (current_pixel_color)
);

// get TRUE/FALSE values to pass to VGA RTL
game_section get_sections(
    .vga_clk              (vga_clk),
    .vga_row              (vga_row_position),
    .vga_col              (vga_col_position),
    .on_game_screen       (on_game_screen),
    .on_score_screen      (on_score_screen),
    .on_level_screen      (on_level_screen),
    .on_lines_screen      (on_lines_screen),
    .on_next_block_screen (on_next_block_screen)
);

// return the pixel by pixel values of decimal digits that will be displayed on screen
chars get_score_number(
    .char   (score_register[(4*digit_index) +: 4]), 
    .rownum (row_offset),
    .pixels (score_number_layer)
);

// return the pixel by pixel values of decimal digits that will be displayed on screen
chars get_level_number(
    .char   (level_register[(4*digit_index) +: 4]), 
    .rownum (row_offset),
    .pixels (level_number_layer)
);

// return the pixel by pixel values of decimal digits that will be displayed on screen
chars get_lines_number(
    .char   (lines_register[(4*digit_index) +: 4]), 
    .rownum (row_offset),
    .pixels (lines_number_layer)
);

// return the pixel by pixel values of tetris sprite that will be displayed on screen
tetris_sprites get_next_block(
    .next_tetris_block (next_tetris_block[2:0]),
    .rownum (row_offset),
    .pixels(next_block_layer)
);

// get color for tetris block
always @(posedge vga_clk) begin
    case (next_tetris_block[2:0]) 
        `I_BLOCK: tetris_block_color = `CYAN; 
        `J_BLOCK: tetris_block_color = `BLUE; 
        `L_BLOCK: tetris_block_color = `ORANGE; 
        `O_BLOCK: tetris_block_color = `YELLOW;
        `S_BLOCK: tetris_block_color = `GREEN; 
        `T_BLOCK: tetris_block_color = `PURPLE; 
        `Z_BLOCK: tetris_block_color = `RED; 
        default: tetris_block_color = `BLACK;
    endcase
end

// main screen (MAIN RTL LOGIC)
always @(posedge vga_clk or posedge wb_rst_i) begin
    if (wb_rst_i) 
    begin
        vga_r <= '0;
        vga_g <= '0;
        vga_b <= '0;
    end 
    else if (on_screen && on_game_screen) 
    begin
        if (screen_position_register[31]) begin // user wants to turn on RTL driven sections
            if (on_score_screen) 
            begin
                row_offset <= ((vga_row_position - `SCORE_COORDINATE_ROW) % `BLOCK_SIZE) / `NEW_PIXEL_SIZE; 
                col_offset <= ((vga_col_position - `SCORE_COORDINATE_COL) % `BLOCK_SIZE) / `NEW_PIXEL_SIZE;
                digit_index <= 5 - (vga_col_position - `SCORE_COORDINATE_COL) / `BLOCK_SIZE;

                vga_r <= ~{4{score_number_layer[7 - col_offset]}};
                vga_g <= ~{4{score_number_layer[7 - col_offset]}};
                vga_b <= ~{4{score_number_layer[7 - col_offset]}};
            end
            else if (on_level_screen) 
            begin
                row_offset <= ((vga_row_position - `LEVEL_COORDINATE_ROW) % `BLOCK_SIZE) / `NEW_PIXEL_SIZE; 
                col_offset <= ((vga_col_position - `LEVEL_COORDINATE_COL) % `BLOCK_SIZE) / `NEW_PIXEL_SIZE;
                digit_index <= 5 - (vga_col_position - `LEVEL_COORDINATE_COL) / `BLOCK_SIZE;

                vga_r <= ~{4{level_number_layer[7 - col_offset]}};
                vga_g <= ~{4{level_number_layer[7 - col_offset]}};
                vga_b <= ~{4{level_number_layer[7 - col_offset]}};
            end
            else if (on_lines_screen) 
            begin
                row_offset <= ((vga_row_position - `LINES_COORDINATE_ROW) % `BLOCK_SIZE) / `NEW_PIXEL_SIZE; 
                col_offset <= ((vga_col_position - `LINES_COORDINATE_COL) % `BLOCK_SIZE) / `NEW_PIXEL_SIZE;
                digit_index <= 5 - (vga_col_position - `LINES_COORDINATE_COL) / `BLOCK_SIZE;

                vga_r <= ~{4{lines_number_layer[7 - col_offset]}};
                vga_g <= ~{4{lines_number_layer[7 - col_offset]}};
                vga_b <= ~{4{lines_number_layer[7 - col_offset]}};
            end
            else if (on_next_block_screen) 
            begin
                row_offset <= (vga_row_position - `NEXT_BLOCK_COORDINATE_ROW) / (`NEW_PIXEL_SIZE*4); 
                col_offset <= (vga_col_position - `NEXT_BLOCK_COORDINATE_COL) / (`NEW_PIXEL_SIZE*4);

                if (next_block_layer[7 - col_offset])
                begin
                    vga_r <= tetris_block_color[11:8];
                    vga_g <= tetris_block_color[7:4];
                    vga_b <= tetris_block_color[3:0];
                end
                else 
                begin
                    vga_r <= `WHITE;
                    vga_g <= `WHITE;
                    vga_b <= `WHITE;
                end
            end
            else 
            begin // draw game frame from RAM
                row_offset <= 0; col_offset <= 0; digit_index <= 0;
                vga_r <= current_pixel_color[11:8];
                vga_g <= current_pixel_color[7:4];
                vga_b <= current_pixel_color[3:0];
            end
        end
        else begin // user wants to turn OFF RTL driven sections
            vga_r <= current_pixel_color[11:8];
            vga_g <= current_pixel_color[7:4];
            vga_b <= current_pixel_color[3:0];
        end
    end 
    else 
    begin
        // don't drive lines outside screen
        vga_r <= '0;
        vga_g <= '0;
        vga_b <= '0;
    end
end


endmodule
