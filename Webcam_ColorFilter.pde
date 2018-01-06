//TO DO
//(Send værdierne i omvendt rækkefølge)
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
int blur = 0;
boolean orignalVideo = true;
int[] selectedHue = {0, 75, 150};
int currentColor = 0;
int currentX = 0;
PGraphics filterColorImg;

void setup() {
  size(640, 360);

  /* start oscP5, listening for incoming messages at port 9000 */
  oscP5 = new OscP5(this, 9000);
  //dest = new NetAddress("127.0.0.1",6448);
  dest = new NetAddress("192.168.43.62", 6448);

  cp5 = new ControlP5(this);
  cp5.addSlider("currentColor", 0, 2).setNumberOfTickMarks(3).linebreak();
  cp5.addSlider("minSat", 0, 255).linebreak();
  cp5.addSlider("minBri", 0, 255).linebreak();
  cp5.addSlider("hueRange", 0, 100).linebreak();
  cp5.addSlider("blur", 0, 30).linebreak();
  cp5.addToggle("orignalVideo");

  String[] cameras = Capture.list();
  cam = new Capture(this, cameras[0]);
  cam.start();
  filterColorImg = createGraphics(width, height);
  colorMode(HSB);
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  fastblur(cam, blur); //Apply fastblur

  pushMatrix();
  scale(-1, 1);
  image(cam, - (width), 0, width, height);
  loadPixels(); 
  popMatrix();

  filterColorImg.beginDraw();
  filterColorImg.background(0);
  OscMessage msg = new OscMessage("/test");

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int loc = x + y*width;
      float h = hue(get(x, y));
      float s = saturation(get(x, y));
      float b = brightness(get(x, y));

      for (int i = 0; i<3; i++) {
        if ((h<(selectedHue[i]+hueRange) && h>(selectedHue[i]-hueRange)) && s > minSat && b > minBri) {
          pixels[loc] =  color(h, s, b);
          filterColorImg.set(x,y,color(h, s, b));
          if (x==currentX) {
            msg.add((float)1);

            msg.add(map(s+b, 0, 255+255, 0, 1));
          }
        } else {
          pixels[loc] =  color(0);
          if (x==currentX) {
            msg.add((float)0);
          }
        }
      }
    }
  }
  filterColorImg.endDraw();

  //oscP5.send(msg, dest);
  //println(msg);

  //updatePixels();
  if (orignalVideo) {
    pushMatrix();
    scale(-1, 1);
    image(cam, - (width), 0, width, height);
    popMatrix();
  } else {
   image(filterColorImg, 0, 0);
  }

  drawUI();
  drawTimer();
  currentX+=1;

  if (currentX>width) currentX = 0;
}

void mousePressed() {
  if (mouseX>180 || mouseY >180)  
    selectedHue[currentColor] = (int)hue(get(mouseX, mouseY));
}

void drawUI() {
  int h = 180;
  int w = 180;
  for (int i = 0; i<selectedHue.length; i++) {
    fill(selectedHue[i], 255, 255);
    if (currentColor == i) {
      stroke(255);
    } else {
      noStroke();
    } 
    rect(5 + i * 17, 5, 13, 13);
  }
  stroke(0);
  line(w, 0, w, h);
  line( 0, h, w, h);
}

void drawTimer() {
  stroke(255);
  line(currentX, 0, currentX, height);
}




// ==================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================
void fastblur(PImage img, int radius)
{
  if (radius<1) {
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
  int vmin[] = new int[max(w, h)];
  int vmax[] = new int[max(w, h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0; i<256*div; i++) {
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0; y<h; y++) {
    rsum=gsum=bsum=0;
    for (i=-radius; i<=radius; i++) {
      p=pix[yi+min(wm, max(i, 0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0; x<w; x++) {

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if (y==0) {
        vmin[x]=min(x+radius+1, wm);
        vmax[x]=max(x-radius, 0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0; x<w; x++) {
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for (i=-radius; i<=radius; i++) {
      yi=max(0, yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0; y<h; y++) {
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if (x==0) {
        vmin[y]=min(y+radius+1, hm)*w;
        vmax[y]=max(y-radius, 0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }
}