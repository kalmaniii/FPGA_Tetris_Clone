# **Playing audio with RAM**

These audio files are uploaded into the board's memory using $readmemh. 
For Vivado to find these files, user must go under "add sources" and add these '.mem' files to the project. 

To create your own audio file:

    1) Use an audio editor to convert .wav files into 8bit unsigned .raw files.
    2) Run the python script "raw2hex.py" to convert .raw file into formatted .mem file.