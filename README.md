android_fft_minim
=================

Fast Fourier Transform algorithms from Processing's Minim audio library, adapted to work in android.

Tested and built with Processing 2.0b8 (android mode).

EDIT:
March 13th 2015
After some minor corrections I've managed to make this work in my Nexus 4, compiling the sketch with the app: APDE - Android Processing IDE (https://play.google.com/store/apps/details?id=com.calsignlabs.apde&hl=en). After installing APDE, just create a new folder called "android_fft_minim" in the sd card's "Sketchbook" folder and copy all the repo's files there. Run the APDE and open and play the android_fft_minim sketch. Have fun!

More info here: http://therandomlab.blogspot.com.es/2013/05/fft-audio-frequency-analysis-with.html

Basically adapted some of the minim analysis code to use the FFT with android audio recorder.
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
            
