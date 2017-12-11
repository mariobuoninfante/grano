//-------------------------------------PUBLIC CLASS-----------------------------------------

// !!!!!Wavetable Chugin used!!!!!

public class Grain{
    float window[512];
    Windowing.hann(512) @=> window; //window types: rectangle, triangle, hann, hamming, blackmanHarris
    second/samp => float SR;

    SndBuf audioFile => Gain dryVol => ADSR out;                        //dry sound
    out.set(10::ms, 140::ms, 0.9, 50::ms);
    audioFile.rate(0);

    Phasor p => Gain pScale => Gain gOffset => Wavetable buffer => Gain g => Gain  master => ADSR adsr => Pan2 stereo;      //grain
    Step step => Envelope offsetLine => gOffset;
    adsr => Gain aux1;       //auxiliary output
    p => Gain gW => Wavetable gWindow => g; //read the window then connect it to the grain "Gain g"
    Step wStep => gW;
    aux1.gain(0);
    step.next(1);
    offsetLine.duration(0::ms);
    offsetLine.target(0);
    g.op(3);                //multiplier

    adsr.set(10::ms, 140::ms, 0.9, 750::ms);
    stereo.pan(0);

    buffer.sync(1);         //set "buffer" input to phase in
    gWindow.sync(1);        //set "buffer" input to phase in

    8 => int bufferSize;
    0 => float bufSizeMsec;
    float gBuf[8];
    gWindow.setTable(window);   //set gWindow
    float pFreq;
    int n;
    float scale;            //file length in a range from 0 to 1
    float offset;           //file length in a range from 0 to 1
    float overlap;          //in a range from 0 to 1
    float grainSize;
    static float grainsVol;
    static float dryMastVol;
    0.5 => static float mixVol;
    applyMixVol(mixVol);
    0.01 => float lineTime; //offset interpolation time
    1 => float sizeMinMsec;
    float sizeMaxMsec;
    0 => float offsetMinMsec;
    0 => float offsetMaxMsec;
    0 => static float spread;
    0 => static float aux1Vol;
    0 => static int grainsNr;

    function void setGrainsVol( float x ){
        (x/grainsNr) => grainsVol;
        master.gain(grainsVol);
    }

    function void setDryVol( float x ){
        x => dryMastVol;
        dryVol.gain(dryMastVol);
    }

    function void setMixVol( float x ){
        x => mixVol;
        applyMixVol(mixVol);
    }

    function void applyMixVol( float x ){ //set both Dry and Grains volume using 1 single argument
        x => grainsVol;
        1-x => dryMastVol;
        master.gain(grainsVol);
        dryVol.gain(dryMastVol);
    }

    function void setWindow( int x ){
        //window types: rectangle, triangle, hann, hamming, blackmanHarris
        if( x == 0 ){ Windowing.hann(512) @=> window; }
        else if( x == 1 ){ Windowing.hamming(512) @=> window; }
        else if( x == 2 ){ Windowing.blackmanHarris(512) @=> window; }
        else if( x == 3 ){ Windowing.triangle(512) @=> window; }
        else if( x == 4 ){ Windowing.rectangle(512) @=> window; }
        gWindow.setTable(window);   //set gWindow
    }

    function void setOffset( float x ){     //argument needs to be specified in msec
        Math.max( 0, ( Math.min(bufSizeMsec, x) - grainSize )  ) => x;
        (SR*x*0.001)/bufferSize => offset;  //normalize offset (0-1)
        offsetLine.target(offset);
    }

    function void setRandOffset( float x ){     //randomizes a bit the grain offset (arg in msec)
        Math.random2f(0.8, 1.2) * x => x;
        Math.max( 0, ( Math.min(bufSizeMsec, x) - grainSize )  ) => x;
        (SR*x*0.001)/bufferSize => offset;      //normalize offset (0-1)
        offsetLine.target(offset);
    }

    function void setOffsetLine( float t ){
        Math.min( Math.max(0, t), 5000 ) => t;
        offsetLine.duration( t::ms );
    }

    function void setOverlap( float x ){
        x => overlap;
        wStep.next(overlap);
    }

    function void setSize( float x ){           //argument needs to be specified in msec
        Math.max( 0.1, ( Math.min( (bufSizeMsec - 0.1), x) )  ) => x;
        1000.0/x => pFreq;
        (SR*x*0.001)/bufferSize => grainSize;   //normalize grainSize (0-1)
        pScale.gain(grainSize);
        p.freq(pFreq);
    }

    function void setRandSize( float x ){       //randomizes a bit the grain size (arg in msec)
        Math.random2f(0.9, 1.1) * x => x;
        Math.max( 0.1, ( Math.min( (bufSizeMsec - 0.1), x) )  ) => x;
        1000.0/x => pFreq;
        (SR*x*0.001)/bufferSize => grainSize;   //normalize grainSize (0-1)
        pScale.gain(grainSize);
        p.freq(pFreq);
    }

    function void setSizeRange( float x, float y ){
        Math.min( Math.max(1, x), bufSizeMsec -1 ) => x;
        Math.min( Math.max(x+1, y), bufSizeMsec - x ) => y;
        x => sizeMinMsec;
        y => sizeMaxMsec;
    }

    function void setOffsetRange( float x, float y ){
        x => offsetMinMsec;
        y => offsetMaxMsec;
    }

    function void setPan( float x ){
        x => stereo.pan;
    }

    function void setSpread( float x ){
        x => spread;
        applySpread(spread);
    }

    function void applySpread( float x ){ //used in play()
        Math.random2f(-x, x) => this.setPan;
    }

    function float getSize(){
        return grainSize*bufSizeMsec; //grain size in msec
    }

    function float getFileSize(){
        return bufSizeMsec; //file size in msec
    }

    function dur getAttack(){
        return adsr.attackTime();
    }

    function dur getDecay(){
        return adsr.decayTime();
    }

    function dur getRelease(){
        return adsr.releaseTime();
    }


    function void adsrTrig( int x ){
        if( x == 1 ){
            adsr.keyOn();
        }
        else if( x == 0 ){
            adsr.keyOff();
        }
    }

    function void setAux1( float x ){
        x => aux1Vol;
        applyAux1(aux1Vol);
    }

    function void applyAux1( float x ){
        aux1.gain(x);
    }

    function void initialize( UGen aux1Out, string loadThisFile ){ //initialize the grain - FIRST THING TO DO BEFORE USE ANY GRAIN!!!!!!
        aux1 => aux1Out;
        audioFile.read(loadThisFile);
        audioFile.samples() =>  bufferSize;
        gBuf.size(bufferSize);
        buffer.setTable(gBuf);
        (1000*bufferSize)/SR => bufSizeMsec;
        for( 0 => int c; c < bufferSize-1; c+1 => c ){
            audioFile.valueAt(c) => gBuf[c];
        }
        grainsNr + 1 => grainsNr;
    }

    function void play( dur attack, dur release ){
        this.applySpread(spread);
        this.applyAux1(aux1Vol);
        this.applyMixVol(mixVol);
        this.adsr.attackTime(attack);
        this.adsr.releaseTime(release);
        this.stereo => dac;
        this.adsrTrig(1);
        attack => now;
        this.adsrTrig(0);
        release => now;
        this.stereo =< dac;
    }

    function void playDry( dur t, int pad ){ //play the original sound in a linear fashion - no grains - created to be used with pads (discrete steps)
        this.applyMixVol(mixVol);
        this.out => dac;
        pad/8.0 => float samplePhase; //max number of pads is hard coded (16) - make changes here if needed
        audioFile.phase(samplePhase);
        audioFile.rate(1);
        this.out.keyOn();
        t => now;
        this.out.keyOff();
        this.out.releaseTime() => now;
        this.out =< dac;
        audioFile.rate(0);
    }
}
