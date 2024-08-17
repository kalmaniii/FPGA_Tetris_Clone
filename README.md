# ECE540 Final Project: FPGA Tetris Clone
Team Members: Moe Hasan, Gene Hu, Eduardo Simancas

## Project Overview
### Description
The objective of this project is to enhance the open-source [VeerWolf softcore RISC-V CPU](https://github.com/chipsalliance/VeeRwolf) by developing peripheral drivers and a corresponding C application for their evaluation and testing.

### Objective
* Implement an VGA Driver to provide a graphical interface.
* Implement an Keyboard driver to provide user input.
* Implement an Audio Driver to provide music.

## Getting Started
### Required Equipment
* [Nexys A7 FPGA](https://digilent.com/shop/nexys-a7-fpga-trainer-board-recommended-for-ece-curriculum/)
* VGA-to-HDMI converter
* Basic Keyboard (non-mechanical with no embedded LEDs)
* VGA monitor or HDMI monitor (both need to be larger than 800x600) 
* Vivado 2022.2
* Catapult-SDK Studio

### Compile Tetris Clone Application
* Use 'make' to compile src code found in applications directory

### Set Up
* Connect Monitor and Keyboard to FPGA
* Upload bitstream
  * Use Catapult-SDK Studio to upload the [project bitstream](final_project_bitstream/rvfpganexys.bit)
* Upload Tetris Clone executable using Catapult-SDK Studio
* Have fun

### Game Manual
This project based the game off of the Tetris DX from the gameboy color.
* The 'enter' key starts the game
* The 'w' key rotates block
* The 'a' key moves block left
* The 's' key moves block down
* The 'd' key moves block right