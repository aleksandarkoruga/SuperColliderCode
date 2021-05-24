// dumpClassSubtree to see all children

//~globalMemory is an array of consecutive buffers
//~globalMemory[0,4] ++ ~globalMemory[3..3] works, not gm[singlenumber]++gm[singlenumber]


UGen Array [0]: 0
UGen Array [1]: 0
UGen Array [2]: -0.000189854
UGen Array [3]: 0
UGen Array [4]: -9.61707e-05
UGen Array [5]: 7.53883e-06
UGen Array [6]: 9.37999e-08
UGen Array [7]: 0


// util for editing and adding the synths
(


~addChopDefFunc={SynthDef(\chop,~chopFunc2.value).add};
~addChopDefInFunc={SynthDef(\chopIN,~globalMemoryWriteFunc.value).add};


~addChopDefFunc.value;

~addChopDefInFunc.value;
)
//2 channels for each buffer first is for data second for rate at which it was written
// do not use 2channel buffers, implement a global memory for rate and in future implementations rates can be different so 8 channel rate buffer...done.
~windowBuf.plot
~addChopDefFunc.value;

~chopSynth.free;
~chopSynth= Synth.after(~chopSynthIn,"chop");


//an OSCfunc to see if the overlap change message works
x=OSCFunc({ |msg| var over= msg[msg.size-1];
	over.postln
}, '/envBufT');
~windowBuf.plot





///MAIN///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
(


~windowBuf=Buffer.alloc(s,1024);
~chopWindowFunc= {|size=1024,env=\hammingWindow,extend=0.5|
	var window;
	var minMax;

	size=size.clip(8,2048);
	extend=(extend.clip(0.0,1024.0)*size).asInteger;
	window=("Signal."++env++"("++ size.asString ++")").interpret;
	minMax=[window.reduce('min'),window.reduce('max')];

	window=(window)[(0..window.indexOf(minMax[1]))];

	(((window++ (minMax[1]!extend)++window.reverse)-minMax[0]).resamp1(size));
	};
~windowBuf.sendCollection(~chopWindowFunc.value(~windowBuf.numFrames,extend:12.0 ));


~oscWin=OSCFunc({ |msg| var over= msg[msg.size-1];

	~windowBuf.sendCollection(~chopWindowFunc.value(~windowBuf.numFrames,extend: (16-(over*4)).asFloat ));
	~chopSynth.set(\envBuf,~windowBuf);
}, '/envBufT');



~intensityMap=128.collect({|i|(i).asBinaryDigits(128.nextPowerOfTwo.log2.asInt).reverse.convertDigits(2) });
//~intensityMap=16.collect({|i|(i).asBinaryDigits(16.nextPowerOfTwo.log2.asInt).reverse.convertDigits(2) });




~globalMemoryWriteFunc={var returnFunc={

	//rate has to depend on the ratio between current bpm ~bpmBus and the number of desired bars
	//  time of 1 bar (always keepeing it 4/4) is
	var tBar=  (240/~bpmBus.kr);
	//total time required considering also the specification of ~globalMemoryNBars multiplier
	var  t= tBar*~globalMemoryNBars.kr;
	var  tBuf=BufDur.kr(~globalMemory); // total time of the buffer at 1.0*sample rate

	// write rate should be corrected so wrPtr writes t time to buffer instead of tBuf
	var rate= tBuf/t;
	var digitalIn=In.ar(~bus.index,6);

//Machinedrum from analog 1/2 computer 5/6 -> 4/5 sc output motu 0-23  motu input 24-47
	var	input=([(LeakDC.ar(Mix.ar(digitalIn[(0..1)])).tanh)]++[(LeakDC.ar(Mix.ar(digitalIn[(2..3)])).tanh)]++[(LeakDC.ar(Mix.ar(digitalIn[(4..5)])).tanh)]++(In.ar(32,2))++(In.ar(30,1))++(In.ar(28,2)  )   );


	// use a trigger for re-alligning the pointer to a "0" (implement a cc on kr bus for retriggering this) -> implement trig bus  ~retrigT=Bus.kr(s,1)  already implemented in chop func for env triggering  ~retrigT=Trig.kr(midion/off(1,-1))
	var ptrTrig=~retrigTime.kr;
	//phasor retrig jumps to specified position (0)
	var wrPtr=Phasor.ar(ptrTrig, (BufRateScale.kr(~globalMemory) * rate), 0.0, BufFrames.kr(~globalMemory));
	var wrPtr2=Phasor.ar(ptrTrig, (BufRateScale.kr(~globalMemoryRate) * rate), 0.0, BufFrames.kr(~globalMemoryRate));
	// write pointer to pointer bus, all 8 pointers are equal, can use this potential differentiation of writing indexes for future implementations.
	OffsetOut.ar(~globalPointer,(wrPtr[0]/BufFrames.kr(~globalMemory[0])));



	// write input to buffer,BufWr does not do multichannel expansion so needs a do
	~globalMemory.do({|buf,n|
		BufWr.ar(input[n]*0.125,buf,wrPtr[n],1);
	});
	//save rate at which the sample was written for reading re-scaling

	~globalMemoryRate.do({|buf,n|
		BufWr.ar( Duty.ar(SampleDur.ir,0,rate[n])   ,buf,wrPtr2[n],1);
	});

	// write (In.ar(~bus.index,6)) to Motu out so audio bus goes also directly to output
	OffsetOut.ar(0,In.ar(~bus.index,6));

};

	returnFunc;

};







// use SelectXFocus to select which buffer to chop when
~chopFunc2={
	var returnFunc={          //4 ccs+trig an envelope for dry/wet ,2 ccs for reverb times from to random amt, rev= 1-amp(clear), all revs go to chop.
		|gatein=1,freqScale=0.5,windowSize=0.12,randAmt=0.0,modAmt= 0.0,focus=7.0,which=7,balance=0.5,envBuf= -1,scale= #[ 1, 1.1224620483089, 1.2599210498937, 1.3348398541685, 1.4983070768743, 1.6817928305039, 1.8877486253586, 1.6817928305039 ]|

		var buffer= ~globalMemory;
		var pointer=~globalPointer;
		var out=~bus.index+6;
		var nBars=~globalMemoryNBars.kr;
		var oneBar=240.0/~bpmBus.kr;
		var signal;

		var rdPtr;
		var totalTime=oneBar*nBars;

		var wrPtr; /// BufFrames.kr(buffer));//rescale 0-1 for warp1
		var ccInput= Lag.kr( ~busFX.kr(6,4),0.2);
		var nBarSet= ~busFX.kr(1,11);
		var ticks=~tickBus.kr;
		var freqCorrection=0.0;
		var bufTime=BufDur.kr(buffer);
		var sRate=SampleRate.ir.reciprocal;
		var tOffset;
		var mix;
		//var env= EnvGate.new();
		var density,modulation;

		var intensity=LocalBuf.newFrom(~intensityMap);
		var intStream;
		var intT;
		var overlap;
		var cuts;
		var barPtr,mainEnv;
		var func;
		var modT;
		var trigDensity;
		var donePhasors=LocalBuf.newFrom((1.0!8)),dMem;
		var modTime;
		var intMod;

		Out.kr(~globalMemoryNBars,nBarSet.linlin(0.0,127.0,0.125,64.0).round(0.125));

		//try CC

		intMod=balance.linlin(0.0078125,1.0,0.25,128.0).round(0.25);

		freqScale=(ccInput[0].linexp(0.0,127.0,0.001,4.0).round(0.00125)* (scale.scramble)).clip(0.00125,4.0).foldExtend(8);
		windowSize=ccInput[1].linexp(0.0,127.0,sRate,oneBar*0.5);

		density=(ccInput[2].linlin(0.0,127.0,0.0,7.0));
		density=(128-2.pow( density).round(1.0));
		trigDensity=ccInput[2].linlin(0.0,127.0,0.0,1.0);

		modAmt=ccInput[3].linexp(0.0,127.0, 0.00001,1.0)-0.00001;

		focus=ccInput[4].lincurve(0.0,127.0,0.0,8.0,4.5);
		which=ccInput[5].linlin(0.0,127.0,0.0,7.0);


		//scale=Duty.ar(SampleDur.ir,0,{scale.ratios.foldExtend(8)});

		overlap=(1.0/windowSize).clip(1,4).round(1.0);



		SendReply.kr(Impulse.kr(0.3,add:-0.1),'/envBufT',overlap);


		wrPtr=((In.ar(~globalPointer.index,1)));

		barPtr= (Phasor.ar((ticks-1).clip(-1,0).abs-0.001,SampleDur.ir*((oneBar*intMod).reciprocal) )*128.0).clip(0.0,127.0);



		intStream=Index.ar(intensity,barPtr).floor;//0->128



		intT=Changed.ar((intStream),0.5);

		modT=intT;
		// when there's a trigger filter it by having clipped white noise with a multiplier, it returns or not a trigger multiply (and) if the degree of intensity of current step is high enough to trigger

		dMem=8.collect({|i| BufRd.ar(1,donePhasors,DC.ar(i),1,0)  });


		//Latch.ar(  ({(WhiteNoise.ar().abs*4.0).round(1.0).clip(0,1)}!8)  ,intT-0.001)
		intT=intT*((intStream-density).clip(0,1));
		intT=  (SetResetFF.ar((intT!8),((1.0-dMem)-0.001)));


		// Line used to initialize the trigger feedback system;
		//(((Latch.ar(  (({(WhiteNoise.ar().abs*4.0).round(1.0).clip(0.0,1.0)}!8)+intT),modT-0.001))))
		modT=(intT+Line.ar(1,-0.1,0.001) ).clip(0.0,1.0);

		//modT= intT; //SetResetFF.ar(modT-0.01,(1.0-dMem)-0.001);



		//index in between==index of a lower weighted beat
		tOffset=((((barPtr+128.0)- IndexInBetween.ar(intensity, 8.collect( {WhiteNoise.ar().abs*intStream})).floor).mod(128.0))/ (128.0*nBars.clip(1.0,inf)));



		tOffset=Latch.ar(tOffset,intT-0.001)*Latch.ar({WhiteNoise.ar().abs.round(1.0)}!8, intT-0.001);

		// select a random previous bar
		tOffset= ((tOffset)+ (( (1.0/(nBars.clip(1.0,inf))) * Latch.ar(({(WhiteNoise.ar().abs*nBars).round(1.0)}!8),intT-0.001)).clip(0.0,1.0) ));




		//modulation=Phasor.ar(modT-0.001,sRate *Latch.ar(8.collect({ (1.0/(oneBar*nBars)) }),intT-0.001)*(((balance*16.0).round(0.05))),0.0, (Latch.ar(({(WhiteNoise.ar()*16.0).abs.add(1.0).round(1.0).clip(1.0,16.0)}!8),intT-0.001)*nBars).reciprocal ).lincurve(0.0,1.0,0.0,1.0,Latch.ar(({1.0*WhiteNoise.ar()}!8),intT-0.001))	*modAmt;

		modTime=(Latch.ar((({(WhiteNoise.ar()).range(0.125,1.0).round(0.125)}!8)*(intMod/128))*oneBar,modT-0.001));

		modulation=Phasor.ar(modT-0.001,SampleDur.ir/modTime,0.0,1.0)*(modAmt.round((nBars.clip(1,inf)*16.0).reciprocal));
		//(Latch.ar(({(WhiteNoise.ar().abs).range(0.125,16.0).round(0.125).clip(0.125,16.0)}!8),modT-0.001))*(nBars.reciprocal)

		//dMem=8.collect({|i|  TDelay.ar(modT.at(i)-0.001,modTime.at(i))  });

		dMem=8.collect({|i|  (Phasor.ar(modT.at(i)-0.001,SampleDur.ir/modTime.at(i),1.0,-0.1))  });

		dMem=(dMem*1000.0).clip(-0.01,1.0);// transform into a gate


	//	mainEnv=EnvGen.ar(Env.asr(0.001,1.0,modTime*0.1),dMem);


		mainEnv=EnvGen.ar(Env.asr(0.001,1.0, Latch.ar(modTime,modT-0.001)/32.0  ),Trig.ar(modT-0.001,Latch.ar(modTime,modT-0.001)));







	//	dMem.collect({|item| PulseCount.ar( item)});

		dMem=8.collect({|i|  BufWr.ar(   (dMem.at(i)), donePhasors, DC.ar(i)  )  }) ;

		//;.clip(0.5,1.0).linlin(0.5,1.0,0.0,1.0));//Latch.ar(({WhiteNoise.ar()}!8),intT-0.001)/(nBars)

		//


		//modulation=modulation+(modAmt.clip(0.0,0.5).linlin(0.0,0.5,1.0,0.0))*SinOsc.ar(modFreq);

		//EnvGen.ar(Env.perc(),intT-0.001);





		rdPtr=(  (8.collect(wrPtr) - (tOffset)+modulation  )+4.0).mod(1.0);




		freqCorrection=ReplaceBadValues.ar( BufRd.ar(1,~globalMemoryRate,rdPtr*BufFrames.kr(~globalMemoryRate)),sub:1.0,post:0);

		freqScale=(freqScale* ReplaceBadValues.ar(freqCorrection.reciprocal,1.0,post:0));



		randAmt=(DC.ar(0.000001)!8).exprand(0.001);

		cuts=[BufRd.ar(1,buffer[6], rdPtr[6]*BufFrames.ir(buffer[6])),BufRd.ar(1,buffer[7], rdPtr[7]*BufFrames.ir(buffer[7]))];


	signal=[Warp1.ar(1,buffer[0],rdPtr[0],freqScale[0],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[0]),
			Warp1.ar(1,buffer[1],rdPtr[1],freqScale[1],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[1]),
			Warp1.ar(1,buffer[2],rdPtr[2],freqScale[2],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[2]),
			Warp1.ar(1,buffer[1],rdPtr[3],freqScale[3],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[3]),
			Warp1.ar(1,buffer[4],rdPtr[4],freqScale[4],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[4]),
			Warp1.ar(1,buffer[5],rdPtr[5],freqScale[5],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[5]),
			Warp1.ar(1,buffer[6],rdPtr[6],freqScale[6],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[6]),
			Warp1.ar(1,buffer[7],rdPtr[7],freqScale[7],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[7])];

signal=signal*mainEnv;
		//signal=signal*((balance)+((1.0-balance)*(  mainEnv)));
//[Slew.ar(Trig.ar(Changed.ar(ttOffset[0])-0.1,ttOffset[1]),400,4.0),((Amplitude.ar(((In.ar(~bus.index,4))++(In.ar(30,2)  )++(In.ar(28,2)  ))))*(1.0-probInt)).tanh,Slew.ar(probInt,400.0,20.0)]

		mix=[ SelectXFocus.ar(which,signal,focus,true),SelectXFocus.ar((7.0-which),signal,focus,true)];


		OffsetOut.ar(out,(mix++cuts));
		//WaveLoss + threshold for gate regulated by beat probability (binary accents). +rescale times


//DELETE CHOPTRIG!!!!!!!!!!!!!!!

		//outEnv=EnvGen.ar(Env.adsr(1.4,0.0,0.7,1.4),~chopTrig.kr);

		//out to MOTU busses from chan 3-> 0 based in sc

		//OffsetOut.ar(0,(([0,0])++((ReplaceBadValues.ar((Mix.ar([Mix.ar(signal)*outEnv,Mix.ar(input)*(1.0-outEnv)])*0.5).tanh))!2)++ In.ar(~bus.index,6)  ));

		//OffsetOut.ar(out,[(ReplaceBadValues.ar((Mix.ar([Mix.ar((signal[0..2]++signal[6]))*outEnv])*0.5).tanh)),(ReplaceBadValues.ar((Mix.ar([Mix.ar((signal[3..5]++signal[7]))*outEnv])*0.5).tanh))]  );


	};
returnFunc;

};

)