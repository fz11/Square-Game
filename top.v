// FPGA VGA Graphics Part 1: Top Module
// (C)2017-2018 Will Green - Licensed under the MIT License
//Modified by Hugo Menendez, Fabricio Zuniga, Alonzo Ramon, Aaron Cantu on 11/29/19
// Learn more at https://timetoexplore.net/blog/arty-fpga-vga-verilog-01

`default_nettype none

module top(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire RST_BTN,         // reset button
    input wire Up,              //BTNU
    input wire Left,            //BTNL
    input wire Right,           //BTNR
    input wire Down,            //BTND
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output wire [3:0] VGA_R,    // 4-bit VGA red output
    output wire [3:0] VGA_G,    // 4-bit VGA green output
    output wire [3:0] VGA_B,     // 4-bit VGA blue output
    output reg [15:0] LED
    );
    
    wire sq_a, sq_b, sq_c, sq_enD, sq_e;
    wire [11:0] sq_enD_x1, sq_enD_x2, sq_enD_y1, sq_enD_y2;
    wire [11:0] sq_a_x1, sq_a_x2, sq_a_y1, sq_a_y2;  // 12-bit values: 0-4095 
    wire [11:0] sq_b_x1, sq_b_x2, sq_b_y1, sq_b_y2;
    wire [11:0] sq_c_x1, sq_c_x2, sq_c_y1, sq_c_y2;
    wire [11:0] sq_e_x1, sq_e_x2, sq_e_y1, sq_e_y2;
    
    
   
    wire check_1, check_2, check_3, check_4;
    assign check_1 = ((sq_c_x1 >= 590 && sq_c_x2 <= 650) && (sq_c_y1 >= 430 && sq_c_y2 <= 490)) ? 1:0;
    //assign check_2 = ( ((sq_c_x1 < 255) && (sq_c_x2 > 295)) && ((sq_c_y1 == sq_b_y2 ) || (sq_c_y2 == sq_b_y1)) ) ? 1 : 0;
//    assign check_3 = ( (125 < sq_c_x1 < 175) && (125 < sq_c_x2 < 175) && ((sq_c_y1 == sq_enD_y2 ) || (sq_c_y2 == sq_enD_y1)) ) ? 1 : 0;
//    assign check_4 = ( (375 < sq_c_x1 < 425) && (375 < sq_c_x2 < 425) && ((sq_c_y1 == sq_e_y2 ) || (sq_c_y2 == sq_e_y1)) ) ? 1 : 0;
    //assign check_2 = ((sq_c_x1 >= sq_b_x1) && (sq_c_x1 <= sq_b_x2)) || ((sq_c_y1 >= sq_b_y1) && (sq_c_y1 <= sq_b_y2));
    //wire rst = (RST_BTN || check_1 || check_2 || check_3 || check_4) ? 1 : 0;
    wire rst = (RST_BTN || check_1) ? 1 : 0;
    
    integer i;
  
    
    reg [3:0] counter = 4'd0;
    
    initial
    begin
        LED = 0;
        counter = 0;
    end
    
    always @ (*)
    begin
        if(rst)
            counter <= counter + 1;
        case(counter)
            3'd1:
                LED[0] <= 1;
            3'd2:
            begin
                LED[0] <= 1;
                LED[1] <= 1;
            end
            3'd3:
            begin
                LED[0] <= 1;
                LED[1] <= 1;
                LED[2] <= 1;
            end
            3'd4:
            begin
//                for(i = 0; i < 16; i = i + 1)
//                    LED[i] <= 1;
                LED <= 0;
                counter <= 0;
            end
//            3'd5:
//            begin
//                //for(i = 0; i < 16; i = i + 1)
//                    //LED[i] <= 0;
//                LED <= 0;    
//                counter <= 0;
//            end
            default:
                   LED = 0;
        endcase
    end
    
 
    // wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)

    wire [9:0] x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0] y;  // current pixel y position:  9-bit value: 0-511
    wire animate;  // high when we're ready to animate at end of drawing

    // generate a 25 MHz pixel strobe
    reg [15:0] cnt = 0;
    reg pix_stb = 0;
    always @(posedge CLK)
        {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000

    vga640x480 display (
        .i_clk(CLK),
        .i_pix_stb(pix_stb),
        .i_rst(rst),
        .o_hs(VGA_HS_O), 
        .o_vs(VGA_VS_O), 
        .o_x(x), 
        .o_y(y),
        .o_animate(animate)
    );

   
    

    square #(.IX(160), .IY(120), .H_SIZE(20)) sq_a_anim (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .o_x1(sq_a_x1),
        .o_x2(sq_a_x2),
        .o_y1(sq_a_y1),
        .o_y2(sq_a_y2)
    );


    square #(.IX(20), .IY(20), .H_SIZE(20)) sq_c_anim (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .o_x1(sq_c_x1),
        .o_x2(sq_c_x2),
        .o_y1(sq_c_y1),
        .o_y2(sq_c_y2),
        .Up(Up),
        .Down(Down),
        .Left(Left),
        .Right(Right)
    );
    
     enemy #(.IX_1(150), .IY_1(150), .IX_2(275), .IY_2(275), .IX_3(400), .IY_3(400), .H_SIZE(20)) sq_enD_anim (
        .i_clk(CLK),
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .o_x1_1(sq_enD_x1),
        .o_x2_1(sq_enD_x2),
        .o_y1_1(sq_enD_y1),
        .o_y2_1(sq_enD_y2),
        .o_x1_2(sq_b_x1),
        .o_x2_2(sq_b_x2),
        .o_y1_2(sq_b_y1),
        .o_y2_2(sq_b_y2),
        .o_x1_3(sq_e_x1),
        .o_x2_3(sq_e_x2),
        .o_y1_3(sq_e_y1),
        .o_y2_3(sq_e_y2)
    );
    
 


    
    assign sq_a = ((x > 600) & (y > 440 ) & (x < 640) & (y < 480)) ? 1 : 0;
    assign sq_b = ((x > sq_b_x1) & (y > sq_b_y1) &
        (x < sq_b_x2) & (y < sq_b_y2)) ? 1 : 0;
    assign sq_c = ((x > sq_c_x1) & (y > sq_c_y1) &
        (x < sq_c_x2) & (y < sq_c_y2)) ? 1 : 0;
    assign sq_e = ((x > sq_e_x1) & (y > sq_e_y1) &
        (x < sq_e_x2) & (y < sq_e_y2)) ? 1 : 0;    
    assign sq_enD = ((x > sq_enD_x1) & (y > sq_enD_y1) &
        (x < sq_enD_x2) & (y < sq_enD_y2)) ? 1 : 0;

    assign VGA_R[3] = sq_a;  // square a is red
    assign VGA_G[3] = sq_enD || sq_b || sq_e;
    assign VGA_B[3] = sq_c;  // square c is blue
   
    

endmodule





















module enemy #(
    H_SIZE=80,      // half square width (for ease of co-ordinate calculations)
    IX_1=20,         // initial horizontal position of square centre
    IY_1=20,         // initial vertical position of square centre
    IX_DIR_1=1,       // initial horizontal direction: 1 is right, 0 is left
    IY_DIR_1=1,       // initial vertical direction: 1 is down, 0 is up
    IX_2=20,         // initial horizontal position of square centre
    IY_2=20,         // initial vertical position of square centre
    IX_DIR_2=1,       // initial horizontal direction: 1 is right, 0 is left
    IY_DIR_2=1,
    IX_3=20,         // initial horizontal position of square centre
    IY_3=20,         // initial vertical position of square centre
    IX_DIR_3=1,       // initial horizontal direction: 1 is right, 0 is left
    IY_DIR_3=1,
    D_WIDTH=640,    // width of display
    D_HEIGHT=480    // height of display
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    output wire [11:0] o_x1_1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2_1,  // square right edge
    output wire [11:0] o_y1_1,  // square top edge
    output wire [11:0] o_y2_1,   // square bottom edge
    output wire [11:0] o_x1_2,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2_2,  // square right edge
    output wire [11:0] o_y1_2,  // square top edge
    output wire [11:0] o_y2_2,   // square bottom edge
    output wire [11:0] o_x1_3,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2_3,  // square right edge
    output wire [11:0] o_y1_3,  // square top edge
    output wire [11:0] o_y2_3   // square bottom edge
    );

    reg [11:0] x_1 = IX_1;   // horizontal position of square centre
    reg [11:0] y_1 = IY_1;   // vertical position of square centre
    reg x_dir_1 = IX_DIR_1;  // horizontal animation direction
    reg y_dir_1 = IY_DIR_1;  // vertical animation direction
    
    reg [11:0] x_2 = IX_2;   // horizontal position of square centre
    reg [11:0] y_2 = IY_2;   // vertical position of square centre
    reg x_dir_2 = IX_DIR_2;  // horizontal animation direction
    reg y_dir_2 = IY_DIR_2;  // vertical animation direction
    
    reg [11:0] x_3 = IX_3;   // horizontal position of square centre
    reg [11:0] y_3 = IY_3;   // vertical position of square centre
    reg x_dir_3 = IX_DIR_3;  // horizontal animation direction
    reg y_dir_3 = IY_DIR_3;  // vertical animation direction


    assign o_x1_1 = x_1 - H_SIZE;  // left: centre minus half horizontal size
    assign o_x2_1 = x_1 + H_SIZE;  // right
    assign o_y1_1 = y_1 - H_SIZE;  // top
    assign o_y2_1 = y_1 + H_SIZE;  // bottom
    
    assign o_x1_2 = x_2 - H_SIZE;  // left: centre minus half horizontal size
    assign o_x2_2 = x_2 + H_SIZE;  // right
    assign o_y1_2 = y_2 - H_SIZE;  // top
    assign o_y2_2 = y_2 + H_SIZE;  // bottom
    
    assign o_x1_3 = x_3 - H_SIZE;  // left: centre minus half horizontal size
    assign o_x2_3 = x_3 + H_SIZE;  // right
    assign o_y1_3 = y_3 - H_SIZE;  // top
    assign o_y2_3 = y_3 + H_SIZE;  // bottom


   
    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x_1 <= IX_1;
            y_1 <= IY_1;
            x_dir_1 <= IX_DIR_1;
            y_dir_1 <= IY_DIR_1;
        end
        if (i_animate && i_ani_stb)
        begin
          y_1 <= (y_dir_1) ? y_1 + 10 : y_1 - 10;  // move down if positive y_dir
            if (y_1 <= H_SIZE + 1)  // edge of square at top of screen
                y_dir_1 <= 1;  // change direction to down
            if (y_1 >= (D_HEIGHT - H_SIZE - 1))  // edge of square at bottom
                y_dir_1 <= 0;  // change direction to up              
        end
    end
    
      always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x_2 <= IX_2;
            y_2 <= IY_2;
            x_dir_2 <= IX_DIR_2;
            y_dir_2 <= IY_DIR_2;
        end
        if (i_animate && i_ani_stb)
        begin
          y_2 <= (y_dir_2) ? y_2 + 15 : y_2 - 15;  // move down if positive y_dir
            if (y_2 <= H_SIZE + 1)  // edge of square at top of screen
                y_dir_2 <= 1;  // change direction to down
            if (y_2 >= (D_HEIGHT - H_SIZE - 1))  // edge of square at bottom
                y_dir_2 <= 0;  // change direction to up              
        end
    end
   
   
         always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x_3 <= IX_3;
            y_3 <= IY_3;
            x_dir_3 <= IX_DIR_3;
            y_dir_3 <= IY_DIR_3;
        end
        if (i_animate && i_ani_stb)
        begin
          y_3 <= (y_dir_3) ? y_3 + 20 : y_3 - 20;  // move down if positive y_dir
            if (y_3 <= H_SIZE + 1)  // edge of square at top of screen
                y_dir_3 <= 1;  // change direction to down
            if (y_3 >= (D_HEIGHT - H_SIZE - 1))  // edge of square at bottom
                y_dir_3 <= 0;  // change direction to up              
        end
    end
endmodule





















//assign sq_c = ((x > 0) & (y > 0 ) & (x < 40) & (y < 40)) ? 1 : 0;
//    assign sq_a = ((x > sq_a_x1) & (y > sq_a_y1) &
//        (x < sq_a_x2) & (y < sq_a_y2)) ? 1 : 0;
//    assign sq_b = ((x > sq_b_x1) & (y > sq_b_y1) &
//        (x < sq_b_x2) & (y < sq_b_y2)) ? 1 : 0;


//reg collisionrenew;

//always @(posedge CLK)
//    begin
//        collisionrenew <= (x == 0) & (y == 500);
//     end

 

//reg colx1, colx2, coly1, coly2;

 

//always @ (posedge CLK)
//    begin
//        if(collisionrenew == 1)
//            colx1 <= 0;
//        else
//            colx1 <= 1;
//    end


//always @ (posedge CLK)
//    begin
//        if(collisionrenew == 1)
//            colx2 <= 0;
//        else
//            colx2 <= 1;
//    end


//always @ (posedge CLK)
//    begin
//        if(collisionrenew == 1)
//            coly1 <= 0;
//        else
//            coly1 <= 1;
//    end

//always @ (posedge CLK)
//    begin
//        if(collisionrenew == 1)
//            coly2 <= 0;
//        else
//            coly2 <= 1;
//    end



//wire rst = (RST_BTN ||((sq_c_x1 >= 600 && sq_c_x1 <= 640) || (sq_c_y1 >= 440 && sq_c_y1 <= 480))) ? 1 : 0; 
     //assign reset = (sq_c_x1 >= 600 || sq_c_y1 >= 440 || sq_c_x2 <= 640 || sq_c_y2 <= 480) ? 0:1;