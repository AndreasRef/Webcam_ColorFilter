//TO DO
//(Send værdierne i omvendt rækkefølge)
//Blur + smooth grafik
//Flere farver
//Classificer flere forskellige mønstre


import processing.video.*;
import controlP5.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress dest;

ControlP5 cp5;

Capture cam;

float minSat = 100;
float minBri = 170;
float hueRange = 5;

boolean orignalVideo = true;

float selectedHue = 10;

int currentX = 0;

void setup() {
  size(640, 360);
  
    /* start oscP5, listening for incoming messages at port 9000 */
  oscP5 = new OscP5(this,9000);
  //dest = new NetAddress("127.0.0.1",6448);
  dest = new NetAddress("192.168.43.62",6448);
  
  cp5 = new ControlP5(this);
  cp5.addSlider("minSat",0,255).linebreak();
  cp5.addSlider("minBri",0,255).linebreak();
  cp5.addSlider("hueRange",0,100).linebreak();
  cp5.addToggle("orignalVideo");

  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, 640, 360);
  } if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);
    cam = new Capture(this, cameras[0]);
    cam.start();
  }
  colorMode(HSB);
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  
  
  pushMatrix();
  
     scale(-1, 1);
    image(cam, - (width), 0,  width, height);
      //image(cam, 0, 0, width, height);
      loadPixels(); 
      popMatrix();
  
  //image(cam, 0, 0, width, height);
  
  //loadPixels(); 
   
   
   OscMessage msg = new OscMessage("/test");
   
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int loc = x + y*width;
      
      // The functions red(), green(), and blue() pull out the 3 color components from a pixel.
      float h = hue(get(x,y));
      float s = saturation(get(x,y));
      float b = brightness(get(x,y));
      
      //if ((h<5 || h>250) && s > minSat && b > minBri) {
      if ((h<(selectedHue+hueRange) && h>(selectedHue-hueRange)) && s > minSat && b > minBri) {
        pixels[loc] =  color(h,s,b);   
        if (x==currentX) {
          msg.add((float)1);
          
          msg.add(map(s+b, 0, 255+255,0,1));
        }
      } else {
        pixels[loc] =  color(0);
        if (x==currentX) {
          msg.add((float)0);
        }
      }
    }
  }
  
  oscP5.send(msg, dest);
  println(msg);
  
  updatePixels();
  if (orignalVideo) {
    pushMatrix();
    scale(-1, 1);
    image(cam, - (width), 0,  width, height);
      //image(cam, 0, 0, width, height);
      
      popMatrix();
  }
  
  fill(selectedHue, 255, 255);
  rect(3,3,12,12);
  
   stroke(0);
   line( 150,0,150,120);
   
   line( 0, 120,150,120);
  
  
  stroke(255);
  line(currentX,0,currentX, height);
  currentX+=1;
  
  if (currentX>width) currentX = 0;
}

void mousePressed() {
  if (mouseX>150&& mouseY >120)  
  selectedHue = (int)hue(get(mouseX, mouseY));
}