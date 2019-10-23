/*
 Code by lingib 
 Last update 12 Feb 2017
 
 This software uses the openCV library and Canny edge detection 
 to trace the outlines within an image.  These outlines are then 
 converted to gcode for use with an Inkscape compatible plotter 
 which assumes that the (0,0) co-ordinate is at the lower left).
 
 To run this software you first need to import the openCV 
 (open computer vision) library by clicking the following pull-down
 menu options within Processing 3: 
 "Sketch|Import Library|Add Library|Open CV for processing"
 
 Each photo requires a lower and upper threshold. A simple
 method for determining each threshold is to move the 
 "find edges" & "display edges" code from the "setup" section 
 into the "draw" section and uncomment the lines containing
 mouseX & mouseY. Move your mouse over the image window and 
 note the two readings when the outline is optimum then 
 restore the code to its original state. 
 
 This code is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as published
 by the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This software is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License. If
 not, see <http://www.gnu.org/licenses/>.
 */

import gab.opencv.*;  //openCV library
OpenCV opencv;  //instantiate opencv

PrintWriter output;  //instantiate output

PImage src, canny;  //image work areas

boolean recursionFlag;
boolean lastCommandG00 = false;

int lastX = 0;
int lastY = 0;

// -------------------------------------
// setup
// -------------------------------------
void setup() {
  // ----- match screen size to image
  size(500, 664);

  // ----- get image
  src = loadImage("image.jpg");  //get image
  loadPixels();  //load image into pixel[] array

  // ----- find edges
  opencv = new OpenCV(this, src);
  opencv.findCannyEdges(99, 122);
  //opencv.findCannyEdges(mouseX, mouseY);
  //println(mouseX);
  //println(mouseY);
  canny = opencv.getSnapshot();

  // ----- display edges
  pushMatrix();
  image(canny, 0, 0);  //white outline
  filter(INVERT);  //black outline
  popMatrix();

  // Create a new file in the sketch directory
  output = createWriter("outline.ngc"); 

  noLoop();  //draw() only runs once
}

// -------------------------------------
// main loop
// -------------------------------------
void draw() {

  // ----- refresh pixels[] array
  loadPixels();

  // ----- move 3x3 matrix center over the image
  for (int y=1; y<height-1; y++) {
    for (int x=1; x<width-1; x++) {

      // ----- trace
      recursionFlag = true;
      trace(x, y);
    }  //end x loop
  }  //end y loop

  // ----- refresh display
  updatePixels();

  // ----- close the output file
  output.println("G00 X0 Y0");  //home
  output.flush();  //writes the remaining data to the file
  output.close();  //finishes the file
  //exit();  //stop the program
}

// -------------------------------------
// trace 
// -------------------------------------
void trace(int X, int Y) {  //XY is 3x3 matrix center

  // ----- generate gcode and record visited pixels
  int value = int(brightness(pixels[X + Y*width]));
  switch (value) {
  case 0:  
    pixels[X + Y*width] = color(0, 0, 250);  //blue outline

    // ----- generate gcode
    if ((abs((X-lastX))<2) && (abs((Y-lastY))<2)) {

      // ----- next point within 1 pixel
      //       move to next point (pen down)
      print("G01 X"); 
      print(X); 
      print(" Y"); 
      print(Y); 
      print("\n");

      // -----  save output to file in inkscape format
      output.println("G01 X" + (width-X) + " Y" + Y);
      lastCommandG00 = false;
    } else {

      // ----- next point greater than 1 pixel
      //       move to next point (pen up)
      if (lastCommandG00 == true) {

        //-----plot last point (pen down)        
        print("G01 X");
        print(lastX); 
        print(" Y"); 
        print(lastY); 
        print("\n");

        // -----  save output to file in inkscape format
        output.println("G01 X" + (width-lastX) + " Y" + lastY);
      }

      // ----- move to next point (pen up)
      println("");
      print("G00 X"); 
      print(X); 
      print(" Y"); 
      print(Y); 
      print("\n");

      // -----  save output to file in inkscape format
      output.println("G00 X" + (width-X) + " Y" + Y);
      lastCommandG00 = true;
    }

    lastX = X;
    lastY = Y;

    break;
  case 255:  
    pixels[X + Y*width] = color(230);  //light gray background
    break;
  }

  // ----- recursive trace
  while (recursionFlag == true) {
    
    recursionFlag = false;  //routine will exit unless a zero is found

    // ----- scan the matrix
    for (int j = -1; j < 2; j++) {  //vert scan
      for (int i = -1; i < 2; i++) {  //hor scan

        // ----- location of the pixel being examined
        int x = X+i;
        int y = Y+j;
        x = constrain(x, 1, width-1);
        y = constrain(y, 1, height-1);

        // ----- recursive trace if zero found
        value = int(brightness(pixels[x + y*width]));
        if (value == 0) {
          recursionFlag = true;  //zero found
          trace(x, y);
        }  //end recursive trace
      }  //end hor scan
    }  //end vert scan
  }  //end while
}