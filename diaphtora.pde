/*
MIT License

Copyright (c) 2023 Bertrand GILLES-CHATELETS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// διαφθορά@bertrandopiroscafo
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
import controlP5.*;
import themidibus.*;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;

String _fno = "./TEMP/corrupted_output.jpg";
String _fn  = "m33_p128.jpg";
PImage _img;

ControlP5 _controlP5;
Slider _depthSlider;
Slider _byteSlider;
Slider _algorithmSlider;
Slider _incursionDepthSlider;
Slider _bwThresholdSlider;
Toggle _animateToggle;
Button _saveButton;
Button _diceButton;
Button _defaultButton;
Button _stepBwdButton;
Button _stepFwdButton;
Button _fileButton;
Button _resetButton;
Button _scanButton;
Toggle _fxToggle;
Toggle _noiseToggle;
Toggle _bwToggle;
Toggle _signatureToggle;

int  _depthValue = 0;
byte _byteValue = 0;
int  _algorithmValue = 0;
int  _incursionDepthValue = 0;
float _bwThresholdValue = 0;
byte _b[]; 
byte _b_orig[]; 
int  _algoCounter = 0;
final int NB_OF_ALGO_USED = 4;

final int DEPTH_MIN = 10;
final int DEPTH_MAX = 10000;
final int BYTE_MIN = -128;
final int BYTE_MAX = 127;
final int ALGO_MIN = 0;
final int ALGO_MAX = 6;
final int INCURSION_MIN = 10;
final int INCURSION_MAX = 10000;

float _inc1 = 0.005;
float _inc2 = 0.005;
float _inc3 = 0.005;
float _inc4 = 0.005;
boolean _isAnimated = false;
boolean _isByteNoisy = false;
boolean _isSaving = false;
boolean _shiftMode = false;
boolean _isFX = false;
boolean _isBW = false;
boolean _isMarked = true;
int _numScan = 0;


MidiBus _myBus; // The MidiBus
final int _CC_CHANNEL = 0;
final int _CC_CV1 = 0;
final int _CC_CV2 = 1;
final int _CC_CV3 = 2;
final int _CC_CV4 = 3;
int _numberOfNotesHolded = 0;

// ===================================================
// Setup
// ===================================================
void setup() {
  
  size(810, 710);
  background(0);
  
  surface.setTitle("διαφθορά V1.0 2023 by @bertrandopiroscafo");
  
  // MMI
  _controlP5 = new ControlP5(this);
  _incursionDepthSlider = _controlP5.addSlider("incursion")
 .setRange(INCURSION_MIN, INCURSION_MAX)
 .setValue((INCURSION_MIN + INCURSION_MAX) / 2)
 .setPosition(10,615)
 .setSize(750,10);
  
  _depthSlider = _controlP5.addSlider("depth")
 .setRange(DEPTH_MIN, DEPTH_MAX)
 .setValue((DEPTH_MIN + DEPTH_MAX) / 2)
 .setPosition(10,630)
 .setSize(750,10);

  _byteSlider = _controlP5.addSlider("byte")
 .setRange(BYTE_MIN, BYTE_MAX)
 .setValue((BYTE_MIN + BYTE_MAX) / 2)
 .setPosition(10,645)
 .setSize(750,10);
 
 _algorithmSlider = _controlP5.addSlider("algorithm")
 .setRange(ALGO_MIN, ALGO_MAX)
 .setValue(ALGO_MIN)
 .setPosition(10,660)
 .setSize(750,10);
 
 _animateToggle = _controlP5.addToggle("animate")
 .setPosition(10,680)
 .setSize(10,10);
 
 _saveButton = _controlP5.addButton("save frame")
 .setPosition(50,680)
 .setSize(60,20);
 
 _diceButton = _controlP5.addButton("dice")
 .setPosition(120,680)
 .setSize(60,20);
 
 _defaultButton = _controlP5.addButton("default")
 .setPosition(190,680)
 .setSize(60,20);
 
 _stepBwdButton = _controlP5.addButton("bwd")
 .setPosition(260,680)
 .setSize(60,20);
 
 _stepFwdButton = _controlP5.addButton("fwd")
 .setPosition(330,680)
 .setSize(60,20);
 
 _fileButton = _controlP5.addButton("file")
 .setPosition(400,680)
 .setSize(60,20);
 
 _resetButton = _controlP5.addButton("reset")
 .setPosition(470,680)
 .setSize(60,20);
 
 _scanButton = _controlP5.addButton("scan")
 .setPosition(540,680)
 .setSize(60,20);
 
 _noiseToggle = _controlP5.addToggle("noise")
 .setPosition(610,680)
 .setSize(10,10);
 
 _fxToggle = _controlP5.addToggle("fx")
 .setPosition(635,680)
 .setSize(10,10);
 
 _bwToggle = _controlP5.addToggle("bw")
 .setPosition(650,680)
 .setSize(10,10);
 
 _signatureToggle = _controlP5.addToggle("mk")
 .setPosition(670,680)
 .setSize(10,10)
 .setValue(1);
 
 _bwThresholdSlider = _controlP5.addSlider("t")
 .setRange(0, 1)
 .setValue(0.5)
 .setPosition(700,680)
 .setSize(100,10);
 
 /*
  textSize(36);
  fill(255,0,0);
  text("Brigitte's Ring ", 10,520);
  text("CoRRupTeD DaTA", 10,560);
  text("@bertrandopiroscafo ", 10,600);
 */
  
  setDefaultParameters();
 
  // load default file
  //_b_orig = loadBytes("./DATA/m33_p128.jpg");
  _b_orig = loadBytes("./DATA/"+_fn);
  _b = new byte[_b_orig.length];
  
  // MIDI initialization
  MidiBus.list(); 
  _myBus = new MidiBus(this, "USB MIDI Interface", -1);
  //_myBus = new MidiBus(this, "iRig KEYS Pro", -1);
}

// ===================================================
// Draw
// ===================================================
void draw() {
  background(0); // useful when an other image is loaded
  if (_isAnimated == true) 
  {
    //animatePerlin();
    animateRandom();
  }
  
  if (_isByteNoisy == true)
  {
    noiseByte();  
  }
  processImage();
  watermark();
}

// ===================================================
// Bitwise Algorithms
// ===================================================
void processImage() {
  
  // work on a copy of the original
  arrayCopy(_b_orig, _b);
  
  // initialize alternate mode
  _algoCounter = 0;
  
  // screw with the bytes
  for (int i = 0 ; i < _b.length ; i++)
  {
    if (i >= _incursionDepthValue) 
    {     
      if ((i - _incursionDepthValue) % _depthValue == 0) 
      {
        screw(i);  
      }
    }
  } 
  try
  {
    //long t = System.nanoTime();
    saveBytes(_fno, _b);  
    _img = loadImage(_fno);   
    //_img = bufferedImageToPImage(byteArrayToBufferedImage(_b)); // slower than with disk access !!!
    //t = System.nanoTime() - t;
    //println("Elapsed time (milliseconds) " + t / 1000000);
   
    if (_isFX == true)
    {
      fx();
    }
    
    if (_isBW == true)
    {
      bw();
    }
    
    image(_img, 0,0, _img.width, _img.height);
    //image(_img, 0,0, 810, 710);
  }
  catch (Exception e){
   //System.out.println("JPEG READER CRASHED !!"); 
  }
}

void screw(int at) {
  switch (_algorithmValue) {
          case 0:
            _b[at] = _byteValue; // SET
            break;
          case 1:
            _b[at] &= _byteValue; // AND
            break;
          case 2:
            _b[at] |= _byteValue; // OR
            break;
          case 3:
            _b[at] ^= _byteValue; // XOR
            break;
          case 4:
            _b[at] = (byte)~(int)_b[at]; // NOT
            break;  
          case 5:
            _b[at] = (byte)(~(int)_b[at] + 1); // Two's complement
            break;  
          case 6:
            alternate(at);
            break;
  }
}

void alternate(int i) 
{
  switch ((++_algoCounter) % NB_OF_ALGO_USED) {
      case 0:
         _b[i] = _byteValue; // SET
         break;
      case 1:
         _b[i] &= _byteValue; // AND
         break;
      case 2:
         _b[i] |= _byteValue; // OR
         break;
      case 3:
         _b[i] ^= _byteValue; // XOR
         break;
  }
}

BufferedImage byteArrayToBufferedImage(byte[] data)
{
    InputStream in = new ByteArrayInputStream(data);
    try {
           BufferedImage wrackedImage = ImageIO.read(in);
           return wrackedImage;
    } catch (IOException e) {
          //e.printStackTrace();
    }
      
    return null;
}
  
PImage bufferedImageToPImage(BufferedImage bufferedImage)
  {
    return new PImage(bufferedImage);
  }

// ===================================================
// MMI
// ===================================================
void controlEvent(ControlEvent theEvent) 
{
 if (theEvent.isController()) 
 { 
  if (theEvent.getController().getName()=="depth") 
  {
     _depthValue = (int)theEvent.getController().getValue(); 
  }
  if (theEvent.getController().getName()=="byte") 
  {
     _byteValue = (byte)theEvent.getController().getValue();
  }
  if (theEvent.getController().getName()=="algorithm") 
  {
     _algorithmValue = (int)theEvent.getController().getValue();
  }
  if (theEvent.getController().getName()=="incursion") 
  {
     _incursionDepthValue = (int)theEvent.getController().getValue();
     //println("incrusion = "+ _incursionDepthValue);
  }
  if (theEvent.getController().getName()=="animate") 
  {
     int v = (int)theEvent.getController().getValue();
     if (v == 1) 
     {
        _isAnimated = true; 
     }
     else  
     {
        _isAnimated = false; 
     } 
  }
  if (theEvent.getController().getName()=="save frame") 
  {
    _isSaving = true;
  }
  if (theEvent.getController().getName()=="dice") 
  {
     animateRandom();
     //_isSaving = true;
  }
  if (theEvent.getController().getName()=="default") 
  {
     setDefaultParameters();
  }
  if (theEvent.getController().getName()=="bwd") 
  {
    // one step backward
    if (_shiftMode == false)
    {   
     --_depthValue;
    }
    else 
    {
     --_incursionDepthValue;
    }
  }
  if (theEvent.getController().getName()=="fwd") 
  {
    // one step forward
    if (_shiftMode == false)
    {
     ++_depthValue;
    }
    else 
    {
     ++_incursionDepthValue;
    }
  }
  if (theEvent.getController().getName()=="file") 
  {
     selectInput("Select a file to process:", "fileSelected");
  }
  if (theEvent.getController().getName()=="reset") 
  {
     reset();
  }
  if (theEvent.getController().getName()=="scan") 
  {
     scanByte();
  }
  if (theEvent.getController().getName()=="noise") 
  {
     int v = (int)theEvent.getController().getValue();
     if (v == 1) 
     {
        _isByteNoisy = true; 
     }
     else  
     {
        _isByteNoisy = false; 
     } 
  }
  if (theEvent.getController().getName()=="fx") 
  {
     int v = (int)theEvent.getController().getValue();
     if (v == 1) 
     {
        _isFX = true; 
     }
     else  
     {
        _isFX = false; 
     }
  }
  if (theEvent.getController().getName()=="bw") 
  {
     int v = (int)theEvent.getController().getValue();
     if (v == 1) 
     {
        _isBW = true; 
     }
     else  
     {
        _isBW = false; 
     }
  }
  if (theEvent.getController().getName()=="t") 
  {
     _bwThresholdValue = theEvent.getController().getValue();
  }
  if (theEvent.getController().getName()=="mk") 
  {
     int v = (int)theEvent.getController().getValue();
     if (v == 1) 
     {
        _isMarked = true; 
     }
     else  
     {
        _isMarked = false; 
     }
  }
 }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    _b_orig = loadBytes(selection.getAbsolutePath());
    _fn = selection.getName();
    _b = new byte[_b_orig.length];    
  }
}

// ==================================================
// MIDI
// ==================================================
void controllerChange(int channel, int number, int value) {
  
  if (number == _CC_CV1)
  {
    if (value >= 0 && value <= 127)
    {
      _depthValue = (int)map(value, 0, 127, DEPTH_MIN, DEPTH_MAX);
      _depthSlider.setValue(_depthValue);
    }
  }
  if (number == _CC_CV2)
  {
    if (value >= 0 && value <= 127)
    {
      _byteValue = (byte)map(value, 0, 127, BYTE_MIN, BYTE_MAX);
      _byteSlider.setValue(_byteValue);
    }
  }
  if (number == _CC_CV3)
  {
    if (value >= 0 && value <= 127)
    {
      _algorithmValue = (int)map(value, 0, 127, ALGO_MIN, ALGO_MAX);
      _algorithmSlider.setValue(_algorithmValue);
    }
  }
  if (number == _CC_CV4)
  {
    if (value >= 0 && value <= 127)
    {
      _incursionDepthValue = (int)map(value, 0, 127, INCURSION_MIN, INCURSION_MAX);
      _incursionDepthSlider.setValue(_incursionDepthValue);
    }
  }
}

// for check purpose
/*void noteOn(Note note) {
  println(note.toString());
}*/

// Avec l'algorithme OR (2), on peut visualiser un accord avec une 
// visualisation unique indépendante de l'ordre de frappe des touches !
// ex Tonique OR Tierce OR Quinte

void noteOn(int channel, int pitch, int velocity) {
  
  if (pitch >= 0 && pitch <= 127 && velocity >= 0 && velocity <= 127) 
  {
    //println("pitch = ", pitch);
    //println("velocity = ", velocity);
   
    _numberOfNotesHolded++;
    //_byteValue = (byte)map(pitch, 0, 127, BYTE_MIN, BYTE_MAX);
    //_byteSlider.setValue(_byteValue);
    _depthValue = (int)map(pitch, 0, 127, DEPTH_MIN, DEPTH_MAX);
    _depthSlider.setValue(_depthValue);
  }
}

void noteOff(int channel, int pitch, int velocity) {
  
   if (pitch >= 0 && pitch <= 127 && velocity >= 0 && velocity <= 127) 
   {
     if (--_numberOfNotesHolded == 0)
     {
      //_byteValue = 0; 
      //_byteSlider.setValue(_byteValue);
      _depthValue = (DEPTH_MIN + DEPTH_MAX) / 2; 
      _depthSlider.setValue(_depthValue);
     }
   }
}

// =======================================================
// Default parameters
// =======================================================
void setDefaultParameters() {
  
  _depthValue = (DEPTH_MIN + DEPTH_MAX) / 2;
  _depthSlider.setValue(_depthValue);
  _byteValue = BYTE_MAX; 
  _byteSlider.setValue(_byteValue);
  _algorithmValue = 3;
  _algorithmSlider.setValue(_algorithmValue);
  _incursionDepthValue = (INCURSION_MIN + INCURSION_MAX) / 2;
  _incursionDepthSlider.setValue(_incursionDepthValue);
  _bwThresholdValue = 0.5;
  _bwThresholdSlider.setValue(_bwThresholdValue);
}

// =======================================================
// Reset (No FX)
// =======================================================
void reset() {
  
  _depthValue = (DEPTH_MIN + DEPTH_MAX) / 2;
  _depthSlider.setValue(_depthValue);
  _byteValue = 0; // no effect with algorithm #2 or #3
  _byteSlider.setValue(_byteValue);
  _algorithmValue = 3;
  _algorithmSlider.setValue(_algorithmValue);
  _incursionDepthValue = (INCURSION_MIN + INCURSION_MAX) / 2;
  _incursionDepthSlider.setValue(_incursionDepthValue);
  _bwThresholdValue = 0.5;
  _bwThresholdSlider.setValue(_bwThresholdValue);
}

// =======================================================
// Animation
// =======================================================
void animatePerlin() {
  
  _depthValue = (int)map(noise(_inc1++), 0.0, 1.0, DEPTH_MIN, _depthSlider.getValue());
  _byteValue = (byte)map(noise(_inc2++), 0.0, 1.0, BYTE_MIN, _byteSlider.getValue());
  _algorithmValue = (int)map(noise(_inc3++), 0.0, 1.0, ALGO_MIN, _algorithmSlider.getValue());
  _incursionDepthValue = (int)map(noise(_inc4++), 0.0, 1.0, INCURSION_MIN, _incursionDepthSlider.getValue());
}

void animateRandom() {
  
  _depthValue = (int)map(random(1.0), 0.0, 1.0, DEPTH_MIN, _depthSlider.getValue());
  _byteValue = (byte)map(random(1.0), 0.0, 1.0, BYTE_MIN, _byteSlider.getValue());
  _algorithmValue = (int)map(random(1.0), 0.0, 1.0, ALGO_MIN, _algorithmSlider.getValue());  
  _incursionDepthValue = (int)map(random(1.0), 0.0, 1.0, INCURSION_MIN, _incursionDepthSlider.getValue());
}

// ========================================================
// Watermark
// ========================================================
void watermark() {
 
  if (_isSaving == true)
  {
    PGraphics pg = createGraphics(_img.width , _img.height);
    pg.beginDraw();
    pg.copy(_img, 0 , 0, _img.width, _img.height, 0, 0, _img.width, _img.height);
    if (_isMarked == true)
    {
      pg.fill(255,0,0);
      pg.textSize(15);
      pg.text("BGC 2023", _img.width - 75, _img.height - 5);
    }
    pg.endDraw();
    pg.save("./SAVE/"+_fn+'_'+(_incursionDepthValue)+' '+(_depthValue)+'_'+(_byteValue)+'_'+(_algorithmValue)+"@bertrandopiroscafo.jpg");
    //pg.save("./SAVE/"+_fn+'_'+(_incursionDepthValue)+' '+(_depthValue)+'_'+(_byteValue)+'_'+(_algorithmValue)+"@bertrandopiroscafo"); // No suffix -> TIFF
    _isSaving = false;
  }
}

void watermarkForScan() {
 
  if (_isSaving == true)
  {
    PGraphics pg = createGraphics(_img.width , _img.height);
    pg.beginDraw();
    pg.copy(_img, 0 , 0, _img.width, _img.height, 0, 0, _img.width, _img.height);
    pg.fill(255,0,0);
    pg.textSize(15);
    pg.text(str(++_numScan)+'/'+"256", 0, _img.height - 5);
    pg.text("BGC 2023", _img.width - 75, _img.height - 5);
    pg.endDraw();
    pg.save("./SAVE/"+_numScan+'_'+_fn+'_'+(_incursionDepthValue)+'_'+(_depthValue)+'_'+(_byteValue)+'_'+(_algorithmValue)+"@bertrandopiroscafo.jpg");
    //pg.save("./SAVE/"+_numScan+'_'+_fn+'_'+(_incursionDepthValue)+'_'+(_depthValue)+'_'+(_byteValue)+'_'+(_algorithmValue)+"@bertrandopiroscafo"); // No suffix -> TIFF
    _isSaving = false;
  }
}

// ========================================================
// scan byte range
// ========================================================
void scanByte()
{
   println("scanning...");
   _numScan = 0;
   for (int i = -128 ; i < 128 ; i++)
   {  
    _byteValue = (byte)i;
    print("["+(_byteValue + 128)+"]");
    _isSaving = true;
    processImage();
    watermarkForScan();
   }
   _byteSlider.setValue(_byteValue);
   println("scan completed");
}

// ========================================================
// noise byte 
// ========================================================
void noiseByte()
{
    _byteValue = (byte)map(noise(_inc2++), 0.0, 1.0, BYTE_MIN, _byteSlider.getValue());
}

// ========================================================
// FX
// ========================================================
void fx() 
{
   _img.filter(INVERT);
}

void bw() 
{
   _img.filter(THRESHOLD, _bwThresholdValue);
}

// ========================================================
// Menu management
// ========================================================
void displayControl(boolean show)
{
   if (show == true)
   {
     _depthSlider.show();
     _byteSlider.show();
     _algorithmSlider.show();
     _incursionDepthSlider.show();
     _animateToggle.show();
     _saveButton.show();
     _diceButton.show();
     _defaultButton.show();
     _stepBwdButton.show();
     _stepFwdButton.show();
     _fileButton.show();
     _resetButton.show();    
     _scanButton.show();
     _noiseToggle.show();
     _fxToggle.show();
     _bwToggle.show();
     _bwThresholdSlider.show();
   }
   else
   {
     _depthSlider.hide();
     _byteSlider.hide();
     _algorithmSlider.hide();
     _incursionDepthSlider.hide();
     _animateToggle.hide();
     _saveButton.hide();
     _diceButton.hide();
     _defaultButton.hide();
     _stepBwdButton.hide();
     _stepFwdButton.hide();
     _fileButton.hide();
     _resetButton.hide();
     _scanButton.hide();
     _noiseToggle.hide();
     _fxToggle.hide();
     _bwToggle.hide();
     _bwThresholdSlider.hide();
   }
}

void keyPressed() {
  if (key == 's') {
    displayControl(true); //<>//
  }
  if (key == 'h') {
    displayControl(false);
  }
 
  if (key == CODED) {
    if (keyCode == SHIFT) {
      _shiftMode = true;
    }   
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      _shiftMode = false;
    }   
  }
}
