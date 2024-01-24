// ================ MOVE ==================

void save_path_select() {
  selectFolder("Select a folder to process:", "folderSelected");
  //changeFlag = true;
}

void load_video() {
  selectInput("Select a file to process:", "fileSelected");
  changeFlag = true;
}

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    bitmapPath = selection.getAbsolutePath();
    println("User selected " + bitmapPath);
    cp5.get(Textfield.class, "name").setText(bitmapPath + "\\frames");
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Not selected");
  } else {
    videoPath = selection.getAbsolutePath();
    println("Select: " + videoPath);
    video = new Movie(this, videoPath);
    number_of_frames = int(video.duration()*video.frameRate);
    cp5.getController("time_line").setMax(video.duration()*video.frameRate);
    cp5.addSlider("time_line").setCaptionLabel("TIME LINE").setPosition(65, 390).setSize(155, 25).setRange(1, number_of_frames).setValue(1).setNumberOfTickMarks(int(number_of_frames));
    cp5.getController("time_line").getCaptionLabel().setPaddingX(-55);
    video.play();
    imageWidth = 256;
    image.resize(imageWidth, 0);    
    sizeSlider.setValue(128);
    cp5.getController("img_rotate").setValue(0);
    sliderXY.setValue(0, 0);
    sliderBC.setValue(0, 1);
  }
  changeFlag = true;
}

void save_image() {
  PImage image = loadImage(bitmapPath);  
  image = filtered(image);
  image.save("outputImage.bmp");
}

void img_width(int size) {
  imageWidth = size;
  changeFlag = true;
}

void img_rotate(int val) {
  rotAngle = radians(val);
}

void image_pos() {
  changeFlag = true;
}

// ============== EFFECTS ==============

void br_contr() {
  changeFlag = true;
}

void grayscale(boolean state) {
  grayscaleState = !state;
  changeFlag = true;
}

void invert(boolean state) {
  invertState = !state;
  changeFlag = true;
}

void dither(boolean state) {
  ditherState = !state;
  changeFlag = true;
}

void frame(boolean state) {
  frameState = !state;
  changeFlag = true;
}

void threshold(boolean state) {
  thresholdState = !state;
  changeFlag = true;
}

void t_value(float val) {
  thresholdValue = val;
  changeFlag = true;
}

void posterize(boolean state) {
  posterizeState = !state;
  changeFlag = true;
}

void p_value(int val) {
  posterizeValue = val;
  changeFlag = true;
}

void play_video(boolean t) {
  play = t;
  cp5.getController("play_video").getCaptionLabel().setText(play ? "pause":"play");
  if (play) video.play();
  else video.pause();
  println("play=", play);
}


// ============== ENCODING ==============

void result_width(int val) {
  resultWidth = 2 * (val + borderW);
}
void result_height(int val) {
  resultHeight = 2 * (val + borderH) ;
}

void dropdown(int val) {
  saveMode = val;
  cp5.getController("save_bitmap").setVisible(true);
  cp5.getController("copy_clipboard").setVisible(true);
  cp5.getController("progmem").setVisible(true);
  cp5.getController("invert_result").setVisible(true);
  cp5.getController("flip_x").setVisible(true);
  cp5.getController("flip_y").setVisible(true);
}

void b_dimension(boolean val) {
  dimension = !val;
  cp5.getController("b_dimension").setCaptionLabel(dimension ? "2D ARRAY" : "1D ARRAY");
}

void progmem(boolean val) {
  progmem = !val;
}
void invert_result(boolean val) {
  invert = !val;
}
void flip_x(boolean val) {
  flipX = !val;
}
void flip_y(boolean val) {
  flipY = !val;
}

String generateName(int arrayH, int arrayW) {
  return ("_"+resultWidth+"x"+resultHeight+(dimension ? "["+ arrayH +"]["+ arrayW +"]" : "[][1024]") + (progmem ? " PROGMEM" : "") + " = {\n{\n");
}

String generateUserName(boolean path) {
  return cp5.get(Textfield.class, "name").getText();
}

String generateUserName() {
  File file = new File(cp5.get(Textfield.class, "name").getText());
  return file.getName();
}
void generateBitmap(int numRows) {
  if (first_frame) {
    saveLines = "// " + generateUserName(true) + ".h " + resultWidth + "x" + resultHeight;
  }
  switch (saveMode) {
  case 0:
    // ==== битмап для оледов ====   
    if (first_frame) {
      saveLines += " 8 pix/byte OLED\n";
      saveLines += "const uint8_t " + generateUserName() + generateName(numRows, resultWidth);
    }
    for (int r = 0; r < numRows; r++) {
      saveLines += "\t";
      if (dimension) saveLines += "{";
      for (int j = 0; j < resultWidth; j++) {     
        byte thisByte = 0;
        for (byte b = 0; b < 8; b++) thisByte |= getPixBW(j, r*8+7-b) << (7-b);          
        saveLines += "0x" + hex(thisByte, 2);
        saveLines += ", ";
      }
      if (dimension) saveLines += "},";
      saveLines += "\n";
    }
    saveLines += "}";
    break;
  case 1:
    // линейный битмап
    if (first_frame) {
      saveLines += " 8 pix/byte\n";
      saveLines += "const uint8_t " + generateUserName() + generateName(resultHeight, resultWidth/8);
    }
    for (int h = 0; h < resultHeight; h++) {
      saveLines += "\t";
      if (dimension) saveLines += "{";
      for (int i = 0; i < resultWidth; i+=8) {      
        byte thisByte = 0;
        for (byte b = 0; b < 8; b++) thisByte |= getPixBW(b+i, h) << (7-b);          
        saveLines += "0x" + hex(thisByte, 2);
        saveLines += ", ";
      }
      if (dimension) saveLines += "},";
      saveLines += "\n";
    }
    saveLines += "}";
    break;
  case 2:
    // 1 pix/byte, BW
    if (first_frame) {
      saveLines += " 1 pix/byte, BW\n";
      saveLines += "const uint8_t " + generateUserName() + generateName(resultHeight, resultWidth);
    }
    for (int y = 0; y < resultHeight; y++) {
      saveLines += "\t";
      if (dimension) saveLines += "{";
      for (int x = 0; x < resultWidth; x++) {
        saveLines += getPixBW(x, y) + ", ";
      }
      if (dimension) saveLines += "},";
      saveLines += "\n";
    }
    saveLines += "}";
    break;
  case 3:
    // ==== 1 pix/byte, Gray ====
    if (first_frame) {
      saveLines += " 1 pix/byte, Gray\n";
      saveLines += "const uint8_t " + generateUserName() + generateName(resultHeight, resultWidth);
    }
    for (int y = 0; y < resultHeight; y++) {
      saveLines += "\t";
      if (dimension) saveLines += "{";
      for (int x = 0; x < resultWidth; x++) {
        saveLines += "0x" + hex(getPixGray(x, y), 2) + ", ";
      }
      if (dimension) saveLines += "},";
      saveLines += "\n";
    }
    saveLines += "}";
    break;
  case 4:
    // ==== rgb8 ====
    if (first_frame) {
      saveLines += " rgb8\n";
      saveLines += "const uint8_t " + generateUserName() + generateName(resultHeight, resultWidth);
    }
    for (int y = 0; y < resultHeight; y++) {
      saveLines += "\t";
      if (dimension) saveLines += "{";
      for (int x = 0; x < resultWidth; x++) {
        saveLines += "0x" + hex(getPixRGB8(x, y), 2) + ", ";
      }
      if (dimension) saveLines += "},";
      saveLines += "\n";
    }
    saveLines += "}";
    break;
  case 5:
    // ==== rgb16 ====
    if (first_frame) {
      saveLines += " rgb16\n";
      saveLines += "const uint16_t " + generateUserName() + generateName(resultHeight, resultWidth);
    }
    for (int y = 0; y < resultHeight; y++) {
      saveLines += "\t";
      if (dimension) saveLines += "{";
      for (int x = 0; x < resultWidth; x++) {
        saveLines += "0x" + hex(getPixRGB16(x, y), 4) + ", ";
      }
      if (dimension) saveLines += "},";
      saveLines += "\n";
    }
    saveLines += "}";
    break;
  case 6:
    // ==== rgb32 ====
    if (first_frame) {
      saveLines += " rgb32\n";
      saveLines = "const uint32_t " + generateUserName() + generateName(resultHeight, resultWidth);
    }
    for (int y = 0; y < resultHeight; y++) {
      saveLines += "\t";
      if (dimension) saveLines += "{";
      for (int x = 0; x < resultWidth; x++) {
        saveLines += "0x" + hex(getPixRGB32(x, y), 6) + ", ";
      }
      if (dimension) saveLines += "},";
      saveLines += "\n";
    }
    saveLines += "}";
    break;
  }
}

void save_bitmap() {
  record_start(1);
}

void copy_clipboard() {
  record_start(2);
}

void record_start(int action) {
  video.stop();
  video.noLoop();  
  video.play();
  first_frame = true;
  play = true;
  record = action;
}

// ============== COLOR PICKERS ==============
color getColor(int x, int y) {
  if (flipX) x = resultWidth-1 - x;
  if (flipY) y = resultHeight-1 - y;
  color c = get(int(rectX + x * rectSize - rectSize*resultWidth/2 + rectSize/2), int(rectY + y * rectSize - rectSize*resultHeight/2 + rectSize/2));
  return (invert ? ~c : c);
}

int getPixBW(int x, int y) {
  if (x >= resultWidth || y >= resultHeight) return 0;
  if (brightness(getColor(x, y)) < 127) return 0;
  else return 1;
}

byte getPixGray(int x, int y) {
  if (x >= resultWidth || y >= resultHeight) return 0;
  return byte(brightness(getColor(x, y)));
}

int getPixRGB32(int x, int y) {
  if (x >= resultWidth || y >= resultHeight) return 0;
  return getColor(x, y);
}

int getPixRGB16(int x, int y) {
  if (x >= resultWidth || y >= resultHeight) return 0;
  int col = getColor(x, y);
  return ( (((col) & 0xF80000) >> 8) | (((col) & 0xFC00) >> 5) | (((col) & 0xF8) >> 3));
}

int getPixRGB8(int x, int y) {
  if (x >= resultWidth || y >= resultHeight) return 0;
  int col = getColor(x, y);
  return ( (((col) & 0xE00000) >> 16) | (((col) & 0xC000) >> 11) | (((col) & 0xE0) >> 5));
}

// ================ BOTTOM ==================

void help_ru() {
  helpState = !helpState;
  langulage = false;
  if (!helpState) changeFlag = true;
}
void help_en() {
  helpState = !helpState;
  langulage = true;
  if (!helpState) changeFlag = true;
}

void about() {
  link("https://github.com/AlexGyver/imageProcessor");
}

void showHelp() {
  background(255);
  int[] textPos = new int[15];
  textPos[0] = 30; 
  textPos[1] = 60;
  textPos[2] = 90; 
  textPos[3] = 130;
  textPos[4] = 150; 
  textPos[5] = 260;
  textPos[6] = 310;
  textPos[7] = 360;
  textPos[8] = 410; 
  textPos[9] = 480;
  textPos[10] = 510; 
  textPos[11] = 540;
  textPos[12] = 590; 
  textPos[13] = 650;
  textPos[14] = height - 10; 

  noFill();
  stroke(0);
  strokeWeight(3);
  rect(840, 3, 300, 610);

  PFont myFont;
  myFont = createFont("Ubuntu", 15);
  textFont(myFont);
  fill(0);
  String[] helpText;

  if (!langulage) helpText = loadStrings("langRU");
  else helpText = loadStrings("langEN");
  for (byte i = 0; i < 15; i++) {
    text(helpText[i], 240, textPos[i]);
  }
  for (byte i = 0; i < 40; i++) {
    text(helpText[i+16], 850, 20+i*15);
  }
}
