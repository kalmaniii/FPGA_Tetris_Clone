/*
@file: audio_top.v
@author: Gene Hu
@date: 3/4/24
@version: 2

@brief:
Stores audio file (.raw -> .mem) from memory into a RAM.
Based on register input audio_select, an audio file will be played.
As of right now, only the Tetris theme song is available.
*/


`default_nettype wire

module audio_top(
    wb_clk_i, 
    wb_rst_i, 
    wb_cyc_i, 
    wb_adr_i,
    wb_dat_i, 
    wb_we_i, 
    wb_stb_i, 
    wb_dat_o,
    wb_ack_o,
    aud_pwm,
    aud_en
    );

// WISHBONE Interface
input             wb_clk_i;	// Clock
input             wb_rst_i;	// Reset
input             wb_cyc_i;	// cycle valid input
input       [7:0] wb_adr_i;	// address bus inputs
input      [31:0] wb_dat_i;	// input data bus
input             wb_we_i;	// indicates write transfer
input             wb_stb_i;	// strobe input
output     [31:0] wb_dat_o;	// output data bus
output            wb_ack_o;	// normal termination

output wire aud_pwm;
output reg aud_en;

// Storing audio files from memory into RAM
// Theme song is split into two parts to save RAM. This is possible because ThemePart1 is repeated in the music.
localparam MEM_SIZE_THEME1              = 102956;
localparam MEM_SIZE_THEME2              = 102884;
// SFX
localparam MEM_SIZE_MENU_SOUND          = 2020;
localparam MEM_SIZE_LEVEL_UP            = 8562;
localparam MEM_SIZE_GAME_OVER           = 8110;

localparam MEM_SIZE_LINE_CLEAR          = 16728;
localparam MEM_SIZE_LINE_CLEAR_FOUR     = 15089;
localparam MEM_SIZE_LINE_CLEAR_FALLING  = 3614;

localparam MEM_SIZE_PIECE_LANDED        = 4756;
localparam MEM_SIZE_PIECE_ROTATE        = 4839;
localparam MEM_SIZE_PIECE_MOVE          = 614;

// BRAM of audio files
(* ram_style = "block" *) reg [7:0] theme1              [MEM_SIZE_THEME1-1:0]; 
(* ram_style = "block" *) reg [7:0] theme2              [MEM_SIZE_THEME2-1:0];

(* ram_style = "block" *) reg [7:0] menu_sound          [MEM_SIZE_MENU_SOUND-1:0]; 
(* ram_style = "block" *) reg [7:0] level_up            [MEM_SIZE_LEVEL_UP-1:0]; 
(* ram_style = "block" *) reg [7:0] game_over           [MEM_SIZE_GAME_OVER-1:0]; 

(* ram_style = "block" *) reg [7:0] line_clear          [MEM_SIZE_LINE_CLEAR-1:0]; 
(* ram_style = "block" *) reg [7:0] line_clear_four     [MEM_SIZE_LINE_CLEAR_FOUR-1:0]; 
(* ram_style = "block" *) reg [7:0] line_clear_falling  [MEM_SIZE_LINE_CLEAR_FALLING-1:0]; 

(* ram_style = "block" *) reg [7:0] piece_landed        [MEM_SIZE_PIECE_LANDED-1:0]; 
(* ram_style = "block" *) reg [7:0] piece_rotate        [MEM_SIZE_PIECE_ROTATE-1:0]; 
(* ram_style = "block" *) reg [7:0] piece_move          [MEM_SIZE_PIECE_MOVE-1:0]; 

// Reading audio files from memory and writing into BRAM
initial begin
    $readmemh("theme8000PART1.mem", theme1);
    $readmemh("theme8000PART2.mem", theme2);

    $readmemh("menu_sound.mem", menu_sound);
    $readmemh("level_up.mem"  , level_up);
    $readmemh("game_over.mem" , game_over);

    $readmemh("line_clear.mem"        , line_clear);
    $readmemh("line_clear_four.mem"   , line_clear_four);
    $readmemh("line_clear_falling.mem", line_clear_falling);

    $readmemh("piece_landed.mem", piece_landed);
    $readmemh("piece_rotate.mem", piece_rotate);
    $readmemh("piece_move.mem"  , piece_move);
end

// Variables used for dividing the clock, pulsing the signal, and outputting to aud_pwm
localparam PRESCALER_MAX = 2; // Up to 64; NOTE: when clk = 50MHz, any prescale value above 2 gives a whine
localparam COUNTER_MAX = 255; // Up to 256
// universal
reg [19:0] address;
reg [5:0] prescaler;
reg [7:0] counter;
reg [7:0] value;
// theme gets separate var because it can be interrupted
reg [19:0] address_theme;
// lock is needed so a SFX doesn't repeat
reg lock;

// States of the theme music
// I broke the theme into two parts, and part one is repeated to complete the theme music
// This was done to save space
localparam state0 = 2'b00;
localparam state1 = 2'b01;
localparam state2 = 2'b10;
reg [2:0] current_state;

/**** application register interface ****/
// *** audio_control isn't doing anything, it's just here in case a 2nd register is needed in future ***
reg wb_ack_ff;
reg [31:0] audio_select;
reg [31:0] audio_control;

// get register values from RISC-V core
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if (wb_rst_i) begin
        audio_select <= 32'h0;
        audio_control <= 32'h0;
        wb_ack_ff <= 0;
    end
    else begin
        case (wb_adr_i[5:2])
            0: begin 
                audio_select = wb_ack_ff && wb_we_i ? wb_dat_i : audio_select;
            end
            1: begin
                audio_control = wb_ack_ff && wb_we_i ? wb_dat_i : audio_control;
            end
            default: begin
                wb_ack_ff <= 0;
            end
        endcase
        wb_ack_ff <= !wb_ack_ff && wb_stb_i && wb_cyc_i;
    end
end

// drive wishbone bus 
assign wb_ack_o = wb_ack_ff;
assign wb_dat_o = (wb_adr_i[5:2] == 0) ? audio_select : audio_control;



/* Playing the selected audio file
 *
 * 0 = initial
 * 1 = theme
 * 2 = menu_sound        
 * 3 = level_up          
 * 4 = game_over         
 * 5 = line_clear        
 * 6 = line_clear_four   
 * 7 = line_clear_falling
 * 8 = piece_landed      
 * 9 = piece_rotate      
 * 10= piece_move  
 *
 * lock is used to stop short tones from repeating      
*/
always @(posedge wb_clk_i) begin
    // switch-case so future audio can be added
    case (audio_select)
    0: begin
        aud_en <= 0;
        prescaler <= 0;
        address <= 0;
        address_theme <= 0;
        counter <= 0;
        current_state <= state0;
        lock <= 0;
    end
    1: begin
        lock <= 0;
        prescaler <= prescaler + 1;
        aud_en <= 0;
        if (prescaler == PRESCALER_MAX) begin // Divides the clock
            prescaler <= 0;
            if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                counter <= 0;
                aud_en <= 1;
                if (current_state == state0) begin // Play the sound file 
                    value <= theme1[address_theme];
                    address_theme <= address_theme + 1;
                    if (address_theme == MEM_SIZE_THEME1) begin
                        address_theme <= 0;
                        current_state <= state1;
                    end
                end else if (current_state == state1) begin
                    value <= theme1[address_theme];
                    address_theme <= address_theme + 1;
                    if (address_theme == MEM_SIZE_THEME1) begin
                        address_theme <= 0;
                        current_state <= state2;
                    end
                end else if (current_state == state2) begin
                    value <= theme2[address_theme];
                    address_theme <= address_theme + 1;
                    if (address_theme == MEM_SIZE_THEME2) begin
                        address_theme <= 0;
                        current_state <= state0;
                    end
                end else begin
                    current_state <= state0;
                end
            end else begin
                counter <= counter + 1;
            end
        end
    end
    2: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= menu_sound[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_MENU_SOUND) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    3: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= level_up[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_LEVEL_UP) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    4: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= game_over[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_GAME_OVER) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    5: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= line_clear[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_LINE_CLEAR) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    6: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= line_clear_four[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_LINE_CLEAR_FOUR) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    7: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= line_clear_falling[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_LINE_CLEAR_FALLING) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    8: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= piece_landed[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_PIECE_LANDED) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    9: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= piece_rotate[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_PIECE_LANDED) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    10: begin
        if (lock == 0) begin
            prescaler <= prescaler + 1;
            aud_en <= 0;
            if (prescaler == PRESCALER_MAX) begin // Divides the clock
                prescaler <= 0;
                if (counter == COUNTER_MAX) begin // The PWM of aud_file[address]
                    counter <= 0;
                    aud_en <= 1;
                    value <= piece_move[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_PIECE_MOVE) begin
                        address <= 0;
                        lock <= 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
    default: begin
        aud_en <= 0;
    end
    endcase
end

// When value is greater than or equal to the counter, aud_pwm is high, else low
assign aud_pwm = (value >= counter);

endmodule