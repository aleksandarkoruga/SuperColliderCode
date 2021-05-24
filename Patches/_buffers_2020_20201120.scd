// dumpClassSubtree to see all children

//~globalMemory is an array of consecutive buffers
//~globalMemory[0,4] ++ ~globalMemory[3..3] works, not gm[singlenumber]++gm[singlenumber]


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
~oscWin.free





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



~intensityMap=16.collect({|i|(i).asBinaryDigits(16.nextPowerOfTwo.log2.asInt).reverse.convertDigits(2) });

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

		var times=((5..63).reciprocal*oneBar); //~stepData[0][2];//~stepData[0][2]
		//var order=(0..(((~stepData[0][1]).size)-1));
		var rdPtr;
		var totalTime=oneBar*nBars;
		// take wrPtr from bus
		var wrPtr; /// BufFrames.kr(buffer));//rescale 0-1 for warp1
		var ccInput= Lag.kr( ~busFX.kr(6,4),0.2);
		var freqCorrection=0.0;
		var bufTime=BufDur.kr(buffer);
		var sRate=SampleRate.ir.reciprocal;
		var ttOffset,tOffset;
		var mix;
		//var env= EnvGate.new();
		var timeScale;
		var demandTimes;
		var intensity;
		var trigEn,trigC=0.0;
		var intStream,probInt,dTimes;
		//var sequence=~stepData[0][1].integrate.mod(1.0).rotate(1);


		var sequence,intT;
		var sequence2;
		var overlap;
		var cuts;

		//try CC
		freqScale=(ccInput[0].linexp(0.0,127.0,0.001,4.0).round(0.00125)* (scale.reverse)).clip(0.00125,4.0);
		windowSize=ccInput[1].linexp(0.0,127.0,sRate,oneBar*nBars);

		timeScale=(ccInput[2].linexp(0.0,127.0,0.00625,2.0)).round(0.000625);
		modAmt=ccInput[3].linlin(0.0,127.0, 0.0,1.0);

		focus=ccInput[4].lincurve(0.0,127.0,0.0,8.0,4.5);
		which=ccInput[5].linlin(0.0,127.0,0.0,7.0);



		//scale=Duty.ar(SampleDur.ir,0,{scale.ratios.foldExtend(8)});


		overlap=(10.0/windowSize).clip(1,4).round(1.0);


		//overlap.poll;
		SendReply.kr(Impulse.kr(0.3,add:-0.1),'/envBufT',overlap);
		//overlap=4;

	//	times=times*timeScale;
		//2 parameters for input mix  params-selectXfocus
		//1 divisor
		//1 length

		wrPtr=((In.ar(~globalPointer.index,1)));
		intensity=Duty.ar(SampleDur.ir,0, ~intensityMap);
		intStream=Select.ar(((   (wrPtr.mod((nBars*timeScale).reciprocal)*((nBars*timeScale)))    *16.0).clip(0,15)),intensity);


		intT=Changed.ar((intStream),0.5);
		// if step intensity > than a random intensity thresh then trigger
		probInt=Gate.ar( ((4.0+WhiteNoise.ar(12).abs)<intStream),(intT-0.01) ).round(1.0).clip(0,15);


		//sequence2=Dreset(Dxrand( Array.series((1+64.rand),1.0,(12.rand+1)  ).reciprocal,inf   ),intT  );

		// sequence of time values
		demandTimes={Dreset( Dxrand(times,inf),intT)}!8;
		//demandTimes.poll;

		// sequence of fractions
		sequence= Dreset(Dxrand(  (Array.series((1+64.rand),1.0,(12.rand+1)     )  .reciprocal),inf   ),intT  );

		sequence=( Duty.ar( demandTimes*intStream,0,sequence!8));

		//
		//use .round!!!
		ttOffset=DemandEnvGen.ar(  [  (sequence ),(demandTimes)] ,(((demandTimes.reciprocal).rand+1.0)* demandTimes ),0,0,1,levelBias:Dxrand({ nBars.rand }!8,inf),timeScale:timeScale);    //level bias offsets for bars, so 1 sequence is 1 bar long always



		// -> toffset -> 0.0-nBars

		//windowSize=windowSize*timeScale;
		//freqScale=freqScale/timeScale;


		//seq of fractions
		ttOffset[0]=ttOffset[0]/nBars;

		dTimes=( Duty.ar( demandTimes*(ttOffset[0].reciprocal),0,demandTimes));


//Diwhite(1, demandTimes.clip(0.001,1024.0).reciprocal, inf)
		//
		trigEn= WaveLoss.ar(Trig.ar(   Changed.ar(ttOffset[0],0.001)   -0.1,ttOffset[1]),(ttOffset[0].reciprocal).rand ,(ttOffset[0].reciprocal).rand);

		//rate=(~bpmBus.kr/startBpm)*(1.0/length); //correct rate for current bpm
		// check total time for duty...
		//~globalMemoryRate



		//freqScale=freqScale+(randAmt*  (Duty.ar(Changed.ar(ttOffset[0]),0,Dwhite(0.25,2.0,inf))));


		trigC=(PulseCount.ar(( ((Sweep.ar((0.8-((trigEn*10.0).tanh)),dTimes).mod(dTimes.reciprocal)) )-0.0001), Changed.ar(ttOffset[0],0.001)));


		//1.0+PulseCount.ar((0.8-((trigEn*10.0).tanh)) , Changed.ar(ttOffset[0],0.001) );




		tOffset=  (((ttOffset[0]*modAmt)+((trigC*(sequence.rotate(5.rand)))*(1.0-modAmt)) ));




		//bufTime=BufFrames.ir(buffer)*SampleRate.ir().reciprocal;BufDur
		//redefine the read functions for adapting to the amount of info in the buffer (~globalMemoryNBars)


		rdPtr=((   (wrPtr - ((tOffset))  )+1.0)).wrap(0.0,1.0);



		freqCorrection=ReplaceBadValues.ar( BufRd.ar(1,~globalMemoryRate,rdPtr*BufFrames.kr(~globalMemoryRate)),sub:1.0,post:0);

		freqScale=(freqScale* ReplaceBadValues.ar(freqCorrection.reciprocal,1.0,post:0));

/*
	signal=8.collect({|i|
			BufGrain.ar(Impulse.ar((windowSize.clip(0.001,oneBar*nBars)*8.0).reciprocal),windowSize.clip(0.001,oneBar*nBars),buffer[i],freqScale[i],rdPtr);

		});

		signal=8.collect({|i|
			Warp1.ar(1,buffer[i],rdPtr,freqScale[i],windowSize.clip(0.001,oneBar*nBars),windowRandRatio:randAmt);

		});
		*/

		randAmt=(DC.ar(0.000001)!8).exprand(0.001);
		//freqScale.poll(3);
		//scale.poll(4);

		cuts=[BufRd.ar(1,buffer[6], rdPtr[6]*BufFrames.ir(buffer[6])),BufRd.ar(1,buffer[7], rdPtr[7]*BufFrames.ir(buffer[7]))];


	signal=[Warp1.ar(1,buffer[0],rdPtr[0],freqScale[0],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt),
			Warp1.ar(1,buffer[1],rdPtr[1],freqScale[1],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt),
			Warp1.ar(1,buffer[2],rdPtr[2],freqScale[2],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt),
			Warp1.ar(1,buffer[1],rdPtr[3],freqScale[3],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt),
			Warp1.ar(1,buffer[4],rdPtr[4],freqScale[4],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt),
			Warp1.ar(1,buffer[5],rdPtr[5],freqScale[5],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt),
			Warp1.ar(1,buffer[6],rdPtr[6],freqScale[6],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt),
			Warp1.ar(1,buffer[7],rdPtr[7],freqScale[7],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt)];


		signal=signal*((balance)+((1.0-balance)*(   Mix.ar([Slew.ar(Trig.ar(Changed.ar(ttOffset[0])-0.1,ttOffset[1]),400,4.0),((Amplitude.ar(((In.ar(~bus.index,4))++(In.ar(30,2)  )++(In.ar(28,2)  ))))*(1.0-probInt)).tanh,Slew.ar(probInt,400.0,20.0)]).tanh)));


		mix=[ SelectXFocus.ar(which,signal,focus,true),SelectXFocus.ar((7.0-which),signal,focus,true)];

		//cuts.poll;
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