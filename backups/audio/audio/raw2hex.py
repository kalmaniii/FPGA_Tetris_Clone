## raw2hex.py 
## Used to convert ".raw" files into a formatted ".mem" file for the FPGA to read
## Each line is a byte in hexidecimal form
## Taken from https://github.com/simonmonk/prog_fpgas/blob/master/utilities/audio/raw2hex.py

import sys

if len(sys.argv) < 3:
    print("Usage: input_file.raw output_file.mem")
    sys.exit()
    
input_file = sys.argv[1]
output_file = sys.argv[2]

with open(input_file, 'rb') as f:
    bytes = f.read()
    
print("Read (bytes)" + str(len(bytes)))

with open(output_file, 'w') as f:
    for b in bytes:
        f.write(hex(b)[2:])
        f.write("\n")