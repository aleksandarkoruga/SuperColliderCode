



//Degree of cross correlation, x(t)Xv(t)= conj(FFT(x))*FFT(v), with slight modifications on the range of the output. Being the output of identical signals ->inf and not correlated 0, i transformed them using the dbamp function to convert from logarithmic to linear range. Well enough the value of a random signal against a sinusoid has an average of 0.5, a completely identical signal 1 ,and a decorrelated signal an oscillating value between 0 and 1 based on the distance in frequency between the two sinusoids.
(
~deconvFunc={
		|sig1,sig2,out=0|
	var frameSize=1024;
	var hop=0.5;
	var chain1, chain2, chain3,chain3conj1,chain3conj2,chain4;
	var xCorr,deconvolved,morph;


	//comment next two lines to use as synthdef, uncomment to test
		sig1= LFNoise2.ar(2.0).abs *SinOsc.ar((500+ (456* SinOsc.ar(678))));
		sig2=LFNoise2.ar(6.0).abs*SinOsc.ar(600+30*SinOsc.ar(450));


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
	xCorr=(1.0-(Amplitude.ar(IFFT(chain2),0.5,0.5) *(-1.0)).dbamp).clip(0.0,1.0).poll;   //.scope.poll(label:"cross-correlation");



	// //////////////////////////////////////// morph
	//instead of using this as time-audio signal, use the fft version and morph it with the source
	//deconvolved=IFFT(chain3conj1);


	//xCorr = 0.5 probably noise , 0 distant in frequency 1 comlpetely correlated


	//noisefloor= 1-(2*(0.5-xCorr).abs) -> leave the range 0.5-1 in amplitude to pass through so 0.5- etc so if noise is present at xCorr=0.5 the floor is raised
	//frequency shift proportional to the correlation distance (morph has still the original input transform up until this point)
	morph= TPV.ar(morph,frameSize,frameSize*hop,80,40, 1.0/(0.1+((1-xCorr)*10.0)), (1-xCorr)*512, (0.5-((0.5-xCorr).abs)));

	//tpv at this point is a signal in time domain and in order to be morphed with the devconvolved signal needs to be re-transformed into frequency domain. This introduces a delay of the window size*hop which has to be compensated for in the input signal to the deconvolution and xcorrelation (DelayN)
	morph= FFT(LocalBuf(frameSize), morph);

	//morph the source with the deconvolved signal
	morph = PV_Morph(morph ,deconvolved ,xCorr);



	//output the morph between original and deconvolved
		(LeakDC.ar(IFFT(morph).tanh));


};

SynthDef(\deconvolve,{
	|in1 ,in2|
	Out.ar(0,~deconvFunc.value(in1,in2,0));
}).add;


 SynthDef(\deconvolveAndShift,
	{
		|sig1,sig2,out=0|
	var frameSize=1024;
	var hop=0.5;
	var chain1, chain2, chain3,chain3conj1,chain3conj2,chain4;
	var xCorr,deconvolved,morph;


	//comment next two lines to use as synthdef, uncomment to test
		sig1= LFNoise2.ar(2.0).abs *SinOsc.ar((500+ (456* SinOsc.ar(678))));
		sig2=LFNoise2.ar(6.0).abs*SinOsc.ar(600+30*SinOsc.ar(450));


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
	xCorr=(1.0-(Amplitude.ar(IFFT(chain2),0.5,0.5) *(-1.0)).dbamp).clip(0.0,1.0).poll;   //.scope.poll(label:"cross-correlation");



	// //////////////////////////////////////// morph
	//instead of using this as time-audio signal, use the fft version and morph it with the source
	//deconvolved=IFFT(chain3conj1);


	//xCorr = 0.5 probably noise , 0 distant in frequency 1 comlpetely correlated


	//noisefloor= 1-(2*(0.5-xCorr).abs) -> leave the range 0.5-1 in amplitude to pass through so 0.5- etc so if noise is present at xCorr=0.5 the floor is raised
	//frequency shift proportional to the correlation distance (morph has still the original input transform up until this point)
	morph= TPV.ar(morph,frameSize,frameSize*hop,80,40, 1.0/(0.1+((1-xCorr)*10.0)), (1-xCorr)*512, (0.5-((0.5-xCorr).abs)));

	//tpv at this point is a signal in time domain and in order to be morphed with the devconvolved signal needs to be re-transformed into frequency domain. This introduces a delay of the window size*hop which has to be compensated for in the input signal to the deconvolution and xcorrelation (DelayN)
	morph= FFT(LocalBuf(frameSize), morph);

	//morph the source with the deconvolved signal
	morph = PV_Morph(morph ,deconvolved ,xCorr);



	//output the morph between original and deconvolved
		Out.ar(out,LeakDC.ar(IFFT(morph).tanh));


}

).add
)


Synth(\deconvolve)
Synth(\deconvolveAndShift)






In.ar(~bus.index,10).collect

// rewrite to the 10 input busses
x=10.collect(|i|   Synth(\deconvolve,[\out,~bus.index+i])

	x=80.collect( {  Synth(\deconvolve)})



x.do(_.free)




 10

8



	var digitalIn=In.ar(~bus.index,6);
//8 inputs
//Machinedrum from analog 1/2 computer 5/6 -> 4/5 sc output motu 0-23  motu input 24-47
	var	input=([(LeakDC.ar(Mix.ar(digitalIn[(0..1)])).tanh)]++[(LeakDC.ar(Mix.ar(digitalIn[(2..3)])).tanh)]++[(LeakDC.ar(Mix.ar(digitalIn[(4..5)])).tanh)]++(In.ar(32,2))++(In.ar(30,1))++(In.ar(28,2)  )   );

//from mixio outputs to ableton/out
//OffsetOut.ar(0,In.ar(~bus.index,10));







