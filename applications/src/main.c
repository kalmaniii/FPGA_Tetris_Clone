/**
* ECE 540 Final Project
*
* Authors:	Gene Hu, Eduardo S. Sanchez, Moe Hasan 
* Date:		2/13/2024	
*
* Brief:
* will only do A-Type mode: this is when the goal is to get the highest score. Speed increases as level increases
* will NOT do B-Type mode: this is when the board is pre-set with tetris shape and the goal is to clear 25 lines
* Scoring A-Type Mode (original gameboy tetris system):
*   soft stops: 0 point/lines passed (shape moves from free fall)
*   hard stops: 1 point/lines passed (shape moves after user presses down key)
*   single line cleared: 40  points*(level + 1) 
*   double line cleared: 100 points*(level + 1)
*   triple line cleared: 300 points*(level + 1)
*   tetris (4 lines cleared): 1200 points*(level + 1)
*   level advances for every 10 lines cleared
**/
#include <math.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/_intsup.h>  // This an the one below it is for catapult
#include <sys/_types.h>   // If not on catapult, should comment <sys/_intsup.h> and <sys/_types.h>
#include "colors.h"
#include "img.h"
#include "keyboard_keys.h"

// These are needed for VScode for something
#ifndef M_PI
    #define M_PI 3.14159265358979323846
#endif
#ifndef M_PI_2
    #define M_PI_2 1.57079632679489661923
#endif

/** registers for VGA/HW graphics **/
// RAM_REG: used to position to a pixel in the 160x144 pixel screen; bits 19:10 = row and bits 9:0 = col
#define RAM_REG 0x80001500
// RGB_REG: used to set the current pixel position to an RGB color; bits 11:8 = red, bits 7:4 = green, bits 3:0 = blue
#define RGB_REG 0x80001504 
// next_shape_REG: used to update the portion of screen displaying the incoming tetris shape; 
// write values 0-6 to chose a tetris shape; 
// 0 = I shape; 1 = J shape, 2 = L shape, 3 = O shape, 4 = Sshape, 5 = Tshape, 6 = Z shape
#define NEXT_SHAPE_REG 0x80001508
// SCORE_REG: used to update the number value in the 'score' section of the screen
// IMPORTANT: must use 'update_number' function to update the value on screen
// because the number needs to be formated a certain way
#define SCORE_REG 0x8000150C
// LEVEL_REG: used to update the number value in the 'level' section of the screen
// IMPORTANT: must use 'update_number' function to update the value on screen
// because the number needs to be formated a certain way
#define LEVEL_REG 0x80001510
// LINES_REG: used to update the number value in the 'lines' section of the screen
// IMPORTANT: must use 'update_number' function to update the value on screen
// because the number needs to be formated a certain way
#define LINES_REG 0x80001514

/** registers for timer ***/
// TIMER_REG: starts or stops a timer in milliseconds
// bit 31 = timer is not done bit; bit = 1 = NOT DONE; bit = 0 = DONE
// bit 30 = start timer; bit = 1 = timer started from beginning; bit = 0 = timer is running
// bit 29:0 = milisecond delay value; if value = 1 = 1 millisecond timer
#define TIMER_REG 0x80001518
#define CHECK_TIMER 0x8000151C

/** regisers for keyboard input **/
// KEYBOARD_REG: read register to get recent keyboard key that was pressed. 
// the 8 least significant bits determine the key that was pressed
// the 8 bits to key pressed mapping is found here: ECE540_FINAL_PROJECT/backups/keyboard/IMPORTANT_NOTE/IMPORTANT_NOTE.jpg
#define KEYBOARD_REG 0x80001700 

/**  registers for audio output **/
// AUDIO_REG: used to turn on or off the tetris theme
// write a 1 = turn on theme music; write a 0 = turn off music
// There are other audio files in the RTL
#define AUDIO_REG 0x80001800

/** defines for screen constant **/
#define SCREEN_WIDTH  160 // the entire screen is 160 pixels wide
#define SCREEN_HEIGHT 144 // the entire screen is 144 pixels tall

/** tetris game screen **/
// game screen is 10 blocks wide and 18 blocks tall
// each block is 8x8 pixels
#define GAME_SCREEN_ROW_MIN 0   // vertial dir: game screen starts at pixel 0
#define GAME_SCREEN_ROW_MAX 144 // vertial dir: game screen stops at pixel 144
#define GAME_SCREEN_COL_MIN 16  // horizontal dir: game screen starts at pixel 16; this is because the first 16 pixels are used for background
#define GAME_SCREEN_COL_MAX 96  // horizontal dir: game screen ends at pixel 96; screen is 10 blocks wide (1 block = 8x8 pixel; 8pixels*10blocks + 16pixels for background = 96 pixels)

/** mask values **/
#define RGB_COLOR_MASK       0x00000FFF // lower 16 bits are used to write to the RGB register
#define ROW_POSITION_MASK    0x000FFC00 // bits 19:10 are used to set the row position on screen
#define COL_POSITION_MASK    0x000003FF // bits 9:0 are used to set the col position on screen
#define KEY_PRESSED_MASK     0x000000FF // lower 8 bits determine which key was pressed
#define DONE_BIT_TIMER_MASK  0x80000000
#define STOP_BIT_TIMER_MASK  0xC0000000
#define START_BIT_TIMER_MASK 0x40000000

/** game board boundaries **/
#define GAME_BOARD_X_MIN 0
#define GAME_BOARD_X_MAX 10
#define GAME_BOARD_Y_MIN 0
#define GAME_BOARD_Y_MAX 18
#define PIXEL_WILL_BE_FREED 99    // used in collision functions, space in game_board will be unoccupied after a move/rotate
#define PIXEL_OCCUPIED 1

/** other **/
#define ROW_POSITION 10 // the row pits are 10 bits to the left; use this to shift left 10
#define NUM_OF_TETRIS_SHAPES 7  // total numbers of tetris shapes 
#define BLOCKS_PER_SHAPE 4
#define BLOCK_DIMENSION 8 // 8x8 block
#define PI_HALF M_PI_2
#define DELAY_INTERVAL 700000 // 10_000 milliseconds (10 seconds)
#define MSB 0x80000000
#define INPUT_DELAY 100000
#define TIMEOUT_DELAY 90000
#define MUSIC_MAIN_THEME 1
#define MUSIC_GAME_OVER 4



#define DEBUG 0
/** enums, struct, others **/
typedef struct tetris_shape_obj tetris_shape_obj_t;
typedef void (*method) (tetris_shape_obj_t *); 

typedef enum tetris_shapes {
    i_shape,
    j_shape,
    l_shape,
    o_shape,
    s_shape,
    t_shape,
    z_shape
} tetris_shapes_t;

typedef enum move_dir {
    left,
    right,
    down
} move_dir_t;

typedef struct vertex {
    unsigned short int x;
    unsigned short int y;
} vertex_t;

typedef struct tetris_shape_obj {
    tetris_shapes_t shape;
    vertex_t blocks[BLOCKS_PER_SHAPE]; // 4 blocks for each shape; always top left point of each block
    vertex_t pivot_point;
    bool is_not_locked;
    unsigned int lines_moved;
    method get_vertices;
    method rotate;
    method *move;
} tetris_shape_obj_t;

typedef struct virtual_board {
    unsigned int occupied;
    unsigned int color; 
} virtual_board_t;

virtual_board_t game_board[GAME_BOARD_Y_MAX][GAME_BOARD_X_MAX] = {0};

/** function declarations **/
#define READ_GPIO(dir) (*(volatile unsigned *)dir)
#define WRITE_GPIO(dir, value) { (*(volatile unsigned *)dir) = (value); }
void delay(unsigned int milliseconds);
void main_menu_gui();
void draw_tetris_game_background();
void update_number(int reg, unsigned int number);
void draw_block(int virtual_row, int virtual_col, int color);
void spawn_block(tetris_shape_obj_t *tetris_obj);
void clear_screen_play();
unsigned short int get_new_shape();
bool collision_movement(int movement_direction, tetris_shape_obj_t *current_shape);
bool collision_rotation(unsigned int rotation_x[BLOCKS_PER_SHAPE], unsigned int rotation_y[BLOCKS_PER_SHAPE], tetris_shape_obj_t *current_shape);
void line_clear(unsigned int *lines);
void stop_drawing();
void update_game_speed(unsigned int *input_delay, unsigned int *timeout_delay, unsigned int level);

// functions for tetris objects
void init_tetris_obj(tetris_shape_obj_t *current_shape, tetris_shapes_t shape);

// initialize vertices for tetris shapes
void shape_vertices(tetris_shape_obj_t *current_shape);

// rotate functions for tetris shapes
void rotate_shape(tetris_shape_obj_t *current_shape);

// move functions for tetris shapes
void move_left (tetris_shape_obj_t *current_shape);
void move_right(tetris_shape_obj_t *current_shape);
void move_down (tetris_shape_obj_t *current_shape);

/** hash tables **/
void (*move_functions[3]) (tetris_shape_obj_t *) = {
    move_left, 
    move_right, 
    move_down
};

int shape_color[NUM_OF_TETRIS_SHAPES] = {
    I_SHAPE_COLOR,
    J_SHAPE_COLOR,
    L_SHAPE_COLOR,
    O_SHAPE_COLOR,
    S_SHAPE_COLOR,
    T_SHAPE_COLOR,
    Z_SHAPE_COLOR
};

int main (void) {
    
    while (true) {
        unsigned int screen_position = 0;
        unsigned int rgb_color = 0;
        unsigned int new_shape = 0;
        unsigned int next_shape = 0;
        unsigned int score = 0;
        unsigned int level = 0;
        unsigned int lines = 0;
        unsigned int input_delay = INPUT_DELAY;
        unsigned int timeout_delay = TIMEOUT_DELAY;
        unsigned int current_time = 0;
        int key_pressed = 0;
        int key_released = 0;
        bool playing_game = true;
        bool moved_down = false;
        tetris_shape_obj_t current_shape;
        unsigned int seed = rand();

        srand(seed);
        main_menu_gui();
        draw_tetris_game_background();
        clear_screen_play();

        // initialize score, level, line values
        update_number(LINES_REG, lines);
        update_number(LEVEL_REG, level);
        update_number(SCORE_REG, score);

        // get new shape
        new_shape = get_new_shape();
        init_tetris_obj(&current_shape, new_shape);

        // update incoming shape
        next_shape = get_new_shape();
        WRITE_GPIO(NEXT_SHAPE_REG, next_shape);
        stop_drawing();
        
        // start music    
        WRITE_GPIO(AUDIO_REG, MUSIC_MAIN_THEME);

        while (playing_game) {
            while (current_shape.is_not_locked) {
                current_time = 0;

                // while timer is not done
                while (current_time != timeout_delay) {
                    key_released = READ_GPIO(KEYBOARD_REG) & KEY_RELEASE_MASK;

                    if (key_released != RELEASE_KEY) {
                        delay(1000);
                        key_pressed = READ_GPIO(KEYBOARD_REG) & KEY_PRESSED_MASK;
                    
                        switch (key_pressed) {
                            // rotate
                            case W_KEY:
                                current_shape.rotate(&current_shape);
                                break;
                            
                            // left
                            case A_KEY:
                                current_shape.move[left](&current_shape);
                                break;
                            
                            // down
                            case S_KEY:
                                current_shape.move[down](&current_shape);
                                score += 1;
                                moved_down = true;
                                break;
                            
                            // right
                            case D_KEY:
                                current_shape.move[right](&current_shape);
                                break;
                        }

                        delay(input_delay);
                    }

                    current_time++;
                }

                // if player does not move down before time out then move them down
                if (!moved_down) {
                    current_shape.move[down](&current_shape);
                } else {
                    moved_down = false;
                }

                // update level and lines on screen
                level = lines / 10;
                update_number(LEVEL_REG, level);
                update_number(SCORE_REG, score);
            }

            // if new shape spawns and it collides with another shape then its Game Over.
            if(!current_shape.is_not_locked && current_shape.lines_moved == 0) {
                playing_game = false;
            }
            
            // update line
            line_clear(&lines);
            update_number(LINES_REG, lines);

            // update new shape
            new_shape = next_shape;
            init_tetris_obj(&current_shape, new_shape);

            // update incoming shape
            next_shape = get_new_shape();
            WRITE_GPIO(NEXT_SHAPE_REG, next_shape);

            // update speed
            update_game_speed(&input_delay, &timeout_delay, level);
        }

        // game over music
        WRITE_GPIO(AUDIO_REG, MUSIC_GAME_OVER);
        delay(DELAY_INTERVAL);
    }

    return 0;
}


/**
 * @brief used to delay
 * 
 * @param length 
 */
void delay(unsigned int milliseconds) {
    while (milliseconds > 0) {
        milliseconds--;
    }
}


/**
 * @brief draws main menu and waits until user hits 'enter' key from keyboard before starting game
 * there is a red box on screen that acts as the curosr for game play. This cursor will blink on and off.
 * 
 */
void main_menu_gui() {
    unsigned int screen_position = 0;
    unsigned int rgb_color = 0;
    unsigned int animation_speed = 500;
    unsigned int animation_row_length = sizeof(animation_section_rows) / sizeof(animation_section_rows[0]);
    unsigned int animation_col_length = sizeof(animation_section_cols) / sizeof(animation_section_cols[0]);
    unsigned int animation_row = 0;
    unsigned int animation_col = 0;
    int key_pressed = 0;
    int key_released = 0;
    
    // main menu gui; draw entire screen only once
    for (int row = 0; row < SCREEN_HEIGHT; row++) {
        screen_position = (screen_position & COL_POSITION_MASK) + (row << ROW_POSITION);
        for (int col = 0; col < SCREEN_WIDTH; col++) {
            screen_position = (screen_position & ROW_POSITION_MASK) + col;
            rgb_color = main_menu[row][col];

            WRITE_GPIO(RAM_REG, screen_position);
            WRITE_GPIO(RGB_REG, rgb_color);
        }
    }
    delay(DELAY_INTERVAL);

    // uncomment loop if your keyboard works
    while (true) {
        key_pressed = READ_GPIO(KEYBOARD_REG) & KEY_PRESSED_MASK;
        delay(DELAY_INTERVAL);
        if (key_pressed == ENTER_KEY) {
            // bit 31 enables the RTL code to update the right side of game screen automatically
            WRITE_GPIO(RAM_REG, (1 << 31));
            return;
        }

        // DELETE GUI cursor from display
        rgb_color = WHITE;
        WRITE_GPIO(RGB_REG, rgb_color);
        
        // loop through sections of screen that will blink (GUI cursor)
        for (int i = 0; i < animation_row_length; i++) {
            animation_row = animation_section_rows[i];
            screen_position = (screen_position & COL_POSITION_MASK) + (animation_row << ROW_POSITION);
            for (int j = 0; j < animation_col_length; j++) {
                animation_col = animation_section_cols[j];
                screen_position = (screen_position & ROW_POSITION_MASK) + animation_col;

                WRITE_GPIO(RAM_REG, screen_position);
            }
        }

        key_pressed = READ_GPIO(KEYBOARD_REG) & KEY_PRESSED_MASK;
        delay(DELAY_INTERVAL);
        if (key_pressed == ENTER_KEY) {
            // bit 31 enables the RTL code to update the right side of game screen automatically
            WRITE_GPIO(RAM_REG, (1 << 31));
            return;
        }
        
        // DRAW cursor on display
        // loop through sections of screen that will blink (GUI cursor)
        for (int i = 0; i < animation_row_length; i++) {
            animation_row = animation_section_rows[i];
            screen_position = (screen_position & COL_POSITION_MASK) + (animation_row << ROW_POSITION);
            for (int j = 0; j < animation_col_length; j++) {
                animation_col = animation_section_cols[j];
                screen_position = (screen_position & ROW_POSITION_MASK) + animation_col;
                rgb_color = main_menu[animation_row][animation_col];

                WRITE_GPIO(RAM_REG, screen_position);
                WRITE_GPIO(RGB_REG, rgb_color);
            }
        }
    }

    stop_drawing();
}


/**
 * @brief draws the tetris game screen
 */
void draw_tetris_game_background() {
    unsigned int screen_position = 0;
    unsigned int rgb_color = 0;

    // draw only once
    for (int row = 0; row < SCREEN_HEIGHT; row++) {
        screen_position = (screen_position & COL_POSITION_MASK) + (row << ROW_POSITION);
        for (int col = 0; col < SCREEN_WIDTH; col++) {
            screen_position = (screen_position & ROW_POSITION_MASK) + col;
            rgb_color = tetris_game_screen[row][col];

            WRITE_GPIO(RAM_REG, screen_position | MSB);
            WRITE_GPIO(RGB_REG, rgb_color);
        }
    }

    stop_drawing();
}


/**
 * @brief used to format the given number so that the RTL hardware can update the numbers on screen correctly
 * @example input = 123; format sent to register needs to be: 0x123 thus each digit from the input is left shifted four bits
 * 
 * @param reg    either: score, level, or line register to update on screen
 * @param number the numer to display on screen
 */
void update_number(int reg, unsigned int number) {
    unsigned short digits[6] = {0};
    unsigned int new_number_format = 0;

    // get each digits from number starting at the ones digit place and ending at the 100 thousand place
    for (int i = 0; i < 6; i++) {
        digits[i] = (number / ((int) pow( (double) 10, (double) i)) ) % 10;
    }

    new_number_format = ((digits[5] << 20) + (digits[4] << 16) + (digits[3] << 12) + (digits[2] << 8) + (digits[1] << 4) + (digits[0]));
    WRITE_GPIO((volatile unsigned int *) reg, new_number_format);
}

/**
 * @brief decreases the time the player has to press a keyboard key
 * 
 * @param input_delay 
 * @param timeout_delay 
 * @param level 
 */
void update_game_speed(unsigned int *input_delay, unsigned int *timeout_delay, unsigned int level) {
    if ( (1 <= level) && (level < 2) ) {
        *input_delay = INPUT_DELAY - 1000;
        *timeout_delay = TIMEOUT_DELAY - 1000; 
    }
    else if ( (2 <= level) && (level < 4) ){
        *input_delay = INPUT_DELAY - 5000;
        *timeout_delay = TIMEOUT_DELAY - 5000; 
    }
    else if ( (4 <= level) && (level < 8) ){
        *input_delay = INPUT_DELAY - 10000;
        *timeout_delay = TIMEOUT_DELAY - 10000; 
    }
}

/**
 * @brief Get the next shape object
 * 
 * @return unsigned short int; 0-6 where 0 = i shape ... 6 = z shape
 */
unsigned short int get_new_shape() {
    unsigned short int next_shape = rand() % NUM_OF_TETRIS_SHAPES;
    return next_shape;
}

/**
 * @brief initializes the tetris shape object
 * 
 * @param current_shape i - z shape
 * @param shape         new shape to adjust object to
 */
void init_tetris_obj(tetris_shape_obj_t *current_shape, tetris_shapes_t shape) {
    current_shape->shape = shape;
    current_shape->is_not_locked = true;
    current_shape->get_vertices = shape_vertices;
    current_shape->rotate = rotate_shape;
    current_shape->move = move_functions;
    current_shape->lines_moved = 0;

    current_shape->get_vertices(current_shape);
    spawn_block(current_shape);
}   


/**
 * @brief Each shape has four blocks. This function will set the top left corner (x, y) point 
 * for each block in shape
 * 
 * @param current_shape 
 */
void shape_vertices(tetris_shape_obj_t *current_shape) {

    switch (current_shape->shape) {
        case i_shape:
            current_shape->blocks[0].y = 1*8; current_shape->blocks[0].x = 3*8;
            current_shape->blocks[1].y = 1*8; current_shape->blocks[1].x = 4*8;
            current_shape->blocks[2].y = 1*8; current_shape->blocks[2].x = 5*8;
            current_shape->blocks[3].y = 1*8; current_shape->blocks[3].x = 6*8;
            current_shape->pivot_point.x = current_shape->blocks[2].x; 
            current_shape->pivot_point.y = current_shape->blocks[2].y + 8;
            break;
        case j_shape:
            current_shape->blocks[0].y = 1*8; current_shape->blocks[0].x = 3*8;
            current_shape->blocks[1].y = 1*8; current_shape->blocks[1].x = 4*8;
            current_shape->blocks[2].y = 1*8; current_shape->blocks[2].x = 5*8;
            current_shape->blocks[3].y = 2*8; current_shape->blocks[3].x = 5*8;
            current_shape->pivot_point.x = current_shape->blocks[1].x + 4; 
            current_shape->pivot_point.y = current_shape->blocks[1].y + 4;
            break;
        case l_shape:
            current_shape->blocks[0].y = 1*8; current_shape->blocks[0].x = 3*8;
            current_shape->blocks[1].y = 1*8; current_shape->blocks[1].x = 4*8;
            current_shape->blocks[2].y = 1*8; current_shape->blocks[2].x = 5*8;
            current_shape->blocks[3].y = 2*8; current_shape->blocks[3].x = 3*8;
            current_shape->pivot_point.x = current_shape->blocks[1].x + 4; 
            current_shape->pivot_point.y = current_shape->blocks[1].y + 4;
            break;
        case o_shape:
            current_shape->blocks[0].y = 0*8; current_shape->blocks[0].x = 3*8;
            current_shape->blocks[1].y = 0*8; current_shape->blocks[1].x = 4*8;
            current_shape->blocks[2].y = 1*8; current_shape->blocks[2].x = 3*8;
            current_shape->blocks[3].y = 1*8; current_shape->blocks[3].x = 4*8;
            current_shape->pivot_point.x = current_shape->blocks[1].x; 
            current_shape->pivot_point.y = current_shape->blocks[1].y + 8;
            break;
        case s_shape:
            current_shape->blocks[0].y = 1*8; current_shape->blocks[0].x = 4*8;
            current_shape->blocks[1].y = 1*8; current_shape->blocks[1].x = 5*8;
            current_shape->blocks[2].y = 2*8; current_shape->blocks[2].x = 3*8;
            current_shape->blocks[3].y = 2*8; current_shape->blocks[3].x = 4*8;
            current_shape->pivot_point.x = current_shape->blocks[0].x + 4; 
            current_shape->pivot_point.y = current_shape->blocks[0].y + 4;
            break;
        case t_shape:
            current_shape->blocks[0].y = 1*8; current_shape->blocks[0].x = 3*8;
            current_shape->blocks[1].y = 1*8; current_shape->blocks[1].x = 4*8;
            current_shape->blocks[2].y = 1*8; current_shape->blocks[2].x = 5*8;
            current_shape->blocks[3].y = 2*8; current_shape->blocks[3].x = 4*8;
            current_shape->pivot_point.x = current_shape->blocks[1].x + 4; 
            current_shape->pivot_point.y = current_shape->blocks[1].y + 4;
            break;
        case z_shape:
            current_shape->blocks[0].y = 1*8; current_shape->blocks[0].x = 3*8;
            current_shape->blocks[1].y = 1*8; current_shape->blocks[1].x = 4*8;
            current_shape->blocks[2].y = 2*8; current_shape->blocks[2].x = 4*8;
            current_shape->blocks[3].y = 2*8; current_shape->blocks[3].x = 5*8;
            current_shape->pivot_point.x = current_shape->blocks[1].x + 4; 
            current_shape->pivot_point.y = current_shape->blocks[1].y + 4;   
            break;
    }
}


/**
 * @brief rotates all the points of the shape CLOCK-WISE by 90 degrees
 * 
 * @param current_shape 
 */
void rotate_shape(tetris_shape_obj_t *current_shape) {
    if (current_shape->shape == o_shape)
        return;

    // for storing new position
    unsigned int new_x[BLOCKS_PER_SHAPE] = {0};
    unsigned int new_y[BLOCKS_PER_SHAPE] = {0};
    int x0, y0; // for centering the current x and y around the origin
    

    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        // center points around origin; rotation only works if its centered around origin
        x0 = current_shape->blocks[i].x - current_shape->pivot_point.x;
        y0 = current_shape->blocks[i].y - current_shape->pivot_point.y;

        // calculate new point and un-center it around origin
        // new x is now at top right corner so need to subtract block width (move to top left)
        new_x[i] = (int) round(((x0 * cos(PI_HALF) - y0 * sin(PI_HALF)) + current_shape->pivot_point.x) - BLOCK_DIMENSION);
        new_y[i] = (int) round((x0 * sin(PI_HALF) + y0 * cos(PI_HALF)) + current_shape->pivot_point.y);
    }

    if (collision_rotation(new_x, new_y, current_shape)) {
        return;
    }

    // clear old posititon from physical and virtual screens
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(
            (current_shape->blocks[i].y) / BLOCK_DIMENSION, 
            (current_shape->blocks[i].x) / BLOCK_DIMENSION,
            WHITE
        );

        // clear from virtual screen
        game_board[(current_shape->blocks[i].y) / BLOCK_DIMENSION][(current_shape->blocks[i].x) / BLOCK_DIMENSION].color = WHITE;
        game_board[(current_shape->blocks[i].y) / BLOCK_DIMENSION][(current_shape->blocks[i].x) / BLOCK_DIMENSION].occupied = 0;
    }

    // update shape with position
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        current_shape->blocks[i].x = new_x[i];
        current_shape->blocks[i].y = new_y[i];
    }

    // update physcial screen and virtual screen with new position
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(
            (current_shape->blocks[i].y) / BLOCK_DIMENSION, 
            (current_shape->blocks[i].x) / BLOCK_DIMENSION,
            shape_color[current_shape->shape]
        );

        game_board[(current_shape->blocks[i].y) / BLOCK_DIMENSION][(current_shape->blocks[i].x) / BLOCK_DIMENSION].occupied = PIXEL_OCCUPIED;
        game_board[(current_shape->blocks[i].y) / BLOCK_DIMENSION][(current_shape->blocks[i].x) / BLOCK_DIMENSION].color = shape_color[current_shape->shape];
    }
}

//  move functions
/**
 * @brief moves current shape left
 * 
 * @param current_shape 
 */
void move_left(tetris_shape_obj_t *current_shape) {
    // Getting the virtual row and col for game board array
    vertex_t virtual[BLOCKS_PER_SHAPE];
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        virtual[i].y = current_shape->blocks[i].y / BLOCK_DIMENSION;
        virtual[i].x = current_shape->blocks[i].x / BLOCK_DIMENSION;
    }
    
    if (collision_movement(left, current_shape)) {
        return;
    }

    // update new info
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        // move block left
        current_shape->blocks[i].x -= BLOCK_DIMENSION;

        // clear old spot
        game_board[virtual[i].y][virtual[i].x].occupied = 0;
        game_board[virtual[i].y][virtual[i].x].color = WHITE;
    }

    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        // write new spot
        game_board[virtual[i].y][virtual[i].x - 1].occupied = PIXEL_OCCUPIED;
        game_board[virtual[i].y][virtual[i].x - 1].color = shape_color[current_shape->shape];
    }

    // update pivot point
    current_shape->pivot_point.x -= BLOCK_DIMENSION;

    // clear
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(virtual[i].y, virtual[i].x, WHITE);
    }

    // draw 
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(virtual[i].y, virtual[i].x - 1, shape_color[current_shape->shape]);
    }
}

/**
 * @brief moves current shape right 
 * 
 * @param current_shape 
 */
void move_right(tetris_shape_obj_t *current_shape) {
    // Getting the virtual row and col
    vertex_t virtual[BLOCKS_PER_SHAPE];
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        virtual[i].y = current_shape->blocks[i].y / BLOCK_DIMENSION;
        virtual[i].x = current_shape->blocks[i].x / BLOCK_DIMENSION;
    }

    if (collision_movement(right, current_shape)) {
        return;
    }

    // update new info
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        current_shape->blocks[i].x += BLOCK_DIMENSION;
        // clear old spot
        game_board[virtual[i].y][virtual[i].x].occupied = 0;
        game_board[virtual[i].y][virtual[i].x].color = WHITE;
    }
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        // write new spot
        game_board[virtual[i].y][virtual[i].x + 1].occupied = PIXEL_OCCUPIED;
        game_board[virtual[i].y][virtual[i].x + 1].color = shape_color[current_shape->shape];
    }

    // update pivot point
    current_shape->pivot_point.x += BLOCK_DIMENSION;

    // clear old position physcial screen
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(virtual[i].y, virtual[i].x, WHITE);
    }

    // draw new position physical screen
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(virtual[i].y, virtual[i].x + 1, shape_color[current_shape->shape]);
    }
}

/**
 * @brief moves current shape down
 * 
 * @param current_shape 
 */
void move_down(tetris_shape_obj_t *current_shape) {
    // Getting the virtual row and col
    vertex_t virtual[BLOCKS_PER_SHAPE];
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        virtual[i].y = current_shape->blocks[i].y / BLOCK_DIMENSION;
        virtual[i].x = current_shape->blocks[i].x / BLOCK_DIMENSION;
    }
    
    if (collision_movement(down, current_shape)) {
        // lock in place
        current_shape->is_not_locked = false;
        return;
    }

    current_shape->lines_moved++;

    // update new info
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        current_shape->blocks[i].y += BLOCK_DIMENSION;
        // clear old spot
        game_board[virtual[i].y][virtual[i].x].occupied = 0;
        game_board[virtual[i].y][virtual[i].x].color = WHITE;
    }
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        // wire new spot
        game_board[virtual[i].y + 1][virtual[i].x].occupied = PIXEL_OCCUPIED;
        game_board[virtual[i].y + 1][virtual[i].x].color = shape_color[current_shape->shape];
    }

    // update pivot point
    current_shape->pivot_point.y += BLOCK_DIMENSION;

    // clear old position on physical screen
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(virtual[i].y, virtual[i].x, WHITE);
    }

    // draw new position on physical screen
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        draw_block(virtual[i].y + 1, virtual[i].x, shape_color[current_shape->shape]);
    }
}

/**
 * @brief draws the block at the initial position
 * 
 * @param tetris_obj 
 */
void spawn_block(tetris_shape_obj_t *tetris_obj) {
    // unsigned short int game_board[18][10] = {0};
    // 18 rows and 10 column
    if (tetris_obj->shape == i_shape) {
        //i_shape
        game_board[1][3].occupied = PIXEL_OCCUPIED; game_board[1][3].color = I_SHAPE_COLOR;
        game_board[1][4].occupied = PIXEL_OCCUPIED; game_board[1][4].color = I_SHAPE_COLOR;
        game_board[1][5].occupied = PIXEL_OCCUPIED; game_board[1][5].color = I_SHAPE_COLOR;
        game_board[1][6].occupied = PIXEL_OCCUPIED; game_board[1][6].color = I_SHAPE_COLOR;
        
        draw_block(1,3,I_SHAPE_COLOR);
        draw_block(1,4,I_SHAPE_COLOR);
        draw_block(1,5,I_SHAPE_COLOR);
        draw_block(1,6,I_SHAPE_COLOR);
        
    }
    else if (tetris_obj->shape == j_shape) {
        //j_shape
        game_board[1][3].occupied = PIXEL_OCCUPIED; game_board[1][3].color = J_SHAPE_COLOR;
        game_board[1][4].occupied = PIXEL_OCCUPIED; game_board[1][4].color = J_SHAPE_COLOR;
        game_board[1][5].occupied = PIXEL_OCCUPIED; game_board[1][5].color = J_SHAPE_COLOR;
        game_board[2][5].occupied = PIXEL_OCCUPIED; game_board[2][5].color = J_SHAPE_COLOR;
        
        draw_block(1,3,J_SHAPE_COLOR);
        draw_block(1,4,J_SHAPE_COLOR);
        draw_block(1,5,J_SHAPE_COLOR);
        draw_block(2,5,J_SHAPE_COLOR);
    }
    else if (tetris_obj->shape == l_shape) {
        //l_shape
        game_board[1][3].occupied = PIXEL_OCCUPIED; game_board[1][3].color = L_SHAPE_COLOR;
        game_board[1][4].occupied = PIXEL_OCCUPIED; game_board[1][4].color = L_SHAPE_COLOR;
        game_board[1][5].occupied = PIXEL_OCCUPIED; game_board[1][5].color = L_SHAPE_COLOR;
        game_board[2][3].occupied = PIXEL_OCCUPIED; game_board[2][3].color = L_SHAPE_COLOR;
        
        draw_block(1,3,L_SHAPE_COLOR);
        draw_block(1,4,L_SHAPE_COLOR);
        draw_block(1,5,L_SHAPE_COLOR);
        draw_block(2,3,L_SHAPE_COLOR);
    }
    else if (tetris_obj->shape == o_shape) {
        //o_shape
        game_board[0][3].occupied = PIXEL_OCCUPIED; game_board[0][3].color = O_SHAPE_COLOR;
        game_board[0][4].occupied = PIXEL_OCCUPIED; game_board[0][4].color = O_SHAPE_COLOR;
        game_board[1][3].occupied = PIXEL_OCCUPIED; game_board[1][3].color = O_SHAPE_COLOR;
        game_board[1][4].occupied = PIXEL_OCCUPIED; game_board[1][4].color = O_SHAPE_COLOR;
        
        draw_block(0,3,O_SHAPE_COLOR);
        draw_block(0,4,O_SHAPE_COLOR);
        draw_block(1,3,O_SHAPE_COLOR);
        draw_block(1,4,O_SHAPE_COLOR);
    }
    else if (tetris_obj->shape == s_shape) {
        //s_shape
        game_board[1][4].occupied = PIXEL_OCCUPIED; game_board[1][4].color = S_SHAPE_COLOR;
        game_board[1][5].occupied = PIXEL_OCCUPIED; game_board[1][5].color = S_SHAPE_COLOR;
        game_board[2][3].occupied = PIXEL_OCCUPIED; game_board[2][3].color = S_SHAPE_COLOR;
        game_board[2][4].occupied = PIXEL_OCCUPIED; game_board[2][4].color = S_SHAPE_COLOR;
        
        draw_block(1,4,S_SHAPE_COLOR);
        draw_block(1,5,S_SHAPE_COLOR);
        draw_block(2,3,S_SHAPE_COLOR);
        draw_block(2,4,S_SHAPE_COLOR);
    }
    else if (tetris_obj->shape == t_shape) {
        //t_shape
        game_board[1][3].occupied = PIXEL_OCCUPIED; game_board[1][3].color = T_SHAPE_COLOR;
        game_board[1][4].occupied = PIXEL_OCCUPIED; game_board[1][4].color = T_SHAPE_COLOR;
        game_board[1][5].occupied = PIXEL_OCCUPIED; game_board[1][5].color = T_SHAPE_COLOR;
        game_board[2][4].occupied = PIXEL_OCCUPIED; game_board[2][4].color = T_SHAPE_COLOR;
        
        draw_block(1,3,T_SHAPE_COLOR);
        draw_block(1,4,T_SHAPE_COLOR);
        draw_block(1,5,T_SHAPE_COLOR);
        draw_block(2,4,T_SHAPE_COLOR);
    }
    else if (tetris_obj->shape == z_shape) {
        //z_shape
        game_board[1][3].occupied = PIXEL_OCCUPIED; game_board[1][3].color = Z_SHAPE_COLOR;
        game_board[1][4].occupied = PIXEL_OCCUPIED; game_board[1][4].color = Z_SHAPE_COLOR;
        game_board[2][4].occupied = PIXEL_OCCUPIED; game_board[2][4].color = Z_SHAPE_COLOR;
        game_board[2][5].occupied = PIXEL_OCCUPIED; game_board[2][5].color = Z_SHAPE_COLOR;
        
        draw_block(1,3,Z_SHAPE_COLOR);
        draw_block(1,4,Z_SHAPE_COLOR);
        draw_block(2,4,Z_SHAPE_COLOR);
        draw_block(2,5,Z_SHAPE_COLOR);
    }

}

/**
 * @brief moves the position register off screen so no unwanted pixel get displayed on screen. 
 * value in register persist so we need to explicitly move the register off screen.
 * 
 */
void stop_drawing() {
    int position = 0;

    // move pixel position offscreen so that vga does not write to unwanted pixel
    position = (1 << 31) + ((8*5) << ROW_POSITION) + (8*16);
    WRITE_GPIO(RAM_REG, position);
}

/** draw_block
 * @brief
 * draws an 8x8 block on the screen
 * picking the color will draw or erase(white) a tetrimino
 *
 * @param virtual_row
 * @param virtual_col
 * These are the x and y coordinates based on game_board[][] 
 * Instead of going by (8,8), (8,16), these are (1,1) and (1,2)
 * @param color
 * Color of block that is being drawn (white will erase)
 */
void draw_block(int virtual_row, int virtual_col, int color) {
    //this is used to draw the graphics for the blocks
    int position = 0;
    int actual_row = virtual_row * 8 + GAME_SCREEN_ROW_MIN;
    int actual_col = virtual_col * 8 + GAME_SCREEN_COL_MIN;
    int final_row = actual_row + 8;
    int final_col = actual_col + 8;
    WRITE_GPIO(RGB_REG, color);

    // MAKES SOLID COLOR
    for (int i = actual_row; i < final_row; i++) {
        position = (position & COL_POSITION_MASK) + (i << ROW_POSITION);
        for (int j = actual_col; j < final_col; j++) {
            position = (position & ROW_POSITION_MASK) + j;

            WRITE_GPIO(RAM_REG, position | MSB);
        }
    }

    switch (color) {
        case I_SHAPE_COLOR:
        case J_SHAPE_COLOR:
        case L_SHAPE_COLOR:
        case O_SHAPE_COLOR:
        case S_SHAPE_COLOR:
        case T_SHAPE_COLOR:
        case Z_SHAPE_COLOR:
            WRITE_GPIO(RGB_REG, BLACK);
            // top and bottom side outline
            for (int col = actual_col; col < final_col; col++) {
                // top row
                position = (actual_row << ROW_POSITION) + col;
                WRITE_GPIO(RAM_REG, position | MSB);

                // bottom row
                position = ((actual_row + (BLOCK_DIMENSION - 1)) << ROW_POSITION) + col;
                WRITE_GPIO(RAM_REG, position | MSB);
            }
            // left and right side outline
            for (int row = actual_row; row < final_row; row++) {
                // top row
                position = (row << ROW_POSITION) + actual_col;
                WRITE_GPIO(RAM_REG, position | MSB);

                // bottom row
                position = (row << ROW_POSITION) + (actual_col + (BLOCK_DIMENSION - 1));
                WRITE_GPIO(RAM_REG, position | MSB);
            }

            // draw small outline within the block
            for (int col = actual_col + 2; col < final_col - 2; col++) {
                // top row
                position = ((actual_row + 2) << ROW_POSITION) + col;
                WRITE_GPIO(RAM_REG, position | MSB);

                // bottom row
                position = ((actual_row + 5) << ROW_POSITION) + col;
                WRITE_GPIO(RAM_REG, position | MSB);
            }
            // left and right side outline
            for (int row = actual_row + 2; row < final_row - 2; row++) {
                // top row
                position = (row << ROW_POSITION) + (actual_col + 2);
                WRITE_GPIO(RAM_REG, position | MSB);

                // bottom row
                position = (row << ROW_POSITION) + (actual_col + 5);
                WRITE_GPIO(RAM_REG, position | MSB);
            }

            // make center white
            
            for (int row = actual_row + 3; row < final_row - 3; row++) {
                position = (row << ROW_POSITION) + (position & COL_POSITION_MASK);

                for (int col = actual_col + 3; col < final_col - 3; col++) {
                    position = (position & ROW_POSITION_MASK) + (col);

                    WRITE_GPIO(RAM_REG, position | MSB);
                    WRITE_GPIO(RGB_REG, WHITE);
                }
            }

            // add shade for aesthetic
            position = ((actual_row + 1) << ROW_POSITION) + (actual_col + 1);
            WRITE_GPIO(RAM_REG, position | MSB);
            position = ((actual_row + 1) << ROW_POSITION) + (actual_col + 2);
            WRITE_GPIO(RAM_REG, position | MSB);
            position = ((actual_row + 2) << ROW_POSITION) + (actual_col + 1);
            WRITE_GPIO(RAM_REG, position | MSB);
            break;
        case WHITE:
            break;
    }

    stop_drawing();
}

/**
 * @brief clears the section of the screen where the tetris blocks fall
 * 
 */
void clear_screen_play() {
    unsigned int screen_position = 0;
    WRITE_GPIO(RGB_REG, WHITE);
    
    // clear physical screen
    for (int row = GAME_SCREEN_ROW_MIN; row < SCREEN_HEIGHT; row++) {
        screen_position = (screen_position & COL_POSITION_MASK) + (row << ROW_POSITION);

        for (int col = GAME_SCREEN_COL_MIN; col < GAME_SCREEN_COL_MAX; col++) {
            screen_position = (screen_position & ROW_POSITION_MASK) + col;

            WRITE_GPIO(RAM_REG, screen_position | MSB);
            
        }
    }

    stop_drawing();

    // clear virtual board 
    for (int i = 0; i < 18; i++) {
        for (int j = 0; j < 10; j++) {
            game_board[i][j].color = 0;
            game_board[i][j].occupied = 0;
        }
    }
}


/**
 * @brief 
 * Detect if a movement in direction will cause a collision
 * 
 * @param movement_direction
 * 0 = moving left
 * 1 = moving right
 * 2 = moving down
 * @param current_shape
 * Information on current tetromino being manipulated/played
 * The current_shape->blocks[] is being extracted for this function
 */
bool collision_movement(int movement_direction, tetris_shape_obj_t *current_shape) {
    vertex_t coord[BLOCKS_PER_SHAPE]; // Stores converted x/y coordinates from current shape to game board x/y
    bool collision = false;

    // converting current_shape->blocks coordinates into game_board[][] usable coordinates
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        coord[i].x = current_shape->blocks[i].x / BLOCK_DIMENSION;
        coord[i].y = current_shape->blocks[i].y / BLOCK_DIMENSION;
        // marking gameboard to keep track of current shape
        game_board[coord[i].y][coord[i].x].occupied = PIXEL_WILL_BE_FREED;
    }

    // Checking for collision based on movement direction
    // If the block is moving into a space that is occupied or out of bounds, collision is true
    switch (movement_direction) {
        case left:
            for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
                if ((coord[i].x - 1 ) < GAME_BOARD_X_MIN) {
                    collision = true;
                    break;
                } 
                else if (game_board[coord[i].y][coord[i].x - 1].occupied == PIXEL_OCCUPIED) {
                    collision = true;
                    break;
                }
            }
            break;
        case right:
            for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
                if ((coord[i].x + 1) >= GAME_BOARD_X_MAX) {
                    collision = true;
                    break;
                } 
                else if (game_board[coord[i].y][coord[i].x + 1].occupied == PIXEL_OCCUPIED) {
                    collision = true;
                    break;
                }
            }
            break;
        case down:
            for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
                if ((coord[i].y + 1) >= GAME_BOARD_Y_MAX) {
                    collision = true;
                    break;
                } 
                else if (game_board[coord[i].y + 1][coord[i].x].occupied == PIXEL_OCCUPIED) {
                    collision = true;
                    break;
                }
            }
            break;
    }

    // unmarking gameboard changes
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        game_board[coord[i].y][coord[i].x].occupied = PIXEL_OCCUPIED;
    }

    return collision;
}

/**
 * @brief
 * Detect if a rotation will cause a collision.
 *
 * @param rotation_x
 * @param rotation_y
 * These are what the x/y coordinates will be if the rotation happens; provided by rotation function.
 * @param current_shape
 * Information on current tetromino being manipulated/played
 * The current_shape->blocks[] is being extracted for this function
 */
bool collision_rotation(unsigned int rotation_x[BLOCKS_PER_SHAPE], unsigned int rotation_y[BLOCKS_PER_SHAPE], tetris_shape_obj_t *current_shape) {
    vertex_t coord_old[BLOCKS_PER_SHAPE];
    vertex_t coord_new[BLOCKS_PER_SHAPE];
    bool collision = false;

    // converting screen coordinates into game_board[][] usable coordinates
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        coord_old[i].x = current_shape->blocks[i].x / BLOCK_DIMENSION;
        coord_old[i].y = current_shape->blocks[i].y / BLOCK_DIMENSION;
        coord_new[i].x = rotation_x[i] / BLOCK_DIMENSION;
        coord_new[i].y = rotation_y[i] / BLOCK_DIMENSION;
        // marking gameboard to keep track of current shape
        game_board[coord_old[i].y][coord_old[i].x].occupied = PIXEL_WILL_BE_FREED;
    }

    // checking if new pixel location is out of bounds or is in occupied space
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        if (
            (coord_new[i].x > (GAME_BOARD_X_MAX - 1)) || 
            (coord_new[i].x < GAME_BOARD_X_MIN)       || 
            (coord_new[i].y > (GAME_BOARD_Y_MAX - 1)) || 
            (coord_new[i].y < GAME_BOARD_Y_MIN) 
        ) {
            collision = true;
            break;
        }
        else if (game_board[coord_new[i].y][coord_new[i].x].occupied == PIXEL_OCCUPIED) {
            collision = true;
            break;
        }
    }

    // unmarking gameboard changes
    for (int i = 0; i < BLOCKS_PER_SHAPE; i++) {
        game_board[coord_old[i].y][coord_old[i].x].occupied = PIXEL_OCCUPIED;
    }

    return collision;
}

/**
 * @brief find how many lines are complete and clears them. Updates lines variable
 * 
 * @param lines 
 */
void line_clear(unsigned int *lines) {
    int lines_to_clear[4] = {99, 99, 99, 99};
    int line_count = 0;
    // find the rows that are full
    for (int row = 17; row > GAME_BOARD_Y_MIN; row--) {
        for (int col = 0; col < GAME_BOARD_X_MAX; col++) {
            if (game_board[row][col].occupied != 1) {
                break;
            }
            if ((game_board[row][col].occupied == 1) && (col == GAME_BOARD_X_MAX-1)) {
                lines_to_clear[line_count] = row;
                line_count++;
            }
        }
    }
    // leave if no lines have been cleared
    if (line_count == 0) {  
        return;
    }
    if (line_count > 4) {   
        return;
    }

    // do a little blink animation (4 times) before erasing the lines
    for (int i = 0; i < 4; i++) {
        for (int k = 0; k < line_count; k++) {
            // blink to gray
            for (int col = 0; col < GAME_BOARD_X_MAX; col++) {
                draw_block(lines_to_clear[k], col, GRAY);
            }
        }
        delay(100000);
        for (int j = 0; j < line_count; j++) {
            // blink back the block
            for (int col = 0; col < GAME_BOARD_X_MAX; col++) {
                draw_block(lines_to_clear[j], col, game_board[lines_to_clear[j]][col].color);
            }
        }
        delay(100000);
    }

    // erase the lines
    for (int i = 0; i < line_count; i++) {
        for (int col = 0; col < GAME_BOARD_X_MAX; col++) {
            draw_block(lines_to_clear[i], col, WHITE);
            // update game board
            game_board[lines_to_clear[i]][col].occupied = 0;
            game_board[lines_to_clear[i]][col].color = WHITE;
        }
    }

    // update the game board starting from the highest missing line
    for (int i = line_count-1; i >= 0; i--) {
        for (int row = lines_to_clear[i]; row > GAME_BOARD_Y_MIN; row--) {
            for (int col = 0; col < GAME_BOARD_X_MAX; col++) {
                game_board[row][col].occupied = game_board[row-1][col].occupied;
                game_board[row][col].color = game_board[row-1][col].color;
            }
        }
    }

    // draw the new game board from the BOTTOM, looks better
    for (int row = 17; row >= GAME_BOARD_Y_MIN; row--) {
        for (int col = 0; col < GAME_BOARD_X_MAX; col++) {
            if (game_board[row][col].occupied != 1) {
                draw_block(row, col, WHITE);
                continue;
            }
            draw_block(row, col, game_board[row][col].color);
        }
    }

    *lines += line_count;
}