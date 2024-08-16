from PIL import Image
import numpy as np
import argparse
import logging

DEFAULT_IMG_DIR_I = 'input_img/'
DEFAULT_IMG_DIR_O = 'output_img/'
DEFAULT_IMG_INPUT = 'Tetris_Board_Color'
DEFAULT_IMG_OUTPUT = 'new_img'

def get_args():
    parser = argparse.ArgumentParser(
        description='convert img to vga array',
        prog='img to pixel'
    )

    parser.add_argument(
        '-i','--img_name_input',
        type=str,
        default=DEFAULT_IMG_INPUT,
        help='name of input img: input'
    )
    parser.add_argument(
        '-o','--img_name_output',
        type=str,
        default=DEFAULT_IMG_OUTPUT,
        help='name of result img: result'
    )  
    parser.add_argument(
        '-p', '--path',
        type=str,
        default=DEFAULT_IMG_DIR_I,
        help='location of img: path/to/img/outer_dir/'
    )
    parser.add_argument(
        '-d', '--debug',
        type=bool,
        default=False,
        help='prints rgb values of input and output img'
    )

    result = parser.parse_args()
    return result.img_name_input, result.img_name_output, result.path, result.debug

def config_log():
    # create logger
    logger = logging.getLogger('debug')
    logger.setLevel(logging.DEBUG)

    # create handler
    fh = logging.FileHandler(
        logger.name + '.log', 
        mode='w'
    )
    fh.setLevel(logging.DEBUG)

    # create formatter
    formatter = logging.Formatter('%(name)s - %(levelname)s - %(message)s')

    # add formatter to ch
    fh.setFormatter(formatter)

    # add ch to logger
    logger.addHandler(fh)

    return logger

def main():
    input_name, output_name, path, debug = get_args()
    log = config_log()

    img = Image.open(path+input_name+'.png')

    new_img_24_bit = img.resize((160,144), Image.NEAREST)
    new_img_24_bit.save(DEFAULT_IMG_DIR_O+output_name+'_24_bit.png')

    width, height = new_img_24_bit.size

    pix_array = new_img_24_bit.load()

    # next
    for i in range(24, 24 + 32):
        for j in range(120, 120 + 32):
            pix_array[j, i] = (0x0, 0x0, 0x0)
    
    # score
    for i in range(80, 80 + 8):
        for j in range(112, 112 + 48):
            pix_array[j, i] = (0x0, 0x0, 0x0)

    # level
    for i in range(104, 104 + 8):
        for j in range(112, 112 + 48):
            pix_array[j, i] = (0x0, 0x0, 0x0)

    # lines
    for i in range(128, 128 + 8):
        for j in range(112, 112 + 48):
            pix_array[j, i] = (0x0, 0x0, 0x0)

    new_pixel = np.zeros((height, width, 3), dtype=np.uint8)

    with open('array_in_C.txt', 'w') as file:
        string = ''
        string += f'unsigned short int img[{height}][{width}] = {{\n'

        debug_str = string

        for row in range(0, height):
            string += '\t{'
            for col in range(0, width):
                r, g, b = pix_array[col, row]
                r //= 16; g //= 16; b //= 16; 
                new_pixel[row, col] = (r, g, b)

                debug_str += f'({r},{g},{b}), '  # decimal 
                hex_value = (r << 8) + (g << 4) + b
                string += f'{hex(hex_value)}, '

            string = string[:-2] + '}, \n'
            debug_str = debug_str[:-2] + '}, \n'

        string = string[:-3] + '\n};'
        debug_str = debug_str[:-3] + '\n};'

        file.write(string)
        if (debug):
            log.debug(debug_str)     

    new_img_12_bit = Image.fromarray(np.uint8(new_pixel)).convert('RGB')
    new_img_12_bit.save(DEFAULT_IMG_DIR_O+output_name+'_12_bit.png')


if __name__ == '__main__':
    main()