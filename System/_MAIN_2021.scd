


NetAddr.langPort

(
s.options.numWireBufs=512;
s.options.numBuffers = 1024 * 256; // increase this if you need to load more samples
s.options.memSize = 4096 * 256; // increase this if you get "alloc failed" messages
s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
s.options.numAudioBusChannels = 1024 * 1024;
s.options.numControlBusChannels = 16384 * 32;


//ServerOptions.devices; //all devices
//ServerOptions.inDevices; //input devices~importMD
//ServerOptions.outDevices;
Server.default.options.sampleRate=48000;
Server.default.options.device="ASIO : MOTU Pro Audio";
Server.default.options.numInputBusChannels_(12);
Server.default.options.numOutputBusChannels_(24);
//Server.default.options;
s.boot;

)


(
~bela =NetAddr("11.11.1.34", 7562);

~chopSeqBuf.free;
~busK.free;
~bus.free;
~bpmBus.free;
~busFX.free;
~globalMemory.do(_.free);
~globalMemoryRate.do(_.free);
~globalPointer.free;
~globalMemoryNBars.free;
~chopTrig.free;
~retrigTime.free;
~irbuffer.free;
~irspectrum.free;
~synthParamBuf.do(_.free);
~synthTimeBuf.do(_.free);



~synthParamBuf=Buffer.allocConsecutive(3,s,(2048*4),1);
~synthTimeBuf=Buffer.allocConsecutive(3,s,(2048*4),1);




~globalMemory=Buffer.allocConsecutive(8,s,s.sampleRate*20,1);
~globalMemoryRate=Buffer.allocConsecutive(8,s,s.sampleRate*20,1);

~globalMemoryNBars=Bus.control(s,1);
~globalMemoryNBars.set(12.0);

~globalPointer=Bus.audio(s,1);



~bus=Bus.audio(s,10);
~busK=Bus.control(s,128);
~busFX=Bus.control(s,128);
~bpmBus=Bus.control;
~chopTrig=Bus.control;
~retrigTime=Bus.control;
~tickBus=Bus.control;
~tickBus.set(0.0);

~bus.index.postln;
~busK.index.postln;

~prevTick=0.0;
~bpm=120.0;
~bar=1.0;

// structure 0-63, fx 64-127
//~cc_StructureAndFx=64.0!128;

~busFX.set(
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64);
~busK.set(
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,
	64, 64, 64, 64,64, 64, 64, 64,
	64, 64, 64, 64);




//RESET MIDI
~noteOn.free;
~noteOff.free;
~cc.free;
~clockM.free;
~start.free;
~stop.free;





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





~deconvFunc={
		|sig1,sig2|
	var frameSize=2048;
	var hop=0.5;
	var chain1, chain2, chain3,chain3conj1,chain3conj2,chain4;
	var xCorr,deconvolved,morph;


	//comment next two lines to use as synthdef, uncomment to test
		//sig1= LFNoise2.ar(2.0).abs *SinOsc.ar((500+ (456* SinOsc.ar(678))));
		//sig2=LFNoise2.ar(6.0).abs*SinOsc.ar(600+30*SinOsc.ar(450));


		//input for tpv then output from morph
	morph=FFT(LocalBuf(frameSize), sig1);

		//signal needs to be delayed for reasons specified in a further comment
		sig1= DelayN.ar(sig1,0.2, frameSize*hop*SampleDur.ir);
		sig2= DelayN.ar(sig2,0.2, frameSize*hop*SampleDur.ir);


	//for cross correlation
	chain1=FFT(LocalBuf(frameSize), sig1);
	chain2=FFT(LocalBuf(frameSize), sig2);

	//fft operations write to the first buffer specified in the called PV object ("except" pv_copy) NOTE: As of SC 3.7 instances of PV_Copy are added automatically
	//nevertheless i find it useful to have an overview of which are the "source" chains and which i am modifying in parallel.
	//local copies of inputs for deconvolution
	chain3=PV_Copy(chain1,LocalBuf(frameSize));
	chain4=PV_Copy(chain2,LocalBuf(frameSize));

	//local copies of input conjugate, useful for calculation of deconvolution
	chain3conj1=PV_Conj(PV_Copy(chain1,LocalBuf(frameSize)));
	chain3conj2=PV_Conj(PV_Copy(chain1,LocalBuf(frameSize)));



	// //////////////////////////////////////// deconvolution
	//deconvolution with Tikhonov  regularization   http://www.ce.memphis.edu/7137/PDFs/signal%20Processing/deconv.pdf
	chain3conj1= PV_Mul(chain3conj1,chain4);
	chain3conj2=PV_Add(PV_Mul(chain3conj2,chain3) , 	FFT(LocalBuf(frameSize), WhiteNoise.ar.abs*0.001) );
	//this is the deconvolved result in fft form
	chain3conj1=PV_Div(chain3conj1,chain3conj2);
	deconvolved=chain3conj1;


	// //////////////////////////////////////// x correlation
	//cross-correlation
	chain1= PV_Conj(chain1);
	chain2= PV_Mul(chain1,chain2);
	//value of x-correlation
	xCorr=(1.0-(Amplitude.ar(IFFT(chain2),0.5,0.5) *(-1.0)).dbamp).clip(0.0,1.0);   //.scope.poll(label:"cross-correlation");



	// //////////////////////////////////////// morph
	//instead of using this as time-audio signal, use the fft version and morph it with the source
	//deconvolved=IFFT(chain3conj1);


	//xCorr = 0.5 probably noise , 0 distant in frequency 1 comlpetely correlated


	//noisefloor= 1-(2*(0.5-xCorr).abs) -> leave the range 0.5-1 in amplitude to pass through so 0.5- etc so if noise is present at xCorr=0.5 the floor is raised
	//frequency shift proportional to the correlation distance (morph has still the original input transform up until this point)
	morph= TPV.ar(morph,frameSize,frameSize*hop,80,40, 1.0/(0.5+((1-xCorr)*1.5)), (1-xCorr)*512, (0.5-((0.5-xCorr).abs)));

	//tpv at this point is a signal in time domain and in order to be morphed with the devconvolved signal needs to be re-transformed into frequency domain. This introduces a delay of the window size*hop which has to be compensated for in the input signal to the deconvolution and xcorrelation (DelayN)
	morph= FFT(LocalBuf(frameSize), morph);

	//morph the source with the deconvolved signal
	morph = PV_Morph(morph ,deconvolved ,xCorr);



	//output the morph between original and deconvolved
		(LeakDC.ar(IFFT(morph).tanh));


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

		var out_clear;
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
		barPtr= (Phasor.ar( ((ticks-1).clip(-1,0).abs)-0.001,SampleDur.ir*((oneBar*intMod).reciprocal) )*32.0).clip(0.0,32.0);




		intStream=Index.ar(intensity,barPtr.floor).floor;



		intT=Changed.ar((intStream),0.5);

		//intensityC=ccInput[2].linlin(0.0,127.0,0.0,1.0);
		//send density and intensity to OSCFunc to update the buffer
		SendReply.kr(PulseDivider.kr( intT-0.1,4,3)/*((intT*Trig.kr(Changed.kr(Lag.kr(density),1e-6)+Changed.kr(Lag.kr(intensityC),(1e-6))))-0.1)*/  ,'/chopIDT',([(density)]++intensityC));




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



		randAmt=(DC.ar(1e-5)!8).exprand(0.001);

		cuts= buffer.collect({|item,i|  Sanitize.ar(	BufRd.ar(1,item, rdPtr[i]*BufFrames.ir(item),interpolation:4))   });
		/*
		cuts=
		[
			Sanitize.ar(	BufRd.ar(1,buffer[0], rdPtr[0]*BufFrames.ir(buffer[0]),interpolation:4)),
			Sanitize.ar(	BufRd.ar(1,buffer[1], rdPtr[1]*BufFrames.ir(buffer[1]),interpolation:4)),
			Sanitize.ar(	BufRd.ar(1,buffer[2], rdPtr[2]*BufFrames.ir(buffer[2]),interpolation:4)),
			Sanitize.ar(	BufRd.ar(1,buffer[3], rdPtr[3]*BufFrames.ir(buffer[3]),interpolation:4)),
			Sanitize.ar(	BufRd.ar(1,buffer[4], rdPtr[4]*BufFrames.ir(buffer[4]),interpolation:4)),
			Sanitize.ar(	BufRd.ar(1,buffer[5], rdPtr[5]*BufFrames.ir(buffer[5]),interpolation:4)),
			Sanitize.ar(	BufRd.ar(1,buffer[6], rdPtr[6]*BufFrames.ir(buffer[6]),interpolation:4)),
			Sanitize.ar(	BufRd.ar(1,buffer[7], rdPtr[7]*BufFrames.ir(buffer[7]),interpolation:4))
		];
		*/
		signal= buffer.collect({|item, i|  	Warp1.ar(1,item,rdPtr[i],freqScale[i],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[i])   });

/*
	signal=[
			Warp1.ar(1,buffer[0],rdPtr[0],freqScale[0],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[0]),
			Warp1.ar(1,buffer[1],rdPtr[1],freqScale[1],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[1]),
			Warp1.ar(1,buffer[2],rdPtr[2],freqScale[2],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[2]),
			Warp1.ar(1,buffer[1],rdPtr[3],freqScale[3],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[3]),
			Warp1.ar(1,buffer[4],rdPtr[4],freqScale[4],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[4]),
			Warp1.ar(1,buffer[5],rdPtr[5],freqScale[5],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[5]),
			Warp1.ar(1,buffer[6],rdPtr[6],freqScale[6],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[6]),
			Warp1.ar(1,buffer[7],rdPtr[7],freqScale[7],windowSize.clip(0.001,oneBar*nBars),envBuf,interp:2,overlaps:overlap,windowRandRatio:randAmt[7])];
*/


		signal=signal*  (Lag.kr(density)+((1-Lag.kr(density))*mainEnv) );

		out_clear=signal;

		signal= signal.collect({ |item,i| ~deconvFunc.value(item,cuts[i])   });



		mix=[Sanitize.ar( SelectXFocus.ar(which,signal,focus,true)),Sanitize.ar(SelectXFocus.ar((7.0-which),signal,focus,true))];
		out_clear=[Sanitize.ar( SelectXFocus.ar(which,out_clear,focus,true)),Sanitize.ar(SelectXFocus.ar((7.0-which),out_clear,focus,true))];

		OffsetOut.ar(out,(out_clear++mix));


	};
returnFunc;

};







// ///////////////////////////////////////////////////
// ///////////////////////////////////////////////////
~markSeq={
	|size,len|
	var chain;
	chain=MarkovFb.new(size);
	len.collect({(chain.next)});
};




// ////////////////////////////////////////////////////////////////////////////////////////////////

// Melody/harmony

// ////////////////////////////////////////////////////////////////////////////////////////////////





// Create Melodic sequences and offset other voices by a multiple of 2 (harmonizing thirds)

~voices={
|nVoices,scale,extension=1,n=16|
	var mark={
			var deg;
		deg=MarkovFb.new(scale.degrees.size*extension).next;
		[deg]++  (deg+({(rrand(1,4)*2)}!(nVoices-1)).value).integrate
	}!n;
	mark.flop
};

// rules from classical harmony
// 1 3 6
// 4 2
// 5 7
~harmonicStructureGen=
{
	|iterations=1|
	var fsm=Pfsm([
	#[0],
	0, (#[3,3,3,1].foldExtend(12)++[2,5].foldExtend(8)),
	1, #[4,4,4,4,4,4,3,3,3,3,7],
	2, #[3,3,3,1,1,5],
	3, #[4,4,4,6,6,1],
	4, #[0,0,0,0,0,0,0,0,0, 5,5,5,5, 2],
	5, #[3,1],
	6, #[0]]).asStream,
	finished=false,structure=[fsm.next];
	iterations.do
	({
		finished=false;i=0;
		while({(finished.not) },

		{
			structure=structure.add({var val=fsm.next;if(val==0,{finished=true});val}.value)
	});

	});
	structure
};







// ////////////////////////////////////////////////////////////////////////////////////////////////

// Rhythm

// ////////////////////////////////////////////////////////////////////////////////////////////////




// the structure for the below levels is obtained from the binary sequences
// prepares for pbind, returns [structure(for rest on/off 0-1),the duration for dur, time until next trigger (for envelopes...)]
~prepareData={|seq,chainLength,maxDepth,binary=true| // chain length permits more depth (collects n values from markov chain)
	var steps,stepL,flatStructure,stepI,structure,stepN;

		structure=~computeStructure.value(seq.deepCopy,maxDepth,stutter:true,chainLength:chainLength);
	stepL=((~findStepSize.value(structure,0,1,binary:binary))).flatten(16);

	flatStructure=structure.deepCopy.flatten(16+maxDepth);
	stepN=flatStructure.deepCopy;
	stepI=~kernels.getSteps(flatStructure.deepCopy);

	flatStructure.indicesOfEqual(1).do
	(
		{
		|item,i|
		var accum=0.0,
		stepIdx=item;//index of active steps


		stepI.at(stepIdx).do({ //stepI @ stepIdx = how many steps until next active
			|item,i|

			accum=accum+stepL.at((stepIdx+i).mod(stepL.size));

		});
		stepN.put(stepIdx,accum);
	}
	);

	if(binary==true,{stepL=(2.pow(stepL+3)).reciprocal });
	[flatStructure,stepL,stepN]
};




~computeStructure={
|list,maxDepth=2,depth=0,stutter=true,chainLength=4|

	var mark=MarkovFb.new(list.size/2),mark2=MarkovFb.new(list.size);
	var sLen,indices,offset=0;//,seq;

	mark=({(mark.next+(list.size/2))%list.size}!chainLength).asInteger;
	list=list.deepCollect(16,{|item| item ?? 0});
	sLen=~kernels.getSteps(list);

	if((depth<maxDepth )&& (list.indicesOfEqual(1)!=nil),{

//seq= ~kernels.setBinarySeq(rrand(0,~kernels.sizeBinaryColleciton-1));


indices=list.indicesOfEqual(1).sect(mark);

indices.do({
	|item,i|
		var sublist,idx=item;
		sublist=~computeStructure.value((~kernels.setBinarySeq(rrand(0,~kernels.sizeBinaryColleciton-1)).rotate(mark2.next)).copyFromStart(rrand(2,list.size-1)),maxDepth,depth+1,stutter,chainLength);

	list.put(idx, sublist );

	});

		indices.do({
			|item,i|
			var idx=item;



			(sLen.at(idx)-1).do({
				|i|	var localOffset=0;

				if((idx-offset+1)>list.size,{localOffset= -1 *i},{localOffset=0});
				list.removeAt((( list.size+idx-offset +localOffset   )+1)%(list.size));
			});
			offset=offset+(sLen.at(idx)-1);
		});


		if(stutter,
			{var len=rrand((list.size*0.5).asInteger,list.size-1);
				list=list.copyFromStart(len)++list.copyFromStart((list.size-1)-len);}
	)

	});
list
};


//recursive function to find length level
// if binary true, divide result by the desired 1st order divisor,
// if binary false, multiply the result by the desired length
~findStepSize=
{
	|item,depth,parentLen,binary=false|
	if(item.isArray,{var out=[],currItem=item;
		item.do({
			|item,i|
			out=out.add(~findStepSize.value(item,depth+1,if(binary,{1/2.pow(depth)},{parentLen/currItem.size}),binary))

	});out},parentLen)
};






// init scale data

    ~selectScale={|scaleIdx=0|

	~scaleKeys=Scale.all.parent.keys;
	scaleIdx=scaleIdx.wrap(0,~scaleKeys.size-1);
	~scaleKey=~scaleKeys.asArray[scaleIdx];
	~scale=Scale.at(~scaleKey);



};
~selectScale.value(20);


// ~steata[2].postln;

// [rest, dur, durToNext]


// init pattern variables

~neuralNet=NeuralNetFb.new(16,8,0.3);
~kernels=RhythmKernels.new;
~kernels.setBinarySeq(rrand(0,~kernels.sizeBinaryColleciton));
~kernels.setKsSeq([rrand(0,80),rrand(0,80)]);
~bSeq=~kernels.currentBinarySeq.rotate(rrand(0,~kernels.currentBinarySeq.size));
~kSeq=~kernels.currentKsSeq[0];
~sSeq=~kernels.currentKsSeq[1];
~nSeq={~neuralNet.next};

//update binary seq as random
//~kernels.setBinarySeq(rrand(0,~kernels.sizeBinaryColleciton));

//update Neural net pattern, maybe better using it as float array

~patternLength=64;
//harm+mel

~resetHarmonicStructure=
{
	|nIter=4|
		~harmonicStructure=Pseq(~harmonicStructureGen.value(nIter),inf).asStream;
};
~resetHarmonicStructure.value(4);

~harmOffset=~harmonicStructure.next;

// melody array
~voicesList=~voices.value(4,~scale,3,32);

~stepData=[[],[],[]];
~deltaDensity=0.0;



~refreshStepData=
{
var s1=	~revWeightFunc.value(  (~weightFunc.value(~kSeq)+(~deltaDensity*(1.0.exprand(2.0.pow(~patternLength))))).abs.floor  ,~patternLength.asInteger);

var s2=	~revWeightFunc.value(  (~weightFunc.value(~sSeq)+(~deltaDensity*(1.0.exprand(2.0.pow(~patternLength))))).abs.floor  ,~patternLength.asInteger);

var s3=	~revWeightFunc.value(  (~weightFunc.value(~bSeq)+(  ~deltaDensity*(1.0.exprand(2.0.pow(~patternLength))))).abs.floor  ,~patternLength.asInteger);

~stepData[0]=~prepareData.value(s1,0,0,true);
~stepData[1]=~prepareData.value(s2,0,0,true);
~stepData[2]=~prepareData.value(s3,0,0,true);
//~patternLength,2
};

~refreshStepData.value;


// synthdefs

// from SynthDef helpfile-> all sc code get evaluated when the synth is added to the server, so in order to re evaluate the code, store synths in functions -> call SynthDef().add to re evaluate


~fmFunc={var returnFunc={
	|freq=60.0, out=0,envRatio=0.2,fb=0.6,env2Ratio=6.0,env2Ratio1=1.0,n=4.0,totTime=0.5,curve= -8.0 ,amp=1.0,midiOffset=54,parBuf,trigBuf,resetT= -0.1,length,in=28,envAmt=0.0|



	var hist1= LocalBuf(1).clear,
	    hist2=LocalBuf(1).clear;
	var rate=SampleRate.ir.reciprocal;
	var xyz;//,rpt;//xyz,rphitheta
	var signal, new;
	var	prev1;// = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	var	prev2; //= Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer
	var env1;
	var env2;
	var env3;
	var envTrig;
	var attack,decay;
	var ccInput= Lag.kr( ~busK.kr(6,midiOffset));

	//[\freq,\totTime,\amp,\envRatio,\curve,\env2Ratio,\env2Ratio1,\fb,\n,envTrig]
	var sTrig=ListTrig2.kr(trigBuf,resetT,numframes:(length+1));
	var counter=PulseCount.kr(sTrig-0.00001,resetT);
	var free;
	var counterE;
	//counter.poll(3);
	//{if(resetT>0,{resetT=-0.1});};


	var stretch  = Lag.kr(~busFX.kr(1,(13+((midiOffset-48)/6)))).linlin(0,127,0.001,0.5);


	var chainA,chainB;
	var tCoef;



	envTrig=(WrapIndex.ar(parBuf,(counter*10)+9));
	counterE=PulseCount.ar(envTrig-0.00001,resetT);
	totTime=WrapIndex.ar(parBuf,(((counterE-1).clip(0,length-1))*10)+1);
	tCoef=SampleDur.ir/totTime;



//freq=WrapIndex.ar(parBuf,counter*10);
	amp=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+2),totTime)*amp;
	envRatio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+3),totTime);
	curve=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+4).wrap2(8.0),totTime);
	env2Ratio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+5),totTime);
	env2Ratio1=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+6),totTime);
	fb=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+7),totTime);
	n=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+8),totTime);

	freq=WrapIndex.ar(parBuf,counterE*10);





	envRatio=envRatio*ccInput[0].linlin(0.0,127.0,0.001,1.0);
	fb=fb*ccInput[1].linexp(0.0,127.0,0.001,16.0);
	env2Ratio=env2Ratio*ccInput[2].linexp(0.0,127.0,0.01,16.0);
	n=((n))*ccInput[4].linexp(0.0,127.0,0.001,1000.0);
	totTime=totTime*(ccInput[5].linlin(0.0,127.0,0.001,2.0).round(0.0625));


	SendReply.kr(sTrig,'/trigBela',[freq,(env2Ratio1)]);






	attack=(envRatio*totTime);
	decay=((1.0-envRatio)*totTime);
	// use same envelope for freeig synth;
	env1=Env.perc(attack,decay,curve:curve);

	free=Lag.kr(1.0-(counter-length).clip(0.0,1.0),0.01)+  EnvGen.ar(Env.perc(0.012,5.0),(counter-length),doneAction:2) ;

	env1=EnvGen.kr(env1 ,((envTrig)-0.01),doneAction:0).abs.tanh;


	env1=env1.abs.clip(0.0,1.0);

	env3=EnvGen.ar( Env.asr(attack,1,decay,curve),sTrig,doneAction:0).tanh.abs;


	env2=DemandEnvGen.ar(env2Ratio1,totTime,7)*ccInput[3].linexp(0.0,127.0,0.01,1.0);
	env1=(((envAmt* env1)+(1.0-envAmt)).clip(0.0,1.0));
	fb=fb+((env2+1.0)*fb);


	prev1 = Duty.ar(rate,0,Dbufrd(hist1)).tanh; // read from buffer
	prev2 = Duty.ar(rate,0,Dbufrd(hist2)).tanh; // read from buffer
//










xyz=[((prev1+(0.3333*CombC.ar(prev1.tanh,1.0,totTime.wrap(0.0,1.0)*0.01,totTime.wrap(0.0,1.0))))),((prev2+(0.3333*CombC.ar(prev2.tanh,1.0,totTime.wrap(0.0,1.0)*0.01,totTime.wrap(0.0,1.0))))),SinOsc.ar(freq+(freq*(prev1+prev2))),SinOsc.ar(freq+(freq*(prev1+prev2)))+Shaper.ar(~globalMemory[7],SinOsc.ar(freq,envRatio,env2Ratio).fold(0.0,1.0))  ];

	chainA=SinOsc.ar( freq+( freq*(1+(env2*100.0))*xyz[2]*SinOsc.ar(freq+(env2Ratio*100.0*xyz[0])) ) );
	chainB=SinOsc.ar( freq+( freq*(1+(env2*100.0))*xyz[3]*(1.0+env3)*SinOsc.ar(freq+(env2Ratio*100.0*xyz[1])) ) );

	chainA= SinOsc.ar((freq*0.5*env2Ratio)+(n*freq*chainB))*chainA.ring1(SawDPW.ar(freq+(chainA*xyz[0]*freq)));
	chainB= SinOsc.ar((freq*0.5*env2Ratio)+(n*freq*chainA))*chainB.ring1(SawDPW.ar(freq+(chainB*xyz[1]*freq)));

	new= [LeakDC.ar((((chainA).tanh))),LeakDC.ar((((chainB).tanh)))];

	//new=[new[1],new[0]];

	new=(new+(2.0*MoogLadder.ar(new,((env2+1.0)*freq)+Lag.ar( new.tanh,tCoef+(Slope.ar(new)*SampleDur.ir)),SinOsc.ar(freq,add:1.0).abs*0.495)))*0.3333333;
	new=LeakDC.ar(((new.wrap2(1.0))) ).tanh;




	//rpt=[xyz.pow(2).sum.sqrt.pow(n).fold2(1.0), atan2(xyz[2],(xyz[0..1].pow(2).sum.sqrt)),atan2(xyz[1],xyz[0])   ];


//	new=env2* ReplaceBadValues.ar([rpt[0]*(rpt[2]*n*fb).cos*(rpt[1]*n*fb).cos,
	//	rpt[0]*(rpt[2]*n*fb).sin*(rpt[1]*n*fb).cos],(((xyz[2]*freq+freq)*2pi).sin)!2,post:0);


	new=ReplaceBadValues.ar(new,SinOsc.ar(freq).dup,post:0);

	signal =Duty.ar(rate,0, [Dbufwr(new[0]*fb, hist1),Dbufwr(new[1]*fb,hist2)]); // write to buffers
	signal=new;

	signal= EnvGate.new()* env1 * signal;//((  SinOsc.ar(((In.ar(in,1))*((1.0-env3)*(ReplaceBadValues.ar( [prev1,prev2],post:0)))),phase:(ReplaceBadValues.ar( [rpt[1..2]],post:0)).mod(2pi))));






	OffsetOut.ar(out
	,LeakDC.ar((amp*signal).wrap2(1.0).tanh)); //((signal.tanh)));
	//Out.ar(20,ToggleFF.ar(CoinGate.ar(0.6,envTrig))*amp*signal.tanh);


};returnFunc};

SynthDef(\fmFb,~fmFunc.value).add;












// //////////////////////////////////////////

~mandelFunc={var returnFunc={
	|freq=60.0, out=0,envRatio=0.2,fb=0.6,env2Ratio=6.0,env2Ratio1=1.0,n=4.0,totTime=0.5,curve= -8.0 ,amp=1.0,midiOffset=54,parBuf,trigBuf,resetT= -0.1,length,in=28,envAmt=0.0|

	var hist1= LocalBuf(1).clear,
	    hist2=LocalBuf(1).clear;
	var rate=SampleRate.ir.reciprocal;
	var xyz,rpt;//xyz,rphitheta
	var signal, new;
	var	prev1;// = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	var	prev2; //= Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer
	var env1;
	var env2;
	var env3;
	var envTrig;
	var attack,decay;
	var ccInput= Lag.kr( ~busK.kr(6,midiOffset));

	//[\freq,\totTime,\amp,\envRatio,\curve,\env2Ratio,\env2Ratio1,\fb,\n,envTrig]
	var sTrig=ListTrig2.kr(trigBuf,resetT,numframes:(length+1));
	var counter=PulseCount.kr(sTrig-0.00001,resetT);
	var free;
	var counterE;
	//{if(resetT>0,{resetT=-0.1});};
	var fb2,n2;

	var stretch  = Lag.kr(~busFX.kr(1,(13+((midiOffset-48)/6)))).linlin(0,127,0.001,0.5);



	envTrig=(WrapIndex.ar(parBuf,(counter*10)+9));
	counterE=PulseCount.ar(envTrig-0.00001,resetT);
	totTime=WrapIndex.ar(parBuf,(((counterE-1).clip(0,length-1))*10)+1);



//freq=WrapIndex.ar(parBuf,counter*10);
	amp=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+2),totTime)*amp;
	envRatio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+3),totTime);
	curve=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+4).wrap2(8.0),totTime);
	env2Ratio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+5),totTime);
	env2Ratio1=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+6),totTime);
	fb=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+7),totTime);
	n=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+8),totTime);


	freq=WrapIndex.ar(parBuf,counterE*10);




	envRatio=envRatio*ccInput[0].linlin(0.0,127.0,0.001,1.0);
	fb=fb*ccInput[1].linexp(0.0,127.0,0.001,128.0);
	fb2=(fb+1.0)*ccInput[1].linexp(0.0,127.0,0.001,1.0);

	env2Ratio=env2Ratio*ccInput[2].linexp(0.0,127.0,0.01,64.0);

	n=n*ccInput[4].linexp(0.0,127.0,0.001,24.0);
    n2=(n.reciprocal+1.0)*ccInput[4].linexp(0.0,127.0,0.001,1.0);


	totTime=totTime*(ccInput[5].linlin(0.0,127.0,0.001,2.0).round(0.0625));

	SendReply.kr(sTrig,'/trigBela',[freq,(env2Ratio1)/16.0]);
	//{if((resetT>0.0),{resetT=-0.1;  });};


	//counterEnv=(PulseCount.ar((envTrig*br)-0.00001));

	//br= br+ (1.0-counterEnv.clip(0.0,1.0));




	attack=(envRatio*totTime);
	decay=((1.0-envRatio)*totTime);
	// use same envelope for freeig synth;
	env1=Env.perc(attack,decay,curve:curve);

	free=Lag.kr(1.0-(counter-length).clip(0.0,1.0),0.01)+  EnvGen.ar(Env.perc(0.012,5.0,curve:curve),(counter-length),doneAction:2) ;

	env1=EnvGen.kr(env1 ,((envTrig)-0.01),doneAction:0).abs.tanh;

	//doneE= PulseCount.kr( Done.kr(env1).poll(label:"done")-0.1);


	env1=env1.abs.clip(0.0,1.0);
	//free=FreeSelf.kr(Trig.kr(counter.poll(label:"counter")-length.poll(label:"length")+(1-(counterE.poll(label:"counterE")-doneE.poll(label:"doneE"))).poll(label:"other")-0.1  ));

	env3=EnvGen.ar( Env.asr(attack,1,decay,curve),sTrig,doneAction:0).abs;
	env2=(DemandEnvGen.ar(env2Ratio1,totTime,7)*ccInput[3].linexp(0.0,127.0,0.01,8.0)); //ReplaceBadValues.ar(LFSaw.ar(-1.0*  (((attack+decay)*env2Ratio*(freq.reciprocal+(env3*(1.0-freq.reciprocal)))).clip((freq*env2Ratio1).reciprocal,1.0)).reciprocal  ,mul:0.5,add:0.5),post:0);
	env1=(((envAmt* env1)+(1.0-envAmt)).clip(0.0,1.0));

	fb=(env2+1.0)*fb;










	prev1 = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	prev2 = Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer

	xyz=[prev1,prev2,(SinOsc.ar(freq+(freq*(prev1+prev2)))+Shaper.ar(~globalMemory[7],SinOsc.ar(freq,envRatio,env2Ratio).fold(0.0,1.0)))  ];



	rpt=[xyz.pow(2).sum.sqrt.pow(n).fold2(1.0), atan2(xyz[2],(xyz[0..1].pow(2).sum.sqrt)),atan2(xyz[1],xyz[0])   ];


	new=env2* ReplaceBadValues.ar([rpt[0]*(rpt[2]*n*fb).cos*(rpt[1]*n*fb).cos,
		rpt[0]*(rpt[2]*n*fb).sin*(rpt[1]*n*fb).cos],(((xyz[2]*freq+freq)*2pi).sin)!2,post:0);







	signal =Duty.ar(rate,0, [Dbufwr(new[0], hist1),Dbufwr(new[1],hist2)]); // write to buffers


	signal= EnvGate.new()* env1 *0.06* ((  SinOsc.ar(( freq +  ( freq* env2Ratio * (ReplaceBadValues.ar( [prev1,prev2],post:0)))),phase:(ReplaceBadValues.ar( [rpt[1..2]],post:0)).mod(2pi))));

	fb=fb2;
	signal=  signal+ (signal.collect( { |item| Mix.ar(4.collect({ item*(KStrongDecay.ar(item,Duty.ar(SampleDur.ir,0,Lag.ar(freq.reciprocal)),Duty.ar(SampleDur.ir,0,(fb2+(env2*fb2)).clip(0.0,1.0)),Duty.ar(SampleDur.ir,0,(n2*(env3+1.0)).clip(0.0,1.0))).tanh)})) }))+signal;
	signal=signal*0.5;




	OffsetOut.ar(out
	,amp*signal.tanh);



	//((signal.tanh)));
	//Out.ar(20,ToggleFF.ar(CoinGate.ar(0.6,envTrig))*amp*signal.tanh);
	//Select.ar( ), [DC.ar(out),DC.ar(20.0)]).poll


};returnFunc};


SynthDef(\mandel,~mandelFunc.value).add;















~conformalFunc={var returnFunc={
	|freq=60.0, out=0,envRatio=0.2,fb=0.6,env2Ratio=6.0,env2Ratio1=1.0,n=4.0,totTime=0.5,curve= -8.0 ,amp=1.0,midiOffset=54,parBuf,trigBuf,resetT= -0.1,length,in=28,envAmt=0.0|

	var hist1= LocalBuf(1).clear,
	    hist2=LocalBuf(1).clear;
	var rate=SampleRate.ir.reciprocal;
	var xyz;//xyz,rphitheta
	var signal, new;
	var	prev1;// = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	var	prev2; //= Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer
	var env1;
	var env2;
	var env3;
	var envTrig;
	var attack,decay;
	var ccInput= Lag.kr( ~busK.kr(6,midiOffset));

	//[\freq,\totTime,\amp,\envRatio,\curve,\env2Ratio,\env2Ratio1,\fb,\n,envTrig]
	var sTrig=ListTrig2.kr(trigBuf,resetT,numframes:(length+1));
	var counter=PulseCount.kr(sTrig-0.00001,resetT);
	var free;
	var counterE;

	var stretch  = Lag.kr(~busFX.kr(1,(13+((midiOffset-48)/6)))).linlin(0,127,0.001,0.5);

	var envBuff=LocalBuf.newFrom([1.0]);


var chainA,chainB;
var tCoef;

	envTrig=(WrapIndex.ar(parBuf,(counter*10)+9));
	counterE=PulseCount.ar(envTrig-0.00001,resetT);
	totTime=WrapIndex.ar(parBuf,(((counterE-1).clip(0,length-1))*10)+1);
	tCoef=SampleDur.ir/totTime;

	amp=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+2),totTime)*amp;
	envRatio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+3),totTime);
	curve=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+4).wrap2(8.0),totTime);
	env2Ratio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+5),totTime);
	env2Ratio1=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+6),totTime);
	fb=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+7),totTime);
	n=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+8),totTime);

	freq=WrapIndex.ar(parBuf,counterE*10);




	envRatio=envRatio*ccInput[0].linlin(0.0,127.0,0.001,1.0);
	fb=fb*ccInput[1].linexp(0.0,127.0,0.001,3000.0);



	env2Ratio=env2Ratio*ccInput[2].linexp(0.0,127.0,0.01,512.0);

	n=((n+1).reciprocal)*ccInput[4].linexp(0.0,127.0,0.001,100.0);



	totTime=totTime*(ccInput[5].linlin(0.0,127.0,0.001,2.0).round(0.0625));



	SendReply.kr(sTrig,'/trigBela',[freq,(env2Ratio1)]);





	attack= (envRatio*totTime);
	decay=((1.0-envRatio)*totTime).clip(0.01,inf);
	// use same envelope for freeig synth;
	env1=Env.perc(attack,decay,curve:curve);

	free=Lag.kr(1.0-(counter-length).clip(0.0,1.0),0.01)+  EnvGen.ar(Env.perc(0.012,5.0),(counter-length),doneAction:2) ;

	env1=EnvGen.ar(env1 ,((envTrig)-0.01),doneAction:0).abs.tanh;



	env1=env1.abs.clip(0.0,1.0);

	env3=EnvGen.ar( Env.perc(attack,decay,curve:curve),sTrig,doneAction:0).tanh.abs;
	env2= DemandEnvGen.ar(env2Ratio1,totTime,7)*ccInput[3].linexp(0.0,127.0,0.01,512.0);

	env2=Lag.ar(env2,totTime);

	env1=(((envAmt* env1)+(1.0-envAmt)).clip(0.0,1.0));
	fb=fb+((env2+1.0)*fb);


	prev1 = Duty.ar(rate,0,Dbufrd(hist1)).tanh; // read from buffer
	prev2 = Duty.ar(rate,0,Dbufrd(hist2)).tanh; // read from buffer
//


xyz=[((prev1+(n*CombC.ar(prev1.tanh,1.0,totTime.wrap(0.0,1.0)*0.01,totTime.wrap(0.0,1.0))))),((prev2+(n*CombC.ar(prev2.tanh,1.0,totTime.wrap(0.0,1.0)*0.01,totTime.wrap(0.0,1.0))))),SinOsc.ar(freq+(freq*(prev1+prev2))),SinOsc.ar(freq+(freq*(prev1+prev2)))+Shaper.ar(~globalMemory[7],SinOsc.ar(freq,envRatio,env2Ratio).fold(0.0,1.0))  ];


	//sig=((sig+(0.3333*CombC.ar(sig.tanh,1.0,tEnv*0.01,tEnv)))*0.75);
			// change 128 to hear the difference
	chainA=FFT(LocalBuf(128),   xyz[0]+ (SinOsc.ar( (xyz[0]+1.0)*freq)),wintype:1);
	chainA=PV_ConformalMap(chainA,(env3+1.0)*env2Ratio*SinOsc.ar((xyz[2]+1.0)*freq),SinOsc.ar((xyz[3]+1.0)*freq));
	chainB=FFT(LocalBuf(256), xyz[1]+ ( SinOsc.ar( (xyz[1]+1.0)*freq)),wintype:1);
	chainB=PV_ConformalMap(chainB,(env2+1.0)*SinOsc.ar((xyz[2]+1.0)*freq),SinOsc.ar((xyz[3]+1.0)*freq));

	new= [LeakDC.ar(((IFFT(chainA).tanh))),LeakDC.ar(((IFFT(chainB).tanh)))];



	new=(new+(2.0*MoogLadder.ar(new,(((env1+1.0)*freq)+(Lag.ar( new.tanh,tCoef+(Slope.ar(new)*SampleDur.ir)))).mod(20000.0),(SinOsc.ar(freq,add:1.0).abs*0.1)  )))*0.3333333;
	new=LeakDC.ar(((new.wrap2(1.0))) ).tanh;

	//rpt=[xyz.pow(2).sum.sqrt.pow(n).fold2(1.0), atan2(xyz[2],(xyz[0..1].pow(2).sum.sqrt)),atan2(xyz[1],xyz[0])   ];


//	new=env2* ReplaceBadValues.ar([rpt[0]*(rpt[2]*n*fb).cos*(rpt[1]*n*fb).cos,
	//	rpt[0]*(rpt[2]*n*fb).sin*(rpt[1]*n*fb).cos],(((xyz[2]*freq+freq)*2pi).sin)!2,post:0);

	new=ReplaceBadValues.ar(new,SinOsc.ar(freq).dup,post:0);

	signal =Duty.ar(rate,0, [Dbufwr(new[0]*fb, hist1),Dbufwr(new[1]*fb,hist2)]); // write to buffers

	signal=new;

	//signal[0].poll;
	signal= EnvGate.new()* env1 * signal;//((  SinOsc.ar(((In.ar(in,1))*((1.0-env3)*(ReplaceBadValues.ar( [prev1,prev2],post:0)))),phase:(ReplaceBadValues.ar( [rpt[1..2]],post:0)).mod(2pi))));






	OffsetOut.ar(out
	,LeakDC.ar((amp*signal).wrap2(1.0).tanh)); //((signal.tanh)));
	//Out.ar(20,ToggleFF.ar(CoinGate.ar(0.6,envTrig))*amp*signal.tanh);
	//Select.ar( ), [DC.ar(out),DC.ar(20.0)]).poll


};returnFunc};



SynthDef(\conformal,~conformalFunc.value).add;




~ksFunc={var returnFunc={
	|freq=60.0, out=0,envRatio=0.2,fb=0.6,env2Ratio=6.0,env2Ratio1=1.0,n=4.0,totTime=0.5,curve= -8.0 ,amp=1.0,midiOffset=54,parBuf,trigBuf,resetT= -0.1,length,in=28,envAmt=0.0|


	var rate=SampleDur.ir;

	var signal;
	var env1;
	var env2;
	var env3;
	var envTrig;
	var attack,decay;
	var ccInput= Lag.kr( ~busK.kr(6,midiOffset));

	//[\freq,\totTime,\amp,\envRatio,\curve,\env2Ratio,\env2Ratio1,\fb,\n,envTrig]
	var sTrig=ListTrig2.kr(trigBuf,resetT,numframes:(length+1));
	var counter=PulseCount.kr(sTrig-0.00001,resetT);
	var free;
	var counterE;



	var stretch  = Lag.kr(~busFX.kr(1,(13+((midiOffset-48)/6)))).linlin(0,127,0.001,0.5);


	envTrig=(WrapIndex.ar(parBuf,(counter*10)+9));
	counterE=PulseCount.ar(envTrig-0.00001,resetT);
	totTime=WrapIndex.ar(parBuf,(((counterE-1).clip(0,length-1))*10)+1);





	amp= Lag.ar( WrapIndex.ar(parBuf,(counter*10)+2),totTime)*amp;
	envRatio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+3),totTime);
	curve=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+4).wrap2(8.0),totTime);
	env2Ratio=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+5),totTime);
	env2Ratio1=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+6),totTime);
	fb=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+7),totTime);
	n=Lag.ar(WrapIndex.ar(parBuf,(counter*10)+8),totTime);

	freq=WrapIndex.ar(parBuf,counterE*10);




	envRatio=envRatio*(ccInput[0].linlin(0.0,127.0,0.001,1.0));
	fb=((fb+1.0)*(ccInput[1].linexp(0.0,127.0,0.01,1.0))).clip(0.0,1.0);
	env2Ratio=env2Ratio*(ccInput[2].linexp(0.0,127.0,0.01,8.0));

	n=((n+1).reciprocal)*(ccInput[4].linexp(0.0,127.0,0.001,1.0));



	totTime=totTime*(ccInput[5].linlin(0.0,127.0,0.001,2.0).round(0.0625));

	SendReply.kr(sTrig,'/trigBela',[freq,(env2Ratio1)]);







	attack=(envRatio*totTime);
	decay=((1.0-envRatio)*totTime);
	// use same envelope for freeig synth;
	env1=Env.perc(attack,decay,curve:curve);

	free=Lag.kr(1.0-(counter-length).clip(0.0,1.0),0.024)+  EnvGen.ar(Env.perc(0.012,5.0,curve:curve),(counter-length),doneAction:2) ;

	env1=EnvGen.ar(env1 ,((envTrig)-0.01),doneAction:0).abs.tanh;

	//doneE= PulseCount.kr( Done.kr(env1).poll(label:"done")-0.1);


	env1=env1.abs.clip(0.0,1.0);


	env3=EnvGen.ar( Env.perc(attack,decay,curve:curve),(sTrig-0.01),doneAction:0).tanh.abs;
	env2=DemandEnvGen.ar(env2Ratio1,totTime,7)*(ccInput[3].linexp(0.0,127.0,0.01,512.0)); //ReplaceBadValues.ar(LFSaw.ar(-1.0*  (((attack+decay)*env2Ratio*(freq.reciprocal+(env3*(1.0-freq.reciprocal)))).clip((freq*env2Ratio1).reciprocal,1.0)).reciprocal  ,mul:0.5,add:0.5),post:0).abs.tanh;
	env1=(((envAmt* env1)+(1.0-envAmt)).clip(0.0,1.0));


	signal=   (2.collect( { Mix.ar(4.collect({ KStrongDecay.ar(((SinOsc.ar(freq+(freq*(fb*10.0)*(1.0+env3)*SinOsc.ar(freq))+(env2*freq*WhiteNoise.ar())+(env3*freq*WhiteNoise.ar())  )*env1)),Duty.ar(SampleDur.ir,0,freq.reciprocal),Duty.ar(SampleDur.ir,0,(fb+(env2*fb)).clip(0.0,1.0)),Duty.ar(SampleDur.ir,0,(n*(env3+1.0)).clip(0.0,1.0)))})) }));




	signal=Duty.ar(SampleDur.ir,sTrig,signal);


	signal= EnvGate.new() * signal*free;


//amp
	OffsetOut.ar(out
	,LeakDC.ar((signal*amp).tanh));


};returnFunc};




SynthDef(\KST,~ksFunc.value).add;



//Synth(\conv,  [\specBufNum, ~irspectrum.bufnum]);
//SynthDef(\multiScale,~multiScaleFunc.value).add;


~addChopDefFunc={SynthDef(\chop,~chopFunc2.value).add};


~addChopDefInFunc={SynthDef(\chopIN,~globalMemoryWriteFunc.value).add};

~addChopDefFunc.value;


~addChopDefInFunc.value;
//~addReverbFunc.value;

SynthDef(\mixIO,{
	OffsetOut.ar(0,In.ar(~bus.index,10));
}).add;
/*

SynthDef(\conv,
	{| in=0, out=0, fftsize=2048, specBufNum=8|
		var sig, verb;
		sig = In.ar(in, 2);
		verb = PartConv.ar(LeakDC.ar( sig), fftsize, specBufNum);
		ReplaceOut.ar(out, LeakDC.ar(( sig * 0.71) +  (  (1.0-(Lag.ar( Amplitude.ar(sig*4.0),0.3).tanh))* verb * 0.1* (LFTri.ar(0.010234,0,0.5,0.5))* SinOsc.ar(0.1) )))
}).add;


*/
//stepData [Trig,Dur/clock,Time]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////




~synthList=[nil,nil,nil];
~synthAmps=[0.0,0.0,0.0];
~doneSynth=[true,true,true];

~voiceTask={|voice_nr=0,stretch=1,curveRange=#[-6.0,6.0],minDur=0.1,maxDur=10.0,octave=3,midiOffset=54,out=(~bus.index),play=true,envAmt=0.0,synthName=\mandel|
	//x=x.add(Synth.new(\default).onFree(x.remove(_);))

	//(~stepData[1][0].collect({|item|(item.asBoolean.and(((1.0+~deltaDensity).clip(0.0,1.0)).coin).or((~deltaDensity.clip(0.0,1.0)).coin) )})

	var trigs=(~stepData[voice_nr][0]);
	var clk=(~bar)*stretch*~stepData[voice_nr][1];//*stretch
	var degree=~voicesList[voice_nr];
	var nSeq=~nSeq.value.linlin(-1.0,1.0,0.0,1.0);
	var ratios=(~scale.ratios.collect({|item,i| if(item>1.0,{item.reciprocal},{item}) }).scramble);
	var sArgs=[\freq,\totTime,\amp,\envRatio,\curve,\env2Ratio,\env2Ratio1,\fb,\n];
	var markov=5.collect({~markSeq.value(~scale.size,trigs.size)});
	var envRatio=ratios*nSeq;
	var curve=(markov[0]+1.0).reciprocal.linlin(0.0,1.0,curveRange[0],curveRange[1]);
	var env2Ratio=(ratios*(markov[1]+1.0)).collect({|item,i| if(item>1.0,{item.reciprocal},{item}) });
	var env2Ratio1=(ratios*(markov[2]+1.0)).collect({|item,i| if(item>1.0,{item.reciprocal},{item}) });
	var fb=((markov[3]+1.0)*10.0).reciprocal;
	var ns=(markov[4]+1.0);
	var res;
	var inChans=[28,29,30];
	var intdT=~stepData[voice_nr][1].integrate;

	// total time calculated from stepdata[2] which contains the number of steps until the next 1, and the duration of the single steps stored in stepdata[1]
	var st_len=~stepData[voice_nr][2].collect({ |item,i| if(item!=0,{intdT.wrapAt(i+item-1)- intdT.wrapAt(i)},{0}) });
	var totTime=(~bar*((intdT.size/16).asInteger.clip(1,inf)) *stretch*st_len).removeAllSuchThat({|item|item!=0}).clip(minDur,maxDur);

	octave=[[0,1,1].at(3.rand),[4,3,2,3].at(4.rand),[3,3,4,5,6].at(5.rand)].at(voice_nr); //(((2.rand+1)+(voice_nr+1))-1);
	//iterate over triggers
	//voice_nr.postln;
		res=	trigs.collect({
				|trig,i|


					/*launch and control synths,funcs etc*/


					//calculate frequency for current step
					var harmOffset;
					var freq;
					var argS;

if((trig>0.5).and(((1.0+~deltaDensity).clip(0.0,1.0)).coin).or((~deltaDensity.clip(0.0,1.0)).coin),{trig=1	},{trig= -0.1});
					/*TODO:put harmony alteration based on bpmbus and weightfunc*/
		if(1.0.rand>0.9999,{~harmOffset=~harmonicStructure.next;"harmony changed ".post;~harmOffset.postln;});
					harmOffset=~harmOffset;
					freq=~scale.degreeToFreq((degree.wrapAt(i)+harmOffset).wrap(0,~scale.degrees.size),44.0,octave);



		argS=[freq,totTime.wrapAt(i), ((trig*3.0)-15.0).dbamp*~synthAmps[voice_nr]  , envRatio.wrapAt(i),curve.wrapAt(i),env2Ratio.wrapAt(i),env2Ratio1.wrapAt(i),fb.wrapAt(i),ns.wrapAt(i),trig];

			//argS[0].postln; <--frequencies
		//	"___________".postln;

				argS;

			});

	       // res;

if(play,
{


			var name=~synthList[voice_nr].asString.replace("Synth("," ").replace("'","").split($ )[1];
			var sendName=~synthList[voice_nr].asString;
			if(~doneSynth[voice_nr]==true,{ ~synthList[voice_nr].free;~synthList[voice_nr]=nil; });

			if((~synthList[voice_nr].isPlaying==false)&&(~synthList[voice_nr]!=nil),{~synthList[voice_nr].free;~synthList[voice_nr]=nil});

			if((name!=synthName.asString) && (name!=nil),{
				name.postln;
				synthName.postln;
				~synthList[voice_nr].free; });





		        if((~synthList[voice_nr]==nil),{
				//\mandel,\fmFb
				var synthS=synthName; //[\KST,\mandel,\mandel].at(voice_nr);
				var bundle;
		//update mod buffer, execute a new synth
		~synthParamBuf[voice_nr].sendCollection(res.flat.foldExtend(trigs.size*10));
	    ~synthTimeBuf[voice_nr].sendCollection(clk.foldExtend(trigs.size));
		//~synthList[voice_nr].release;

				~doneSynth[voice_nr]=false;
				bundle=s.makeBundle(false,{
					~synthList[voice_nr]=Synth(synthName,[\length,trigs.size,\in,inChans[voice_nr],\out,out,\midiOffset,midiOffset,\parBuf,~synthParamBuf[voice_nr],\trigBuf,~synthTimeBuf[voice_nr],\envAmt,envAmt]).onFree({
					~doneSynth[voice_nr]=true;});
				NodeWatcher.register(~synthList[voice_nr]);
				});
				s.listSendBundle(nil,bundle);




	},{

		//synth already there, update buffer and send reset reading for triglist

		//



		~synthList[voice_nr].set(\length,trigs.size);
		~synthList[voice_nr].set(\envAmt,envAmt);
		~synthParamBuf[voice_nr].sendCollection(res.flat.foldExtend(trigs.size*10));
	    ~synthTimeBuf[voice_nr].sendCollection(clk.foldExtend(trigs.size));
		~synthList[voice_nr].set(\trigBuf,~synthTimeBuf[voice_nr],\parBuf,~synthParamBuf[voice_nr]);
		//~synthList[voice_nr].set(\resetT,1.0);




	});
},{



		~synthParamBuf[voice_nr].sendCollection(res.flat.foldExtend(trigs.size*10));
	    ~synthTimeBuf[voice_nr].sendCollection(clk.foldExtend(trigs.size));
			if((~synthList[voice_nr]!=nil),{
				~synthList[voice_nr].set(\trigBuf,~synthTimeBuf[voice_nr],\parBuf,~synthParamBuf[voice_nr]);
				//~synthList[voice_nr].set(\envAmt,envAmt);

		~synthList[voice_nr].set(\length,trigs.size);



			});

	});


};
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

//octave=3,midiOffset=54,out=(~bus.index)
~voice_1=~voiceTask.value(voice_nr:0,octave:0,out:~bus.index,midiOffset:48,play:false);
~voice_2=~voiceTask.value(voice_nr:1,octave:1,out:~bus.index+2,midiOffset:54,play:false);
~voice_3=~voiceTask.value(voice_nr:2,octave:6,out:~bus.index+4,midiOffset:60,play:false);



//~addFmCascadeDefFunc.value;
//~addPendulumDefFunc.value;
// init the eventstreamplayer



// if argument (stretch) not nil reset the ~voice_1.value(stretch).play;
//CALL WITH MIDI
~playVoice1={|stretch=1,play=true,velocity=0.0,synthName=\mandel|
	~voice_1=~voiceTask.value(play:play,voice_nr:0,stretch:stretch,octave:0,out:~bus.index,midiOffset:48,envAmt:(velocity/127.0).clip(0.0,1.0),synthName:synthName);


};
~playVoice2={|stretch=1,play=true,velocity=0.0,synthName=\mandel|

	~voice_2=(~voiceTask.value(play:play,voice_nr:1,stretch:stretch,octave:1,out:~bus.index+2,midiOffset:54,envAmt:(velocity/127.0).clip(0.0,1.0),synthName:synthName));
};
~playVoice3={|stretch=1,play=true,velocity=0.0,synthName=\mandel|

~voice_3=(~voiceTask.value(play:play,voice_nr:2,stretch:stretch,octave:3,out:~bus.index+4,midiOffset:60,envAmt:(velocity/127.0).clip(0.0,1.0),synthName:synthName  ));
//~voiceP3=~voiceP3.play(doReset:true);
};

// ////////////
// trigger structural changes




~trigStruct={

	var bus=0;
	var nBars,density;
	var newseq=[[0],[0],[0]];
	var outDensity;
	bus=~busFX.getnSynchronous ; // ({arg value;bus=value;bus.postln});

	~selectScale.value(bus[10].asInteger);
	~chopSynth.set(\scale,`(~scale.ratios.scramble.collect({|item| if(0.5.coin,{item},{item.reciprocal}) }).foldExtend(8))) ;


	//~nSeq.value;
	// not necessary anymore here, set in chop synth
	//get nBars and density from bus, bus[11,12]
	nBars=bus[11].linlin(0,127,1.0,64.0).round(1.0);
	density=(bus[12].linlin(0,127,0.0,0.99212598425197))+((1/127).rand);




	~globalMemoryNBars.set(nBars);

//nIter-> base but prime * (max-nthprime)

	newseq.collect({~revWeightFunc.value((density*(1.0.exprand(2.0.pow(~patternLength)))),~patternLength,5.rand.nthPrime)});




	/*
	nIter.asInt.do({
	var val,x,y;
	~kernels.setBinarySeq((density*(19.9375))+rrand(0,(~kernels.sizeBinaryColleciton-1)/128) );

	newseq[0]=newseq[0]+~kernels.currentBinarySeq.rotate(rrand(0,~kernels.currentBinarySeq.size));
	//~bSeq=~kernels.currentBinarySeq.rotate(rrand(0,~kernels.currentBinarySeq.size));

	//51.2578125
	//6561/127
	//6561%81
	//(6561/81).clip(0,80)
	val=((density*51.2578125)+rrand(0,51.2578125)).asInt;
	x=val%81;
	y=((val/81).clip(0,80)).asInt;

	~kernels.setKsSeq([x,y]);
		newseq[1]=newseq[1]+~kernels.currentKsSeq[0];
		newseq[2]=newseq[2]+~kernels.currentKsSeq[1];
	//~kSeq=~kernels.currentKsSeq[0];
	//~sSeq=~kernels.currentKsSeq[1];


	});
	*/

	~bSeq=newseq[0].deepCopy.clip(0,1);
	~kSeq=newseq[1].deepCopy.clip(0,1);
	~sSeq=newseq[1].deepCopy.clip(0,1);





	~resetHarmonicStructure.value(1);
	~harmOffset=~harmonicStructure.next;
	~voicesList=~voices.value(4,~scale,1,32);
	~refreshStepData.value;

	outDensity=(~stepData.collect({|item,i| (item[0].sum)/(item[0].size) } ));
	outDensity=outDensity.sum/outDensity.size;
	//(~bSeq.sum +~kSeq.sum+~sSeq.sum)/(~bSeq.size +~kSeq.size+~sSeq.size);
	~deltaDensity=(density.linlin(0.0,127.0,0.0,1.0))-outDensity;


	//maybe too heavy?...
	//~addFmCascadeDefFunc.value;
	~playVoice1.value(((bus[13]).linlin(0,127,0.5,8.0)).round(0.125),false);
	~playVoice2.value(((bus[14]).linlin(0,127,0.5,8.0)).round(0.125),false);
	~playVoice3.value(((bus[15]).linlin(0,127,0.5,8.0)).round(0.125),false);
};


//~chopSynth.set(\modAmt,0.0)

~trigFx=
{
	|vel=64|

	~chopSynth.set(\balance,(vel/128.0));
	~chopTrig.set(1.0);  // set this to -1.1 in noteOff
	//trig randomized times for reverbs


};
~trigChopOff={

	~chopTrig.set(-1.07);

};





// "global transport" + midi init
~prevTick=0.0;
~bpm=120.0;
~bar=8.0;

//RESET
~noteOn.free;
~noteOff.free;
~cc.free;
~clockM.free;
~start.free;
~stop.free;

~midiIN=0;
MIDIClient.init;
MIDIClient.sources.do({
	|item,i|
	if(item.asString.contains("loopMIDI Port 1"),{~midiIN=i});
});
MIDIIn.connect(0,MIDIClient.sources.at(~midiIN));
~mainGroup=Group.new();
~tickAccum=0;

~clockM=MIDIFunc.midiClock({
	 var t= ~prevTick.deepCopy;

			~prevTick= Date.getDate.rawSeconds;
	        ~bpm=(2.5/((~prevTick-t))) ;	//60s/24 ticks(dt) per quarter=2.5
	        ~bar=96.0*(~prevTick-t);          //24*4 24tpq*4q=96t *1bar
            ~bpmBus.set(~bpm);
	        ~tickAccum=(~tickAccum+1).mod(96.0*128.0);
	        ~tickBus.setSynchronous((~tickAccum));

});
~start.free;
~start=MIDIFunc.start({

		~tickBus.setSynchronous(0.0);
		~tickAccum=0.0;
		//~addChopFunc.value;

		try(
			{
				~chopSynth.free;
				~chopSynthIn.free;
				//~reverbSynth.free;
				~mixIO.free;
				//~rev1.free;
				//~rev2.free;
				//~rev3.free;
				~chopSynth.set(\envBuf,~windowBuf);
				~chopSynth.set(\intensityBuf,~chopSeqBuf);
		},{arg e;"nothing to free".postln});


	     ~mainGroup=Group.new();
		// input is ~bus 1-6,
		~chopSynthIn= Synth.new("chopIN",target:~mainGroup);

		~chopSynth= Synth.after(~chopSynthIn,"chop");
		~chopSynth.set(\envBuf,~windowBuf);
		~chopSynth.set(\intensityBuf,~chopSeqBuf);
	    ~chopSynth.postln;

	//	~rev1= Synth.before(~chopSynthIn,\conv,  [\specBufNum, ~irspectrum.bufnum,in:(~bus.index),out:(~bus.index)]);
		//~rev2=Synth.before(~chopSynthIn,\conv,  [\specBufNum, ~irspectrum.bufnum,in:(~bus.index+2),out:(~bus.index+2)]);

		//~trigFx.value(true);

		//~reverbSynth=Synth.new("basicReverb");
		~mixIO=Synth.after(~chopSynth,"mixIO",target:~mainGroup);




		//~rev3=Synth.before(~mixIO,\conv,  [\specBufNum, ~irspectrum.bufnum,in:(~bus.index+6),out:(~bus.index+6)]);
		//Ndef(\chop,~chopFunc.value(/*put default inits here*/));
		//Ndef(\mix).play;
		"start received".postln;
		//Start Ndefs

});


~stop.free;
~stop=MIDIFunc.stop({



	       ~globalMemory.do(_.zero);
		   try(
			{
			s.freeAll;
				~synthList.do({|item|
				item.postln;
				item.free});

			~synthList=[nil,nil,nil];
				//~midiOut.allNotesOff(0);

			   ~chopSynthIn.postln;
			   ~chopSynthIn.free;
				~chopSynth.free;
			    ~mainGroup.free;
				//~reverbSynth.free;
				//~rev1.free;
				//~rev2.free;
				//~rev3.free;
				~mixIO.free;
			s.freeAll;
		},{arg e;"nothing to free".postln});

		//Ndef(\mix).stop;
		"stop received".postln;

});



// CHANNELS from Machinedrum control -> 3,4,5,6 .. 16 -> sc(zero based) 2,3,4,5..15
// TODO: chan 3(sc:2): 3 voice seq trig (different noteons)  + real time ccs to synthdefs (6ccs per voice max from MD)
//       chan 4(sc:3): 3 voice step trig --> fix the two different Pbinds (stepped crashes because of Ptime// mainstructure)
//       chan 5(sc:4): trig structural changes + ccs for structural values
//
// note trigs+ccs from machinedrum base chan (0) can be used to trigger fx changes..?
//
// chan 3: trig


// val, cc, chan, src

~cc.free;
~cc=MIDIFunc.cc({
	 arg val, num, chan, src;
	//-> cc 0-17 fill ~busK, cc 18-23+ MIDI chan 3 notes+cc go to trigger structural and fx changes directly
	switch(chan,
		//0,{ ~midiOut.control(chan,num,val)  },
		2,
		{

			~busK.setAt(num,val);
		},
		3,
		{


			~busFX.setAt(num,val);

		}
	);


});




~noteOn.free;
// vel, num, chan, src
~noteOn = MIDIFunc.noteOn({
	 arg vel, num, chan, src;

	/*"--noteon------------------".postln;
	Date.getDate.rawSeconds.postln;
	"noteon".postln;
	"src:".post;src.postln;
	"chan:".post;chan.postln;
	"num:".post;num.postln;
	"vel:".post;vel.postln;
	"-----------------------END".postln;*/
	// 3 voices triggered by 3x3 different notes on chan 2.
	var bus;
	var synthName=[\mandel,\fmFb,\conformal];
	bus=~busFX.getnSynchronous;
	synthName=synthName[ (num.mod(3)) ];

	switch(
		chan,
		//0,{ ~midiOut.noteOn(chan,num,vel) },
		2,{switch((num/3).asInteger,
			0,{
				//"voice1".postln;


				~playVoice1.value(((bus[13]).linlin(0,127,0.5,8.0)).round(0.25),velocity:vel,synthName:synthName);
				//~bela.sendMsg("/belaReverb",1,0.2.exprand(0.97));

				//~voiceP1.reset;
				//~voiceP1.play;

		},
			1,{
				~playVoice2.value(((bus[14]).linlin(0,127,0.5,8.0)).round(0.25),velocity:vel,synthName:synthName);
				//~voiceP2.stop;
				//~voiceP2.reset;
				//~voiceP2.play;

		},
			2,{
				~playVoice3.value(((bus[15]).linlin(0,127,0.5,8.0)).round(0.25),velocity:vel,synthName:synthName);
				//~voiceP3.stop;
				//~voiceP3.reset;
				//~voiceP3.play;

		});

		},
		3,{switch(num,
			//Trig Struct Change
			0,{~trigStruct.value},
			//Trig Fx Change
			1,{~trigFx.value(vel);});

		},

	);






});

~noteOff =  MIDIFunc.noteOff({
	arg vel, num, chan, src;

	switch(
		chan,
		//0,{ ~midiOut.noteOff(chan,num,vel) },
		2,{switch((num/3).asInteger,0,{~synthList[0].set(\resetT, -0.1)},1,{~synthList[1].set(\resetT, -0.1)},2,{~synthList[2].set(\resetT, -0.1)});  },
		3,{switch(num,
			//Trig Struct Change
			0,{},
			//Trig Fx Change
			1,{~trigChopOff.value});

		}
	);



	/*"--noteoff------------------".postln;
	"noteoff".postln;
	"src:".post;src.postln;
	"chan:".post;chan.postln;
	"num:".post;num.postln;
	"vel:".post;vel.postln;
	"-----------------------END".postln;*/
});



~machineDpatterns=[nil]!18;
~recvLength.free;
~recvLength=OSCFunc( {
	|msg|
	~patternLength=msg[1];
},"/pLength" );

~recvAmp.free;


~recvAmp=OSCFunc( {
	|msg|
	var amps= msg[1].asString.interpret;
	~synthAmps=amps;
	~synthList.do({ |item,idx| if(item.notNil,{amps[idx].postln; item.set(\amp,amps[idx]) });  });




},"/pAmp" );



~recvPatterns.free;
~recvPatterns=OSCFunc( {
	|msg|
	var pat=((msg[1])).asString.interpret;

	~machineDpatterns[pat[0].asInteger]=pat[1..65].asInteger;

},"/pattern" );


~trigBela.free;
~trigBela=OSCFunc({ |msg|

	var size= msg.size;
	var freq=msg[size-2];
	var env2Ratio1=msg[size-1];


	//bela

				fork{
					////damping time cutoff speed rand1 rand2

						~bela.sendMsg("/belaReverb",0,0.988.exprand(1.0));
						~bela.sendMsg("/belaReverb",1,freq.clip(0.0,12543.0).cpsmidi.linlin(0.0,127.0,0.9,0.1));
						~bela.sendMsg("/belaReverb",2,0.00001.exprand(0.7));
						~bela.sendMsg("/belaReverb",3,env2Ratio1.abs.clip(0.0,1.0));
						~bela.sendMsg("/belaReverb",4,0.1.exprand(0.5));
						~bela.sendMsg("/belaReverb",5,0.1.exprand(0.5));
		if(0.1.coin,{~bela.sendMsg("/belaReverb",6,1.0);});
							~bela.sendMsg("/belaReverb",7,3.rand);
						~bela.sendMsg("/belaReverb",8,3.rand);



				};

}, '/trigBela');

~setNbars.free;
~setNBars=OSCFunc({arg ... args;
	var scale=(args[0][1]).asFloat;
	scale=scale.linlin(0.0,1.0,0.125,64.0).round(0.125);
	~globalMemoryNBars.set(scale);

},'/nbars');

//not necessary anymore, kills all synths after the third one
/*
~voiceControl.free;
~voiceControl=OSCFunc({arg ... args;



	var multi=args[0].findAll(['multiScale']);
	var mandel=args[0].findAll(['mandel']);




	if((mandel!=nil),{
		mandel=mandel.reverse;
		if((mandel.size>3),{

		(mandel.size-3).do({|i|
			var nodeId=args[0][mandel[i]-2];
			s.sendMsg(\n_free,nodeId);
		});
})});
	if((multi!=nil),{

		multi=multi.reverse;
		if((multi.size>3),{

		(multi.size-3).do({|i|
			var nodeId=args[0][multi[i]-2];
			s.sendMsg(\n_free,nodeId);
		});
})});


},'/g_queryTree.reply');*/




"finished".postln;

)




// //////////////////////////////////////////////////////////////////////////////////////////
// //////////////////////////////////////////////////////////////////////////////////////////
// //////////////////////////////////////////////////////////////////////////////////////////
