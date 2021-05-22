# Square-Game
Final Group Project for Digital Systems Design - EE3564. This project utilizes the VGA module from the Nexys 4 DDR Artix-7 to output video of a game created using Verilog
Xilinx Vivado. Purpose of this game is for the user to control a literal colored square and using the touch button d-pad that is already embedded on the FPGA, the square
has to move to its destination, which is a colored square located at the other side of the screen. Please refer to the .mp4 for a working demo. This project was divided 
in 3 different source files. square.v takes care of creating the 'squares' that are shown in the final 
project. vga640x480.v creates the video signal used for the VGA module. These two files are instantiated/references in the top.v file, where the main code is hosted. 
