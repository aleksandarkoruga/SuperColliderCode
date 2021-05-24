// Demand synths don't keep up with the signal vector, one sample buffer works fine (testK synth confirms Duty is once per sample) but
// when using larger buffers (at least my mac - 2012) it fails and lags behind, the solution is using c++ to write an external
// (see included code and paper in the compressed folder)


// /////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////
// like max, just a delay and a two point average filter
(SynthDef(\fbK,{|freq=440.0|
	var b= LocalBuf.new().clear;
	var v;

	var impulse=Impulse.ar(0.5);
	var	envelope1=EnvGen.ar(Env.perc(0.001,0.02),impulse-0.001);
	var sig=0.0;

	v= Duty.ar(SampleDur.ir,0,Dbufrd(b,0));

	sig=DelayL.ar(v+  (WhiteNoise.ar()*envelope1),0.5,1/freq);
	sig=OnePole.ar(sig);
	v=Duty.ar(SampleDur.ir,0,Dbufwr(sig,b,0));
	Out.ar(0,sig);
}).add)

// /////////////////////////////////////////////////////////////
// https://www.jstor.org/stable/3680063?origin=JSTOR-pdf&seq=1
// Basic Karplus Strong Algorithm
(SynthDef(\ksBasic,
	{
		|feedback=0.8,delay=4|
		var buf=LocalBuf.new(1024);
		var idxMem=LocalBuf.new();

		var rIdx=0.0,wIdx=0.0;

		var sig=0.0;
		var rIdx2=0.0;
		var envelope1,impulse;
		var out=0.0;



		wIdx=Duty.ar(SampleDur.ir,0,Dbufrd(idxMem,0));



		rIdx= ((wIdx+1024.0)-(delay.floor)).mod(1024.0).floor;
		rIdx2=(rIdx+1023.0).mod(1024.0).floor;


		impulse=Impulse.ar(0.5);
		envelope1=EnvGen.ar(Env.perc(0.001,0.02),impulse-0.001);


		sig=Duty.ar(SampleDur.ir,0,0.5*(Dbufrd(buf,rIdx)+Dbufrd(buf,rIdx2)));

		out=sig;


		sig=(sig*( feedback))+(WhiteNoise.ar()*envelope1);


		sig=Dbufwr(sig,buf,wIdx);
		sig=Duty.ar(SampleDur.ir,0,sig);

		wIdx=(wIdx+1.0).mod(1024.0);
		wIdx=Dbufwr(wIdx,idxMem,0);
		wIdx=Duty.ar(SampleDur.ir,0,wIdx);

		OffsetOut.ar(0,LeakDC.ar(out));

}).add)

// /////////////////////////////////////////////////////////////
// https://www.jstor.org/stable/3680063?origin=JSTOR-pdf&seq=1


// Basic Karplus Strong Algorithm + allpass filter for tuning
(SynthDef(\ksTuned,
	{
		|freq=440.0|
		var buf=LocalBuf.new(1024).clear;
		var idxMem=LocalBuf.new().clear;

		//previous values of:  twopoint filter, allpass outputs
		var filtOutMem=LocalBuf.new(1).clear;
		var filtOutMem1=LocalBuf.new(1).clear;
		var pF1=0.0,pF2=0.0;
		// //////////
		// read/write indexes
		var rIdx=0.0,rIdx2=0.0,wIdx=0.0;

		// delaysamps
		var delay=SampleRate.ir()/ freq;
		// frequency in radians
		var radFreq=2pi*freq;

		var sig=0.0;

		//allpass filter coefficient, integer delay, fractional delay
		var cAll=0.0, nD=0.0, fD=0.0;

		var envelope1,impulse,input;
		var out=0.0,allpass=0.0;




		//previous value of two point average
		pF1=Duty.ar(SampleDur.ir,0,Dbufrd(filtOutMem,0));
		//previous value of AllPass output
		pF2=Duty.ar(SampleDur.ir,0,Dbufrd(filtOutMem1,0));

		// write and read indexes
		wIdx=Duty.ar(SampleDur.ir,0,Dbufrd(idxMem,0));
		delay.poll(label:\samps);
		// the integer index has to compensate for phase delay of the two point average filter =0.5
		// plus an infinitesimal offset
		nD=( delay -0.5-0.0001 ).floor;

		nD.poll(label:\nd);
		fD= (delay-nD-0.5);
		// allpass coefficient for fractional delay
		cAll= (((radFreq*SampleDur.ir)-(radFreq*SampleDur.ir*fD))*0.5).sin;
		cAll= cAll/ ((((radFreq*SampleDur.ir)+(radFreq*SampleDur.ir*fD))*0.5).sin);

		cAll.poll(label:\coef);


		// N point delay
		rIdx=((wIdx+1024.0)-(nD)).mod(1024.0).floor;
		// N+1 point delay
		rIdx2=(rIdx+1023.0).mod(1024.0).floor;

		// envelope for input signal
		impulse=Impulse.ar(1.0);
		envelope1=EnvGen.ar(Env.perc(0.001,0.2),impulse-0.001);


		//twopoint average filter
		sig=Duty.ar(SampleDur.ir,0,0.5*((Dbufrd(buf,rIdx))+(Dbufrd(buf,rIdx2)))).poll(label:\sig);






		allpass= (cAll * sig) + pF1 -(cAll * pF2);

		out=allpass.poll(label:\all);

		// write filter outputs to memory

		pF1=Duty.ar(SampleDur.ir,0,Dbufwr(sig,filtOutMem,0));

		pF2=Duty.ar(SampleDur.ir,0,Dbufwr(allpass,filtOutMem1,0));


		// write signal to delay line
		sig=Duty.ar(SampleDur.ir,0,Dbufwr(allpass+(WhiteNoise.ar()*envelope1),buf,wIdx));

		// increment pointer and write to memory
		wIdx=(wIdx+1.0).mod(1024.0);
		wIdx=Duty.ar(SampleDur.ir,0,Dbufwr(wIdx,idxMem,0));

		Out.ar(0,out);

}).add)




(
x=Synth(\ksTuned);
)

// /////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////




// /////////////////////////////////////////////////////////////
//https://www.jstor.org/stable/3680063?origin=JSTOR-pdf&seq=1

b=Buffer.alloc(s,100,1);
u=Buffer.alloc(s,100,1);
b.free
(SynthDef(\testK,{|freq=440.0|

	var buff=b.clear;
	var buff1=u.clear;
	var ib=LocalBuf.new().clear;
	var iib=LocalBuf.new().clear;
	var idx=0.0,i2=0.0,b1,b2;
	idx=Duty.ar(SampleDur.ir,0,(Dbufrd(ib,0)));
	i2=Duty.ar(SampleDur.ir,0,(Dbufrd(iib,0)));


	(idx/100.0).scope;
	b1= Duty.ar(SampleDur.ir,0,Dbufwr(idx,buff,idx.mod(100)));
	b2=Duty.ar(SampleDur.ir,0,Dbufwr(i2,buff1,idx.mod(100)));


	i2= Duty.ar(SampleDur.ir,0,Dbufwr(idx.mod(100),iib,0));
	idx= Duty.ar(SampleDur.ir,0,Dbufwr((idx+1).mod(100),ib,0));



}).add)
b.asArray[0..100]
a=[]
t=[]
a
b.getToFloatArray(0,100,0.1,3,{|ar|a=ar})
u.getToFloatArray(0,100,0.1,3,{|ar|t=ar})
(a-t).plot

(
x=Synth(\testK);
)


// /////////////////////////////////////////////////////////////

// C++ versions:
// https://www.jstor.org/stable/3680063?origin=JSTOR-pdf&seq=1
// - tunable string



(SynthDef(\KStr,{
	|freq=440.0,fb=0.9|

	var impulse=Impulse.ar(0.5);
	var	envelope1=EnvGen.ar(Env.perc(0.001,0.2),impulse-0.001);
	var sig=envelope1*WhiteNoise.ar();

	var del=Duty.ar(SampleDur.ir,0,1.0/freq).poll;
	fb=Duty.ar(SampleDur.ir,0,fb).poll;

	sig=KStrong.ar(sig,del,fb);
	Out.ar(1,sig);
}).add)


// /////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////

// - tunable string with decay and stretch control
// https://www.jstor.org/stable/3680063?origin=JSTOR-pdf&seq=1

(
SynthDef(\KStrD,{
	|freq=440.0,freq2=200.0,mAmp=0.5,ro=0.9,s=0.5|

	var impulse=Impulse.ar(0.8);
	var	envelope1=EnvGen.ar(Env.perc(0.1,0.1),impulse-0.001);

	var	envelope2=EnvGen.ar(Env.perc(0.1,0.06),impulse-0.001);
	var sig=envelope1*WhiteNoise.ar();

	var del=Duty.ar(SampleDur.ir,0,1.0/(freq+ (mAmp*envelope2*SinOsc.ar(freq2))  )).poll;
	ro=Duty.ar(SampleDur.ir,0,ro).poll;
	s=Duty.ar(SampleDur.ir,0,s).poll;
	sig=MoogLadder.ar(sig,freq+(freq*10.0*envelope2),0.9);

	sig=( (KStrongDecay.ar(sig,del,ro,s)));
	Out.ar(1,LeakDC.ar(sig.tanh));
}).add

)

(
y=Synth(\KStrD);

)
y.set(\freq,320,\ro,0.9999,\s,0.27,\mAmp,0.11,\freq2,640.0)

// /////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////

(
x=Synth(\ks);
)

(
y=Synth(\KStr);
)

(
z=Synth(\fbK);
)

b.plot
