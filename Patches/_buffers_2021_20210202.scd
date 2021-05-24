// dumpClassSubtree to see all children

//~globalMemory is an array of consecutive buffers
//~globalMemory[0,4] ++ ~globalMemory[3..3] works, not gm[singlenumber]++gm[singlenumber]
Buffer

12.collect({|i|  ~busFX.getSynchronous(i).postln})


UGen Array [0]: 0
UGen Array [1]: 0
UGen Array [2]: -0.000189854
UGen Array [3]: 0
UGen Array [4]: -9.61707e-05
UGen Array [5]: 7.53883e-06
UGen Array [6]: 9.37999e-08
UGen Array [7]: 0

m = NetAddr("127.0.0.1", NetAddr.langPort);
m.sendMsg('\chopIDT',[0.51,0.4])

128*8
~chopSeqBuf.sendCollection( (0.0!1024) );

x={}.play

x.kill

s.freeAll
~windowBuf.plot
~addChopDefFunc.value;

~chopSynth.free;
~chopSynth= Synth.after(~chopSynthIn,"chop");


//an OSCfunc to see if the overlap change message works
x=OSCFunc({ |msg| var over= msg[msg.size-1];
	over.postln
}, '/envBufT');
~windowBuf.plot
~chopSeqBuf.loadToFloatArray(action: { arg array; a = array.postln; {a.plot;}.defer; "sequence".postln;});

~chopSeqBuf.plot


s.hasShmInterface




// util for editing and adding the synths
(


~addChopDefFunc={SynthDef(\chop,~chopFunc2.value).add};
~addChopDefInFunc={SynthDef(\chopIN,~globalMemoryWriteFunc.value).add};


~addChopDefFunc.value;

~addChopDefInFunc.value;
)




///MAIN///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
(
~chopSeqBuf.free;

~windowBuf.free;
~oscWin.free;





~weightFunc={
	|pattern,base=2|

	var size=pattern.size;
	var nBits= ((NumericalExtensions.logN(size-1,base).floor)+1);
	var mask=
	pattern.size.collect({|i|  i.asDigits(base,nBits).reverse.convertDigits(base)  });

	if(pattern.size>30,
		{
			NumericalExtensions.convertDigitsFloat((pattern[mask.order].reverse),2)

		}

		,{pattern[mask.order].reverse.convertDigits(2)})
};

~revWeightFunc={
	|num,size=16,base=2|

	var nBits= ((NumericalExtensions.logN(size-1,base).floor)+1);
	var mask=size.collect({|i|  i.asDigits(base,nBits).reverse.convertDigits(base)  });



	var maskOrdered=mask.deepCopy;

	mask.order.do({|item,i|
		/*item is the index givven by .order, i is the progressive index to pad sequences not multiple of base power*/
		maskOrdered.put(item,i)
	});



	(  (NumericalExtensions.toBinaryArray(num,size).reverse)[maskOrdered])

};





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

	//not needed?
	//~chopSynth.set(\envBuf,~windowBuf);

}, '/envBufT');


// working on fixed 128 division of length, base 2 intensity
~intensityMap=32.collect({|i|(i).asBinaryDigits(32.nextPowerOfTwo.log2.asInteger).reverse.convertDigits(2) });
~chopSeqBuf=Buffer.alloc(s,(32*8));
~chopSeqBuf.zero;



~oscDensityFunc.free;

//IDT=intensity/density trigger;
~oscDensityFunc=OSCFunc({
	|msg|
	var density= msg[msg.size-9].clip(0.0,1.0),intensity=msg[((msg.size-8)..(msg.size-1))].clip(0.0,1.0);
	var seq;
	var dFunc={
		|density=0.5,intensity=0.5,size=32|

		var res,delta;
		var signDelta,counter=0;

		density=(density*size).asInteger;
		intensity=(2.pow(size))*intensity;


		// convert to binary number the intensity
		res=NumericalExtensions.toBinaryArray(intensity,size).floor.asInteger;
		// put lsb first -> re reverse sequence after substituting  zeroes or ones
		res=res.reverse;
		// using intensity function-> intensity value has same number of zeroes/ones as the rappresented sequence
		// if delta negative-> density of intensity func (res)> target density -> take away the amount of lsb otherwise add
		// by doing that the new intensity is calculated with a sequence that has the target density and nearest intensity

		delta=density-res.sum;
		signDelta=delta.sign;

		delta=delta.abs;

		//signDelta becomes the target bit state to control
		if(signDelta<0,{signDelta=1},{signDelta=0});

		res=res.collect({ |item,idx| if(counter<delta,{if((item)==(signDelta),{counter=counter+1;counter;(1-signDelta)},{item})},{item}) ; });
		// re flip lsb
		res=res.reverse;
		res=NumericalExtensions.convertDigitsFloat(res,2);

		~revWeightFunc.value(res,size,2);

	};
	//msg.postln;
	//intensity.postln;
	// get sequence
	seq= intensity.collect({|item|dFunc.value(density,item,32)} );

	//update buffer
	~chopSeqBuf.sendCollection(seq.flat);

	//{|msg| 0.01.wait; }
	//~chopSynth.set(\intensityBuf,~chopSeqBuf);

},'/chopIDT');










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
		|gatein=1,freqScale=0.5,windowSize=0.12,randAmt=0.0,modAmt= 0.0,focus=7.0,which=7,balance=0.5,envBuf= (~windowBuf),scale= #[ 1, 1.1224620483089, 1.2599210498937, 1.3348398541685, 1.4983070768743, 1.6817928305039, 1.8877486253586, 1.6817928305039 ],intensityBuf=(~chopSeqBuf)|

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
		var intensityC;
		//var donePhasors=LocalBuf.newFrom((1.0!8)),dMem;
		var modTime;
		var intMod;

		// set the global parameter of number of bars from machinedrum;
		Out.kr(~globalMemoryNBars,nBarSet.linlin(0.0,127.0,0.125,64.0).round(0.125));




		intMod=balance.linlin(0.0078125,1.0,0.25,128.0).round(0.25);

		freqScale=(ccInput[0].linexp(0.0,127.0,0.001,4.0).round(0.00125)* (scale)).clip(0.00125,4.0).foldExtend(8);
		windowSize=ccInput[1].linexp(0.0,127.0,sRate,oneBar*0.5);

		//0-32.0
		intensityC=(8.collect({(2.0).pow( ((ccInput[2].linlin(0,127,0.0,0.99212598425197))+(WhiteNoise.kr((1.0/127.0)))).linlin(0.0,1.0,0.0,5.0))}))/32.0;


		density=(~busFX.kr(1,12).linlin(0,127,0.0,0.99212598425197))+(WhiteNoise.kr((1.0/127.0)));





		modAmt=ccInput[3].linexp(0.0,127.0, 0.00001,1.0)-0.00001;

		focus=ccInput[4].lincurve(0.0,127.0,0.0,16.0,4.5);
		which=ccInput[5].linlin(0.0,127.0,0.0,8.0);


		//scale=Duty.ar(SampleDur.ir,0,{scale.ratios.foldExtend(8)});

		overlap=(1.0/windowSize).clip(1,4).round(1.0);



		// trigger the grain envelope recalculation (if overlap changed)
		SendReply.kr(Impulse.kr(0.3,add:-0.1),'/envBufT',overlap);


		wrPtr=((In.ar(~globalPointer.index,1)));


		//0->128
		barPtr= (Phasor.ar((ticks-1).clip(-1,0).abs-0.001,SampleDur.ir*((oneBar*intMod).reciprocal) )*32.0).clip(0.0,32.0);




		intStream=Index.ar(intensity,barPtr.floor).floor;



		intT=Changed.ar((intStream),0.5);

		//intensityC=ccInput[2].linlin(0.0,127.0,0.0,1.0);
		//send density and intensity to OSCFunc to update the buffer
		SendReply.ar( ((intT*Trig.kr(Changed.kr(Lag.kr(density),0.0001)+Changed.kr(Lag.kr(intensityC),(0.0001))))-0.1)  ,'/chopIDT',([(density)]++intensityC));




		// trigger is the trigger of selected scale && (*)
		intT=intT*((8.collect({|i|  ((  Index.ar(intensityBuf,((barPtr.floor)+(32.0*i)))  -0.1)*10.0) })).clip(-0.1,1.0));



		modT=intT;

		//index in between==index of a lower weighted beat


		tOffset=  ((((barPtr+32.0)- IndexInBetween.ar(intensity, 8.collect( {WhiteNoise.ar().abs*intStream})).floor).mod(32.0))/ (32.0*nBars.clip(1.0,inf)));



		tOffset=Latch.ar(tOffset,((intT-0.001)));



		// select a random previous bar
		tOffset= ((tOffset)+ (( (1.0/(nBars.clip(1.0,inf))) * Latch.ar((8.collect({(WhiteNoise.ar().abs*nBars).round(1.0)})   ),intT-0.001)).clip(0.0,1.0) ));



		// mean event duration ((oneBar*intMod)/(density.linlin(0.0,1.0,1.0,32.0)) )
		// random gaussian of modulation (TGaussRand.ar(-1.0,1.0).abs)*(oneBar*intMod)+meanduration
		modTime=( (modT.collect( {|i| TGaussRand.ar(-1.0,1.0,i-0.01).abs } ))  *(oneBar*nBars)) +((oneBar*intMod)/(density.linlin(0.0,1.0,1.0,32.0)));






//(modAmt.round((nBars.clip(1.0,inf)*16.0).reciprocal))
		modulation=(Phasor.ar(modT-0.001,(SampleDur.ir/(modTime.clip(SampleDur.ir,inf)))*(modAmt*32.0),0.0,1.0));
		modulation=modulation.pow( Demand.ar(modT-0.01,0,Dbrown(0.25,3.0, SampleDur.ir*(modAmt.linlin(0.0,1.0,0.0001,100.0))  )) );
		//




		mainEnv=EnvGen.ar(Env.perc(0.001, Latch.ar(modTime,modT-0.001)  ),(modT-0.001));





		rdPtr=(  (8.collect(wrPtr) - (tOffset)-modulation  )+4.0).mod(1.0);




		freqCorrection=ReplaceBadValues.ar( BufRd.ar(1,~globalMemoryRate,rdPtr*BufFrames.kr(~globalMemoryRate)),sub:1.0,post:0);

		freqScale=(freqScale* ReplaceBadValues.ar(freqCorrection.reciprocal,1.0,post:0));



		randAmt=(DC.ar(0.000001)!8).exprand(0.001);

		cuts=[BufRd.ar(1,buffer[6], rdPtr[6]*BufFrames.ir(buffer[6]),interpolation:4),BufRd.ar(1,buffer[7], rdPtr[7]*BufFrames.ir(buffer[7]),interpolation:4)];


	signal=[Warp1.ar(1,buffer[0],rdPtr[0],freqScale[0],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[0]),
			Warp1.ar(1,buffer[1],rdPtr[1],freqScale[1],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[1]),
			Warp1.ar(1,buffer[2],rdPtr[2],freqScale[2],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[2]),
			Warp1.ar(1,buffer[1],rdPtr[3],freqScale[3],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[3]),
			Warp1.ar(1,buffer[4],rdPtr[4],freqScale[4],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[4]),
			Warp1.ar(1,buffer[5],rdPtr[5],freqScale[5],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[5]),
			Warp1.ar(1,buffer[6],rdPtr[6],freqScale[6],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[6]),
			Warp1.ar(1,buffer[7],rdPtr[7],freqScale[7],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[7])];
		signal=signal*mainEnv;



		mix=[ SelectXFocus.ar(which,signal,focus,true),SelectXFocus.ar((7.0-which),signal,focus,true)];


		OffsetOut.ar(out,(mix++cuts));


	};
returnFunc;

};

)



