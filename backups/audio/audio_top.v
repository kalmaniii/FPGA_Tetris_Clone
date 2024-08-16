/*
@file: audio_top.v
@author: The power rangers
@date: 3/4/24
@version: 1

@brief:
it should play audio, probably won't
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

/**** application register interface ****/
// *** audio_control isn't doing anything, it's just here in case a 2nd register is needed. ***
reg wb_ack_ff;
reg [31:0] sound_select;
reg [31:0] audio_control;

// get register values from RISC-V core
always @(posedge wb_clk_i, posedge wb_rst_i) begin
    if (wb_rst_i) begin
        sound_select <= 32'h0;
        audio_control <= 32'h0;
        wb_ack_ff <= 0;
    end
    else begin
        case (wb_adr_i[5:2])
            0: 
            begin 
                sound_select = wb_ack_ff && wb_we_i ? wb_dat_i : sound_select;
            end
            1: 
            begin
                audio_control = wb_ack_ff && wb_we_i ? wb_dat_i : audio_control;
            end
            default:
            begin
                wb_ack_ff <= 0;
            end
        endcase
        wb_ack_ff <= !wb_ack_ff && wb_stb_i && wb_cyc_i;
    end
end

// drive wishbone bus 
assign wb_ack_o = wb_ack_ff;
assign wb_dat_o = (wb_adr_i[5:2] == 0) ? sound_select : audio_control;

/**** audio play ****/
// Storing audio files from memory into RAM
// Theme song is split into two parts to save RAM. This is possible because ThemePart1 is repeated in the music.
localparam MEM_SIZE_THEME1 = 102956;
localparam MEM_SIZE_THEME2 = 102884;
(* ram_style = "block" *) reg [7:0] theme1[MEM_SIZE_THEME1-1:0]; 
(* ram_style = "block" *) reg [7:0] theme2[MEM_SIZE_THEME2-1:0];

initial begin
    $readmemh("theme8000PART1.mem", theme1);
    $readmemh("theme8000PART2.mem", theme2);
end

// prescale and PWM variables
localparam PRESCALER_MAX = 2; // Up to 64; NOTE: when clk = 50MHz, any prescale value above 2 gives a whine
localparam COUNTER_MAX = 255; // Up to 256
reg [19:0] address;
reg [5:0] prescaler;
reg [7:0] counter;
reg [7:0] value;

localparam state0 = 2'b00;
localparam state1 = 2'b01;
localparam state2 = 2'b10;
reg [2:0] current_state;

// Playing the Tetris theme song (Korobeiniki)
always @(posedge wb_clk_i) begin
    // switch-case so future audio can be added
    case (sound_select)
    0: begin
        aud_en <= 0;
        prescaler <= 0;
        address <= 0;
        counter <= 0;
        current_state <= state0;
    end
    1: begin
        prescaler <= prescaler + 1;
        aud_en <= 0;
        if (prescaler == PRESCALER_MAX) begin // Divides the clock
            prescaler <= 0;
            if (counter == COUNTER_MAX) begin // The PWM of aud_file[address], every 256 counter aud_en = 1
                counter <= 0;
                aud_en <= 1;
                if (current_state == state0) begin           // Play theme1 or theme2 depending on state; go to next state when 
                    value <= theme1[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_THEME1) begin
                        address <= 0;
                        current_state <= state1;
                    end
                end else if (current_state == state1) begin
                    value <= theme1[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_THEME1) begin
                        address <= 0;
                        current_state <= state2;
                    end
                end else if (current_state == state2) begin
                    value <= theme2[address];
                    address <= address + 1;
                    if (address == MEM_SIZE_THEME2) begin
                        address <= 0;
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
    default: begin
        aud_en <= 0;
    end
    endcase
end
assign aud_pwm = (value >= counter);

endmodule