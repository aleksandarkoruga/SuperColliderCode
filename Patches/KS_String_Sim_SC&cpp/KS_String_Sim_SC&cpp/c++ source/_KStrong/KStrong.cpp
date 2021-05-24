#include "SC_PlugIn.h"
#define TWO_PI 6.28318530718
#define SAMP_DUR 1.0/(float)SAMPLERATE
static InterfaceTable *ft;

struct KStrong : public Unit {
    // Max delay in seconds.
    float maxdelay;

  

    // Size of the buffer in samples, always a power of 2
    int bufsize;
    // bufsize - 1, so the modulo function can be replaced with a faster bitwise and
    int mask;
    // The buffer itself. This is an internal buffer, and is not connected with any Buffer instance.
    // It must be allocated in Ctor and freed in Dtor.
    float* buf;
    //twopoint average memory
    float avg;
    //allpass memory
    float allpass=0.0;
    // Position of the write head.
    int writephase;

    // State of the one-pole lowpass filter.
    float s1;
};


static void KStrong_next(KStrong *unit, int inNumSamples);
static void KStrong_Ctor(KStrong* unit);
static void KStrong_Dtor(KStrong* unit);


void KStrong_Ctor(KStrong* unit) {
    SETCALC(KStrong_next);

    float maxdel= 10.0;//ZIN0(2);
    unit->maxdelay = maxdel;
    unit->allpass=0.0;
    // To get the buffer size in samples, take the sample rate times the length in seconds.
    // The buffer size doesn't NEED to be a power of two, but if you're doing a lot of moduloing then it's faster that way.
    unit->bufsize = NEXTPOWEROFTWO((float)SAMPLERATE * unit->maxdelay);
    unit->mask = unit->bufsize - 1;
    unit->avg=0.0;
    unit->writephase = 0;
    unit->s1 = 0;

    // Allocate the buffer. Do NOT use malloc!
    // SuperCollider provides special real-time-safe allocation and freeing functions.
    unit->buf = (float*)RTAlloc(unit->mWorld, unit->bufsize * sizeof(float));

    // This check makes sure that RTAlloc succeeded. (It might fail if there's not enough memory.)
    // If you don't do this check properly then YOU CAN CRASH THE SERVER!
    // A lot of ugens in core and sc3-plugins fail to do this. Don't follow their example.
    if (unit->buf == NULL) {
        // Avoid retaining KStrong_next as the calculation function.
        SETCALC(ft->fClearUnitOutputs);
        ClearUnitOutputs(unit, 1);

        if(unit->mWorld->mVerbosity > -2) {
            Print("Failed to allocate memory for KStrong ugen.\n");
        }

        return;
    }

    // Fill the buffer with zeros.
    memset(unit->buf, 0, unit->bufsize * sizeof(float));

    KStrong_next(unit, 1);
}

// this must be named PluginName_Dtor.
void KStrong_Dtor(KStrong* unit) {
    // Free the memory.
    RTFree(unit->mWorld, unit->buf);
}

void KStrong_next(KStrong *unit, int inNumSamples)
{
    // audio-rate input signal
    float *in = IN(0);
    // audio-rate output signal
    float *out = OUT(0);
    // control-rate delay
    float *del = IN(1);

    float *fb= IN(2);
    
    
    
    
    

    


    float* buf = unit->buf;
    int mask = unit->mask;
    int writephase = unit->writephase;
    float s1 = unit->s1;
    
    float delay;
    float feedback;

    for (int i = 0; i < inNumSamples; i++) {

         
         delay= del[i];
         feedback=fb[i];
         
  // Cap the delay at maxdelay
    if (delay > unit->maxdelay) {
        delay = unit->maxdelay;
    }



    // Compute the delay in samples and the integer and fractional parts of this delay.
    float delay_samples = (float)SAMPLERATE * delay;
    float epsilon= 0.0001;
    int offset = std::floorf(delay_samples-0.5-epsilon);
   //fractional part (0.5 is to compensate for the two point average)
    float pFrac= delay-offset-0.5;
    float freq=1/delay;
    float omega=TWO_PI*freq;//SAMP_DUR
    //all pass coeff - correct formula for fractional phase offset (simplified=1-frac/1+frac)
    float c_all=std::sinf(0.5*(omega*SAMP_DUR-omega*SAMP_DUR*pFrac))/std::sinf(0.5*(omega*SAMP_DUR+omega*SAMP_DUR*pFrac));
    
    
    
    


      //read phases
        int phase1 = writephase - offset;
        int phase2 = phase1 - 1;
        
       //delayed samples 
        float d1 = buf[phase1 & mask];
        float d2 = buf[phase2 & mask];
       
        // two point average
        float delayed = 0.5*(d1+d2); 
        
        ////allpass
        
        unit->allpass=c_all*delayed+unit->avg -c_all*unit->allpass;


        buf[writephase] = in[i]+unit->allpass ;

        // Multiply by feedback coefficient and add to input signal.
        // zapgremlins gets rid of Bad Things like denormals, explosions, etc.
      
        out[i]=zapgremlins(unit->allpass);
       
        // Here's why the buffer size is a power of two -- otherwise this becomes a much more
        // expensive modulo operation.
        writephase = (writephase + 1) & mask;
        unit->avg=delayed;
    }

    // These two variables were updated and need to be stored back into the state of the UGen.
    unit->writephase = writephase;
    unit->s1 = s1;
}


PluginLoad(KStrong)
{
    ft = inTable;
    // ATTENTION! This has changed!
    // In the previous examples this was DefineSimpleUnit.
    DefineDtorUnit(KStrong);
}