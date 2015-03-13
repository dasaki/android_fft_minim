/*
Audio spectrum analyzer for android devices
12 may 2013
David Sanz Kirbis

This is a remix of a lot of code and info.

Basically adapted some of the minim analysis code to use the FFT with
android audio recorder.
https://github.com/ddf/Minim/tree/master/src/ddf/minim/analysis

More info:

setting up android & processing:
http://wiki.processing.org/w/Android
http://developer.android.com/sdk/index.html#ExistingIDE
http://developer.android.com/sdk/installing/index.html

http://forum.processing.org/topic/microphone-on-android

android specific
http://stackoverflow.com/questions/5774104/android-audio-fft-to-retrieve-specific-frequency-magnitude-using-audiorecord
http://www.androidcookbook.info/android-media/visualizing-frequencies.html

fft generic:
http://stackoverflow.com/questions/4633203/extracting-precise-frequencies-from-fft-bins-using-phase-change-between-frames
http://www.dsprelated.com/showmessage/18389/1.php
dsp.stackexchange.com/questions/2121/i-need-advice-about-how-to-make-an-audio-frequency-analyzer
https://en.wikipedia.org/wiki/Log-log_plot
            
*/


import android.media.AudioRecord;
import android.media.AudioFormat;
import android.media.MediaRecorder;


int       RECORDER_SAMPLERATE = 44100;
int       MAX_FREQ = RECORDER_SAMPLERATE/2;
final int RECORDER_CHANNELS = AudioFormat.CHANNEL_IN_MONO;
final int RECORDER_AUDIO_ENCODING = AudioFormat.ENCODING_PCM_16BIT;
final int PEAK_THRESH = 20;

short[]     buffer           = null;
int         bufferReadResult = 0;
AudioRecord audioRecord      = null;
boolean     aRecStarted      = false;
int         bufferSize       = 2048;
int         minBufferSize    = 0;
float       volume           = 0;
FFT         fft              = null;
float[]     fftRealArray     = null;
int         mainFreq         = 0;

float       drawScaleH       = 4.5; // TODO: calculate the drawing scales
float       drawScaleW       = 1.0; // TODO: calculate the drawing scales
int         drawStepW        = 2;   // display only every Nth freq value
float       maxFreqToDraw    = 2500; // max frequency to represent graphically
int         drawBaseLine     = 0;

void setup() {
  
  size(displayWidth, displayHeight);
  drawBaseLine = displayHeight-150;
  minBufferSize = AudioRecord.getMinBufferSize(RECORDER_SAMPLERATE,RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING);
  // if we are working with the android emulator, getMinBufferSize() does not work
  // and the only samplig rate we can use is 8000Hz
  if (minBufferSize == AudioRecord.ERROR_BAD_VALUE)  {
    RECORDER_SAMPLERATE = 8000; // forced by the android emulator
    MAX_FREQ = RECORDER_SAMPLERATE/2;
    bufferSize =  getHigherP2(RECORDER_SAMPLERATE);// buffer size must be power of 2!!!
    // the buffer size determines the analysis frequency at: RECORDER_SAMPLERATE/bufferSize
    // this might make trouble if there is not enough computation power to record and analyze
    // a frequency. In the other hand, if the buffer size is too small AudioRecord will not initialize
  } else bufferSize = minBufferSize;
  
  buffer = new short[bufferSize];
  // use the mic with Auto Gain Control turned off!
  audioRecord = new AudioRecord( MediaRecorder.AudioSource.VOICE_RECOGNITION, RECORDER_SAMPLERATE,
                                 RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING, bufferSize);
 
  //audioRecord = new AudioRecord( MediaRecorder.AudioSource.MIC, RECORDER_SAMPLERATE,
   //                              RECORDER_CHANNELS,RECORDER_AUDIO_ENCODING, bufferSize);
  if ((audioRecord != null) && (audioRecord.getState() == AudioRecord.STATE_INITIALIZED)) {
    try {
      // this throws an exception with some combinations
      // of RECORDER_SAMPLERATE and bufferSize 
      audioRecord.startRecording(); 
      aRecStarted = true;
    }
    catch (Exception e) {
      aRecStarted = false;
    }
    
    if (aRecStarted) {
        bufferReadResult = audioRecord.read(buffer, 0, bufferSize);
        // compute nearest higher power of two
       bufferReadResult = getHigherP2(bufferReadResult);
        fft = new FFT(bufferReadResult, RECORDER_SAMPLERATE);
        fftRealArray = new float[bufferReadResult]; 
        drawScaleW = drawScaleW*(float)displayWidth/(float)fft.freqToIndex(maxFreqToDraw);
    }
  }
  fill(0);
  noStroke();
}

void draw() {
   background(128); fill(0); noStroke();
   if (aRecStarted) {
       bufferReadResult = audioRecord.read(buffer, 0, bufferSize);  
       
       // After we read the data from the AudioRecord object, we loop through
       // and translate it from short values to double values. We can't do this
       // directly by casting, as the values expected should be between -1.0 and 1.0
       // rather than the full range. Dividing the short by 32768.0 will do that,
       // as that value is the maximum value of short.
       volume = 0;
       for (int i = 0; i < bufferReadResult; i++) {
            fftRealArray[i] = (float) buffer[i] / Short.MAX_VALUE;// 32768.0;
            volume += Math.abs(fftRealArray[i]);
       }
       volume = (float)Math.log10(volume/bufferReadResult);
         
         // apply windowing
        for (int i = 0; i < bufferReadResult/2; ++i) {
          // Calculate & apply window symmetrically around center point
          // Hanning (raised cosine) window
          float winval = (float)(0.5+0.5*Math.cos(Math.PI*(float)i/(float)(bufferReadResult/2)));
          if (i > bufferReadResult/2)  winval = 0;
          fftRealArray[bufferReadResult/2 + i] *= winval;
          fftRealArray[bufferReadResult/2 - i] *= winval;
        }
        // zero out first point (not touched by odd-length window)
        fftRealArray[0] = 0;
        fft.forward(fftRealArray);
         
         //
        fill(255);
        stroke(100);
        pushMatrix();
        rotate(radians(90));
        translate(drawBaseLine-3, 0);
        textAlign(LEFT,CENTER);
        for (float freq = RECORDER_SAMPLERATE/2-1; freq > 0.0; freq -= 150.0) {
          int y = -(int)(fft.freqToIndex(freq)*drawScaleW); // which bin holds this frequency?
          line(-displayHeight,y,0,y); // add tick mark
          text(Math.round(freq)+" Hz", 10, y); // add text label
        }
        popMatrix();
        noStroke();
   
        float lastVal = 0;
        float val = 0;
        float maxVal = 0; // index of the bin with highest value
        int maxValIndex = 0; // index of the bin with highest value
        for(int i = 0; i < fft.specSize(); i++)
        {
          val += fft.getBand(i);
          if (i % drawStepW == 0) {
               val /= drawStepW; // average volume value
               int prev_i = i-drawStepW;
              stroke(255);
              // draw the line for frequency band i, scaling it up a bit so we can see it
              line( prev_i*drawScaleW, drawBaseLine, prev_i*drawScaleW, drawBaseLine - lastVal*drawScaleH );
          
              if (val-lastVal > PEAK_THRESH) {
                  stroke(255,0,0);
                  fill(255,128,128);
                  ellipse(i*drawScaleW, drawBaseLine - val*drawScaleH, 20,20);
                  stroke(255);
                  fill(255);
                  if (val > maxVal) {
                    maxVal = val;
                    maxValIndex = i;
                  }
              } 
              line( prev_i*drawScaleW, drawBaseLine - lastVal*drawScaleH, i*drawScaleW, drawBaseLine - val*drawScaleH );
              lastVal = val;
              val = 0;  
           }
        }
        if (maxValIndex-drawStepW > 0) {
           fill(255,0,0);
           ellipse(maxValIndex*drawScaleW, drawBaseLine - maxVal*drawScaleH, 20,20);
           fill(0,0,255);
           text( " " + fft.indexToFreq(maxValIndex-drawStepW/2)+"Hz",
                 25+maxValIndex*drawScaleW, drawBaseLine - maxVal*drawScaleH);     
        }
        fill(255); 
        pushMatrix();
        translate(displayWidth/2,drawBaseLine);
        text("buffer readed: " + bufferReadResult, 20, 80);
        text("fft spec size: " + fft.specSize(), 20, 100);
        text("volume: " + volume, 20, 120);  
        popMatrix();
  }
  else {
    fill(255,0,0);
    text("AUDIO RECORD NOT INITIALIZED!!!", 100, height/2);
  }  
  fill(255); 
  pushMatrix();
  translate(0,drawBaseLine);
  text("sample rate: " + RECORDER_SAMPLERATE + " Hz", 20, 80);   
  text("displaying freq: 0 Hz  to  "+maxFreqToDraw+" Hz", 20, 100);   
  text("buffer size: " + bufferSize, 20, 120);   
  popMatrix();
}

void stop() {
  audioRecord.stop();
  audioRecord.release();
}

// compute nearest higher power of two
// see: graphics.stanford.edu/~seander/bithacks.html
int getHigherP2(int val)
{
  val--;
  val |= val >> 1;
  val |= val >> 2;
  val |= val >> 8;
  val |= val >> 16;
  val++;
  return(val);
}
